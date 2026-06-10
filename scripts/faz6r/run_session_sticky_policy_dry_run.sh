#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_1_4_session_sticky_policy.v1.json}"
POLICY_FILE="${2:-configs/faz6r/session_sticky_policy.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_1_4_session_sticky_policy_test.json}"

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
        "policy_id": rec.get("policy_id"),
        "surface": rec.get("surface"),
        "current_signal": rec.get("current_signal"),
        "recommended_action": rec.get("recommended_action"),
        "risk_level": rec.get("risk_level"),
        "tenant_aware_guard_status": rec.get("tenant_aware_guard_status"),
        "stateless_fallback_status": rec.get("stateless_fallback_status"),
        "session_store_health_status": rec.get("session_store_health_status"),
        "cookie_security_status": rec.get("cookie_security_status"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_SESSION_STICKY_POLICY_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "session_sticky_policy_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "gateway_session_mutation_allowed": config.get("gateway_session_mutation_allowed"),
    "load_balancer_sticky_mutation_allowed": config.get("load_balancer_sticky_mutation_allowed"),
    "nginx_mutation_allowed": config.get("nginx_mutation_allowed"),
    "redis_session_mutation_allowed": config.get("redis_session_mutation_allowed"),
    "cookie_policy_mutation_allowed": config.get("cookie_policy_mutation_allowed"),
    "deployment_rollout_allowed": config.get("deployment_rollout_allowed"),
    "recommendation_count": len(rows),
    "next_step": "FAZ_6_21_1_5",
    "recommendations": rows
}, indent=2, ensure_ascii=False))
PY
