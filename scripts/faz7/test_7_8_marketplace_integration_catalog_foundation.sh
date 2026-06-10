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

echo "===== FAZ 7-8 TEST BASLADI ====="

check_file "7-8" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md"
check_file "7-8" "docs/faz7/evidence/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_EVIDENCE.md"
check_file "7-8" "configs/faz7/integration_catalog.v1.json"
check_file "7-8" "internal/platform/commercial/integrationcatalog/integrationcatalog.go"
check_file "7-8" "internal/platform/commercial/integrationcatalog/integrationcatalog_test.go"
check_file "7-8" "scripts/faz7/test_7_8_marketplace_integration_catalog_foundation.sh"
check_file "7-8" "scripts/faz7/audit_7_8_real_implementation.sh"

check_grep "7-8.1 Entegrasyon katalogu" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1 Entegrasyon Katalogu"
check_grep "7-8.1.1 Entegrasyon katalog modeli" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.1 Entegrasyon katalog modeli"
check_grep "7-8.1.2 Parasut entegrasyon hazirligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.2 Parasut entegrasyon hazirligi"
check_grep "7-8.1.3 Pazaryeri entegrasyon hazirligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.3 Pazaryeri entegrasyon hazirligi"
check_grep "7-8.1.4 Webhook public API hazirligi" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.4 Webhook/public API hazirligi"
check_grep "7-8.1.5 Paketleme ucretlendirme" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.1.5 Entegrasyon paketleme ve ucretlendirme"
check_grep "7-8.2 Access gate" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-8.2 Access Gate"
check_grep "7-8.3 Code artifact" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "internal/platform/commercial/integrationcatalog/integrationcatalog.go"
check_grep "7-8.4 Config artifact" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "configs/faz7/integration_catalog.v1.json"
check_grep "7-8.5 7-9 hazirlik" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "7-9"

check_grep "7-8 config schema" "configs/faz7/integration_catalog.v1.json" "integration_catalog.v1"
check_grep "7-8 config parasut" "configs/faz7/integration_catalog.v1.json" "\"code\": \"parasut\""
check_grep "7-8 config marketplace discovery" "configs/faz7/integration_catalog.v1.json" "\"code\": \"marketplace_discovery\""
check_grep "7-8 config webhook" "configs/faz7/integration_catalog.v1.json" "\"code\": \"webhook\""
check_grep "7-8 config public api" "configs/faz7/integration_catalog.v1.json" "\"code\": \"public_api\""
check_grep "7-8 config tdhp export" "configs/faz7/integration_catalog.v1.json" "\"code\": \"tdhp_export\""
check_grep "7-8 config accountant bridge" "configs/faz7/integration_catalog.v1.json" "\"code\": \"accountant_portal_bridge\""

check_grep "7-8 code Integration struct" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type Integration struct"
check_grep "7-8 code RuntimeContext" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type RuntimeContext struct"
check_grep "7-8 code Runtime" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "type Runtime struct"
check_grep "7-8 code CheckAccess" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckAccess"
check_grep "7-8 code CheckIntegrationLimit" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckIntegrationLimit"
check_grep "7-8 code CheckAccessAndLimit" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "CheckAccessAndLimit"
check_grep "7-8 code catalog integration" "internal/platform/commercial/integrationcatalog/integrationcatalog.go" "commercial/catalog"

echo
echo "===== 7-8 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/integration_catalog.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "integration_catalog.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-8":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

required_categories = {"accounting", "marketplace", "webhook", "public_api", "export", "accountant"}
categories = set(data.get("categories", []))
missing_categories = required_categories - categories
if missing_categories:
    raise SystemExit(f"missing categories: {sorted(missing_categories)}")

ctx = data.get("required_context", {})
for key in ["tenant_id_required", "user_id_required", "plan_code_required"]:
    if ctx.get(key) is not True:
        raise SystemExit(f"context gate missing: {key}")

required_integrations = {
    "parasut",
    "marketplace_discovery",
    "marketplace_orders",
    "marketplace_stock_sync",
    "webhook",
    "public_api",
    "tdhp_export",
    "accountant_portal_bridge",
}
integrations = {item["code"]: item for item in data.get("integrations", [])}
missing_integrations = required_integrations - set(integrations.keys())
if missing_integrations:
    raise SystemExit(f"missing integrations: {sorted(missing_integrations)}")

for code, item in integrations.items():
    if not item.get("required_features"):
        raise SystemExit(f"required_features missing for {code}")
    if not item.get("required_limit"):
        raise SystemExit(f"required_limit missing for {code}")

required_rules = {"starter", "pro", "enterprise", "accountant", "marketplace"}
rules = set(data.get("plan_packaging_rules", {}).keys())
missing_rules = required_rules - rules
if missing_rules:
    raise SystemExit(f"missing plan packaging rules: {sorted(missing_rules)}")

required_reasons = {
    "ALLOW_INTEGRATION_ACCESS",
    "ALLOW_INTEGRATION_LIMIT_AVAILABLE",
    "DENY_TENANT_REQUIRED",
    "DENY_USER_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_INTEGRATION_UNKNOWN",
    "DENY_INTEGRATION_DISABLED",
    "DENY_FEATURE_NOT_INCLUDED",
    "DENY_LIMIT_UNKNOWN",
    "DENY_LIMIT_EXCEEDED",
}
reasons = set(data.get("decision_model", {}).get("reason_codes", []))
missing_reasons = required_reasons - reasons
if missing_reasons:
    raise SystemExit(f"missing reason codes: {sorted(missing_reasons)}")

print("JSON_OK")
PY
then
  ok "7-8 JSON config parse ve integration gate kontrolu"
else
  fail "7-8 JSON config parse ve integration gate kontrolu"
fi

echo
echo "===== 7-8 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/integrationcatalog -v; then
    ok "7-8 Go integration catalog unit testleri"
  else
    fail "7-8 Go integration catalog unit testleri"
  fi
else
  fail "7-8 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-8 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_8_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-8 testleri basariyla gecti"
else
  echo "FAZ_7_8_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-8 testlerinde hata var"
  exit 1
fi
