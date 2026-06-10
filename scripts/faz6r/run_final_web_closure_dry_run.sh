#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_8_final_web_closure.v1.json}"
CLOSURE_FILE="${2:-configs/faz6r/final_web_closure.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_8_final_web_closure_test.json}"

python3 - "$CONFIG_FILE" "$CLOSURE_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
closure = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in closure.get("closure_records", []):
    rows.append({
        "closure_id": rec.get("closure_id"),
        "surface": rec.get("surface"),
        "accessibility_gate_status": rec.get("accessibility_gate_status"),
        "performance_gate_status": rec.get("performance_gate_status"),
        "visual_regression_gate_status": rec.get("visual_regression_gate_status"),
        "release_blocker_status": rec.get("release_blocker_status"),
        "rollback_readiness_status": rec.get("rollback_readiness_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_FINAL_WEB_CLOSURE_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "final_web_closure_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "route_mutation_allowed": config.get("route_mutation_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "nginx_mutation_allowed": config.get("nginx_mutation_allowed"),
    "asset_pipeline_mutation_allowed": config.get("asset_pipeline_mutation_allowed"),
    "closure_count": len(rows),
    "next_step": closure.get("next_step", {}).get("step"),
    "closure_records": rows
}, indent=2, ensure_ascii=False))
PY
