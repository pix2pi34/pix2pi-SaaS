#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_2_5_pitr_provasi.v1.json}"
REHEARSAL_FILE="${2:-configs/faz6r/pitr_rehearsal.ha_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_2_5_pitr_provasi_test.json}"

python3 - "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
rehearsal_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for item in rehearsal_doc.get("rehearsals", []):
    rows.append({
        "rehearsal_id": item.get("rehearsal_id"),
        "restore_target": item.get("restore_target"),
        "recovery_target_time_status": item.get("recovery_target_time_status"),
        "backup_chain_status": item.get("backup_chain_status"),
        "wal_archive_status": item.get("wal_archive_status"),
        "restore_preflight_status": item.get("restore_preflight_status"),
        "wal_replay_validation_status": item.get("wal_replay_validation_status"),
        "data_integrity_validation_status": item.get("data_integrity_validation_status"),
        "tenant_scope_validation_status": item.get("tenant_scope_validation_status"),
        "rto_minutes": item.get("rto_minutes"),
        "rpo_minutes": item.get("rpo_minutes"),
        "mutation_allowed": item.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_PITR_REHEARSAL_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "pitr_rehearsal_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "restore_execution_allowed": config.get("restore_execution_allowed"),
    "primary_overwrite_allowed": config.get("primary_overwrite_allowed"),
    "replica_rebuild_allowed": config.get("replica_rebuild_allowed"),
    "wal_replay_execution_allowed": config.get("wal_replay_execution_allowed"),
    "backup_delete_allowed": config.get("backup_delete_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "dsn_mutation_allowed": config.get("dsn_mutation_allowed"),
    "application_route_mutation_allowed": config.get("application_route_mutation_allowed"),
    "rehearsal_count": len(rows),
    "next_step": rehearsal_doc.get("next_step", {}).get("step"),
    "rehearsals": rows
}, indent=2, ensure_ascii=False))
PY
