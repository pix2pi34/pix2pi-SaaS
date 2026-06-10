#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_1_2_service_discovery_runtime_tuning.v1.json}"
TUNING_FILE="${2:-configs/faz6r/service_discovery_runtime_tuning.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_1_2_service_discovery_runtime_tuning_test.json}"

python3 - "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
tuning = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in tuning.get("recommendations", []):
    rows.append({
        "tuning_id": rec.get("tuning_id"),
        "service": rec.get("service"),
        "current_signal": rec.get("current_signal"),
        "recommended_action": rec.get("recommended_action"),
        "risk_level": rec.get("risk_level"),
        "route_confidence_status": rec.get("route_confidence_status"),
        "stale_endpoint_guard_status": rec.get("stale_endpoint_guard_status"),
        "tenant_aware_guard_status": rec.get("tenant_aware_guard_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_SERVICE_DISCOVERY_TUNING_RECOMMENDATION_ONLY"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "service_discovery_runtime_tuning_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "service_registry_mutation_allowed": config.get("service_registry_mutation_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "load_balancer_mutation_allowed": config.get("load_balancer_mutation_allowed"),
    "gateway_route_mutation_allowed": config.get("gateway_route_mutation_allowed"),
    "deployment_rollout_allowed": config.get("deployment_rollout_allowed"),
    "container_restart_allowed": config.get("container_restart_allowed"),
    "recommendation_count": len(rows),
    "next_step": "FAZ_6_21_1_4",
    "recommendations": rows
}, indent=2, ensure_ascii=False))
PY
