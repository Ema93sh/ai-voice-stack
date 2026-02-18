#!/usr/bin/env bash
set -euo pipefail

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[pre-commit] shellcheck not found, skipping"
  exit 0
fi

staged=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash)$' || true)
# Also check scripts without extension that have bash shebang
staged_no_ext=$(git diff --cached --name-only --diff-filter=ACM | while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in *.sh|*.bash|*.py) continue ;; esac
  head -n1 "$f" 2>/dev/null | grep -q 'bash' && echo "$f" || true
done)

all_files="$staged"
if [ -n "$staged_no_ext" ]; then
  all_files="$(printf '%s\n%s' "$staged" "$staged_no_ext" | sort -u)"
fi

if [ -z "$all_files" ]; then
  exit 0
fi

echo "[pre-commit] shellcheck on staged bash files"
echo "$all_files" | xargs shellcheck -x --exclude=SC1091 || exit 1
