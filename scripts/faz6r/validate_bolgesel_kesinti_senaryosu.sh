#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_6_3_bolgesel_kesinti_senaryosu.v1.json}"
SCENARIO_FILE="${2:-configs/faz6r/regional_outage_scenario.dr_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_6_3_bolgesel_kesinti_senaryosu_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_regional_outage_scenario_dry_run.sh}"

python3 - "$CONFIG_FILE" "$SCENARIO_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
scenario_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(scenario_path.exists(), f"scenario missing: {scenario_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    scenario_doc = json.loads(scenario_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "290", "item must be 290")
    require(config.get("code") == "FAZ_6_21_6_3", "code must be FAZ_6_21_6_3")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "live_failover_allowed",
        "dns_mutation_allowed",
        "db_failover_allowed",
        "queue_failover_allowed",
        "storage_failover_allowed",
        "compute_failover_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    rto_rpo = config.get("rto_rpo_policy", {})
    require(rto_rpo.get("enabled") is True, "rto/rpo policy must be enabled")
    require(int(rto_rpo.get("default_rto_minutes", 0)) > 0, "default RTO must be positive")
    require(int(rto_rpo.get("default_rpo_minutes", 0)) > 0, "default RPO must be positive")
    require(rto_rpo.get("requires_business_owner_ack") is True, "business owner ack must be required")

    surfaces = set(config.get("affected_surfaces", []))
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"affected surface missing: {surface}")

    guards = config.get("failover_guards", {})
    for guard_name in ["dns_failover_guard", "db_failover_guard", "queue_failover_guard", "storage_failover_guard"]:
        guard = guards.get(guard_name, {})
        require(guard.get("enabled") is True, f"{guard_name} must be enabled")
        require(guard.get("manual_approval_required") is True, f"{guard_name} manual approval required")

    degrade = config.get("read_only_degradation_policy", {})
    require(degrade.get("enabled") is True, "read-only degradation policy must be enabled")
    allowed_decisions = set(degrade.get("allowed_decisions", []))
    for decision in fixture.get("expected_decisions", []):
        require(decision in allowed_decisions, f"decision missing: {decision}")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval must be required")
    for action in ["dns_failover_execute", "db_failover_execute", "queue_failover_execute", "storage_failover_execute", "compute_failover_execute"]:
        require(action in manual.get("required_for", []), f"manual approval action missing: {action}")

    comm = config.get("communication_handoff_policy", {})
    require(comm.get("required") is True, "communication handoff must be required")
    require(comm.get("detailed_step") == fixture.get("expected_communication_step"), "communication step mismatch")

    provider = config.get("provider_mutation_closed_policy", {})
    require(provider.get("enabled") is True, "provider mutation closed policy must be enabled")
    for field in ["dns_mutation_allowed", "db_promotion_allowed", "queue_mutation_allowed", "storage_mutation_allowed", "compute_mutation_allowed"]:
        require(provider.get(field) is False, f"provider {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["scenario_id", "severity", "affected_region", "affected_surfaces", "rto_minutes", "rpo_minutes", "decision", "manual_approval_required", "provider_mutation_allowed", "timestamp"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    scenarios = scenario_doc.get("scenarios", [])
    require(len(scenarios) >= fixture.get("expected_min_scenario_count"), "scenario count below minimum")
    for s in scenarios:
        require(bool(s.get("scenario_id")), "scenario_id missing")
        require(s.get("provider_mutation_allowed") is False, f"provider mutation must be false for {s.get('scenario_id')}")
        require(s.get("manual_approval_required") is True, f"manual approval must be true for {s.get('scenario_id')}")
        require(s.get("communication_handoff_required") is True, f"communication handoff must be true for {s.get('scenario_id')}")
        require(s.get("decision") in allowed_decisions, f"scenario decision not allowed: {s.get('decision')}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(scenario_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime_status must be PASS")
        require(runtime.get("mode") == "regional_outage_dry_run", "runtime mode mismatch")
        for field in ["live_failover_allowed", "dns_mutation_allowed", "db_failover_allowed", "queue_failover_allowed", "storage_failover_allowed", "compute_failover_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("scenario_count") >= fixture.get("expected_min_scenario_count"), "runtime scenario count below minimum")
        for decision in runtime.get("decisions", []):
            require(decision.get("status") == "DRY_RUN_DECISION_ONLY", "runtime decision must be dry-run only")
            require(decision.get("provider_mutation_allowed") is False, "runtime provider mutation must be false")
            require(decision.get("manual_approval_required") is True, "runtime manual approval must be true")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Bölgesel kesinti senaryosu config, scenario, fixture and dry-run runtime are semantically valid")
PY
