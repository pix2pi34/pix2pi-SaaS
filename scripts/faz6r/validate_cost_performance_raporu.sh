#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_5_cost_performance_raporu.v1.json}"
REPORT_FILE="${2:-configs/faz6r/cost_performance_report.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_5_cost_performance_raporu_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_cost_performance_report_dry_run.sh}"

python3 - "$CONFIG_FILE" "$REPORT_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
report_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(report_path.exists(), f"report missing: {report_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    report = json.loads(report_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "297", "item must be 297")
    require(config.get("code") == "FAZ_6_21_5_5", "code must be FAZ_6_21_5_5")

    deps = set(config.get("depends_on", []))
    for dep in fixture.get("expected_dependencies", []):
        require(dep in deps, f"dependency missing: {dep}")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "production_change_allowed",
        "cost_action_execute_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    categories = set(config.get("report_categories", []))
    for category in fixture.get("expected_categories", []):
        require(category in categories, f"category missing: {category}")

    guard = config.get("guard_policy", {})
    for field in [
        "slo_guard_required",
        "dr_capacity_guard_required",
        "data_safety_guard_required",
        "tenant_isolation_guard_required",
        "manual_approval_required",
        "recommendation_only"
    ]:
        require(guard.get(field) is True, f"guard {field} must be true")

    mutation = config.get("mutation_closed_policy", {})
    require(mutation.get("enabled") is True, "mutation closed policy must be enabled")
    for field in [
        "provider_mutation_allowed",
        "production_change_allowed",
        "resize_allowed",
        "delete_allowed",
        "purge_allowed",
        "retention_mutation_allowed",
        "ttl_mutation_allowed",
        "queue_mutation_allowed",
        "db_mutation_allowed"
    ]:
        require(mutation.get(field) is False, f"mutation {field} must be false")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval must be required")
    for action in ["any_provider_mutation", "any_production_change", "any_resize", "any_delete", "any_purge", "any_retention_change", "any_db_mutation", "any_cache_queue_mutation"]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in ["report_id", "category", "recommendation_count", "estimated_savings_level", "risk_level", "priority", "guard_status", "approval_required", "mutation_allowed", "next_action", "timestamp"]:
        require(field in fields, f"evidence field missing: {field}")

    require(report.get("status") == fixture.get("expected_report_status"), "report status mismatch")
    summaries = report.get("category_summaries", [])
    require(len(summaries) >= fixture.get("expected_min_category_count"), "category summary count below minimum")

    summary_categories = {s.get("category") for s in summaries}
    for category in fixture.get("expected_categories", []):
        require(category in summary_categories, f"summary category missing: {category}")

    for s in summaries:
        require(s.get("approval_required") is True, f"approval must be required: {s.get('category')}")
        require(s.get("mutation_allowed") is False, f"mutation must be false: {s.get('category')}")
        require(bool(s.get("guard_status")), f"guard status missing: {s.get('category')}")
        require(bool(s.get("priority")), f"priority missing: {s.get('category')}")
        require(int(s.get("recommendation_count", 0)) > 0, f"recommendation count invalid: {s.get('category')}")

    risks = report.get("risk_impact_matrix", [])
    require(len(risks) >= fixture.get("expected_min_risk_count"), "risk matrix below minimum")
    for risk in risks:
        require(bool(risk.get("risk")), "risk missing")
        require(bool(risk.get("guard")), "risk guard missing")
        require(risk.get("status") == "REQUIRED", "risk guard status must be REQUIRED")

    final = report.get("final_recommendation", {})
    require(final.get("overall_status") == "REVIEW_READY_NO_MUTATION", "overall status mismatch")
    require(final.get("first_next_tuning_step") == fixture.get("expected_next_step"), "next step mismatch")
    require(final.get("mutation_allowed") is False, "final mutation must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(report_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "cost_performance_report_dry_run", "runtime mode mismatch")
        for field in ["provider_mutation_allowed", "production_change_allowed", "cost_action_execute_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("category_count") >= fixture.get("expected_min_category_count"), "runtime category count too low")
        require(runtime.get("risk_count") >= fixture.get("expected_min_risk_count"), "runtime risk count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("rows", []):
            require(row.get("status") == "DRY_RUN_COST_PERFORMANCE_REPORT_ROW", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime row mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Cost-performance raporu config, report, fixture and dry-run runtime are semantically valid")
PY
