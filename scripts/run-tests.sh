#!/usr/bin/env bash
# Run every top-level tests/test_*.mojo file with -I src.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
elif command -v pixi >/dev/null 2>&1 && [[ -d "$root/.pixi" ]]; then
  MOJO=(pixi run mojo)
else
  echo "mojo not found; run pixi install" >&2
  exit 1
fi

shopt -s nullglob
files=("$root"/tests/test_*.mojo)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "no tests/test_*.mojo files" >&2
  exit 1
fi

fail=0
for f in "${files[@]}"; do
  echo "=== ${f#"$root"/} ==="
  if ! "${MOJO[@]}" run -I src -I tests -I tests/generated "$f"; then
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "one or more test files failed" >&2
  exit 1
fi
echo "all test files passed"
