#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

MIGRATION_BASE="${MIGRATION_BASE:-20260429_213001_security_audit_event_model}" \
python3 "$SCRIPT_DIR/phase4b_audit_event_model.py" "$ROOT_DIR"
