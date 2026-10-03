#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_BASE="${CONFIG_BASE%/}"
CONFIG_DIR="$CONFIG_BASE/opencode"

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
