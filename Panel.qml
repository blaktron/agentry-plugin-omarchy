pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The panel under the Agentry bar button: the account, the machine's
// readiness, the QuickAgents installed on this computer with a Run button
// each, and the schedules. The bar widget owns the state and hands it over as
// `agentry`; the panel reads it and asks it to act.
Panel {
  id: root
  moduleName: "net.secureagentry.agentry"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var agentry: null

  readonly property color foreground: Commons.Color.popups.text
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  property double nowMs: Date.now()

  readonly property bool checked: agentry ? agentry.checked : false
  readonly property bool refreshing: agentry ? agentry.refreshing : false
  readonly property bool installed: agentry ? agentry.installed : false
  readonly property string version: agentry ? agentry.version : ""
  readonly property bool signedIn: agentry ? agentry.signedIn : false
  readonly property string account: agentry ? agentry.account : ""
  readonly property string tier: agentry ? agentry.tier : ""
  readonly property string accountError: agentry ? agentry.accountError : ""
  readonly property bool doctorChecked: agentry ? agentry.doctorChecked : false
  readonly property bool ready: agentry ? agentry.ready : false
  readonly property var failing: agentry ? agentry.failing : []
  readonly property string readiness: agentry ? agentry.readiness : ""
  readonly property bool setupHelps: agentry ? agentry.setupHelps : false
  readonly property var quickagents: agentry ? agentry.quickagents : []
  readonly property var schedules: agentry ? agentry.schedules : []
  readonly property string lastError: agentry ? agentry.lastError : ""
  readonly property bool hasDesktop: agentry ? agentry.desktopBin !== "" : false

  readonly property string accountLine: !checked ? "Checking…"
    : !installed ? "The Agentry CLI is not installed"
    : signedIn ? account + (tier !== "" ? " · " + tier : "")
    : "Not signed in · public QuickAgents only"
  readonly property string versionLine: !installed ? "" : version !== "" ? "CLI " + version : "CLI"

  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function") return bar.switchPanelFrom(hostWidget || root, direction)
    return false
  }

  function refresh() {
    nowMs = Date.now()
    if (agentry) agentry.refresh()
  }

  onOpenedChanged: {
    if (agentry) agentry.panelOpen = opened
    if (opened) refresh()
  }

  Timer {
    interval: 30000
    repeat: true
    running: root.opened
    onTriggered: root.nowMs = Date.now()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(560))

    content: PanelKeyCatcher {
      id: keyCatcher
      implicitHeight: column.implicitHeight
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refresh()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          PanelHero {
            id: hero
            width: parent.width
            title: "Agentry"
            meta: root.accountLine
            detail: root.versionLine
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: root.installed || !root.checked ? 1.0 : 0.5
            iconComponent: Component {
              AgentryIcon {
                iconSize: Style.font.display
                color: root.foreground
                badgeColor: root.urgent
                badgeTextColor: Commons.Color.popups.background
                warning: root.checked && root.installed && (!root.signedIn || (root.doctorChecked && !root.ready))
              }
            }
            trailingControl: Component {
              PanelActionButton {
                iconText: "↻"
                tooltipText: root.refreshing ? "Refreshing…" : "Refresh (R)"
                foreground: hero.foreground
                fontFamily: hero.fontFamily
                enabled: !root.refreshing
                opacity: root.refreshing ? 0.5 : 1.0
                onClicked: root.refresh()
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: root.lastError !== "" || root.accountError !== ""
            width: parent.width
            text: root.lastError !== "" ? root.lastError : root.accountError
            color: root.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          // The CLI is missing: say where it comes from and offer the page.
          Column {
            visible: root.checked && !root.installed
            width: parent.width
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: "Install the Agentry CLI, then refresh. If it is installed somewhere PATH does not reach, set its path in this widget's settings (agentryBin)."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }

            Button {
              text: "Download page"
              iconText: "⇩"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.agentry) root.agentry.openDownload()
            }
          }

          PanelSeparator {
            visible: root.installed
            foreground: root.foreground
          }

          // Readiness: what `agentry doctor` found, and the way to fix it.
          Column {
            visible: root.installed
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "This computer"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: root.readiness
              color: root.doctorChecked && !root.ready ? root.urgent : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }

            Repeater {
              model: root.failing
              Text {
                required property var modelData
                textFormat: Text.PlainText
                width: parent.width
                text: modelData.name + ": " + modelData.detail
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(8)

              Button {
                visible: !root.signedIn
                text: "Sign in"
                iconText: "→"
                bordered: true
                tooltipText: "Runs agentry login in a terminal"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: if (root.agentry) root.agentry.signIn()
              }

              Button {
                visible: root.setupHelps
                text: "Set up"
                iconText: "⚙"
                bordered: true
                tooltipText: "Runs agentry setup in a terminal"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: if (root.agentry) root.agentry.setUp()
              }

              Button {
                text: "Check"
                iconText: "✓"
                bordered: true
                tooltipText: "Runs agentry doctor in a terminal"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: if (root.agentry) root.agentry.doctorInTerminal()
              }
            }
          }

          PanelSeparator {
            visible: root.installed
            foreground: root.foreground
          }

          // The QuickAgents installed for the runner, each with a Run button.
          Column {
            visible: root.installed
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: root.quickagents.length > 0 ? "QuickAgents · " + root.quickagents.length : "QuickAgents"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              textFormat: Text.PlainText
              visible: root.checked && root.quickagents.length === 0
              width: parent.width
              text: "No QuickAgents are installed on this computer yet."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }

            Repeater {
              model: root.quickagents
              Item {
                id: quickagentRow
                required property var modelData
                width: parent.width
                implicitHeight: Math.max(quickagentLabels.implicitHeight, runButton.implicitHeight)

                Column {
                  id: quickagentLabels
                  anchors.left: parent.left
                  anchors.right: runButton.left
                  anchors.rightMargin: Style.space(10)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: quickagentRow.modelData.ref
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideMiddle
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: quickagentRow.modelData.version + (quickagentRow.modelData.local ? " · local" : "")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                Button {
                  id: runButton
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Run"
                  iconText: "▶"
                  bordered: true
                  tooltipText: "Runs " + Model.runRef(quickagentRow.modelData) + " in a terminal"
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  onClicked: if (root.agentry) root.agentry.runQuickAgent(quickagentRow.modelData)
                }
              }
            }
          }

          PanelSeparator {
            visible: root.installed && root.schedules.length > 0
            foreground: root.foreground
          }

          // Schedules, soonest first.
          Column {
            visible: root.installed && root.schedules.length > 0
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: "Schedules · " + root.schedules.length
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.schedules
              Item {
                id: scheduleRow
                required property var modelData
                width: parent.width
                implicitHeight: scheduleLabels.implicitHeight

                readonly property string when: modelData.ended ? "ended"
                  : modelData.paused ? "paused"
                  : Model.relativeTime(modelData.nextMs, root.nowMs)

                Column {
                  id: scheduleLabels
                  anchors.left: parent.left
                  anchors.right: scheduleWhen.left
                  anchors.rightMargin: Style.space(10)

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: scheduleRow.modelData.name
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideMiddle
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: scheduleRow.modelData.describe
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                Text {
                  id: scheduleWhen
                  textFormat: Text.PlainText
                  anchors.right: parent.right
                  anchors.top: parent.top
                  text: scheduleRow.when
                  color: scheduleRow.modelData.ended || scheduleRow.modelData.paused ? root.dim : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }
            }
          }

          PanelSeparator {
            visible: root.installed
            foreground: root.foreground
          }

          Flow {
            visible: root.installed
            width: parent.width
            spacing: Style.space(8)

            Button {
              text: "Find QuickAgents"
              iconText: "⌕"
              bordered: true
              tooltipText: "Opens the registry's search in your browser"
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.agentry) root.agentry.openSearch()
            }

            Button {
              visible: root.hasDesktop
              text: "Open Agentry Desktop"
              iconText: "▣"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.agentry) root.agentry.openDesktop()
            }
          }
        }
      }
    }
  }
}
