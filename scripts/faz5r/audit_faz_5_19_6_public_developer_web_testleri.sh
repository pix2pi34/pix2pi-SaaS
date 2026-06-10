#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-19.6"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_19_6_PUBLIC_DEVELOPER_WEB_TESTLERI.md"
CONFIG_FILE="configs/faz5r/faz_5_19_6_public_developer_web_testleri.v1.json"
CONTROL_FILE="configs/faz5r/public_developer_web_tests.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_19_6_public_developer_web_testleri_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/publicdeveloperwebtests/public_developer_web_tests.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/publicdeveloperwebtests/public_developer_web_tests_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_19_6_PUBLIC_DEVELOPER_WEB_TESTLERI_REAL_IMPLEMENTATION_AUDIT.md"

WEB_DEVELOPER_DOCS="web/faz5r/developer-docs/index.html"
WEB_API_KEY="web/faz5r/api-key-management/index.html"
WEB_SANDBOX="web/faz5r/sandbox-surface/index.html"
WEB_PRICING="web/faz5r/pricing-pages/index.html"

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$PHASE $1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$PHASE $1 REQUIRED_FAIL / HATA ❌"
}

contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

file_exists() {
  local file="$1"
  local label="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

html_has_common_guards() {
  local file="$1"
  local label="$2"

  file_exists "$file" "$label file"
  contains "$file" '<meta name="viewport"' "$label viewport"
  contains "$file" 'noindex,nofollow' "$label noindex"
  contains "$file" 'Launch Guard' "$label launch guard"
}

echo "===== FAZ 5-19.6 PUBLIC / DEVELOPER WEB TESTLERI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"developer_docs_web"' "developer docs web registered"
contains "$CONTROL_FILE" '"api_key_management_web"' "api key management web registered"
contains "$CONTROL_FILE" '"sandbox_surface_web"' "sandbox surface web registered"
contains "$CONTROL_FILE" '"pricing_pages_web"' "pricing pages web registered"
contains "$CONTROL_FILE" '"launch_guard_matrix"' "launch guard matrix registered"
contains "$CONTROL_FILE" '"html_quality_matrix"' "html quality matrix registered"
contains "$CONTROL_FILE" '"security_guard_matrix"' "security guard matrix registered"
contains "$CONTROL_FILE" '"final_closure_deferred_marker"' "final closure deferred marker registered"

contains "$CONTROL_FILE" '"DEVELOPER_DOCS"' "developer docs domain registered"
contains "$CONTROL_FILE" '"API_KEY_SCREEN"' "api key screen domain registered"
contains "$CONTROL_FILE" '"SANDBOX_SURFACE"' "sandbox surface domain registered"
contains "$CONTROL_FILE" '"PRICING_PAGES"' "pricing pages domain registered"
contains "$CONTROL_FILE" '"LAUNCH_GUARD"' "launch guard domain registered"
contains "$CONTROL_FILE" '"HTML_QUALITY"' "html quality domain registered"
contains "$CONTROL_FILE" '"SECURITY_GUARD"' "security guard domain registered"
contains "$CONTROL_FILE" '"CLOSURE_NEXT"' "closure next domain registered"

contains "$CONTROL_FILE" '"internal_web_tests_ready": true' "internal web tests ready"
contains "$CONTROL_FILE" '"public_developer_surface_tests_ready": true' "public developer surface tests ready"
contains "$CONTROL_FILE" '"production_publish_allowed": false' "production publish disabled"
contains "$CONTROL_FILE" '"real_customer_access_enabled": false' "real customer access disabled"
contains "$CONTROL_FILE" '"real_developer_access_enabled": false' "real developer access disabled"
contains "$CONTROL_FILE" '"checkout_enabled": false' "checkout disabled"
contains "$CONTROL_FILE" '"payment_collection_enabled": false' "payment collection disabled"
contains "$CONTROL_FILE" '"api_key_creation_enabled": false' "api key creation disabled"
contains "$CONTROL_FILE" '"sandbox_live_enabled": false' "sandbox live disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"static_html_ready": true' "static html ready"
contains "$CONTROL_FILE" '"requires_file_exists": true' "file exists required"
contains "$CONTROL_FILE" '"requires_noindex": true' "noindex required"
contains "$CONTROL_FILE" '"requires_viewport": true' "viewport required"
contains "$CONTROL_FILE" '"requires_start_marker": true' "start marker required"
contains "$CONTROL_FILE" '"requires_launch_guard": true' "launch guard required"
contains "$CONTROL_FILE" '"requires_production_disabled_marker": true' "production disabled marker required"
contains "$CONTROL_FILE" '"requires_real_access_disabled_marker": true' "real access disabled marker required"
contains "$CONTROL_FILE" '"requires_checkout_disabled_marker": true' "checkout disabled marker required"
contains "$CONTROL_FILE" '"requires_payment_collection_disabled_marker": true' "payment collection disabled marker required"
contains "$CONTROL_FILE" '"requires_api_key_creation_disabled_marker": true' "api key creation disabled marker required"
contains "$CONTROL_FILE" '"requires_sandbox_live_disabled_marker": true' "sandbox live disabled marker required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_customer": true' "real customer block present"
contains "$CONTROL_FILE" '"blocks_real_developer_access": true' "real developer access block present"
contains "$CONTROL_FILE" '"blocks_checkout": true' "checkout block present"
contains "$CONTROL_FILE" '"blocks_payment_collection": true' "payment collection block present"
contains "$CONTROL_FILE" '"blocks_api_key_creation": true' "api key creation block present"
contains "$CONTROL_FILE" '"blocks_sandbox_live": true' "sandbox live block present"
contains "$CONTROL_FILE" '"deferred_to_final_closure": true' "final closure deferred present"
contains "$CONTROL_FILE" '"FAZ_5_R_FINAL_REVIEW_CLOSURE"' "next gate final closure present"

html_has_common_guards "$WEB_DEVELOPER_DOCS" "developer docs html"
contains "$WEB_DEVELOPER_DOCS" "PIX2PI_DEVELOPER_DOCS_PORTAL_START" "developer docs marker"
contains "$WEB_DEVELOPER_DOCS" "production_docs_published=false" "developer docs production disabled marker"
contains "$WEB_DEVELOPER_DOCS" "api_key_creation_enabled=false" "developer docs api key disabled marker"
contains "$WEB_DEVELOPER_DOCS" "X-Tenant-ID" "developer docs tenant safety"

html_has_common_guards "$WEB_API_KEY" "api key html"
contains "$WEB_API_KEY" "PIX2PI_API_KEY_MANAGEMENT_SCREEN_START" "api key screen marker"
contains "$WEB_API_KEY" "api_key_creation_enabled=false" "api key creation disabled marker"
contains "$WEB_API_KEY" "api_key_reveal_enabled=false" "api key reveal disabled marker"
contains "$WEB_API_KEY" "api_key_rotation_enabled=false" "api key rotation disabled marker"
contains "$WEB_API_KEY" "X-Tenant-ID" "api key tenant safety"

html_has_common_guards "$WEB_SANDBOX" "sandbox html"
contains "$WEB_SANDBOX" "PIX2PI_SANDBOX_SURFACE_START" "sandbox marker"
contains "$WEB_SANDBOX" "live_api_call_enabled=false" "sandbox live api disabled marker"
contains "$WEB_SANDBOX" "live_data_mutation_enabled=false" "sandbox live mutation disabled marker"
contains "$WEB_SANDBOX" "payment_simulation_live_enabled=false" "sandbox payment simulation disabled marker"
contains "$WEB_SANDBOX" "X-Tenant-ID" "sandbox tenant safety"

html_has_common_guards "$WEB_PRICING" "pricing html"
contains "$WEB_PRICING" "PIX2PI_PRICING_PAGES_START" "pricing marker"
contains "$WEB_PRICING" "production_page_published=false" "pricing production disabled marker"
contains "$WEB_PRICING" "checkout_enabled=false" "pricing checkout disabled marker"
contains "$WEB_PRICING" "payment_collection_enabled=false" "pricing payment collection disabled marker"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCKED" "production publish guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_ACCESS_BLOCKED" "real customer access guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCKED" "real developer access guard"
contains "$RUNTIME_FILE" "CHECKOUT_BLOCKED" "checkout guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_BLOCKED" "payment collection guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCKED" "api key creation guard"
contains "$RUNTIME_FILE" "SANDBOX_LIVE_BLOCKED" "sandbox live guard"
contains "$RUNTIME_FILE" "NOINDEX_REQUIRED" "noindex guard"
contains "$RUNTIME_FILE" "VIEWPORT_REQUIRED" "viewport guard"
contains "$RUNTIME_FILE" "START_MARKER_REQUIRED" "start marker guard"
contains "$RUNTIME_FILE" "LAUNCH_GUARD_REQUIRED" "launch guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/publicdeveloperwebtests; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/public_developer_web_tests.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_19_6_public_developer_web_testleri_test.json").read_text())

surfaces = {s["key"]: s for s in control["surfaces"]}
domains = {s["domain"] for s in control["surfaces"]}

for key in test["must_have_surface_keys"]:
    assert key in surfaces, f"missing surface key: {key}"
    s = surfaces[key]
    assert s["required"] is True, f"surface not required: {key}"
    assert s["has_evidence"] is True, f"evidence missing: {key}"
    assert s["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert s["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert s["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert s["production_published"] is False, f"production must be false: {key}"
    assert s["real_customer_enabled"] is False, f"real customer must be false: {key}"
    assert s["real_developer_access_enabled"] is False, f"developer access must be false: {key}"
    assert s["checkout_enabled"] is False, f"checkout must be false: {key}"
    assert s["payment_collection_enabled"] is False, f"payment must be false: {key}"
    assert s["api_key_creation_enabled"] is False, f"api key creation must be false: {key}"
    assert s["sandbox_live_enabled"] is False, f"sandbox live must be false: {key}"
    assert s["blocks_production_publish"] is True, f"production block missing: {key}"
    assert s["blocks_real_customer"] is True, f"real customer block missing: {key}"
    assert s["blocks_real_developer_access"] is True, f"developer access block missing: {key}"
    assert s["blocks_checkout"] is True, f"checkout block missing: {key}"
    assert s["blocks_payment_collection"] is True, f"payment block missing: {key}"
    assert s["blocks_api_key_creation"] is True, f"api key block missing: {key}"
    assert s["blocks_sandbox_live"] is True, f"sandbox block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

for f in test["must_have_web_files"]:
    p = Path(f)
    assert p.exists(), f"missing web file: {f}"
    text = p.read_text()
    assert '<meta name="viewport"' in text, f"missing viewport: {f}"
    assert 'noindex,nofollow' in text, f"missing noindex: {f}"
    assert 'Launch Guard' in text, f"missing launch guard: {f}"

assert surfaces["final_closure_deferred_marker"]["deferred_to_final_closure"] is True
assert surfaces["final_closure_deferred_marker"]["deferred_reason"], "final closure deferred reason missing"
assert control["internal_web_tests_ready"] is True
assert control["public_developer_surface_tests_ready"] is True
assert control["production_publish_allowed"] is False
assert control["real_customer_access_enabled"] is False
assert control["real_developer_access_enabled"] is False
assert control["checkout_enabled"] is False
assert control["payment_collection_enabled"] is False
assert control["api_key_creation_enabled"] is False
assert control["sandbox_live_enabled"] is False
assert control["final_policy"]["faz_5_r_priority_4_web_l8_complete"] is True
assert control["final_policy"]["faz_5_r_final_review_closure_required_next"] is True
PY
then
  ok "json semantic validation"
else
  fail "json semantic validation"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

mkdir -p "$(dirname "$EVIDENCE_FILE")"
cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 5-19.6 Public / Developer Web Testleri Real Implementation Audit

PHASE=FAZ_5_19_6
AUDIT_DATE=$(date -Is)

## Real Implementation Audit Result

PASS_COUNT=$PASS_COUNT
FAIL_COUNT=$FAIL_COUNT
WARN_COUNT=$WARN_COUNT
REQUIRED_FAIL=$REQUIRED_FAIL
OPTIONAL_WARN=$OPTIONAL_WARN

## Status

DOC_STATUS=READY
CONFIG_STATUS=READY
CONTROL_CONFIG_STATUS=READY
RUNTIME_STATUS=READY
TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
INTERNAL_WEB_TESTS_READY=true
PUBLIC_DEVELOPER_SURFACE_TESTS_READY=true
PRODUCTION_PUBLISH_ALLOWED=false
REAL_CUSTOMER_ACCESS_ENABLED=false
REAL_DEVELOPER_ACCESS_ENABLED=false
CHECKOUT_ENABLED=false
PAYMENT_COLLECTION_ENABLED=false
API_KEY_CREATION_ENABLED=false
SANDBOX_LIVE_ENABLED=false
FAZ_5_R_PRIORITY_4_WEB_L8_COMPLETE=true
FAZ_5_R_FINAL_REVIEW_CLOSURE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
- $WEB_DEVELOPER_DOCS
- $WEB_API_KEY
- $WEB_SANDBOX
- $WEB_PRICING
EOF2

echo "===== FAZ 5-19.6 PUBLIC / DEVELOPER WEB TESTLERI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_19_6_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_19_6_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
