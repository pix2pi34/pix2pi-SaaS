#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_1_5_node_health_fencing.v1.json}"
POLICY_FILE="${2:-configs/faz6r/node_health_fencing.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_1_5_node_health_fencing_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_node_health_fencing_dry_run.sh}"

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
    require(config.get("item") == "305", "item must be 305")
    require(config.get("code") == "FAZ_6_21_1_5", "code must be FAZ_6_21_1_5")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "node_cordon_allowed",
        "node_drain_allowed",
        "node_restart_allowed",
        "node_shutdown_allowed",
        "lb_detach_allowed",
        "dns_mutation_allowed",
        "gateway_route_mutation_allowed",
        "service_registry_mutation_allowed",
        "container_kill_allowed",
        "deployment_rollout_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    node_classes = {s.get("node_class") for s in config.get("node_surfaces", [])}
    for node_class in fixture.get("expected_node_classes", []):
        require(node_class in node_classes, f"node class missing: {node_class}")

    metrics = set(config.get("health_signal_model", {}).get("required_metrics", []))
    for metric in [
        "node_cpu_saturation",
        "node_memory_saturation",
        "node_disk_pressure",
        "node_io_wait",
        "node_network_error_ratio",
        "tenant_traffic_error_ratio",
        "session_affinity_error_ratio",
        "heartbeat_age_seconds"
    ]:
        require(metric in metrics, f"metric missing: {metric}")

    health = config.get("health_signal_model", {})
    require(health.get("requires_node_class_breakdown") is True, "node class breakdown required")
    require(health.get("requires_tenant_impact_breakdown") is True, "tenant impact breakdown required")
    require(int(health.get("minimum_observation_minutes", 0)) >= 15, "minimum observation minutes must be >= 15")

    decision = config.get("fencing_decision_policy", {})
    require(decision.get("enabled") is True, "fencing decision policy enabled")
    require(decision.get("mode") == "dry_run_decision_only_no_fencing", "decision mode must be dry-run only")
    require(decision.get("manual_approval_required") is True, "manual approval required")
    require(decision.get("auto_fencing_allowed") is False, "auto fencing must be false")
    for value in [
        "NO_FENCE_HEALTHY",
        "REVIEW_NODE_DEGRADED",
        "READY_FOR_MANUAL_FENCE_REHEARSAL",
        "BLOCKED_QUORUM_RISK",
        "BLOCKED_SPLIT_BRAIN_RISK",
        "BLOCKED_TENANT_TRAFFIC_RISK",
        "BLOCKED_SESSION_AFFINITY_RISK"
    ]:
        require(value in decision.get("decision_values", []), f"decision value missing: {value}")

    guards = config.get("guards", {})
    for guard_name in [
        "quorum_safety_guard",
        "split_brain_guard",
        "tenant_traffic_isolation_guard",
        "workload_drain_policy",
        "lb_detach_policy",
        "session_affinity_safety_guard"
    ]:
        require(guards.get(guard_name, {}).get("enabled") is True, f"{guard_name} must be enabled")

    require(guards.get("quorum_safety_guard", {}).get("block_if_remaining_capacity_below_quorum") is True, "quorum capacity block missing")
    require(guards.get("split_brain_guard", {}).get("block_if_cluster_membership_uncertain") is True, "split brain membership block missing")
    require(guards.get("tenant_traffic_isolation_guard", {}).get("block_if_tenant_traffic_would_cross_scope") is True, "tenant traffic block missing")
    require(guards.get("workload_drain_policy", {}).get("mode") == "dry_run_only", "workload drain must be dry-run only")
    require(guards.get("lb_detach_policy", {}).get("mode") == "dry_run_only", "LB detach must be dry-run only")
    require(guards.get("session_affinity_safety_guard", {}).get("block_if_session_sticky_policy_conflict") is True, "session sticky conflict block missing")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "node_cordon_execute",
        "node_drain_execute",
        "node_restart_execute",
        "node_shutdown_execute",
        "lb_detach_execute",
        "dns_mutation_execute",
        "gateway_route_mutation_execute",
        "service_registry_mutation_execute",
        "container_kill_execute",
        "deployment_rollout_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "node_cordon_allowed",
        "node_drain_allowed",
        "node_restart_allowed",
        "node_shutdown_allowed",
        "lb_detach_allowed",
        "dns_mutation_allowed",
        "gateway_route_mutation_allowed",
        "service_registry_mutation_allowed",
        "container_kill_allowed",
        "deployment_rollout_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "fencing_id",
        "node_class",
        "current_signal",
        "fencing_decision",
        "risk_level",
        "quorum_guard_status",
        "split_brain_guard_status",
        "tenant_traffic_guard_status",
        "session_affinity_guard_status",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(policy.get("status") == fixture.get("expected_status"), "policy status mismatch")
    recs = policy.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("fencing_id")), "fencing id missing")
        require(rec.get("node_class") in node_classes, f"invalid node class: {rec.get('node_class')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('fencing_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('fencing_id')}")
        require(bool(rec.get("quorum_guard_status")), f"quorum guard missing: {rec.get('fencing_id')}")
        require(bool(rec.get("split_brain_guard_status")), f"split brain guard missing: {rec.get('fencing_id')}")
        require(bool(rec.get("tenant_traffic_guard_status")), f"tenant traffic guard missing: {rec.get('fencing_id')}")
        require(bool(rec.get("session_affinity_guard_status")), f"session affinity guard missing: {rec.get('fencing_id')}")

    next_step = policy.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

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
        require(runtime.get("mode") == "node_health_fencing_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "node_cordon_allowed",
            "node_drain_allowed",
            "node_restart_allowed",
            "node_shutdown_allowed",
            "lb_detach_allowed",
            "dns_mutation_allowed",
            "gateway_route_mutation_allowed",
            "service_registry_mutation_allowed",
            "container_kill_allowed",
            "deployment_rollout_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("recommendations", []):
            require(row.get("status") == "DRY_RUN_NODE_HEALTH_FENCING_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Node health fencing config, policy, fixture and dry-run runtime are semantically valid")
PY
