#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="ai-voice-stack"
REPO_URL="https://github.com/Ema93sh/ai-voice-stack.git"
DEFAULT_CLONE_DIR="$HOME/.local/share/$REPO_NAME"

log() { printf '[ai-say:install] %s\n' "$*"; }
err() { printf '[ai-say:install] ERROR: %s\n' "$*" >&2; }

find_repo() {
  # 1. Running from within the repo already?
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local candidate="$script_dir/../../.."
  if [ -f "$candidate/scripts/voice-up-setup.sh" ]; then
    printf '%s' "$(cd "$candidate" && pwd)"
    return 0
  fi

  # 2. Default clone location
  if [ -f "$DEFAULT_CLONE_DIR/scripts/voice-up-setup.sh" ]; then
    printf '%s' "$DEFAULT_CLONE_DIR"
    return 0
  fi

  return 1
}

repo_dir=""
if repo_dir="$(find_repo)"; then
  log "found repo at $repo_dir"
else
  log "repo not found locally — cloning to $DEFAULT_CLONE_DIR"
  git clone "$REPO_URL" "$DEFAULT_CLONE_DIR"
  repo_dir="$DEFAULT_CLONE_DIR"
  log "cloned to $repo_dir"
fi

log "running voice-up-setup.sh $*"
exec "$repo_dir/scripts/voice-up-setup.sh" "$@"
