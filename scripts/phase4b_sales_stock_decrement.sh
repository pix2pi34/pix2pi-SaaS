#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

MIGRATION_BASE="${MIGRATION_BASE:-20260428_183001_inventory_sales_stock_decrement}" \
python3 "$SCRIPT_DIR/phase4b_sales_stock_decrement.py" "$ROOT_DIR"
