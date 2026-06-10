#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_4_4_tls_cert_continuous_checks.v1.json}"
FIXTURE_FILE="${2:-tests/faz6r/faz_6_21_4_4_tls_cert_continuous_checks_test.json}"

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
    require(config.get("item") == "283", "item must be 283")
    require(config.get("code") == "FAZ_6_21_4_4", "code must be FAZ_6_21_4_4")
    require(config.get("provider_neutral") is True, "provider_neutral must be true")
    require(config.get("live_certificate_mutation_allowed") is False, "live certificate mutation must be false")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    required = set(config.get("required_controls", []))
    expected = set(fixture.get("expected_required_controls", []))
    require(expected.issubset(required), "required controls incomplete")

    domains = config.get("domains", [])
    domain_hosts = {d.get("host") for d in domains}
    for host in fixture.get("expected_domains", []):
        require(host in domain_hosts, f"domain missing: {host}")

    for d in domains:
        require(d.get("https_required") is True, f"https_required must be true for {d.get('host')}")
        require(d.get("hsts_required") is True, f"hsts_required must be true for {d.get('host')}")
        require(d.get("min_tls_version") == fixture.get("expected_min_tls_version"), f"min tls mismatch for {d.get('host')}")

    expiry = config.get("certificate_expiry_check_policy", {})
    require(expiry.get("enabled") is True, "expiry policy must be enabled")
    require(expiry.get("warning_days") == fixture.get("expected_warning_days"), "warning_days mismatch")
    require(expiry.get("critical_days") == fixture.get("expected_critical_days"), "critical_days mismatch")
    require(expiry.get("blocker_days") == fixture.get("expected_blocker_days"), "blocker_days mismatch")
    require(expiry.get("warning_days") > expiry.get("critical_days") > expiry.get("blocker_days"), "expiry thresholds must be descending")

    https = config.get("https_enforcement_policy", {})
    require(https.get("enabled") is True, "https enforcement must be enabled")
    require(https.get("http_to_https_redirect_required") is True, "http to https redirect must be required")

    hsts = config.get("hsts_policy", {})
    require(hsts.get("enabled") is True, "hsts policy must be enabled")
    require(hsts.get("required_header") == fixture.get("expected_hsts_header"), "hsts header mismatch")
    require(int(hsts.get("minimum_max_age_seconds", 0)) >= 15552000, "hsts max-age too low")

    tls = config.get("tls_min_version_policy", {})
    require(tls.get("minimum_allowed") == fixture.get("expected_min_tls_version"), "minimum tls version mismatch")
    require(tls.get("preferred") == fixture.get("expected_preferred_tls_version"), "preferred tls version mismatch")

    chain = config.get("certificate_chain_validation_policy", {})
    require(chain.get("verify_chain") is True, "verify_chain must be true")
    require(chain.get("verify_hostname") is True, "verify_hostname must be true")
    require(chain.get("verify_not_expired") is True, "verify_not_expired must be true")

    schedule = config.get("scheduled_check_policy", {})
    require(schedule.get("enabled") is True, "scheduled check must be enabled")
    require(schedule.get("suggested_frequency") == fixture.get("expected_scheduled_frequency"), "scheduled frequency mismatch")
    require(schedule.get("live_cron_mutation_allowed") is False, "live cron mutation must be false")

    rollback = config.get("rollback", {})
    require(rollback.get("required") is True, "rollback.required must be true")
    require(rollback.get("evidence_required") is True, "rollback evidence must be true")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: TLS / cert continuous checks config and fixture are semantically valid")
PY
