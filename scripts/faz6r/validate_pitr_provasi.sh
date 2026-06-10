#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_2_5_pitr_provasi.v1.json}"
REHEARSAL_FILE="${2:-configs/faz6r/pitr_rehearsal.ha_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_2_5_pitr_provasi_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_pitr_rehearsal_dry_run.sh}"

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
    require(config.get("item") == "302", "item must be 302")
    require(config.get("code") == "FAZ_6_21_2_5", "code must be FAZ_6_21_2_5")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "restore_execution_allowed",
        "primary_overwrite_allowed",
        "replica_rebuild_allowed",
        "wal_replay_execution_allowed",
        "backup_delete_allowed",
        "dns_mutation_allowed",
        "dsn_mutation_allowed",
        "application_route_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    backup = config.get("backup_chain_policy", {})
    require(backup.get("enabled") is True, "backup chain policy enabled")
    require(backup.get("block_if_missing_base_backup") is True, "base backup block required")
    require(backup.get("block_if_missing_wal_archive") is True, "wal archive block required")
    require(backup.get("block_if_backup_manifest_missing") is True, "manifest block required")
    for rec in ["base_backup_reference", "wal_archive_reference", "backup_manifest_reference", "restore_procedure_reference"]:
        require(rec in backup.get("required_records", []), f"backup required record missing: {rec}")

    target = config.get("recovery_target_time_policy", {})
    require(target.get("enabled") is True, "target time policy enabled")
    require(target.get("requires_explicit_target_time") is True, "explicit target time required")
    require(target.get("target_time_must_be_inside_pitr_window") is True, "target must be inside PITR window")
    require(target.get("target_time_must_be_after_last_base_backup") is True, "target must be after last base backup")

    isolated = config.get("isolated_restore_target_policy", {})
    require(isolated.get("enabled") is True, "isolated restore policy enabled")
    require(isolated.get("restore_target") == "isolated_restore_environment_only", "restore target must be isolated")
    require(isolated.get("production_restore_allowed") is False, "production restore must be false")
    require(isolated.get("primary_overwrite_allowed") is False, "primary overwrite must be false")
    require(isolated.get("network_isolation_required") is True, "network isolation required")
    require(isolated.get("read_only_validation_required") is True, "read-only validation required")

    preflight = config.get("restore_preflight_policy", {})
    require(preflight.get("enabled") is True, "restore preflight enabled")
    for check in [
        "replica_failover_evidence_pass",
        "base_backup_available",
        "wal_archive_available",
        "target_time_inside_window",
        "isolated_restore_target_ready",
        "tenant_scope_validation_ready",
        "data_integrity_validation_ready"
    ]:
        require(check in preflight.get("required_checks", []), f"preflight check missing: {check}")

    validation = config.get("validation_policy", {})
    for field in [
        "wal_replay_validation_required",
        "data_integrity_validation_required",
        "tenant_scope_validation_required",
        "sample_query_validation_required",
        "checksum_or_manifest_validation_required"
    ]:
        require(validation.get(field) is True, f"validation {field} must be true")

    rto = config.get("rto_rpo_measurement_policy", {})
    require(rto.get("enabled") is True, "RTO/RPO enabled")
    require(rto.get("dry_run_measurement_only") is True, "RTO/RPO must be dry-run only")
    require(rto.get("target_rto_minutes") <= 120, "target RTO too high")
    require(rto.get("target_rpo_minutes") <= 15, "target RPO too high")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "restore_execute",
        "primary_overwrite_execute",
        "replica_rebuild_execute",
        "wal_replay_execute",
        "dns_switch_execute",
        "dsn_switch_execute",
        "application_route_switch_execute",
        "backup_delete_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "restore_execution_allowed",
        "primary_overwrite_allowed",
        "replica_rebuild_allowed",
        "wal_replay_execution_allowed",
        "backup_delete_allowed",
        "dns_mutation_allowed",
        "dsn_mutation_allowed",
        "application_route_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "rehearsal_id",
        "restore_target",
        "recovery_target_time_status",
        "backup_chain_status",
        "wal_archive_status",
        "restore_preflight_status",
        "wal_replay_validation_status",
        "data_integrity_validation_status",
        "tenant_scope_validation_status",
        "rto_minutes",
        "rpo_minutes",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(rehearsal.get("status") == fixture.get("expected_status"), "rehearsal status mismatch")
    rehearsals = rehearsal.get("rehearsals", [])
    require(len(rehearsals) >= fixture.get("expected_min_rehearsal_count"), "rehearsal count below minimum")

    seen = {r.get("rehearsal_id") for r in rehearsals}
    for rid in [
        "pitr-dry-run-happy-path",
        "pitr-blocked-missing-wal",
        "pitr-blocked-target-time-outside-window",
        "pitr-blocked-production-target"
    ]:
        require(rid in seen, f"rehearsal missing: {rid}")

    for r in rehearsals:
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('rehearsal_id')}")
        require(bool(r.get("restore_target")), f"restore target missing: {r.get('rehearsal_id')}")
        require(bool(r.get("recovery_target_time_status")), f"target time status missing: {r.get('rehearsal_id')}")
        require(bool(r.get("backup_chain_status")), f"backup chain missing: {r.get('rehearsal_id')}")
        require(bool(r.get("wal_archive_status")), f"WAL archive missing: {r.get('rehearsal_id')}")
        require(bool(r.get("restore_preflight_status")), f"preflight missing: {r.get('rehearsal_id')}")
        if r.get("restore_target") == "production_primary":
            require(r.get("restore_preflight_status") == "BLOCKED", "production restore target must be blocked")

    next_step = rehearsal.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

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
        require(runtime.get("mode") == "pitr_rehearsal_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "restore_execution_allowed",
            "primary_overwrite_allowed",
            "replica_rebuild_allowed",
            "wal_replay_execution_allowed",
            "backup_delete_allowed",
            "dns_mutation_allowed",
            "dsn_mutation_allowed",
            "application_route_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("rehearsal_count") >= fixture.get("expected_min_rehearsal_count"), "runtime rehearsal count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("rehearsals", []):
            require(row.get("status") == "DRY_RUN_PITR_REHEARSAL_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Point-in-time recovery provası config, rehearsal, fixture and dry-run runtime are semantically valid")
PY
