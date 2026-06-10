#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_1_5_node_health_fencing.v1.json}"
POLICY_FILE="${2:-configs/faz6r/node_health_fencing.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_1_5_node_health_fencing_test.json}"

python3 - "$CONFIG_FILE" "$POLICY_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
policy = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in policy.get("recommendations", []):
    rows.append({
        "fencing_id": rec.get("fencing_id"),
        "node_class": rec.get("node_class"),
        "current_signal": rec.get("current_signal"),
        "fencing_decision": rec.get("fencing_decision"),
        "risk_level": rec.get("risk_level"),
        "quorum_guard_status": rec.get("quorum_guard_status"),
        "split_brain_guard_status": rec.get("split_brain_guard_status"),
        "tenant_traffic_guard_status": rec.get("tenant_traffic_guard_status"),
        "session_affinity_guard_status": rec.get("session_affinity_guard_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_NODE_HEALTH_FENCING_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "node_health_fencing_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "node_cordon_allowed": config.get("node_cordon_allowed"),
    "node_drain_allowed": config.get("node_drain_allowed"),
    "node_restart_allowed": config.get("node_restart_allowed"),
    "node_shutdown_allowed": config.get("node_shutdown_allowed"),
    "lb_detach_allowed": config.get("lb_detach_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "gateway_route_mutation_allowed": config.get("gateway_route_mutation_allowed"),
    "service_registry_mutation_allowed": config.get("service_registry_mutation_allowed"),
    "container_kill_allowed": config.get("container_kill_allowed"),
    "deployment_rollout_allowed": config.get("deployment_rollout_allowed"),
    "recommendation_count": len(rows),
    "next_step": policy.get("next_step", {}).get("step"),
    "recommendations": rows
}, indent=2, ensure_ascii=False))
PY
