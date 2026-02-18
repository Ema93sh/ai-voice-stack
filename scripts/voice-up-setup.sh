#!/usr/bin/env bash
set -euo pipefail

WITH_SYSTEM_DEPS=0
FORCE_CONFIG=0
SKIP_PYTHON=0
NO_HOTKEYS=0

usage() {
  cat <<'USAGE'
Usage: voice-up-setup.sh [options]

Options:
  --with-system-deps   Install apt packages with sudo
  --force-config       Overwrite ~/.xbindkeysrc and ~/.config/ai-audio.env
  --skip-python        Skip Python venv/package setup
  --no-hotkeys         Do not restart xbindkeys at the end
  -h, --help           Show this help
USAGE
}

log() {
  printf '[voice-up] %s\n' "$*"
}

warn() {
  printf '[voice-up][warn] %s\n' "$*" >&2
}

backup_then_copy() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && [ "$FORCE_CONFIG" -ne 1 ]; then
    warn "keeping existing $dst (use --force-config to overwrite)"
    return 0
  fi

  if [ -f "$dst" ]; then
    cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    log "backup created for $dst"
  fi

  cp "$src" "$dst"
  log "installed $dst"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-system-deps) WITH_SYSTEM_DEPS=1 ;;
    --force-config) FORCE_CONFIG=1 ;;
    --skip-python) SKIP_PYTHON=1 ;;
    --no-hotkeys) NO_HOTKEYS=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      warn "unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_BIN="$HOME/.local/bin"
KOKORO_HOME="$HOME/.local/share/kokoro-tts"
DICTATION_VENV="$HOME/.venvs/dictation"
KOKORO_VENV="$KOKORO_HOME/.venv"

if [ "$WITH_SYSTEM_DEPS" -eq 1 ]; then
  if ! command -v sudo >/dev/null 2>&1; then
    warn "sudo is required for --with-system-deps"
    exit 1
  fi
  log "installing system dependencies"
  sudo apt update
  sudo apt install -y \
    portaudio19-dev python3-venv python3-pip git \
    xdotool ydotool pulseaudio-utils ffmpeg xbindkeys
fi

log "installing scripts into ~/.local/bin"
mkdir -p "$HOME_BIN" "$KOKORO_HOME"

install -m 0755 "$REPO_ROOT/scripts/dictate-start" "$HOME_BIN/dictate-start"
install -m 0755 "$REPO_ROOT/scripts/dictate-stop" "$HOME_BIN/dictate-stop"
install -m 0755 "$REPO_ROOT/scripts/dictation-hotkeys" "$HOME_BIN/dictation-hotkeys"
install -m 0755 "$REPO_ROOT/scripts/transcribe_whisper.py" "$HOME_BIN/transcribe_whisper.py"
install -m 0755 "$REPO_ROOT/scripts/transcribe-audio" "$HOME_BIN/transcribe-audio"
install -m 0755 "$REPO_ROOT/scripts/ai-say" "$HOME_BIN/ai-say"
install -m 0755 "$REPO_ROOT/scripts/ai-tts-last" "$HOME_BIN/ai-tts-last"
install -m 0755 "$REPO_ROOT/scripts/kokoro-synthesize.py" "$KOKORO_HOME/synthesize.py"
ln -sf "$HOME_BIN/ai-say" "$HOME_BIN/ai-tts"

log "installing config files"
backup_then_copy "$REPO_ROOT/config/xbindkeysrc.sample" "$HOME/.xbindkeysrc"
backup_then_copy "$REPO_ROOT/config/ai-audio.env.sample" "$HOME/.config/ai-audio.env"

if [ "$SKIP_PYTHON" -ne 1 ]; then
  log "setting up dictation python env"
  python3 -m venv "$DICTATION_VENV"
  "$DICTATION_VENV/bin/pip" install --upgrade pip
  "$DICTATION_VENV/bin/pip" install faster-whisper

  PY_KOKORO="$(command -v python3.12 || true)"
  if [ -z "$PY_KOKORO" ]; then
    warn "python3.12 not found, falling back to python3"
    PY_KOKORO="$(command -v python3)"
  fi

  log "setting up kokoro python env via $PY_KOKORO"
  "$PY_KOKORO" -m venv "$KOKORO_VENV"
  "$KOKORO_VENV/bin/pip" install --upgrade pip setuptools wheel
  "$KOKORO_VENV/bin/pip" install kokoro soundfile
fi

if [ "$NO_HOTKEYS" -ne 1 ]; then
  log "restarting hotkeys"
  "$HOME_BIN/dictation-hotkeys" || warn "could not restart hotkeys automatically"
fi

cat <<'DONE'

[voice-up] setup complete

Next:
1) Edit ~/.config/ai-audio.env if your source/sink names differ.
2) Test dictation: hold Menu, speak, release.
3) Test TTS: ~/.local/bin/ai-say "Voice test"

DONE
