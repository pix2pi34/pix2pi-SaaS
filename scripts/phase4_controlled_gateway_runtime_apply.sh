#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

APPLY_REPORTING_RUNTIME="${APPLY_REPORTING_RUNTIME:-1}" \
python3 "$SCRIPT_DIR/phase4_controlled_gateway_runtime_apply.py" "$ROOT_DIR"
