#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_3_4_rate_limit_tuning.v1.json}"
TUNING_FILE="${2:-configs/faz6r/rate_limit_tuning.performance_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_3_4_rate_limit_tuning_test.json}"

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
        "surface": rec.get("surface"),
        "current_signal": rec.get("current_signal"),
        "recommended_action": rec.get("recommended_action"),
        "expected_effect": rec.get("expected_effect"),
        "risk_level": rec.get("risk_level"),
        "tenant_scope_guard_status": rec.get("tenant_scope_guard_status"),
        "false_positive_guard_status": rec.get("false_positive_guard_status"),
        "security_guard_status": rec.get("security_guard_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_RATE_LIMIT_TUNING_RECOMMENDATION_ONLY"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "rate_limit_tuning_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "gateway_rate_limit_mutation_allowed": config.get("gateway_rate_limit_mutation_allowed"),
    "redis_rate_limit_mutation_allowed": config.get("redis_rate_limit_mutation_allowed"),
    "edge_waf_mutation_allowed": config.get("edge_waf_mutation_allowed"),
    "nginx_mutation_allowed": config.get("nginx_mutation_allowed"),
    "recommendation_count": len(rows),
    "recommendations": rows
}, indent=2, ensure_ascii=False))
PY
