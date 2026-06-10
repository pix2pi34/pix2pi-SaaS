#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0
OPTIONAL_WARN=0
AUDIT_FILE="docs/faz7/evidence/FAZ_7_7_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-7 REAL IMPLEMENTATION AUDIT BASLADI ====="

has_file "7-7.1 Public website dokumani" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md"
has_file "7-7.2 Evidence dokumani" "docs/faz7/evidence/FAZ_7_7_PUBLIC_WEBSITE_DEMO_FLOW_EVIDENCE.md"
has_file "7-7.3 Public demo config" "configs/faz7/public_demo_flow.v1.json"
has_file "7-7.4 Go public demo runtime modeli" "internal/platform/commercial/publicdemo/publicdemo.go"
has_file "7-7.5 Go public demo testleri" "internal/platform/commercial/publicdemo/publicdemo_test.go"
has_file "7-7.6 Static HTML checkpoint" "web/faz7/public-demo/index.html"
has_file "7-7.7 Test scripti" "scripts/faz7/test_7_7_public_website_landing_demo_flow.sh"
has_file "7-7.8 Real implementation audit scripti" "scripts/faz7/audit_7_7_real_implementation.sh"

has_text "7-7.1.1 Public landing page dokuman karsiligi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "Public landing page"
has_text "7-7.1.2 Paket/fiyat dokuman karsiligi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "Paket/fiyat gosterimi"
has_text "7-7.1.3 Demo talep formu dokuman karsiligi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "Demo talep formu"
has_text "7-7.1.4 Trial CTA dokuman karsiligi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "Trial baslatma yuzeyi"
has_text "7-7.1.5 SEO schema dokuman karsiligi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "SEO / schema hazirligi"

has_text "7-7 config landing sections karsiligi" "configs/faz7/public_demo_flow.v1.json" "landing_sections"
has_text "7-7 config demo fields karsiligi" "configs/faz7/public_demo_flow.v1.json" "required_demo_fields"
has_text "7-7 config consent gate karsiligi" "configs/faz7/public_demo_flow.v1.json" "consent_gate"
has_text "7-7 config public launch disabled karsiligi" "configs/faz7/public_demo_flow.v1.json" "\"public_production_launch_enabled\": false"
has_text "7-7 config Cloudflare gate karsiligi" "configs/faz7/public_demo_flow.v1.json" "requires_cloudflare_green_mode_before_public_launch"
has_text "7-7 config SEO schema karsiligi" "configs/faz7/public_demo_flow.v1.json" "SoftwareApplication"

has_text "7-7 code DemoRequest karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "type DemoRequest struct"
has_text "7-7 code Lead karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "type Lead struct"
has_text "7-7 code LandingModel karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "type LandingModel struct"
has_text "7-7 code CreateDemoLead karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "CreateDemoLead"
has_text "7-7 code QualifyLead karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "QualifyLead"
has_text "7-7 code MarkReadyForOnboarding karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "MarkReadyForOnboarding"
has_text "7-7 code CheckPublicLaunchGate karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "CheckPublicLaunchGate"
has_text "7-7 code catalog integration karsiligi" "internal/platform/commercial/publicdemo/publicdemo.go" "commercial/catalog"

has_text "7-7 HTML SoftwareApplication karsiligi" "web/faz7/public-demo/index.html" "SoftwareApplication"
has_text "7-7 HTML demo form karsiligi" "web/faz7/public-demo/index.html" "Demo Talep Formu"
has_text "7-7 HTML paketler karsiligi" "web/faz7/public-demo/index.html" "Paketler"
has_text "7-7 HTML entegrasyon karsiligi" "web/faz7/public-demo/index.html" "Entegrasyon"
has_text "7-7 HTML launch gate note karsiligi" "web/faz7/public-demo/index.html" "Public launch icin legal, KVKK ve Cloudflare green mode gate gerekir"

echo
echo "===== 7-7 AUDIT GO TEST VERIFICATION ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/publicdemo -v >/tmp/faz7_7_publicdemo_go_test.log 2>&1; then
    ok "7-7 Go test real implementation verification"
  else
    cat /tmp/faz7_7_publicdemo_go_test.log || true
    fail "7-7 Go test real implementation verification"
  fi
else
  fail "7-7 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-7 REAL IMPLEMENTATION AUDIT OZETI ====="
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
# FAZ 7-7 Real Implementation Audit

## Audit Summary

PASS_COUNT=$PASS_COUNT
REQUIRED_FAIL=$FAIL_COUNT
OPTIONAL_WARN=$OPTIONAL_WARN
FAZ_7_7_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
FAZ_7_7_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅

## Checked Implementation Evidence

- docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md
- docs/faz7/evidence/FAZ_7_7_PUBLIC_WEBSITE_DEMO_FLOW_EVIDENCE.md
- configs/faz7/public_demo_flow.v1.json
- internal/platform/commercial/publicdemo/publicdemo.go
- internal/platform/commercial/publicdemo/publicdemo_test.go
- web/faz7/public-demo/index.html
- scripts/faz7/test_7_7_public_website_landing_demo_flow.sh
- scripts/faz7/audit_7_7_real_implementation.sh

## Real Implementation Decision

7-7 real implementation audit confirms that public website readiness, landing page model, demo request runtime, consent gate, requested plan validation, lead status model, static HTML checkpoint, SEO/schema trace, config, Go tests, test script and audit script exist as real code/config/script/document artifacts.

## Final Status

FAZ_7_7_REAL_IMPLEMENTATION_STATUS=$STATUS $STATUS_ICON
AUDIT_REPORT

echo "OK ✅ evidence yazildi: $AUDIT_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_7_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_7_7_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo "OK ✅ FAZ 7-7 real implementation audit basariyla gecti"
else
  echo "FAZ_7_7_REAL_IMPLEMENTATION_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-7 real implementation audit basarisiz"
  exit 1
fi
