#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/devkiyo/mac-setup.git"
BRANCH="main"
WORK_DIR="$HOME/.mac-setup"

log() {
  printf '%s\n' "$*"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "Error: '$cmd' is required but not installed."
    exit 1
  fi
}

ensure_pat() {
  local pat="${GITHUB_PAT:-}"

  if [[ -z "$pat" ]]; then
    read -r -s -p "GitHub PAT (repo read-only) を入力してください: " pat
    printf '\n'
  fi

  if [[ -z "$pat" ]]; then
    log "Error: PAT が空です。処理を中断します。"
    exit 1
  fi

  GITHUB_PAT_VALUE="$pat"
}

setup_askpass() {
  ASKPASS_FILE="$(mktemp)"
  cat > "$ASKPASS_FILE" <<'ASKPASS_EOF'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf '%s\n' 'x-access-token' ;;
  *Password*) printf '%s\n' "$GITHUB_PAT_INTERNAL" ;;
  *) printf '\n' ;;
esac
ASKPASS_EOF
  chmod 700 "$ASKPASS_FILE"

  export GITHUB_PAT_INTERNAL="$GITHUB_PAT_VALUE"
  export GIT_ASKPASS="$ASKPASS_FILE"
  export GIT_TERMINAL_PROMPT=0
}

cleanup() {
  rm -f "${ASKPASS_FILE:-}"
  unset GITHUB_PAT_INTERNAL
  unset GITHUB_PAT_VALUE
}

clone_or_update_repo() {
  if [[ -d "$WORK_DIR/.git" ]]; then
    log "Updating existing repository at $WORK_DIR"
    cd "$WORK_DIR"
    git fetch origin "$BRANCH"
    git checkout "$BRANCH"
    git pull --ff-only origin "$BRANCH"
    return
  fi

  if [[ -e "$WORK_DIR" ]]; then
    local backup_path
    backup_path="$HOME/.mac-setup.backup.$(date +%Y%m%d-%H%M%S)"
    log "Existing non-git directory found. Moving to: $backup_path"
    mv "$WORK_DIR" "$backup_path"
  fi

  log "Cloning private repository to $WORK_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$WORK_DIR"
}

run_bootstrap() {
  cd "$WORK_DIR"
  exec bash bootstrap.sh
}

main() {
  trap cleanup EXIT

  need_cmd git
  ensure_pat
  setup_askpass

  clone_or_update_repo
  run_bootstrap
}

main "$@"
