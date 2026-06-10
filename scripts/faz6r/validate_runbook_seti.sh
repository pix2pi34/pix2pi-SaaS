#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_1_runbook_seti.v1.json}"
RUNBOOK_FILE="${2:-configs/faz6r/runbook_set.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_1_runbook_seti_test.json}"

python3 - "$CONFIG_FILE" "$RUNBOOK_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
runbook_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(runbook_path.exists(), f"runbook missing: {runbook_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    runbook_set = json.loads(runbook_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "285", "item must be 285")
    require(config.get("code") == "FAZ_6_21_7_1", "code must be FAZ_6_21_7_1")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")
    require(config.get("runtime_mutation_allowed") is False, "runtime mutation must be false")
    require(config.get("destructive_action_default_allowed") is False, "destructive default must be false")
    require(config.get("auto_remediation_enabled") is False, "auto remediation must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    sev_levels = {s.get("level") for s in config.get("severity_model", [])}
    for level in fixture.get("expected_severity_levels", []):
        require(level in sev_levels, f"severity level missing: {level}")

    policies = config.get("policies", {})
    evidence = policies.get("evidence_capture_policy", {})
    require(evidence.get("required") is True, "evidence capture must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["incident_id", "severity", "timestamp", "affected_surface", "actions_taken", "final_status"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    manual = policies.get("manual_approval_policy", {})
    manual_required = set(manual.get("required_for", []))
    for action in fixture.get("expected_manual_approval_for", []):
        require(action in manual_required, f"manual approval action missing: {action}")

    no_destructive = policies.get("no_destructive_default_policy", {})
    require(no_destructive.get("enabled") is True, "no destructive default policy must be enabled")
    require(no_destructive.get("default_mode") == "read_only_diagnosis", "default mode must be read_only_diagnosis")
    require(no_destructive.get("destructive_actions_require_explicit_approval") is True, "destructive actions must require approval")

    esc = policies.get("escalation_policy_placeholder", {})
    require(esc.get("enabled") is True, "escalation placeholder must be enabled")
    require(esc.get("detailed_step") == "FAZ_6_21_7_4", "escalation detailed step must be FAZ_6_21_7_4")

    runbooks = runbook_set.get("runbooks", [])
    require(len(runbooks) == fixture.get("expected_runbook_count"), "runbook count mismatch")

    runbook_controls = {r.get("control") for r in runbooks}
    for control in fixture.get("expected_runbook_controls", []):
        require(control in runbook_controls, f"runbook control missing: {control}")

    for rb in runbooks:
        require(bool(rb.get("id")), "runbook id missing")
        require(bool(rb.get("title")), f"runbook title missing: {rb.get('id')}")
        require(bool(rb.get("symptoms")), f"symptoms missing: {rb.get('id')}")
        require(bool(rb.get("detection")), f"detection missing: {rb.get('id')}")
        require(bool(rb.get("first_response")), f"first_response missing: {rb.get('id')}")
        require(bool(rb.get("mitigation")), f"mitigation missing: {rb.get('id')}")
        require(bool(rb.get("rollback")), f"rollback missing: {rb.get('id')}")
        require(rb.get("evidence_required") is True, f"evidence_required must be true: {rb.get('id')}")
        require(bool(rb.get("owner")), f"owner missing: {rb.get('id')}")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Runbook seti config, runbook artifact and fixture are semantically valid")
PY
