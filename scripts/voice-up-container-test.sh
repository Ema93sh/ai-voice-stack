#!/usr/bin/env bash
set -euo pipefail

MODE="quick"
IMAGE="${VOICE_UP_TEST_IMAGE:-ubuntu:24.04}"

usage() {
  cat <<'USAGE'
Usage: voice-up-container-test.sh [mode]

Modes:
  quick   Fast validation: installs apt deps and runs setup with --skip-python (default)
  full    Full validation: installs apt deps, runs full setup, verifies Python imports
  both    Run quick then full

Environment:
  VOICE_UP_TEST_IMAGE   Docker image to use (default: ubuntu:24.04)
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "${1:-}" != "" ]; then
  MODE="$1"
fi

case "$MODE" in
  quick|full|both) ;;
  *)
    echo "[voice-up-test][error] unknown mode: $MODE" >&2
    usage
    exit 1
    ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  echo "[voice-up-test][error] docker is required" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_quick() {
  echo "[voice-up-test] running quick test in $IMAGE"
  docker run --rm \
    -v "$REPO_ROOT:/repo" \
    "$IMAGE" \
    bash -lc '
      set -euo pipefail
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y \
        ca-certificates \
        portaudio19-dev python3 python3-venv python3-pip git \
        xdotool ydotool pulseaudio-utils ffmpeg xbindkeys
      cd /repo
      scripts/voice-up-setup.sh --skip-python --no-hotkeys --force-config
      test -x /root/.local/bin/ai-say
      test -x /root/.local/bin/transcribe-audio
      test -f /root/.xbindkeysrc
      test -f /root/.config/ai-audio.env
      echo PASS_QUICK
    '
}

run_full() {
  echo "[voice-up-test] running full test in $IMAGE"
  docker run --rm \
    -v "$REPO_ROOT:/repo" \
    "$IMAGE" \
    bash -lc '
      set -euo pipefail
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y \
        ca-certificates \
        portaudio19-dev python3 python3-venv python3-pip git \
        xdotool ydotool pulseaudio-utils ffmpeg xbindkeys
      cd /repo
      scripts/voice-up-setup.sh --no-hotkeys --force-config
      /root/.venvs/dictation/bin/python -c "import faster_whisper; print(\"dictation_ok\")"
      /root/.local/share/kokoro-tts/.venv/bin/python -c "import kokoro, soundfile; print(\"tts_ok\")"
      echo PASS_FULL
    '
}

case "$MODE" in
  quick) run_quick ;;
  full) run_full ;;
  both)
    run_quick
    run_full
    ;;
esac
