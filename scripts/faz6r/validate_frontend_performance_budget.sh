#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_22_3_frontend_performance_budget.v1.json}"
BUDGET_FILE="${2:-configs/faz6r/frontend_performance_budget.web_release.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_22_3_frontend_performance_budget_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_frontend_performance_budget_dry_run.sh}"

python3 - "$CONFIG_FILE" "$BUDGET_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
budget_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(budget_path.exists(), f"budget missing: {budget_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    budget = json.loads(budget_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "309", "item must be 309")
    require(config.get("code") == "FAZ_6_22_3", "code must be FAZ_6_22_3")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "bundle_mutation_allowed",
        "cdn_invalidation_allowed",
        "route_mutation_allowed",
        "asset_pipeline_mutation_allowed",
        "compression_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    cwv = config.get("core_web_vitals_budget_policy", {})
    require(cwv.get("enabled") is True, "Core Web Vitals policy enabled")
    require(cwv.get("lcp_ms_target") <= 2500, "LCP target too high")
    require(cwv.get("inp_ms_target") <= 200, "INP target too high")
    require(cwv.get("cls_target") <= 0.1, "CLS target too high")
    require(cwv.get("ttfb_ms_target") <= 800, "TTFB target too high")
    require(cwv.get("block_if_lcp_above_target") is True, "LCP block required")
    require(cwv.get("block_if_inp_above_target") is True, "INP block required")
    require(cwv.get("block_if_cls_above_target") is True, "CLS block required")

    routes = {r.get("route") for r in config.get("route_budgets", [])}
    for route in fixture.get("expected_routes", []):
        require(route in routes, f"route budget missing: {route}")

    asset = config.get("asset_budget_policy", {})
    require(asset.get("enabled") is True, "asset budget enabled")
    require(asset.get("total_js_kb_max") <= 350, "total JS budget too high")
    require(asset.get("total_css_kb_max") <= 120, "total CSS budget too high")
    require(asset.get("total_image_kb_max") <= 1000, "image budget too high")
    require(asset.get("font_kb_max") <= 120, "font budget too high")
    require(asset.get("third_party_script_kb_max") <= 120, "third-party script budget too high")
    require(asset.get("block_if_unknown_third_party_script") is True, "third-party block required")
    require(asset.get("block_if_uncompressed_assets") is True, "uncompressed asset block required")

    cache = config.get("cache_budget_policy", {})
    require(cache.get("enabled") is True, "cache budget policy enabled")
    require(cache.get("static_asset_cache_required") is True, "static asset cache required")
    require(cache.get("html_no_cache_policy_required") is True, "HTML no-cache required")
    require(cache.get("hashed_asset_policy_required") is True, "hashed asset policy required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "frontend_deploy_execute",
        "build_publish_execute",
        "bundle_mutation_execute",
        "cdn_invalidation_execute",
        "route_mutation_execute",
        "asset_pipeline_mutation_execute",
        "compression_mutation_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "frontend_deploy_allowed",
        "build_publish_allowed",
        "bundle_mutation_allowed",
        "cdn_invalidation_allowed",
        "route_mutation_allowed",
        "asset_pipeline_mutation_allowed",
        "compression_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "budget_id",
        "route",
        "lcp_status",
        "inp_status",
        "cls_status",
        "js_budget_status",
        "css_budget_status",
        "image_budget_status",
        "cache_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(budget.get("status") == fixture.get("expected_status"), "budget status mismatch")
    records = budget.get("budgets", [])
    require(len(records) >= fixture.get("expected_min_budget_count"), "budget count below minimum")

    record_routes = {r.get("route") for r in records}
    for route in fixture.get("expected_routes", []):
        require(route in record_routes, f"budget route missing: {route}")

    for r in records:
        require(bool(r.get("budget_id")), "budget id missing")
        require(r.get("route") in routes, f"invalid route: {r.get('route')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('budget_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('budget_id')}")
        require(bool(r.get("lcp_status")), f"LCP status missing: {r.get('budget_id')}")
        require(bool(r.get("inp_status")), f"INP status missing: {r.get('budget_id')}")
        require(bool(r.get("cls_status")), f"CLS status missing: {r.get('budget_id')}")
        require(bool(r.get("js_budget_status")), f"JS budget missing: {r.get('budget_id')}")
        require(bool(r.get("css_budget_status")), f"CSS budget missing: {r.get('budget_id')}")
        require(bool(r.get("image_budget_status")), f"image budget missing: {r.get('budget_id')}")
        require(bool(r.get("cache_status")), f"cache status missing: {r.get('budget_id')}")

    next_step = budget.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(budget_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "frontend_performance_budget_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "frontend_deploy_allowed",
            "build_publish_allowed",
            "bundle_mutation_allowed",
            "cdn_invalidation_allowed",
            "route_mutation_allowed",
            "asset_pipeline_mutation_allowed",
            "compression_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("budget_count") >= fixture.get("expected_min_budget_count"), "runtime budget count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("budgets", []):
            require(row.get("status") == "DRY_RUN_FRONTEND_PERFORMANCE_BUDGET_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Frontend performance budget config, budget, fixture and dry-run runtime are semantically valid")
PY
