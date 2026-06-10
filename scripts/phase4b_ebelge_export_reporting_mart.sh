#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

MIGRATION_BASE="${MIGRATION_BASE:-20260428_153001_ebelge_export_reporting_mart}" \
python3 "$SCRIPT_DIR/phase4b_ebelge_export_reporting_mart.py" "$ROOT_DIR"
