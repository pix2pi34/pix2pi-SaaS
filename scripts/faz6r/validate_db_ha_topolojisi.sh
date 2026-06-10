#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_2_1_db_ha_topolojisi.v1.json}"
TOPOLOGY_FILE="${2:-configs/faz6r/db_ha_topology.ha_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_2_1_db_ha_topolojisi_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_db_ha_topology_dry_run.sh}"

python3 - "$CONFIG_FILE" "$TOPOLOGY_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
topology_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(topology_path.exists(), f"topology missing: {topology_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    topology = json.loads(topology_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "300", "item must be 300")
    require(config.get("code") == "FAZ_6_21_2_1", "code must be FAZ_6_21_2_1")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "db_promotion_allowed",
        "replica_attach_allowed",
        "replica_detach_allowed",
        "dns_mutation_allowed",
        "dsn_mutation_allowed",
        "read_write_route_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    roles = {r.get("role") for r in config.get("ha_roles", [])}
    for role in fixture.get("expected_roles", []):
        require(role in roles, f"HA role missing: {role}")

    primary_roles = [r for r in config.get("ha_roles", []) if r.get("role") == "primary"]
    require(len(primary_roles) == 1, "exactly one primary role required")
    require(primary_roles[0].get("write_allowed") is True, "primary must allow write")
    require(primary_roles[0].get("max_instances") == 1, "primary max_instances must be 1")

    replication = config.get("replication_health_model", {})
    require(replication.get("enabled") is True, "replication health model enabled")
    require(replication.get("requires_backup_chain_healthy") is True, "backup chain healthy required")
    require(replication.get("requires_pitr_window_available") is True, "PITR window required")
    require(int(replication.get("max_replica_lag_seconds_for_failover_candidate", 9999)) <= 30, "replica lag threshold too high")
    signals = set(replication.get("required_signals", []))
    for signal in ["replica_lag_seconds", "wal_receiver_status", "wal_sender_status", "backup_chain_status", "pitr_recovery_window"]:
        require(signal in signals, f"replication signal missing: {signal}")

    routing = config.get("connection_routing_policy", {})
    require(routing.get("enabled") is True, "routing policy enabled")
    require(routing.get("write_dsn_target") == "primary_only", "write DSN must target primary only")
    require(routing.get("read_dsn_target") == "read_pool_only", "read DSN must target read pool")
    require(routing.get("route_mutation_allowed") is False, "route mutation must be false")
    require(routing.get("requires_application_read_write_split") is True, "read/write split required")

    failover = config.get("failover_decision_guard", {})
    require(failover.get("enabled") is True, "failover guard enabled")
    require(failover.get("mode") == "decision_only_no_promotion", "failover mode mismatch")
    require(failover.get("manual_approval_required") is True, "manual approval required")
    for field in [
        "block_if_split_brain_risk",
        "block_if_replica_lag_above_threshold",
        "block_if_backup_chain_unhealthy",
        "block_if_pitr_window_missing",
        "block_if_primary_status_unknown"
    ]:
        require(failover.get(field) is True, f"failover guard missing: {field}")

    rto = config.get("rto_rpo_alignment_policy", {})
    require(rto.get("enabled") is True, "RTO/RPO policy enabled")
    require(rto.get("target_rto_minutes") <= 30, "target RTO too high")
    require(rto.get("target_rpo_minutes") <= 5, "target RPO too high")
    require(rto.get("requires_replica_failover_rehearsal_next") is True, "replica failover rehearsal next required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in ["db_promotion_execute", "replica_attach_execute", "replica_detach_execute", "dns_mutation_execute", "dsn_mutation_execute", "read_write_route_change_execute"]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "db_promotion_allowed",
        "replica_attach_allowed",
        "replica_detach_allowed",
        "dns_mutation_allowed",
        "dsn_mutation_allowed",
        "read_write_route_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in ["topology_id", "role", "node", "write_allowed", "read_allowed", "failover_candidate", "replication_health_status", "split_brain_guard_status", "rto_minutes", "rpo_minutes", "mutation_allowed", "timestamp"]:
        require(field in fields, f"evidence field missing: {field}")

    require(topology.get("status") == fixture.get("expected_status"), "topology status mismatch")
    nodes = topology.get("nodes", [])
    require(len(nodes) >= fixture.get("expected_min_node_count"), "node count below minimum")

    node_roles = {n.get("role") for n in nodes}
    for role in fixture.get("expected_roles", []):
        require(role in node_roles, f"topology role missing: {role}")

    write_primaries = [n for n in nodes if n.get("role") == "primary" and n.get("write_allowed") is True]
    require(len(write_primaries) == 1, "topology must have exactly one write primary")

    for node in nodes:
        require(node.get("mutation_allowed") is False, f"mutation must be false: {node.get('node')}")
        if node.get("role") != "primary":
            require(node.get("write_allowed") is False, f"non-primary write must be false: {node.get('node')}")
        require(bool(node.get("replication_health_status")), f"replication health missing: {node.get('node')}")
        require(bool(node.get("split_brain_guard_status")), f"split brain guard missing: {node.get('node')}")

    topo_routing = topology.get("routing", {})
    require(topo_routing.get("write_target") == "postgres_primary", "topology write target mismatch")
    require(topo_routing.get("route_mutation_allowed") is False, "topology route mutation false")
    require(topo_routing.get("dsn_mutation_allowed") is False, "topology dsn mutation false")

    next_rehearsal = topology.get("next_rehearsal", {})
    require(next_rehearsal.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_rehearsal.get("promotion_allowed_now") is False, "promotion must not be allowed now")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(topology_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "db_ha_topology_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "db_promotion_allowed",
            "replica_attach_allowed",
            "replica_detach_allowed",
            "dns_mutation_allowed",
            "dsn_mutation_allowed",
            "read_write_route_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("node_count") >= fixture.get("expected_min_node_count"), "runtime node count too low")
        require(runtime.get("write_primary_count") == 1, "runtime write primary count must be 1")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("nodes", []):
            require(row.get("status") == "DRY_RUN_DB_HA_TOPOLOGY_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: DB HA topolojisi config, topology, fixture and dry-run runtime are semantically valid")
PY
