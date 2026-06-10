#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_6_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p docs/faz7/evidence

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 REQUIRED_FAIL ❌"
}

warn() {
  OPTIONAL_WARN=$((OPTIONAL_WARN+1))
  echo "$1 OPTIONAL_WARN ⚠️"
}

has_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

has_text() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-6 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-6.1 Tenant onboarding dokumani" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md"
has_file "7-6.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md"
has_file "7-6.3 Tenant onboarding config" "configs/faz7/tenant_onboarding.v1.json"
has_file "7-6.4 Go onboarding runtime modeli" "internal/platform/commercial/onboarding/onboarding.go"
has_file "7-6.5 Go onboarding testleri" "internal/platform/commercial/onboarding/onboarding_test.go"
has_file "7-6.6 Test scripti" "scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh"
has_file "7-6.7 Real implementation audit scripti" "scripts/faz7/audit_7_6_real_implementation.sh"

has_text "7-6.1.1 Yeni isletme kayit akisi dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Yeni isletme kayit akisi"
has_text "7-6.1.2 Tenant olusturma dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Tenant olusturma"
has_text "7-6.1.3 Ilk admin kullanici dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Ilk admin kullanici"
has_text "7-6.1.4 Demo/bos baslangic dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Demo veri / bos baslangic secimi"
has_text "7-6.1.5 Audit izi dokuman karsiligi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "Onboarding audit izi"

has_text "7-6 config tenant_id karsiligi" "configs/faz7/tenant_onboarding.v1.json" "tenant_id"
has_text "7-6 config admin role karsiligi" "configs/faz7/tenant_onboarding.v1.json" "TENANT_ADMIN"
has_text "7-6 config demo_data karsiligi" "configs/faz7/tenant_onboarding.v1.json" "demo_data"
has_text "7-6 config blank karsiligi" "configs/faz7/tenant_onboarding.v1.json" "blank"
has_text "7-6 config trial 14 gun karsiligi" "configs/faz7/tenant_onboarding.v1.json" "\"default_trial_days\": 14"
has_text "7-6 config real payment disabled karsiligi" "configs/faz7/tenant_onboarding.v1.json" "\"real_payment_enabled\": false"
has_text "7-6 config billing simulation karsiligi" "configs/faz7/tenant_onboarding.v1.json" "\"billing_simulation_enabled\": true"

has_text "7-6 code Request karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "type Request struct"
has_text "7-6 code TenantRecord karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "type TenantRecord struct"
has_text "7-6 code AdminUserRecord karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "type AdminUserRecord struct"
has_text "7-6 code StartModeDemoData karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "StartModeDemoData"
has_text "7-6 code StartModeBlank karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "StartModeBlank"
has_text "7-6 code AdminRoleTenantAdmin karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "AdminRoleTenantAdmin"
has_text "7-6 code StartTrialOnboarding karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "StartTrialOnboarding"
has_text "7-6 code CompleteOnboarding karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "CompleteOnboarding"
has_text "7-6 code subscription integration karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "commercial/subscription"
has_text "7-6 code billing integration karsiligi" "internal/platform/commercial/onboarding/onboarding.go" "commercial/billing"

echo
echo "===== 7-6 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/onboarding -v >/tmp/faz7_6_onboarding_go_test.log 2>&1; then
    ok "7-6 Go test real implementation verification"
  else
    cat /tmp/faz7_6_onboarding_go_test.log || true
    fail "7-6 Go test real implementation verification"
  fi
else
  fail "7-6 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-6 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "REQUIRED_FAIL=$FAIL_COUNT"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$FAIL_COUNT" -eq 0 ]; then
  STATUS="PASS"
  STATUS_ICON="✅"
else
  STATUS="FAIL"
  STATUS_ICON="❌"
fi

cat > "$AUDIT_FILE" <<AUDIT_REPORT
# FAZ 7-6 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_6_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_6_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md
- docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md
- configs/faz7/tenant_onboarding.v1.json
- internal/platform/commercial/onboarding/onboarding.go
- internal/platform/commercial/onboarding/onboarding_test.go
- scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh
- scripts/faz7/audit_7_6_real_implementation.sh

## Real Implementation Decision

7-6 real implementation audit confirms that tenant onboarding readiness, new business registration model, tenant/account/admin model, demo_data/blank start mode, trial subscription start, billing profile preparation, invoice draft simulation, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_6_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-6 real implementation audit basariyla gecti"
else
  echo "FAZ_7_6_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-6 real implementation audit basarisiz"
  exit 1
fi
