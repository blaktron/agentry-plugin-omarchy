# Agentry for Omarchy

An [Omarchy](https://omarchy.org) bar widget for Agentry. It puts the Agentry
mark in your bar and, behind it, a panel with your account, whether this
computer is ready to run QuickAgents, the QuickAgents installed here with a
Run button each, and your schedules. Everything it shows comes from the
Agentry CLI on your computer; everything it does, it does by opening a
terminal on that CLI, so you see every prompt and every result.

QuickAgents are signed, scanned agent packages with a declared capability
contract. The CLI keeps your sign-in and enforces each QuickAgent's contract;
the widget never sees a token. Documentation: https://docs.secureagentry.net/agentry/mcp/.

## What it shows

- **The bar**: the Agentry mark, dimmed when the CLI is missing, with a badge
  when something needs you (no CLI, not signed in, or a failing check).
- **Account**: who is signed in, or that only public QuickAgents are available.
- **This computer**: what `agentry doctor` finds (the runner policy, a model,
  Docker, the runtime images, the registry), with a Set up button when setting
  up the runner would fix it and a Check button that runs doctor in a terminal.
- **QuickAgents**: every QuickAgent installed on this computer, each with a Run
  button that opens a terminal on `agentry run` for exactly that version.
- **Schedules**: what runs when, soonest first.
- **Find QuickAgents** opens the registry's search in your browser, and
  **Open Agentry Desktop** appears when the desktop app is installed.

Left-click the mark to open or close the panel, middle-click to refresh.
In the panel, R refreshes and Escape closes.

## Install

```sh
omarchy plugin add https://github.com/blaktron/agentry-plugin-omarchy.git --enable
```

Omarchy warns you that plugins run unsandboxed inside its shell and asks you
to confirm; read the code first if you like, it is all in this repository.
The widget lands in the bar's right section. Move it with
`omarchy bar move net.secureagentry.agentry --section centerEnd`.

## Requirements

- Omarchy with the Quickshell shell (the one with `omarchy plugin`).
- The Agentry CLI on this computer, found through your login shell's PATH.
  Install it from https://secureagentry.net/download; the installer puts it in
  `~/.local/bin`. Without it the panel says so and offers the download page.
- Docker, for runs on this computer (`agentry setup` walks you through it).
- Omarchy's own `omarchy-launch-floating-terminal-with-presentation` and
  `omarchy-launch-browser`, which every Omarchy install has.

The widget runs only the Agentry CLI, the Agentry desktop app when you click
its button, and those two Omarchy launchers. It downloads nothing.

## Settings

Settings live on the widget's entry in `~/.config/omarchy/shell.json` and are
set with `omarchy bar set`:

```sh
omarchy bar set net.secureagentry.agentry refreshIntervalSec 600
omarchy bar set net.secureagentry.agentry agentryBin /home/you/.local/bin/agentry
omarchy bar set net.secureagentry.agentry registry https://registry.example.com
```

| Setting | Default | What it does |
| --- | --- | --- |
| `refreshIntervalSec` | 300 | How often the widget asks the CLI again (30 to 3600). |
| `agentryBin` | empty | A path to the CLI, when your login shell's PATH does not find it. |
| `registry` | empty | A registry URL passed to every CLI call; empty uses the CLI's default. |

## Removal

```sh
omarchy plugin remove net.secureagentry.agentry
```

That disables the widget and deletes this checkout from
`~/.config/omarchy/plugins/`. It changes nothing else: the CLI, its sign-in and
your QuickAgents stay as they were.

## Privacy

The widget sends nothing anywhere itself. The Agentry CLI talks to the
registry you signed in to, under its privacy policy: https://secureagentry.net/privacy.

## Licence

MIT, see [LICENSE](LICENSE).
