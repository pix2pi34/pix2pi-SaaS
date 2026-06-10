#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

MIGRATION_BASE="${MIGRATION_BASE:-20260428_143001_import_staging_tables}" \
python3 "$SCRIPT_DIR/phase4b_import_staging_tables.py" "$ROOT_DIR"
