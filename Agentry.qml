import QtQuick
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

// What the widget knows about Agentry on this computer, read from the
// installed CLI: whether it is there and signed in, what `agentry doctor`
// finds, and the QuickAgents and schedules it keeps. Every read is a process
// the shell starts and waits for; the widget opens no network connection of
// its own, keeps no credential, and starts a run, a sign-in or a set-up only
// when the person clicks, in a terminal they can watch.
Item {
  id: root

  property var settings: ({})
  property bool panelOpen: false

  readonly property string configuredBin: String(setting("agentryBin", "") || "agentry")
  readonly property string registry: String(setting("registry", "") || "")
  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 300, 30, 3600)
  readonly property string site: registry !== "" ? registry.replace(/\/+$/, "") : "https://secureagentry.net"

  // One refresh has finished, so the bar may judge the state.
  property bool checked: false
  property bool refreshing: false
  // The CLI's resolved path, or "" when PATH has none.
  property string bin: ""
  property string desktopBin: ""
  readonly property bool installed: bin !== ""
  property string version: ""
  property bool signedIn: false
  property string account: ""
  property string tier: ""
  property string accountRegistry: ""
  property string accountError: ""
  property bool doctorChecked: false
  property bool ready: false
  property var checks: []
  property var failing: []
  property string readiness: "Not checked yet"
  property bool setupHelps: false
  property var quickagents: []
  property var schedules: []
  property string lastError: ""

  readonly property bool attention: checked && (!installed || !signedIn || (doctorChecked && !ready))
  readonly property bool busy: resolveProcess.running || versionProcess.running || whoamiProcess.running
    || listProcess.running || scheduleProcess.running || doctorProcess.running
  readonly property string tooltip: Model.barTooltip({
    checked: checked, installed: installed, signedIn: signedIn, account: account,
    quickagents: quickagents.length, schedules: schedules.length,
    doctorChecked: doctorChecked, ready: ready
  })

  property string _resolveOut: ""
  property string _versionOut: ""
  property string _whoamiOut: ""
  property string _whoamiErr: ""
  property string _listOut: ""
  property string _listErr: ""
  property string _scheduleOut: ""
  property string _scheduleErr: ""
  property string _doctorOut: ""
  property string _doctorErr: ""

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    return Math.max(min, Math.min(max, n))
  }

  function argv(args) {
    return Model.cliArgv(bin, registry, args)
  }

  // Reads everything again. The reads run one after another, each starting
  // the next when it exits, so the CLI is never asked two things at once.
  function refresh() {
    if (busy) return
    refreshing = true
    lastError = ""
    resolveProcess.running = true
  }

  function finish() {
    refreshing = false
    checked = true
  }

  function clearState() {
    version = ""
    signedIn = false
    account = ""
    tier = ""
    accountRegistry = ""
    accountError = ""
    quickagents = []
    schedules = []
    checks = []
    failing = []
    doctorChecked = false
    ready = false
    readiness = "Not checked yet"
    setupHelps = false
  }

  // Runs one CLI command in Omarchy's floating terminal, with Omarchy's own
  // wrapper, so the person sees every prompt the CLI asks and the result
  // stays on screen until they dismiss it. The arguments are quoted twice:
  // once for the shell this call starts, once for the shell the wrapper
  // starts inside the terminal.
  function inTerminal(args) {
    if (!installed) return
    var inner = argv(args).map(Util.shellQuote).join(" ")
    Util.execDetached("omarchy-launch-floating-terminal-with-presentation " + Util.shellQuote(inner))
  }

  function runQuickAgent(item) {
    inTerminal(["run", Model.runRef(item)])
  }

  function signIn() {
    inTerminal(["login"])
  }

  function setUp() {
    inTerminal(["setup"])
  }

  function doctorInTerminal() {
    inTerminal(["doctor"])
  }

  function openSearch() {
    Util.execArgv(["omarchy-launch-browser", site + "/search"])
  }

  function openDownload() {
    Util.execArgv(["omarchy-launch-browser", "https://secureagentry.net/download"])
  }

  function openDesktop() {
    if (desktopBin !== "") Util.execArgv([desktopBin])
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A login shell resolves the CLI the way the person's terminal would: the
  // installer puts it in ~/.local/bin, which the shell process's own PATH
  // may not have. The desktop app is looked up the same way.
  Process {
    id: resolveProcess
    running: false
    command: ["bash", "-lc", 'printf "%s\\n" "$(command -v -- "$1" 2>/dev/null)" "$(command -v -- agentry-desktop 2>/dev/null)"', "bash", root.configuredBin]
    stdout: StdioCollector {
      id: resolveOut
      waitForEnd: true
      onStreamFinished: root._resolveOut = text
    }
    onExited: function() {
      var lines = String(resolveOut.text || root._resolveOut || "").split("\n")
      root.bin = (lines[0] || "").trim()
      root.desktopBin = (lines[1] || "").trim()
      if (!root.installed) {
        root.clearState()
        root.finish()
        return
      }
      versionProcess.running = true
    }
  }

  Process {
    id: versionProcess
    running: false
    command: [root.bin, "--version"]
    stdout: StdioCollector {
      id: versionOut
      waitForEnd: true
      onStreamFinished: root._versionOut = text
    }
    onExited: function() {
      root.version = Model.parseVersion(String(versionOut.text || root._versionOut || ""))
      whoamiProcess.running = true
    }
  }

  Process {
    id: whoamiProcess
    running: false
    command: root.argv(["whoami"])
    stdout: StdioCollector {
      id: whoamiOut
      waitForEnd: true
      onStreamFinished: root._whoamiOut = text
    }
    stderr: StdioCollector {
      id: whoamiErr
      waitForEnd: true
      onStreamFinished: root._whoamiErr = text
    }
    onExited: function(exitCode) {
      var who = Model.parseWhoami(String(whoamiOut.text || root._whoamiOut || ""), String(whoamiErr.text || root._whoamiErr || ""), exitCode)
      root.signedIn = who.signedIn
      root.account = who.handle !== "" ? "@" + who.handle : who.email
      root.tier = who.tier
      root.accountRegistry = who.registry
      root.accountError = who.error
      listProcess.running = true
    }
  }

  Process {
    id: listProcess
    running: false
    command: root.argv(["list", "--json"])
    stdout: StdioCollector {
      id: listOut
      waitForEnd: true
      onStreamFinished: root._listOut = text
    }
    stderr: StdioCollector {
      id: listErr
      waitForEnd: true
      onStreamFinished: root._listErr = text
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.lastError = Model.conciseError(String(listErr.text || root._listErr || ""), "Could not list the installed QuickAgents")
      } else {
        var parsed = Model.parseInstalled(String(listOut.text || root._listOut || ""))
        if (parsed.ok) root.quickagents = parsed.items
        else root.lastError = parsed.error
      }
      scheduleProcess.running = true
    }
  }

  Process {
    id: scheduleProcess
    running: false
    command: root.argv(["schedule", "list", "--json"])
    stdout: StdioCollector {
      id: scheduleOut
      waitForEnd: true
      onStreamFinished: root._scheduleOut = text
    }
    stderr: StdioCollector {
      id: scheduleErr
      waitForEnd: true
      onStreamFinished: root._scheduleErr = text
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        if (root.lastError === "") root.lastError = Model.conciseError(String(scheduleErr.text || root._scheduleErr || ""), "Could not list the schedules")
      } else {
        var parsed = Model.parseSchedules(String(scheduleOut.text || root._scheduleOut || ""))
        if (parsed.ok) root.schedules = parsed.items
        else if (root.lastError === "") root.lastError = parsed.error
      }
      doctorProcess.running = true
    }
  }

  // doctor exits non-zero whenever a check fails, so its exit code is read
  // from the checks themselves.
  Process {
    id: doctorProcess
    running: false
    command: root.argv(["doctor", "--json"])
    stdout: StdioCollector {
      id: doctorOut
      waitForEnd: true
      onStreamFinished: root._doctorOut = text
    }
    stderr: StdioCollector {
      id: doctorErr
      waitForEnd: true
      onStreamFinished: root._doctorErr = text
    }
    onExited: function() {
      var doctor = Model.parseDoctor(String(doctorOut.text || root._doctorOut || ""), String(doctorErr.text || root._doctorErr || ""))
      root.doctorChecked = doctor.ok
      root.ready = doctor.ready
      root.checks = doctor.checks
      root.failing = doctor.failing
      root.readiness = Model.readinessSummary(doctor)
      root.setupHelps = Model.setupHelps(doctor)
      root.finish()
    }
  }
}
