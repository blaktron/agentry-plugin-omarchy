pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons
import qs.Ui

// The Agentry bar widget: the Agentry mark in the bar, a badge when something
// needs the person, and a panel with the account, the machine's readiness
// and the QuickAgents and schedules on this computer. The widget owns the
// state (Agentry.qml) so it keeps refreshing while the panel is closed; the
// panel is loaded once and reads from it.
BarWidget {
  id: root
  moduleName: "net.secureagentry.agentry"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color barForeground: bar ? bar.barForeground : Commons.Color.foreground

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function refresh() {
    agentry.refresh()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.agentry = agentry
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Agentry {
    id: agentry
    settings: root.settings
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: agentry.tooltip
    iconComponent: Component {
      Item {
        AgentryIcon {
          x: (parent.width - width) / 2
          y: (parent.height - height) / 2
          iconSize: button.iconSize
          color: agentry.installed || !agentry.checked ? root.barForeground : Qt.darker(root.barForeground, 1.55)
          badgeColor: root.urgent
          badgeTextColor: Commons.Color.background
          warning: agentry.attention
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.MiddleButton) agentry.refresh()
      else root.toggle()
    }
  }
}
