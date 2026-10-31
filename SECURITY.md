# Security policy

**Do not open a public issue for a security vulnerability.**

Email **security@secureagentry.net** with what you found, how to reproduce it
and what an attacker gains. A person reads every report within 2 business
days, sends an assessment within 5, and ships a fix or mitigation for high
and critical issues within 30 days. Credit goes in the advisory if you want
it. You can also report privately through this repository's Security tab.

This plugin runs inside the Omarchy shell with your user's permissions, as
every Omarchy plugin does. Of particular interest:

- **Running without a click**: the widget starting `agentry run`, `agentry
  login` or `agentry setup`, or any other command that changes something, on
  its own. It may only read (`--version`, `whoami`, `list`, `schedule list`,
  `doctor`) until you click.
- **Running the wrong program**: the widget starting anything other than the
  Agentry CLI it resolved on your PATH (or the path you set in its settings),
  the desktop app it found there, and Omarchy's own terminal and browser
  launchers.
- **Credential exposure**: the widget reading, storing or showing a token, a
  password or a model key. It never should: the CLI keeps your sign-in and the
  widget only asks it who you are.
- **Command injection**: a QuickAgent name, a schedule or anything else the CLI
  reports reaching a shell unquoted.

Malicious content in a QuickAgent is reported to the registry that serves it
(the report control on the QuickAgent's page), not here.
