#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_3_on_call_plani.v1.json}"
PLAN_FILE="${2:-configs/faz6r/on_call_plan.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_3_on_call_plani_test.json}"

python3 - "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(plan_path.exists(), f"plan missing: {plan_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "287", "item must be 287")
    require(config.get("code") == "FAZ_6_21_7_3", "code must be FAZ_6_21_7_3")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    require(config.get("runtime_mutation_allowed") is False, "runtime mutation must be false")
    require(config.get("notification_provider_enabled") is False, "notification provider must be disabled")
    require(config.get("real_paging_enabled") is False, "real paging must be disabled")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    roles = {r.get("role") for r in config.get("roles", [])}
    for role in fixture.get("expected_roles", []):
        require(role in roles, f"role missing: {role}")

    coverage = config.get("coverage_policy", {})
    require(coverage.get("timezone") == fixture.get("expected_timezone"), "timezone mismatch")
    require(coverage.get("primary_required") is True, "primary must be required")
    require(coverage.get("secondary_required") is True, "secondary must be required")
    require(coverage.get("handoff_required") is True, "handoff must be required")

    handoff_fields = set(coverage.get("minimum_handoff_fields", []))
    for field in ["from_owner", "to_owner", "handoff_time", "active_incidents", "known_risks", "acknowledgement"]:
        require(field in handoff_fields, f"handoff field missing: {field}")

    targets = config.get("severity_response_targets", [])
    target_by_sev = {t.get("severity"): t for t in targets}
    for sev in fixture.get("expected_severities", []):
        require(sev in target_by_sev, f"severity target missing: {sev}")

    require(target_by_sev["P0"].get("ack_target_minutes") <= 5, "P0 ack target too slow")
    require(target_by_sev["P1"].get("ack_target_minutes") <= 15, "P1 ack target too slow")
    require(target_by_sev["P0"].get("incident_commander_required") is True, "P0 incident commander required")
    require(target_by_sev["P1"].get("incident_commander_required") is True, "P1 incident commander required")

    override = config.get("override_policy", {})
    require(override.get("enabled") is True, "override policy must be enabled")
    require(override.get("requires_reason") is True, "override must require reason")
    require(override.get("requires_replacement_owner") is True, "override must require replacement owner")
    require(int(override.get("max_override_hours", 0)) <= 24, "override max hours must be <= 24")

    fatigue = config.get("fatigue_management_policy", {})
    require(fatigue.get("enabled") is True, "fatigue policy must be enabled")
    require(int(fatigue.get("max_continuous_on_call_hours", 0)) <= 24, "max continuous on-call too high")
    require(fatigue.get("requires_secondary_backup") is True, "secondary backup required")

    notify = config.get("notification_provider_policy", {})
    require(notify.get("enabled") is False, "notification provider must stay disabled")
    require(notify.get("real_sms_enabled") is False, "real SMS must stay disabled")
    require(notify.get("real_email_enabled") is False, "real email must stay disabled")
    require(notify.get("real_phone_call_enabled") is False, "real phone call must stay disabled")
    require(notify.get("provider_mutation_allowed") is False, "provider mutation must stay disabled")

    esc = config.get("escalation_placeholder_policy", {})
    require(esc.get("enabled") is True, "escalation placeholder must be enabled")
    require(esc.get("detailed_step") == fixture.get("expected_escalation_step"), "escalation detailed step mismatch")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["incident_id", "severity", "primary_on_call", "secondary_on_call", "ack_time", "triage_time", "handoff_status", "final_status"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    rotation = plan.get("rotation", {})
    require(plan.get("timezone") == fixture.get("expected_timezone"), "plan timezone mismatch")
    require(rotation.get("primary_required") is True, "plan primary required")
    require(rotation.get("secondary_required") is True, "plan secondary required")
    require(rotation.get("incident_commander_for_p0_p1") is True, "plan incident commander for P0/P1 required")
    require(rotation.get("real_calendar_invite_enabled") is False, "real calendar invite must be disabled")
    require(rotation.get("real_pager_enabled") is False, "real pager must be disabled")

    require(len(plan.get("sample_roster", [])) >= 2, "sample roster must have at least two templates")
    require(len(plan.get("handoff_checklist", [])) >= 5, "handoff checklist too short")

    assignment = {a.get("severity"): a for a in plan.get("incident_assignment_rules", [])}
    require(assignment.get("P0", {}).get("incident_commander_required") is True, "P0 assignment must require IC")
    require(assignment.get("P1", {}).get("incident_commander_required") is True, "P1 assignment must require IC")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: On-call plan config, plan artifact and fixture are semantically valid")
PY
