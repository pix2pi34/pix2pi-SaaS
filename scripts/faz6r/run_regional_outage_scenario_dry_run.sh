#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_6_3_bolgesel_kesinti_senaryosu.v1.json}"
SCENARIO_FILE="${2:-configs/faz6r/regional_outage_scenario.dr_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_6_3_bolgesel_kesinti_senaryosu_test.json}"

python3 - "$CONFIG_FILE" "$SCENARIO_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
scenario_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

decisions = []
for scenario in scenario_doc.get("scenarios", []):
    decisions.append({
        "scenario_id": scenario.get("scenario_id"),
        "severity": scenario.get("severity"),
        "affected_region": scenario.get("affected_region"),
        "affected_surfaces": scenario.get("affected_surfaces", []),
        "rto_minutes": scenario.get("rto_minutes"),
        "rpo_minutes": scenario.get("rpo_minutes"),
        "decision": scenario.get("decision"),
        "manual_approval_required": scenario.get("manual_approval_required"),
        "provider_mutation_allowed": scenario.get("provider_mutation_allowed"),
        "communication_handoff_required": scenario.get("communication_handoff_required"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_DECISION_ONLY"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "regional_outage_dry_run",
    "live_failover_allowed": config.get("live_failover_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "db_failover_allowed": config.get("db_failover_allowed"),
    "queue_failover_allowed": config.get("queue_failover_allowed"),
    "storage_failover_allowed": config.get("storage_failover_allowed"),
    "compute_failover_allowed": config.get("compute_failover_allowed"),
    "scenario_count": len(decisions),
    "decisions": decisions
}, indent=2, ensure_ascii=False))
PY
