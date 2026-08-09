#!/usr/bin/env bash
# Reliable Go → Wasm build for Spin.
# Uses componentize-go's patched Go with an isolated GOCACHE to avoid
# wasiOnIdle relocation failures from sharing cache with the host toolchain.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

CACHE_ROOT="${HOME}/Library/Caches"
COMPONENTIZE_BIN="${CACHE_ROOT}/com.github.bytecodealliance-componentize-go/bin/componentize-go"
PATCHED_GO="${CACHE_ROOT}/componentize-go/v2/go-darwin-arm64-bootstrap/bin/go"

# Ensure the release binary is cached (go tool downloads it on first run).
if [[ ! -x "${COMPONENTIZE_BIN}" ]]; then
  go tool componentize-go --help >/dev/null
fi

# Ensure the patched Go toolchain is present.
if [[ ! -x "${PATCHED_GO}" ]]; then
  echo "Downloading patched Go toolchain for componentize-go..."
  # componentize-go downloads the toolchain before compiling; ignore compile errors.
  "${COMPONENTIZE_BIN}" build >/dev/null 2>&1 || true
fi

if [[ ! -x "${PATCHED_GO}" ]]; then
  echo "error: patched Go not found at ${PATCHED_GO}" >&2
  echo "hint: run 'go tool componentize-go build' once to seed the cache" >&2
  exit 1
fi

export GOCACHE="${ROOT}/.gocache"
mkdir -p "${GOCACHE}"

exec "${COMPONENTIZE_BIN}" build --go "${PATCHED_GO}" "$@"
