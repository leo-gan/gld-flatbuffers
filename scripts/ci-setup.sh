#!/usr/bin/env bash
# Install pixi and Mojo 1.0.0 for this repo.
# conda.modular.com may require a prefix.dev token. Put PREFIX_API_KEY in a
# local .env file. Do not commit that file.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if ! command -v pixi >/dev/null 2>&1; then
  echo "pixi not found; installing to ~/.pixi/bin" >&2
  curl -fsSL https://pixi.sh/install.sh | bash
  export PATH="${HOME}/.pixi/bin:${PATH}"
fi

if ! command -v pixi >/dev/null 2>&1; then
  echo "pixi is still not on PATH" >&2
  exit 1
fi

echo "pixi: $(pixi --version)"
echo "pin: mojo == 1.0.0"

if ! pixi install; then
  echo "pixi install failed." >&2
  echo "If the error is 401 on conda.modular.com, set PREFIX_API_KEY in .env and retry." >&2
  exit 1
fi

pixi run mojo --version
echo "ok: $(pixi run mojo --version)"
