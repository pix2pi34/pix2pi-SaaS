#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_5_tenant_lifecycle_commercial_ops.md"
PREV_JSON="configs/faz5/tenant_lifecycle_policy_v1.json"
DOC="docs/faz5/5_6_legal_compliance_kvkk_terms.md"
JSON_FILE="configs/faz5/legal_compliance_policy_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_6_LEGAL_COMPLIANCE_KVKK_TERMS_REPORT.txt"

FAIL_COUNT=0
OK_COUNT=0
DONE_CHECK_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut: $file"
  else
    fail_soft "$label yok: $file"
  fi
}

check_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail_soft "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail_soft "$label bulunamadi: $pattern"
  fi
}

check_done() {
  local item="$1"
  local pattern="$2"

  if grep -Fq "$pattern" "$DOC"; then
    DONE_CHECK_COUNT=$((DONE_CHECK_COUNT + 1))
    pass "$item"
  else
    fail_soft "$item"
  fi
}

check_json_expr() {
  local expr="$1"
  local label="$2"

  if python3 -c "import json; d=json.load(open('$JSON_FILE', encoding='utf-8')); $expr" >/dev/null 2>&1; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 5-6 LEGAL / COMPLIANCE / KVKK / TERMS TEST BASLADI ====="

check_file "$PREV_DOC" "5-5 tenant lifecycle dokumani"
check_file "$PREV_JSON" "5-5 tenant lifecycle json"
check_file "$DOC" "5-6 legal compliance dokumani"
check_file "$JSON_FILE" "5-6 legal compliance json"

check_grep "$PREV_DOC" "FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS=SEALED" "5-5 sealed"
check_grep "$PREV_DOC" "FAZ_5_6_READY=YES" "5-6 giris izni"

check_grep "$DOC" "STEP_NO=5-6" "step no"
check_grep "$DOC" "STEP_NAME=Legal / Compliance / KVKK / Terms" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_6_LEGAL_COMPLIANCE_STATUS=PASS" "5-6 pass"
check_grep "$DOC" "FAZ_5_6_LEGAL_COMPLIANCE_SEAL_STATUS=SEALED" "5-6 sealed"
check_grep "$DOC" "FAZ_5_7_READY=YES" "5-7 ready"

echo
echo "===== FAZ 5-6 YAPILAN ISLER KONTROLU ====="

check_done "5-6 — Legal / Compliance / KVKK / Terms" "FAZ 5-6 — Legal / Compliance / KVKK / Terms"

check_done "5-6.1 Yasal belge haritası" "### 5-6.1 Yasal belge haritası"
check_done "5-6.1.1 Kullanım şartları" "### 5-6.1.1 Kullanım şartları"
check_done "5-6.1.2 Gizlilik politikası" "### 5-6.1.2 Gizlilik politikası"
check_done "5-6.1.3 KVKK aydınlatma metni" "### 5-6.1.3 KVKK aydınlatma metni"
check_done "5-6.1.4 Çerez politikası" "### 5-6.1.4 Çerez politikası"
check_done "5-6.1.5 Mesafeli satış / hizmet sözleşmesi notu" "### 5-6.1.5 Mesafeli satış / hizmet sözleşmesi notu"
check_done "5-6.1.6 Veri işleme sözleşmesi" "### 5-6.1.6 Veri işleme sözleşmesi"
check_done "5-6.1.7 Muhasebeci portal sözleşme notu" "### 5-6.1.7 Muhasebeci portal sözleşme notu"

check_done "5-6.2 Veri politikaları" "### 5-6.2 Veri politikaları"
check_done "5-6.2.1 Veri saklama politikası" "### 5-6.2.1 Veri saklama politikası"
check_done "5-6.2.2 Veri silme politikası" "### 5-6.2.2 Veri silme politikası"
check_done "5-6.2.3 Veri export politikası" "### 5-6.2.3 Veri export politikası"
check_done "5-6.2.4 Backup retention ilişkisi" "### 5-6.2.4 Backup retention ilişkisi"
check_done "5-6.2.5 Tenant kapanışında veri akışı" "### 5-6.2.5 Tenant kapanışında veri akışı"
check_done "5-6.2.6 Kişisel veri erişim talebi akışı" "### 5-6.2.6 Kişisel veri erişim talebi akışı"

check_done "5-6.3 Public legal surface" "### 5-6.3 Public legal surface"
check_done "5-6.3.1 Footer legal link haritası" "### 5-6.3.1 Footer legal link haritası"
check_done "5-6.3.2 Pricing sayfası yasal notlar" "### 5-6.3.2 Pricing sayfası yasal notlar"
check_done "5-6.3.3 Demo kayıt yasal onay kutuları" "### 5-6.3.3 Demo kayıt yasal onay kutuları"
check_done "5-6.3.4 Abonelik yasal onay kutuları" "### 5-6.3.4 Abonelik yasal onay kutuları"
check_done "5-6.3.5 KVKK açık rıza ayrımı" "### 5-6.3.5 KVKK açık rıza ayrımı"
check_done "5-6.3.6 Ticari iletişim izni" "### 5-6.3.6 Ticari iletişim izni"

check_done "5-6.4 Açık hukuk işleri" "### 5-6.4 Açık hukuk işleri"
check_done "5-6.4.1 Profesyonel hukukçu incelemesi" "### 5-6.4.1 Profesyonel hukukçu incelemesi"
check_done "5-6.4.2 KVKK danışmanı incelemesi" "### 5-6.4.2 KVKK danışmanı incelemesi"
check_done "5-6.4.3 Vergi / mali müşavir incelemesi" "### 5-6.4.3 Vergi / mali müşavir incelemesi"
check_done "5-6.4.4 Enterprise sözleşme taslağı" "### 5-6.4.4 Enterprise sözleşme taslağı"
check_done "5-6.4.5 Muhasebeci portal özel sözleşme" "### 5-6.4.5 Muhasebeci portal özel sözleşme"

check_done "5-6.5 Test / mühür" "### 5-6.5 Test / mühür"
check_done "5-6.5.1 Legal checklist doc test" "### 5-6.5.1 Legal checklist doc test"
check_done "5-6.5.2 Legal JSON map test" "### 5-6.5.2 Legal JSON map test"
check_done "5-6.5.3 Required links test" "### 5-6.5.3 Required links test"
check_done "5-6.5.4 Open legal issue test" "### 5-6.5.4 Open legal issue test"
check_done "5-6.5.5 Report üretimi" "### 5-6.5.5 Report üretimi"
check_done "5-6.5.6 5-7 geçiş izni" "### 5-6.5.6 5-7 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_legal_compliance_policy_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-6'" "step dogru"
check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert 'pix2pi_subscription_billing_policy_v1' in d['depends_on']" "subscription dependency dogru"
check_json_expr "assert 'pix2pi_tenant_lifecycle_policy_v1' in d['depends_on']" "tenant lifecycle dependency dogru"

check_json_expr "docs={x['code']:x for x in d['legal_document_map']}; assert docs['terms_of_service']['required'] is True" "terms required"
check_json_expr "docs={x['code']:x for x in d['legal_document_map']}; assert docs['privacy_policy']['public_link_required'] is True" "privacy public link"
check_json_expr "docs={x['code']:x for x in d['legal_document_map']}; assert docs['kvkk_notice']['professional_review_required'] is True" "kvkk review required"
check_json_expr "docs={x['code']:x for x in d['legal_document_map']}; assert docs['cookie_policy']['required'] is True" "cookie required"
check_json_expr "docs={x['code']:x for x in d['legal_document_map']}; assert docs['data_processing_agreement']['required'] is True" "dpa required"
check_json_expr "docs={x['code']:x for x in d['legal_document_map']}; assert docs['accountant_portal_terms']['required'] is True" "accountant terms required"

check_json_expr "assert d['data_policies']['retention_policy_required'] is True" "retention policy required"
check_json_expr "assert d['data_policies']['deletion_policy_required'] is True" "deletion policy required"
check_json_expr "assert d['data_policies']['export_policy_required'] is True" "export policy required"
check_json_expr "assert d['data_policies']['backup_retention_alignment_required'] is True" "backup retention alignment"
check_json_expr "assert d['data_policies']['tenant_close_data_flow_required'] is True" "tenant close data flow"
check_json_expr "assert d['data_policies']['personal_data_request_flow_required'] is True" "personal data request flow"
check_json_expr "assert 'excel' in d['data_policies']['export_formats']" "export excel"
check_json_expr "assert 'pdf' in d['data_policies']['export_formats']" "export pdf"
check_json_expr "assert 'tdhp' in d['data_policies']['export_formats']" "export tdhp"
check_json_expr "assert 'accountant_handoff_file' in d['data_policies']['export_formats']" "export accountant handoff"

check_json_expr "assert 'terms_of_service' in d['public_legal_surface']['footer_links']" "footer terms"
check_json_expr "assert 'privacy_policy' in d['public_legal_surface']['footer_links']" "footer privacy"
check_json_expr "assert 'kvkk_notice' in d['public_legal_surface']['footer_links']" "footer kvkk"
check_json_expr "assert 'cookie_policy' in d['public_legal_surface']['footer_links']" "footer cookie"
check_json_expr "assert 'vat_note' in d['public_legal_surface']['pricing_page_notes']" "pricing vat note"
check_json_expr "assert 'accept_terms' in d['public_legal_surface']['demo_signup_checkboxes']" "demo accept terms"
check_json_expr "assert 'commercial_communication_optional' in d['public_legal_surface']['demo_signup_checkboxes']" "commercial communication optional"
check_json_expr "assert d['public_legal_surface']['explicit_consent_must_be_separate'] is True" "explicit consent separate"
check_json_expr "assert d['public_legal_surface']['commercial_communication_must_be_separate'] is True" "commercial communication separate"

check_json_expr "reviews={x['code']:x for x in d['open_legal_reviews']}; assert reviews['lawyer_review']['required_before_public_launch'] is True" "lawyer review required"
check_json_expr "reviews={x['code']:x for x in d['open_legal_reviews']}; assert reviews['kvkk_consultant_review']['required_before_public_launch'] is True" "kvkk consultant review required"
check_json_expr "reviews={x['code']:x for x in d['open_legal_reviews']}; assert reviews['tax_advisor_review']['required_before_public_launch'] is True" "tax advisor review required"
check_json_expr "reviews={x['code']:x for x in d['open_legal_reviews']}; assert reviews['enterprise_contract_template']['required_before_enterprise_sale'] is True" "enterprise contract required"
check_json_expr "reviews={x['code']:x for x in d['open_legal_reviews']}; assert reviews['accountant_portal_contract']['required_before_accountant_package_sale'] is True" "accountant contract required"

check_json_expr "assert d['approval_gates']['technical_checklist_status']=='ready'" "technical checklist ready"
check_json_expr "assert d['approval_gates']['legal_final_approval_status']=='open'" "legal approval open"
check_json_expr "assert d['approval_gates']['kvkk_final_approval_status']=='open'" "kvkk approval open"
check_json_expr "assert d['approval_gates']['tax_final_approval_status']=='open'" "tax approval open"
check_json_expr "assert d['approval_gates']['public_launch_allowed_without_professional_review'] is False" "public launch without review false"

check_json_expr "assert 'final_lawyer_approved_contract_text' in d['out_of_scope']" "out of scope final lawyer text"
check_json_expr "assert 'final_kvkk_consultant_approval' in d['out_of_scope']" "out of scope final kvkk approval"
check_json_expr "assert 'runtime_cookie_consent' in d['out_of_scope']" "out of scope cookie runtime"
check_json_expr "assert 'runtime_kvkk_request_panel' in d['out_of_scope']" "out of scope kvkk panel"
check_json_expr "assert d['seal']['FAZ_5_6_LEGAL_COMPLIANCE_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_6_LEGAL_COMPLIANCE_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_7_READY']=='YES'" "json 5-7 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP7_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP7_READY="NO ❌"
fi

{
  echo "FAZ_5_6_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_6_LEGAL_COMPLIANCE_STATUS=$STEP_STATUS"
  echo "FAZ_5_6_LEGAL_COMPLIANCE_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_6_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_6_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_6_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_6_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_7_READY=$STEP7_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-6 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-6 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-6 LEGAL / COMPLIANCE / KVKK / TERMS TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-6 LEGAL / COMPLIANCE / KVKK / TERMS TEST SONUCU: HATA ❌ ====="
  exit 1
fi
