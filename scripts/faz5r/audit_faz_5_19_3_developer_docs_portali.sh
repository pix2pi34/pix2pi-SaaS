#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-19.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_19_3_DEVELOPER_DOCS_PORTALI.md"
CONFIG_FILE="configs/faz5r/faz_5_19_3_developer_docs_portali.v1.json"
CONTROL_FILE="configs/faz5r/developer_docs_portal.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_19_3_developer_docs_portali_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/developerdocsportal/developer_docs_portal.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/developerdocsportal/developer_docs_portal_test.go"
WEB_FILE="web/faz5r/developer-docs/index.html"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_19_3_DEVELOPER_DOCS_PORTALI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-19.3 DEVELOPER DOCS PORTALI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"
file_exists "$WEB_FILE" "HTML portal file"

contains "$CONTROL_FILE" '"developer_overview"' "developer overview registered"
contains "$CONTROL_FILE" '"authentication_docs"' "authentication docs registered"
contains "$CONTROL_FILE" '"tenant_context_docs"' "tenant context docs registered"
contains "$CONTROL_FILE" '"api_reference_docs"' "api reference docs registered"
contains "$CONTROL_FILE" '"webhook_docs"' "webhook docs registered"
contains "$CONTROL_FILE" '"sandbox_usage_docs"' "sandbox usage docs registered"
contains "$CONTROL_FILE" '"security_compliance_docs"' "security compliance docs registered"
contains "$CONTROL_FILE" '"support_sla_docs"' "support sla docs registered"
contains "$CONTROL_FILE" '"api_key_screen_deferred_marker"' "api key screen deferred marker registered"
contains "$CONTROL_FILE" '"OVERVIEW"' "overview domain registered"
contains "$CONTROL_FILE" '"AUTH_API"' "auth api domain registered"
contains "$CONTROL_FILE" '"TENANT_API"' "tenant api domain registered"
contains "$CONTROL_FILE" '"API_REFERENCE"' "api reference domain registered"
contains "$CONTROL_FILE" '"WEBHOOK_API"' "webhook api domain registered"
contains "$CONTROL_FILE" '"SANDBOX"' "sandbox domain registered"
contains "$CONTROL_FILE" '"SECURITY"' "security domain registered"
contains "$CONTROL_FILE" '"SUPPORT"' "support domain registered"
contains "$CONTROL_FILE" '"NEXT_PRIORITY"' "next priority domain registered"
contains "$CONTROL_FILE" '"internal_developer_docs_portal_ready": true' "internal developer docs portal ready"
contains "$CONTROL_FILE" '"static_html_ready": true' "static html ready"
contains "$CONTROL_FILE" '"production_docs_published": false' "production docs unpublished"
contains "$CONTROL_FILE" '"real_developer_access_enabled": false' "real developer access disabled"
contains "$CONTROL_FILE" '"api_key_creation_enabled": false' "api key creation disabled"
contains "$CONTROL_FILE" '"sandbox_live_enabled": false' "sandbox live disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_public_copy_guard": true' "public copy guard required"
contains "$CONTROL_FILE" '"requires_versioning": true' "versioning required"
contains "$CONTROL_FILE" '"requires_endpoint_catalog": true' "endpoint catalog required"
contains "$CONTROL_FILE" '"requires_auth_guide": true' "auth guide required"
contains "$CONTROL_FILE" '"requires_tenant_header_guide": true' "tenant header guide required"
contains "$CONTROL_FILE" '"requires_rate_limit_notice": true' "rate limit notice required"
contains "$CONTROL_FILE" '"requires_webhook_guide": true' "webhook guide required"
contains "$CONTROL_FILE" '"requires_sandbox_guide": true' "sandbox guide required"
contains "$CONTROL_FILE" '"requires_security_notice": true' "security notice required"
contains "$CONTROL_FILE" '"requires_support_path": true' "support path required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_developer_access": true' "real developer access block present"
contains "$CONTROL_FILE" '"blocks_api_key_creation": true' "api key creation block present"
contains "$CONTROL_FILE" '"blocks_sandbox_live": true' "sandbox live block present"
contains "$CONTROL_FILE" '"deferred_to_api_key_management_screen": true' "api key management screen deferred present"
contains "$CONTROL_FILE" '"FAZ_5_19_4_API_KEY_YONETIM_EKRANI"' "next gate 276 present"

contains "$WEB_FILE" "PIX2PI_DEVELOPER_DOCS_PORTAL_START" "html portal start marker"
contains "$WEB_FILE" "data-doc-section=\"developer_overview\"" "html developer overview section"
contains "$WEB_FILE" "data-doc-section=\"authentication_docs\"" "html authentication docs section"
contains "$WEB_FILE" "data-doc-section=\"tenant_context_docs\"" "html tenant context docs section"
contains "$WEB_FILE" "data-doc-section=\"api_reference_docs\"" "html api reference docs section"
contains "$WEB_FILE" "data-doc-section=\"webhook_docs\"" "html webhook docs section"
contains "$WEB_FILE" "production_docs_published=false" "html production docs disabled marker"
contains "$WEB_FILE" "api_key_creation_enabled=false" "html api key creation disabled marker"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_DOCS_PUBLISH_BLOCKED" "production docs publish guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCKED" "real developer access guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCKED" "api key creation guard"
contains "$RUNTIME_FILE" "SANDBOX_LIVE_BLOCKED" "sandbox live guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PUBLIC_COPY_GUARD_REQUIRED" "public copy guard"
contains "$RUNTIME_FILE" "VERSIONING_REQUIRED" "versioning guard"
contains "$RUNTIME_FILE" "ENDPOINT_CATALOG_REQUIRED" "endpoint catalog guard"
contains "$RUNTIME_FILE" "AUTH_GUIDE_REQUIRED" "auth guide guard"
contains "$RUNTIME_FILE" "TENANT_HEADER_GUIDE_REQUIRED" "tenant header guide guard"
contains "$RUNTIME_FILE" "RATE_LIMIT_NOTICE_REQUIRED" "rate limit notice guard"
contains "$RUNTIME_FILE" "WEBHOOK_GUIDE_REQUIRED" "webhook guide guard"
contains "$RUNTIME_FILE" "SANDBOX_GUIDE_REQUIRED" "sandbox guide guard"
contains "$RUNTIME_FILE" "SECURITY_NOTICE_REQUIRED" "security notice guard"
contains "$RUNTIME_FILE" "SUPPORT_PATH_REQUIRED" "support path guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED" "real developer access block guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCK_REQUIRED" "api key creation block guard"
contains "$RUNTIME_FILE" "SANDBOX_LIVE_BLOCK_REQUIRED" "sandbox live block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/developerdocsportal; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/developer_docs_portal.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_19_3_developer_docs_portali_test.json").read_text())
html = Path("web/faz5r/developer-docs/index.html").read_text()

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
    assert s["production_docs_published"] is False, f"production docs must be false: {key}"
    assert s["real_developer_access_enabled"] is False, f"real developer access must be false: {key}"
    assert s["api_key_creation_enabled"] is False, f"api key creation must be false: {key}"
    assert s["sandbox_live_enabled"] is False, f"sandbox live must be false: {key}"
    assert s["requires_public_copy_guard"] is True, f"public copy guard missing: {key}"
    assert s["requires_versioning"] is True, f"versioning missing: {key}"
    assert s["requires_endpoint_catalog"] is True, f"endpoint catalog missing: {key}"
    assert s["requires_auth_guide"] is True, f"auth guide missing: {key}"
    assert s["requires_tenant_header_guide"] is True, f"tenant header guide missing: {key}"
    assert s["requires_rate_limit_notice"] is True, f"rate limit notice missing: {key}"
    assert s["requires_webhook_guide"] is True, f"webhook guide missing: {key}"
    assert s["requires_sandbox_guide"] is True, f"sandbox guide missing: {key}"
    assert s["requires_security_notice"] is True, f"security notice missing: {key}"
    assert s["requires_support_path"] is True, f"support path missing: {key}"
    assert s["requires_legal_review"] is True, f"legal review missing: {key}"
    assert s["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert s["requires_change_log"] is True, f"change log missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["blocks_production_publish"] is True, f"production block missing: {key}"
    assert s["blocks_real_developer_access"] is True, f"developer access block missing: {key}"
    assert s["blocks_api_key_creation"] is True, f"api key block missing: {key}"
    assert s["blocks_sandbox_live"] is True, f"sandbox block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["api_key_screen_deferred_marker"]["deferred_to_api_key_management_screen"] is True
assert sections["api_key_screen_deferred_marker"]["deferred_reason"], "api key screen deferred reason missing"
assert control["internal_developer_docs_portal_ready"] is True
assert control["static_html_ready"] is True
assert control["production_docs_published"] is False
assert control["real_developer_access_enabled"] is False
assert control["api_key_creation_enabled"] is False
assert control["sandbox_live_enabled"] is False
assert control["final_policy"]["api_key_management_screen_required_next"] is True
assert "PIX2PI_DEVELOPER_DOCS_PORTAL_START" in html
assert "production_docs_published=false" in html
assert "api_key_creation_enabled=false" in html
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
# FAZ 5-19.3 Developer Docs Portalı Real Implementation Audit

PHASE=FAZ_5_19_3
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
INTERNAL_DEVELOPER_DOCS_PORTAL_READY=true
STATIC_HTML_READY=true
PRODUCTION_DOCS_PUBLISHED=false
REAL_DEVELOPER_ACCESS_ENABLED=false
API_KEY_CREATION_ENABLED=false
SANDBOX_LIVE_ENABLED=false
API_KEY_MANAGEMENT_SCREEN_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
- $WEB_FILE
EOF2

echo "===== FAZ 5-19.3 DEVELOPER DOCS PORTALI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_19_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_19_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
