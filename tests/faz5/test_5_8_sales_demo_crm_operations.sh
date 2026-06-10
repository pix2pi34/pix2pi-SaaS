#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_7_support_sla_incident_escalation.md"
PREV_JSON="configs/faz5/support_sla_incident_policy_v1.json"
DOC="docs/faz5/5_8_sales_demo_crm_operations.md"
JSON_FILE="configs/faz5/sales_demo_crm_policy_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_8_SALES_DEMO_CRM_OPERATIONS_REPORT.txt"

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

echo "===== FAZ 5-8 SALES / DEMO / CRM OPERATIONS TEST BASLADI ====="

check_file "$PREV_DOC" "5-7 support sla dokumani"
check_file "$PREV_JSON" "5-7 support sla json"
check_file "$DOC" "5-8 sales demo crm dokumani"
check_file "$JSON_FILE" "5-8 sales demo crm json"

check_grep "$PREV_DOC" "FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=SEALED" "5-7 sealed"
check_grep "$PREV_DOC" "FAZ_5_8_READY=YES" "5-8 giris izni"

check_grep "$DOC" "STEP_NO=5-8" "step no"
check_grep "$DOC" "STEP_NAME=Sales / Demo / CRM Operations" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_8_SALES_DEMO_CRM_STATUS=PASS" "5-8 pass"
check_grep "$DOC" "FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=SEALED" "5-8 sealed"
check_grep "$DOC" "FAZ_5_9_READY=YES" "5-9 ready"

echo
echo "===== FAZ 5-8 YAPILAN ISLER KONTROLU ====="

check_done "5-8 — Sales / Demo / CRM Operations" "FAZ 5-8 — Sales / Demo / CRM Operations"

check_done "5-8.1 Lead yönetimi" "### 5-8.1 Lead yönetimi"
check_done "5-8.1.1 Lead created" "### 5-8.1.1 Lead created"
check_done "5-8.1.2 Lead qualified" "### 5-8.1.2 Lead qualified"
check_done "5-8.1.3 Demo scheduled" "### 5-8.1.3 Demo scheduled"
check_done "5-8.1.4 Proposal sent" "### 5-8.1.4 Proposal sent"
check_done "5-8.1.5 Negotiation" "### 5-8.1.5 Negotiation"
check_done "5-8.1.6 Won" "### 5-8.1.6 Won"
check_done "5-8.1.7 Lost" "### 5-8.1.7 Lost"

check_done "5-8.2 Demo tenant akışı" "### 5-8.2 Demo tenant akışı"
check_done "5-8.2.1 Demo başvuru" "### 5-8.2.1 Demo başvuru"
check_done "5-8.2.2 Demo tenant oluşturma" "### 5-8.2.2 Demo tenant oluşturma"
check_done "5-8.2.3 Demo kullanıcı daveti" "### 5-8.2.3 Demo kullanıcı daveti"
check_done "5-8.2.4 Demo veri seti" "### 5-8.2.4 Demo veri seti"
check_done "5-8.2.5 Demo süre takibi" "### 5-8.2.5 Demo süre takibi"
check_done "5-8.2.6 Demo → paid dönüşüm" "### 5-8.2.6 Demo → paid dönüşüm"

check_done "5-8.3 Teklif operasyonu" "### 5-8.3 Teklif operasyonu"
check_done "5-8.3.1 Starter teklif" "### 5-8.3.1 Starter teklif"
check_done "5-8.3.2 Pro teklif" "### 5-8.3.2 Pro teklif"
check_done "5-8.3.3 Enterprise teklif" "### 5-8.3.3 Enterprise teklif"
check_done "5-8.3.4 Muhasebeci teklif" "### 5-8.3.4 Muhasebeci teklif"
check_done "5-8.3.5 İndirim kuralları" "### 5-8.3.5 İndirim kuralları"
check_done "5-8.3.6 Teklif geçerlilik süresi" "### 5-8.3.6 Teklif geçerlilik süresi"

check_done "5-8.4 Satış kapanış akışı" "### 5-8.4 Satış kapanış akışı"
check_done "5-8.4.1 Paket seçimi" "### 5-8.4.1 Paket seçimi"
check_done "5-8.4.2 Sözleşme / onay" "### 5-8.4.2 Sözleşme / onay"
check_done "5-8.4.3 İlk ödeme" "### 5-8.4.3 İlk ödeme"
check_done "5-8.4.4 Tenant aktivasyonu" "### 5-8.4.4 Tenant aktivasyonu"
check_done "5-8.4.5 Onboarding başlatma" "### 5-8.4.5 Onboarding başlatma"
check_done "5-8.4.6 Support kanalına alma" "### 5-8.4.6 Support kanalına alma"

check_done "5-8.5 CRM JSON contract" "### 5-8.5 CRM JSON contract"
check_done "5-8.5.1 Lead state catalog" "### 5-8.5.1 Lead state catalog"
check_done "5-8.5.2 Demo state catalog" "### 5-8.5.2 Demo state catalog"
check_done "5-8.5.3 Proposal state catalog" "### 5-8.5.3 Proposal state catalog"
check_done "5-8.5.4 Won / lost reason catalog" "### 5-8.5.4 Won / lost reason catalog"
check_done "5-8.5.5 Sales handoff checklist" "### 5-8.5.5 Sales handoff checklist"

check_done "5-8.6 Test / mühür" "### 5-8.6 Test / mühür"
check_done "5-8.6.1 Sales doc test" "### 5-8.6.1 Sales doc test"
check_done "5-8.6.2 CRM JSON test" "### 5-8.6.2 CRM JSON test"
check_done "5-8.6.3 Demo flow test" "### 5-8.6.3 Demo flow test"
check_done "5-8.6.4 Proposal flow test" "### 5-8.6.4 Proposal flow test"
check_done "5-8.6.5 Report üretimi" "### 5-8.6.5 Report üretimi"
check_done "5-8.6.6 5-9 geçiş izni" "### 5-8.6.6 5-9 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_sales_demo_crm_policy_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-8'" "step dogru"
check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert 'pix2pi_subscription_billing_policy_v1' in d['depends_on']" "subscription dependency dogru"
check_json_expr "assert 'pix2pi_tenant_lifecycle_policy_v1' in d['depends_on']" "tenant lifecycle dependency dogru"
check_json_expr "assert 'pix2pi_legal_compliance_policy_v1' in d['depends_on']" "legal dependency dogru"
check_json_expr "assert 'pix2pi_support_sla_incident_policy_v1' in d['depends_on']" "support dependency dogru"

check_json_expr "assert 'lead_created' in d['lead_states']" "lead state created"
check_json_expr "assert 'lead_qualified' in d['lead_states']" "lead state qualified"
check_json_expr "assert 'demo_scheduled' in d['lead_states']" "lead state demo scheduled"
check_json_expr "assert 'proposal_sent' in d['lead_states']" "lead state proposal sent"
check_json_expr "assert 'negotiation' in d['lead_states']" "lead state negotiation"
check_json_expr "assert 'won' in d['lead_states']" "lead state won"
check_json_expr "assert 'lost' in d['lead_states']" "lead state lost"

check_json_expr "assert 'web_form' in d['lead_sources']" "lead source web form"
check_json_expr "assert 'phone_whatsapp' in d['lead_sources']" "lead source phone whatsapp"
check_json_expr "assert 'referral' in d['lead_sources']" "lead source referral"
check_json_expr "assert 'accountant_referral' in d['lead_sources']" "lead source accountant referral"

check_json_expr "assert 'business_type' in d['qualification_fields']" "qualification business type"
check_json_expr "assert 'branch_count' in d['qualification_fields']" "qualification branch count"
check_json_expr "assert 'user_count' in d['qualification_fields']" "qualification user count"
check_json_expr "assert 'package_potential' in d['qualification_fields']" "qualification package potential"

check_json_expr "assert d['demo_flow']['default_package']=='demo'" "demo default package"
check_json_expr "assert d['demo_flow']['trial_days']==14" "demo trial 14"
check_json_expr "assert d['demo_flow']['max_users']==2" "demo max users 2"
check_json_expr "assert d['demo_flow']['live_financial_operation'] is False" "demo live finance false"
check_json_expr "assert d['demo_flow']['api_access']=='disabled'" "demo api disabled"
check_json_expr "assert d['demo_flow']['export_access']=='disabled'" "demo export disabled"
check_json_expr "assert d['demo_flow']['demo_dataset_allowed'] is True" "demo dataset allowed"
check_json_expr "assert 'starter' in d['demo_flow']['conversion_targets']" "demo convert starter"
check_json_expr "assert 'pro' in d['demo_flow']['conversion_targets']" "demo convert pro"
check_json_expr "assert 'enterprise' in d['demo_flow']['conversion_targets']" "demo convert enterprise"
check_json_expr "assert 'accountant' in d['demo_flow']['conversion_targets']" "demo convert accountant"

check_json_expr "assert 'draft' in d['proposal_flow']['proposal_states']" "proposal state draft"
check_json_expr "assert 'sent' in d['proposal_flow']['proposal_states']" "proposal state sent"
check_json_expr "assert 'accepted' in d['proposal_flow']['proposal_states']" "proposal state accepted"
check_json_expr "assert 'expired' in d['proposal_flow']['proposal_states']" "proposal state expired"
check_json_expr "assert d['proposal_flow']['default_validity_days']['starter']==7" "starter proposal 7 days"
check_json_expr "assert d['proposal_flow']['default_validity_days']['pro']==7" "pro proposal 7 days"
check_json_expr "assert d['proposal_flow']['default_validity_days']['enterprise']==15" "enterprise proposal 15 days"
check_json_expr "assert d['proposal_flow']['default_validity_days']['accountant']==15" "accountant proposal 15 days"
check_json_expr "assert 'package_code' in d['proposal_flow']['required_fields']" "proposal package code"
check_json_expr "assert 'price' in d['proposal_flow']['required_fields']" "proposal price"
check_json_expr "assert 'tax_note' in d['proposal_flow']['required_fields']" "proposal tax note"
check_json_expr "assert 'annual_payment_discount' in d['proposal_flow']['discount_types']" "discount annual"
check_json_expr "assert 'pilot_customer_discount' in d['proposal_flow']['discount_types']" "discount pilot"
check_json_expr "assert 'accountant_multi_company_discount' in d['proposal_flow']['discount_types']" "discount accountant"

check_json_expr "assert 'package_selection' in d['sales_close_flow']['required_steps']" "close package selection"
check_json_expr "assert 'legal_acceptance' in d['sales_close_flow']['required_steps']" "close legal acceptance"
check_json_expr "assert 'first_payment_or_manual_approval' in d['sales_close_flow']['required_steps']" "close first payment"
check_json_expr "assert 'tenant_activation' in d['sales_close_flow']['required_steps']" "close tenant activation"
check_json_expr "assert 'onboarding_start' in d['sales_close_flow']['required_steps']" "close onboarding"
check_json_expr "assert 'support_channel_assignment' in d['sales_close_flow']['required_steps']" "close support assignment"
check_json_expr "assert 'package_code' in d['sales_close_flow']['activation_dependencies']" "activation package code"
check_json_expr "assert 'subscription_state' in d['sales_close_flow']['activation_dependencies']" "activation subscription"
check_json_expr "assert 'entitlement_profile' in d['sales_close_flow']['activation_dependencies']" "activation entitlement"
check_json_expr "assert 'tenant_owner' in d['sales_close_flow']['activation_dependencies']" "activation owner"
check_json_expr "assert 'first_user' in d['sales_close_flow']['activation_dependencies']" "activation first user"
check_json_expr "assert 'revenue_metrics' in d['sales_close_flow']['handoff_targets']" "handoff revenue metrics"

check_json_expr "assert 'price_fit' in d['won_reasons']" "won reason price fit"
check_json_expr "assert 'feature_fit' in d['won_reasons']" "won reason feature fit"
check_json_expr "assert 'pos_erp_unified_need' in d['won_reasons']" "won reason pos erp"
check_json_expr "assert 'price' in d['lost_reasons']" "lost reason price"
check_json_expr "assert 'missing_feature' in d['lost_reasons']" "lost reason feature"
check_json_expr "assert 'competitor' in d['lost_reasons']" "lost reason competitor"

check_json_expr "assert 'customer_identity' in d['sales_handoff_checklist']" "handoff customer identity"
check_json_expr "assert 'selected_package' in d['sales_handoff_checklist']" "handoff selected package"
check_json_expr "assert 'billing_cycle' in d['sales_handoff_checklist']" "handoff billing cycle"
check_json_expr "assert 'payment_status' in d['sales_handoff_checklist']" "handoff payment status"
check_json_expr "assert 'support_level' in d['sales_handoff_checklist']" "handoff support level"
check_json_expr "assert 'legal_acceptance_status' in d['sales_handoff_checklist']" "handoff legal acceptance"

check_json_expr "assert 'real_crm_app_setup' in d['out_of_scope']" "out of scope crm app"
check_json_expr "assert 'runtime_demo_tenant_automation' in d['out_of_scope']" "out of scope demo runtime"
check_json_expr "assert 'proposal_pdf_generation' in d['out_of_scope']" "out of scope proposal pdf"
check_json_expr "assert 'payment_link_generation' in d['out_of_scope']" "out of scope payment link"
check_json_expr "assert d['seal']['FAZ_5_8_SALES_DEMO_CRM_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_9_READY']=='YES'" "json 5-9 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP9_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP9_READY="NO ❌"
fi

{
  echo "FAZ_5_8_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_8_SALES_DEMO_CRM_STATUS=$STEP_STATUS"
  echo "FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_8_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_8_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_8_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_8_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_9_READY=$STEP9_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-8 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-8 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-8 SALES / DEMO / CRM OPERATIONS TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-8 SALES / DEMO / CRM OPERATIONS TEST SONUCU: HATA ❌ ====="
  exit 1
fi
