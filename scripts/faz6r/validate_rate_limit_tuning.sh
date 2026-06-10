#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_3_4_rate_limit_tuning.v1.json}"
TUNING_FILE="${2:-configs/faz6r/rate_limit_tuning.performance_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_3_4_rate_limit_tuning_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_rate_limit_tuning_dry_run.sh}"

python3 - "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
tuning_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(tuning_path.exists(), f"tuning missing: {tuning_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    tuning = json.loads(tuning_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "299", "item must be 299")
    require(config.get("code") == "FAZ_6_21_3_4", "code must be FAZ_6_21_3_4")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "gateway_rate_limit_mutation_allowed",
        "redis_rate_limit_mutation_allowed",
        "edge_waf_mutation_allowed",
        "nginx_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("rate_limit_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    metric_model = config.get("metric_model", {})
    require(metric_model.get("requires_per_tenant_breakdown") is True, "per-tenant breakdown required")
    require(metric_model.get("requires_per_route_breakdown") is True, "per-route breakdown required")
    require(int(metric_model.get("minimum_observation_days", 0)) >= 7, "minimum observation days must be >= 7")

    metrics = set(metric_model.get("required_metrics", []))
    for metric in [
        "request_rate_per_tenant",
        "request_rate_per_route",
        "burst_rate_per_route",
        "rate_limit_block_count",
        "auth_failed_attempt_count",
        "api_abuse_signal_count",
        "webhook_retry_count",
        "false_positive_candidate_count",
        "redis_rate_limit_key_growth"
    ]:
        require(metric in metrics, f"metric missing: {metric}")

    tuning_policy = config.get("tuning_policy", {})
    require(tuning_policy.get("mode") == "recommendation_only", "tuning mode must be recommendation-only")
    for key in [
        "burst_policy_review_enabled",
        "tenant_limit_review_enabled",
        "route_limit_review_enabled",
        "auth_bruteforce_review_enabled",
        "webhook_retry_review_enabled",
        "false_positive_review_enabled",
        "edge_waf_alignment_required",
        "redis_namespace_required"
    ]:
        require(tuning_policy.get(key) is True, f"{key} must be true")

    guards = config.get("guards", {})
    for guard_name in [
        "auth_bruteforce_guard",
        "api_abuse_guard",
        "webhook_rate_limit_guard",
        "public_web_rate_limit_guard",
        "false_positive_guard",
        "redis_namespace_guard",
        "edge_waf_alignment_guard"
    ]:
        require(guards.get(guard_name, {}).get("enabled") is True, f"{guard_name} must be enabled")

    require(guards.get("auth_bruteforce_guard", {}).get("block_if_bruteforce_risk_increases") is True, "auth brute force block missing")
    require(guards.get("false_positive_guard", {}).get("block_if_legitimate_tenant_traffic_impacted") is True, "false positive block missing")
    require(guards.get("redis_namespace_guard", {}).get("block_if_key_without_tenant_or_surface_namespace") is True, "redis namespace block missing")
    require(guards.get("edge_waf_alignment_guard", {}).get("block_if_conflicts_with_waf_or_bot_policy") is True, "edge WAF alignment block missing")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "gateway_rate_limit_change_execute",
        "redis_rate_limit_policy_change_execute",
        "edge_waf_rate_limit_change_execute",
        "nginx_rate_limit_change_execute",
        "auth_bruteforce_threshold_change_execute",
        "webhook_rate_limit_change_execute",
        "public_web_rate_limit_change_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual approval action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "gateway_rate_limit_mutation_allowed",
        "redis_rate_limit_mutation_allowed",
        "edge_waf_mutation_allowed",
        "nginx_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "tuning_id",
        "surface",
        "current_signal",
        "recommended_action",
        "expected_effect",
        "risk_level",
        "tenant_scope_guard_status",
        "false_positive_guard_status",
        "security_guard_status",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(tuning.get("status") == fixture.get("expected_status"), "tuning status mismatch")
    recs = tuning.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("tuning_id")), "tuning id missing")
        require(rec.get("surface") in surfaces, f"invalid surface: {rec.get('surface')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('tuning_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('tuning_id')}")
        require(bool(rec.get("tenant_scope_guard_status")), f"tenant scope guard missing: {rec.get('tuning_id')}")
        require(bool(rec.get("false_positive_guard_status")), f"false-positive guard missing: {rec.get('tuning_id')}")
        require(bool(rec.get("security_guard_status")), f"security guard missing: {rec.get('tuning_id')}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(tuning_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "rate_limit_tuning_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "gateway_rate_limit_mutation_allowed",
            "redis_rate_limit_mutation_allowed",
            "edge_waf_mutation_allowed",
            "nginx_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        for rec in runtime.get("recommendations", []):
            require(rec.get("status") == "DRY_RUN_RATE_LIMIT_TUNING_RECOMMENDATION_ONLY", "runtime recommendation status mismatch")
            require(rec.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Rate limit tuning config, tuning, fixture and dry-run runtime are semantically valid")
PY
