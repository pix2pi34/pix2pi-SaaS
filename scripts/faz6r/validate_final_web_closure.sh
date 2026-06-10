#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_8_final_web_closure.v1.json}"
CLOSURE_FILE="${2:-configs/faz6r/final_web_closure.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_8_final_web_closure_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_final_web_closure_dry_run.sh}"

python3 - "$CONFIG_FILE" "$CLOSURE_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
closure_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(closure_path.exists(), f"closure missing: {closure_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    closure = json.loads(closure_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "311", "item must be 311")
    require(config.get("code") == "FAZ_6_22_8", "code must be FAZ_6_22_8")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "route_mutation_allowed",
        "cdn_invalidation_allowed",
        "dns_mutation_allowed",
        "nginx_mutation_allowed",
        "asset_pipeline_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    dep = config.get("dependency_evidence_policy", {})
    require(dep.get("enabled") is True, "dependency evidence policy enabled")
    require(dep.get("block_if_any_dependency_not_pass") is True, "dependency pass block required")
    for evidence in [
        "FAZ_6_22_2_ACCESSIBILITY_FINALIZASYON_REAL_IMPLEMENTATION_AUDIT",
        "FAZ_6_22_3_FRONTEND_PERFORMANCE_BUDGET_REAL_IMPLEMENTATION_AUDIT",
        "FAZ_6_22_4_VISUAL_REGRESSION_SETI_REAL_IMPLEMENTATION_AUDIT"
    ]:
        require(evidence in dep.get("required_evidence", []), f"dependency evidence missing: {evidence}")

    surfaces = {s.get("surface") for s in config.get("closure_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"closure surface missing: {surface}")

    blocker = config.get("release_blocker_policy", {})
    require(blocker.get("enabled") is True, "release blocker policy enabled")
    for field in [
        "block_if_accessibility_fail",
        "block_if_performance_budget_fail",
        "block_if_visual_regression_fail",
        "block_if_unreviewed_critical_route",
        "block_if_unapproved_risk",
        "accepted_risk_requires_owner"
    ]:
        require(blocker.get(field) is True, f"release blocker missing: {field}")

    rollback = config.get("rollback_readiness_policy", {})
    require(rollback.get("enabled") is True, "rollback readiness enabled")
    for field in [
        "previous_build_reference_required",
        "asset_rollback_reference_required",
        "cdn_rollback_plan_required",
        "route_rollback_plan_required",
        "manual_approval_required"
    ]:
        require(rollback.get(field) is True, f"rollback readiness missing: {field}")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "frontend_deploy_execute",
        "build_publish_execute",
        "route_mutation_execute",
        "cdn_invalidation_execute",
        "dns_mutation_execute",
        "nginx_mutation_execute",
        "asset_pipeline_mutation_execute",
        "final_web_release_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "route_mutation_allowed",
        "cdn_invalidation_allowed",
        "dns_mutation_allowed",
        "nginx_mutation_allowed",
        "asset_pipeline_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "closure_id",
        "surface",
        "accessibility_gate_status",
        "performance_gate_status",
        "visual_regression_gate_status",
        "release_blocker_status",
        "rollback_readiness_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(closure.get("status") == fixture.get("expected_status"), "closure status mismatch")
    records = closure.get("closure_records", [])
    require(len(records) >= fixture.get("expected_min_closure_count"), "closure count below minimum")

    record_surfaces = {r.get("surface") for r in records}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in record_surfaces, f"closure record surface missing: {surface}")

    for r in records:
        require(bool(r.get("closure_id")), "closure id missing")
        require(r.get("surface") in surfaces, f"invalid surface: {r.get('surface')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('closure_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('closure_id')}")
        require(bool(r.get("accessibility_gate_status")), f"accessibility gate missing: {r.get('closure_id')}")
        require(bool(r.get("performance_gate_status")), f"performance gate missing: {r.get('closure_id')}")
        require(bool(r.get("visual_regression_gate_status")), f"visual regression gate missing: {r.get('closure_id')}")
        require(bool(r.get("release_blocker_status")), f"release blocker missing: {r.get('closure_id')}")
        require(bool(r.get("rollback_readiness_status")), f"rollback readiness missing: {r.get('closure_id')}")

    next_step = closure.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(closure_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "final_web_closure_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "frontend_deploy_allowed",
            "build_publish_allowed",
            "route_mutation_allowed",
            "cdn_invalidation_allowed",
            "dns_mutation_allowed",
            "nginx_mutation_allowed",
            "asset_pipeline_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("closure_count") >= fixture.get("expected_min_closure_count"), "runtime closure count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("closure_records", []):
            require(row.get("status") == "DRY_RUN_FINAL_WEB_CLOSURE_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Final web closure config, closure, fixture and dry-run runtime are semantically valid")
PY
