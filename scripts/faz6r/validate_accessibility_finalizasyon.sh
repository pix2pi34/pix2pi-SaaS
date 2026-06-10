#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_2_accessibility_finalizasyon.v1.json}"
CHECKLIST_FILE="${2:-configs/faz6r/accessibility_finalization.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_2_accessibility_finalizasyon_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_accessibility_finalization_dry_run.sh}"

python3 - "$CONFIG_FILE" "$CHECKLIST_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
checklist_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(checklist_path.exists(), f"checklist missing: {checklist_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    checklist = json.loads(checklist_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "308", "item must be 308")
    require(config.get("code") == "FAZ_6_22_2", "code must be FAZ_6_22_2")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "frontend_deploy_allowed",
        "css_mutation_allowed",
        "js_mutation_allowed",
        "design_token_mutation_allowed",
        "route_mutation_allowed",
        "cdn_invalidation_allowed",
        "build_publish_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    wcag = config.get("wcag_target_policy", {})
    require(wcag.get("enabled") is True, "WCAG target policy enabled")
    require(wcag.get("target") == "WCAG_2_2_AA", "WCAG target must be WCAG_2_2_AA")
    for field in [
        "block_if_critical_flow_not_keyboard_accessible",
        "block_if_focus_indicator_missing",
        "block_if_contrast_below_aa",
        "block_if_form_error_not_announced",
        "block_if_modal_focus_trap_missing"
    ]:
        require(wcag.get(field) is True, f"WCAG block missing: {field}")

    surfaces = {s.get("surface") for s in config.get("accessibility_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    policy = config.get("policy_model", {})
    require(policy.get("mode") == "dry_run_review_only", "policy mode must be dry_run_review_only")
    for key in [
        "keyboard_navigation_required",
        "focus_visible_required",
        "focus_restore_required",
        "modal_focus_trap_required",
        "semantic_landmarks_required",
        "form_error_aria_live_required",
        "toast_notification_aria_live_required",
        "table_header_scope_required",
        "skip_link_required",
        "reduced_motion_policy_required"
    ]:
        require(policy.get(key) is True, f"{key} must be true")

    metric = config.get("metric_model", {})
    require(metric.get("requires_per_surface_breakdown") is True, "per-surface breakdown required")
    require(metric.get("requires_critical_flow_breakdown") is True, "critical flow breakdown required")
    checks = set(metric.get("required_checks", []))
    for check in [
        "keyboard_tab_order_check",
        "focus_visible_check",
        "focus_trap_check",
        "contrast_ratio_check",
        "semantic_landmark_check",
        "form_error_announcement_check",
        "screen_reader_label_check",
        "skip_link_check"
    ]:
        require(check in checks, f"required check missing: {check}")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "frontend_deploy_execute",
        "css_mutation_execute",
        "js_mutation_execute",
        "design_token_mutation_execute",
        "route_mutation_execute",
        "cdn_invalidation_execute",
        "build_publish_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "frontend_deploy_allowed",
        "css_mutation_allowed",
        "js_mutation_allowed",
        "design_token_mutation_allowed",
        "route_mutation_allowed",
        "cdn_invalidation_allowed",
        "build_publish_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "check_id",
        "surface",
        "wcag_target",
        "keyboard_status",
        "focus_status",
        "contrast_status",
        "semantic_status",
        "aria_status",
        "screen_reader_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(checklist.get("status") == fixture.get("expected_status"), "checklist status mismatch")
    records = checklist.get("checks", [])
    require(len(records) >= fixture.get("expected_min_check_count"), "check count below minimum")

    record_surfaces = {r.get("surface") for r in records}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in record_surfaces, f"check surface missing: {surface}")

    for r in records:
        require(bool(r.get("check_id")), "check id missing")
        require(r.get("surface") in surfaces, f"invalid surface: {r.get('surface')}")
        require(r.get("wcag_target") == "WCAG_2_2_AA", f"WCAG target mismatch: {r.get('check_id')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('check_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('check_id')}")
        require(bool(r.get("keyboard_status")), f"keyboard status missing: {r.get('check_id')}")
        require(bool(r.get("focus_status")), f"focus status missing: {r.get('check_id')}")
        require(bool(r.get("contrast_status")), f"contrast status missing: {r.get('check_id')}")
        require(bool(r.get("semantic_status")), f"semantic status missing: {r.get('check_id')}")
        require(bool(r.get("screen_reader_status")), f"screen reader status missing: {r.get('check_id')}")

    next_step = checklist.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(checklist_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "accessibility_finalization_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "frontend_deploy_allowed",
            "css_mutation_allowed",
            "js_mutation_allowed",
            "design_token_mutation_allowed",
            "route_mutation_allowed",
            "cdn_invalidation_allowed",
            "build_publish_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("check_count") >= fixture.get("expected_min_check_count"), "runtime check count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("checks", []):
            require(row.get("status") == "DRY_RUN_ACCESSIBILITY_FINALIZATION_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Accessibility finalizasyon config, checklist, fixture and dry-run runtime are semantically valid")
PY
