#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_2_2_replica_failover_provasi.v1.json}"
REHEARSAL_FILE="${2:-configs/faz6r/replica_failover_rehearsal.ha_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_2_2_replica_failover_provasi_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_replica_failover_rehearsal_dry_run.sh}"

python3 - "$CONFIG_FILE" "$REHEARSAL_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
rehearsal_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(rehearsal_path.exists(), f"rehearsal missing: {rehearsal_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    rehearsal = json.loads(rehearsal_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "301", "item must be 301")
    require(config.get("code") == "FAZ_6_21_2_2", "code must be FAZ_6_21_2_2")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "db_promotion_allowed",
        "replica_promotion_allowed",
        "dns_mutation_allowed",
        "dsn_mutation_allowed",
        "application_route_mutation_allowed",
        "replication_slot_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    preflight = config.get("preflight_policy", {})
    require(preflight.get("enabled") is True, "preflight policy enabled")
    for check in [
        "db_ha_topology_evidence_pass",
        "single_write_primary_confirmed",
        "primary_reachability_known",
        "replica_reachability_known",
        "replica_lag_within_threshold",
        "wal_replay_healthy",
        "backup_chain_healthy",
        "pitr_window_available",
        "split_brain_guard_ready"
    ]:
        require(check in preflight.get("required_checks", []), f"preflight check missing: {check}")

    candidate = config.get("failover_candidate_policy", {})
    require(candidate.get("enabled") is True, "candidate policy enabled")
    require(candidate.get("candidate_role") == "sync_replica_candidate", "candidate role mismatch")
    require(candidate.get("candidate_node") == "postgres_sync_replica_candidate", "candidate node mismatch")
    require(int(candidate.get("max_replica_lag_seconds", 9999)) <= 30, "replica lag threshold too high")
    require(candidate.get("requires_wal_replay_healthy") is True, "WAL replay required")
    require(candidate.get("requires_backup_chain_healthy") is True, "backup chain required")
    require(candidate.get("requires_pitr_window_available") is True, "PITR window required")
    require(candidate.get("requires_primary_status_known") is True, "primary status known required")

    decision = config.get("promotion_decision_policy", {})
    require(decision.get("enabled") is True, "promotion decision policy enabled")
    require(decision.get("mode") == "dry_run_decision_only_no_promotion", "decision mode mismatch")
    require(decision.get("allow_promotion_execute") is False, "promotion execute must be false")
    decision_values = set(decision.get("decision_values", []))
    for value in [
        "READY_FOR_MANUAL_APPROVED_FAILOVER_REHEARSAL",
        "BLOCKED_SPLIT_BRAIN_RISK",
        "BLOCKED_REPLICA_LAG",
        "BLOCKED_BACKUP_PITR"
    ]:
        require(value in decision_values, f"decision value missing: {value}")

    routing = config.get("routing_switch_guard", {})
    require(routing.get("enabled") is True, "routing switch guard enabled")
    for field in ["dns_switch_allowed", "dsn_switch_allowed", "application_route_switch_allowed", "read_write_route_switch_allowed"]:
        require(routing.get(field) is False, f"{field} must be false")

    rollback = config.get("rollback_decision_policy", {})
    require(rollback.get("enabled") is True, "rollback decision policy enabled")
    require(rollback.get("mode") == "decision_only_no_rollback_execute", "rollback mode mismatch")
    require(rollback.get("requires_previous_primary_quarantine_plan") is True, "previous primary quarantine required")
    require(rollback.get("requires_data_divergence_check") is True, "data divergence check required")
    require(rollback.get("requires_manual_approval") is True, "rollback manual approval required")

    rto = config.get("rto_rpo_measurement_policy", {})
    require(rto.get("enabled") is True, "RTO/RPO measurement enabled")
    require(rto.get("dry_run_measurement_only") is True, "RTO/RPO must be dry-run only")
    require(rto.get("target_rto_minutes") <= 30, "target RTO too high")
    require(rto.get("target_rpo_minutes") <= 5, "target RPO too high")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "db_promotion_execute",
        "replica_promotion_execute",
        "dns_switch_execute",
        "dsn_switch_execute",
        "application_route_switch_execute",
        "read_write_route_switch_execute",
        "replication_slot_change_execute",
        "rollback_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "db_promotion_allowed",
        "replica_promotion_allowed",
        "dns_mutation_allowed",
        "dsn_mutation_allowed",
        "application_route_mutation_allowed",
        "replication_slot_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "rehearsal_id",
        "candidate_node",
        "preflight_status",
        "promotion_decision",
        "primary_reachability_status",
        "replica_reachability_status",
        "replica_lag_seconds",
        "wal_replay_status",
        "backup_pitr_status",
        "split_brain_guard_status",
        "rto_minutes",
        "rpo_minutes",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(rehearsal.get("status") == fixture.get("expected_status"), "rehearsal status mismatch")
    rehearsals = rehearsal.get("rehearsals", [])
    require(len(rehearsals) >= fixture.get("expected_min_rehearsal_count"), "rehearsal count below minimum")

    seen_decisions = {r.get("promotion_decision") for r in rehearsals}
    for value in ["READY_FOR_MANUAL_APPROVED_FAILOVER_REHEARSAL", "BLOCKED_REPLICA_LAG", "BLOCKED_SPLIT_BRAIN_RISK", "BLOCKED_BACKUP_PITR"]:
        require(value in seen_decisions, f"rehearsal decision missing: {value}")

    for r in rehearsals:
        require(r.get("candidate_node") == "postgres_sync_replica_candidate", f"candidate node mismatch: {r.get('rehearsal_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('rehearsal_id')}")
        require(bool(r.get("preflight_status")), f"preflight missing: {r.get('rehearsal_id')}")
        require(bool(r.get("promotion_decision")), f"promotion decision missing: {r.get('rehearsal_id')}")
        require(bool(r.get("wal_replay_status")), f"WAL replay missing: {r.get('rehearsal_id')}")
        require(bool(r.get("backup_pitr_status")), f"backup PITR missing: {r.get('rehearsal_id')}")
        require(bool(r.get("split_brain_guard_status")), f"split brain guard missing: {r.get('rehearsal_id')}")

    next_step = rehearsal.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("restore_execution_allowed_now") is False, "restore execution must be false now")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(rehearsal_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "replica_failover_rehearsal_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "db_promotion_allowed",
            "replica_promotion_allowed",
            "dns_mutation_allowed",
            "dsn_mutation_allowed",
            "application_route_mutation_allowed",
            "replication_slot_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("rehearsal_count") >= fixture.get("expected_min_rehearsal_count"), "runtime rehearsal count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("rehearsals", []):
            require(row.get("status") == "DRY_RUN_REPLICA_FAILOVER_REHEARSAL_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Replica failover provası config, rehearsal, fixture and dry-run runtime are semantically valid")
PY
