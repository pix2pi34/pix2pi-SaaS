#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_20_2_replica_routing_read_pool_stratejisi.v1.json}"
STRATEGY_FILE="${2:-configs/faz6r/replica_routing_read_pool_strategy.db_scale.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_20_2_replica_routing_read_pool_stratejisi_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_replica_routing_read_pool_strategy_dry_run.sh}"

python3 - "$CONFIG_FILE" "$STRATEGY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
strategy_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(strategy_path.exists(), f"strategy missing: {strategy_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    strategy = json.loads(strategy_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "306", "item must be 306")
    require(config.get("code") == "FAZ_6_20_2", "code must be FAZ_6_20_2")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "dsn_mutation_allowed",
        "application_route_mutation_allowed",
        "read_pool_attach_allowed",
        "read_pool_detach_allowed",
        "replica_promotion_allowed",
        "db_role_mutation_allowed",
        "dns_mutation_allowed",
        "load_balancer_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("routing_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    read_pool = config.get("read_pool_model", {})
    require(read_pool.get("enabled") is True, "read pool model enabled")
    require(read_pool.get("write_target") == "primary_only", "write target must be primary_only")
    require(read_pool.get("requires_health_score") is True, "health score required")
    require(read_pool.get("requires_lag_score") is True, "lag score required")
    require(read_pool.get("requires_tenant_scope_validation") is True, "tenant scope validation required")

    scoring = config.get("replica_health_scoring_policy", {})
    require(scoring.get("enabled") is True, "replica health scoring enabled")
    require(scoring.get("minimum_health_score", 0) >= 0.95, "minimum health score too low")
    require(scoring.get("max_lag_seconds_operational") <= 5, "operational lag threshold too high")
    require(scoring.get("max_lag_seconds_reporting") <= 60, "reporting lag threshold too high")
    require(scoring.get("block_if_wal_receiver_unhealthy") is True, "WAL receiver block required")
    require(scoring.get("block_if_replication_slot_unhealthy") is True, "replication slot block required")

    consistency = config.get("consistency_policy", {})
    require(consistency.get("enabled") is True, "consistency policy enabled")
    require(consistency.get("read_after_write_guard_required") is True, "read-after-write guard required")
    require(consistency.get("strict_consistency_routes_use_primary") is True, "strict routes must use primary")
    require(consistency.get("stale_read_guard_required") is True, "stale read guard required")
    require(consistency.get("tenant_safe_read_routing_required") is True, "tenant safe routing required")
    require(consistency.get("block_if_tenant_scope_unknown") is True, "tenant unknown block required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "dsn_switch_execute",
        "application_route_change_execute",
        "read_pool_attach_execute",
        "read_pool_detach_execute",
        "replica_promotion_execute",
        "db_role_mutation_execute",
        "dns_mutation_execute",
        "load_balancer_mutation_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "dsn_mutation_allowed",
        "application_route_mutation_allowed",
        "read_pool_attach_allowed",
        "read_pool_detach_allowed",
        "replica_promotion_allowed",
        "db_role_mutation_allowed",
        "dns_mutation_allowed",
        "load_balancer_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "routing_id",
        "surface",
        "target_decision",
        "health_score_status",
        "lag_guard_status",
        "consistency_guard_status",
        "tenant_scope_guard_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(strategy.get("status") == fixture.get("expected_status"), "strategy status mismatch")
    decisions = strategy.get("routing_decisions", [])
    require(len(decisions) >= fixture.get("expected_min_decision_count"), "decision count below minimum")

    decision_surfaces = {d.get("surface") for d in decisions}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in decision_surfaces, f"decision surface missing: {surface}")

    for d in decisions:
        require(bool(d.get("routing_id")), "routing id missing")
        require(d.get("surface") in surfaces, f"invalid surface: {d.get('surface')}")
        require(d.get("approval_required") is True, f"approval must be required: {d.get('routing_id')}")
        require(d.get("mutation_allowed") is False, f"mutation must be false: {d.get('routing_id')}")
        require(bool(d.get("health_score_status")), f"health score missing: {d.get('routing_id')}")
        require(bool(d.get("lag_guard_status")), f"lag guard missing: {d.get('routing_id')}")
        require(bool(d.get("consistency_guard_status")), f"consistency guard missing: {d.get('routing_id')}")
        require(bool(d.get("tenant_scope_guard_status")), f"tenant scope guard missing: {d.get('routing_id')}")

    next_step = strategy.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(strategy_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "replica_routing_read_pool_strategy_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "dsn_mutation_allowed",
            "application_route_mutation_allowed",
            "read_pool_attach_allowed",
            "read_pool_detach_allowed",
            "replica_promotion_allowed",
            "db_role_mutation_allowed",
            "dns_mutation_allowed",
            "load_balancer_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("decision_count") >= fixture.get("expected_min_decision_count"), "runtime decision count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("routing_decisions", []):
            require(row.get("status") == "DRY_RUN_REPLICA_ROUTING_READ_POOL_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Replica routing / read pool stratejisi config, strategy, fixture and dry-run runtime are semantically valid")
PY
