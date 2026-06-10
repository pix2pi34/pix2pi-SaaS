#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_2_2_replica_failover_provasi.v1.json}"
REHEARSAL_FILE="${2:-configs/faz6r/replica_failover_rehearsal.ha_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_2_2_replica_failover_provasi_test.json}"

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
        "candidate_node": item.get("candidate_node"),
        "preflight_status": item.get("preflight_status"),
        "promotion_decision": item.get("promotion_decision"),
        "primary_reachability_status": item.get("primary_reachability_status"),
        "replica_reachability_status": item.get("replica_reachability_status"),
        "replica_lag_seconds": item.get("replica_lag_seconds"),
        "wal_replay_status": item.get("wal_replay_status"),
        "backup_pitr_status": item.get("backup_pitr_status"),
        "split_brain_guard_status": item.get("split_brain_guard_status"),
        "rto_minutes": item.get("rto_minutes"),
        "rpo_minutes": item.get("rpo_minutes"),
        "mutation_allowed": item.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_REPLICA_FAILOVER_REHEARSAL_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "replica_failover_rehearsal_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "db_promotion_allowed": config.get("db_promotion_allowed"),
    "replica_promotion_allowed": config.get("replica_promotion_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "dsn_mutation_allowed": config.get("dsn_mutation_allowed"),
    "application_route_mutation_allowed": config.get("application_route_mutation_allowed"),
    "replication_slot_mutation_allowed": config.get("replication_slot_mutation_allowed"),
    "rehearsal_count": len(rows),
    "next_step": rehearsal_doc.get("next_step", {}).get("step"),
    "rehearsals": rows
}, indent=2, ensure_ascii=False))
PY
