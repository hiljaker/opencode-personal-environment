# Architecture

This repository is a reproducible personal OpenCode environment. It is the source of truth for intentionally portable OpenCode behavior and extensions, not a backup of machine state.

## Portable layers

- `opencode.jsonc`: seeded global OpenCode runtime/server baseline. It is written only when missing, so machine-local MCP configuration survives updates.
- `cli.json`: global CLI/TUI settings.
- `AGENTS.md`: baseline instructions.
- `agents/`: reusable agent profiles.
- `commands/`: reusable slash-command templates.
- `skills/`: on-demand domain/technology guidance.
- `plugins/`: optional local plugins.
- `tools/`: optional custom tools.
- `themes/`: optional themes.
- `scripts/checklist.sh`: generic keyboard checklist used by the installer.
- `scripts/optional.sh`: catalog, detection, and install recipes for third-party MCP servers and skills.

## Optional extensions

Third-party MCP servers and skills are not part of the managed file state. The repository stores only catalog metadata and install recipes; binaries and skill files are installed from their official sources with `curl` or `npx`.

Detection is read-only and runs before every install or update:

- MCP servers are detected from the global `opencode.jsonc` or `opencode.json` keys and from their binaries.
- Skills are detected from the OpenCode config `skills/` directory, `~/.claude/skills`, and `~/.agents/skills`, in that precedence order.
- An existing installation is never overwritten unless the user explicitly selects it for update.
- A skill copy in the OpenCode config directory shadows the canonical copy in `~/.agents/skills`. Selecting update updates the canonical copy, then moves the shadow copy into the backup directory.

## Machine-local layers

The following are deliberately not stored here:

- provider credentials and OAuth state;
- service passwords or API tokens;
- cache and session state;
- `node_modules/`;
- absolute paths to local projects;
- OS-specific application state.

Use OpenCode's provider authentication flow on each device.

## Install model

The installer copies managed portable files into the user's global OpenCode config directory. Existing managed files are backed up before replacement. Unmanaged files in that directory are preserved.

`opencode.jsonc` is a seed file, not a managed file. It is copied only when the destination does not exist, and it is never removed as stale. `--refresh-config` is the explicit opt-in to back it up and replace it with the repository baseline.

The installer records the managed file list and seed list in local state so uninstall/update can remove files that were previously managed even if a later repository revision changes the directory contents. Seed entries are recorded separately and uninstall skips them.

Optional MCP servers and skills are outside this state. Their own detection functions decide whether they are present, so updates and uninstalls do not touch them.
