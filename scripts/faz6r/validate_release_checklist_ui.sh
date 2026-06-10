#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_6_release_checklist_ui.v1.json}"
UI_FILE="${2:-configs/faz6r/release_checklist_ui.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_6_release_checklist_ui_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_release_checklist_ui_dry_run.sh}"

python3 - "$CONFIG_FILE" "$UI_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
ui_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(ui_path.exists(), f"ui missing: {ui_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    ui = json.loads(ui_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "314", "item must be 314")
    require(config.get("code") == "FAZ_6_22_6", "code must be FAZ_6_22_6")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "ui_deploy_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "route_mutation_allowed",
        "checklist_state_mutation_allowed",
        "approval_state_mutation_allowed",
        "cdn_invalidation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surface_policy = config.get("ui_surface_policy", {})
    require(surface_policy.get("enabled") is True, "ui surface policy enabled")
    require(surface_policy.get("mode") == "read_only_release_readiness_ui", "ui mode mismatch")
    for field in [
        "block_if_checklist_can_mutate",
        "block_if_approval_can_mutate",
        "block_if_missing_permission_guard",
        "block_if_missing_tenant_guard",
        "block_if_missing_audit_evidence_link"
    ]:
        require(surface_policy.get(field) is True, f"ui surface block missing: {field}")

    sections = {s.get("section") for s in config.get("checklist_sections", [])}
    for section in fixture.get("expected_sections", []):
        require(section in sections, f"section missing: {section}")

    visibility = config.get("visibility_policy", {})
    require(visibility.get("enabled") is True, "visibility policy enabled")
    for field in [
        "requires_authenticated_user",
        "requires_tenant_scope",
        "requires_release_role",
        "block_cross_tenant_evidence",
        "mask_sensitive_evidence_paths"
    ]:
        require(visibility.get(field) is True, f"visibility policy missing: {field}")
    for role in ["TENANT_ADMIN", "OWNER", "SUPER_ADMIN"]:
        require(role in visibility.get("allowed_roles", []), f"allowed role missing: {role}")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "ui_deploy_execute",
        "frontend_deploy_execute",
        "build_publish_execute",
        "route_mutation_execute",
        "checklist_state_mutation_execute",
        "approval_state_mutation_execute",
        "cdn_invalidation_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "ui_deploy_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "route_mutation_allowed",
        "checklist_state_mutation_allowed",
        "approval_state_mutation_allowed",
        "cdn_invalidation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "ui_check_id",
        "section",
        "dependency_gate_status",
        "blocker_status",
        "approval_display_status",
        "rollback_display_status",
        "permission_guard_status",
        "tenant_guard_status",
        "audit_link_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(ui.get("status") == fixture.get("expected_status"), "ui status mismatch")
    records = ui.get("checks", [])
    require(len(records) >= fixture.get("expected_min_check_count"), "ui check count below minimum")

    record_sections = {r.get("section") for r in records}
    for section in fixture.get("expected_sections", []):
        require(section in record_sections, f"ui check section missing: {section}")

    for r in records:
        require(bool(r.get("ui_check_id")), "ui check id missing")
        require(r.get("section") in sections, f"invalid section: {r.get('section')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('ui_check_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('ui_check_id')}")
        require(bool(r.get("dependency_gate_status")), f"dependency gate missing: {r.get('ui_check_id')}")
        require(bool(r.get("blocker_status")), f"blocker status missing: {r.get('ui_check_id')}")
        require(bool(r.get("approval_display_status")), f"approval display missing: {r.get('ui_check_id')}")
        require(bool(r.get("rollback_display_status")), f"rollback display missing: {r.get('ui_check_id')}")
        require(bool(r.get("permission_guard_status")), f"permission guard missing: {r.get('ui_check_id')}")
        require(bool(r.get("tenant_guard_status")), f"tenant guard missing: {r.get('ui_check_id')}")
        require(bool(r.get("audit_link_status")), f"audit link missing: {r.get('ui_check_id')}")

    next_step = ui.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(ui_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "release_checklist_ui_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "ui_deploy_allowed",
            "frontend_deploy_allowed",
            "build_publish_allowed",
            "route_mutation_allowed",
            "checklist_state_mutation_allowed",
            "approval_state_mutation_allowed",
            "cdn_invalidation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("check_count") >= fixture.get("expected_min_check_count"), "runtime check count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("checks", []):
            require(row.get("status") == "DRY_RUN_RELEASE_CHECKLIST_UI_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Release checklist UI config, UI, fixture and dry-run runtime are semantically valid")
PY
