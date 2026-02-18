#!/usr/bin/env bash
# Shared functions for dictation scripts.
# Source this file; do not execute directly.

# Source platform-lib.sh for cross-platform abstractions
_DICTATION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PLAT_PATHS=("$_DICTATION_LIB_DIR/platform-lib.sh" "$HOME/.local/lib/platform-lib.sh")
for _plib in "${_PLAT_PATHS[@]}"; do
  if [ -f "$_plib" ]; then
    # shellcheck source=scripts/platform-lib.sh
    . "$_plib"
    break
  fi
done
unset _plib _PLAT_PATHS _DICTATION_LIB_DIR

get_mic_source() {
  local src=""
  # Linux-only: check for explicit DICTATION_SOURCE and HyperX preferred mic
  if [ "${PLATFORM:-Linux}" = "Linux" ] && command -v pactl >/dev/null 2>&1; then
    if [ -n "${DICTATION_SOURCE:-}" ]; then
      if pactl list short sources | awk '{print $2}' | rg -Fx -- "${DICTATION_SOURCE}" >/dev/null 2>&1; then
        printf '%s' "${DICTATION_SOURCE}"
        return
      fi
    fi

    local preferred=""
    preferred="$(pactl list short sources | awk '/HyperX_SoloCast|HyperX SoloCast|usb-HP__Inc_HyperX_SoloCast/ {print $2; exit}')"
    if [ -n "$preferred" ]; then
      printf '%s' "$preferred"
      return
    fi
  fi

  if command -v plat_get_default_source >/dev/null 2>&1; then
    src="$(plat_get_default_source)"
  elif command -v pactl >/dev/null 2>&1; then
    src="$(pactl get-default-source 2>/dev/null || true)"
    if [ -z "$src" ]; then
      src="$(pactl info 2>/dev/null | awk -F': ' '/Default Source/ {print $2; exit}' || true)"
    fi
  fi
  printf '%s' "$src"
}

get_mic_mute() {
  local src="$1"
  if [ -z "$src" ]; then
    printf 'unknown'
    return
  fi
  if command -v plat_get_source_mute >/dev/null 2>&1; then
    plat_get_source_mute "$src"
  elif command -v pactl >/dev/null 2>&1; then
    pactl get-source-mute "$src" 2>/dev/null | awk '{print $2}' || printf 'unknown'
  else
    printf 'unknown'
  fi
}

get_mic_volume() {
  local src="$1"
  if [ -z "$src" ]; then
    printf '?'
    return
  fi
  if command -v plat_get_source_volume >/dev/null 2>&1; then
    plat_get_source_volume "$src"
  elif command -v pactl >/dev/null 2>&1; then
    pactl get-source-volume "$src" 2>/dev/null | awk -F'/' 'NR==1 {gsub(/ /, "", $2); print $2; exit}' || printf '?'
  else
    printf '?'
  fi
}

log_mic_state() {
  local log_file="$1"
  local mic_source mic_mute mic_vol mic_state
  mic_source="$(get_mic_source)"
  mic_mute="$(get_mic_mute "$mic_source")"
  mic_vol="$(get_mic_volume "$mic_source")"
  mic_state="ON"
  if [ "$mic_mute" = "yes" ]; then
    mic_state="OFF"
  fi
  printf '%s mic_state=%s source=%s volume=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$mic_state" "${mic_source:-default}" "$mic_vol" >> "$log_file"
}
