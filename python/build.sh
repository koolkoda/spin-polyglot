#!/usr/bin/env bash
# Build the Python Spin component with an isolated venv.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

VENV="${ROOT}/.venv"
PYTHON="${VENV}/bin/python"
PIP="${VENV}/bin/pip"
COMPONENTIZE_PY="${VENV}/bin/componentize-py"

if [[ ! -x "${PYTHON}" ]]; then
  python3 -m venv "${VENV}"
fi

"${PIP}" install -q -r requirements.txt

# componentize-py discovers site-packages via VIRTUAL_ENV.
export VIRTUAL_ENV="${VENV}"
export PATH="${VENV}/bin:${PATH}"

exec "${COMPONENTIZE_PY}" \
  -w spin:up/http-trigger@4.0.0 \
  componentize app \
  -p . \
  -o app.wasm \
  "$@"
