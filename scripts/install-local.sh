#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_BASE="${CONFIG_BASE%/}"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$CONFIG_BASE/opencode}"
CONFIG_DIR="${CONFIG_DIR%/}"
BACKUP_ROOT="$CONFIG_BASE/opencode-backups"
TIMESTAMP="$(date -u '+%Y%m%d-%H%M%S')"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
STATE_FILE="$CONFIG_DIR/.personal-opencode-environment-state"

MANAGED_ROOT_FILES=(
  "cli.json"
  "AGENTS.md"
)
SEED_ROOT_FILES=(
  "opencode.jsonc"
)
MANAGED_DIRS=(
  "agents"
  "commands"
  "skills"
  "plugins"
  "tools"
  "themes"
)

NO_OPTIONAL=0
WITH_ITEMS=""
LIST_OPTIONAL=0
DRY_RUN=0
REFRESH_CONFIG=0
ASSUME_YES=0
OPTIONAL_FAILED=0

usage() {
  cat <<USAGE
Usage:
  ./install.sh [options]
  curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/<ref>/install.sh | bash -s -- [options]

Options:
  --no-optional       Skip optional MCP servers and skills.
  --with LIST         Comma-separated optional items (kind:id).
  --list-optional     List optional items and their detection status.
  --dry-run           Show planned actions without writing.
  --refresh-config    Back up and replace opencode.jsonc with the repo baseline.
  --yes               Skip the confirmation screen.
  --help              Show this help.

Optional item IDs:
  mcp:codebase-memory-mcp
  mcp:browse
  skill:frontend-design
  skill:impeccable
  skill:security-audit
  skill:vercel-react-best-practices

Environment overrides:
  XDG_CONFIG_HOME      Base config directory (default: ~/.config).
  OPENCODE_CONFIG_DIR  OpenCode config directory (overrides XDG_CONFIG_HOME/opencode).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-optional)
      NO_OPTIONAL=1
      shift
      ;;
    --with)
      if [[ $# -lt 2 ]]; then
        echo "Error: --with requires a value." >&2
        exit 1
      fi
      WITH_ITEMS="$2"
      shift 2
      ;;
    --with=*)
      WITH_ITEMS="${1#*=}"
      shift
      ;;
    --list-optional)
      LIST_OPTIONAL=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --refresh-config)
      REFRESH_CONFIG=1
      shift
      ;;
    --yes|-y)
      ASSUME_YES=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$LIST_OPTIONAL" -eq 1 ]]; then
  # shellcheck source=scripts/optional.sh
  source "$SCRIPT_DIR/scripts/optional.sh"
  optional_list
  exit 0
fi

SOURCE_FILES=()
for rel in "${MANAGED_ROOT_FILES[@]}"; do
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

SEED_FILES=()
for rel in "${SEED_ROOT_FILES[@]}"; do
  if [[ -f "$SCRIPT_DIR/$rel" ]]; then
    SEED_FILES+=("$rel")
  elif [[ "$REFRESH_CONFIG" -eq 1 ]]; then
    echo "Error: seed file missing: $rel" >&2
    exit 1
  fi
done

is_current_file() {
  local candidate="$1"
  local rel
  for rel in "${SOURCE_FILES[@]}"; do
    [[ "$rel" == "$candidate" ]] && return 0
  done
  return 1
}

# Seed files are machine-local after the first copy. Never treat them as stale
# and never remove them through the state file.
is_seed_path() {
  local candidate="$1"
  local rel
  [[ "$candidate" == "opencode.jsonc" ]] && return 0
  for rel in "${SEED_FILES[@]}"; do
    [[ "$rel" == "$candidate" ]] && return 0
  done
  return 1
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run: no files will be written."
  echo "  Config:        $CONFIG_DIR"
  echo "  Managed files: ${#SOURCE_FILES[@]}"
  echo "  Seed files:    ${#SEED_FILES[@]}"
  for rel in "${SOURCE_FILES[@]}"; do
    echo "  would copy:    $rel"
  done
  for rel in "${SEED_FILES[@]}"; do
    if [[ -e "$CONFIG_DIR/$rel" || -L "$CONFIG_DIR/$rel" ]]; then
      if [[ "$REFRESH_CONFIG" -eq 1 ]]; then
        echo "  would refresh: $rel"
      else
        echo "  would keep:    $rel"
      fi
    else
      echo "  would create:  $rel"
    fi
  done
else
  mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
fi

BACKED_UP=0
REMOVED_STALE=0
SEED_CREATED=0
SEED_REFRESHED=0
SEED_KEPT=0

# Read the previous manifest so updates can remove files that this repository
# used to manage but no longer ships. Only files listed by our own state file
# are eligible for stale removal.
PREVIOUS_FILES=()
if [[ -f "$STATE_FILE" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    case "$line" in
      file=*)
        PREVIOUS_FILES+=("${line#file=}")
        ;;
      seed=*|optional=*|schemaVersion=*|repository=*|installedAt=*)
        ;;
      *'='*)
        ;;
      *)
        # Backward compatibility with schemaVersion=1 state, which stored
        # managed relative paths without a `file=` prefix.
        PREVIOUS_FILES+=("$line")
        ;;
    esac
  done < "$STATE_FILE"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  # Backup every existing managed file before replacing/removing it. The
  # candidate list is built explicitly because expanding "${arr[@]}" on an
  # empty array aborts under `set -u` in bash 3.2 (the macOS default).
  BACKUP_CANDIDATES=()
  if [[ "${#PREVIOUS_FILES[@]}" -gt 0 ]]; then
    BACKUP_CANDIDATES+=("${PREVIOUS_FILES[@]}")
  fi
  BACKUP_CANDIDATES+=("${SOURCE_FILES[@]}")
  if [[ "$REFRESH_CONFIG" -eq 1 ]]; then
    for rel in "${SEED_FILES[@]}"; do
      BACKUP_CANDIDATES+=("$rel")
    done
  fi
  BACKUP_SEEN=()
  for rel in "${BACKUP_CANDIDATES[@]}"; do
    [[ -n "$rel" ]] || continue
    if is_seed_path "$rel" && [[ "$REFRESH_CONFIG" -ne 1 ]]; then
      continue
    fi
    skip=0
    if [[ "${#BACKUP_SEEN[@]}" -gt 0 ]]; then
      for seen in "${BACKUP_SEEN[@]}"; do
        if [[ "$seen" == "$rel" ]]; then
          skip=1
          break
        fi
      done
    fi
    [[ "$skip" -eq 1 ]] && continue
    BACKUP_SEEN+=("$rel")
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
      if is_seed_path "$rel"; then
        continue
      fi
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

  for rel in "${SEED_FILES[@]}"; do
    src="$SCRIPT_DIR/$rel"
    dest="$CONFIG_DIR/$rel"
    if [[ -e "$dest" || -L "$dest" ]]; then
      if [[ "$REFRESH_CONFIG" -eq 1 ]]; then
        mkdir -p "$(dirname "$dest")"
        cp -p "$src" "$dest"
        SEED_REFRESHED=$((SEED_REFRESHED + 1))
      else
        SEED_KEPT=$((SEED_KEPT + 1))
      fi
    else
      mkdir -p "$(dirname "$dest")"
      cp -p "$src" "$dest"
      SEED_CREATED=$((SEED_CREATED + 1))
    fi
  done

  # Local state is line-oriented and intentionally excluded from Git.
  {
    printf 'schemaVersion=2\n'
    printf 'installedAt=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    for rel in "${SEED_FILES[@]}"; do
      printf 'seed=%s\n' "$rel"
    done
    for rel in "${SOURCE_FILES[@]}"; do
      printf 'file=%s\n' "$rel"
    done
  } > "$STATE_FILE"

  chmod 600 "$STATE_FILE" 2>/dev/null || true
fi

OPEN_CODE_STATUS="not found"
if command -v opencode >/dev/null 2>&1; then
  OPEN_CODE_STATUS="$(opencode --version 2>/dev/null | head -n 1 || printf 'installed')"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run completed. No files were written."
else
  echo "OpenCode personal environment installed."
  echo "  Config:           $CONFIG_DIR"
  echo "  Managed files:    ${#SOURCE_FILES[@]}"
  echo "  Seed files:       ${#SEED_FILES[@]} (created $SEED_CREATED, refreshed $SEED_REFRESHED, kept $SEED_KEPT)"
  echo "  Backup:           $BACKUP_DIR"
  echo "  Backed up:        $BACKED_UP"
  echo "  Removed stale:    $REMOVED_STALE"
  echo "  OpenCode:         $OPEN_CODE_STATUS"
fi

if [[ "$NO_OPTIONAL" -eq 0 ]]; then
  # shellcheck source=scripts/optional.sh
  source "$SCRIPT_DIR/scripts/optional.sh"
  if ! optional_main; then
    echo "Warning: optional extension setup did not complete." >&2
    OPTIONAL_FAILED=1
  fi
fi

echo
echo "Next: authenticate providers locally in OpenCode (for example, /connect), then select a model with /models."

if [[ "$OPTIONAL_FAILED" -eq 1 ]]; then
  exit 1
fi
