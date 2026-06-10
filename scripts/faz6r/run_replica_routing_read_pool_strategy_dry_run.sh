#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_20_2_replica_routing_read_pool_stratejisi.v1.json}"
STRATEGY_FILE="${2:-configs/faz6r/replica_routing_read_pool_strategy.db_scale.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_20_2_replica_routing_read_pool_stratejisi_test.json}"

python3 - "$CONFIG_FILE" "$STRATEGY_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
strategy = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in strategy.get("routing_decisions", []):
    rows.append({
        "routing_id": rec.get("routing_id"),
        "surface": rec.get("surface"),
        "target_decision": rec.get("target_decision"),
        "health_score_status": rec.get("health_score_status"),
        "lag_guard_status": rec.get("lag_guard_status"),
        "consistency_guard_status": rec.get("consistency_guard_status"),
        "tenant_scope_guard_status": rec.get("tenant_scope_guard_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_REPLICA_ROUTING_READ_POOL_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "replica_routing_read_pool_strategy_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "dsn_mutation_allowed": config.get("dsn_mutation_allowed"),
    "application_route_mutation_allowed": config.get("application_route_mutation_allowed"),
    "read_pool_attach_allowed": config.get("read_pool_attach_allowed"),
    "read_pool_detach_allowed": config.get("read_pool_detach_allowed"),
    "replica_promotion_allowed": config.get("replica_promotion_allowed"),
    "db_role_mutation_allowed": config.get("db_role_mutation_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "load_balancer_mutation_allowed": config.get("load_balancer_mutation_allowed"),
    "decision_count": len(rows),
    "next_step": strategy.get("next_step", {}).get("step"),
    "routing_decisions": rows
}, indent=2, ensure_ascii=False))
PY
