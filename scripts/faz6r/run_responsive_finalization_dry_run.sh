#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_1_responsive_finalizasyon.v1.json}"
CHECKLIST_FILE="${2:-configs/faz6r/responsive_finalization.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_1_responsive_finalizasyon_test.json}"

python3 - "$CONFIG_FILE" "$CHECKLIST_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
checklist = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in checklist.get("checks", []):
    rows.append({
        "responsive_check_id": rec.get("responsive_check_id"),
        "surface": rec.get("surface"),
        "mobile_status": rec.get("mobile_status"),
        "tablet_status": rec.get("tablet_status"),
        "desktop_status": rec.get("desktop_status"),
        "overflow_guard_status": rec.get("overflow_guard_status"),
        "touch_target_status": rec.get("touch_target_status"),
        "navigation_status": rec.get("navigation_status"),
        "form_table_modal_status": rec.get("form_table_modal_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_RESPONSIVE_FINALIZATION_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "responsive_finalization_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "css_mutation_allowed": config.get("css_mutation_allowed"),
    "layout_mutation_allowed": config.get("layout_mutation_allowed"),
    "breakpoint_mutation_allowed": config.get("breakpoint_mutation_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "check_count": len(rows),
    "next_step": checklist.get("next_step", {}).get("step"),
    "checks": rows
}, indent=2, ensure_ascii=False))
PY
