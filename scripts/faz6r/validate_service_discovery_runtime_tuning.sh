#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_1_2_service_discovery_runtime_tuning.v1.json}"
TUNING_FILE="${2:-configs/faz6r/service_discovery_runtime_tuning.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_1_2_service_discovery_runtime_tuning_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_service_discovery_runtime_tuning_dry_run.sh}"

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
    require(config.get("item") == "303", "item must be 303")
    require(config.get("code") == "FAZ_6_21_1_2", "code must be FAZ_6_21_1_2")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "service_registry_mutation_allowed",
        "dns_mutation_allowed",
        "load_balancer_mutation_allowed",
        "gateway_route_mutation_allowed",
        "deployment_rollout_allowed",
        "container_restart_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    services = {s.get("service") for s in config.get("service_surfaces", [])}
    for service in fixture.get("expected_services", []):
        require(service in services, f"service missing: {service}")

    metrics = set(config.get("metric_model", {}).get("required_metrics", []))
    for metric in [
        "service_health_status",
        "registry_last_seen_age_seconds",
        "stale_endpoint_count",
        "route_success_ratio",
        "tenant_header_preservation_ratio",
        "dns_lb_alignment_status",
        "gateway_route_confidence_score"
    ]:
        require(metric in metrics, f"metric missing: {metric}")

    metric_model = config.get("metric_model", {})
    require(metric_model.get("requires_per_service_breakdown") is True, "per-service breakdown required")
    require(metric_model.get("requires_per_tenant_route_validation") is True, "per-tenant route validation required")
    require(int(metric_model.get("minimum_observation_days", 0)) >= 7, "minimum observation days must be >= 7")

    tuning_policy = config.get("tuning_policy", {})
    require(tuning_policy.get("mode") == "recommendation_only", "tuning mode must be recommendation-only")
    for key in [
        "health_ttl_review_enabled",
        "stale_endpoint_review_enabled",
        "deregistration_review_enabled",
        "route_confidence_review_enabled",
        "dependency_graph_review_enabled",
        "dns_lb_alignment_required",
        "tenant_aware_guard_required"
    ]:
        require(tuning_policy.get(key) is True, f"{key} must be true")

    guards = config.get("guards", {})
    for guard_name in [
        "stale_endpoint_guard",
        "deregistration_guard",
        "health_based_routing_guard",
        "service_route_confidence_policy",
        "tenant_aware_service_guard",
        "dns_lb_alignment_guard"
    ]:
        require(guards.get(guard_name, {}).get("enabled") is True, f"{guard_name} must be enabled")

    require(guards.get("service_route_confidence_policy", {}).get("minimum_confidence_score", 0) >= 0.95, "route confidence threshold too low")
    require(guards.get("tenant_aware_service_guard", {}).get("block_if_x_tenant_id_not_preserved") is True, "tenant header guard missing")
    require(guards.get("dns_lb_alignment_guard", {}).get("block_if_dns_and_lb_targets_mismatch") is True, "DNS/LB alignment block missing")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "service_registry_mutation_execute",
        "dns_mutation_execute",
        "load_balancer_mutation_execute",
        "gateway_route_mutation_execute",
        "deployment_rollout_execute",
        "container_restart_execute",
        "service_deregistration_execute",
        "health_ttl_change_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "service_registry_mutation_allowed",
        "dns_mutation_allowed",
        "load_balancer_mutation_allowed",
        "gateway_route_mutation_allowed",
        "deployment_rollout_allowed",
        "container_restart_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "tuning_id",
        "service",
        "current_signal",
        "recommended_action",
        "risk_level",
        "route_confidence_status",
        "stale_endpoint_guard_status",
        "tenant_aware_guard_status",
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
        require(rec.get("service") in services, f"invalid service: {rec.get('service')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('tuning_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('tuning_id')}")
        require(bool(rec.get("route_confidence_status")), f"route confidence missing: {rec.get('tuning_id')}")
        require(bool(rec.get("stale_endpoint_guard_status")), f"stale endpoint guard missing: {rec.get('tuning_id')}")
        require(bool(rec.get("tenant_aware_guard_status")), f"tenant-aware guard missing: {rec.get('tuning_id')}")

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
        require(runtime.get("mode") == "service_discovery_runtime_tuning_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "service_registry_mutation_allowed",
            "dns_mutation_allowed",
            "load_balancer_mutation_allowed",
            "gateway_route_mutation_allowed",
            "deployment_rollout_allowed",
            "container_restart_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for rec in runtime.get("recommendations", []):
            require(rec.get("status") == "DRY_RUN_SERVICE_DISCOVERY_TUNING_RECOMMENDATION_ONLY", "runtime row status mismatch")
            require(rec.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Service discovery runtime tuning config, tuning, fixture and dry-run runtime are semantically valid")
PY
