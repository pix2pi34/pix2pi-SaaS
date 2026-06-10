#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_6_4_operasyonel_iletisim_plani.v1.json}"
PLAN_FILE="${2:-configs/faz6r/operational_communication_plan.dr_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_6_4_operasyonel_iletisim_plani_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_operational_communication_dry_run.sh}"

python3 - "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(plan_path.exists(), f"plan missing: {plan_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "291", "item must be 291")
    require(config.get("code") == "FAZ_6_21_6_4", "code must be FAZ_6_21_6_4")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "real_customer_notification_enabled",
        "real_status_page_enabled",
        "real_email_enabled",
        "real_sms_enabled",
        "real_phone_call_enabled",
        "provider_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    stakeholders = config.get("stakeholders", [])
    stakeholder_roles = {s.get("role") for s in stakeholders}
    for role in ["incident_commander", "sre_owner", "ops_owner", "business_owner", "security_owner", "support_owner", "customer"]:
        require(role in stakeholder_roles, f"stakeholder missing: {role}")

    sev_map = config.get("severity_communication_mapping", [])
    severities = {m.get("severity") for m in sev_map}
    for sev in fixture.get("expected_severities", []):
        require(sev in severities, f"severity mapping missing: {sev}")

    by_sev = {m.get("severity"): m for m in sev_map}
    require(by_sev["P0"].get("business_owner_approval_required") is True, "P0 business owner approval required")
    require(by_sev["P1"].get("business_owner_approval_required") is True, "P1 business owner approval required")
    require(by_sev["P0"].get("status_page_update_required_if_public_impact") is True, "P0 status page rule missing")
    require(by_sev["P1"].get("status_page_update_required_if_public_impact") is True, "P1 status page rule missing")
    require(int(by_sev["P0"].get("next_update_minutes", 0)) <= 30, "P0 next update too slow")

    provider = config.get("channel_provider_closed_policy", {})
    require(provider.get("enabled") is True, "channel provider closed policy must be enabled")
    require(provider.get("mode") == fixture.get("expected_send_mode"), "provider mode mismatch")
    for field in ["real_customer_notification_enabled", "real_status_page_enabled", "real_email_enabled", "real_sms_enabled", "real_phone_call_enabled", "provider_mutation_allowed"]:
        require(provider.get(field) is False, f"provider {field} must be false")

    approval = config.get("approval_policy", {})
    require(approval.get("business_owner_approval_required_for_customer_facing") is True, "business approval for customer-facing required")
    require(approval.get("security_owner_approval_required_for_security_incident") is True, "security approval for security incident required")
    require(approval.get("incident_commander_approval_required_for_p0_p1") is True, "IC approval for P0/P1 required")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["communication_id", "incident_id", "severity", "audience", "channel", "message_template", "approval_required", "approval_owner", "send_mode", "next_update_minutes", "timestamp"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    channels = {c.get("channel") for c in plan.get("channels", [])}
    for channel in fixture.get("expected_channels", []):
        require(channel in channels, f"channel missing: {channel}")

    for c in plan.get("channels", []):
        require(c.get("mode") == fixture.get("expected_send_mode"), f"channel must be record only: {c.get('channel')}")

    templates = plan.get("templates", [])
    require(len(templates) >= fixture.get("expected_template_count"), "template count below expected")
    template_channels = {t.get("channel") for t in templates}
    for channel in ["internal_incident_room", "customer_update_draft", "status_page_draft", "support_macro_draft"]:
        require(channel in template_channels, f"template channel missing: {channel}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(plan_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime_status must be PASS")
        require(runtime.get("mode") == "operational_communication_dry_run", "runtime mode mismatch")
        for field in ["real_customer_notification_enabled", "real_status_page_enabled", "real_email_enabled", "real_sms_enabled", "real_phone_call_enabled", "provider_mutation_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("communication_count", 0) > 0, "runtime must produce communication records")
        for comm in runtime.get("communications", []):
            require(comm.get("send_mode") == fixture.get("expected_send_mode"), "communication must be record only")
            require(comm.get("status") == "DRY_RUN_COMMUNICATION_RECORD", "communication status mismatch")
            require(bool(comm.get("next_update_minutes")), "next update minutes missing")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Operasyonel iletişim planı config, plan, fixture and dry-run runtime are semantically valid")
PY
