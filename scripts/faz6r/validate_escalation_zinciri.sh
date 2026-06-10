#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_4_escalation_zinciri.v1.json}"
CHAIN_FILE="${2:-configs/faz6r/escalation_chain.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_4_escalation_zinciri_test.json}"

python3 - "$CONFIG_FILE" "$CHAIN_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
chain_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(chain_path.exists(), f"chain missing: {chain_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    chain = json.loads(chain_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "288", "item must be 288")
    require(config.get("code") == "FAZ_6_21_7_4", "code must be FAZ_6_21_7_4")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    require(config.get("runtime_mutation_allowed") is False, "runtime mutation must be false")
    require(config.get("notification_provider_enabled") is False, "notification provider must be false")
    require(config.get("real_sms_enabled") is False, "real SMS must be false")
    require(config.get("real_email_enabled") is False, "real email must be false")
    require(config.get("real_phone_call_enabled") is False, "real phone call must be false")
    require(config.get("real_pager_enabled") is False, "real pager must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    levels = {l.get("level") for l in config.get("escalation_levels", [])}
    for level in fixture.get("expected_escalation_levels", []):
        require(level in levels, f"escalation level missing: {level}")

    mapping = {m.get("severity"): m for m in config.get("severity_mapping", [])}
    for sev in fixture.get("expected_severities", []):
        require(sev in mapping, f"severity mapping missing: {sev}")

    require(set(fixture.get("expected_p0_required_levels", [])).issubset(set(mapping["P0"].get("required_levels", []))), "P0 required levels incomplete")
    require(set(fixture.get("expected_p1_required_levels", [])).issubset(set(mapping["P1"].get("required_levels", []))), "P1 required levels incomplete")
    require(mapping["P0"].get("incident_commander_required") is True, "P0 incident commander required")
    require(mapping["P1"].get("incident_commander_required") is True, "P1 incident commander required")
    require(mapping["P0"].get("business_owner_required") is True, "P0 business owner required")
    require(mapping["P0"].get("security_owner_required") is True, "P0 security owner required")
    require(mapping["P1"].get("security_owner_required") is True, "P1 security owner required")

    ack = config.get("ack_timeout_policy", {})
    require(ack.get("enabled") is True, "ack timeout policy must be enabled")
    require(ack.get("auto_escalate_on_ack_timeout") is True, "ack timeout must auto escalate")
    require(ack.get("requires_evidence") is True, "ack timeout must require evidence")
    require(ack.get("timeout_action") == "escalate_to_next_level", "timeout action mismatch")
    require(ack.get("provider_action_mode") == fixture.get("expected_provider_mode"), "provider action mode mismatch")

    owners = config.get("owner_notification_policy", {})
    require(owners.get("business_owner_notification_policy", {}).get("mode") == fixture.get("expected_provider_mode"), "business owner mode mismatch")
    require(owners.get("security_owner_notification_policy", {}).get("mode") == fixture.get("expected_provider_mode"), "security owner mode mismatch")
    require(owners.get("technical_owner_notification_policy", {}).get("mode") == fixture.get("expected_provider_mode"), "technical owner mode mismatch")

    provider = config.get("provider_closed_policy", {})
    require(provider.get("enabled") is True, "provider closed policy must be enabled")
    require(provider.get("real_sms_enabled") is False, "provider real SMS must be false")
    require(provider.get("real_email_enabled") is False, "provider real email must be false")
    require(provider.get("real_phone_call_enabled") is False, "provider real phone must be false")
    require(provider.get("real_pager_enabled") is False, "provider real pager must be false")
    require(provider.get("provider_mutation_allowed") is False, "provider mutation must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["incident_id", "severity", "current_level", "next_level", "ack_deadline", "ack_status", "escalation_reason", "timestamp", "final_status"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    chains = {c.get("severity"): c for c in chain.get("chains", [])}
    for sev in fixture.get("expected_severities", []):
        require(sev in chains, f"chain missing: {sev}")

    require(len(chains["P0"].get("steps", [])) == 5, "P0 chain must have 5 steps")
    require(len(chains["P1"].get("steps", [])) == 4, "P1 chain must have 4 steps")
    require(chains["P0"].get("incident_commander_required") is True, "P0 chain IC required")
    require(chains["P1"].get("incident_commander_required") is True, "P1 chain IC required")

    provider_mode = chain.get("provider_mode", {})
    require(provider_mode.get("record_only_no_real_send") is True, "chain provider mode must be record-only")
    require(provider_mode.get("real_sms_enabled") is False, "chain SMS must be false")
    require(provider_mode.get("real_email_enabled") is False, "chain email must be false")
    require(provider_mode.get("real_phone_call_enabled") is False, "chain phone must be false")
    require(provider_mode.get("real_pager_enabled") is False, "chain pager must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Escalation zinciri config, chain artifact and fixture are semantically valid")
PY
