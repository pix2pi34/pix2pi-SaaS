#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_1_compute_maliyet_optimizasyonu.v1.json}"
PLAN_FILE="${2:-configs/faz6r/compute_cost_optimization.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_1_compute_maliyet_optimizasyonu_test.json}"

python3 - "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
plan = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

recommendations = []
for rec in plan.get("recommendations", []):
    recommendations.append({
        "recommendation_id": rec.get("recommendation_id"),
        "service": rec.get("service"),
        "workload_class": rec.get("workload_class"),
        "current_shape": rec.get("current_shape"),
        "recommended_shape": rec.get("recommended_shape"),
        "estimated_savings_level": rec.get("estimated_savings_level"),
        "risk_level": rec.get("risk_level"),
        "slo_guard_status": rec.get("slo_guard_status"),
        "dr_capacity_guard_status": rec.get("dr_capacity_guard_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_RECOMMENDATION_ONLY"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "compute_cost_optimization_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "production_resize_allowed": config.get("production_resize_allowed"),
    "instance_shutdown_allowed": config.get("instance_shutdown_allowed"),
    "autoscaling_policy_mutation_allowed": config.get("autoscaling_policy_mutation_allowed"),
    "recommendation_count": len(recommendations),
    "recommendations": recommendations
}, indent=2, ensure_ascii=False))
PY
