#!/usr/bin/env bash
# Regenerate tests/generated from the .fbs schemas.
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

mkdir -p tests/generated
for schema in testdata/schema/*.fbs; do
  case "$(basename "$schema")" in
    child.fbs|parent.fbs) continue ;;
  esac
  "${MOJO[@]}" run -I src src/codegen/cli.mojo --fbs "$schema" --out tests/generated
done
