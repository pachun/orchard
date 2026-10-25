// The launcher: Cmd+Space opens a search field over the desktop; typing
// narrows a list of everything on this machine that opts in, Enter opens
// the selection, Escape closes.
//
// Nothing is indexed. Each feature that has something worth opening ships a
// launcher/<Name>.json, linked into ~/.config/launcher/, and this reads that
// directory when it opens — so the list is exactly the features on the
// machine, and a feature that is removed takes its row with it. The file's
// name is the entry's name, spelled as it should appear; inside are a
// Phosphor glyph, the command to run (with ~/.local/bin on the path, so the
// bar's menus and panels are entries too) and aliases: the other things you
// might call it, searched as names.
//
// After xmsadik's YourOmaLauncher, cut down: one list rather than folders,
// edited in the repo rather than in the panel. Colors come from colors.json,
// written from the active theme by render-launcher-theme and re-read when it
// changes.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  property bool opened: false
  property var entries: []
  property var results: []
  property int selectedIndex: 0
  property var targetScreen: null
  property point pointerLastSeenAt: Qt.point(-1, -1)
  property bool pointerSeen: false

  readonly property int panelWidth: 560
  readonly property int rowHeight: 44
  readonly property int rowsShown: 8
  readonly property int fieldHeight: 60
  readonly property int padding: 8
  readonly property int cornerRadius: 10
  readonly property int borderWidth: 2

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

  function focusedScreen() {
    var monitorName = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; ++i) {
      if (String(screens[i].name || "") === monitorName)
        return screens[i]
    }
    return screens.length > 0 ? screens[0] : null
  }

  function open() {
    targetScreen = focusedScreen()
    searchField.text = ""
    selectedIndex = 0
    pointerSeen = false
    results = entries
    if (!entriesQuery.running)
      entriesQuery.running = true
    opened = true
    Qt.callLater(function() { searchField.forceActiveFocus() })
  }

  function close() {
    opened = false
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  // How well one name answers the query. Reading it from its start beats
  // reading it from a word inside it, which beats finding the query anywhere
  // in it. Below zero is no match.
  function rankName(name, query) {
    if (name.indexOf(query) === 0) return 400 - name.length
    var atWord = name.indexOf(" " + query)
    if (atWord >= 0) return 300 - atWord
    var at = name.indexOf(query)
    if (at >= 0) return 200 - at
    return -1
  }

  // An alias is another name for the thing, so it ranks as the name does. The
  // letters merely appearing in order in the name is the last resort, so
  // "clr" still finds Calculator.
  function rank(entry, query) {
    var name = String(entry.name || "").toLowerCase()
    var names = [name].concat(Array.isArray(entry.aliases) ? entry.aliases : [])
    var best = -1
    for (var i = 0; i < names.length; ++i)
      best = Math.max(best, rankName(String(names[i]).toLowerCase(), query))
    if (best >= 0) return best

    var at = 0
    for (var j = 0; j < query.length; ++j) {
      at = name.indexOf(query[j], at)
      if (at < 0) return -1
      at += 1
    }
    return 50 - at
  }

  function search(text) {
    var query = String(text || "").trim().toLowerCase()
    if (!query) {
      results = entries
    } else {
      var ranked = []
      for (var i = 0; i < entries.length; ++i) {
        var score = rank(entries[i], query)
        if (score >= 0) ranked.push({ entry: entries[i], score: score })
      }
      ranked.sort(function(a, b) {
        return b.score - a.score || String(a.entry.name).localeCompare(String(b.entry.name))
      })
      results = ranked.map(function(r) { return r.entry })
    }
    selectedIndex = 0
  }

  // Hover selects only when the pointer has actually moved. Qt reports a
  // move to a row that merely appears under a pointer sitting still, which
  // happens on every keystroke that reshapes the list, so a move is only
  // believed when it lands somewhere other than where the pointer was last
  // seen — and the first report after opening only records where that is.
  function pointerMovedTo(point, index) {
    var moved = pointerSeen && (point.x !== pointerLastSeenAt.x || point.y !== pointerLastSeenAt.y)
    pointerLastSeenAt = point
    pointerSeen = true
    if (moved) selectedIndex = index
  }

  function move(direction) {
    if (results.length === 0) return
    selectedIndex = (selectedIndex + direction + results.length) % results.length
    Qt.callLater(function() { list.positionViewAtIndex(selectedIndex, ListView.Contain) })
  }

  function launchSelected() {
    if (selectedIndex < 0 || selectedIndex >= results.length) return
    var command = String(results[selectedIndex].command || "")
    close()
    if (command)
      Quickshell.execDetached(["sh", "-c", 'PATH="$HOME/.local/bin:$PATH"; exec ' + command])
  }

  function finishEntriesQuery(text) {
    var loaded
    try {
      loaded = JSON.parse(String(text || "[]"))
    } catch (error) {
      console.warn("launcher: failed to parse ~/.config/launcher/*.json:", error)
      return
    }
    if (!Array.isArray(loaded)) return
    loaded.sort(function(a, b) { return String(a.name).localeCompare(String(b.name)) })
    entries = loaded
    search(searchField.text)
  }

  Process {
    id: entriesQuery
    // The file's name is the entry's name, so each one is read with it added.
    command: ["sh", "-c", 'for entry in "$HOME"/.config/launcher/*.json; do [ -f "$entry" ] && jq --arg name "$(basename "$entry" .json)" ". + {name: \\$name}" "$entry"; done | jq -s .']
    running: true

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishEntriesQuery(text)
    }
  }

  GlobalShortcut {
    appid: "orchard-launcher"
    name: "toggle"
    description: "Open or close the launcher"
    onPressed: root.toggle()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    onVisibleChanged: {
      if (visible) searchField.forceActiveFocus()
    }
    screen: root.targetScreen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.namespace: "launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: theme.backdrop

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }

    // The same frame as the bar's menus and dropdowns — the theme panel
    // color, a 2px accent border, radius 10 — frosted by Hyprland's layer
    // rule on this window's namespace. It sits in the upper third, where the
    // eye goes first and where the list has room to grow downward.
    Rectangle {
      id: box
      width: root.panelWidth
      // The list is inset by the same padding on every side — below the rule,
      // beside the frame, and above the bottom border — so a lone highlighted
      // row floats inside the frame rather than resting on its bottom edge.
      height: root.fieldHeight + rule.height + (root.results.length > 0 ? Math.min(root.results.length, root.rowsShown) * root.rowHeight + root.padding * 2 + root.borderWidth : emptyNote.height + root.padding * 2)
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round(panel.height * 0.2)
      radius: root.cornerRadius
      color: theme.panel
      border.width: root.borderWidth
      border.color: theme.accent
      clip: true

      MouseArea {
        anchors.fill: parent
      }

      TextInput {
        id: searchField
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
          leftMargin: 20
          rightMargin: 20
        }
        height: root.fieldHeight
        verticalAlignment: TextInput.AlignVCenter
        color: theme.ink
        font.family: "SF Pro"
        font.pixelSize: 22
        selectionColor: theme.accent
        selectedTextColor: theme.panel
        clip: true
        onTextChanged: root.search(text)
        onAccepted: root.launchSelected()

        // Arrows, Tab, and the vim keys with Ctrl held, since the hands are
        // already on the home row to type the search: Ctrl+J down, Ctrl+K up,
        // Ctrl+L open, the same reflex as moving through a list in nvim.
        Keys.onPressed: function(event) {
          var ctrl = event.modifiers & Qt.ControlModifier
          if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) || (ctrl && event.key === Qt.Key_J)) {
            root.move(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
            root.move(-1)
            event.accepted = true
          } else if (ctrl && event.key === Qt.Key_L) {
            root.launchSelected()
            event.accepted = true
          }
        }

        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          text: "Search"
          color: theme.dim
          visible: !searchField.text
          font: searchField.font
        }
      }

      Rectangle {
        id: rule
        anchors {
          top: searchField.bottom
          left: parent.left
          right: parent.right
          leftMargin: root.borderWidth
          rightMargin: root.borderWidth
        }
        height: 1
        color: theme.track
        visible: root.results.length > 0
      }

      Text {
        id: emptyNote
        anchors {
          top: searchField.bottom
          left: parent.left
          leftMargin: 20
          topMargin: root.padding
        }
        text: root.entries.length === 0 ? "Nothing has opted in yet" : "Nothing matches"
        color: theme.dim
        visible: root.results.length === 0
        font.family: "SF Pro"
        font.pixelSize: 15
      }

      ListView {
        id: list
        anchors {
          top: rule.bottom
          left: parent.left
          right: parent.right
          topMargin: root.padding
          leftMargin: root.padding
          rightMargin: root.padding
        }
        height: Math.min(root.results.length, root.rowsShown) * root.rowHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results
        currentIndex: root.selectedIndex
        visible: root.results.length > 0

        delegate: Rectangle {
          id: row
          required property int index
          required property var modelData

          readonly property bool selected: index === root.selectedIndex

          width: list.width
          height: root.rowHeight
          radius: root.cornerRadius - 2
          color: selected ? theme.selected : "transparent"

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: function(mouse) { root.pointerMovedTo(mapToItem(null, mouse.x, mouse.y), row.index) }
            onClicked: root.launchSelected()
          }

          Text {
            id: glyph
            anchors {
              left: parent.left
              leftMargin: 14
              verticalCenter: parent.verticalCenter
            }
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text: String(row.modelData.icon || "")
            color: row.selected ? theme.accent : theme.dim
            font.family: "Phosphor-Fill"
            font.pixelSize: 18
          }

          Text {
            anchors {
              left: glyph.right
              right: parent.right
              leftMargin: 14
              rightMargin: 14
              verticalCenter: parent.verticalCenter
            }
            text: String(row.modelData.name || "")
            color: theme.ink
            elide: Text.ElideRight
            font.family: "SF Pro"
            font.pixelSize: 15
            font.weight: row.selected ? Font.DemiBold : Font.Normal
          }
        }
      }
    }
  }
}
