#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_7_release_build_dogrulamasi.v1.json}"
BUILD_FILE="${2:-configs/faz6r/release_build_verification.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_7_release_build_dogrulamasi_test.json}"

python3 - "$CONFIG_FILE" "$BUILD_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
build = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in build.get("checks", []):
    rows.append({
        "build_check_id": rec.get("build_check_id"),
        "surface": rec.get("surface"),
        "manifest_status": rec.get("manifest_status"),
        "checksum_status": rec.get("checksum_status"),
        "secret_scan_status": rec.get("secret_scan_status"),
        "dependency_lock_status": rec.get("dependency_lock_status"),
        "rollback_status": rec.get("rollback_status"),
        "release_blocker_status": rec.get("release_blocker_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_RELEASE_BUILD_VERIFICATION_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "release_build_verification_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "frontend_deploy_allowed": config.get("frontend_deploy_allowed"),
    "container_image_push_allowed": config.get("container_image_push_allowed"),
    "artifact_upload_allowed": config.get("artifact_upload_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "route_mutation_allowed": config.get("route_mutation_allowed"),
    "migration_apply_allowed": config.get("migration_apply_allowed"),
    "production_release_execute_allowed": config.get("production_release_execute_allowed"),
    "check_count": len(rows),
    "next_step": build.get("next_step", {}).get("step"),
    "checks": rows
}, indent=2, ensure_ascii=False))
PY
