#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 HATA ❌"
}

check_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label file mevcut: $path"
  else
    fail "$label file eksik: $path"
  fi
}

check_grep() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label bulundu"
  else
    fail "$label bulunamadi"
  fi
}

echo "===== FAZ 7-6 TEST BASLADI ====="

check_file "7-6" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md"
check_file "7-6" "docs/faz7/evidence/FAZ_7_6_TENANT_ONBOARDING_EVIDENCE.md"
check_file "7-6" "configs/faz7/tenant_onboarding.v1.json"
check_file "7-6" "internal/platform/commercial/onboarding/onboarding.go"
check_file "7-6" "internal/platform/commercial/onboarding/onboarding_test.go"
check_file "7-6" "scripts/faz7/test_7_6_tenant_onboarding_self_service_readiness.sh"
check_file "7-6" "scripts/faz7/audit_7_6_real_implementation.sh"

check_grep "7-6.1 Onboarding akisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1 Onboarding Akisi"
check_grep "7-6.1.1 Yeni isletme kayit akisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.1 Yeni isletme kayit akisi"
check_grep "7-6.1.2 Tenant olusturma" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.2 Tenant olusturma"
check_grep "7-6.1.3 Ilk admin kullanici" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.3 Ilk admin kullanici"
check_grep "7-6.1.4 Demo veri bos baslangic secimi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.4 Demo veri / bos baslangic secimi"
check_grep "7-6.1.5 Onboarding audit izi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.1.5 Onboarding audit izi"
check_grep "7-6.2 Subscription baglantisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.2 Subscription Baglantisi"
check_grep "7-6.3 Billing profile baglantisi" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-6.3 Billing Profile Baglantisi"
check_grep "7-6.4 Code artifact" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "internal/platform/commercial/onboarding/onboarding.go"
check_grep "7-6.5 Config artifact" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "configs/faz7/tenant_onboarding.v1.json"
check_grep "7-6.6 7-7 hazirlik" "docs/faz7/FAZ_7_6_TENANT_ONBOARDING_SELF_SERVICE_READINESS.md" "7-7 Public Website"

check_grep "7-6 code Request" "internal/platform/commercial/onboarding/onboarding.go" "type Request struct"
check_grep "7-6 code TenantRecord" "internal/platform/commercial/onboarding/onboarding.go" "type TenantRecord struct"
check_grep "7-6 code AdminUserRecord" "internal/platform/commercial/onboarding/onboarding.go" "type AdminUserRecord struct"
check_grep "7-6 code Result" "internal/platform/commercial/onboarding/onboarding.go" "type Result struct"
check_grep "7-6 code Runtime" "internal/platform/commercial/onboarding/onboarding.go" "type Runtime struct"
check_grep "7-6 code StartTrialOnboarding" "internal/platform/commercial/onboarding/onboarding.go" "StartTrialOnboarding"
check_grep "7-6 code CompleteOnboarding" "internal/platform/commercial/onboarding/onboarding.go" "CompleteOnboarding"
check_grep "7-6 code subscription integration" "internal/platform/commercial/onboarding/onboarding.go" "commercial/subscription"
check_grep "7-6 code billing integration" "internal/platform/commercial/onboarding/onboarding.go" "commercial/billing"

echo
echo "===== 7-6 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/tenant_onboarding.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "tenant_onboarding.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-6":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

required_fields = {
    "tenant_id",
    "account_id",
    "business_name",
    "legal_name",
    "tax_number",
    "tax_office",
    "billing_email",
    "billing_address",
    "admin_user_id",
    "admin_email",
    "plan_code",
    "start_mode",
}
fields = set(data.get("required_onboarding_fields", []))
missing_fields = required_fields - fields
if missing_fields:
    raise SystemExit(f"missing required fields: {sorted(missing_fields)}")

required_modes = {"demo_data", "blank"}
modes = set(data.get("start_modes", []))
missing_modes = required_modes - modes
if missing_modes:
    raise SystemExit(f"missing start modes: {sorted(missing_modes)}")

trial = data.get("trial", {})
if trial.get("trial_enabled") is not True:
    raise SystemExit("trial must be enabled")
if trial.get("default_trial_days") != 14:
    raise SystemExit("default trial days mismatch")
if trial.get("real_payment_enabled") is not False:
    raise SystemExit("real payment must be disabled")
if trial.get("billing_simulation_enabled") is not True:
    raise SystemExit("billing simulation must be enabled")

required_reasons = {
    "ALLOW_ONBOARDING_READY",
    "DENY_TENANT_REQUIRED",
    "DENY_ACCOUNT_REQUIRED",
    "DENY_BUSINESS_REQUIRED",
    "DENY_LEGAL_REQUIRED",
    "DENY_TAX_PROFILE_REQUIRED",
    "DENY_BILLING_PROFILE_REQUIRED",
    "DENY_ADMIN_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_START_MODE_INVALID",
    "DENY_SUBSCRIPTION_FAILED",
    "DENY_BILLING_FAILED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-6 JSON config parse ve onboarding gate kontrolu"
else
  fail "7-6 JSON config parse ve onboarding gate kontrolu"
fi

echo
echo "===== 7-6 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/onboarding -v; then
    ok "7-6 Go onboarding unit testleri"
  else
    fail "7-6 Go onboarding unit testleri"
  fi
else
  fail "7-6 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-6 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_6_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-6 testleri basariyla gecti"
else
  echo "FAZ_7_6_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-6 testlerinde hata var"
  exit 1
fi
