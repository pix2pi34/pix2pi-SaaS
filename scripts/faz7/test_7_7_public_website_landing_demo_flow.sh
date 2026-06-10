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

echo "===== FAZ 7-7 TEST BASLADI ====="

check_file "7-7" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md"
check_file "7-7" "docs/faz7/evidence/FAZ_7_7_PUBLIC_WEBSITE_DEMO_FLOW_EVIDENCE.md"
check_file "7-7" "configs/faz7/public_demo_flow.v1.json"
check_file "7-7" "internal/platform/commercial/publicdemo/publicdemo.go"
check_file "7-7" "internal/platform/commercial/publicdemo/publicdemo_test.go"
check_file "7-7" "web/faz7/public-demo/index.html"
check_file "7-7" "scripts/faz7/test_7_7_public_website_landing_demo_flow.sh"
check_file "7-7" "scripts/faz7/audit_7_7_real_implementation.sh"

check_grep "7-7.1 Public yuzey" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.1 Public Yuzey"
check_grep "7-7.1.1 Public landing page" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.1.1 Public landing page"
check_grep "7-7.1.2 Paket fiyat gosterimi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.1.2 Paket/fiyat gosterimi"
check_grep "7-7.1.3 Demo talep formu" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.1.3 Demo talep formu"
check_grep "7-7.1.4 Trial baslatma yuzeyi" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.1.4 Trial baslatma yuzeyi"
check_grep "7-7.1.5 SEO schema" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.1.5 SEO / schema hazirligi"
check_grep "7-7.2 Demo lead runtime" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-7.2 Demo Lead Runtime"
check_grep "7-7.3 Static public checkpoint" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "web/faz7/public-demo/index.html"
check_grep "7-7.6 7-8 hazirlik" "docs/faz7/FAZ_7_7_PUBLIC_WEBSITE_LANDING_DEMO_FLOW.md" "7-8 Marketplace"

check_grep "7-7 config schema" "configs/faz7/public_demo_flow.v1.json" "public_demo_flow.v1"
check_grep "7-7 config request_demo CTA" "configs/faz7/public_demo_flow.v1.json" "request_demo"
check_grep "7-7 config start_trial CTA" "configs/faz7/public_demo_flow.v1.json" "start_trial"
check_grep "7-7 config marketplace CTA" "configs/faz7/public_demo_flow.v1.json" "marketplace_discovery"
check_grep "7-7 config SoftwareApplication" "configs/faz7/public_demo_flow.v1.json" "SoftwareApplication"
check_grep "7-7 config public launch disabled" "configs/faz7/public_demo_flow.v1.json" "\"public_production_launch_enabled\": false"

check_grep "7-7 code DemoRequest" "internal/platform/commercial/publicdemo/publicdemo.go" "type DemoRequest struct"
check_grep "7-7 code Lead" "internal/platform/commercial/publicdemo/publicdemo.go" "type Lead struct"
check_grep "7-7 code LandingModel" "internal/platform/commercial/publicdemo/publicdemo.go" "type LandingModel struct"
check_grep "7-7 code CreateDemoLead" "internal/platform/commercial/publicdemo/publicdemo.go" "CreateDemoLead"
check_grep "7-7 code QualifyLead" "internal/platform/commercial/publicdemo/publicdemo.go" "QualifyLead"
check_grep "7-7 code MarkReadyForOnboarding" "internal/platform/commercial/publicdemo/publicdemo.go" "MarkReadyForOnboarding"
check_grep "7-7 code CheckPublicLaunchGate" "internal/platform/commercial/publicdemo/publicdemo.go" "CheckPublicLaunchGate"

check_grep "7-7 html title" "web/faz7/public-demo/index.html" "Pix2pi SaaS ERP"
check_grep "7-7 html demo form" "web/faz7/public-demo/index.html" "Demo Talep Formu"
check_grep "7-7 html SoftwareApplication schema" "web/faz7/public-demo/index.html" "SoftwareApplication"
check_grep "7-7 html public launch note" "web/faz7/public-demo/index.html" "FAZ_7_7_WEB_STATUS=READY"

echo
echo "===== 7-7 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/public_demo_flow.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "public_demo_flow.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-7":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

if data.get("public_launch_status") != "NOT_PUBLIC_PRODUCTION_LAUNCH":
    raise SystemExit("public launch status mismatch")

required_sections = {"hero", "product_value", "plans", "demo_request", "trial_cta", "integration_cta", "seo_schema"}
sections = set(data.get("landing_sections", []))
missing_sections = required_sections - sections
if missing_sections:
    raise SystemExit(f"missing landing sections: {sorted(missing_sections)}")

required_plans = {"starter", "pro", "enterprise", "accountant", "marketplace"}
plans = set(data.get("plans_visible", []))
missing_plans = required_plans - plans
if missing_plans:
    raise SystemExit(f"missing visible plans: {sorted(missing_plans)}")

required_fields = {
    "request_id",
    "business_name",
    "contact_name",
    "email",
    "phone",
    "company_size",
    "requested_plan",
    "message",
    "consent_accepted",
}
fields = set(data.get("required_demo_fields", []))
missing_fields = required_fields - fields
if missing_fields:
    raise SystemExit(f"missing demo fields: {sorted(missing_fields)}")

consent = data.get("consent_gate", {})
if consent.get("kvkk_consent_required") is not True:
    raise SystemExit("kvkk consent gate missing")
if consent.get("commercial_contact_consent_required") is not True:
    raise SystemExit("commercial contact consent gate missing")

gates = data.get("public_safety_gates", {})
if gates.get("real_payment_enabled") is not False:
    raise SystemExit("real payment must be disabled")
if gates.get("public_production_launch_enabled") is not False:
    raise SystemExit("public production launch must be disabled")
for key in [
    "requires_legal_approval_before_public_launch",
    "requires_kvkk_approval_before_public_forms",
    "requires_cloudflare_green_mode_before_public_launch",
]:
    if gates.get(key) is not True:
        raise SystemExit(f"public safety gate missing: {key}")

required_reasons = {
    "ALLOW_DEMO_REQUEST_READY",
    "ALLOW_READY_FOR_ONBOARDING",
    "DENY_REQUEST_REQUIRED",
    "DENY_BUSINESS_REQUIRED",
    "DENY_CONTACT_REQUIRED",
    "DENY_EMAIL_INVALID",
    "DENY_PHONE_REQUIRED",
    "DENY_COMPANY_SIZE_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_CONSENT_REQUIRED",
    "DENY_PUBLIC_LAUNCH_DISABLED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-7 JSON config parse ve public demo gate kontrolu"
else
  fail "7-7 JSON config parse ve public demo gate kontrolu"
fi

echo
echo "===== 7-7 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/publicdemo -v; then
    ok "7-7 Go public demo unit testleri"
  else
    fail "7-7 Go public demo unit testleri"
  fi
else
  fail "7-7 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-7 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_7_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-7 testleri basariyla gecti"
else
  echo "FAZ_7_7_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-7 testlerinde hata var"
  exit 1
fi
