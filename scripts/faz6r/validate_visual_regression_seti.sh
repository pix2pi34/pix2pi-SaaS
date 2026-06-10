#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_4_visual_regression_seti.v1.json}"
SET_FILE="${2:-configs/faz6r/visual_regression_set.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_4_visual_regression_seti_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_visual_regression_set_dry_run.sh}"

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
require(set_path.exists(), f"visual set missing: {set_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    visual_set = json.loads(set_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "310", "item must be 310")
    require(config.get("code") == "FAZ_6_22_4", "code must be FAZ_6_22_4")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "screenshot_baseline_mutation_allowed",
        "snapshot_update_allowed",
        "visual_approval_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "route_mutation_allowed",
        "cdn_invalidation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    target = config.get("visual_target_policy", {})
    require(target.get("enabled") is True, "visual target policy enabled")
    require(target.get("mode") == "dry_run_review_only", "target mode must be dry_run_review_only")
    require(target.get("max_pixel_diff_ratio") <= 0.01, "pixel diff threshold too high")
    require(target.get("max_layout_shift_ratio") <= 0.005, "layout shift threshold too high")
    for field in [
        "block_if_critical_route_missing",
        "block_if_viewport_matrix_missing",
        "block_if_theme_matrix_missing",
        "block_if_pii_secret_mask_missing",
        "block_if_accessibility_or_performance_guard_missing"
    ]:
        require(target.get(field) is True, f"target block missing: {field}")

    viewport = config.get("viewport_matrix", {})
    require(viewport.get("enabled") is True, "viewport matrix enabled")
    for vp in ["desktop_1440x900", "laptop_1366x768", "tablet_768x1024", "mobile_390x844"]:
        require(vp in viewport.get("required_viewports", []), f"viewport missing: {vp}")

    theme = config.get("theme_matrix", {})
    require(theme.get("enabled") is True, "theme matrix enabled")
    for th in ["light", "dark"]:
        require(th in theme.get("required_themes", []), f"theme missing: {th}")
    require(theme.get("contrast_guard_required") is True, "contrast guard required")

    surfaces = {s.get("surface") for s in config.get("critical_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    deterministic = config.get("deterministic_fixture_policy", {})
    require(deterministic.get("enabled") is True, "deterministic fixture policy enabled")
    for field in [
        "fixed_clock_required",
        "fixed_seed_required",
        "network_mock_required",
        "animation_disable_required",
        "font_loading_control_required",
        "pii_secret_masking_required"
    ]:
        require(deterministic.get(field) is True, f"deterministic fixture missing: {field}")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "screenshot_baseline_update_execute",
        "snapshot_update_execute",
        "visual_approval_execute",
        "frontend_deploy_execute",
        "build_publish_execute",
        "route_mutation_execute",
        "cdn_invalidation_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "screenshot_baseline_mutation_allowed",
        "snapshot_update_allowed",
        "visual_approval_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "route_mutation_allowed",
        "cdn_invalidation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "visual_check_id",
        "surface",
        "viewport_status",
        "theme_status",
        "state_snapshot_status",
        "diff_threshold_status",
        "a11y_guard_status",
        "performance_guard_status",
        "pii_secret_mask_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(visual_set.get("status") == fixture.get("expected_status"), "visual set status mismatch")
    records = visual_set.get("checks", [])
    require(len(records) >= fixture.get("expected_min_check_count"), "visual check count below minimum")

    record_surfaces = {r.get("surface") for r in records}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in record_surfaces, f"visual surface missing: {surface}")

    for r in records:
        require(bool(r.get("visual_check_id")), "visual check id missing")
        require(r.get("surface") in surfaces, f"invalid surface: {r.get('surface')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('visual_check_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('visual_check_id')}")
        require(bool(r.get("viewport_status")), f"viewport status missing: {r.get('visual_check_id')}")
        require(bool(r.get("theme_status")), f"theme status missing: {r.get('visual_check_id')}")
        require(bool(r.get("state_snapshot_status")), f"state snapshot missing: {r.get('visual_check_id')}")
        require(bool(r.get("diff_threshold_status")), f"diff threshold missing: {r.get('visual_check_id')}")
        require(bool(r.get("a11y_guard_status")), f"a11y guard missing: {r.get('visual_check_id')}")
        require(bool(r.get("performance_guard_status")), f"performance guard missing: {r.get('visual_check_id')}")
        require(bool(r.get("pii_secret_mask_status")), f"pii mask missing: {r.get('visual_check_id')}")

    next_step = visual_set.get("next_step", {})
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
        require(runtime.get("mode") == "visual_regression_set_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "screenshot_baseline_mutation_allowed",
            "snapshot_update_allowed",
            "visual_approval_mutation_allowed",
            "frontend_deploy_allowed",
            "build_publish_allowed",
            "route_mutation_allowed",
            "cdn_invalidation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("check_count") >= fixture.get("expected_min_check_count"), "runtime check count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("checks", []):
            require(row.get("status") == "DRY_RUN_VISUAL_REGRESSION_SET_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Visual regression seti config, set, fixture and dry-run runtime are semantically valid")
PY
