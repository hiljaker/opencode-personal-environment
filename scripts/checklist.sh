#!/usr/bin/env bash
# Generic keyboard checklist for bash 3.2+.
#
# Contract:
#   CHECKLIST_TITLE       Heading shown at the top.
#   CHECKLIST_SUBTITLE    Optional second heading.
#   CHECKLIST_LABELS      Array of item labels.
#   CHECKLIST_HINTS       Array of status hints, one per label.
#   CHECKLIST_STATES      Array of 0/1 selection flags, updated in place.
#   CHECKLIST_DISABLED    Array of 0/1 disabled flags, one per label.
#   CHECKLIST_FOOTER      Optional footer text.
#
# checklist_run returns:
#   0  confirmed
#   1  cancelled
#   2  no interactive terminal

_checklist_tty="/dev/tty"
_checklist_saved_stty=""
_checklist_saved_trap=""
_checklist_cursor_hidden=0
_checklist_cursor=0

_checklist_restore() {
  if [[ -n "$_checklist_saved_stty" ]]; then
    stty "$_checklist_saved_stty" 2>/dev/null < "$_checklist_tty" || true
    _checklist_saved_stty=""
  fi
  if [[ "$_checklist_cursor_hidden" -eq 1 ]]; then
    printf '\033[?25h' 2>/dev/null > "$_checklist_tty" || true
    _checklist_cursor_hidden=0
  fi
}

_checklist_begin() {
  [[ -t 0 || -t 1 || -t 2 ]] || return 2
  [[ -r "$_checklist_tty" && -w "$_checklist_tty" ]] || return 2
  _checklist_saved_stty="$(stty -g 2>/dev/null < "$_checklist_tty")" || {
    _checklist_saved_stty=""
    return 2
  }
  stty -echo -icanon min 1 time 0 2>/dev/null < "$_checklist_tty" || {
    _checklist_restore
    return 2
  }
  _checklist_saved_trap="$(trap -p EXIT 2>/dev/null || true)"
  trap '_checklist_restore' EXIT
  trap '_checklist_restore; exit 130' INT TERM
  printf '\033[?25l' 2>/dev/null > "$_checklist_tty" || true
  _checklist_cursor_hidden=1
  return 0
}

_checklist_end() {
  _checklist_restore
  trap - EXIT INT TERM
  if [[ -n "$_checklist_saved_trap" ]]; then
    eval "$_checklist_saved_trap"
    _checklist_saved_trap=""
  fi
}

_checklist_render() {
  local i marker hint
  {
    printf '\033[H\033[J'
    printf '%s\n' "${CHECKLIST_TITLE:-Checklist}"
    if [[ -n "${CHECKLIST_SUBTITLE:-}" ]]; then
      printf '%s\n' "$CHECKLIST_SUBTITLE"
    fi
    printf '\n'
    for i in "${!CHECKLIST_LABELS[@]}"; do
      marker=" "
      if [[ "${CHECKLIST_STATES[$i]:-0}" -eq 1 ]]; then
        marker="x"
      fi
      hint="${CHECKLIST_HINTS[$i]:-}"
      if [[ "$i" -eq "$_checklist_cursor" ]]; then
        printf '> [%s] %-28s' "$marker" "${CHECKLIST_LABELS[$i]}"
      else
        printf '  [%s] %-28s' "$marker" "${CHECKLIST_LABELS[$i]}"
      fi
      if [[ "${CHECKLIST_DISABLED[$i]:-0}" -eq 1 ]]; then
        if [[ -n "$hint" ]]; then
          printf '  (%s, disabled)' "$hint"
        else
          printf '  (disabled)'
        fi
      elif [[ -n "$hint" ]]; then
        printf '  (%s)' "$hint"
      fi
      printf '\n'
    done
    printf '\n%s\n' "${CHECKLIST_FOOTER:-up/down move  space toggle  enter next  q skip}"
  } 2>/dev/null > "$_checklist_tty"
}

_checklist_move() {
  local delta="$1"
  local count="${#CHECKLIST_LABELS[@]}"
  local next
  [[ "$count" -gt 0 ]] || return 0
  next=$((_checklist_cursor + delta))
  if [[ "$next" -lt 0 ]]; then
    next=$((count - 1))
  fi
  if [[ "$next" -ge "$count" ]]; then
    next=0
  fi
  _checklist_cursor="$next"
}

_checklist_toggle() {
  local i="$_checklist_cursor"
  [[ "${CHECKLIST_DISABLED[$i]:-0}" -eq 1 ]] && return 0
  if [[ "${CHECKLIST_STATES[$i]:-0}" -eq 1 ]]; then
    CHECKLIST_STATES[$i]=0
  else
    CHECKLIST_STATES[$i]=1
  fi
}

checklist_run() {
  local key seq
  _checklist_cursor=0
  _checklist_begin || return $?
  while true; do
    _checklist_render
    if ! IFS= read -rsn1 key 2>/dev/null < "$_checklist_tty"; then
      _checklist_end
      return 1
    fi
    case "$key" in
      $'\x1b')
        # Arrow keys arrive as ESC followed by two bytes. A lone ESC waits
        # for the timeout and then acts as cancel.
        if IFS= read -rsn2 -t 1 seq 2>/dev/null < "$_checklist_tty"; then
          case "$seq" in
            '[A') _checklist_move -1 ;;
            '[B') _checklist_move 1 ;;
            *) ;;
          esac
        else
          _checklist_end
          return 1
        fi
        ;;
      ' ')
        _checklist_toggle
        ;;
      ''|$'\r'|$'\n')
        _checklist_end
        return 0
        ;;
      'q'|'Q')
        _checklist_end
        return 1
        ;;
      'j'|'J')
        _checklist_move 1
        ;;
      'k'|'K')
        _checklist_move -1
        ;;
      *) ;;
    esac
  done
}
