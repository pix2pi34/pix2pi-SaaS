#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_2_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-2 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-2.1 Product packaging dokumani" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md"
has_file "7-2.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md"
has_file "7-2.3 Plan catalog config" "configs/faz7/product_plan_catalog.v1.json"
has_file "7-2.4 Go catalog modeli" "internal/platform/commercial/catalog/catalog.go"
has_file "7-2.5 Go catalog testleri" "internal/platform/commercial/catalog/catalog_test.go"
has_file "7-2.6 Test scripti" "scripts/faz7/test_7_2_product_packaging_plan_catalog.sh"
has_file "7-2.7 Real implementation audit scripti" "scripts/faz7/audit_7_2_real_implementation.sh"

has_text "7-2.1.1 Starter paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Starter Paket"
has_text "7-2.1.2 Pro paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Pro Paket"
has_text "7-2.1.3 Enterprise paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Enterprise Paket"
has_text "7-2.1.4 Muhasebeci paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Muhasebeci Paket"
has_text "7-2.1.5 Marketplace paket dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Marketplace / Entegrasyon Paketi"

has_text "7-2.2.1 Feature matrix dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Feature Matrix"
has_text "7-2.2.2 Kullanici limit dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Kullanici Limiti"
has_text "7-2.2.3 Tenant limit dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Tenant Limiti"
has_text "7-2.2.4 API hakki dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "API Hakki"
has_text "7-2.2.5 Export hakki dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Export Hakki"
has_text "7-2.2.6 Muhasebeci erisim dokuman karsiligi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "Muhasebeci Erisim Hakki"

has_text "7-2 config starter karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"starter\""
has_text "7-2 config pro karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"pro\""
has_text "7-2 config enterprise karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"enterprise\""
has_text "7-2 config accountant karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"accountant\""
has_text "7-2 config marketplace karsiligi" "configs/faz7/product_plan_catalog.v1.json" "\"code\": \"marketplace\""

has_text "7-2 code PlanStarter karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanStarter"
has_text "7-2 code PlanPro karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanPro"
has_text "7-2 code PlanEnterprise karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanEnterprise"
has_text "7-2 code PlanAccountant karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanAccountant"
has_text "7-2 code PlanMarketplace karsiligi" "internal/platform/commercial/catalog/catalog.go" "PlanMarketplace"

echo
echo "===== 7-2 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/catalog -v >/tmp/faz7_2_catalog_go_test.log 2>&1; then
    ok "7-2 Go test real implementation verification"
  else
    cat /tmp/faz7_2_catalog_go_test.log || true
    fail "7-2 Go test real implementation verification"
  fi
else
  fail "7-2 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-2 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-2 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_2_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_2_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md
- docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md
- configs/faz7/product_plan_catalog.v1.json
- internal/platform/commercial/catalog/catalog.go
- internal/platform/commercial/catalog/catalog_test.go
- scripts/faz7/test_7_2_product_packaging_plan_catalog.sh
- scripts/faz7/audit_7_2_real_implementation.sh

## Real Implementation Decision

7-2 real implementation audit confirms that the product packaging plan, plan catalog config, Go catalog model, Go unit tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_2_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_2_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_2_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-2 real implementation audit basariyla gecti"
else
  echo "FAZ_7_2_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-2 real implementation audit basarisiz"
  exit 1
fi
