#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

MIGRATION_BASE="${MIGRATION_BASE:-20260428_186001_inventory_negative_stock_policy}" \
python3 "$SCRIPT_DIR/phase4b_negative_stock_policy.py" "$ROOT_DIR"
