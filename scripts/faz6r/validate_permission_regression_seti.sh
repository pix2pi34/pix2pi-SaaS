#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_5_permission_regression_seti.v1.json}"
SET_FILE="${2:-configs/faz6r/permission_regression_set.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_5_permission_regression_seti_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_permission_regression_set_dry_run.sh}"

python3 - "$CONFIG_FILE" "$SET_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
set_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(set_path.exists(), f"permission set missing: {set_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    regression_set = json.loads(set_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "313", "item must be 313")
    require(config.get("code") == "FAZ_6_22_5", "code must be FAZ_6_22_5")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "role_permission_mutation_allowed",
        "jwt_claim_mutation_allowed",
        "route_guard_mutation_allowed",
        "api_policy_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("permission_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    policy = config.get("permission_regression_policy", {})
    require(policy.get("enabled") is True, "permission regression policy enabled")
    for field in [
        "requires_api_guard",
        "requires_ui_guard",
        "requires_negative_cases",
        "requires_cross_tenant_deny_case",
        "requires_super_admin_boundary_case",
        "requires_jwt_claim_alignment",
        "block_if_ui_only_guard",
        "block_if_route_without_api_guard",
        "block_if_cross_tenant_access_possible"
    ]:
        require(policy.get(field) is True, f"permission policy missing: {field}")

    role_matrix = config.get("role_matrix_policy", {})
    require(role_matrix.get("enabled") is True, "role matrix policy enabled")
    for role in ["TENANT_ADMIN", "OWNER", "MANAGER", "OPERATOR", "ACCOUNTANT", "READONLY", "SUPER_ADMIN"]:
        require(role in role_matrix.get("required_roles", []), f"role missing: {role}")
    for decision in ["ALLOW", "DENY", "MASK", "REQUIRES_APPROVAL"]:
        require(decision in role_matrix.get("required_decisions", []), f"decision missing: {decision}")
    require(role_matrix.get("requires_per_route_mapping") is True, "per route mapping required")
    require(role_matrix.get("requires_per_action_mapping") is True, "per action mapping required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "role_permission_mutation_execute",
        "jwt_claim_mutation_execute",
        "route_guard_mutation_execute",
        "api_policy_mutation_execute",
        "frontend_deploy_execute",
        "build_publish_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "role_permission_mutation_allowed",
        "jwt_claim_mutation_allowed",
        "route_guard_mutation_allowed",
        "api_policy_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "permission_check_id",
        "surface",
        "role",
        "route_or_action",
        "expected_decision",
        "api_guard_status",
        "ui_guard_status",
        "tenant_scope_status",
        "negative_case_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(regression_set.get("status") == fixture.get("expected_status"), "permission set status mismatch")
    records = regression_set.get("checks", [])
    require(len(records) >= fixture.get("expected_min_check_count"), "permission check count below minimum")

    record_surfaces = {r.get("surface") for r in records}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in record_surfaces, f"permission check surface missing: {surface}")

    for r in records:
        require(bool(r.get("permission_check_id")), "permission check id missing")
        require(r.get("surface") in surfaces, f"invalid surface: {r.get('surface')}")
        require(bool(r.get("role")), f"role missing: {r.get('permission_check_id')}")
        require(bool(r.get("route_or_action")), f"route/action missing: {r.get('permission_check_id')}")
        require(bool(r.get("expected_decision")), f"expected decision missing: {r.get('permission_check_id')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('permission_check_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('permission_check_id')}")
        require(bool(r.get("api_guard_status")), f"api guard missing: {r.get('permission_check_id')}")
        require(bool(r.get("ui_guard_status")), f"ui guard missing: {r.get('permission_check_id')}")
        require(bool(r.get("tenant_scope_status")), f"tenant scope missing: {r.get('permission_check_id')}")
        require(bool(r.get("negative_case_status")), f"negative case missing: {r.get('permission_check_id')}")

    next_step = regression_set.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(set_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "permission_regression_set_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "role_permission_mutation_allowed",
            "jwt_claim_mutation_allowed",
            "route_guard_mutation_allowed",
            "api_policy_mutation_allowed",
            "frontend_deploy_allowed",
            "build_publish_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("check_count") >= fixture.get("expected_min_check_count"), "runtime check count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("checks", []):
            require(row.get("status") == "DRY_RUN_PERMISSION_REGRESSION_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Permission regression seti config, set, fixture and dry-run runtime are semantically valid")
PY
