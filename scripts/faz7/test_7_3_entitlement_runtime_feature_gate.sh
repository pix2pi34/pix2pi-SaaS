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

echo "===== FAZ 7-3 TEST BASLADI ====="

check_file "7-3" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md"
check_file "7-3" "docs/faz7/evidence/FAZ_7_3_ENTITLEMENT_RUNTIME_EVIDENCE.md"
check_file "7-3" "configs/faz7/entitlement_feature_gate.v1.json"
check_file "7-3" "internal/platform/commercial/entitlement/entitlement.go"
check_file "7-3" "internal/platform/commercial/entitlement/entitlement_test.go"
check_file "7-3" "scripts/faz7/test_7_3_entitlement_runtime_feature_gate.sh"
check_file "7-3" "scripts/faz7/audit_7_3_real_implementation.sh"

check_grep "7-3.1 Entitlement cekirdegi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.1 Entitlement Cekirdegi"
check_grep "7-3.1.1 Paket hakki kontrolu" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.1.1 Paket hakki kontrolu"
check_grep "7-3.1.2 Tenant bazli feature flag" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.1.2 Tenant bazli feature flag"
check_grep "7-3.1.3 Kullanici bazli entitlement" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.1.3 Kullanici bazli entitlement"
check_grep "7-3.1.4 API gateway paket kontrolu" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.1.4 API/gateway seviyesinde paket kontrolu"
check_grep "7-3.1.5 Audit log entitlement izi" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.1.5 Audit log ile entitlement izi"

check_grep "7-3.2 Limit gate" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.2 Limit Gate"
check_grep "7-3.2.1 Kullanici limiti" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.2.1 Kullanici limiti"
check_grep "7-3.2.2 Tenant limiti" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.2.2 Tenant limiti"
check_grep "7-3.2.3 API aylik istek limiti" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.2.3 API aylik istek limiti"
check_grep "7-3.2.4 Export limiti" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.2.4 Export limiti"
check_grep "7-3.2.5 Entegrasyon limiti" "docs/faz7/FAZ_7_3_ENTITLEMENT_RUNTIME_FEATURE_GATE.md" "7-3.2.5 Entegrasyon limiti"

check_grep "7-3 code NewDefaultRuntime" "internal/platform/commercial/entitlement/entitlement.go" "NewDefaultRuntime"
check_grep "7-3 code CheckFeature" "internal/platform/commercial/entitlement/entitlement.go" "CheckFeature"
check_grep "7-3 code CheckLimit" "internal/platform/commercial/entitlement/entitlement.go" "CheckLimit"
check_grep "7-3 code CheckFeatureAndLimit" "internal/platform/commercial/entitlement/entitlement.go" "CheckFeatureAndLimit"
check_grep "7-3 code DecisionAllow" "internal/platform/commercial/entitlement/entitlement.go" "DecisionAllow"
check_grep "7-3 code DecisionDeny" "internal/platform/commercial/entitlement/entitlement.go" "DecisionDeny"

echo
echo "===== 7-3 JSON CONFIG VALIDATION ====="
if python3 - <<'PY'
import json
from pathlib import Path

path = Path("configs/faz7/entitlement_feature_gate.v1.json")
data = json.loads(path.read_text(encoding="utf-8"))

if data.get("schema_version") != "entitlement_feature_gate.v1":
    raise SystemExit("schema_version mismatch")

if data.get("phase") != "FAZ_7":
    raise SystemExit("phase mismatch")

if data.get("step") != "7-3":
    raise SystemExit("step mismatch")

if data.get("runtime_status") != "READY":
    raise SystemExit("runtime_status mismatch")

ctx = data.get("required_context", {})
for key in ["tenant_id_required", "user_id_required", "plan_code_required"]:
    if ctx.get(key) is not True:
        raise SystemExit(f"required context missing or false: {key}")

model = data.get("decision_model", {})
if model.get("allow_status") != "ALLOW":
    raise SystemExit("allow status mismatch")
if model.get("deny_status") != "DENY":
    raise SystemExit("deny status mismatch")

required_reasons = {
    "ALLOW_FEATURE_INCLUDED",
    "ALLOW_LIMIT_AVAILABLE",
    "DENY_TENANT_REQUIRED",
    "DENY_USER_REQUIRED",
    "DENY_PLAN_REQUIRED",
    "DENY_PLAN_UNKNOWN",
    "DENY_FEATURE_NOT_INCLUDED",
    "DENY_LIMIT_UNKNOWN",
    "DENY_LIMIT_EXCEEDED",
}
reasons = set(model.get("reason_codes", []))
missing = required_reasons - reasons
if missing:
    raise SystemExit(f"missing reason codes: {sorted(missing)}")

if "api_access_basic" not in data.get("gated_features", []):
    raise SystemExit("api_access_basic missing from gated features")

if "monthly_exports" not in data.get("gated_limits", []):
    raise SystemExit("monthly_exports missing from gated limits")

print("JSON_OK")
PY
then
  ok "7-3 JSON config parse ve gate kontrolu"
else
  fail "7-3 JSON config parse ve gate kontrolu"
fi

echo
echo "===== 7-3 GO TEST ====="
if command -v go >/dev/null 2>&1; then
  if go test ./internal/platform/commercial/entitlement -v; then
    ok "7-3 Go entitlement unit testleri"
  else
    fail "7-3 Go entitlement unit testleri"
  fi
else
  fail "7-3 go binary bulunamadi"
fi

echo
echo "===== FAZ 7-3 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_3_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-3 testleri basariyla gecti"
else
  echo "FAZ_7_3_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-3 testlerinde hata var"
  exit 1
fi
