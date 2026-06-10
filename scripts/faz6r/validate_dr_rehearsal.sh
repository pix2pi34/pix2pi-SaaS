#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_6_5_dr_rehearsal.v1.json}"
REHEARSAL_FILE="${2:-configs/faz6r/dr_rehearsal.dr_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_6_5_dr_rehearsal_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_dr_rehearsal_dry_run.sh}"

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
    require(config.get("item") == "292", "item must be 292")
    require(config.get("code") == "FAZ_6_21_6_5", "code must be FAZ_6_21_6_5")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "live_failover_allowed",
        "dns_mutation_allowed",
        "db_promotion_allowed",
        "queue_mutation_allowed",
        "storage_mutation_allowed",
        "compute_mutation_allowed",
        "customer_notification_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    scope = config.get("rehearsal_scope", {})
    require(scope.get("mode") == "dry_run_only", "rehearsal scope mode must be dry_run_only")
    excluded = set(scope.get("excluded_live_actions", []))
    for action in ["dns_failover_execute", "db_promotion_execute", "queue_failover_execute", "storage_failover_execute", "compute_failover_execute", "customer_notification_send", "status_page_publish"]:
        require(action in excluded, f"excluded live action missing: {action}")

    preflight = config.get("preflight_check_policy", {})
    require(preflight.get("enabled") is True, "preflight policy must be enabled")
    for check in ["dependency_evidence_pass", "scenario_catalog_ready", "communication_plan_ready", "rollback_plan_recorded", "provider_mutation_closed"]:
        require(check in preflight.get("required_checks", []), f"preflight check missing: {check}")

    rto = config.get("rto_rpo_measurement_policy", {})
    require(rto.get("enabled") is True, "rto/rpo measurement must be enabled")
    require(rto.get("dry_run_measurement_only") is True, "rto/rpo must be dry-run only")
    require(int(rto.get("target_rto_minutes", 0)) > 0, "target RTO must be positive")
    require(int(rto.get("target_rpo_minutes", 0)) > 0, "target RPO must be positive")

    backup = config.get("backup_restore_readiness_check", {})
    require(backup.get("enabled") is True, "backup restore readiness must be enabled")
    require(backup.get("mode") == "evidence_check_only", "backup restore mode must be evidence_check_only")
    require(backup.get("restore_execution_allowed") is False, "restore execution must be false")

    linked = config.get("linked_artifacts", {})
    for key in ["regional_outage_scenario", "operational_communication_plan", "previous_evidence"]:
        require(bool(linked.get(key)), f"linked artifact missing: {key}")

    provider = config.get("provider_mutation_closed_policy", {})
    require(provider.get("enabled") is True, "provider mutation closed policy must be enabled")
    for field in ["dns_mutation_allowed", "db_promotion_allowed", "queue_mutation_allowed", "storage_mutation_allowed", "compute_mutation_allowed", "customer_notification_allowed", "status_page_publish_allowed"]:
        require(provider.get(field) is False, f"provider {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["rehearsal_id", "scenario_id", "surface", "preflight_status", "rto_target_minutes", "rpo_target_minutes", "measured_rto_status", "measured_rpo_status", "mutation_allowed", "decision", "timestamp"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    require(rehearsal.get("status") == fixture.get("expected_status"), "rehearsal status mismatch")
    rehearsals = rehearsal.get("rehearsals", [])
    require(len(rehearsals) >= fixture.get("expected_min_rehearsal_count"), "rehearsal count below minimum")

    surfaces = {r.get("surface") for r in rehearsals}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"rehearsal surface missing: {surface}")

    for r in rehearsals:
        require(r.get("preflight_status") == "READY", f"preflight not ready: {r.get('rehearsal_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('rehearsal_id')}")
        require("WITHOUT_TARGET" not in str(r.get("measured_rto_status")), f"bad RTO status: {r.get('rehearsal_id')}")
        require("WITHOUT_TARGET" not in str(r.get("measured_rpo_status")), f"bad RPO status: {r.get('rehearsal_id')}")

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
        require(runtime.get("runtime_status") == "PASS", "runtime_status must be PASS")
        require(runtime.get("mode") == "dr_rehearsal_dry_run", "runtime mode mismatch")
        for field in ["live_failover_allowed", "runtime_mutation_allowed", "dns_mutation_allowed", "db_promotion_allowed", "queue_mutation_allowed", "storage_mutation_allowed", "compute_mutation_allowed", "customer_notification_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("rehearsal_count") >= fixture.get("expected_min_rehearsal_count"), "runtime rehearsal count too low")
        for r in runtime.get("rehearsals", []):
            require(r.get("status") == "DRY_RUN_REHEARSAL_RECORD", "runtime rehearsal status mismatch")
            require(r.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: DR rehearsal config, rehearsal, fixture and dry-run runtime are semantically valid")
PY
