#!/usr/bin/env bash
set -euo pipefail

CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_BASE="${CONFIG_BASE%/}"
CONFIG_DIR="$CONFIG_BASE/opencode"
STATE_FILE="$CONFIG_DIR/.personal-opencode-environment-state"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "No installation state found at: $STATE_FILE"
  exit 0
fi

REMOVED=0
while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  case "$rel" in
    schemaVersion=*|repository=*|installedAt=*) continue ;;
    file=*) rel="${rel#file=}" ;;
  esac
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
    schemaVersion=*|repository=*|installedAt=*) continue ;;
    file=*) rel="${rel#file=}" ;;
  esac
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
