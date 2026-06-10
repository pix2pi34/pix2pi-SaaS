#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_4_1_waf_tuning.v1.json}"
FIXTURE_FILE="${2:-tests/faz6r/faz_6_21_4_1_waf_tuning_test.json}"

python3 - "$CONFIG_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
fixture_path = Path(sys.argv[2])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "280", "item must be 280")
    require(config.get("code") == "FAZ_6_21_4_1", "code must be FAZ_6_21_4_1")
    require(config.get("provider_neutral") is True, "provider_neutral must be true")
    require(config.get("live_provider_api_mutation_allowed") is False, "live mutation must be false")

    domains = config.get("domains", [])
    require("api.pix2pi.com.tr" in domains, "api domain missing")
    require("auth.pix2pi.com.tr" in domains, "auth domain missing")

    required = set(config.get("required_controls", []))
    expected = set(fixture.get("expected_required_controls", []))
    require(expected.issubset(required), "expected controls missing from config")

    rule_controls = {r.get("control") for r in config.get("rule_groups", [])}
    for control in expected:
        if control.endswith("_policy"):
            continue
        require(control in rule_controls, f"rule group missing for {control}")

    rollout = config.get("safe_rollout", {})
    require(rollout.get("default_stage") == "observe", "default rollout must be observe")
    require(set(["observe", "challenge", "enforce", "rollback"]).issubset(set(rollout.get("allowed_stages", []))), "rollout stages incomplete")

    rollback = config.get("rollback", {})
    require(rollback.get("required") is True, "rollback.required must be true")
    require(rollback.get("evidence_required") is True, "rollback evidence must be required")

    tenant_rules = [r for r in config.get("rule_groups", []) if r.get("control") == "tenant_api_header_presence_guard"]
    require(len(tenant_rules) == 1, "tenant header rule must exist once")
    if tenant_rules:
        require(tenant_rules[0].get("required_header") == "X-Tenant-ID", "tenant header must be X-Tenant-ID")

    danger_rules = [r for r in config.get("rule_groups", []) if r.get("control") == "dangerous_method_block"]
    require(len(danger_rules) == 1, "dangerous method rule must exist once")
    if danger_rules:
        blocked = set(danger_rules[0].get("blocked_methods", []))
        require({"TRACE", "TRACK"}.issubset(blocked), "TRACE and TRACK must be blocked")

if errors:
    for e in errors:
        print(f"VALIDATION_FAIL: {e}")
    sys.exit(1)

print("VALIDATION_PASS: WAF tuning config and fixture are semantically valid")
PY
