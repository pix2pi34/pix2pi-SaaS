#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_4_visual_regression_seti.v1.json}"
SET_FILE="${2:-configs/faz6r/visual_regression_set.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_4_visual_regression_seti_test.json}"

python3 - "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
visual_set = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in visual_set.get("checks", []):
    rows.append({
        "visual_check_id": rec.get("visual_check_id"),
        "surface": rec.get("surface"),
        "viewport_status": rec.get("viewport_status"),
        "theme_status": rec.get("theme_status"),
        "state_snapshot_status": rec.get("state_snapshot_status"),
        "diff_threshold_status": rec.get("diff_threshold_status"),
        "a11y_guard_status": rec.get("a11y_guard_status"),
        "performance_guard_status": rec.get("performance_guard_status"),
        "pii_secret_mask_status": rec.get("pii_secret_mask_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_VISUAL_REGRESSION_SET_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "visual_regression_set_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "screenshot_baseline_mutation_allowed": config.get("screenshot_baseline_mutation_allowed"),
    "snapshot_update_allowed": config.get("snapshot_update_allowed"),
    "visual_approval_mutation_allowed": config.get("visual_approval_mutation_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "route_mutation_allowed": config.get("route_mutation_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "check_count": len(rows),
    "next_step": visual_set.get("next_step", {}).get("step"),
    "checks": rows
}, indent=2, ensure_ascii=False))
PY
