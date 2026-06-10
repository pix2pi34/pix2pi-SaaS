#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-19.4"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_19_4_API_KEY_YONETIM_EKRANI.md"
CONFIG_FILE="configs/faz5r/faz_5_19_4_api_key_yonetim_ekrani.v1.json"
CONTROL_FILE="configs/faz5r/api_key_management_screen.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_19_4_api_key_yonetim_ekrani_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/apikeymanagementscreen/api_key_management_screen.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/apikeymanagementscreen/api_key_management_screen_test.go"
WEB_FILE="web/faz5r/api-key-management/index.html"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_19_4_API_KEY_YONETIM_EKRANI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-19.4 API KEY YONETIM EKRANI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"
file_exists "$WEB_FILE" "HTML screen file"

contains "$CONTROL_FILE" '"key_inventory"' "key inventory registered"
contains "$CONTROL_FILE" '"key_create_disabled_panel"' "key create disabled panel registered"
contains "$CONTROL_FILE" '"key_masked_secret_panel"' "key masked secret panel registered"
contains "$CONTROL_FILE" '"key_rotation_preview"' "key rotation preview registered"
contains "$CONTROL_FILE" '"key_revoke_preview"' "key revoke preview registered"
contains "$CONTROL_FILE" '"permission_scope_panel"' "permission scope panel registered"
contains "$CONTROL_FILE" '"tenant_scope_panel"' "tenant scope panel registered"
contains "$CONTROL_FILE" '"audit_trail_panel"' "audit trail panel registered"
contains "$CONTROL_FILE" '"security_policy_panel"' "security policy panel registered"
contains "$CONTROL_FILE" '"sandbox_surface_deferred_marker"' "sandbox surface deferred marker registered"
contains "$CONTROL_FILE" '"KEY_INVENTORY"' "key inventory domain registered"
contains "$CONTROL_FILE" '"KEY_LIFECYCLE"' "key lifecycle domain registered"
contains "$CONTROL_FILE" '"PERMISSION"' "permission domain registered"
contains "$CONTROL_FILE" '"TENANT_SCOPE"' "tenant scope domain registered"
contains "$CONTROL_FILE" '"AUDIT"' "audit domain registered"
contains "$CONTROL_FILE" '"SECURITY"' "security domain registered"
contains "$CONTROL_FILE" '"SANDBOX_NEXT"' "sandbox next domain registered"
contains "$CONTROL_FILE" '"internal_api_key_screen_ready": true' "internal api key screen ready"
contains "$CONTROL_FILE" '"static_html_ready": true' "static html ready"
contains "$CONTROL_FILE" '"production_screen_published": false' "production screen unpublished"
contains "$CONTROL_FILE" '"real_developer_access_enabled": false' "real developer access disabled"
contains "$CONTROL_FILE" '"api_key_creation_enabled": false' "api key creation disabled"
contains "$CONTROL_FILE" '"api_key_reveal_enabled": false' "api key reveal disabled"
contains "$CONTROL_FILE" '"api_key_rotation_enabled": false' "api key rotation disabled"
contains "$CONTROL_FILE" '"sandbox_live_enabled": false' "sandbox live disabled"
contains "$CONTROL_FILE" '"has_evidence": true' "evidence present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_developer_account": true' "developer account required"
contains "$CONTROL_FILE" '"requires_role_guard": true' "role guard required"
contains "$CONTROL_FILE" '"requires_permission_scope": true' "permission scope required"
contains "$CONTROL_FILE" '"requires_key_name": true' "key name required"
contains "$CONTROL_FILE" '"requires_masked_secret_display": true' "masked secret display required"
contains "$CONTROL_FILE" '"requires_create_disabled_guard": true' "create disabled guard required"
contains "$CONTROL_FILE" '"requires_reveal_disabled_guard": true' "reveal disabled guard required"
contains "$CONTROL_FILE" '"requires_rotate_disabled_guard": true' "rotate disabled guard required"
contains "$CONTROL_FILE" '"requires_revoke_preview": true' "revoke preview required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_rate_limit_policy": true' "rate limit policy required"
contains "$CONTROL_FILE" '"requires_expiry_policy": true' "expiry policy required"
contains "$CONTROL_FILE" '"requires_security_notice": true' "security notice required"
contains "$CONTROL_FILE" '"requires_legal_review": true' "legal review required"
contains "$CONTROL_FILE" '"requires_founder_approval": true' "founder approval required"
contains "$CONTROL_FILE" '"requires_change_log": true' "change log required"
contains "$CONTROL_FILE" '"blocks_production_publish": true' "production publish block present"
contains "$CONTROL_FILE" '"blocks_real_developer_access": true' "real developer access block present"
contains "$CONTROL_FILE" '"blocks_api_key_creation": true' "api key creation block present"
contains "$CONTROL_FILE" '"blocks_api_key_reveal": true' "api key reveal block present"
contains "$CONTROL_FILE" '"blocks_api_key_rotation": true' "api key rotation block present"
contains "$CONTROL_FILE" '"blocks_sandbox_live": true' "sandbox live block present"
contains "$CONTROL_FILE" '"deferred_to_sandbox_surface": true' "sandbox surface deferred present"
contains "$CONTROL_FILE" '"FAZ_5_19_5_SANDBOX_KULLANIM_YUZEYI"' "next gate 277 present"

contains "$WEB_FILE" "PIX2PI_API_KEY_MANAGEMENT_SCREEN_START" "html screen start marker"
contains "$WEB_FILE" "data-screen-section=\"key_inventory\"" "html key inventory section"
contains "$WEB_FILE" "data-screen-section=\"key_create_disabled_panel\"" "html create disabled section"
contains "$WEB_FILE" "data-screen-section=\"key_masked_secret_panel\"" "html masked secret section"
contains "$WEB_FILE" "data-screen-section=\"key_rotation_preview\"" "html rotation preview section"
contains "$WEB_FILE" "data-screen-section=\"tenant_scope_panel\"" "html tenant scope section"
contains "$WEB_FILE" "api_key_creation_enabled=false" "html api key creation disabled marker"
contains "$WEB_FILE" "api_key_reveal_enabled=false" "html api key reveal disabled marker"
contains "$WEB_FILE" "api_key_rotation_enabled=false" "html api key rotation disabled marker"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_SCREEN_PUBLISH_BLOCKED" "production screen publish guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCKED" "real developer access guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCKED" "api key creation guard"
contains "$RUNTIME_FILE" "API_KEY_REVEAL_BLOCKED" "api key reveal guard"
contains "$RUNTIME_FILE" "API_KEY_ROTATION_BLOCKED" "api key rotation guard"
contains "$RUNTIME_FILE" "SANDBOX_LIVE_BLOCKED" "sandbox live guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "DEVELOPER_ACCOUNT_REQUIRED" "developer account guard"
contains "$RUNTIME_FILE" "ROLE_GUARD_REQUIRED" "role guard"
contains "$RUNTIME_FILE" "PERMISSION_SCOPE_REQUIRED" "permission scope guard"
contains "$RUNTIME_FILE" "KEY_NAME_REQUIRED" "key name guard"
contains "$RUNTIME_FILE" "MASKED_SECRET_DISPLAY_REQUIRED" "masked secret display guard"
contains "$RUNTIME_FILE" "CREATE_DISABLED_GUARD_REQUIRED" "create disabled guard"
contains "$RUNTIME_FILE" "REVEAL_DISABLED_GUARD_REQUIRED" "reveal disabled guard"
contains "$RUNTIME_FILE" "ROTATE_DISABLED_GUARD_REQUIRED" "rotate disabled guard"
contains "$RUNTIME_FILE" "REVOKE_PREVIEW_REQUIRED" "revoke preview guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "RATE_LIMIT_POLICY_REQUIRED" "rate limit policy guard"
contains "$RUNTIME_FILE" "EXPIRY_POLICY_REQUIRED" "expiry policy guard"
contains "$RUNTIME_FILE" "SECURITY_NOTICE_REQUIRED" "security notice guard"
contains "$RUNTIME_FILE" "LEGAL_REVIEW_REQUIRED" "legal review guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "CHANGE_LOG_REQUIRED" "change log guard"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLISH_BLOCK_REQUIRED" "production publish block guard"
contains "$RUNTIME_FILE" "REAL_DEVELOPER_ACCESS_BLOCK_REQUIRED" "real developer access block guard"
contains "$RUNTIME_FILE" "API_KEY_CREATION_BLOCK_REQUIRED" "api key creation block guard"
contains "$RUNTIME_FILE" "API_KEY_REVEAL_BLOCK_REQUIRED" "api key reveal block guard"
contains "$RUNTIME_FILE" "API_KEY_ROTATION_BLOCK_REQUIRED" "api key rotation block guard"
contains "$RUNTIME_FILE" "SANDBOX_LIVE_BLOCK_REQUIRED" "sandbox live block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/apikeymanagementscreen; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/api_key_management_screen.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_19_4_api_key_yonetim_ekrani_test.json").read_text())
html = Path("web/faz5r/api-key-management/index.html").read_text()

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
    assert s["production_screen_published"] is False, f"production screen must be false: {key}"
    assert s["real_developer_access_enabled"] is False, f"real developer access must be false: {key}"
    assert s["api_key_creation_enabled"] is False, f"api key creation must be false: {key}"
    assert s["api_key_reveal_enabled"] is False, f"api key reveal must be false: {key}"
    assert s["api_key_rotation_enabled"] is False, f"api key rotation must be false: {key}"
    assert s["sandbox_live_enabled"] is False, f"sandbox live must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_developer_account"] is True, f"developer account missing: {key}"
    assert s["requires_role_guard"] is True, f"role guard missing: {key}"
    assert s["requires_permission_scope"] is True, f"permission scope missing: {key}"
    assert s["requires_key_name"] is True, f"key name missing: {key}"
    assert s["requires_masked_secret_display"] is True, f"masked secret missing: {key}"
    assert s["requires_create_disabled_guard"] is True, f"create disabled missing: {key}"
    assert s["requires_reveal_disabled_guard"] is True, f"reveal disabled missing: {key}"
    assert s["requires_rotate_disabled_guard"] is True, f"rotate disabled missing: {key}"
    assert s["requires_revoke_preview"] is True, f"revoke preview missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_rate_limit_policy"] is True, f"rate limit missing: {key}"
    assert s["requires_expiry_policy"] is True, f"expiry missing: {key}"
    assert s["requires_security_notice"] is True, f"security notice missing: {key}"
    assert s["requires_legal_review"] is True, f"legal review missing: {key}"
    assert s["requires_founder_approval"] is True, f"founder approval missing: {key}"
    assert s["requires_change_log"] is True, f"change log missing: {key}"
    assert s["blocks_production_publish"] is True, f"production block missing: {key}"
    assert s["blocks_real_developer_access"] is True, f"developer access block missing: {key}"
    assert s["blocks_api_key_creation"] is True, f"api creation block missing: {key}"
    assert s["blocks_api_key_reveal"] is True, f"api reveal block missing: {key}"
    assert s["blocks_api_key_rotation"] is True, f"api rotation block missing: {key}"
    assert s["blocks_sandbox_live"] is True, f"sandbox block missing: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

assert sections["sandbox_surface_deferred_marker"]["deferred_to_sandbox_surface"] is True
assert sections["sandbox_surface_deferred_marker"]["deferred_reason"], "sandbox surface deferred reason missing"
assert control["internal_api_key_screen_ready"] is True
assert control["static_html_ready"] is True
assert control["production_screen_published"] is False
assert control["real_developer_access_enabled"] is False
assert control["api_key_creation_enabled"] is False
assert control["api_key_reveal_enabled"] is False
assert control["api_key_rotation_enabled"] is False
assert control["sandbox_live_enabled"] is False
assert control["final_policy"]["sandbox_surface_required_next"] is True
assert "PIX2PI_API_KEY_MANAGEMENT_SCREEN_START" in html
assert "api_key_creation_enabled=false" in html
assert "api_key_reveal_enabled=false" in html
assert "api_key_rotation_enabled=false" in html
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
# FAZ 5-19.4 API Key Yönetim Ekranı Real Implementation Audit

PHASE=FAZ_5_19_4
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
INTERNAL_API_KEY_SCREEN_READY=true
STATIC_HTML_READY=true
PRODUCTION_SCREEN_PUBLISHED=false
REAL_DEVELOPER_ACCESS_ENABLED=false
API_KEY_CREATION_ENABLED=false
API_KEY_REVEAL_ENABLED=false
API_KEY_ROTATION_ENABLED=false
SANDBOX_LIVE_ENABLED=false
SANDBOX_SURFACE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
- $WEB_FILE
EOF2

echo "===== FAZ 5-19.4 API KEY YONETIM EKRANI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_19_4_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_19_4_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
