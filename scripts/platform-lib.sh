#!/usr/bin/env bash
# Platform abstraction layer for Linux and macOS.
# Source this file; do not execute directly.

PLATFORM="$(uname -s)"

plat_play_wav() {
  local file="$1"
  case "$PLATFORM" in
    Linux)  paplay "$file" ;;
    Darwin) afplay "$file" ;;
    *)      paplay "$file" ;;
  esac
}

plat_play_pipe() {
  case "$PLATFORM" in
    Linux)
      paplay "$@"
      ;;
    Darwin)
      local tmp
      tmp="$(mktemp "${TMPDIR:-/tmp}/plat_play.XXXXXX.wav")"
      cat > "$tmp"
      afplay "$tmp"
      rm -f "$tmp"
      ;;
    *)
      paplay "$@"
      ;;
  esac
}

plat_get_default_sink() {
  case "$PLATFORM" in
    Linux)  pactl get-default-sink 2>/dev/null || true ;;
    Darwin) echo "default" ;;
    *)      pactl get-default-sink 2>/dev/null || true ;;
  esac
}

plat_set_sink() {
  local sink="$1"
  case "$PLATFORM" in
    Linux)
      pactl set-default-sink "$sink" >/dev/null 2>&1 || true
      pactl set-sink-mute "$sink" 0 >/dev/null 2>&1 || true
      ;;
    Darwin)
      # macOS uses system audio routing; no-op
      ;;
  esac
}

plat_get_default_source() {
  case "$PLATFORM" in
    Linux)
      pactl get-default-source 2>/dev/null || true
      ;;
    Darwin)
      echo "default"
      ;;
    *)
      pactl get-default-source 2>/dev/null || true
      ;;
  esac
}

plat_get_source_mute() {
  local src="$1"
  case "$PLATFORM" in
    Linux)
      pactl get-source-mute "$src" 2>/dev/null | awk '{print $2}' || printf 'unknown'
      ;;
    Darwin)
      local vol
      vol="$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo '')"
      if [ -z "$vol" ]; then
        printf 'unknown'
      elif [ "$vol" -eq 0 ] 2>/dev/null; then
        printf 'yes'
      else
        printf 'no'
      fi
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}

plat_get_source_volume() {
  local src="$1"
  case "$PLATFORM" in
    Linux)
      pactl get-source-volume "$src" 2>/dev/null \
        | awk -F'/' 'NR==1 {gsub(/ /, "", $2); print $2; exit}' || printf '?'
      ;;
    Darwin)
      local vol
      vol="$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo '?')"
      printf '%s%%' "$vol"
      ;;
    *)
      printf '?'
      ;;
  esac
}

plat_rec_ffmpeg_args() {
  local src="${1:-default}"
  case "$PLATFORM" in
    Linux)
      printf '%s\n' "-f" "pulse" "-i" "$src"
      ;;
    Darwin)
      local idx="${DICTATION_AVFOUNDATION_INDEX:-:default}"
      printf '%s\n' "-f" "avfoundation" "-i" "$idx"
      ;;
    *)
      printf '%s\n' "-f" "pulse" "-i" "$src"
      ;;
  esac
}

plat_now_ms() {
  case "$PLATFORM" in
    Linux)
      date +%s%3N
      ;;
    Darwin)
      python3 -c "import time; print(int(time.time()*1000))"
      ;;
    *)
      date +%s%3N
      ;;
  esac
}

plat_tts_fallback() {
  local text="$1"
  case "$PLATFORM" in
    Linux)
      spd-say -o espeak-ng -i 100 -w -- "$text" >/dev/null 2>&1 || true
      ;;
    Darwin)
      say "$text" 2>/dev/null || true
      ;;
    *)
      spd-say -o espeak-ng -i 100 -w -- "$text" >/dev/null 2>&1 || true
      ;;
  esac
}

plat_insert_text() {
  local text="$1"
  case "$PLATFORM" in
    Darwin)
      printf '%s' "$text" | pbcopy
      osascript -e 'tell application "System Events" to keystroke "v" using command down' 2>/dev/null || true
      ;;
    *)
      if [ "${XDG_SESSION_TYPE:-x11}" = "wayland" ]; then
        printf '%s' "$text" | wl-copy
        ydotool key 29:1 47:1 47:0 29:0
      else
        xdotool keyup Menu >/dev/null 2>&1 || true
        xdotool type --clearmodifiers --delay 1 "$text"
      fi
      ;;
  esac
}

plat_press_enter() {
  case "$PLATFORM" in
    Darwin)
      osascript -e 'tell application "System Events" to keystroke return using control down' 2>/dev/null || true
      ;;
    *)
      if [ "${XDG_SESSION_TYPE:-x11}" = "wayland" ]; then
        ydotool key 29:1 28:1 28:0 29:0
      else
        xdotool keyup Menu >/dev/null 2>&1 || true
        xdotool key ctrl+Return
      fi
      ;;
  esac
}

plat_hotkey_process_running() {
  case "$PLATFORM" in
    Linux)  pgrep -x xbindkeys >/dev/null 2>&1 ;;
    Darwin) return 1 ;;  # macOS uses Karabiner, no daemon to check
  esac
}

plat_hotkey_process_name() {
  case "$PLATFORM" in
    Linux)  echo "xbindkeys" ;;
    Darwin) echo "Karabiner-Elements" ;;
    *)      echo "xbindkeys" ;;
  esac
}
