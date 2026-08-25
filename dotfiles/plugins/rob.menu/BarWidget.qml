import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    fixedWidth: Style.space(27)
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }

    Image {
      anchors.centerIn: parent
      source: "arch.svg"
      width: Style.space(20)
      height: Style.space(20)
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      horizontalAlignment: Image.AlignHCenter
      verticalAlignment: Image.AlignVCenter
    }
  }
}
