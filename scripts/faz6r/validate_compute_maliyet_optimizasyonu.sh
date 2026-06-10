#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_1_compute_maliyet_optimizasyonu.v1.json}"
PLAN_FILE="${2:-configs/faz6r/compute_cost_optimization.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_1_compute_maliyet_optimizasyonu_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_compute_cost_optimization_dry_run.sh}"

python3 - "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(plan_path.exists(), f"plan missing: {plan_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "293", "item must be 293")
    require(config.get("code") == "FAZ_6_21_5_1", "code must be FAZ_6_21_5_1")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "production_resize_allowed",
        "instance_shutdown_allowed",
        "autoscaling_policy_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    classes = {c.get("class") for c in config.get("workload_classes", [])}
    for cls in fixture.get("expected_workload_classes", []):
        require(cls in classes, f"workload class missing: {cls}")

    signals = set(config.get("signals", []))
    for signal in ["cpu_avg_24h", "cpu_p95_24h", "memory_avg_24h", "memory_p95_24h", "latency_p95_24h", "error_rate_24h"]:
        require(signal in signals, f"signal missing: {signal}")

    rec_policy = config.get("recommendation_policy", {})
    require(rec_policy.get("rightsizing_enabled") is True, "rightsizing must be enabled")
    require(rec_policy.get("idle_capacity_detection_enabled") is True, "idle detection must be enabled")
    require(rec_policy.get("scale_down_recommendation_only") is True, "scale-down must be recommendation-only")
    require(rec_policy.get("requires_slo_confirmation") is True, "SLO confirmation required")
    require(rec_policy.get("requires_dr_capacity_confirmation") is True, "DR capacity confirmation required")

    slo = config.get("slo_guard", {})
    require(slo.get("enabled") is True, "SLO guard must be enabled")
    require(slo.get("block_scale_down_if_p95_latency_regression_risk") is True, "latency regression guard missing")
    require(slo.get("block_scale_down_if_error_rate_regression_risk") is True, "error regression guard missing")
    require(slo.get("block_scale_down_if_dr_capacity_below_minimum") is True, "DR capacity guard missing")

    reservation = config.get("reservation_commitment_review", {})
    require(reservation.get("mode") == "review_only_no_purchase", "reservation must be review-only")
    require(reservation.get("requires_business_approval") is True, "reservation requires business approval")

    burst = config.get("burst_capacity_policy", {})
    require(burst.get("minimum_headroom_percent", 0) >= 30, "minimum headroom below 30%")
    require(burst.get("critical_runtime_headroom_percent", 0) >= 50, "critical headroom below 50%")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in ["production_resize_execute", "instance_shutdown_execute", "autoscaling_policy_change_execute", "reserved_commitment_purchase"]:
        require(action in manual.get("required_for", []), f"manual approval action missing: {action}")

    provider = config.get("provider_mutation_closed_policy", {})
    require(provider.get("enabled") is True, "provider mutation closed policy must be enabled")
    for field in ["provider_mutation_allowed", "production_resize_allowed", "instance_shutdown_allowed", "autoscaling_policy_mutation_allowed", "reserved_commitment_purchase_allowed"]:
        require(provider.get(field) is False, f"provider {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in ["recommendation_id", "service", "workload_class", "current_shape", "recommended_shape", "estimated_savings_level", "risk_level", "slo_guard_status", "dr_capacity_guard_status", "approval_required", "mutation_allowed", "timestamp"]:
        require(field in fields, f"evidence field missing: {field}")

    require(plan.get("status") == fixture.get("expected_status"), "plan status mismatch")
    recs = plan.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("recommendation_id")), "recommendation id missing")
        require(rec.get("workload_class") in classes, f"invalid workload class: {rec.get('workload_class')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('recommendation_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('recommendation_id')}")
        require(bool(rec.get("slo_guard_status")), f"slo guard missing: {rec.get('recommendation_id')}")
        require(bool(rec.get("dr_capacity_guard_status")), f"dr guard missing: {rec.get('recommendation_id')}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(plan_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "compute_cost_optimization_dry_run", "runtime mode mismatch")
        for field in ["provider_mutation_allowed", "production_resize_allowed", "instance_shutdown_allowed", "autoscaling_policy_mutation_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        for rec in runtime.get("recommendations", []):
            require(rec.get("status") == "DRY_RUN_RECOMMENDATION_ONLY", "runtime recommendation status mismatch")
            require(rec.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Compute maliyet optimizasyonu config, plan, fixture and dry-run runtime are semantically valid")
PY
