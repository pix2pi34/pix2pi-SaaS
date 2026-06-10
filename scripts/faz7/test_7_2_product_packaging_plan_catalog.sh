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

echo "===== FAZ 7-2 TEST BASLADI ====="

check_file "7-2" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md"
check_file "7-2" "docs/faz7/evidence/FAZ_7_2_PRODUCT_PACKAGING_EVIDENCE.md"
check_file "7-2" "configs/faz7/product_plan_catalog.v1.json"
check_file "7-2" "internal/platform/commercial/catalog/catalog.go"
check_file "7-2" "internal/platform/commercial/catalog/catalog_test.go"
check_file "7-2" "scripts/faz7/test_7_2_product_packaging_plan_catalog.sh"
check_file "7-2" "scripts/faz7/audit_7_2_real_implementation.sh"

check_grep "7-2.1 Paket mimarisi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1 Paket Mimarisi"
check_grep "7-2.1.1 Starter paket" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.1 Starter Paket"
check_grep "7-2.1.2 Pro paket" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.2 Pro Paket"
check_grep "7-2.1.3 Enterprise paket" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.3 Enterprise Paket"
check_grep "7-2.1.4 Muhasebeci paketi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.4 Muhasebeci Paketi"
check_grep "7-2.1.5 Marketplace entegrasyon paketi" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.1.5 Marketplace / Entegrasyon Paketi"

check_grep "7-2.2 Feature matrix" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2 Feature Matrix"
check_grep "7-2.2.1 Modul bazli yetki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.1 Modul Bazli Yetki"
check_grep "7-2.2.2 Kullanici limiti" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.2 Kullanici Limiti"
check_grep "7-2.2.3 Tenant limiti" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.3 Tenant Limiti"
check_grep "7-2.2.4 API hakki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.4 API Hakki"
check_grep "7-2.2.5 Export hakki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.5 Export Hakki"
check_grep "7-2.2.6 Muhasebeci erisim hakki" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-2.2.6 Muhasebeci Erisim Hakki"

check_grep "7-2.3 Plan catalog config" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "configs/faz7/product_plan_catalog.v1.json"
check_grep "7-2.4 Go code artifact" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "internal/platform/commercial/catalog/catalog.go"
check_grep "7-2.5 7-3 hazirlik" "docs/faz7/FAZ_7_2_PRODUCT_PACKAGING_PLAN_CATALOG.md" "7-3 entitlement runtime"

echo
echo "===== 7-2 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/product_plan_catalog.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

required_plans = {"starter", "pro", "enterprise", "accountant", "marketplace"}
plans = {p["code"]: p for p in data.get("plans", [])}

missing = required_plans - set(plans.keys())
if missing:
    raise SystemExit(f"missing plans: {sorted(missing)}")

if data.get("schema_version") != "product_plan_catalog.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-2":
    raise SystemExit("step mismatch")

if data.get("catalog_status") != "READY":
    raise SystemExit("catalog_status mismatch")

for code, plan in plans.items():
    if not plan.get("features"):
        raise SystemExit(f"plan has no features: {code}")
    limits = plan.get("limits", {})
    for key in ["users", "tenants", "api_monthly_requests", "monthly_exports", "accountant_firms", "integrations"]:
        if key not in limits:
            raise SystemExit(f"plan {code} missing limit {key}")

gates = data.get("launch_gates", {})
for key in [
    "real_payment_requires_financial_approval",
    "public_launch_requires_legal_approval",
    "public_launch_requires_kvkk_approval",
    "public_launch_requires_cloudflare_green_mode",
    "public_launch_requires_waf_rate_limit",
]:
    if gates.get(key) is not True:
        raise SystemExit(f"launch gate missing or false: {key}")

print("JSON_OK")
PY
then
  ok "7-2 JSON config parse ve gate kontrolu"
else
  fail "7-2 JSON config parse ve gate kontrolu"
fi

echo
echo "===== 7-2 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/catalog -v; then
    ok "7-2 Go catalog unit testleri"
  else
    fail "7-2 Go catalog unit testleri"
  fi
else
  fail "7-2 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-2 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_2_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-2 testleri basariyla gecti"
else
  echo "FAZ_7_2_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-2 testlerinde hata var"
  exit 1
fi
