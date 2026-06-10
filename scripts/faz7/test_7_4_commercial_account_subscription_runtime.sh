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

echo "===== FAZ 7-4 TEST BASLADI ====="

check_file "7-4" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md"
check_file "7-4" "docs/faz7/evidence/FAZ_7_4_SUBSCRIPTION_RUNTIME_EVIDENCE.md"
check_file "7-4" "configs/faz7/subscription_runtime.v1.json"
check_file "7-4" "internal/platform/commercial/subscription/subscription.go"
check_file "7-4" "internal/platform/commercial/subscription/subscription_test.go"
check_file "7-4" "scripts/faz7/test_7_4_commercial_account_subscription_runtime.sh"
check_file "7-4" "scripts/faz7/audit_7_4_real_implementation.sh"

check_grep "7-4.1 Subscription modeli" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.1 Subscription Modeli"
check_grep "7-4.1.1 Tenant subscription kaydi" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.1.1 Tenant subscription kaydi"
check_grep "7-4.1.2 Plan degisikligi" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.1.2 Plan degisikligi"
check_grep "7-4.1.3 Trial demo suresi" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.1.3 Trial/demo suresi"
check_grep "7-4.1.4 Paket yenileme" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.1.4 Paket yenileme"
check_grep "7-4.1.5 Askiya alma yeniden acma" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.1.5 Askiya alma / yeniden acma"

check_grep "7-4.2 Status modeli" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.2 Status Modeli"
check_grep "7-4.2.1 ACTIVE" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.2.1 ACTIVE"
check_grep "7-4.2.2 TRIALING" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.2.2 TRIALING"
check_grep "7-4.2.3 SUSPENDED" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.2.3 SUSPENDED"
check_grep "7-4.2.4 CANCELED" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.2.4 CANCELED"
check_grep "7-4.2.5 EXPIRED" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.2.5 EXPIRED"

check_grep "7-4.3 Entitlement baglantisi" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.3 Entitlement Baglantisi"
check_grep "7-4.4 Usage counters" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-4.4 Usage Counters"
check_grep "7-4.5 Code artifact" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "internal/platform/commercial/subscription/subscription.go"
check_grep "7-4.6 Config artifact" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "configs/faz7/subscription_runtime.v1.json"
check_grep "7-4.7 7-5 hazirlik" "docs/faz7/FAZ_7_4_COMMERCIAL_ACCOUNT_SUBSCRIPTION_RUNTIME.md" "7-5 Billing Readiness"

check_grep "7-4 code Account struct" "internal/platform/commercial/subscription/subscription.go" "type Account struct"
check_grep "7-4 code Runtime struct" "internal/platform/commercial/subscription/subscription.go" "type Runtime struct"
check_grep "7-4 code StartTrial" "internal/platform/commercial/subscription/subscription.go" "StartTrial"
check_grep "7-4 code Activate" "internal/platform/commercial/subscription/subscription.go" "Activate"
check_grep "7-4 code ChangePlan" "internal/platform/commercial/subscription/subscription.go" "ChangePlan"
check_grep "7-4 code Renew" "internal/platform/commercial/subscription/subscription.go" "Renew"
check_grep "7-4 code Suspend" "internal/platform/commercial/subscription/subscription.go" "Suspend"
check_grep "7-4 code Resume" "internal/platform/commercial/subscription/subscription.go" "Resume"
check_grep "7-4 code Cancel" "internal/platform/commercial/subscription/subscription.go" "Cancel"
check_grep "7-4 code entitlement integration" "internal/platform/commercial/subscription/subscription.go" "commercial/entitlement"

echo
echo "===== 7-4 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/subscription_runtime.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "subscription_runtime.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-4":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

required_fields = {
    "tenant_id",
    "account_id",
    "plan_code",
    "subscription_status",
    "current_period_start",
    "current_period_end",
}
fields = set(data.get("required_account_fields", []))
missing_fields = required_fields - fields
if missing_fields:
    raise SystemExit(f"missing required fields: {sorted(missing_fields)}")

required_statuses = {"ACTIVE", "TRIALING", "SUSPENDED", "CANCELED", "EXPIRED"}
statuses = set(data.get("subscription_statuses", []))
missing_statuses = required_statuses - statuses
if missing_statuses:
    raise SystemExit(f"missing statuses: {sorted(missing_statuses)}")

required_operations = {
    "start_trial",
    "activate",
    "change_plan",
    "renew",
    "suspend",
    "resume",
    "cancel",
    "check_feature",
    "check_limit",
    "check_feature_and_limit",
}
operations = set(data.get("supported_operations", []))
missing_operations = required_operations - operations
if missing_operations:
    raise SystemExit(f"missing operations: {sorted(missing_operations)}")

billing = data.get("billing_readiness", {})
if billing.get("real_payment_enabled") is not False:
    raise SystemExit("real payment must be disabled in 7-4")
if billing.get("billing_simulation_enabled") is not True:
    raise SystemExit("billing simulation must be enabled")
if billing.get("requires_financial_approval_before_real_payment") is not True:
    raise SystemExit("financial approval gate missing")

print("JSON_OK")
PY
then
  ok "7-4 JSON config parse ve runtime gate kontrolu"
else
  fail "7-4 JSON config parse ve runtime gate kontrolu"
fi

echo
echo "===== 7-4 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/subscription -v; then
    ok "7-4 Go subscription unit testleri"
  else
    fail "7-4 Go subscription unit testleri"
  fi
else
  fail "7-4 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-4 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_4_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-4 testleri basariyla gecti"
else
  echo "FAZ_7_4_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-4 testlerinde hata var"
  exit 1
fi
