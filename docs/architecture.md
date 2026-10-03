# Architecture

This repository is a reproducible personal OpenCode environment. It is the source of truth for intentionally portable OpenCode behavior and extensions, not a backup of machine state.

## Portable layers

- `opencode.jsonc`: global OpenCode runtime/server configuration.
- `cli.json`: global CLI/TUI settings.
- `AGENTS.md`: baseline instructions.
- `agents/`: reusable agent profiles.
- `commands/`: reusable slash-command templates.
- `skills/`: on-demand domain/technology guidance.
- `plugins/`: optional local plugins.
- `tools/`: optional custom tools.
- `themes/`: optional themes.

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

The installer copies only managed portable files into the user's global OpenCode config directory. Existing managed files are backed up before replacement. Unmanaged files in that directory are preserved.

The installer records the installed file list in local state so uninstall/update can remove files that were previously managed even if a later repository revision changes the directory contents.
