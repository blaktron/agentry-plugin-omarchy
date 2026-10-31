.pragma library

// Pure functions over what the Agentry CLI prints, kept out of the QML so
// they can be tested on their own. Each parser takes the text as the process
// gave it and answers an object the panel binds to; a parse that fails
// answers an error field instead of throwing.

function parseJson(text) {
  try {
    return { ok: true, value: JSON.parse(String(text || "")) }
  } catch (e) {
    return { ok: false, error: "unreadable output: " + e.message }
  }
}

// The first line of an error, without the CLI's own name in front, short
// enough for a panel row.
function conciseError(text, fallback) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim().replace(/^agentry:\s*/, "")
    if (line === "") continue
    return line.length > 160 ? line.slice(0, 157) + "…" : line
  }
  return fallback
}

// "agentry version 0.6.1004" on the first line of `agentry --version`.
function parseVersion(text) {
  var m = /^agentry version\s+(\S+)/m.exec(String(text || ""))
  return m ? m[1] : ""
}

// `agentry whoami` prints "key:   value" lines (registry, handle, email,
// tier, …). It exits 2 with "no credential stored" when nobody is signed in,
// which is a state, not an error; any other failure is reported.
function parseWhoami(stdout, stderr, exitCode) {
  var out = { signedIn: false, handle: "", email: "", registry: "", tier: "", error: "" }
  if (exitCode !== 0) {
    var err = String(stderr || "").trim()
    if (!/no credential stored/i.test(err)) out.error = conciseError(err, "Could not read the account")
    return out
  }
  var lines = String(stdout || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^([a-z]+):\s*(.*)$/.exec(lines[i])
    if (!m) continue
    var value = m[2].trim()
    if (m[1] === "handle") out.handle = value
    else if (m[1] === "email") out.email = value
    else if (m[1] === "registry") out.registry = value
    else if (m[1] === "tier") out.tier = value
  }
  out.signedIn = out.handle !== "" || out.email !== ""
  return out
}

// `agentry list --json`: every install record on this computer. The panel
// shows the ones `agentry run` can start, which are the runner's installs
// whose directory is still there.
function parseInstalled(text) {
  var p = parseJson(text)
  if (!p.ok) return { ok: false, error: p.error, items: [] }
  var records = p.value && Array.isArray(p.value.records) ? p.value.records : []
  var items = []
  for (var i = 0; i < records.length; i++) {
    var r = records[i] || {}
    if (r.target !== "runner" || r.present === false) continue
    if (!r.namespace || !r.name) continue
    items.push({
      ref: r.namespace + "/" + r.name,
      namespace: String(r.namespace),
      name: String(r.name),
      version: String(r.version || ""),
      installedAt: String(r.installedAt || ""),
      local: r.source === "local"
    })
  }
  items.sort(function(a, b) { return a.ref < b.ref ? -1 : a.ref > b.ref ? 1 : 0 })
  return { ok: true, items: items }
}

// The ref `agentry run` takes for an installed QuickAgent: the exact version
// that is installed, so a run never resolves to something newer by surprise.
function runRef(item) {
  return item.version ? item.ref + "@" + item.version : item.ref
}

// `agentry schedule list --json`: one entry per schedule, with the CLI's own
// description of its recurrence and the next occurrence. Live schedules come
// first, soonest first; paused and ended ones after.
function parseSchedules(text) {
  var p = parseJson(text)
  if (!p.ok) return { ok: false, error: p.error, items: [] }
  var list = Array.isArray(p.value) ? p.value : []
  var items = []
  for (var i = 0; i < list.length; i++) {
    var s = list[i] || {}
    var nextMs = s.next ? Date.parse(s.next) : NaN
    items.push({
      id: String(s.id || ""),
      name: String(s.name || s.ref || s.id || ""),
      ref: String(s.ref || s.local || ""),
      describe: String(s.describe || ""),
      nextMs: isFinite(nextMs) ? nextMs : 0,
      ended: s.ended === true,
      paused: s.paused === true,
      alarm: s.alarm === true,
      alarmUnknown: s.alarmUnknown === true,
      runs: typeof s.runs === "number" ? s.runs : 0
    })
  }
  items.sort(function(a, b) {
    var la = a.ended || a.paused ? 1 : 0
    var lb = b.ended || b.paused ? 1 : 0
    if (la !== lb) return la - lb
    var na = a.nextMs || Number.MAX_VALUE
    var nb = b.nextMs || Number.MAX_VALUE
    return na - nb
  })
  return { ok: true, items: items }
}

// `agentry doctor --json`: the checks and what each found. The command exits
// non-zero when a check fails, so the exit code says nothing the checks do
// not; an empty or unreadable answer is the error.
function parseDoctor(stdout, stderr) {
  var p = parseJson(stdout)
  var checks = p.ok && p.value && Array.isArray(p.value.checks) ? p.value.checks : null
  if (!checks) {
    return { ok: false, error: conciseError(stderr, p.ok ? "doctor printed no checks" : p.error), checks: [], ready: false, failing: [] }
  }
  var out = []
  var failing = []
  for (var i = 0; i < checks.length; i++) {
    var c = checks[i] || {}
    var check = { name: String(c.name || ""), status: String(c.status || ""), detail: String(c.detail || "") }
    out.push(check)
    if (check.status !== "ok") failing.push(check)
  }
  return { ok: true, error: "", checks: out, ready: failing.length === 0, failing: failing }
}

// One line for the readiness row.
function readinessSummary(doctor) {
  if (!doctor || !doctor.ok) return doctor && doctor.error ? doctor.error : "Not checked yet"
  if (doctor.ready) return "Ready to run QuickAgents"
  var names = []
  for (var i = 0; i < doctor.failing.length; i++) names.push(doctor.failing[i].name)
  return "Needs attention: " + names.join(", ")
}

// Setting up the runner is the cure for a missing policy or model; anything
// else doctor reports (Docker, images, the registry) is for the person to
// read, so the panel offers Set up only when it would help.
function setupHelps(doctor) {
  if (!doctor || !doctor.ok) return false
  for (var i = 0; i < doctor.failing.length; i++) {
    var n = doctor.failing[i].name
    if (n === "policy" || n === "model" || n === "secretSource") return true
  }
  return false
}

// The argv for one CLI call, with the registry the person configured.
function cliArgv(bin, registry, args) {
  var argv = [bin]
  if (registry) argv.push("--registry", registry)
  return argv.concat(args)
}

// "in 5 min", "in 3 h", "in 2 d"; "due" once the time has passed.
function relativeTime(ms, nowMs) {
  if (!ms) return ""
  var delta = Math.round((ms - nowMs) / 1000)
  if (delta <= 30) return "due"
  if (delta < 3600) return "in " + Math.max(1, Math.round(delta / 60)) + " min"
  if (delta < 86400) return "in " + Math.round(delta / 3600) + " h"
  return "in " + Math.round(delta / 86400) + " d"
}

function plural(n, one, many) {
  return n + " " + (n === 1 ? one : many)
}

// The bar button's tooltip, one line.
function barTooltip(state) {
  if (!state.checked) return "Agentry"
  if (!state.installed) return "Agentry: the CLI is not installed"
  var parts = []
  parts.push(state.signedIn ? (state.account || "signed in") : "not signed in")
  parts.push(plural(state.quickagents, "QuickAgent", "QuickAgents"))
  if (state.schedules > 0) parts.push(plural(state.schedules, "schedule", "schedules"))
  if (state.doctorChecked && !state.ready) parts.push("needs attention")
  return "Agentry: " + parts.join(" · ")
}
