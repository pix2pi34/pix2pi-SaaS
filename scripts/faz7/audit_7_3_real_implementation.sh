#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_3_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-3 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-3.1 Entitlement runtime dokumani" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md"
has_file "7-3.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_3_ENTITLEMENT_RUNTIME_EVIDENCE.md"
has_file "7-3.3 Entitlement config" "configs/faz7/entitlement_feature_gate.v1.json"
has_file "7-3.4 Go entitlement runtime modeli" "internal/platform/commercial/entitlement/entitlement.go"
has_file "7-3.5 Go entitlement testleri" "internal/platform/commercial/entitlement/entitlement_test.go"
has_file "7-3.6 Test scripti" "scripts/faz7/test_7_3_entitlement_runtime_feature_gate.sh"
has_file "7-3.7 Real implementation audit scripti" "scripts/faz7/audit_7_3_real_implementation.sh"

has_text "7-3.1.1 Paket hakki kontrolu dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Paket hakki kontrolu"
has_text "7-3.1.2 Tenant bazli feature flag dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Tenant bazli feature flag"
has_text "7-3.1.3 Kullanici bazli entitlement dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Kullanici bazli entitlement"
has_text "7-3.1.4 API/gateway paket kontrol dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "API/gateway seviyesinde paket kontrolu"
has_text "7-3.1.5 Audit log entitlement izi dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Audit log ile entitlement izi"

has_text "7-3.2.1 Kullanici limiti dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Kullanici limiti"
has_text "7-3.2.2 Tenant limiti dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Tenant limiti"
has_text "7-3.2.3 API aylik istek limiti dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "API aylik istek limiti"
has_text "7-3.2.4 Export limiti dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Export limiti"
has_text "7-3.2.5 Entegrasyon limiti dokuman karsiligi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "Entegrasyon limiti"

has_text "7-3 config required tenant karsiligi" "configs/faz7/entitlement_feature_gate.v1.json" "tenant_id_required"
has_text "7-3 config required user karsiligi" "configs/faz7/entitlement_feature_gate.v1.json" "user_id_required"
has_text "7-3 config allow decision karsiligi" "configs/faz7/entitlement_feature_gate.v1.json" "ALLOW"
has_text "7-3 config deny decision karsiligi" "configs/faz7/entitlement_feature_gate.v1.json" "DENY"
has_text "7-3 config monthly export limit karsiligi" "configs/faz7/entitlement_feature_gate.v1.json" "monthly_exports"

has_text "7-3 code Runtime karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "type Runtime struct"
has_text "7-3 code RuntimeContext karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "type RuntimeContext struct"
has_text "7-3 code Decision karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "type Decision struct"
has_text "7-3 code CheckFeature karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "CheckFeature"
has_text "7-3 code CheckLimit karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "CheckLimit"
has_text "7-3 code CheckFeatureAndLimit karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "CheckFeatureAndLimit"
has_text "7-3 code catalog integration karsiligi" "internal/platform/commercial/entitlement/entitlement.go" "commercial/catalog"

echo
echo "===== 7-3 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/entitlement -v >/tmp/faz7_3_entitlement_go_test.log 2>&1; then
    ok "7-3 Go test real implementation verification"
  else
    cat /tmp/faz7_3_entitlement_go_test.log || true
    fail "7-3 Go test real implementation verification"
  fi
else
  fail "7-3 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-3 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-3 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_3_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_3_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md
- docs/faz7/evidence/FAZ_7_3_ENTITLEMENT_RUNTIME_EVIDENCE.md
- configs/faz7/entitlement_feature_gate.v1.json
- internal/platform/commercial/entitlement/entitlement.go
- internal/platform/commercial/entitlement/entitlement_test.go
- scripts/faz7/test_7_3_entitlement_runtime_feature_gate.sh
- scripts/faz7/audit_7_3_real_implementation.sh

## Real Implementation Decision

7-3 real implementation audit confirms that entitlement runtime, feature gate logic, limit gate logic, tenant/user context validation, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_3_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_3_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_3_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-3 real implementation audit basariyla gecti"
else
  echo "FAZ_7_3_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-3 real implementation audit basarisiz"
  exit 1
fi
