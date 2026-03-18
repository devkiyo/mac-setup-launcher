#!/usr/bin/env bash

set -euo pipefail

REPO_OWNER="devkiyo"
REPO_NAME="mac-setup"
BRANCH="main"
WORK_DIR="$HOME/.mac-setup"
ARCHIVE_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/tarball/${BRANCH}"

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
    if [[ -t 0 ]]; then
      read -r -s -p "GitHub PAT (repo read-only) を入力してください: " pat || true
      printf '\n'
    elif [[ -r /dev/tty ]]; then
      read -r -s -p "GitHub PAT (repo read-only) を入力してください: " pat < /dev/tty || true
      printf '\n' > /dev/tty
    fi
  fi

  if [[ -z "$pat" ]]; then
    log "Error: PAT が空です。処理を中断します。"
    log "Hint: curl 経由で実行する場合は GITHUB_PAT を環境変数で渡すか、対話端末で実行してください。"
    exit 1
  fi

  GITHUB_PAT_VALUE="$pat"
}

cleanup() {
  rm -rf "${TMP_DIR:-}"
  unset GITHUB_PAT_VALUE
}

prepare_temp_paths() {
  TMP_DIR="$(mktemp -d)"
  ARCHIVE_FILE="$TMP_DIR/mac-setup.tar.gz"
  EXTRACT_DIR="$TMP_DIR/extracted"
  CURL_CONFIG_FILE="$TMP_DIR/curl.conf"
}

build_curl_config() {
  cat > "$CURL_CONFIG_FILE" <<EOF_CURL
url = "$ARCHIVE_URL"
header = "Accept: application/vnd.github+json"
header = "Authorization: Bearer ${GITHUB_PAT_VALUE}"
header = "X-GitHub-Api-Version: 2022-11-28"
location
fail
silent
show-error
output = "$ARCHIVE_FILE"
EOF_CURL
  chmod 600 "$CURL_CONFIG_FILE"
}

download_archive() {
  log "Downloading private repository archive..."
  curl --config "$CURL_CONFIG_FILE"
}

extract_archive() {
  mkdir -p "$EXTRACT_DIR"
  tar -xzf "$ARCHIVE_FILE" -C "$EXTRACT_DIR"

  SOURCE_DIR="$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$SOURCE_DIR" ]]; then
    log "Error: アーカイブ展開に失敗しました。"
    exit 1
  fi
}

prepare_work_dir() {
  if [[ -e "$WORK_DIR" ]]; then
    local backup_path
    backup_path="$HOME/.mac-setup.backup.$(date +%Y%m%d-%H%M%S)"
    log "Existing directory found. Moving to: $backup_path"
    mv "$WORK_DIR" "$backup_path"
  fi
  mkdir -p "$WORK_DIR"
}

install_archive_contents() {
  prepare_work_dir
  (cd "$SOURCE_DIR" && tar -cf - .) | (cd "$WORK_DIR" && tar -xf -)
}

run_bootstrap() {
  if [[ ! -f "$WORK_DIR/bootstrap.sh" ]]; then
    log "Error: bootstrap.sh が見つかりません。"
    exit 1
  fi

  cd "$WORK_DIR"
  exec bash bootstrap.sh
}

main() {
  trap cleanup EXIT

  need_cmd curl
  need_cmd tar
  need_cmd mktemp

  ensure_pat
  prepare_temp_paths
  build_curl_config
  download_archive
  extract_archive
  install_archive_contents
  run_bootstrap
}

main "$@"
