#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_4_2_abuse_bot_tuning.v1.json}"
FIXTURE_FILE="${2:-tests/faz6r/faz_6_21_4_2_abuse_bot_tuning_test.json}"

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
    require(config.get("item") == "281", "item must be 281")
    require(config.get("code") == "FAZ_6_21_4_2", "code must be FAZ_6_21_4_2")
    require(config.get("depends_on") == fixture.get("expected_dependency"), "dependency mismatch")
    require(config.get("provider_neutral") is True, "provider_neutral must be true")
    require(config.get("live_provider_api_mutation_allowed") is False, "live provider mutation must be false")

    required = set(config.get("required_controls", []))
    expected = set(fixture.get("expected_required_controls", []))
    require(expected.issubset(required), "expected required controls missing")

    surfaces = {s.get("surface") for s in config.get("protected_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
      require(surface in surfaces, f"protected surface missing: {surface}")

    signals = config.get("signals", [])
    signal_controls = {s.get("control") for s in signals}
    for control in fixture.get("expected_signal_controls", []):
      require(control in signal_controls, f"signal control missing: {control}")

    bad_ua = [s for s in signals if s.get("control") == "bad_user_agent_guard"]
    require(len(bad_ua) == 1, "bad user-agent guard must exist once")
    if bad_ua:
      require(bad_ua[0].get("action") == "block", "bad user-agent action must be block")
      require("sqlmap" in bad_ua[0].get("patterns", []), "sqlmap pattern must be blocked")

    impossible = [s for s in signals if s.get("control") == "impossible_path_guard"]
    require(len(impossible) == 1, "impossible path guard must exist once")
    if impossible:
      require(impossible[0].get("action") == "block", "impossible path action must be block")
      require("/.env*" in impossible[0].get("paths", []), ".env path must be blocked")

    tenant = [s for s in signals if s.get("control") == "tenant_abuse_signal_policy"]
    require(len(tenant) == 1, "tenant abuse signal policy must exist once")
    if tenant:
      dims = set(tenant[0].get("required_dimensions", []))
      require({"tenant_id", "ip", "route", "request_id", "reason"}.issubset(dims), "tenant abuse dimensions incomplete")

    allowlist = config.get("allowlist", {})
    require(allowlist.get("requires_reason") is True, "allowlist must require reason")
    require(allowlist.get("requires_expiry") is True, "allowlist must require expiry")
    require(int(allowlist.get("max_expiry_days", 0)) <= 30, "allowlist max expiry must be <= 30 days")

    rollout = config.get("safe_rollout", {})
    require(rollout.get("default_stage") == "observe", "safe rollout default must be observe")
    require(set(["observe", "challenge", "enforce", "rollback"]).issubset(set(rollout.get("allowed_stages", []))), "safe rollout stages incomplete")

    rollback = config.get("rollback", {})
    require(rollback.get("required") is True, "rollback.required must be true")
    require(rollback.get("evidence_required") is True, "rollback evidence required must be true")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Abuse / bot tuning config and fixture are semantically valid")
PY
