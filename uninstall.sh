#!/usr/bin/env bash
set -euo pipefail

CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_BASE="${CONFIG_BASE%/}"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$CONFIG_BASE/opencode}"
CONFIG_DIR="${CONFIG_DIR%/}"
STATE_FILE="$CONFIG_DIR/.personal-opencode-environment-state"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No installation state found at: $STATE_FILE"
  exit 0
fi

REMOVED=0
while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  case "$rel" in
    schemaVersion=*|repository=*|installedAt=*|seed=*|optional=*) continue ;;
    file=*) rel="${rel#file=}" ;;
  esac
  # opencode.jsonc is a seed file. It may contain machine-local MCP entries,
  # so uninstall must never remove it, even when an old state file lists it.
  [[ "$rel" == "opencode.jsonc" ]] && continue
  target="$CONFIG_DIR/$rel"
  if [[ -f "$target" || -L "$target" ]]; then
    rm -f "$target"
    REMOVED=$((REMOVED + 1))
  fi
done < "$STATE_FILE"

# Remove empty directories from the deepest level without touching the config root.
while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  case "$rel" in
    schemaVersion=*|repository=*|installedAt=*|seed=*|optional=*) continue ;;
    file=*) rel="${rel#file=}" ;;
  esac
  [[ "$rel" == "opencode.jsonc" ]] && continue
  dir="$CONFIG_DIR/$(dirname "$rel")"
  while [[ "$dir" != "$CONFIG_DIR" && "$dir" == "$CONFIG_DIR"/* ]]; do
    rmdir "$dir" 2>/dev/null || break
    dir="$(dirname "$dir")"
  done
done < "$STATE_FILE"

rm -f "$STATE_FILE"

echo "OpenCode environment uninstalled."
echo "  Removed files: $REMOVED"
echo "  Backups remain under: $CONFIG_BASE/opencode-backups"
echo
echo "Optional MCP servers and skills installed from third-party sources are not removed."
echo "Manage them with their own tools, or remove them from the OpenCode config manually."
