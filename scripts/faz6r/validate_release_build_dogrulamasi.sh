#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_7_release_build_dogrulamasi.v1.json}"
BUILD_FILE="${2:-configs/faz6r/release_build_verification.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_7_release_build_dogrulamasi_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_release_build_verification_dry_run.sh}"

python3 - "$CONFIG_FILE" "$BUILD_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
build_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(build_path.exists(), f"build missing: {build_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    build = json.loads(build_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "315", "item must be 315")
    require(config.get("code") == "FAZ_6_22_7", "code must be FAZ_6_22_7")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "build_publish_allowed",
        "frontend_deploy_allowed",
        "container_image_push_allowed",
        "artifact_upload_allowed",
        "cdn_invalidation_allowed",
        "route_mutation_allowed",
        "migration_apply_allowed",
        "production_release_execute_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    policy = config.get("release_candidate_policy", {})
    require(policy.get("enabled") is True, "release candidate policy enabled")
    require(policy.get("mode") == "dry_run_verification_only", "release candidate mode mismatch")
    for field in [
        "requires_manifest",
        "requires_artifact_inventory",
        "requires_checksums",
        "requires_secret_scan",
        "requires_dependency_lock",
        "requires_rollback_manifest",
        "block_if_untracked_release_artifact",
        "block_if_secret_scan_missing",
        "block_if_dependency_lock_missing",
        "block_if_rollback_manifest_missing"
    ]:
        require(policy.get(field) is True, f"release candidate policy missing: {field}")

    surfaces = {s.get("surface") for s in config.get("build_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"build surface missing: {surface}")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "build_publish_execute",
        "frontend_deploy_execute",
        "container_image_push_execute",
        "artifact_upload_execute",
        "cdn_invalidation_execute",
        "route_mutation_execute",
        "migration_apply_execute",
        "production_release_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "build_publish_allowed",
        "frontend_deploy_allowed",
        "container_image_push_allowed",
        "artifact_upload_allowed",
        "cdn_invalidation_allowed",
        "route_mutation_allowed",
        "migration_apply_allowed",
        "production_release_execute_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "build_check_id",
        "surface",
        "manifest_status",
        "checksum_status",
        "secret_scan_status",
        "dependency_lock_status",
        "rollback_status",
        "release_blocker_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(build.get("status") == fixture.get("expected_status"), "build status mismatch")
    records = build.get("checks", [])
    require(len(records) >= fixture.get("expected_min_check_count"), "build check count below minimum")

    record_surfaces = {r.get("surface") for r in records}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in record_surfaces, f"build check surface missing: {surface}")

    for r in records:
        require(bool(r.get("build_check_id")), "build check id missing")
        require(r.get("surface") in surfaces, f"invalid surface: {r.get('surface')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('build_check_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('build_check_id')}")
        require(bool(r.get("manifest_status")), f"manifest status missing: {r.get('build_check_id')}")
        require(bool(r.get("checksum_status")), f"checksum status missing: {r.get('build_check_id')}")
        require(bool(r.get("secret_scan_status")), f"secret scan status missing: {r.get('build_check_id')}")
        require(bool(r.get("dependency_lock_status")), f"dependency lock status missing: {r.get('build_check_id')}")
        require(bool(r.get("rollback_status")), f"rollback status missing: {r.get('build_check_id')}")
        require(bool(r.get("release_blocker_status")), f"release blocker status missing: {r.get('build_check_id')}")

    next_step = build.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(build_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "release_build_verification_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "build_publish_allowed",
            "frontend_deploy_allowed",
            "container_image_push_allowed",
            "artifact_upload_allowed",
            "cdn_invalidation_allowed",
            "route_mutation_allowed",
            "migration_apply_allowed",
            "production_release_execute_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("check_count") >= fixture.get("expected_min_check_count"), "runtime check count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("checks", []):
            require(row.get("status") == "DRY_RUN_RELEASE_BUILD_VERIFICATION_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Release build doğrulaması config, build, fixture and dry-run runtime are semantically valid")
PY
