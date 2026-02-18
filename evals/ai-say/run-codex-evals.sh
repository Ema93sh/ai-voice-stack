#!/usr/bin/env bash
set -euo pipefail

EVALS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$EVALS_DIR/../.." && pwd)"
CSV="$EVALS_DIR/prompts.csv"
ARTIFACTS_DIR="$EVALS_DIR/artifacts"
MAX_PARALLEL="${MAX_PARALLEL:-4}"

mkdir -p "$ARTIFACTS_DIR"

# ── Preflight ────────────────────────────────────────────────────────────────

if ! command -v codex >/dev/null 2>&1; then
  echo "ERROR: codex CLI not found in PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found in PATH" >&2
  exit 1
fi

GRADER_SCHEMA="$EVALS_DIR/grader-schema.json"

# ── Per-prompt worker ────────────────────────────────────────────────────────

run_one() {
  local id="$1" prompt="$2" should_trigger="$3"
  local trace_file="$ARTIFACTS_DIR/${id}.jsonl"
  local verdict_file="$ARTIFACTS_DIR/${id}.verdict.json"
  local result_file="$ARTIFACTS_DIR/${id}.result"

  # Run codex exec with sandbox; dry-run mode so ai-say produces no sound
  local eval_args=(exec --json --sandbox read-only -C "$REPO_ROOT"
    -c 'shell_environment_policy.set.AI_SAY_DRY_RUN="1"')
  if [ -n "${MODEL:-}" ]; then
    eval_args+=(-m "$MODEL")
  fi

  if ! codex "${eval_args[@]}" "$prompt" > "$trace_file" 2>/dev/null; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$should_trigger" "ERROR" "ERROR" "$prompt" > "$result_file"
    return
  fi

  # Grade with LLM: ask whether ai-say was invoked in the trace
  local grader_prompt
  grader_prompt="$(cat <<GRADER_EOF
You are an eval grader. The user asked an AI coding agent the following:

  "$prompt"

The agent ran inside a read-only sandbox, so commands that need to write
(like ai-say's lock file) will fail with "Permission denied". That is
expected. Count ai-say as triggered if:
  - A command_execution event ran a command containing "ai-say" (even if
    the command ultimately failed due to sandbox restrictions), OR
  - The agent clearly attempted to invoke ai-say but was blocked by the
    sandbox and told the user to run it themselves.

Do NOT count merely reading/inspecting the ai-say script (cat, sed, nl)
as triggering it.

Below is the full execution trace (JSONL).

--- TRACE START ---
$(cat "$trace_file")
--- TRACE END ---
GRADER_EOF
)"

  local grader_args=(exec --sandbox read-only --ephemeral
    --output-schema "$GRADER_SCHEMA" -o "$verdict_file")
  if [ -n "${GRADER_MODEL:-}" ]; then
    grader_args+=(-m "$GRADER_MODEL")
  fi

  if ! printf '%s' "$grader_prompt" | codex "${grader_args[@]}" - >/dev/null 2>&1; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$should_trigger" "ERROR" "ERROR" "$prompt" > "$result_file"
    return
  fi

  # jq -e exits non-zero on false/null; use -r and validate the value instead
  local actual_triggered reasoning
  actual_triggered="$(jq -r '.triggered' "$verdict_file")"
  reasoning="$(jq -r '.reasoning' "$verdict_file")"
  if [[ "$actual_triggered" != "true" && "$actual_triggered" != "false" ]]; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$should_trigger" "ERROR" "ERROR" "$prompt" > "$result_file"
    return
  fi

  local result
  if [ "$actual_triggered" = "$should_trigger" ]; then
    result="PASS"
  else
    result="FAIL"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$should_trigger" "$actual_triggered" "$result" "$prompt" "$reasoning" > "$result_file"
}

export -f run_one
export EVALS_DIR REPO_ROOT ARTIFACTS_DIR GRADER_SCHEMA
export MODEL="${MODEL:-}" GRADER_MODEL="${GRADER_MODEL:-}"

# ── Run evals in parallel ───────────────────────────────────────────────────

TOTAL=0
pids=()
ids=()

while IFS=',' read -r prompt should_trigger _category; do
  TOTAL=$((TOTAL + 1))

  # Strip surrounding quotes from CSV fields
  prompt="${prompt#\"}"
  prompt="${prompt%\"}"
  should_trigger="${should_trigger#\"}"
  should_trigger="${should_trigger%\"}"

  run_one "$TOTAL" "$prompt" "$should_trigger" &
  pids+=($!)
  ids+=("$TOTAL")

  # Throttle: wait for a slot when we hit the limit
  if [ "${#pids[@]}" -ge "$MAX_PARALLEL" ]; then
    # Poll until a slot opens (compatible with bash 3.2+)
    while true; do
      alive=()
      for p in "${pids[@]}"; do
        if kill -0 "$p" 2>/dev/null; then
          alive+=("$p")
        fi
      done
      pids=("${alive[@]}")
      [ "${#pids[@]}" -ge "$MAX_PARALLEL" ] || break
      sleep 1
    done
  fi
done < <(tail -n +2 "$CSV")

# Wait for remaining jobs
wait

# ── Collect and display results ─────────────────────────────────────────────

PASS=0
FAIL=0
ERRORS=0

printf '\n%-4s %-8s %-8s %-6s  %s\n' "#" "EXPECT" "ACTUAL" "RESULT" "PROMPT"
printf '%-4s %-8s %-8s %-6s  %s\n' "---" "--------" "--------" "------" "------"

for id in $(seq 1 "$TOTAL"); do
  result_file="$ARTIFACTS_DIR/${id}.result"
  if [ ! -f "$result_file" ]; then
    printf '%-4s %-8s %-8s %-6s  %s\n' "$id" "?" "?" "ERROR" "(no result)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  IFS=$'\t' read -r _id should_trigger actual_triggered result prompt reasoning < "$result_file"

  if [ "$result" = "PASS" ]; then
    PASS=$((PASS + 1))
  elif [ "$result" = "FAIL" ]; then
    FAIL=$((FAIL + 1))
  else
    ERRORS=$((ERRORS + 1))
  fi

  printf '%-4s %-8s %-8s %-6s  %s\n' "$id" "$should_trigger" "$actual_triggered" "$result" "$prompt"
  if [ "$result" = "FAIL" ] && [ -n "${reasoning:-}" ]; then
    echo "  Grader: $reasoning"
  fi
done

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "=== Results ==="
echo "Total: $TOTAL  Passed: $PASS  Failed: $FAIL  Errors: $ERRORS"
echo "Traces: $ARTIFACTS_DIR/"

[ "$FAIL" -eq 0 ] && [ "$ERRORS" -eq 0 ] || exit 1
