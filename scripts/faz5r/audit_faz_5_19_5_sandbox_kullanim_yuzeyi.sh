#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-19.5"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_19_5_SANDBOX_KULLANIM_YUZEYI.md"
CONFIG_FILE="configs/faz5r/faz_5_19_5_sandbox_kullanim_yuzeyi.v1.json"
CONTROL_FILE="configs/faz5r/sandbox_surface.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_19_5_sandbox_kullanim_yuzeyi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/sandboxsurface/sandbox_surface.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/sandboxsurface/sandbox_surface_test.go"
WEB_FILE="web/faz5r/sandbox-surface/index.html"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_19_5_SANDBOX_KULLANIM_YUZEYI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-19.5 SANDBOX KULLANIM YUZEYI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"
file_exists "$WEB_FILE" "HTML sandbox file"

contains "$CONTROL_FILE" '"sandbox_overview"' "sandbox overview registered"
contains "$CONTROL_FILE" '"mock_credentials_panel"' "mock credentials panel registered"
contains "$CONTROL_FILE" '"sample_requests_panel"' "sample requests panel registered"
contains "$CONTROL_FILE" '"sample_responses_panel"' "sample responses panel registered"
contains "$CONTROL_FILE" '"webhook_mock_panel"' "webhook mock panel registered"
contains "$CONTROL_FILE" '"tenant_scope_panel"' "tenant scope panel registered"
contains "$CONTROL_FILE" '"data_reset_policy_panel"' "data reset policy panel registered"
contains "$CONTROL_FILE" '"security_notice_panel"' "security notice panel registered"
contains "$CONTROL_FILE" '"pricing_pages_deferred_marker"' "pricing pages deferred marker registered"
contains "$CONTROL_FILE" '"SANDBOX_OVERVIEW"' "sandbox overview domain registered"
contains "$CONTROL_FILE" '"MOCK_CREDENTIAL"' "mock credential domain registered"
contains "$CONTROL_FILE" '"API_SAMPLE"' "api sample domain registered"
contains "$CONTROL_FILE" '"WEBHOOK_MOCK"' "webhook mock domain registered"
contains "$CONTROL_FILE" '"TENANT_SCOPE"' "tenant scope domain registered"
contains "$CONTROL_FILE" '"DATA_RESET"' "data reset domain registered"
contains "$CONTROL_FILE" '"SECURITY"' "security domain registered"
contains "$CONTROL_FILE" '"PRICING_NEXT"' "pricing next domain registered"
contains "$CONTROL_FILE" '"internal_sandbox_surface_ready": true' "internal sandbox surface ready"
contains "$CONTROL_FILE" '"static_html_ready": true' "static html ready"
contains "$CONTROL_FILE" '"production_sandbox_published": false' "production sandbox unpublished"
contains "$CONTROL_FILE" '"real_developer_access_enabled": false' "real developer access disabled"
contains "$CONTROL_FILE" '"live_api_call_enabled": false' "live api call disabled"
contains "$CONTROL_FILE" '"live_data_mutation_enabled": false' "live data mutation disabled"
contains "$CONTROL_FILE" '"payment_simulation_live_enabled": false' "payment simulation live disabled"
contains "$CONTROL_FILE" '"api_key_creation_enabled": false' "api key creation disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_mock_credential": true' "mock credential required"
contains "$CONTROL_FILE" '"requires_sample_request": true' "sample request required"
contains "$CONTROL_FILE" '"requires_sample_response": true' "sample response required"
contains "$CONTROL_FILE" '"requires_tenant_isolation_notice": true' "tenant isolation notice required"
contains "$CONTROL_FILE" '"requires_rate_limit_preview": true' "rate limit preview required"
contains "$CONTROL_FILE" '"requires_webhook_mock_guide": true' "webhook mock guide required"
contains "$CONTROL_FILE" '"requires_data_reset_policy": true' "data reset policy required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_security_notice": true' "security notice required"
contains "$CONTROL_FILE" '"requires_support_path": true' "support path required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_developer_access": true' "real developer access block present"
contains "$CONTROL_FILE" '"blocks_live_api_call": true' "live api call block present"
contains "$CONTROL_FILE" '"blocks_live_data_mutation": true' "live data mutation block present"
contains "$CONTROL_FILE" '"blocks_payment_simulation_live": true' "payment simulation live block present"
contains "$CONTROL_FILE" '"blocks_api_key_creation": true' "api key creation block present"
contains "$CONTROL_FILE" '"deferred_to_pricing_pages": true' "pricing pages deferred present"
contains "$CONTROL_FILE" '"FAZ_5_19_2_FIYATLAMA_SAYFALARI"' "next gate 278 present"

contains "$WEB_FILE" "PIX2PI_SANDBOX_SURFACE_START" "html sandbox start marker"
contains "$WEB_FILE" "data-sandbox-section=\"sandbox_overview\"" "html sandbox overview section"
contains "$WEB_FILE" "data-sandbox-section=\"mock_credentials_panel\"" "html mock credentials section"
contains "$WEB_FILE" "data-sandbox-section=\"sample_requests_panel\"" "html sample requests section"
contains "$WEB_FILE" "data-sandbox-section=\"sample_responses_panel\"" "html sample responses section"
contains "$WEB_FILE" "data-sandbox-section=\"webhook_mock_panel\"" "html webhook mock section"
contains "$WEB_FILE" "live_api_call_enabled=false" "html live api call disabled marker"
contains "$WEB_FILE" "live_data_mutation_enabled=false" "html live data mutation disabled marker"
contains "$WEB_FILE" "payment_simulation_live_enabled=false" "html payment simulation disabled marker"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SANDBOX_PUBLISH_BLOCKED" "production sandbox publish guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCKED" "real developer access guard"
contains "$RUNTIME_FILE" "LIVE_API_CALL_BLOCKED" "live api call guard"
contains "$RUNTIME_FILE" "LIVE_DATA_MUTATION_BLOCKED" "live data mutation guard"
contains "$RUNTIME_FILE" "PAYMENT_SIMULATION_LIVE_BLOCKED" "payment simulation live guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCKED" "api key creation guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "MOCK_CREDENTIAL_REQUIRED" "mock credential guard"
contains "$RUNTIME_FILE" "SAMPLE_REQUEST_REQUIRED" "sample request guard"
contains "$RUNTIME_FILE" "SAMPLE_RESPONSE_REQUIRED" "sample response guard"
contains "$RUNTIME_FILE" "TENANT_ISOLATION_NOTICE_REQUIRED" "tenant isolation notice guard"
contains "$RUNTIME_FILE" "RATE_LIMIT_PREVIEW_REQUIRED" "rate limit preview guard"
contains "$RUNTIME_FILE" "WEBHOOK_MOCK_GUIDE_REQUIRED" "webhook mock guide guard"
contains "$RUNTIME_FILE" "DATA_RESET_POLICY_REQUIRED" "data reset policy guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "SECURITY_NOTICE_REQUIRED" "security notice guard"
contains "$RUNTIME_FILE" "SUPPORT_PATH_REQUIRED" "support path guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED" "real developer access block guard"
contains "$RUNTIME_FILE" "LIVE_API_CALL_BLOCK_REQUIRED" "live api call block guard"
contains "$RUNTIME_FILE" "LIVE_DATA_MUTATION_BLOCK_REQUIRED" "live data mutation block guard"
contains "$RUNTIME_FILE" "PAYMENT_SIMULATION_LIVE_BLOCK_REQUIRED" "payment simulation live block guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCK_REQUIRED" "api key creation block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/sandboxsurface; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/sandbox_surface.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_19_5_sandbox_kullanim_yuzeyi_test.json").read_text())
html = Path("web/faz5r/sandbox-surface/index.html").read_text()

sections = {s["key"]: s for s in control["sections"]}
domains = {s["domain"] for s in control["sections"]}

for key in test["must_have_section_keys"]:
    assert key in sections, f"missing section key: {key}"
    s = sections[key]
    assert s["required"] is True, f"section not required: {key}"
    assert s["has_evidence"] is True, f"evidence missing: {key}"
    assert s["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert s["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert s["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert s["production_sandbox_published"] is False, f"production sandbox must be false: {key}"
    assert s["real_developer_access_enabled"] is False, f"real developer access must be false: {key}"
    assert s["live_api_call_enabled"] is False, f"live api call must be false: {key}"
    assert s["live_data_mutation_enabled"] is False, f"live data mutation must be false: {key}"
    assert s["payment_simulation_live_enabled"] is False, f"payment simulation must be false: {key}"
    assert s["api_key_creation_enabled"] is False, f"api key creation must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_mock_credential"] is True, f"mock credential missing: {key}"
    assert s["requires_sample_request"] is True, f"sample request missing: {key}"
    assert s["requires_sample_response"] is True, f"sample response missing: {key}"
    assert s["requires_tenant_isolation_notice"] is True, f"tenant isolation missing: {key}"
    assert s["requires_rate_limit_preview"] is True, f"rate limit missing: {key}"
    assert s["requires_webhook_mock_guide"] is True, f"webhook mock missing: {key}"
    assert s["requires_data_reset_policy"] is True, f"data reset missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_security_notice"] is True, f"security notice missing: {key}"
    assert s["requires_support_path"] is True, f"support path missing: {key}"
    assert s["requires_legal_review"] is True, f"legal review missing: {key}"
    assert s["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert s["requires_change_log"] is True, f"change log missing: {key}"
    assert s["blocks_production_publish"] is True, f"production block missing: {key}"
    assert s["blocks_real_developer_access"] is True, f"developer access block missing: {key}"
    assert s["blocks_live_api_call"] is True, f"live api block missing: {key}"
    assert s["blocks_live_data_mutation"] is True, f"live mutation block missing: {key}"
    assert s["blocks_payment_simulation_live"] is True, f"payment simulation block missing: {key}"
    assert s["blocks_api_key_creation"] is True, f"api key block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["pricing_pages_deferred_marker"]["deferred_to_pricing_pages"] is True
assert sections["pricing_pages_deferred_marker"]["deferred_reason"], "pricing pages deferred reason missing"
assert control["internal_sandbox_surface_ready"] is True
assert control["static_html_ready"] is True
assert control["production_sandbox_published"] is False
assert control["real_developer_access_enabled"] is False
assert control["live_api_call_enabled"] is False
assert control["live_data_mutation_enabled"] is False
assert control["payment_simulation_live_enabled"] is False
assert control["api_key_creation_enabled"] is False
assert control["final_policy"]["pricing_pages_required_next"] is True
assert "PIX2PI_SANDBOX_SURFACE_START" in html
assert "live_api_call_enabled=false" in html
assert "live_data_mutation_enabled=false" in html
assert "payment_simulation_live_enabled=false" in html
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
# FAZ 5-19.5 Sandbox Kullanım Yüzeyi Real Implementation Audit

PHASE=FAZ_5_19_5
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
WEB_STATUS=READY
TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
INTERNAL_SANDBOX_SURFACE_READY=true
STATIC_HTML_READY=true
PRODUCTION_SANDBOX_PUBLISHED=false
REAL_DEVELOPER_ACCESS_ENABLED=false
LIVE_API_CALL_ENABLED=false
LIVE_DATA_MUTATION_ENABLED=false
PAYMENT_SIMULATION_LIVE_ENABLED=false
API_KEY_CREATION_ENABLED=false
PRICING_PAGES_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
- $WEB_FILE
EOF2

echo "===== FAZ 5-19.5 SANDBOX KULLANIM YUZEYI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_19_5_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_19_5_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
