#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_5_cost_performance_raporu.v1.json}"
REPORT_FILE="${2:-configs/faz6r/cost_performance_report.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_5_cost_performance_raporu_test.json}"

python3 - "$CONFIG_FILE" "$REPORT_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for row in report.get("category_summaries", []):
    rows.append({
        "report_id": report.get("report_id"),
        "category": row.get("category"),
        "recommendation_count": row.get("recommendation_count"),
        "estimated_savings_level": row.get("estimated_savings_level"),
        "risk_level": row.get("risk_level"),
        "priority": row.get("priority"),
        "guard_status": row.get("guard_status"),
        "approval_required": row.get("approval_required"),
        "mutation_allowed": row.get("mutation_allowed"),
        "next_action": row.get("next_action"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_COST_PERFORMANCE_REPORT_ROW"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "cost_performance_report_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "production_change_allowed": config.get("production_change_allowed"),
    "cost_action_execute_allowed": config.get("cost_action_execute_allowed"),
    "category_count": len(rows),
    "risk_count": len(report.get("risk_impact_matrix", [])),
    "next_step": report.get("final_recommendation", {}).get("first_next_tuning_step"),
    "rows": rows
}, indent=2, ensure_ascii=False))
PY
