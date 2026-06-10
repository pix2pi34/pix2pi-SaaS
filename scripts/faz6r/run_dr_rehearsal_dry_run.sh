#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_6_5_dr_rehearsal.v1.json}"
REHEARSAL_FILE="${2:-configs/faz6r/dr_rehearsal.dr_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_6_5_dr_rehearsal_test.json}"

python3 - "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
rehearsal_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

results = []
for item in rehearsal_doc.get("rehearsals", []):
    results.append({
        "rehearsal_id": item.get("rehearsal_id"),
        "scenario_id": item.get("scenario_id"),
        "surface": item.get("surface"),
        "preflight_status": item.get("preflight_status"),
        "rto_target_minutes": item.get("rto_target_minutes"),
        "rpo_target_minutes": item.get("rpo_target_minutes"),
        "measured_rto_status": item.get("measured_rto_status"),
        "measured_rpo_status": item.get("measured_rpo_status"),
        "mutation_allowed": item.get("mutation_allowed"),
        "decision": item.get("decision"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_REHEARSAL_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "dr_rehearsal_dry_run",
    "live_failover_allowed": config.get("live_failover_allowed"),
    "runtime_mutation_allowed": config.get("runtime_mutation_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "db_promotion_allowed": config.get("db_promotion_allowed"),
    "queue_mutation_allowed": config.get("queue_mutation_allowed"),
    "storage_mutation_allowed": config.get("storage_mutation_allowed"),
    "compute_mutation_allowed": config.get("compute_mutation_allowed"),
    "customer_notification_allowed": config.get("customer_notification_allowed"),
    "rehearsal_count": len(results),
    "rehearsals": results
}, indent=2, ensure_ascii=False))
PY
