#!/usr/bin/env bash
set -euo pipefail

# Bootstrap installer for the portable Personal OpenCode Environment.
#
# Remote install:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/personal-opencode-environment/main/install.sh | bash
#
# Before publishing this repository, replace REPOSITORY_SLUG below with the
# actual public GitHub owner/repository. It is also overridable at runtime:
#   OPENCODE_ENV_REPO=owner/repository OPENCODE_ENV_REF=main bash
#
# Local install:
#   ./install.sh

REPOSITORY_SLUG="${OPENCODE_ENV_REPO:-YOUR_GITHUB_USERNAME/personal-opencode-environment}"
REF="${OPENCODE_ENV_REF:-main}"

usage() {
  cat <<USAGE
Usage:
  ./install.sh
  curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/<ref>/install.sh | bash

Environment overrides:
  OPENCODE_ENV_REPO    GitHub repository in owner/repository form.
  OPENCODE_ENV_REF     Branch or tag to install (default: main).
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

SOURCE_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SOURCE_PATH" && -f "$SOURCE_PATH" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "$SOURCE_PATH")" && pwd)"
  if [[ -f "$SCRIPT_DIR/scripts/install-local.sh" ]]; then
    exec bash "$SCRIPT_DIR/scripts/install-local.sh" "$@"
  fi
fi

if [[ "$REPOSITORY_SLUG" == YOUR_GITHUB_USERNAME/* ]]; then
  echo "Error: set REPOSITORY_SLUG in install.sh before publishing this repository." >&2
  echo "       Current value: $REPOSITORY_SLUG" >&2
  echo "       You can also override it with OPENCODE_ENV_REPO=owner/repository." >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || {
  echo "Error: curl is required for remote installation." >&2
  exit 1
}
command -v tar >/dev/null 2>&1 || {
  echo "Error: tar is required for remote installation." >&2
  exit 1
}

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/personal-opencode-environment.XXXXXX")"
cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT INT TERM

ARCHIVE="$TMP_ROOT/repository.tar.gz"
DOWNLOAD_URL="https://github.com/${REPOSITORY_SLUG}/archive/${REF}.tar.gz"

# A public GitHub repository is intentional here. The raw installer itself is
# fetched without authentication, so a private repository would require a
# different distribution mechanism.
curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$TMP_ROOT"

REPO_ROOT=""
for candidate in "$TMP_ROOT"/*; do
  if [[ -d "$candidate" && -f "$candidate/scripts/install-local.sh" ]]; then
    REPO_ROOT="$candidate"
    break
  fi
done

if [[ -z "$REPO_ROOT" ]]; then
  echo "Error: downloaded repository does not contain scripts/install-local.sh." >&2
  exit 1
fi

exec bash "$REPO_ROOT/scripts/install-local.sh" "$@"
