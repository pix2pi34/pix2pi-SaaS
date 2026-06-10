#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_3_frontend_performance_budget.v1.json}"
BUDGET_FILE="${2:-configs/faz6r/frontend_performance_budget.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_3_frontend_performance_budget_test.json}"

python3 - "$CONFIG_FILE" "$BUDGET_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
budget = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in budget.get("budgets", []):
    rows.append({
        "budget_id": rec.get("budget_id"),
        "route": rec.get("route"),
        "lcp_status": rec.get("lcp_status"),
        "inp_status": rec.get("inp_status"),
        "cls_status": rec.get("cls_status"),
        "js_budget_status": rec.get("js_budget_status"),
        "css_budget_status": rec.get("css_budget_status"),
        "image_budget_status": rec.get("image_budget_status"),
        "cache_status": rec.get("cache_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_FRONTEND_PERFORMANCE_BUDGET_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "frontend_performance_budget_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "bundle_mutation_allowed": config.get("bundle_mutation_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "route_mutation_allowed": config.get("route_mutation_allowed"),
    "asset_pipeline_mutation_allowed": config.get("asset_pipeline_mutation_allowed"),
    "compression_mutation_allowed": config.get("compression_mutation_allowed"),
    "budget_count": len(rows),
    "next_step": budget.get("next_step", {}).get("step"),
    "budgets": rows
}, indent=2, ensure_ascii=False))
PY
