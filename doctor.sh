#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_BASE="${CONFIG_BASE%/}"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$CONFIG_BASE/opencode}"
CONFIG_DIR="${CONFIG_DIR%/}"

fail=0

pass() { printf 'PASS  %s\n' "$1"; }
fail_check() { printf 'FAIL  %s\n' "$1"; fail=1; }

for rel in opencode.jsonc cli.json AGENTS.md manifest.json README.md; do
  if [[ -f "$SCRIPT_DIR/$rel" ]]; then pass "$rel exists"; else fail_check "$rel is missing"; fi
done
for dir in agents skills commands; do
  if [[ -d "$SCRIPT_DIR/$dir" ]]; then pass "$dir directory exists"; else fail_check "$dir directory is missing"; fi
done

while IFS= read -r file; do
  first_line="$(head -n 1 "$file")"
  if [[ "$first_line" != '---' ]]; then
    fail_check "missing skill frontmatter: ${file#$SCRIPT_DIR/}"
  fi
  skill_dir="$(basename "$(dirname "$file")")"
  if [[ ! "$skill_dir" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    fail_check "invalid skill directory name: $skill_dir"
  fi
done < <(find "$SCRIPT_DIR/skills" -type f -name SKILL.md -print | LC_ALL=C sort)

while IFS= read -r file; do
  first_line="$(head -n 1 "$file")"
  if [[ "$first_line" != '---' ]]; then
    fail_check "missing agent frontmatter: ${file#$SCRIPT_DIR/}"
  fi
  if grep -qE '^permission:' "$file"; then
    fail_check "legacy 'permission' frontmatter (use native 'permissions'): ${file#$SCRIPT_DIR/}"
  fi
  if ! grep -qE '^permissions:' "$file"; then
    fail_check "missing native 'permissions' frontmatter: ${file#$SCRIPT_DIR/}"
  fi
  if ! grep -qE '^mode: (primary|subagent)$' "$file"; then
    fail_check "missing or invalid 'mode' frontmatter: ${file#$SCRIPT_DIR/}"
  fi
done < <(find "$SCRIPT_DIR/agents" -type f -name '*.md' -print | LC_ALL=C sort)

if [[ -d "$SCRIPT_DIR/commands" ]]; then
  while IFS= read -r file; do
    agent_name="$(awk '/^agent:/ { sub(/^agent:[[:space:]]*/, ""); print; exit }' "$file")"
    [[ -n "$agent_name" ]] || continue
    target="$SCRIPT_DIR/agents/$agent_name.md"
    if [[ ! -f "$target" ]]; then
      fail_check "command references missing agent '$agent_name': ${file#$SCRIPT_DIR/}"
    elif ! grep -qE '^mode: primary$' "$target"; then
      fail_check "command references non-primary agent '$agent_name': ${file#$SCRIPT_DIR/}"
    fi
  done < <(find "$SCRIPT_DIR/commands" -type f -name '*.md' -print | LC_ALL=C sort)
fi

for script in "$SCRIPT_DIR/install.sh" "$SCRIPT_DIR/uninstall.sh" "$SCRIPT_DIR/doctor.sh" "$SCRIPT_DIR/scripts/"*.sh; do
  [[ -f "$script" ]] || continue
  if bash -n "$script" 2>/dev/null; then
    pass "syntax: ${script#$SCRIPT_DIR/}"
  else
    fail_check "syntax error: ${script#$SCRIPT_DIR/}"
  fi
done

if grep -q '"seed"' "$SCRIPT_DIR/manifest.json"; then
  pass 'manifest defines seed files'
else
  fail_check 'manifest does not define seed files'
fi

if grep -q 'SEED_ROOT_FILES=' "$SCRIPT_DIR/scripts/install-local.sh"; then
  pass 'installer defines seed files'
else
  fail_check 'installer does not define seed files'
fi

if [[ -f "$SCRIPT_DIR/scripts/optional.sh" ]]; then
  # shellcheck source=scripts/optional.sh
  source "$SCRIPT_DIR/scripts/optional.sh"
  if [[ "${#OPTIONAL_KINDS[@]}" -eq "${#OPTIONAL_IDS[@]}" && "${#OPTIONAL_IDS[@]}" -eq "${#OPTIONAL_LABELS[@]}" && "${#OPTIONAL_IDS[@]}" -eq "${#OPTIONAL_DESCRIPTIONS[@]}" && "${#OPTIONAL_IDS[@]}" -eq "${#OPTIONAL_SKILL_SOURCES[@]}" ]]; then
    pass 'optional catalog arrays are consistent'
  else
    fail_check 'optional catalog arrays have different lengths'
  fi
  seen=""
  for id in "${OPTIONAL_IDS[@]}"; do
    case " $seen " in
      *" $id "*) fail_check "duplicate optional id: $id" ;;
    esac
    seen="$seen $id"
  done
  for kind in "${OPTIONAL_KINDS[@]}"; do
    case "$kind" in
      mcp|skill) ;;
      *) fail_check "invalid optional kind: $kind" ;;
    esac
  done
  for i in "${!OPTIONAL_IDS[@]}"; do
    if [[ "${OPTIONAL_KINDS[$i]}" == "skill" && -z "${OPTIONAL_SKILL_SOURCES[$i]}" ]]; then
      fail_check "optional skill missing source: ${OPTIONAL_IDS[$i]}"
    fi
  done
fi

if grep -RniE 'ayopajak|purwadhika|garda bina utama|\btax\b|\bpajak\b|e[- ]?faktur|e[- ]?bupot|\bcoretax\b|\bpjap\b' "$SCRIPT_DIR/skills" >/dev/null 2>&1; then
  fail_check 'project/domain-specific references detected in skills'
else
  pass 'skills contain no known project/domain-specific references'
fi

if [[ -d "$CONFIG_DIR" ]]; then
  pass "OpenCode config directory exists: $CONFIG_DIR"
else
  printf 'INFO  OpenCode config directory does not exist yet: %s\n' "$CONFIG_DIR"
fi

if command -v opencode >/dev/null 2>&1; then
  version="$(opencode --version 2>/dev/null || true)"
  printf 'INFO  OpenCode: %s\n' "${version:-version unavailable}"
else
  printf 'INFO  OpenCode CLI not found on PATH\n'
fi

if [[ "$fail" -ne 0 ]]; then exit 1; fi
printf '\nDoctor check completed successfully.\n'
