#!/usr/bin/env bash
# Fail when tests/generated drifts from the .fbs and .bfbs front ends.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
elif command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
else
  echo "mojo not found" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for schema in testdata/schema/benchmark_v2 testdata/schema/features; do
  "${MOJO[@]}" run -I src src/codegen/cli.mojo --fbs "${schema}.fbs" --out "$tmp/fbs"
  "${MOJO[@]}" run -I src src/codegen/cli.mojo --bfbs "${schema}.bfbs" --out "$tmp/bfbs"
  stem="$(basename "$schema")"
  diff -u "$tmp/fbs/${stem}.mojo" "$tmp/bfbs/${stem}.mojo"
  diff -u "tests/generated/${stem}.mojo" "$tmp/fbs/${stem}.mojo"
done
echo "generated sources match both schema front ends"
