#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_BASE="${CONFIG_BASE%/}"
CONFIG_DIR="$CONFIG_BASE/opencode"
BACKUP_ROOT="$CONFIG_BASE/opencode-backups"
TIMESTAMP="$(date -u '+%Y%m%d-%H%M%S')"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
STATE_FILE="$CONFIG_DIR/.personal-opencode-environment-state"

ROOT_FILES=(
  "opencode.jsonc"
  "cli.json"
  "AGENTS.md"
)
MANAGED_DIRS=(
  "agents"
  "commands"
  "skills"
  "plugins"
  "tools"
  "themes"
)

SOURCE_FILES=()
for rel in "${ROOT_FILES[@]}"; do
  if [[ ! -f "$SCRIPT_DIR/$rel" ]]; then
    echo "Error: managed file missing: $rel" >&2
    exit 1
  fi
  SOURCE_FILES+=("$rel")
done

for dir in "${MANAGED_DIRS[@]}"; do
  [[ -d "$SCRIPT_DIR/$dir" ]] || continue
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    SOURCE_FILES+=("${file#$SCRIPT_DIR/}")
  done < <(find "$SCRIPT_DIR/$dir" -type f -print | LC_ALL=C sort)
done

if [[ "${#SOURCE_FILES[@]}" -eq 0 ]]; then
  echo "Error: no managed source files found." >&2
  exit 1
fi

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"

BACKED_UP=0
REMOVED_STALE=0

# Read the previous manifest so updates can remove files that this repository
# used to manage but no longer ships. Only files listed by our own state file
# are eligible for stale removal.
PREVIOUS_FILES=()
if [[ -f "$STATE_FILE" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == file=* ]]; then
      PREVIOUS_FILES+=("${line#file=}")
    elif [[ "$line" != *'='* ]]; then
      # Backward compatibility with schemaVersion=1 state, which stored
      # managed relative paths without a `file=` prefix.
      PREVIOUS_FILES+=("$line")
    fi
  done < "$STATE_FILE"
fi

is_current_file() {
  local candidate="$1"
  local rel
  for rel in "${SOURCE_FILES[@]}"; do
    [[ "$rel" == "$candidate" ]] && return 0
  done
  return 1
}

# Backup every existing managed file before replacing/removing it. The
# candidate list is built explicitly because expanding "${arr[@]}" on an
# empty array aborts under `set -u` in bash 3.2 (the macOS default).
BACKUP_CANDIDATES=()
if [[ "${#PREVIOUS_FILES[@]}" -gt 0 ]]; then
  BACKUP_CANDIDATES+=("${PREVIOUS_FILES[@]}")
fi
BACKUP_CANDIDATES+=("${SOURCE_FILES[@]}")
for rel in "${BACKUP_CANDIDATES[@]}"; do
  [[ -n "$rel" ]] || continue
  dest="$CONFIG_DIR/$rel"
  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    if [[ -L "$dest" ]]; then
      cp -P "$dest" "$BACKUP_DIR/$rel"
      rm -f "$dest"
    else
      cp -p "$dest" "$BACKUP_DIR/$rel"
    fi
    BACKED_UP=$((BACKED_UP + 1))
  fi
done

# Remove previously managed files that disappeared from the repository.
if [[ "${#PREVIOUS_FILES[@]}" -gt 0 ]]; then
  for rel in "${PREVIOUS_FILES[@]}"; do
    [[ -n "$rel" ]] || continue
    if ! is_current_file "$rel"; then
      dest="$CONFIG_DIR/$rel"
      if [[ -e "$dest" || -L "$dest" ]]; then
        rm -f "$dest"
        REMOVED_STALE=$((REMOVED_STALE + 1))
      fi
    fi
  done
fi

for rel in "${SOURCE_FILES[@]}"; do
  src="$SCRIPT_DIR/$rel"
  dest="$CONFIG_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -p "$src" "$dest"
done

# Local state is line-oriented and intentionally excluded from Git.
{
  printf 'schemaVersion=2\n'
  printf 'installedAt=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  for rel in "${SOURCE_FILES[@]}"; do
    printf 'file=%s\n' "$rel"
  done
} > "$STATE_FILE"

chmod 600 "$STATE_FILE" 2>/dev/null || true

OPEN_CODE_STATUS="not found"
if command -v opencode >/dev/null 2>&1; then
  OPEN_CODE_STATUS="$(opencode --version 2>/dev/null | head -n 1 || printf 'installed')"
fi

echo "OpenCode personal environment installed."
echo "  Config:           $CONFIG_DIR"
echo "  Files:            ${#SOURCE_FILES[@]}"
echo "  Backup:           $BACKUP_DIR"
echo "  Backed up:        $BACKED_UP"
echo "  Removed stale:    $REMOVED_STALE"
echo "  OpenCode:         $OPEN_CODE_STATUS"
echo
echo "Next: authenticate providers locally in OpenCode (for example, /connect), then select a model with /models."
