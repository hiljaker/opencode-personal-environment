#!/usr/bin/env bash
# Optional third-party MCP servers and skills.
#
# This file is sourced by scripts/install-local.sh and doctor.sh. It stores
# catalog metadata and install recipes only; third-party artifacts are never
# written to this repository.

# shellcheck source=scripts/checklist.sh
source "$SCRIPT_DIR/scripts/checklist.sh"

OPTIONAL_KINDS=(mcp mcp skill skill skill skill)
OPTIONAL_IDS=(codebase-memory-mcp browse frontend-design impeccable security-audit vercel-react-best-practices)
OPTIONAL_LABELS=(codebase-memory browse frontend-design impeccable security-audit vercel-react-best-practices)
OPTIONAL_DESCRIPTIONS=(
  "Codebase knowledge graph MCP server"
  "Browser automation MCP server"
  "Anthropic frontend design guidance"
  "Frontend design and UX review"
  "Cloudflare security audit"
  "Vercel React and Next.js performance rules"
)
OPTIONAL_SKILL_SOURCES=(
  ""
  ""
  "anthropics/skills"
  "pbakaus/impeccable"
  "cloudflare/security-audit-skill"
  "vercel-labs/agent-skills"
)

optional_key_kind() {
  printf '%s\n' "${1%%:*}"
}

optional_key_id() {
  printf '%s\n' "${1#*:}"
}

optional_index_of() {
  local key="$1"
  local i
  for i in "${!OPTIONAL_IDS[@]}"; do
    if [[ "${OPTIONAL_KINDS[$i]}:${OPTIONAL_IDS[$i]}" == "$key" ]]; then
      printf '%s\n' "$i"
      return 0
    fi
  done
  return 1
}

optional_mcp_binary() {
  local id="$1"
  local bin=""
  case "$id" in
    codebase-memory-mcp)
      bin="$(command -v codebase-memory-mcp 2>/dev/null || true)"
      if [[ -z "$bin" && -x "$HOME/.local/bin/codebase-memory-mcp" ]]; then
        bin="$HOME/.local/bin/codebase-memory-mcp"
      fi
      ;;
    browse)
      bin="$(command -v browse 2>/dev/null || true)"
      if [[ -z "$bin" && -x "$HOME/.local/bin/browse" ]]; then
        bin="$HOME/.local/bin/browse"
      fi
      if [[ -z "$bin" && -n "${XDG_BIN_HOME:-}" && -x "$XDG_BIN_HOME/browse" ]]; then
        bin="$XDG_BIN_HOME/browse"
      fi
      ;;
  esac
  [[ -n "$bin" ]] || return 1
  printf '%s\n' "$bin"
}

# Heuristic: catalog names are unique enough that a key match is reliable.
# OpenCode V2 normalizes V1 entries, so both config shapes count as configured.
optional_mcp_configured() {
  local id="$1"
  local file
  for file in "$CONFIG_DIR/opencode.jsonc" "$CONFIG_DIR/opencode.json"; do
    [[ -f "$file" ]] || continue
    if grep -Eq "\"${id}\"[[:space:]]*:" "$file"; then
      return 0
    fi
  done
  return 1
}

optional_mcp_state() {
  local id="$1"
  local bin=""
  local configured=0
  bin="$(optional_mcp_binary "$id" || true)"
  if optional_mcp_configured "$id"; then
    configured=1
  fi
  if [[ "$configured" -eq 1 && -n "$bin" ]]; then
    printf 'configured\n'
  elif [[ "$configured" -eq 1 ]]; then
    printf 'configured_no_binary\n'
  elif [[ -n "$bin" ]]; then
    printf 'binary_only\n'
  else
    printf 'not_installed\n'
  fi
}

# OpenCode loads skills from three global roots. The first root wins, so a
# copy under the OpenCode config directory shadows the canonical copy.
optional_skill_state() {
  local id="$1"
  local shadow="$CONFIG_DIR/skills"
  local external="$HOME/.claude/skills"
  local canonical="$HOME/.agents/skills"
  local root
  local dir
  local incomplete=""

  for root in "$shadow" "$external" "$canonical"; do
    dir="$root/$id"
    if [[ -f "$dir/SKILL.md" || -f "$root/$id.md" ]]; then
      case "$root" in
        "$shadow") printf 'shadowed\t%s\n' "$root" ;;
        "$external") printf 'external_only\t%s\n' "$root" ;;
        *) printf 'installed\t%s\n' "$root" ;;
      esac
      return 0
    fi
    if [[ -d "$dir" && -z "$incomplete" ]]; then
      incomplete="$root"
    fi
  done

  if [[ -n "$incomplete" ]]; then
    printf 'incomplete\t%s\n' "$incomplete"
  else
    printf 'not_installed\t\n'
  fi
}

optional_state() {
  local key="$1"
  local kind
  local id
  local line
  kind="$(optional_key_kind "$key")"
  id="$(optional_key_id "$key")"
  case "$kind" in
    mcp)
      optional_mcp_state "$id"
      ;;
    skill)
      line="$(optional_skill_state "$id")"
      printf '%s\n' "$line" | cut -f1
      ;;
    *)
      return 1
      ;;
  esac
}

optional_status_hint() {
  case "$1" in
    not_installed) printf '' ;;
    installed) printf 'installed' ;;
    shadowed) printf 'installed, shadow copy' ;;
    incomplete) printf 'incomplete install' ;;
    external_only) printf 'installed in ~/.claude' ;;
    configured) printf 'configured' ;;
    configured_no_binary) printf 'configured, binary missing' ;;
    binary_only) printf 'binary installed, not configured' ;;
    *) printf '' ;;
  esac
}

optional_node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local major
  local minor
  major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || printf '0')"
  minor="$(node -p 'process.versions.node.split(".")[1]' 2>/dev/null || printf '0')"
  [[ "$major" =~ ^[0-9]+$ ]] || return 1
  [[ "$minor" =~ ^[0-9]+$ ]] || return 1
  ((major > 22 || (major == 22 && minor >= 20)))
}

optional_run_shell() {
  local description="$1"
  local command="$2"
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '  [dry-run] %s\n' "$description"
    printf '            %s\n' "$command"
    return 0
  fi
  printf '  -> %s\n' "$description"
  bash -o pipefail -c "$command"
}

optional_run_cmd() {
  local description="$1"
  shift
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '  [dry-run] %s\n' "$description"
    printf '            '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  printf '  -> %s\n' "$description"
  "$@"
}

optional_install_codebase_memory() {
  local status="$1"
  local bin
  local install_cmd="curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash -s -- --skip-config"

  if ! optional_run_shell "install or update codebase-memory-mcp" "$install_cmd"; then
    return 1
  fi

  bin="$(optional_mcp_binary codebase-memory-mcp || true)"
  if [[ "${DRY_RUN:-0}" -eq 0 && -z "$bin" ]]; then
    printf '  codebase-memory-mcp was not found after installation.\n' >&2
    return 1
  fi

  case "$status" in
    configured|configured_no_binary)
      return 0
      ;;
  esac

  if ! command -v opencode >/dev/null 2>&1; then
    printf '  opencode CLI not found; skipped MCP registration.\n' >&2
    printf '  After installing OpenCode, run: opencode mcp add codebase-memory-mcp --global -- %s\n' "${bin:-codebase-memory-mcp}" >&2
    return 0
  fi

  optional_run_cmd "register codebase-memory-mcp with OpenCode" \
    opencode mcp add codebase-memory-mcp --global -- "${bin:-codebase-memory-mcp}"
}

optional_install_browse() {
  local status="$1"
  local bin
  local install_cmd="curl -fsSL https://opencode.ai/browse/install | bash -s -- --no-setup"

  if [[ "$status" == "configured" ]]; then
    bin="$(optional_mcp_binary browse || true)"
    if [[ -n "$bin" ]]; then
      optional_run_cmd "update browse runtime" "$bin" update
      return $?
    fi
    return 1
  fi

  if ! optional_run_shell "install or update browse binary" "$install_cmd"; then
    return 1
  fi

  bin="$(optional_mcp_binary browse || true)"
  if [[ "${DRY_RUN:-0}" -eq 0 && -z "$bin" ]]; then
    printf '  browse was not found after installation.\n' >&2
    return 1
  fi

  if [[ "$status" == "configured_no_binary" ]]; then
    printf '  browse binary restored. If the extension is not paired, run: %s install -a opencode -y\n' "$bin" >&2
    return 0
  fi

  if ! command -v opencode >/dev/null 2>&1; then
    printf '  opencode CLI not found; skipped browse MCP registration.\n' >&2
    printf '  After installing OpenCode, run: %s install -a opencode -y --no-open --no-wait\n' "${bin:-browse}" >&2
    return 0
  fi

  optional_run_cmd "configure browse with OpenCode" \
    "${bin:-browse}" install -a opencode -y --no-open --no-wait
}

optional_backup_skill_path() {
  local src="$1"
  local id="$2"
  local dest="$BACKUP_DIR/optional-skills/$id"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    return 0
  fi
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '  [dry-run] backup %s to %s\n' "$src" "$dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    dest="$dest.$(date -u '+%Y%m%d-%H%M%S')"
  fi
  mv "$src" "$dest" || return 1
  printf '  Backed up shadow skill: %s -> %s\n' "$src" "$dest"
}

optional_install_skill() {
  local id="$1"
  local source="$2"
  local status="$3"
  local root="$4"
  local shadow_dir="$CONFIG_DIR/skills/$id"
  local shadow_file="$CONFIG_DIR/skills/$id.md"
  local canonical_dir="$HOME/.agents/skills/$id"
  local canonical_file="$HOME/.agents/skills/$id.md"

  if [[ "$status" == "external_only" ]]; then
    printf '  %s is installed in ~/.claude/skills; leaving it untouched.\n' "$id" >&2
    return 0
  fi

  if ! optional_node_ok; then
    printf '  Node.js 22.20+ is required for skills; skipped %s.\n' "$id" >&2
    return 1
  fi
  if ! command -v npx >/dev/null 2>&1; then
    printf '  npx was not found; skipped %s.\n' "$id" >&2
    return 1
  fi

  if ! optional_run_cmd "install or update $id" \
    env npm_config_update_notifier=false npx -y skills add "$source" --skill "$id" -g -a opencode -y; then
    return 1
  fi

  # Move the shadow copy only after the canonical install succeeds. If the
  # install fails, the active copy stays where it is.
  if [[ "$status" == "shadowed" ]]; then
    optional_backup_skill_path "$shadow_dir" "$id" || return 1
    optional_backup_skill_path "$shadow_file" "$id.md" || return 1
  elif [[ "$status" == "incomplete" && "$root" == "$CONFIG_DIR/skills" ]]; then
    optional_backup_skill_path "$shadow_dir" "$id" || return 1
    optional_backup_skill_path "$shadow_file" "$id.md" || return 1
  fi

  if [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    if [[ ! -f "$canonical_dir/SKILL.md" && ! -f "$canonical_file" ]]; then
      printf '  %s was not found in %s after installation.\n' "$id" "$HOME/.agents/skills" >&2
      return 1
    fi
    if [[ -e "$shadow_dir" || -L "$shadow_dir" || -f "$shadow_file" ]]; then
      printf '  A shadow copy still exists at %s.\n' "$shadow_dir" >&2
      return 1
    fi
  fi

  return 0
}

optional_execute_item() {
  local key="$1"
  local kind
  local id
  local status
  local line
  local root
  local idx
  local source
  kind="$(optional_key_kind "$key")"
  id="$(optional_key_id "$key")"

  case "$kind" in
    mcp)
      status="$(optional_mcp_state "$id")"
      case "$id" in
        codebase-memory-mcp)
          optional_install_codebase_memory "$status"
          ;;
        browse)
          optional_install_browse "$status"
          ;;
        *)
          printf 'Unknown MCP item: %s\n' "$id" >&2
          return 1
          ;;
      esac
      ;;
    skill)
      line="$(optional_skill_state "$id")"
      IFS=$'\t' read -r status root <<< "$line"
      idx="$(optional_index_of "$key")"
      source="${OPTIONAL_SKILL_SOURCES[$idx]}"
      optional_install_skill "$id" "$source" "$status" "$root"
      ;;
    *)
      printf 'Unknown optional kind: %s\n' "$kind" >&2
      return 1
      ;;
  esac
}

optional_list() {
  local i
  local key
  local status
  printf '%-8s %-30s %-28s %s\n' "KIND" "ID" "STATUS" "DESCRIPTION"
  for i in "${!OPTIONAL_IDS[@]}"; do
    key="${OPTIONAL_KINDS[$i]}:${OPTIONAL_IDS[$i]}"
    status="$(optional_state "$key")"
    printf '%-8s %-30s %-28s %s\n' "${OPTIONAL_KINDS[$i]}" "${OPTIONAL_IDS[$i]}" "$status" "${OPTIONAL_DESCRIPTIONS[$i]}"
  done
}

optional_build_screen() {
  local kind="$1"
  local i
  local key
  local status
  local hint
  local disabled
  local node_ok=0

  CHECKLIST_TITLE=""
  CHECKLIST_SUBTITLE=""
  CHECKLIST_LABELS=()
  CHECKLIST_HINTS=()
  CHECKLIST_STATES=()
  CHECKLIST_DISABLED=()
  CHECKLIST_KEYS=()

  case "$kind" in
    mcp)
      CHECKLIST_TITLE="Optional MCP servers"
      CHECKLIST_SUBTITLE="Select servers to install or update."
      ;;
    skill)
      CHECKLIST_TITLE="Optional skills"
      CHECKLIST_SUBTITLE="Select skills to install or update."
      if optional_node_ok; then
        node_ok=1
      fi
      ;;
  esac

  for i in "${!OPTIONAL_IDS[@]}"; do
    [[ "${OPTIONAL_KINDS[$i]}" == "$kind" ]] || continue
    key="${OPTIONAL_KINDS[$i]}:${OPTIONAL_IDS[$i]}"
    status="$(optional_state "$key")"
    hint="$(optional_status_hint "$status")"
    disabled=0
    if [[ "$kind" == "skill" ]]; then
      if [[ "$node_ok" -eq 0 ]]; then
        hint="Node 22.20+ required"
        disabled=1
      elif [[ "$status" == "external_only" ]]; then
        disabled=1
      fi
    fi
    CHECKLIST_LABELS+=("${OPTIONAL_LABELS[$i]}")
    CHECKLIST_HINTS+=("$hint")
    CHECKLIST_STATES+=(0)
    CHECKLIST_DISABLED+=("$disabled")
    CHECKLIST_KEYS+=("$key")
  done
}

optional_apply_screen_selection() {
  local j
  local key
  local idx
  for j in "${!CHECKLIST_KEYS[@]}"; do
    key="${CHECKLIST_KEYS[$j]}"
    idx="$(optional_index_of "$key")"
    OPTIONAL_SELECTED[$idx]="${CHECKLIST_STATES[$j]}"
  done
}

optional_run_tui() {
  local i
  local rc
  OPTIONAL_SELECTED=()
  for i in "${!OPTIONAL_IDS[@]}"; do
    OPTIONAL_SELECTED+=(0)
  done

  optional_build_screen mcp
  if checklist_run; then
    rc=0
  else
    rc=$?
  fi
  if [[ "$rc" -eq 2 ]]; then
    return 2
  fi
  if [[ "$rc" -ne 0 ]]; then
    return 1
  fi
  optional_apply_screen_selection

  optional_build_screen skill
  if checklist_run; then
    rc=0
  else
    rc=$?
  fi
  if [[ "$rc" -eq 2 ]]; then
    return 2
  fi
  if [[ "$rc" -ne 0 ]]; then
    return 1
  fi
  optional_apply_screen_selection

  return 0
}

optional_confirm_selection() {
  local i
  local key
  local status
  local action
  local count=0
  local keypress

  printf '\nSelected optional items:\n'
  for i in "${!OPTIONAL_IDS[@]}"; do
    [[ "${OPTIONAL_SELECTED[$i]:-0}" -eq 1 ]] || continue
    key="${OPTIONAL_KINDS[$i]}:${OPTIONAL_IDS[$i]}"
    status="$(optional_state "$key")"
    case "$status" in
      not_installed|binary_only|configured_no_binary|incomplete) action="install" ;;
      *) action="update" ;;
    esac
    printf '  %-8s %-30s %-8s %s\n' "${OPTIONAL_KINDS[$i]}" "${OPTIONAL_IDS[$i]}" "$action" "$(optional_status_hint "$status")"
    count=$((count + 1))
  done
  if [[ "$count" -eq 0 ]]; then
    printf '  (none)\n'
    return 0
  fi
  if [[ "${ASSUME_YES:-0}" -eq 1 ]]; then
    return 0
  fi
  printf '\nPress enter to continue, q to cancel: '
  if ! IFS= read -rsn1 keypress < /dev/tty; then
    return 1
  fi
  if [[ "$keypress" == "q" || "$keypress" == "Q" ]]; then
    return 1
  fi
  return 0
}

optional_main() {
  local selected=()
  local installed=()
  local updated=()
  local failed=()
  local skipped=()
  local key
  local requested
  local rc
  local i
  local status

  if [[ -n "${WITH_ITEMS:-}" ]]; then
    IFS=',' read -r -a requested <<< "$WITH_ITEMS"
    for key in "${requested[@]}"; do
      key="$(printf '%s' "$key" | tr -d '[:space:]')"
      [[ -n "$key" ]] || continue
      if ! optional_index_of "$key" >/dev/null; then
        printf 'Unknown optional item: %s\n' "$key" >&2
        return 1
      fi
      selected+=("$key")
    done
  else
    if [[ "${NO_OPTIONAL:-0}" -eq 1 ]]; then
      return 0
    fi
    if optional_run_tui; then
      rc=0
    else
      rc=$?
    fi
    if [[ "$rc" -eq 2 ]]; then
      printf 'Optional install skipped: no interactive terminal.\n' >&2
      printf 'Use --with mcp:codebase-memory-mcp,skill:frontend-design to select items.\n' >&2
      return 0
    fi
    if [[ "$rc" -ne 0 ]]; then
      printf 'Optional install skipped.\n'
      return 0
    fi
    for i in "${!OPTIONAL_IDS[@]}"; do
      if [[ "${OPTIONAL_SELECTED[$i]:-0}" -eq 1 ]]; then
        selected+=("${OPTIONAL_KINDS[$i]}:${OPTIONAL_IDS[$i]}")
      fi
    done
    if ! optional_confirm_selection; then
      printf 'Optional install cancelled.\n'
      return 0
    fi
  fi

  if [[ "${#selected[@]}" -eq 0 ]]; then
    printf 'No optional items selected.\n'
    return 0
  fi

  for key in "${selected[@]}"; do
    status="$(optional_state "$key")"
    if [[ "$status" == "external_only" ]]; then
      printf '  Skipping %s: installed in ~/.claude/skills.\n' "$key"
      skipped+=("$key")
      continue
    fi
    printf '\n[%s]\n' "$key"
    if optional_execute_item "$key"; then
      case "$status" in
        not_installed|binary_only|configured_no_binary|incomplete)
          installed+=("$key")
          ;;
        *)
          updated+=("$key")
          ;;
      esac
    else
      failed+=("$key")
    fi
  done

  printf '\nOptional summary\n'
  printf '  installed: %s\n' "${#installed[@]}"
  printf '  updated:   %s\n' "${#updated[@]}"
  printf '  skipped:   %s\n' "${#skipped[@]}"
  printf '  failed:    %s\n' "${#failed[@]}"
  if [[ "${#installed[@]}" -gt 0 ]]; then
    printf '    install: %s\n' "${installed[*]}"
  fi
  if [[ "${#updated[@]}" -gt 0 ]]; then
    printf '    update:  %s\n' "${updated[*]}"
  fi
  if [[ "${#skipped[@]}" -gt 0 ]]; then
    printf '    skip:    %s\n' "${skipped[*]}"
  fi
  if [[ "${#failed[@]}" -gt 0 ]]; then
    printf '    failed:  %s\n' "${failed[*]}"
  fi
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '\nDry run: no changes were made.\n'
  fi
  return 0
}
