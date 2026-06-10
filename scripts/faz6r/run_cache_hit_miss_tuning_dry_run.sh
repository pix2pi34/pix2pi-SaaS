#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_3_3_cache_hit_miss_tuning.v1.json}"
TUNING_FILE="${2:-configs/faz6r/cache_hit_miss_tuning.performance_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_3_3_cache_hit_miss_tuning_test.json}"

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
        "cache_surface": rec.get("cache_surface"),
        "current_signal": rec.get("current_signal"),
        "recommended_action": rec.get("recommended_action"),
        "expected_hit_ratio_impact": rec.get("expected_hit_ratio_impact"),
        "risk_level": rec.get("risk_level"),
        "tenant_namespace_guard_status": rec.get("tenant_namespace_guard_status"),
        "fallback_safety_status": rec.get("fallback_safety_status"),
        "stale_data_guard_status": rec.get("stale_data_guard_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_CACHE_TUNING_RECOMMENDATION_ONLY"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "cache_hit_miss_tuning_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "redis_mutation_allowed": config.get("redis_mutation_allowed"),
    "cache_flush_allowed": config.get("cache_flush_allowed"),
    "cache_key_delete_allowed": config.get("cache_key_delete_allowed"),
    "cache_ttl_mutation_allowed": config.get("cache_ttl_mutation_allowed"),
    "namespace_mutation_allowed": config.get("namespace_mutation_allowed"),
    "recommendation_count": len(rows),
    "recommendations": rows
}, indent=2, ensure_ascii=False))
PY
