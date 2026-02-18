#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf '  PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1" >&2; }

echo "=== Shellcheck ==="
if command -v shellcheck >/dev/null 2>&1; then
  sc_files=()
  while IFS= read -r f; do
    sc_files+=("$f")
  done < <(find "$REPO_ROOT/scripts" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.bash' \))

  # Also check files without extension that have bash shebang
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    case "$f" in *.sh|*.bash|*.py) continue ;; esac
    if head -n1 "$f" 2>/dev/null | grep -q 'bash'; then
      sc_files+=("$f")
    fi
  done < <(find "$REPO_ROOT/scripts" -maxdepth 1 -type f)

  if [ "${#sc_files[@]}" -eq 0 ]; then
    echo "  No bash files found"
  else
    for f in "${sc_files[@]}"; do
      name="$(basename "$f")"
      if shellcheck -x --exclude=SC1091 "$f" >/dev/null 2>&1; then
        pass "shellcheck $name"
      else
        fail "shellcheck $name"
        shellcheck -x --exclude=SC1091 "$f" || true
      fi
    done
  fi
else
  echo "  shellcheck not installed, skipping lint"
fi

echo ""
echo "=== Unit Tests ==="

# Test: dictation-lib.sh loads and defines functions
if (
  # shellcheck source=scripts/dictation-lib.sh
  . "$REPO_ROOT/scripts/dictation-lib.sh"
  type get_mic_source >/dev/null 2>&1
  type get_mic_mute >/dev/null 2>&1
  type get_mic_volume >/dev/null 2>&1
  type log_mic_state >/dev/null 2>&1
); then
  pass "dictation-lib.sh loads and exports functions"
else
  fail "dictation-lib.sh load"
fi

# Test: ai-say with empty input exits 0
if printf '' | bash "$REPO_ROOT/scripts/ai-say" >/dev/null 2>&1; then
  pass "ai-say empty input exits 0"
else
  fail "ai-say empty input"
fi

# Test: ai-say with special characters exits 0
if printf 'hello "world" & <test>' | bash "$REPO_ROOT/scripts/ai-say" >/dev/null 2>&1; then
  pass "ai-say special chars exits 0"
else
  fail "ai-say special chars"
fi

# Test: kokoro-synthesize.py rejects missing args
if python3 "$REPO_ROOT/scripts/kokoro-synthesize.py" --out /dev/null 2>/dev/null; then
  fail "kokoro-synthesize.py should reject missing --text/--text-file"
else
  pass "kokoro-synthesize.py rejects missing text args"
fi

# Test: voice-status runs without error
if bash "$REPO_ROOT/scripts/voice-status" >/dev/null 2>&1; then
  pass "voice-status runs"
else
  fail "voice-status"
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
