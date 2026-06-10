#!/usr/bin/env bash
set -euo pipefail

PHASE_SLUG="faz_5_18_3_1_sozlesme_seti"
DOC_FILE="docs/faz5r/FAZ_5_18_3_1_SOZLESME_SETI.md"
CONFIG_FILE="configs/faz5r/${PHASE_SLUG}.v1.json"
TEST_FILE="tests/faz5r/${PHASE_SLUG}_test.json"
GO_DIR="internal/commercial/publiclaunch/contracts"
CONTRACT_DIR="contracts/faz5r/public_launch"

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

echo "===== FAZ 5-18.3.1 SOZLESME SETI FIX REAL IMPLEMENTATION AUDIT START ====="

check_file "5-18.3.1 documentation file" "$DOC_FILE"
check_file "5-18.3.1 config manifest file" "$CONFIG_FILE"
check_file "5-18.3.1 test fixture file" "$TEST_FILE"
check_file "5-18.3.1 Go runtime file" "$GO_DIR/contract_manifest.go"
check_file "5-18.3.1 Go test file" "$GO_DIR/contract_manifest_test.go"
check_file "5-18.3.1 contract README file" "$CONTRACT_DIR/README.md"

if go test ./internal/commercial/publiclaunch/contracts; then
  pass "5-18.3.1 go test status is PASS"
else
  fail "5-18.3.1 go test status"
fi

if python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

required_slugs = {
    "abonelik_hizmet_sozlesmesi",
    "kullanim_sartlari",
    "gizlilik_politikasi",
    "kvkk_aydinlatma_metni",
    "acik_riza_metni",
    "cerez_politikasi",
    "veri_isleme_ek_protokolu",
    "sla_destek_politikasi",
    "iptal_iade_politikasi",
    "muhasebeci_portali_ek_sartlari",
    "paket_fiyat_entitlement_ek_sartlari",
    "ticari_fayda_programi_ek_sartlari",
}

assert data["phase"] == "FAZ 5-R"
assert data["step_no"] == 242
assert data["step_code"] == "FAZ_5_18_3_1"
assert data["slug"] == "faz_5_18_3_1_sozlesme_seti"
assert data["set_version"] == "0.2.0-draft-fix"
assert data["public_publish_allowed"] is False
assert data["public_core_product_allowed"] is True
assert data["public_contract_draft_allowed"] is False
assert data["data_monetization_public_allowed"] is False
assert data["legal_kvkk_approval_required_for_data_model"] is True
assert data["legal_approval_required"] is True
assert data["kvkk_approval_required"] is True
assert data["production_ready"] is False

business = data["business_terms"]
assert business["system_name"] == "Pix2pi Ticaret Operasyon Sistemi"
assert business["restricted_paid_plan_supported"] is True
assert business["module_based_pricing_supported"] is True
assert business["enterprise_privacy_plan_supported"] is True
assert business["commercial_benefit_program_supported"] is True
assert business["procurement_recommendation_supported"] is True
assert business["pooled_purchasing_supported"] is True
assert business["sponsored_offer_supported"] is True
assert business["anonymous_aggregated_insight_supported"] is True
assert business["pix2pi_supplier_reseller_role_supported"] is True

runtime = data["runtime_gate_contract"]
for key, value in runtime.items():
    assert value is True, f"runtime gate must be true: {key}"

pricing = data["pricing_policy"]
assert pricing["pix2pi_can_set_monthly_yearly_periodic_prices"] is True
assert pricing["first_year_discount_or_free_does_not_create_permanent_right"] is True
assert pricing["renewal_prices_can_change"] is True
assert pricing["module_based_pricing_can_apply_when_data_model_declined"] is True
assert pricing["customer_may_cancel_before_renewal_if_new_price_declined"] is True

approval_gates = data["approval_gates"]
for gate in [
    "hukukcu_onayi",
    "kvkk_danismani_onayi",
    "ticari_operasyon_onayi",
    "founder_go_no_go",
]:
    assert gate in approval_gates
    assert approval_gates[gate]["status"] == "PENDING"
    assert approval_gates[gate]["required_for_public_launch"] is True

plan_modes = data["plan_modes"]
for mode in ["DATA_SUPPORTED", "RESTRICTED_PAID", "ENTERPRISE_PRIVACY"]:
    assert mode in plan_modes
    assert plan_modes[mode]["core_product_allowed"] is True

docs = data["required_documents"]
assert len(docs) >= 12
seen = {doc["slug"] for doc in docs}
assert required_slugs.issubset(seen)

for doc in docs:
    assert doc["status"] == "DRAFT"
    assert doc["version"] == "0.2.0-draft-fix"
    assert doc["file"].startswith("contracts/faz5r/public_launch/")
    assert len(doc["required_approvals"]) >= 1

PY
then
  pass "5-18.3.1 config semantic validation"
else
  fail "5-18.3.1 config semantic validation"
fi

if python3 - "$TEST_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

expected = data["expected"]
assert data["step_no"] == 242
assert data["step_code"] == "FAZ_5_18_3_1"
assert expected["public_publish_allowed"] is False
assert expected["public_core_product_allowed"] is True
assert expected["public_contract_draft_allowed"] is False
assert expected["data_monetization_public_allowed"] is False
assert expected["legal_kvkk_approval_required_for_data_model"] is True
assert expected["legal_approval_required"] is True
assert expected["kvkk_approval_required"] is True
assert expected["production_ready"] is False
assert expected["required_document_count"] == 12
assert len(expected["required_contract_slugs"]) == 12
assert len(expected["required_gates"]) == 4
assert len(expected["required_plan_modes"]) == 3

PY
then
  pass "5-18.3.1 test fixture semantic validation"
else
  fail "5-18.3.1 test fixture semantic validation"
fi

required_files=(
  "abonelik_hizmet_sozlesmesi.tr.md"
  "kullanim_sartlari.tr.md"
  "gizlilik_politikasi.tr.md"
  "kvkk_aydinlatma_metni.tr.md"
  "acik_riza_metni.tr.md"
  "cerez_politikasi.tr.md"
  "veri_isleme_ek_protokolu.tr.md"
  "sla_destek_politikasi.tr.md"
  "iptal_iade_politikasi.tr.md"
  "muhasebeci_portali_ek_sartlari.tr.md"
  "paket_fiyat_entitlement_ek_sartlari.tr.md"
  "ticari_fayda_programi_ek_sartlari.tr.md"
)

for contract_file in "${required_files[@]}"; do
  full_path="${CONTRACT_DIR}/${contract_file}"
  check_file "5-18.3.1 contract file ${contract_file}" "$full_path"
  check_grep "5-18.3.1 ${contract_file} draft marker" "CONTRACT_STATUS: DRAFT" "$full_path"
  check_grep "5-18.3.1 ${contract_file} public publish closed marker" "PUBLIC_PUBLISH_ALLOWED: NO" "$full_path"
  check_grep "5-18.3.1 ${contract_file} legal pending marker" "LEGAL_APPROVAL_STATUS: PENDING" "$full_path"
  check_grep "5-18.3.1 ${contract_file} kvkk pending marker" "KVKK_APPROVAL_STATUS: PENDING" "$full_path"
  check_grep "5-18.3.1 ${contract_file} system name marker" "Pix2pi Ticaret Operasyon Sistemi" "$full_path"
done

check_grep "5-18.3.1 documentation data supported plan" "Veri Destekli Plan Kararı" "$DOC_FILE"
check_grep "5-18.3.1 documentation core product gate" "PUBLIC_CORE_PRODUCT_ALLOWED: true" "$DOC_FILE"
check_grep "5-18.3.1 documentation data monetization closed gate" "DATA_MONETIZATION_PUBLIC_ALLOWED: false" "$DOC_FILE"
check_grep "5-18.3.1 documentation runtime consent fields" "DATA_SUPPORTED_PLAN_ACCEPTED" "$DOC_FILE"
check_grep "5-18.3.1 ticari fayda programi role" "aracı, bayi, distribütör" "$CONTRACT_DIR/ticari_fayda_programi_ek_sartlari.tr.md"
check_grep "5-18.3.1 paket fiyat renewal policy" "kazanılmış hak oluşturmaz" "$CONTRACT_DIR/paket_fiyat_entitlement_ek_sartlari.tr.md"
check_grep "5-18.3.1 acik riza selectable checkboxes" "Seçimli Açık Rıza Kutuları" "$CONTRACT_DIR/acik_riza_metni.tr.md"
check_grep "5-18.3.1 kvkk data supported distinction" "Ticari Veri ve Kişisel Veri Ayrımı" "$CONTRACT_DIR/kvkk_aydinlatma_metni.tr.md"

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  DOC_STATUS="READY"
  CONFIG_STATUS="READY"
  CONTRACT_SET_STATUS="READY"
  RUNTIME_CONTRACT_STATUS="READY"
  TEST_STATUS="PASS"
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  DOC_STATUS="BLOCKED"
  CONFIG_STATUS="BLOCKED"
  CONTRACT_SET_STATUS="BLOCKED"
  RUNTIME_CONTRACT_STATUS="BLOCKED"
  TEST_STATUS="FAIL"
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat <<RESULT

===== FAZ 5-18.3.1 SOZLESME SETI FIX REAL IMPLEMENTATION AUDIT RESULT =====
PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}
AUDIT_EVIDENCE_FILE=${AUDIT_EVIDENCE_FILE:-docs/faz5r/evidence/FAZ_5_18_3_1_SOZLESME_SETI_REAL_IMPLEMENTATION_AUDIT.md}
FAZ_5_18_3_1_DOC_STATUS=${DOC_STATUS}
FAZ_5_18_3_1_CONFIG_STATUS=${CONFIG_STATUS}
FAZ_5_18_3_1_CONTRACT_SET_STATUS=${CONTRACT_SET_STATUS}
FAZ_5_18_3_1_RUNTIME_CONTRACT_STATUS=${RUNTIME_CONTRACT_STATUS}
FAZ_5_18_3_1_TEST_STATUS=${TEST_STATUS}
FAZ_5_18_3_1_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FAZ_5_18_3_1_FINAL_STATUS=${FINAL_STATUS}
FAZ_5_18_3_2_READY=${NEXT_READY}
RESULT

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  exit 0
fi

exit 1
