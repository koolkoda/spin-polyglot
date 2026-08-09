#!/usr/bin/env bash
# Reliable Go → Wasm build for Spin.
# Uses componentize-go's patched Go with an isolated GOCACHE to avoid
# wasiOnIdle relocation failures from sharing cache with the host toolchain.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}" in
  Darwin) CACHE_HOME="${HOME}/Library/Caches"; GO_OS="darwin" ;;
  Linux)  CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"; GO_OS="linux" ;;
  *)
    echo "error: unsupported OS: ${OS}" >&2
    exit 1
    ;;
esac

case "${ARCH}" in
  arm64|aarch64) GO_ARCH="arm64" ;;
  x86_64|amd64)  GO_ARCH="amd64" ;;
  *)
    echo "error: unsupported arch: ${ARCH}" >&2
    exit 1
    ;;
esac

COMPONENTIZE_BIN="${CACHE_HOME}/com.github.bytecodealliance-componentize-go/bin/componentize-go"
PATCHED_ROOT="${CACHE_HOME}/componentize-go/v2/go-${GO_OS}-${GO_ARCH}-bootstrap"
PATCHED_GO="${PATCHED_ROOT}/bin/go"

# Ensure the release binary is cached (go tool downloads it on first run).
if [[ ! -x "${COMPONENTIZE_BIN}" ]]; then
  go tool componentize-go --help >/dev/null
fi

# Ensure the patched Go toolchain is present.
if [[ ! -x "${PATCHED_GO}" ]]; then
  echo "Downloading patched Go toolchain for componentize-go..."
  # First build seeds the toolchain cache; ignore compile errors from a shared GOCACHE.
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
