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

echo "===== FAZ 7-5 TEST BASLADI ====="

check_file "7-5" "docs/faz7/FAZ_7_5_BILLING_READINESS.md"
check_file "7-5" "docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md"
check_file "7-5" "configs/faz7/billing_readiness.v1.json"
check_file "7-5" "internal/platform/commercial/billing/billing.go"
check_file "7-5" "internal/platform/commercial/billing/billing_test.go"
check_file "7-5" "scripts/faz7/test_7_5_billing_readiness.sh"
check_file "7-5" "scripts/faz7/audit_7_5_real_implementation.sh"

check_grep "7-5.1 Billing hazirligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1 Billing Hazirligi"
check_grep "7-5.1.1 Fatura hazirlik modeli" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.1 Fatura hazirlik modeli"
check_grep "7-5.1.2 Vergi KDV uyumu" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.2 Vergi/KDV uyumu"
check_grep "7-5.1.3 Muhasebeci firma basi ucret" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.3 Muhasebeci paketi firma basi ucret modeli"
check_grep "7-5.1.4 Billing simulation" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.4 Gercek odeme saglayici oncesi billing simulation"
check_grep "7-5.1.5 Payment adapter hazirligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.1.5 Gercek odeme entegrasyonu icin adapter hazirligi"
check_grep "7-5.2 Billing decision model" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-5.2 Billing Decision Model"
check_grep "7-5.3 Code artifact" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "internal/platform/commercial/billing/billing.go"
check_grep "7-5.4 Config artifact" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "configs/faz7/billing_readiness.v1.json"
check_grep "7-5.5 7-6 hazirlik" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "7-6 Tenant Onboarding"

check_grep "7-5 code BillingProfile" "internal/platform/commercial/billing/billing.go" "type BillingProfile struct"
check_grep "7-5 code PlanPrice" "internal/platform/commercial/billing/billing.go" "type PlanPrice struct"
check_grep "7-5 code InvoiceDraft" "internal/platform/commercial/billing/billing.go" "type InvoiceDraft struct"
check_grep "7-5 code BuildInvoiceDraft" "internal/platform/commercial/billing/billing.go" "BuildInvoiceDraft"
check_grep "7-5 code CalculateVAT" "internal/platform/commercial/billing/billing.go" "CalculateVAT"
check_grep "7-5 code SimulateBilling" "internal/platform/commercial/billing/billing.go" "SimulateBilling"
check_grep "7-5 code CheckRealPaymentGate" "internal/platform/commercial/billing/billing.go" "CheckRealPaymentGate"
check_grep "7-5 code subscription integration" "internal/platform/commercial/billing/billing.go" "commercial/subscription"

echo
echo "===== 7-5 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/billing_readiness.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "billing_readiness.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-5":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

if data.get("currency") != "TRY":
    raise SystemExit("currency mismatch")

if data.get("money_unit") != "kurus":
    raise SystemExit("money unit mismatch")

if data.get("default_vat_rate_bps") != 2000:
    raise SystemExit("vat rate mismatch")

if data.get("real_payment_enabled") is not False:
    raise SystemExit("real payment must be disabled")

if data.get("billing_simulation_enabled") is not True:
    raise SystemExit("billing simulation must be enabled")

for key in [
    "requires_financial_approval_before_real_payment",
    "requires_tax_advisor_approval_before_real_billing",
    "requires_payment_provider_contract_before_real_payment",
]:
    if data.get(key) is not True:
        raise SystemExit(f"gate missing or false: {key}")

required_plans = {"starter", "pro", "enterprise", "accountant", "marketplace"}
prices = {p["plan_code"]: p for p in data.get("plan_prices", [])}
missing = required_plans - set(prices.keys())
if missing:
    raise SystemExit(f"missing prices: {sorted(missing)}")

for code, price in prices.items():
    if price.get("monthly_net_amount_kurus", 0) <= 0:
        raise SystemExit(f"price not positive for {code}")
    if price.get("currency") != "TRY":
        raise SystemExit(f"currency mismatch for {code}")

required_reasons = {
    "ALLOW_INVOICE_DRAFT_READY",
    "ALLOW_BILLING_SIMULATION_READY",
    "DENY_TENANT_REQUIRED",
    "DENY_ACCOUNT_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_BILLING_PROFILE_REQUIRED",
    "DENY_INVALID_PERIOD",
    "DENY_SUBSCRIPTION_NOT_BILLABLE",
    "DENY_REAL_PAYMENT_DISABLED",
    "DENY_FINANCIAL_APPROVAL_REQUIRED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-5 JSON config parse ve billing gate kontrolu"
else
  fail "7-5 JSON config parse ve billing gate kontrolu"
fi

echo
echo "===== 7-5 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/billing -v; then
    ok "7-5 Go billing unit testleri"
  else
    fail "7-5 Go billing unit testleri"
  fi
else
  fail "7-5 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-5 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_5_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-5 testleri basariyla gecti"
else
  echo "FAZ_7_5_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-5 testlerinde hata var"
  exit 1
fi
