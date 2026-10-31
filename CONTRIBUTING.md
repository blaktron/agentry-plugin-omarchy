# Contributing to the Agentry plugin for Omarchy

This repository holds the published Agentry plugin for Omarchy. Every file
in it is written by the release that publishes the plugin, so nothing is
changed here by hand, and a pull request cannot be merged as it stands.

## Issues

Issues are welcome here: a problem installing or enabling the plugin, a panel
that shows the wrong thing, a button that does not do what its label says, or
a listing detail that is wrong. Say which plugin version you have (the
`version` in `manifest.json`), your Omarchy version (`omarchy version`), the
output of `agentry --version`, and anything the shell's log says
(`omarchy-shell log` or `qs log`). Never paste a token, password or model key.

Other problems belong elsewhere:

- A QuickAgent that misbehaves: report it to the registry that serves it, with
  the report control on the QuickAgent's page.
- The Agentry CLI, which this widget drives:
  [blaktron/agentry-cli](https://github.com/blaktron/agentry-cli).

## Changes

Describe a fix in an issue, or show it in a pull request. A maintainer carries
it into the plugin's source, and it arrives here with the next release.

## Security

Never in a public issue or pull request. See [SECURITY.md](SECURITY.md).

## Code of Conduct

Everyone who takes part follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## Licence

MIT, see [LICENSE](LICENSE).
