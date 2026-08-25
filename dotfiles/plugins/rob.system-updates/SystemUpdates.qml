import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "rob.system-updates"

  readonly property string pacmanIcon: "󰮯"

  property int updateCount: -1

  function refresh() {
    if (!updateProc.running) updateProc.running = true
  }

  function runUpdate() {
    if (updateLaunchProc.running) return
    // Claim the bar's popout slot so the built-in open-panel indicator lights
    // up underneath this widget while the update terminal is running.
    if (root.bar && root.bar.requestPopout) root.bar.requestPopout(root)
    updateLaunchProc.running = true
  }

  readonly property string displayText: updateCount >= 0 ? String(updateCount) : "…"

  // Lets the bar size the open-panel indicator to the widget's full rendered
  // width, so the accent underline spans the whole widget.
  readonly property real openPanelIndicatorWidth: root.width

  implicitWidth: row.implicitWidth
  implicitHeight: root.barSize

  IpcHandler {
    target: "rob.system-updates"

    function refresh(): void {
      root.broadcast("refresh")
    }

    function status(): string {
      return String(root.updateCount)
    }
  }

  Process {
    id: updateLaunchProc
    command: ["bash", "-c", "omarchy-launch-floating-terminal-with-presentation omarchy-update"]
    onExited: {
      if (root.bar && root.bar.releasePopout) root.bar.releasePopout(root)
    }
  }

  Process {
    id: updateProc
    command: ["bash", "-c", "$HOME/.config/omarchy/bin/system-update-count"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: function() {
        var raw = String(text || "").trim()
        root.updateCount = parseInt(raw, 10) || 0
      }
    }
  }

  Timer {
    interval: 3600000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Row {
    id: row
    spacing: 3
    visible: root.updateCount >= 0

    BarIconButton {
      id: icon
      anchors.verticalCenter: parent.verticalCenter
      bar: root.bar
      text: root.pacmanIcon
      active: root.updateCount > 0
      activeColor: "#ffd75f"
      slotSize: Style.bar.statusSlot
      opticalSize: 12
      horizontalMargin: 0
      fontSize: 12
      tooltipText: root.updateCount > 0
        ? "Pending updates: " + root.updateCount
        : "System up to date"
      onPressed: function(button) {
        if (button === Qt.LeftButton || button === Qt.RightButton) root.runUpdate()
        else root.refresh()
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.displayText
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      visible: root.updateCount >= 0

      MouseArea {
        anchors.fill: parent
        onClicked: root.runUpdate()
        onPressAndHold: root.refresh()
      }
    }
  }
}
