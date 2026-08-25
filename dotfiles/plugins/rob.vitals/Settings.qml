import QtQuick
import qs.Commons
import qs.Ui

// Settings popup for rob.vitals: a Toggle row per metric, listed in the stored
// display order. Flipping a switch persists through the host widget
// (updateEntryInline); dragging a row's grip reorders the list live and
// persists the new order on release, so the bar follows immediately and the
// choice survives restarts.
//
// Wraps a PopupCard because PopupCard declares `bar`/`anchorItem` as required
// properties; loaded via a Loader, they are only known once the host widget
// injects them, so the required check would fail at construction. An Item root
// with defaults lets the Loader succeed and the PopupCard bindings update when
// the host injects bar/anchorItem after load.
Item {
  id: root

  // Injected by the host widget after load (bar may be null until then).
  property var bar: null
  property var anchorItem: null
  property var hostWidget: null

  readonly property bool opened: card.open

  function show() { card.open = true }
  function open() { card.open = true }
  function toggle() { card.open = !card.open }
  function close() { card.close() }
  // Sets the popup closed without going through PopupCard.close(), which would
  // call owner.close() (the host widget) and bounce straight back here.
  function closeDirect() { card.open = false }
  function closeForPopoutSwitch() { card.open = false }
  readonly property bool popoutSwitchClosing: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property real rowHeight: 54
  readonly property real listSpacing: Style.space(10)

  // Working copy of the display order. Kept in sync with the host widget's
  // metricOrder so the list reflects persisted state when the popup opens.
  property var order: hostWidget ? hostWidget.metricOrder : []
  onOrderChanged: syncOrder()

  ListModel { id: orderList }

  function syncOrder() {
    orderList.clear()
    for (var i = 0; i < root.order.length; i++) {
      orderList.append({ key: String(root.order[i]) })
    }
  }

  Component.onCompleted: syncOrder()

  function showName(key) {
    if (typeof key !== "string" || key.length === 0) return ""
    return "show" + key.charAt(0).toUpperCase() + key.slice(1)
  }

  // ---- drag reorder ----------------------------------------------------------
  property int dragIndex: -1

  function dragStart(index) {
    root.dragIndex = index
  }

  function dragMoveScene(point) {
    if (root.dragIndex < 0) return
    var local = metricList.mapFromItem(null, point.x, point.y)
    var step = root.rowHeight + root.listSpacing
    var target = Math.round(local.y / step)
    target = Math.max(0, Math.min(orderList.count - 1, target))
    if (target !== root.dragIndex) {
      orderList.move(root.dragIndex, target, 1)
      root.dragIndex = target
    }
  }

  function dragEnd() {
    if (root.dragIndex >= 0) {
      var out = []
      for (var i = 0; i < orderList.count; i++) out.push(orderList.get(i).key)
      if (hostWidget) hostWidget.setMetricOrder(out)
    }
    root.dragIndex = -1
  }

  PopupCard {
    id: card
    anchorItem: root.anchorItem
    bar: root.bar
    // The bar lights the open-panel indicator when its activePopout matches
    // the mounted widget; owning this popup to the host widget makes the
    // popout route through it.
    owner: root.hostWidget

    contentWidth: Style.space(272)
    contentHeight: Style.space(250)

    Column {
      width: parent.width
      spacing: Style.space(8)

      Text {
        text: "VITALS"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
      }

      Item {
        width: parent.width
        height: orderList.count * root.rowHeight + root.listSpacing * Math.max(0, orderList.count - 1)

        ListView {
          id: metricList
          anchors.fill: parent
          model: orderList
          spacing: root.listSpacing
          interactive: false
          clip: true

          delegate: Item {
            id: delegateRow
            required property var model
            required property int index
            width: metricList.width
            height: root.rowHeight

            readonly property bool dragging: root.dragIndex === index
            // Track the grip pointer so reorder can follow it live; the grip
            // itself never moves (the row keeps its layout slot).
            readonly property point pointerScene: gripHandler.centroid.scenePosition
            onPointerSceneChanged: root.dragMoveScene(pointerScene)

            Toggle {
              anchors.left: parent.left
              anchors.right: grip.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              label: root.hostWidget ? root.hostWidget.metricLabel(delegateRow.model.key) : ""
              description: root.hostWidget ? root.hostWidget.metricDescription(delegateRow.model.key) : ""
              checked: root.hostWidget ? root.hostWidget.metricShown(delegateRow.model.key) : true
              foreground: root.foreground
              fontFamily: root.fontFamily
              opacity: delegateRow.dragging ? 0.6 : 1.0
              onClicked: root.hostWidget.toggleMetric(root.showName(delegateRow.model.key))
            }

            Item {
              id: grip
              width: Style.space(28)
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.bottom: parent.bottom

              Text {
                anchors.centerIn: parent
                text: "" // nf-fa-bars (U+F0C9)
                color: delegateRow.dragging ? (root.foreground) : Qt.darker(root.foreground, 1.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }

              DragHandler {
                id: gripHandler
                target: null
                xAxis.enabled: false
                yAxis.enabled: true
                onActiveChanged: {
                  if (gripHandler.active) root.dragStart(index)
                  else root.dragEnd()
                }
              }
            }
          }
        }
      }
    }
  }
}