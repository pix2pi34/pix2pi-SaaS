#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_4_5_security_edge_audit.v1.json}"
FIXTURE_FILE="${2:-tests/faz6r/faz_6_21_4_5_security_edge_audit_test.json}"

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
    require(config.get("item") == "284", "item must be 284")
    require(config.get("code") == "FAZ_6_21_4_5", "code must be FAZ_6_21_4_5")
    require(config.get("provider_neutral") is True, "provider_neutral must be true")
    require(config.get("live_provider_api_mutation_allowed") is False, "live provider mutation must be false")

    deps = set(config.get("depends_on", []))
    expected_deps = set(fixture.get("expected_dependencies", []))
    require(expected_deps.issubset(deps), "dependencies incomplete")

    dep_evidence = config.get("dependency_evidence", [])
    require(len(dep_evidence) == fixture.get("expected_dependency_evidence_count"), "dependency evidence count mismatch")
    for dep in dep_evidence:
        require(dep.get("required_final_status") == "PASS", f"dependency {dep.get('code')} must require PASS")
        require(bool(dep.get("file")), f"dependency {dep.get('code')} evidence file missing")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = config.get("audit_surfaces", [])
    by_surface = {s.get("surface"): s for s in surfaces}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in by_surface, f"surface missing: {surface}")

    for surface in fixture.get("expected_no_cache_surfaces", []):
        require(by_surface.get(surface, {}).get("cache_allowed") is False, f"{surface} cache must be false")

    require(by_surface.get("public_web", {}).get("cache_allowed") is True, "public web cache must be allowed")
    require(by_surface.get("health", {}).get("must_not_hard_block") is True, "health must not hard block")
    require(by_surface.get("webhook", {}).get("signature_validation_layer") == "application", "webhook signature layer must be application")
    require(by_surface.get("auth", {}).get("requires_credential_stuffing_guard") is True, "auth must require credential stuffing guard")
    require(by_surface.get("api", {}).get("requires_waf") is True, "api must require waf")
    require(by_surface.get("panel", {}).get("requires_security_headers") is True, "panel must require security headers")

    sec = config.get("security_requirements", {})

    tenant = sec.get("tenant_header_observability", {})
    require(tenant.get("enabled") is True, "tenant header observability must be enabled")
    require(tenant.get("required_header") == fixture.get("expected_tenant_header"), "tenant header mismatch")
    require(tenant.get("action") == "log", "tenant header action must be log")

    tls = sec.get("tls_https_hsts", {})
    require(tls.get("enabled") is True, "tls https hsts must be enabled")
    require(tls.get("minimum_tls") == fixture.get("expected_minimum_tls"), "minimum tls mismatch")
    require(tls.get("preferred_tls") == fixture.get("expected_preferred_tls"), "preferred tls mismatch")
    require(tls.get("https_required") is True, "https required must be true")
    require(tls.get("hsts_required") is True, "hsts required must be true")
    require(tls.get("hsts_header") == fixture.get("expected_hsts_header"), "hsts header mismatch")

    abuse = sec.get("abuse_bot_signals", {})
    require(abuse.get("enabled") is True, "abuse bot signals must be enabled")
    required_signals = set(abuse.get("required_signals", []))
    for signal in ["bot_score_policy", "credential_stuffing_guard", "api_scraping_guard", "tenant_abuse_signal_policy"]:
        require(signal in required_signals, f"abuse signal missing: {signal}")

    rollback = sec.get("rollback_readiness", {})
    require(rollback.get("enabled") is True, "rollback readiness must be enabled")
    require(rollback.get("required") is True, "rollback readiness must be required")
    require(len(rollback.get("strategies", [])) >= 4, "rollback strategies incomplete")

    blocker = config.get("release_blocker_policy", {})
    require(blocker.get("enabled") is True, "release blocker policy must be enabled")
    require(blocker.get("block_release_on_required_fail") is True, "required fail must block release")
    require(blocker.get("block_release_on_missing_dependency_evidence") is True, "missing dependency evidence must block release")
    require(blocker.get("block_release_on_missing_tls_https_hsts") is True, "missing tls https hsts must block release")
    require(blocker.get("block_release_on_missing_rollback") is True, "missing rollback must block release")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Security edge audit config and fixture are semantically valid")
PY
