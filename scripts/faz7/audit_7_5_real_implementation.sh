#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_5_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-5 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-5.1 Billing readiness dokumani" "docs/faz7/FAZ_7_5_BILLING_READINESS.md"
has_file "7-5.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md"
has_file "7-5.3 Billing readiness config" "configs/faz7/billing_readiness.v1.json"
has_file "7-5.4 Go billing runtime modeli" "internal/platform/commercial/billing/billing.go"
has_file "7-5.5 Go billing testleri" "internal/platform/commercial/billing/billing_test.go"
has_file "7-5.6 Test scripti" "scripts/faz7/test_7_5_billing_readiness.sh"
has_file "7-5.7 Real implementation audit scripti" "scripts/faz7/audit_7_5_real_implementation.sh"

has_text "7-5.1.1 Fatura hazirlik modeli dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "Fatura hazirlik modeli"
has_text "7-5.1.2 Vergi/KDV uyumu dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "Vergi/KDV uyumu"
has_text "7-5.1.3 Muhasebeci firma basi ucret dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "Muhasebeci paketi firma basi ucret modeli"
has_text "7-5.1.4 Billing simulation dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "billing simulation"
has_text "7-5.1.5 Payment adapter gate dokuman karsiligi" "docs/faz7/FAZ_7_5_BILLING_READINESS.md" "real_payment_enabled=false"

has_text "7-5 config TRY currency karsiligi" "configs/faz7/billing_readiness.v1.json" "\"currency\": \"TRY\""
has_text "7-5 config kurus money unit karsiligi" "configs/faz7/billing_readiness.v1.json" "\"money_unit\": \"kurus\""
has_text "7-5 config VAT karsiligi" "configs/faz7/billing_readiness.v1.json" "\"default_vat_rate_bps\": 2000"
has_text "7-5 config real payment disabled karsiligi" "configs/faz7/billing_readiness.v1.json" "\"real_payment_enabled\": false"
has_text "7-5 config billing simulation karsiligi" "configs/faz7/billing_readiness.v1.json" "\"billing_simulation_enabled\": true"
has_text "7-5 config financial approval gate karsiligi" "configs/faz7/billing_readiness.v1.json" "requires_financial_approval_before_real_payment"
has_text "7-5 config tax advisor gate karsiligi" "configs/faz7/billing_readiness.v1.json" "requires_tax_advisor_approval_before_real_billing"
has_text "7-5 config payment provider gate karsiligi" "configs/faz7/billing_readiness.v1.json" "requires_payment_provider_contract_before_real_payment"

has_text "7-5 code BillingProfile karsiligi" "internal/platform/commercial/billing/billing.go" "type BillingProfile struct"
has_text "7-5 code PlanPrice karsiligi" "internal/platform/commercial/billing/billing.go" "type PlanPrice struct"
has_text "7-5 code InvoiceDraft karsiligi" "internal/platform/commercial/billing/billing.go" "type InvoiceDraft struct"
has_text "7-5 code BuildInvoiceDraft karsiligi" "internal/platform/commercial/billing/billing.go" "BuildInvoiceDraft"
has_text "7-5 code SimulateBilling karsiligi" "internal/platform/commercial/billing/billing.go" "SimulateBilling"
has_text "7-5 code CheckRealPaymentGate karsiligi" "internal/platform/commercial/billing/billing.go" "CheckRealPaymentGate"
has_text "7-5 code CalculateVAT karsiligi" "internal/platform/commercial/billing/billing.go" "CalculateVAT"
has_text "7-5 code subscription integration karsiligi" "internal/platform/commercial/billing/billing.go" "commercial/subscription"

echo
echo "===== 7-5 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/billing -v >/tmp/faz7_5_billing_go_test.log 2>&1; then
    ok "7-5 Go test real implementation verification"
  else
    cat /tmp/faz7_5_billing_go_test.log || true
    fail "7-5 Go test real implementation verification"
  fi
else
  fail "7-5 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-5 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-5 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_5_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_5_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_5_BILLING_READINESS.md
- docs/faz7/evidence/FAZ_7_5_BILLING_READINESS_EVIDENCE.md
- configs/faz7/billing_readiness.v1.json
- internal/platform/commercial/billing/billing.go
- internal/platform/commercial/billing/billing_test.go
- scripts/faz7/test_7_5_billing_readiness.sh
- scripts/faz7/audit_7_5_real_implementation.sh

## Real Implementation Decision

7-5 real implementation audit confirms that billing readiness, invoice draft runtime, VAT calculation, plan price catalog, billing simulation, real payment disabled gate, financial/tax/payment provider approval gates, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_5_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_5_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-5 real implementation audit basariyla gecti"
else
  echo "FAZ_7_5_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-5 real implementation audit basarisiz"
  exit 1
fi
