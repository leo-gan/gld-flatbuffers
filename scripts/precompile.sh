#!/usr/bin/env bash
# Precompile the published packages and build the gld-flatc-mojo CLI.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
export PATH="${HOME}/.pixi/bin:${PATH}"

out="${1:-/tmp/mojo-flatbuffers-pkg}"
mkdir -p "$out"

if command -v pixi >/dev/null 2>&1 && [[ -d "$root/.pixi" ]]; then
  MOJO=(pixi run mojo)
elif command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  echo "mojo not found; run scripts/ci-setup.sh" >&2
  exit 1
fi

"${MOJO[@]}" precompile -I src src/wire -o "$out/wire.mojoc"
"${MOJO[@]}" precompile -I src src/flex -o "$out/flex.mojoc"
"${MOJO[@]}" precompile -I src src/schema -o "$out/schema.mojoc"
"${MOJO[@]}" precompile -I src src/flatbuffers -o "$out/flatbuffers.mojoc"
"${MOJO[@]}" build -I src src/codegen/cli.mojo -o "$out/gld-flatc-mojo"
echo "wrote $out/{wire,flex,schema,flatbuffers}.mojoc and $out/gld-flatc-mojo"
