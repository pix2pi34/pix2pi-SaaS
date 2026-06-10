#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

python3 "$SCRIPT_DIR/phase4b_uat_scenario_execution_contract.py" "$ROOT_DIR"
