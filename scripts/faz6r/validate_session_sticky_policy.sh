#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_1_4_session_sticky_policy.v1.json}"
POLICY_FILE="${2:-configs/faz6r/session_sticky_policy.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_1_4_session_sticky_policy_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_session_sticky_policy_dry_run.sh}"

python3 - "$CONFIG_FILE" "$POLICY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
policy_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(policy_path.exists(), f"policy missing: {policy_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    policy = json.loads(policy_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "304", "item must be 304")
    require(config.get("code") == "FAZ_6_21_1_4", "code must be FAZ_6_21_1_4")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "gateway_session_mutation_allowed",
        "load_balancer_sticky_mutation_allowed",
        "nginx_mutation_allowed",
        "redis_session_mutation_allowed",
        "cookie_policy_mutation_allowed",
        "deployment_rollout_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("session_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    metrics = set(config.get("metric_model", {}).get("required_metrics", []))
    for metric in [
        "session_store_health_status",
        "session_error_ratio",
        "sticky_route_success_ratio",
        "tenant_header_preservation_ratio",
        "cookie_secure_flag_coverage",
        "stateless_fallback_success_ratio",
        "node_failover_session_loss_candidate_count"
    ]:
        require(metric in metrics, f"metric missing: {metric}")

    metric_model = config.get("metric_model", {})
    require(metric_model.get("requires_per_surface_breakdown") is True, "per-surface breakdown required")
    require(metric_model.get("requires_per_tenant_breakdown") is True, "per-tenant breakdown required")
    require(int(metric_model.get("minimum_observation_days", 0)) >= 7, "minimum observation days must be >= 7")

    policy_model = config.get("policy_model", {})
    require(policy_model.get("mode") == "recommendation_only", "policy mode must be recommendation-only")
    for key in [
        "sticky_affinity_review_enabled",
        "tenant_aware_affinity_required",
        "stateless_fallback_required",
        "cookie_security_review_enabled",
        "session_store_health_required",
        "failover_affinity_review_enabled",
        "websocket_sse_affinity_review_enabled",
        "pos_offline_session_review_enabled"
    ]:
        require(policy_model.get(key) is True, f"{key} must be true")

    guards = config.get("guards", {})
    for guard_name in [
        "tenant_aware_affinity_guard",
        "stateless_fallback_policy",
        "session_store_health_policy",
        "cookie_security_policy",
        "failover_affinity_policy",
        "gateway_lb_alignment_guard"
    ]:
        require(guards.get(guard_name, {}).get("enabled") is True, f"{guard_name} must be enabled")

    require(guards.get("tenant_aware_affinity_guard", {}).get("block_if_x_tenant_id_not_preserved") is True, "tenant header guard missing")
    require(guards.get("stateless_fallback_policy", {}).get("block_if_surface_has_no_fallback") is True, "stateless fallback block missing")
    require(guards.get("session_store_health_policy", {}).get("block_if_session_store_unhealthy") is True, "session health block missing")
    require(guards.get("cookie_security_policy", {}).get("requires_secure") is True, "secure cookie required")
    require(guards.get("cookie_security_policy", {}).get("requires_http_only") is True, "httpOnly cookie required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "gateway_session_policy_change_execute",
        "load_balancer_sticky_change_execute",
        "nginx_sticky_change_execute",
        "redis_session_policy_change_execute",
        "cookie_policy_change_execute",
        "deployment_rollout_execute",
        "websocket_sse_affinity_change_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "gateway_session_mutation_allowed",
        "load_balancer_sticky_mutation_allowed",
        "nginx_mutation_allowed",
        "redis_session_mutation_allowed",
        "cookie_policy_mutation_allowed",
        "deployment_rollout_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "policy_id",
        "surface",
        "current_signal",
        "recommended_action",
        "risk_level",
        "tenant_aware_guard_status",
        "stateless_fallback_status",
        "session_store_health_status",
        "cookie_security_status",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(policy.get("status") == fixture.get("expected_status"), "policy status mismatch")
    recs = policy.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("policy_id")), "policy id missing")
        require(rec.get("surface") in surfaces, f"invalid surface: {rec.get('surface')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('policy_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('policy_id')}")
        require(bool(rec.get("tenant_aware_guard_status")), f"tenant-aware guard missing: {rec.get('policy_id')}")
        require(bool(rec.get("stateless_fallback_status")), f"stateless fallback missing: {rec.get('policy_id')}")
        require(bool(rec.get("session_store_health_status")), f"session health missing: {rec.get('policy_id')}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(policy_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "session_sticky_policy_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "gateway_session_mutation_allowed",
            "load_balancer_sticky_mutation_allowed",
            "nginx_mutation_allowed",
            "redis_session_mutation_allowed",
            "cookie_policy_mutation_allowed",
            "deployment_rollout_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("recommendations", []):
            require(row.get("status") == "DRY_RUN_SESSION_STICKY_POLICY_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Session / sticky policy config, policy, fixture and dry-run runtime are semantically valid")
PY
