// The window switcher: hold Cmd, press Tab, and a strip of live window
// previews appears in the middle of the screen in most-recently-used order,
// the previous window already selected. Tab moves forward, Shift+Tab (or `)
// back, releasing Cmd focuses the selection, Escape cancels.
//
// After lsongdev's omarchy-switcher. Hyprland is the source of truth for the
// order: each session takes one `hyprctl clients -j` and sorts by
// focusHistoryID, so there is no window history of our own to drift. The
// previews come from ScreencopyView over Hyprland's toplevel export, one
// frame each, never written to disk.
//
// Hyprland drives it through global shortcuts (hyprland.lua binds Cmd+Tab and
// friends to them) and the overlay takes exclusive keyboard focus while open,
// so the Cmd release that commits reaches it even though Hyprland also binds
// that release as a backup. Colors come from colors.json, written from the
// active theme by render-window-switcher-theme and re-read when it changes.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  property bool opened: false
  property var windows: []
  property int selectedIndex: 0
  property int pendingSteps: 0
  property bool queryWanted: false
  property bool commitWhenQueryLands: false
  property var targetScreen: null

  readonly property int cardWidth: 260
  readonly property int cardHeight: 176
  readonly property int cardSpacing: 12
  readonly property int trackPadding: 16
  readonly property int cornerRadius: 10
  readonly property int borderWidth: 2
  readonly property int screenMargin: 80

  FileView {
    path: Quickshell.shellDir + "/colors.json"
    watchChanges: true
    onFileChanged: reload()
    adapter: JsonAdapter {
      id: theme
      property color backdrop: "#401e1e2e"
      property color panel: "#cc1e1e2e"
      property color track: "#26cdd6f4"
      property color ink: "#cdd6f4"
      property color dim: "#99cdd6f4"
      property color accent: "#89b4fa"
      property color selected: "#2489b4fa"
    }
  }

  function normalizeAddress(value) {
    var address = String(value || "").toLowerCase()
    if (!address) return ""
    if (address.indexOf("0x") !== 0) address = "0x" + address
    return /^0x[0-9a-f]+$/.test(address) ? address : ""
  }

  function focusedScreen() {
    var monitorName = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; ++i) {
      if (String(screens[i].name || "") === monitorName)
        return screens[i]
    }
    return screens.length > 0 ? screens[0] : null
  }

  // Minimized windows (focus-or-launch stashes them on a special workspace)
  // stay out, as do unmapped and hidden ones: the strip is what is on the
  // desktops, in the order it was last looked at.
  function snapshotWindows(clients) {
    if (!Array.isArray(clients)) return []

    var toplevelByAddress = ({})
    var toplevels = Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : []
    for (var i = 0; i < toplevels.length; ++i) {
      var topAddress = normalizeAddress(toplevels[i].address)
      if (topAddress) toplevelByAddress[topAddress] = toplevels[i]
    }

    var rows = []
    for (var j = 0; j < clients.length; ++j) {
      var client = clients[j]
      if (!client || client.mapped === false || client.hidden === true) continue

      var workspaceId = Number(client.workspace ? client.workspace.id : -1)
      if (workspaceId <= 0) continue

      var address = normalizeAddress(client.address)
      if (!address) continue

      var focusHistoryId = Number(client.focusHistoryID)
      if (!Number.isFinite(focusHistoryId) || focusHistoryId < 0)
        focusHistoryId = 2147483647

      var toplevel = toplevelByAddress[address] || null
      var appClass = String(client.class || client.initialClass || "Application")
      var title = String(client.title || (toplevel ? toplevel.title || "" : "") || appClass)

      rows.push({
        address: address,
        title: title,
        appClass: appClass,
        focusHistoryId: focusHistoryId,
        wayland: toplevel ? (toplevel.wayland || null) : null
      })
    }

    rows.sort(function(a, b) { return a.focusHistoryId - b.focusHistoryId })
    return rows
  }

  function cycle(direction) {
    if (opened && windows.length > 0) {
      select(direction)
      return
    }

    if (!queryWanted)
      targetScreen = focusedScreen()
    pendingSteps += direction
    queryWanted = true
    if (!clientsQuery.running)
      clientsQuery.running = true
  }

  function select(direction) {
    if (windows.length === 0) return
    selectedIndex = (selectedIndex + direction + windows.length) % windows.length
    Qt.callLater(function() {
      listView.positionViewAtIndex(selectedIndex, ListView.Contain)
    })
  }

  function cancel() {
    opened = false
    windows = []
    pendingSteps = 0
    queryWanted = false
    commitWhenQueryLands = false
  }

  function focusWindow(address) {
    if (address)
      Qt.callLater(function() {
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
      })
  }

  // A Cmd release that arrives while the client list is still loading is a
  // quick tap: the switch happens the moment the list lands, with no strip,
  // the way a quick Cmd+Tab on a Mac goes straight to the previous window.
  function commit() {
    if (!opened && queryWanted) {
      commitWhenQueryLands = true
      return
    }
    if (!opened || selectedIndex < 0 || selectedIndex >= windows.length) {
      cancel()
      return
    }

    var address = windows[selectedIndex].address
    cancel()
    focusWindow(address)
  }

  function finishWindowQuery(text) {
    if (!queryWanted) return

    var clients
    try {
      clients = JSON.parse(String(text || "[]"))
    } catch (error) {
      console.warn("window-switcher: failed to parse hyprctl clients:", error)
      pendingSteps = 0
      queryWanted = false
      return
    }

    var nextWindows = snapshotWindows(clients)
    if (nextWindows.length < 2) {
      pendingSteps = 0
      queryWanted = false
      return
    }

    windows = nextWindows

    var steps = pendingSteps
    pendingSteps = 0
    queryWanted = false
    selectedIndex = ((steps % windows.length) + windows.length) % windows.length

    if (commitWhenQueryLands) {
      var address = windows[selectedIndex].address
      cancel()
      focusWindow(address)
      return
    }

    opened = true
    Qt.callLater(function() {
      keyCatcher.forceActiveFocus()
      listView.positionViewAtIndex(selectedIndex, ListView.Contain)
    })
  }

  Process {
    id: clientsQuery
    command: ["hyprctl", "clients", "-j"]
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishWindowQuery(text)
    }
  }

  GlobalShortcut {
    appid: "orchard-window-switcher"
    name: "next"
    description: "Open or advance the window switcher"
    onPressed: root.cycle(1)
  }

  GlobalShortcut {
    appid: "orchard-window-switcher"
    name: "previous"
    description: "Open or move backward in the window switcher"
    onPressed: root.cycle(-1)
  }

  GlobalShortcut {
    appid: "orchard-window-switcher"
    name: "commit"
    description: "Focus the selected window"
    onPressed: root.commit()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    onVisibleChanged: {
      if (visible) keyCatcher.forceActiveFocus()
    }
    screen: root.targetScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.namespace: "window-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: theme.backdrop
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.cancel()
          event.accepted = true
        }
      }
      Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
          root.commit()
          event.accepted = true
        }
      }
    }

    // The strip: the same frame as the bar's menus and dropdowns — the theme
    // panel color, a 2px accent border, radius 10 — frosted by Hyprland's
    // layer rule on this window's namespace.
    Rectangle {
      id: track
      anchors.centerIn: parent
      width: Math.min(
        panel.width - root.screenMargin,
        root.windows.length * root.cardWidth
          + Math.max(0, root.windows.length - 1) * root.cardSpacing
          + root.trackPadding * 2
      )
      height: root.cardHeight + root.trackPadding * 2
      radius: root.cornerRadius
      color: theme.panel
      border.width: root.borderWidth
      border.color: theme.accent

      ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: root.trackPadding
        orientation: ListView.Horizontal
        spacing: root.cardSpacing
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.windows
        currentIndex: root.selectedIndex

        delegate: Rectangle {
          id: card
          required property int index
          required property var modelData

          readonly property bool selected: index === root.selectedIndex

          width: root.cardWidth
          height: root.cardHeight
          radius: root.cornerRadius - 2
          color: selected ? theme.selected : "transparent"
          border.width: 1
          border.color: selected ? theme.accent : theme.track
          clip: true

          Rectangle {
            id: previewFrame
            anchors {
              top: parent.top
              left: parent.left
              right: parent.right
              bottom: titleBar.top
              margins: 7
              bottomMargin: 5
            }
            radius: Math.max(2, card.radius - 3)
            color: theme.track
            clip: true

            // What stands in for a preview the compositor could not give us.
            Text {
              anchors.centerIn: parent
              width: parent.width - 20
              text: card.modelData.appClass
              color: theme.dim
              visible: !preview.hasContent
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              font.family: "SF Pro"
              font.pixelSize: 15
            }

            ScreencopyView {
              id: preview
              anchors.fill: parent
              captureSource: root.opened && card.modelData.wayland ? card.modelData.wayland : null
              paintCursor: false
              live: false
              constraintSize: Qt.size(Math.max(1, width), Math.max(1, height))
              visible: hasContent
            }
          }

          Item {
            id: titleBar
            anchors {
              left: parent.left
              right: parent.right
              bottom: parent.bottom
            }
            height: 34

            Text {
              anchors {
                left: parent.left
                right: parent.right
                leftMargin: 10
                rightMargin: 10
                verticalCenter: parent.verticalCenter
              }
              text: card.modelData.title
              color: card.selected ? theme.ink : theme.dim
              elide: Text.ElideRight
              maximumLineCount: 1
              font.family: "SF Pro"
              font.pixelSize: 13
              font.weight: card.selected ? Font.DemiBold : Font.Normal
            }
          }
        }
      }
    }
  }
}
