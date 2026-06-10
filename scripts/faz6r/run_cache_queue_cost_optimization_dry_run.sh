#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_4_cache_queue_maliyet_optimizasyonu.v1.json}"
PLAN_FILE="${2:-configs/faz6r/cache_queue_cost_optimization.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_4_cache_queue_maliyet_optimizasyonu_test.json}"

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
        "surface": rec.get("surface"),
        "resource_class": rec.get("resource_class"),
        "current_cost_driver": rec.get("current_cost_driver"),
        "recommended_action": rec.get("recommended_action"),
        "estimated_savings_level": rec.get("estimated_savings_level"),
        "risk_level": rec.get("risk_level"),
        "tenant_namespace_guard_status": rec.get("tenant_namespace_guard_status"),
        "idempotency_guard_status": rec.get("idempotency_guard_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_CACHE_QUEUE_COST_RECOMMENDATION_ONLY"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "cache_queue_cost_optimization_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "cache_flush_allowed": config.get("cache_flush_allowed"),
    "cache_key_delete_allowed": config.get("cache_key_delete_allowed"),
    "cache_ttl_mutation_allowed": config.get("cache_ttl_mutation_allowed"),
    "queue_purge_allowed": config.get("queue_purge_allowed"),
    "stream_delete_allowed": config.get("stream_delete_allowed"),
    "consumer_delete_allowed": config.get("consumer_delete_allowed"),
    "queue_retention_mutation_allowed": config.get("queue_retention_mutation_allowed"),
    "recommendation_count": len(recommendations),
    "recommendations": recommendations
}, indent=2, ensure_ascii=False))
PY
