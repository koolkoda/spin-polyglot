#!/usr/bin/env bash
# Reliable Go → Wasm build for Spin (macOS + Linux CI).
# Downloads componentize-go + its patched Go toolchain explicitly, then builds
# with an isolated GOCACHE to avoid wasiOnIdle relocation failures.
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

COMPONENTIZE_VERSION="v0.3.3"
COMPONENTIZE_DIR="${CACHE_HOME}/com.github.bytecodealliance-componentize-go/bin"
COMPONENTIZE_BIN="${COMPONENTIZE_DIR}/componentize-go"

PATCHED_CACHE="${CACHE_HOME}/componentize-go/v2"
PATCHED_NAME="go-${GO_OS}-${GO_ARCH}-bootstrap"
PATCHED_GO="${PATCHED_CACHE}/${PATCHED_NAME}/bin/go"

mkdir -p "${COMPONENTIZE_DIR}" "${PATCHED_CACHE}"

if [[ ! -x "${COMPONENTIZE_BIN}" ]]; then
  echo "Downloading componentize-go ${COMPONENTIZE_VERSION}..."
  curl -fsSL \
    "https://github.com/bytecodealliance/componentize-go/releases/download/${COMPONENTIZE_VERSION}/componentize-go-${GO_OS}-${GO_ARCH}.tar.gz" \
    | tar -xz -C "${COMPONENTIZE_DIR}"
  chmod +x "${COMPONENTIZE_BIN}"
fi

if [[ ! -x "${PATCHED_GO}" ]]; then
  echo "Downloading patched Go toolchain (${PATCHED_NAME})..."
  curl -fsSL \
    "https://github.com/dicej/go/releases/download/go1.25.5-wasi-on-idle-v2/${PATCHED_NAME}.tbz" \
    | tar -xj -C "${PATCHED_CACHE}"
fi

if [[ ! -x "${PATCHED_GO}" ]]; then
  echo "error: patched Go not found at ${PATCHED_GO}" >&2
  exit 1
fi

export GOCACHE="${ROOT}/.gocache"
mkdir -p "${GOCACHE}"

# Ensure Spin Go SDK (and its embedded WIT) is in the module cache.
go mod download

exec "${COMPONENTIZE_BIN}" build --go "${PATCHED_GO}" "$@"
