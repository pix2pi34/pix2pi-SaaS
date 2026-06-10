#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_5_permission_regression_seti.v1.json}"
SET_FILE="${2:-configs/faz6r/permission_regression_set.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_5_permission_regression_seti_test.json}"

python3 - "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
regression_set = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in regression_set.get("checks", []):
    rows.append({
        "permission_check_id": rec.get("permission_check_id"),
        "surface": rec.get("surface"),
        "role": rec.get("role"),
        "route_or_action": rec.get("route_or_action"),
        "expected_decision": rec.get("expected_decision"),
        "api_guard_status": rec.get("api_guard_status"),
        "ui_guard_status": rec.get("ui_guard_status"),
        "tenant_scope_status": rec.get("tenant_scope_status"),
        "negative_case_status": rec.get("negative_case_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_PERMISSION_REGRESSION_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "permission_regression_set_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "role_permission_mutation_allowed": config.get("role_permission_mutation_allowed"),
    "jwt_claim_mutation_allowed": config.get("jwt_claim_mutation_allowed"),
    "route_guard_mutation_allowed": config.get("route_guard_mutation_allowed"),
    "api_policy_mutation_allowed": config.get("api_policy_mutation_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "check_count": len(rows),
    "next_step": regression_set.get("next_step", {}).get("step"),
    "checks": rows
}, indent=2, ensure_ascii=False))
PY
