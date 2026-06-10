#!/usr/bin/env bash
set -euo pipefail

PHASE_SLUG="faz_5_18_3_2_kvkk_gizlilik_metinleri"
DOC_FILE="docs/faz5r/FAZ_5_18_3_2_KVKK_GIZLILIK_METINLERI.md"
CONFIG_FILE="configs/faz5r/${PHASE_SLUG}.v1.json"
TEST_FILE="tests/faz5r/${PHASE_SLUG}_test.json"
PRIVACY_DIR="privacy/faz5r/public_launch"
GO_DIR="internal/commercial/publiclaunch/privacy"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 MISSING_OR_INVALID / HATA ❌"
}

check_file() {
  local label="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 5-18.3.2 KVKK / GIZLILIK METINLERI REAL IMPLEMENTATION AUDIT START ====="

check_file "5-18.3.2 documentation file" "$DOC_FILE"
check_file "5-18.3.2 config manifest file" "$CONFIG_FILE"
check_file "5-18.3.2 test fixture file" "$TEST_FILE"
check_file "5-18.3.2 Go runtime file" "$GO_DIR/privacy_manifest.go"
check_file "5-18.3.2 Go test file" "$GO_DIR/privacy_manifest_test.go"

if go test ./internal/commercial/publiclaunch/privacy; then
  pass "5-18.3.2 go test status is PASS"
else
  fail "5-18.3.2 go test status"
fi

if python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

assert data["phase"] == "FAZ 5-R"
assert data["step_no"] == 243
assert data["step_code"] == "FAZ_5_18_3_2"
assert data["public_publish_allowed"] is False
assert data["public_core_product_allowed"] is True
assert data["data_monetization_public_allowed"] is False
assert data["legal_approval_required"] is True
assert data["kvkk_approval_required"] is True
assert data["production_ready"] is False

rules = data["separation_rules"]
assert rules["privacy_notice_separate_from_explicit_consent"] is True
assert rules["cookie_policy_separate"] is True
assert rules["commercial_electronic_message_consent_separate"] is True
assert rules["data_supported_plan_contract_terms_separate_from_personal_data_consent"] is True

runtime = data["runtime_contract"]
for key, value in runtime.items():
    assert value is True, key

docs = data["privacy_documents"]
assert len(docs) == 8
for doc in docs:
    assert doc["status"] == "DRAFT"
    assert doc["version"] == "0.1.0-draft"
    assert doc["public_publish_allowed"] is False
    assert doc["file"].startswith("privacy/faz5r/public_launch/")
    assert len(doc["required_approvals"]) >= 1

scopes = set(data["required_consent_scopes"])
required = {
    "DATA_SUPPORTED_PLAN_TERMS",
    "PERSONAL_DATA_COMMERCIAL_RECOMMENDATION",
    "SPONSORED_OFFER_PERSONALIZATION",
    "ANONYMIZED_AGGREGATED_INSIGHT",
    "AI_DECISION_SUPPORT",
    "COMMERCIAL_ELECTRONIC_MESSAGE",
    "NON_ESSENTIAL_COOKIES",
}
assert required.issubset(scopes)

PY
then
  pass "5-18.3.2 config semantic validation"
else
  fail "5-18.3.2 config semantic validation"
fi

if python3 - "$TEST_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

expected = data["expected"]
assert data["step_no"] == 243
assert data["step_code"] == "FAZ_5_18_3_2"
assert expected["public_publish_allowed"] is False
assert expected["public_core_product_allowed"] is True
assert expected["data_monetization_public_allowed"] is False
assert expected["privacy_document_count"] == 8
assert expected["required_consent_scope_count"] == 7
assert expected["privacy_notice_separate_from_explicit_consent"] is True
assert expected["commercial_electronic_message_consent_separate"] is True
assert expected["runtime_contract_required"] is True

PY
then
  pass "5-18.3.2 test fixture semantic validation"
else
  fail "5-18.3.2 test fixture semantic validation"
fi

privacy_files=(
  "privacy_notice.tr.md"
  "privacy_policy.tr.md"
  "explicit_consent.tr.md"
  "cookie_policy.tr.md"
  "commercial_electronic_message_consent.tr.md"
  "data_processing_inventory.tr.md"
  "privacy_preference_matrix.tr.md"
  "consent_registry_runtime_contract.tr.md"
)

for f in "${privacy_files[@]}"; do
  full_path="${PRIVACY_DIR}/${f}"
  check_file "5-18.3.2 privacy file ${f}" "$full_path"
  check_grep "5-18.3.2 ${f} draft marker" "DOCUMENT_STATUS: DRAFT" "$full_path"
  check_grep "5-18.3.2 ${f} public publish closed marker" "PUBLIC_PUBLISH_ALLOWED: NO" "$full_path"
  check_grep "5-18.3.2 ${f} legal pending marker" "LEGAL_APPROVAL_STATUS: PENDING" "$full_path"
  check_grep "5-18.3.2 ${f} kvkk pending marker" "KVKK_APPROVAL_STATUS: PENDING" "$full_path"
  check_grep "5-18.3.2 ${f} system marker" "Pix2pi Ticaret Operasyon Sistemi" "$full_path"
done

check_grep "5-18.3.2 privacy notice not explicit consent" "Bu metin açık rıza değildir" "${PRIVACY_DIR}/privacy_notice.tr.md"
check_grep "5-18.3.2 explicit consent checkbox exists" "Seçimli Açık Rıza Kutuları" "${PRIVACY_DIR}/explicit_consent.tr.md"
check_grep "5-18.3.2 commercial message separate consent" "Ayrı Onay" "${PRIVACY_DIR}/commercial_electronic_message_consent.tr.md"
check_grep "5-18.3.2 cookie non essential guard" "NON_ESSENTIAL_COOKIES" "${PRIVACY_DIR}/cookie_policy.tr.md"
check_grep "5-18.3.2 privacy preference data supported plan terms" "DATA_SUPPORTED_PLAN_TERMS" "${PRIVACY_DIR}/privacy_preference_matrix.tr.md"
check_grep "5-18.3.2 consent registry tenant id" "tenant_id" "${PRIVACY_DIR}/consent_registry_runtime_contract.tr.md"
check_grep "5-18.3.2 consent registry evidence hash" "evidence_hash" "${PRIVACY_DIR}/consent_registry_runtime_contract.tr.md"
check_grep "5-18.3.2 data inventory personal commercial distinction" "Kişisel veri niteliği taşımayan ticari işletme verileri" "${PRIVACY_DIR}/data_processing_inventory.tr.md"
check_grep "5-18.3.2 documentation public gate" "LEGAL_APPROVAL_STATUS" "$DOC_FILE"
check_grep "5-18.3.2 documentation runtime required fields" "privacy_notice_version" "$DOC_FILE"

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  DOC_STATUS="READY"
  CONFIG_STATUS="READY"
  PRIVACY_TEXT_STATUS="READY"
  RUNTIME_CONTRACT_STATUS="READY"
  TEST_STATUS="PASS"
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  DOC_STATUS="BLOCKED"
  CONFIG_STATUS="BLOCKED"
  PRIVACY_TEXT_STATUS="BLOCKED"
  RUNTIME_CONTRACT_STATUS="BLOCKED"
  TEST_STATUS="FAIL"
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat <<RESULT

===== FAZ 5-18.3.2 KVKK / GIZLILIK METINLERI REAL IMPLEMENTATION AUDIT RESULT =====
PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}
AUDIT_EVIDENCE_FILE=${AUDIT_EVIDENCE_FILE:-docs/faz5r/evidence/FAZ_5_18_3_2_KVKK_GIZLILIK_METINLERI_REAL_IMPLEMENTATION_AUDIT.md}
FAZ_5_18_3_2_DOC_STATUS=${DOC_STATUS}
FAZ_5_18_3_2_CONFIG_STATUS=${CONFIG_STATUS}
FAZ_5_18_3_2_PRIVACY_TEXT_STATUS=${PRIVACY_TEXT_STATUS}
FAZ_5_18_3_2_RUNTIME_CONTRACT_STATUS=${RUNTIME_CONTRACT_STATUS}
FAZ_5_18_3_2_TEST_STATUS=${TEST_STATUS}
FAZ_5_18_3_2_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FAZ_5_18_3_2_FINAL_STATUS=${FINAL_STATUS}
FAZ_5_18_3_4_READY=${NEXT_READY}
RESULT

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  exit 0
fi

exit 1
