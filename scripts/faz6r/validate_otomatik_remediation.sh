#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_2_otomatik_remediation.v1.json}"
RULES_FILE="${2:-configs/faz6r/auto_remediation.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_2_otomatik_remediation_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_auto_remediation_dry_run.sh}"

python3 - "$CONFIG_FILE" "$RULES_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
rules_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])

errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(rules_path.exists(), f"rules missing: {rules_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    rules = json.loads(rules_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "286", "item must be 286")
    require(config.get("code") == "FAZ_6_21_7_2", "code must be FAZ_6_21_7_2")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    require(config.get("auto_remediation_mode") == fixture.get("expected_mode"), "mode mismatch")
    require(config.get("runtime_mutation_allowed") is False, "runtime mutation must be false")
    require(config.get("production_mutation_allowed") is False, "production mutation must be false")
    require(config.get("destructive_action_default_allowed") is False, "destructive default must be false")
    require(config.get("manual_approval_required_for_production_mutation") is True, "manual approval for production mutation must be true")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    safe = set(config.get("safe_action_allowlist", []))
    expected_safe = set(fixture.get("expected_safe_actions", []))
    require(expected_safe.issubset(safe), "safe action allowlist incomplete")

    unsafe = set(config.get("unsafe_action_denylist", []))
    expected_unsafe = set(fixture.get("expected_unsafe_actions", []))
    require(expected_unsafe.issubset(unsafe), "unsafe action denylist incomplete")

    approval = config.get("approval_policy", {})
    require(approval.get("manual_approval_required") is True, "manual approval policy must be required")
    require(set(["P0", "P1"]).issubset(set(approval.get("required_for_severities", []))), "P0/P1 approval policy missing")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["incident_id", "severity", "signal", "recommended_action", "action_mode", "approval_required", "runbook_id", "decision_reason", "timestamp"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    rule_list = rules.get("rules", [])
    require(len(rule_list) == fixture.get("expected_rule_count"), "rule count mismatch")

    for rule in rule_list:
        require(bool(rule.get("id")), "rule id missing")
        require(bool(rule.get("signal")), f"rule signal missing: {rule.get('id')}")
        require(bool(rule.get("runbook_id")), f"runbook binding missing: {rule.get('id')}")
        require(bool(rule.get("safe_actions")), f"safe actions missing: {rule.get('id')}")
        require(bool(rule.get("unsafe_actions_blocked")), f"unsafe blocked actions missing: {rule.get('id')}")
        require(rule.get("approval_required_for_execute") is True, f"approval required missing: {rule.get('id')}")
        for action in rule.get("safe_actions", []):
            require(action in safe, f"safe action not allowlisted: {action}")
        for action in rule.get("unsafe_actions_blocked", []):
            require(action in unsafe, f"unsafe blocked action not denylisted: {action}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(rules_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime_result = json.loads(proc.stdout)
        require(runtime_result.get("runtime_status") == "PASS", "runtime_status must be PASS")
        require(runtime_result.get("mode") == "dry_run_guarded", "runtime mode must be dry_run_guarded")
        require(runtime_result.get("production_mutation_allowed") is False, "runtime production mutation must be false")
        require(runtime_result.get("destructive_action_default_allowed") is False, "runtime destructive default must be false")
        require(runtime_result.get("decision_count") == len(fixture.get("sample_incidents", [])), "runtime decision count mismatch")
        for decision in runtime_result.get("decisions", []):
            require(decision.get("status") == "DRY_RUN_RECOMMENDATION", "decision must be dry-run recommendation")
            require(decision.get("action_mode") == "dry_run_guarded", "decision mode must be dry_run_guarded")
            require(bool(decision.get("runbook_id")), "decision runbook_id missing")
            require(bool(decision.get("recommended_action")), "decision recommended_action missing")
            require(decision.get("decision_reason") == "dry_run_guarded_mode_no_production_mutation", "decision reason mismatch")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Otomatik remediation config, rules, fixture and dry-run runtime are semantically valid")
PY
