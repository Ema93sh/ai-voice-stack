#!/usr/bin/env bash
set -euo pipefail

pass=0
fail=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  PASS  %s\n' "$label"
    pass=$(( pass + 1 ))
  else
    printf '  FAIL  %s\n' "$label"
    fail=$(( fail + 1 ))
  fi
}

check_file() { [ -f "$1" ]; }
check_exec() { [ -x "$1" ]; }
check_cmd()  { command -v "$1" >/dev/null 2>&1; }
check_import() { "$1" -c "import $2" 2>/dev/null; }

printf '=== ai-say doctor ===\n\n'

# --- Binaries in ~/.local/bin/ ---
printf 'Binaries (~/.local/bin/):\n'
for bin in ai-say dictate-start dictate-stop transcribe-audio voice-status; do
  check "$bin" check_exec "$HOME/.local/bin/$bin"
done

# --- Library ---
printf '\nLibrary:\n'
check "dictation-lib.sh" check_file "$HOME/.local/lib/dictation-lib.sh"

# --- System dependencies ---
printf '\nSystem dependencies:\n'
for cmd in pactl ffmpeg xbindkeys xdotool; do
  check "$cmd" check_cmd "$cmd"
done

# --- Python venvs ---
printf '\nPython environments:\n'
check "dictation venv" check_exec "$HOME/.venvs/dictation/bin/python3"
check "faster_whisper import" check_import "$HOME/.venvs/dictation/bin/python3" faster_whisper
check "kokoro venv" check_exec "$HOME/.local/share/kokoro-tts/.venv/bin/python"
check "kokoro import" check_import "$HOME/.local/share/kokoro-tts/.venv/bin/python" kokoro

# --- Config files ---
printf '\nConfig:\n'
check "ai-audio.env" check_file "$HOME/.config/ai-audio.env"
check ".xbindkeysrc" check_file "$HOME/.xbindkeysrc"

# --- Kokoro ---
printf '\nKokoro:\n'
check "synthesize.py" check_file "$HOME/.local/share/kokoro-tts/synthesize.py"

# --- Summary ---
total=$(( pass + fail ))
printf '\n--- %d/%d checks passed ---\n' "$pass" "$total"

if [ "$fail" -gt 0 ]; then
  printf '%d check(s) failed. Run install to fix:\n' "$fail"
  printf '  bash %s/install.sh --with-system-deps\n' "$(dirname "${BASH_SOURCE[0]}")"
  exit 1
fi
