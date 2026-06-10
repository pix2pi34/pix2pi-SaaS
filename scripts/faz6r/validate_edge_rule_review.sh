#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_4_3_edge_rule_review.v1.json}"
FIXTURE_FILE="${2:-tests/faz6r/faz_6_21_4_3_edge_rule_review_test.json}"

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
    require(config.get("item") == "282", "item must be 282")
    require(config.get("code") == "FAZ_6_21_4_3", "code must be FAZ_6_21_4_3")
    require(config.get("provider_neutral") is True, "provider_neutral must be true")
    require(config.get("live_provider_api_mutation_allowed") is False, "live provider mutation must be false")

    deps = set(config.get("depends_on", []))
    expected_deps = set(fixture.get("expected_dependencies", []))
    require(expected_deps.issubset(deps), "dependency list incomplete")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    route_classes = config.get("route_classes", [])
    classes = {r.get("class") for r in route_classes}
    for expected_class in fixture.get("expected_route_classes", []):
        require(expected_class in classes, f"route class missing: {expected_class}")

    by_class = {r.get("class"): r for r in route_classes}

    require(by_class.get("public_web", {}).get("must_not_require_auth") is True, "public web must not require auth")
    require(by_class.get("api", {}).get("cache_policy") == "no_edge_cache", "api must not use edge cache")
    require(by_class.get("auth", {}).get("credential_stuffing_guard_required") is True, "auth must require credential stuffing guard")
    require(by_class.get("panel", {}).get("strict_security_headers_required") is True, "panel must require strict security headers")
    require(by_class.get("health", {}).get("must_not_hard_block") is True, "health must not hard block")
    require(by_class.get("webhook", {}).get("signature_validation_layer") == "application", "webhook signature validation must remain application layer")

    for cls in fixture.get("expected_no_cache_classes", []):
        require(by_class.get(cls, {}).get("cache_policy") == "no_edge_cache", f"{cls} must bypass edge cache")

    policies = config.get("edge_policies", {})
    headers = set(policies.get("security_header_policy_review", {}).get("required_headers", []))
    for header in fixture.get("expected_security_headers", []):
        require(header in headers, f"security header missing: {header}")

    canonical = policies.get("redirect_canonical_policy_review", {})
    require(canonical.get("force_https") is True, "force_https must be true")
    require(canonical.get("http_to_https_redirect_required") is True, "http to https redirect must be required")

    origin = policies.get("origin_lockdown_policy_review", {})
    require(origin.get("live_origin_firewall_mutation_allowed") is False, "origin firewall mutation must be false")

    cache = policies.get("edge_cache_bypass_policy_review", {})
    must_bypass = set(cache.get("must_bypass", []))
    require("/api/*" in must_bypass, "api must bypass edge cache")
    require("/api/webhooks/*" in must_bypass, "webhooks must bypass edge cache")

    tenant = policies.get("tenant_header_edge_observability_review", {})
    require(tenant.get("required_header") == fixture.get("expected_tenant_header"), "tenant header mismatch")
    require(tenant.get("action") == "log", "tenant edge observability must be log")

    rollback = config.get("rollback", {})
    require(rollback.get("required") is True, "rollback.required must be true")
    require(rollback.get("evidence_required") is True, "rollback evidence must be true")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Edge rule review config and fixture are semantically valid")
PY
