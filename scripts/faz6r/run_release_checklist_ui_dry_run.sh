#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_6_release_checklist_ui.v1.json}"
UI_FILE="${2:-configs/faz6r/release_checklist_ui.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_6_release_checklist_ui_test.json}"

python3 - "$CONFIG_FILE" "$UI_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
ui = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in ui.get("checks", []):
    rows.append({
        "ui_check_id": rec.get("ui_check_id"),
        "section": rec.get("section"),
        "dependency_gate_status": rec.get("dependency_gate_status"),
        "blocker_status": rec.get("blocker_status"),
        "approval_display_status": rec.get("approval_display_status"),
        "rollback_display_status": rec.get("rollback_display_status"),
        "permission_guard_status": rec.get("permission_guard_status"),
        "tenant_guard_status": rec.get("tenant_guard_status"),
        "audit_link_status": rec.get("audit_link_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_RELEASE_CHECKLIST_UI_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "release_checklist_ui_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "ui_deploy_allowed": config.get("ui_deploy_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "route_mutation_allowed": config.get("route_mutation_allowed"),
    "checklist_state_mutation_allowed": config.get("checklist_state_mutation_allowed"),
    "approval_state_mutation_allowed": config.get("approval_state_mutation_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "check_count": len(rows),
    "next_step": ui.get("next_step", {}).get("step"),
    "checks": rows
}, indent=2, ensure_ascii=False))
PY
