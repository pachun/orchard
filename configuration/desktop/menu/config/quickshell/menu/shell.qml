// The picker behind the bar's menus: Wi-Fi, Bluetooth, sound, VPN, theme and
// the system menu each build their rows and hand them to orchard-menu, which
// hands them here and waits for the choice. Typing narrows the rows, Enter
// (or Ctrl+L) answers with the selected row, Escape answers that nothing was
// chosen. A request with no rows is a prompt for typed text, masked when the
// request says so, which is how the Wi-Fi password and Bluetooth PIN are
// asked for.
//
// orchard-menu writes each request to a file and names it over Quickshell's
// IPC; the answer goes back the same way, to the path the request names, so
// nothing a person types is ever a process's argument. Rows are text as the
// menus already build them: a Phosphor glyph, two spaces, the label.
//
// The same frame, keys and search as the launcher. Colors come from
// colors.json, written from the active theme by render-menu-theme and
// re-read when it changes.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  property bool opened: false
  property var request: null
  property var rows: []
  property var results: []
  property int selectedIndex: 0
  property var targetScreen: null
  property point pointerLastSeenAt: Qt.point(-1, -1)
  property bool pointerSeen: false

  readonly property bool asksForText: request !== null && rows.length === 0
  readonly property bool masked: request !== null && request.password === true

  readonly property int panelWidth: 480
  readonly property int rowHeight: 40
  readonly property int rowsShown: 12
  readonly property int fieldHeight: 56
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

  FileView {
    id: answer
    printErrors: false
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

  // A row is "<glyph>  <label>" when the menu gave it a glyph: one character
  // from the private-use range the icon fonts live in, then two spaces.
  function splitRow(text) {
    var match = /^([-])  (.*)$/.exec(String(text))
    return match ? { icon: match[1], label: match[2] } : { icon: "", label: String(text) }
  }

  function openRequest(path) {
    if (opened) cancel()
    requestQuery.command = ["cat", path]
    requestQuery.running = true
  }

  function finishRequestQuery(text) {
    var loaded
    try {
      loaded = JSON.parse(String(text || "{}"))
    } catch (error) {
      console.warn("menu: failed to parse the request:", error)
      return
    }
    if (!loaded || typeof loaded.response !== "string") return

    request = loaded
    rows = (Array.isArray(loaded.rows) ? loaded.rows : []).map(function(row) {
      var parts = splitRow(row)
      return { text: String(row), icon: parts.icon, label: parts.label }
    })
    targetScreen = focusedScreen()
    searchField.text = ""
    selectedIndex = 0
    pointerSeen = false
    results = rows
    opened = true
    Qt.callLater(function() { searchField.forceActiveFocus() })
  }

  function respond(chosen, cancelled) {
    var pending = request
    opened = false
    request = null
    rows = []
    results = []
    if (!pending) return
    // The answer names its own request: FileView skips a write whose text
    // matches the last one it wrote, and every "nothing chosen" answer would
    // otherwise be the same text as the one before.
    answer.path = pending.response
    answer.setText(JSON.stringify({ request: pending.response, chosen: chosen, cancelled: cancelled }))
  }

  function cancel() {
    respond("", true)
  }

  function answerWithSelection() {
    if (asksForText) {
      respond(searchField.text, false)
    } else if (selectedIndex >= 0 && selectedIndex < results.length) {
      respond(results[selectedIndex].text, false)
    } else {
      respond(searchField.text, false)
    }
  }

  function rankName(name, query) {
    if (name.indexOf(query) === 0) return 400 - name.length
    var atWord = name.indexOf(" " + query)
    if (atWord >= 0) return 300 - atWord
    var at = name.indexOf(query)
    if (at >= 0) return 200 - at
    return -1
  }

  function rank(row, query) {
    var label = row.label.toLowerCase()
    var best = rankName(label, query)
    if (best >= 0) return best

    var at = 0
    for (var j = 0; j < query.length; ++j) {
      at = label.indexOf(query[j], at)
      if (at < 0) return -1
      at += 1
    }
    return 50 - at
  }

  // The menu's own order is kept whenever the query matches rows equally
  // well: the Wi-Fi menu lists the connected network first and the rest by
  // signal, and a search should not shuffle that.
  function search(text) {
    if (asksForText) return
    var query = String(text || "").trim().toLowerCase()
    if (!query) {
      results = rows
    } else {
      var ranked = []
      for (var i = 0; i < rows.length; ++i) {
        var score = rank(rows[i], query)
        if (score >= 0) ranked.push({ row: rows[i], score: score, order: i })
      }
      ranked.sort(function(a, b) { return b.score - a.score || a.order - b.order })
      results = ranked.map(function(r) { return r.row })
    }
    selectedIndex = 0
  }

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

  Process {
    id: requestQuery
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.finishRequestQuery(text)
    }
  }

  IpcHandler {
    target: "menu"

    function open(requestPath: string): void {
      root.openRequest(requestPath)
    }

    function close(): void {
      root.cancel()
    }
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

    WlrLayershell.namespace: "menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: theme.backdrop

      MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
      }
    }

    Rectangle {
      id: box
      width: root.panelWidth
      height: root.fieldHeight + rule.height + (root.results.length > 0 ? Math.min(root.results.length, root.rowsShown) * root.rowHeight + root.padding * 2 + root.borderWidth : (root.asksForText ? 0 : emptyNote.height + root.padding * 2))
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

      // The prompt is the question when the menu asks for typed text —
      // "password for Oxygen Oasis" — and nothing when it lists rows, which
      // say for themselves what menu this is.
      Text {
        id: promptLabel
        anchors {
          left: parent.left
          leftMargin: 20
          verticalCenter: searchField.verticalCenter
        }
        text: root.request ? String(root.request.prompt || "").replace(/:\s*$/, "") : ""
        color: theme.dim
        visible: root.asksForText && text !== ""
        font.family: "SF Pro"
        font.pixelSize: 20
      }

      TextInput {
        id: searchField
        anchors {
          top: parent.top
          left: promptLabel.visible ? promptLabel.right : parent.left
          right: parent.right
          leftMargin: promptLabel.visible ? 12 : 20
          rightMargin: 20
        }
        height: root.fieldHeight
        verticalAlignment: TextInput.AlignVCenter
        color: theme.ink
        font.family: "SF Pro"
        font.pixelSize: 20
        echoMode: root.masked ? TextInput.Password : TextInput.Normal
        selectionColor: theme.accent
        selectedTextColor: theme.panel
        clip: true
        onTextChanged: root.search(text)
        onAccepted: root.answerWithSelection()

        Keys.onPressed: function(event) {
          var ctrl = event.modifiers & Qt.ControlModifier
          if (event.key === Qt.Key_Escape) {
            root.cancel()
            event.accepted = true
          } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) || (ctrl && event.key === Qt.Key_J)) {
            root.move(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
            root.move(-1)
            event.accepted = true
          } else if (ctrl && event.key === Qt.Key_L) {
            root.answerWithSelection()
            event.accepted = true
          }
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
        height: root.asksForText ? 0 : 1
        color: theme.track
        visible: !root.asksForText
      }

      Text {
        id: emptyNote
        anchors {
          top: rule.bottom
          left: parent.left
          leftMargin: 20
          topMargin: root.padding
        }
        text: "Nothing matches"
        color: theme.dim
        visible: !root.asksForText && root.results.length === 0
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
            onClicked: root.answerWithSelection()
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
            text: row.modelData.icon
            visible: row.modelData.icon !== ""
            color: row.selected ? theme.accent : theme.dim
            // The regular weight: the menus chose their codepoints for it, and
            // the fill face does not share them all.
            font.family: "Phosphor"
            font.pixelSize: 17
          }

          Text {
            anchors {
              left: row.modelData.icon !== "" ? glyph.right : parent.left
              right: parent.right
              leftMargin: 14
              rightMargin: 14
              verticalCenter: parent.verticalCenter
            }
            text: row.modelData.label
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
