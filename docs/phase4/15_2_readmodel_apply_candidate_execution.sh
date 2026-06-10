#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the FAZ 4 / 15.2 readmodel apply candidate execution file."
echo "15.2 gate does not execute migration apply."
echo "Actual apply belongs to FAZ 4 / 15.3 with explicit approval."
exit 99

# FAZ 4 / 15.2 - Readmodel Apply Candidate Execution
# Generated at: 2026-04-27 18:07:17 +0300
# This file is intentionally blocked by exit 99 above.

cd ~/pix2pi/pix2pi-SaaS

MIGRATION_BASE="20260427_151001_readmodel_operational_tables"
UP_FILE="db/migrations/20260427_151001_readmodel_operational_tables.up.sql"
DOWN_FILE="db/migrations/20260427_151001_readmodel_operational_tables.down.sql"

# Required explicit env:
# export APPLY_READMODEL=1
# export DB_WRITE_DSN='***'

if [ "${APPLY_READMODEL:-0}" != "1" ]; then
  echo "APPLY_READMODEL_NOT_CONFIRMED"
  exit 2
fi

# Mandatory pre-checks:
bash scripts/phase4_readmodel_apply_gate.sh . "$MIGRATION_BASE"

# Candidate apply command:
# psql "${DB_WRITE_DSN:?DB_WRITE_DSN required}" -v ON_ERROR_STOP=1 -f "$UP_FILE"

# Mandatory post-checks after actual apply:
# bash scripts/phase4_readmodel_apply_gate.sh . "$MIGRATION_BASE"
# Verify READMODEL_TARGET_TABLE_COUNT=6
