#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_1_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-1 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-1.1 Master plan dokumani" "docs/faz7/FAZ_7_MASTER_PLAN.md"
has_file "7-1.2 Scope freeze dokumani" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md"
has_file "7-1.3 Evidence dokumani" "docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md"
has_file "7-1.4 Test scripti" "scripts/faz7/test_7_1_faz7_master_scope_freeze.sh"
has_file "7-1.5 Real implementation audit scripti" "scripts/faz7/audit_7_1_real_implementation.sh"

has_text "7-1.1.1 Moduler buyume dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Moduler buyume"
has_text "7-1.1.2 Public launch dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Public launch"
has_text "7-1.1.3 Urunlestirme dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Urunlestirme"
has_text "7-1.1.4 Ticari runtime dokuman karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Ticari runtime"

has_text "7-1.2.1 Dahil isler scope karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 dahil isler"
has_text "7-1.2.2 Dis isler scope karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 disi isler"
has_text "7-1.2.3 Production launch gate karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Production public launch icin on sartlar"
has_text "7-1.2.4 Cloudflare green mode gate karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Cloudflare green mode"

has_text "7-1.3.1 Gercek odeme gate karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Gercek odeme"
has_text "7-1.3.2 Hukuk/KVKK gate karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "KVKK"
has_text "7-1.3.3 Billing/tax gate karsiligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "mali/vergi"
has_text "7-1.3.4 Core rewrite dislama karsiligi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Buyuk core rewrite"

echo
echo "===== FAZ 7-1 REAL IMPLEMENTATION AUDIT OZETI ====="
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

cat > "$AUDIT_FILE" <<AUDIT
# FAZ 7-1 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_1_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_1_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_MASTER_PLAN.md
- docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md
- docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md
- scripts/faz7/test_7_1_faz7_master_scope_freeze.sh
- scripts/faz7/audit_7_1_real_implementation.sh

## Real Implementation Decision

7-1 real implementation audit confirms that the FAZ 7 master plan, scope freeze, evidence, test script and audit script exist as code/config/script/document artifacts.

## Final Status

FAZ_7_1_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_1_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_1_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-1 real implementation audit basariyla gecti"
else
  echo "FAZ_7_1_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-1 real implementation audit basarisiz"
  exit 1
fi
