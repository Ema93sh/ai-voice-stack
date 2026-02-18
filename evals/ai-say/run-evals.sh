#!/usr/bin/env bash
set -euo pipefail

EVALS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$EVALS_DIR/../.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/ai-say"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf '  PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL: %s\n' "$1" >&2; }

# ── 1. SKILL.md Frontmatter ─────────────────────────────────────────────────

echo "=== SKILL.md Frontmatter ==="

SKILL_MD="$SKILL_DIR/SKILL.md"

if [ -f "$SKILL_MD" ]; then
  pass "SKILL.md exists"
else
  fail "SKILL.md exists"
fi

# Has --- delimiters (frontmatter)
if head -n1 "$SKILL_MD" | grep -q '^---$'; then
  pass "SKILL.md has opening --- delimiter"
else
  fail "SKILL.md has opening --- delimiter"
fi

# Has closing --- delimiter
if awk 'NR>1 && /^---$/{found=1; exit} END{exit !found}' "$SKILL_MD"; then
  pass "SKILL.md has closing --- delimiter"
else
  fail "SKILL.md has closing --- delimiter"
fi

# name field is valid: lowercase, hyphens, 1-64 chars
name=$(awk '/^---$/{ if(n++) exit } /^name:/{print $2}' "$SKILL_MD")
if [[ "$name" =~ ^[a-z][a-z0-9-]{0,63}$ ]]; then
  pass "name is valid ($name)"
else
  fail "name is valid (got: $name)"
fi

# name matches directory name
dir_name="$(basename "$SKILL_DIR")"
if [ "$name" = "$dir_name" ]; then
  pass "name matches directory ($dir_name)"
else
  fail "name matches directory (name=$name, dir=$dir_name)"
fi

# description is 1-1024 chars
desc_len=$(awk '
  /^---$/{ if(n++) done=1 }
  !done && /^description:/{
    in_desc=1
    sub(/^description:[[:space:]]*>-?[[:space:]]*/, "")
    if ($0 != "") buf = $0
    next
  }
  in_desc && !done && /^[[:space:]]/{
    sub(/^[[:space:]]+/, "")
    buf = (buf == "" ? $0 : buf " " $0)
    next
  }
  in_desc { print buf; printed=1; exit }
  END { if (in_desc && !printed) print buf }
' "$SKILL_MD")
desc_chars=${#desc_len}
if [ "$desc_chars" -ge 1 ] && [ "$desc_chars" -le 1024 ]; then
  pass "description length ($desc_chars chars)"
else
  fail "description length ($desc_chars chars, want 1-1024)"
fi

# Body under 500 lines
body_lines=$(awk '/^---$/{ if(n++) p=1; next } p{c++} END{print c+0}' "$SKILL_MD")
if [ "$body_lines" -lt 500 ]; then
  pass "body under 500 lines ($body_lines)"
else
  fail "body under 500 lines ($body_lines)"
fi

# ── 2. Directory Structure ───────────────────────────────────────────────────

echo ""
echo "=== Directory Structure ==="

if [ -d "$SKILL_DIR/scripts" ]; then
  pass "scripts/ exists"
else
  fail "scripts/ exists"
fi

if [ -x "$SKILL_DIR/scripts/install.sh" ]; then
  pass "install.sh is executable"
else
  fail "install.sh is executable"
fi

if [ -x "$SKILL_DIR/scripts/doctor.sh" ]; then
  pass "doctor.sh is executable"
else
  fail "doctor.sh is executable"
fi

if [ -d "$EVALS_DIR" ]; then
  pass "evals/ai-say/ exists"
else
  fail "evals/ai-say/ exists"
fi

if [ -f "$EVALS_DIR/prompts.csv" ]; then
  pass "prompts.csv exists"
else
  fail "prompts.csv exists"
fi

if [ -x "$EVALS_DIR/run-evals.sh" ]; then
  pass "run-evals.sh is executable"
else
  fail "run-evals.sh is executable"
fi

# ── 3. Doctor ────────────────────────────────────────────────────────────────

echo ""
echo "=== Doctor ==="

if bash "$SKILL_DIR/scripts/doctor.sh" >/dev/null 2>&1; then
  pass "doctor.sh exits 0"
else
  # doctor failing is expected when the stack isn't installed — still record it
  fail "doctor.sh exits 0 (stack may not be installed)"
fi

# ── 4. Install Script ───────────────────────────────────────────────────────

echo ""
echo "=== Install Script ==="

if bash -n "$SKILL_DIR/scripts/install.sh" 2>/dev/null; then
  pass "install.sh syntax valid"
else
  fail "install.sh syntax valid"
fi

if grep -q 'voice-up-setup\.sh' "$SKILL_DIR/scripts/install.sh"; then
  pass "install.sh references voice-up-setup.sh"
else
  fail "install.sh references voice-up-setup.sh"
fi

# Repo detection: the script should be able to resolve the repo root
if [ -f "$REPO_ROOT/scripts/voice-up-setup.sh" ]; then
  pass "repo detection (scripts/voice-up-setup.sh reachable)"
else
  fail "repo detection (scripts/voice-up-setup.sh not found at $REPO_ROOT)"
fi

# ── 5. ai-say Invocation ────────────────────────────────────────────────────
# Stub out all audio-producing commands so evals are silent.
# We place no-op stubs for paplay, ffmpeg, spd-say, and pactl first in PATH
# and disable Kokoro so ai-say runs its full logic without producing sound.

echo ""
echo "=== ai-say Invocation ==="

STUB_DIR="$(mktemp -d)"
for cmd in paplay ffmpeg spd-say pactl; do
  printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/$cmd"
  chmod +x "$STUB_DIR/$cmd"
done

ai_say_silent() {
  env PATH="$STUB_DIR:$PATH" AI_KOKORO_PY=/dev/null \
    bash "$REPO_ROOT/scripts/ai-say" >/dev/null 2>&1
}

if printf '' | ai_say_silent; then
  pass "ai-say empty input exits 0"
else
  fail "ai-say empty input exits 0"
fi

if printf 'hello "world" & <test>' | ai_say_silent; then
  pass "ai-say special chars exits 0"
else
  fail "ai-say special chars exits 0"
fi

long_text="$(printf 'A%.0s' $(seq 1 1601))"
if printf '%s' "$long_text" | ai_say_silent; then
  pass "ai-say long text (>1600 chars) exits 0"
else
  fail "ai-say long text (>1600 chars) exits 0"
fi

rm -rf "$STUB_DIR"

# ── 6. Prompt Dataset ───────────────────────────────────────────────────────

echo ""
echo "=== Prompt Dataset ==="

CSV="$EVALS_DIR/prompts.csv"

# Valid header
header=$(head -n1 "$CSV")
if [ "$header" = "prompt,should_trigger,category" ]; then
  pass "prompts.csv valid header"
else
  fail "prompts.csv valid header (got: $header)"
fi

# All rows have 3 fields (using tail to skip header)
bad_rows=0
while IFS= read -r line; do
  # Count commas outside quotes — simplified: count fields after stripping quoted content
  fields=$(echo "$line" | awk -F',' '{print NF}')
  if [ "$fields" -ne 3 ]; then
    bad_rows=$((bad_rows + 1))
  fi
done < <(tail -n +2 "$CSV")
if [ "$bad_rows" -eq 0 ]; then
  pass "all rows have 3 fields"
else
  fail "all rows have 3 fields ($bad_rows bad rows)"
fi

# should_trigger values are true or false
bad_vals=0
while IFS=',' read -r _ trigger _; do
  # Strip quotes if present
  trigger="${trigger//\"/}"
  if [ "$trigger" != "true" ] && [ "$trigger" != "false" ]; then
    bad_vals=$((bad_vals + 1))
  fi
done < <(tail -n +2 "$CSV")
if [ "$bad_vals" -eq 0 ]; then
  pass "should_trigger values are true/false"
else
  fail "should_trigger values are true/false ($bad_vals invalid)"
fi

# At least 15 cases
case_count=$(tail -n +2 "$CSV" | grep -c '[^[:space:]]')
if [ "$case_count" -ge 15 ]; then
  pass "has >= 15 cases ($case_count)"
else
  fail "has >= 15 cases ($case_count)"
fi

# Has both true and false cases
has_true=$(tail -n +2 "$CSV" | grep -c ',true,' || true)
has_false=$(tail -n +2 "$CSV" | grep -c ',false,' || true)
if [ "$has_true" -gt 0 ] && [ "$has_false" -gt 0 ]; then
  pass "has both true ($has_true) and false ($has_false) cases"
else
  fail "has both true ($has_true) and false ($has_false) cases"
fi

# ── 7. Shellcheck ────────────────────────────────────────────────────────────

echo ""
echo "=== Shellcheck ==="

if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r f; do
    fname="$(basename "$f")"
    if shellcheck -x --exclude=SC1091 "$f" >/dev/null 2>&1; then
      pass "shellcheck $fname"
    else
      fail "shellcheck $fname"
      shellcheck -x --exclude=SC1091 "$f" || true
    fi
  done < <(find "$SKILL_DIR" "$EVALS_DIR" -name '*.sh' -type f)
else
  echo "  shellcheck not installed, skipping lint"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results ==="
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
