#!/usr/bin/env bash
set -u

DOC="docs/faz5/5_11_commercial_readiness_test_suite.md"
JSON_FILE="configs/faz5/commercial_readiness_suite_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_11_COMMERCIAL_READINESS_TEST_SUITE_REPORT.txt"

PACKAGES_JSON="configs/faz5/packages_pricing_v1.json"
ENTITLEMENT_JSON="configs/faz5/entitlement_matrix_v1.json"
BILLING_JSON="configs/faz5/subscription_billing_policy_v1.json"
TENANT_JSON="configs/faz5/tenant_lifecycle_policy_v1.json"
LEGAL_JSON="configs/faz5/legal_compliance_policy_v1.json"
SUPPORT_JSON="configs/faz5/support_sla_incident_policy_v1.json"
SALES_JSON="configs/faz5/sales_demo_crm_policy_v1.json"
REVENUE_JSON="configs/faz5/revenue_metrics_policy_v1.json"
PUBLIC_JSON="configs/faz5/public_pricing_developer_surface_v1.json"

FAIL_COUNT=0
OK_COUNT=0
DONE_CHECK_COUNT=0
BLOCKER_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

blocker() {
  BLOCKER_COUNT=$((BLOCKER_COUNT + 1))
  fail_soft "$1"
}

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut: $file"
  else
    blocker "$label yok: $file"
  fi
}

check_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    blocker "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    blocker "$label bulunamadi: $pattern"
  fi
}

check_done() {
  local item="$1"
  local pattern="$2"

  if grep -Fq "$pattern" "$DOC"; then
    DONE_CHECK_COUNT=$((DONE_CHECK_COUNT + 1))
    pass "$item"
  else
    blocker "$item"
  fi
}

check_json_file_expr() {
  local file="$1"
  local expr="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    blocker "$label json dosya yok: $file"
    return
  fi

  if python3 -c "import json; d=json.load(open('$file', encoding='utf-8')); $expr" >/dev/null 2>&1; then
    pass "$label"
  else
    blocker "$label"
  fi
}

check_url_marker() {
  local url="$1"
  local marker="$2"
  local label="$3"
  local tmp_file="$4"

  local status
  status="$(curl -k -L -sS \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o "$tmp_file" \
    -w "%{http_code}" \
    "$url")"

  echo "URL=$url"
  echo "HTTP_STATUS=$status"

  if [ "$status" = "200" ]; then
    pass "$label HTTP 200"
  else
    blocker "$label HTTP 200 degil: $status"
  fi

  if grep -Fq "$marker" "$tmp_file"; then
    pass "$label marker dogru"
  else
    blocker "$label marker donmedi: $marker"
  fi
}

echo "===== FAZ 5-11 COMMERCIAL READINESS TEST SUITE BASLADI ====="

echo
echo "===== ANA DOSYA KONTROLU ====="

check_file "$DOC" "5-11 commercial readiness dokumani"
check_file "$JSON_FILE" "5-11 commercial readiness json"

check_grep "$DOC" "STEP_NO=5-11" "step no"
check_grep "$DOC" "STEP_NAME=Commercial Readiness Test Suite" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_11_COMMERCIAL_READINESS_STATUS=PASS" "5-11 pass"
check_grep "$DOC" "FAZ_5_11_COMMERCIAL_READINESS_SEAL_STATUS=SEALED" "5-11 sealed"
check_grep "$DOC" "FAZ_5_12_READY=YES" "5-12 ready"

echo
echo "===== FAZ 5-11 YAPILAN ISLER KONTROLU ====="

check_done "5-11 — Commercial Readiness Test Suite" "FAZ 5-11 — Commercial Readiness Test Suite"

check_done "5-11.1 Paket readiness testleri" "### 5-11.1 Paket readiness testleri"
check_done "5-11.1.1 Paket catalog testi" "### 5-11.1.1 Paket catalog testi"
check_done "5-11.1.2 Fiyat catalog testi" "### 5-11.1.2 Fiyat catalog testi"
check_done "5-11.1.3 Paket kodları testi" "### 5-11.1.3 Paket kodları testi"
check_done "5-11.1.4 Yıllık / aylık tutarlılık testi" "### 5-11.1.4 Yıllık / aylık tutarlılık testi"

check_done "5-11.2 Entitlement readiness testleri" "### 5-11.2 Entitlement readiness testleri"
check_done "5-11.2.1 Demo hak testi" "### 5-11.2.1 Demo hak testi"
check_done "5-11.2.2 Starter hak testi" "### 5-11.2.2 Starter hak testi"
check_done "5-11.2.3 Pro hak testi" "### 5-11.2.3 Pro hak testi"
check_done "5-11.2.4 Enterprise hak testi" "### 5-11.2.4 Enterprise hak testi"
check_done "5-11.2.5 Accountant hak testi" "### 5-11.2.5 Accountant hak testi"
check_done "5-11.2.6 Subscription state testi" "### 5-11.2.6 Subscription state testi"
check_done "5-11.2.7 Freeze policy testi" "### 5-11.2.7 Freeze policy testi"

check_done "5-11.3 Billing readiness testleri" "### 5-11.3 Billing readiness testleri"
check_done "5-11.3.1 Subscription lifecycle test" "### 5-11.3.1 Subscription lifecycle test"
check_done "5-11.3.2 Payment state test" "### 5-11.3.2 Payment state test"
check_done "5-11.3.3 Past due test" "### 5-11.3.3 Past due test"
check_done "5-11.3.4 Suspended test" "### 5-11.3.4 Suspended test"
check_done "5-11.3.5 Cancelled test" "### 5-11.3.5 Cancelled test"
check_done "5-11.3.6 Accountant company billing test" "### 5-11.3.6 Accountant company billing test"

check_done "5-11.4 Tenant lifecycle readiness testleri" "### 5-11.4 Tenant lifecycle readiness testleri"
check_done "5-11.4.1 Tenant open test" "### 5-11.4.1 Tenant open test"
check_done "5-11.4.2 Tenant upgrade test" "### 5-11.4.2 Tenant upgrade test"
check_done "5-11.4.3 Tenant downgrade test" "### 5-11.4.3 Tenant downgrade test"
check_done "5-11.4.4 Tenant freeze test" "### 5-11.4.4 Tenant freeze test"
check_done "5-11.4.5 Tenant close test" "### 5-11.4.5 Tenant close test"
check_done "5-11.4.6 Data handoff test" "### 5-11.4.6 Data handoff test"

check_done "5-11.5 Legal / support / sales readiness testleri" "### 5-11.5 Legal / support / sales readiness testleri"
check_done "5-11.5.1 Legal checklist test" "### 5-11.5.1 Legal checklist test"
check_done "5-11.5.2 Support SLA test" "### 5-11.5.2 Support SLA test"
check_done "5-11.5.3 Incident class test" "### 5-11.5.3 Incident class test"
check_done "5-11.5.4 Sales CRM test" "### 5-11.5.4 Sales CRM test"
check_done "5-11.5.5 Demo flow test" "### 5-11.5.5 Demo flow test"

check_done "5-11.6 Public readiness testleri" "### 5-11.6 Public readiness testleri"
check_done "5-11.6.1 Pricing page test" "### 5-11.6.1 Pricing page test"
check_done "5-11.6.2 Developer surface test" "### 5-11.6.2 Developer surface test"
check_done "5-11.6.3 Legal links test" "### 5-11.6.3 Legal links test"
check_done "5-11.6.4 Mobile responsive test" "### 5-11.6.4 Mobile responsive test"
check_done "5-11.6.5 Public publish readiness test" "### 5-11.6.5 Public publish readiness test"

check_done "5-11.7 Commercial readiness runner" "### 5-11.7 Commercial readiness runner"
check_done "5-11.7.1 Tüm 5-x raporları kontrol" "### 5-11.7.1 Tüm 5-x raporları kontrol"
check_done "5-11.7.2 Tüm JSON catalog kontrol" "### 5-11.7.2 Tüm JSON catalog kontrol"
check_done "5-11.7.3 Tüm doc seal kontrol" "### 5-11.7.3 Tüm doc seal kontrol"
check_done "5-11.7.4 Blocker count kontrol" "### 5-11.7.4 Blocker count kontrol"
check_done "5-11.7.5 Final readiness raporu" "### 5-11.7.5 Final readiness raporu"
check_done "5-11.7.6 5-12 geçiş izni" "### 5-11.7.6 5-12 geçiş izni"

echo
echo "===== 5-1 / 5-10 DOC SEAL KONTROLU ====="

check_file "docs/faz5/5_1_commercial_master_plan_scope_freeze.md" "5-1 doc"
check_file "docs/faz5/5_2_packages_pricing_architecture.md" "5-2 doc"
check_file "docs/faz5/5_3_entitlement_matrix_module_rights.md" "5-3 doc"
check_file "docs/faz5/5_4_subscription_billing_payment_ops.md" "5-4 doc"
check_file "docs/faz5/5_5_tenant_lifecycle_commercial_ops.md" "5-5 doc"
check_file "docs/faz5/5_6_legal_compliance_kvkk_terms.md" "5-6 doc"
check_file "docs/faz5/5_7_support_sla_incident_escalation.md" "5-7 doc"
check_file "docs/faz5/5_8_sales_demo_crm_operations.md" "5-8 doc"
check_file "docs/faz5/5_9_revenue_metrics_mrr_arr_churn.md" "5-9 doc"
check_file "docs/faz5/5_10_public_pricing_developer_surfaces.md" "5-10 doc"

check_grep "docs/faz5/5_1_commercial_master_plan_scope_freeze.md" "FAZ_5_1_SCOPE_FREEZE_SEAL_STATUS=SEALED" "5-1 sealed"
check_grep "docs/faz5/5_2_packages_pricing_architecture.md" "FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS=SEALED" "5-2 sealed"
check_grep "docs/faz5/5_3_entitlement_matrix_module_rights.md" "FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=SEALED" "5-3 sealed"
check_grep "docs/faz5/5_4_subscription_billing_payment_ops.md" "FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=SEALED" "5-4 sealed"
check_grep "docs/faz5/5_5_tenant_lifecycle_commercial_ops.md" "FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS=SEALED" "5-5 sealed"
check_grep "docs/faz5/5_6_legal_compliance_kvkk_terms.md" "FAZ_5_6_LEGAL_COMPLIANCE_SEAL_STATUS=SEALED" "5-6 sealed"
check_grep "docs/faz5/5_7_support_sla_incident_escalation.md" "FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=SEALED" "5-7 sealed"
check_grep "docs/faz5/5_8_sales_demo_crm_operations.md" "FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=SEALED" "5-8 sealed"
check_grep "docs/faz5/5_9_revenue_metrics_mrr_arr_churn.md" "FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=SEALED" "5-9 sealed"
check_grep "docs/faz5/5_10_public_pricing_developer_surfaces.md" "FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SEAL_STATUS=SEALED" "5-10 sealed"

echo
echo "===== JSON FORMAT VE ICERIK KONTROLU ====="

for jf in \
  "$PACKAGES_JSON" \
  "$ENTITLEMENT_JSON" \
  "$BILLING_JSON" \
  "$TENANT_JSON" \
  "$LEGAL_JSON" \
  "$SUPPORT_JSON" \
  "$SALES_JSON" \
  "$REVENUE_JSON" \
  "$PUBLIC_JSON" \
  "$JSON_FILE"
do
  if python3 -m json.tool "$jf" >/dev/null 2>&1; then
    pass "json format gecerli: $jf"
  else
    blocker "json format bozuk: $jf"
  fi
done

check_json_file_expr "$PACKAGES_JSON" "codes=sorted([p['code'] for p in d['packages']]); assert codes==sorted(['demo','starter','pro','enterprise','accountant'])" "5-11.1.1 package catalog"
check_json_file_expr "$PACKAGES_JSON" "p={x['code']:x for x in d['packages']}; assert p['starter']['monthly_try']==799 and p['pro']['monthly_try']==1999 and p['accountant']['monthly_try']==999" "5-11.1.2 pricing catalog"
check_json_file_expr "$PACKAGES_JSON" "codes=[p['code'] for p in d['packages']]; assert all(c.isascii() and c==c.lower() for c in codes)" "5-11.1.3 package codes"
check_json_file_expr "$PACKAGES_JSON" "p={x['code']:x for x in d['packages']}; assert p['starter']['annual_try']<=p['starter']['monthly_try']*12 and p['pro']['annual_try']<=p['pro']['monthly_try']*12" "5-11.1.4 annual monthly consistency"

check_json_file_expr "$ENTITLEMENT_JSON" "p={x['code']:x for x in d['packages']}; assert p['demo']['modules']['api_access']=='disabled' and p['demo']['live_financial_operation'] is False" "5-11.2.1 demo rights"
check_json_file_expr "$ENTITLEMENT_JSON" "p={x['code']:x for x in d['packages']}; assert p['starter']['modules']['erp_core']=='enabled' and p['starter']['modules']['api_access']=='disabled'" "5-11.2.2 starter rights"
check_json_file_expr "$ENTITLEMENT_JSON" "p={x['code']:x for x in d['packages']}; assert p['pro']['modules']['reporting_advanced']=='enabled' and p['pro']['modules']['api_access']=='limited'" "5-11.2.3 pro rights"
check_json_file_expr "$ENTITLEMENT_JSON" "p={x['code']:x for x in d['packages']}; assert p['enterprise']['modules']['api_access']=='enabled' and p['enterprise']['custom_override_allowed'] is True" "5-11.2.4 enterprise rights"
check_json_file_expr "$ENTITLEMENT_JSON" "p={x['code']:x for x in d['packages']}; assert p['accountant']['modules']['accountant_portal']=='enabled' and p['accountant']['company_based_billing'] is True" "5-11.2.5 accountant rights"
check_json_file_expr "$ENTITLEMENT_JSON" "assert d['subscription_state_policy']['active']=='full_package_rights' and d['subscription_state_policy']['suspended']=='commercial_access_restricted'" "5-11.2.6 subscription state"
check_json_file_expr "$ENTITLEMENT_JSON" "assert d['freeze_policy']['delete_data'] is False and d['freeze_policy']['api_access_on_suspend']=='disabled'" "5-11.2.7 freeze policy"

check_json_file_expr "$BILLING_JSON" "assert 'trialing' in d['subscription_states'] and 'active' in d['subscription_states'] and 'enterprise_hold' in d['subscription_states']" "5-11.3.1 subscription lifecycle"
check_json_file_expr "$BILLING_JSON" "assert 'pending' in d['payment_states'] and 'paid' in d['payment_states'] and 'manual_review' in d['payment_states']" "5-11.3.2 payment state"
check_json_file_expr "$BILLING_JSON" "assert d['subscription_to_entitlement_effect']['past_due']=='restricted_write_possible'" "5-11.3.3 past due"
check_json_file_expr "$BILLING_JSON" "assert d['subscription_to_entitlement_effect']['suspended']=='commercial_access_restricted'" "5-11.3.4 suspended"
check_json_file_expr "$BILLING_JSON" "assert d['subscription_to_entitlement_effect']['cancelled']=='commercial_access_closed'" "5-11.3.5 cancelled"
check_json_file_expr "$BILLING_JSON" "assert d['accountant_billing']['company_based_billing'] is True and d['accountant_billing']['per_company_monthly_try']==149" "5-11.3.6 accountant company billing"

check_json_file_expr "$TENANT_JSON" "assert d['open_flows']['demo_tenant']['default_package']=='demo' and d['open_flows']['paid_tenant']['requires_owner'] is True" "5-11.4.1 tenant open"
check_json_file_expr "$TENANT_JSON" "assert d['package_transitions']['starter_to_pro']['type']=='upgrade' and d['package_transitions']['pro_to_enterprise']['requires_contract'] is True" "5-11.4.2 tenant upgrade"
check_json_file_expr "$TENANT_JSON" "assert d['package_transitions']['pro_to_starter']['type']=='downgrade' and d['package_transitions']['pro_to_starter']['requires_limit_check'] is True" "5-11.4.3 tenant downgrade"
check_json_file_expr "$TENANT_JSON" "assert 'payment_delay' in d['freeze_reasons'] and 'security_risk' in d['freeze_reasons'] and d['freeze_policy']['write_access']=='disabled'" "5-11.4.4 tenant freeze"
check_json_file_expr "$TENANT_JSON" "assert 'customer_cancellation' in d['close_reasons'] and d['close_policy']['final_state']=='closed'" "5-11.4.5 tenant close"
check_json_file_expr "$TENANT_JSON" "assert d['data_handoff']['excel_export'] is True and d['data_handoff']['tdhp_export'] is True and d['data_handoff']['enterprise_custom_handoff'] is True" "5-11.4.6 data handoff"

check_json_file_expr "$LEGAL_JSON" "docs={x['code']:x for x in d['legal_document_map']}; assert docs['terms_of_service']['required'] is True and docs['kvkk_notice']['required'] is True" "5-11.5.1 legal checklist"
check_json_file_expr "$SUPPORT_JSON" "assert d['package_support_map']['demo']=='best_effort' and d['package_support_map']['enterprise']=='contract_sla'" "5-11.5.2 support SLA"
check_json_file_expr "$SUPPORT_JSON" "classes={x['code']:x for x in d['incident_classes']}; assert 'P0' in classes and 'P1' in classes and 'P4' in classes" "5-11.5.3 incident class"
check_json_file_expr "$SALES_JSON" "assert 'lead_created' in d['lead_states'] and 'won' in d['lead_states'] and 'lost' in d['lead_states']" "5-11.5.4 sales CRM"
check_json_file_expr "$SALES_JSON" "assert d['demo_flow']['trial_days']==14 and d['demo_flow']['max_users']==2 and d['demo_flow']['api_access']=='disabled'" "5-11.5.5 demo flow"

check_json_file_expr "$PUBLIC_JSON" "cards={x['code']:x for x in d['pricing_cards']}; assert cards['starter']['monthly_try']==799 and cards['pro']['monthly_try']==1999" "5-11.6.1 pricing page"
check_json_file_expr "$PUBLIC_JSON" "assert d['developer_surface']['developer_docs_landing'] is True and d['developer_surface']['webhook_docs_scope'] is True" "5-11.6.2 developer surface"
check_json_file_expr "$PUBLIC_JSON" "assert 'terms_of_service' in d['legal_footer_links'] and 'kvkk_notice' in d['legal_footer_links']" "5-11.6.3 legal links"
check_grep "web/faz5/pricing/index.html" "viewport" "5-11.6.4 pricing viewport"
check_grep "web/faz5/pricing/index.html" "@media" "5-11.6.4 pricing responsive"
check_grep "web/faz5/developer/index.html" "viewport" "5-11.6.4 developer viewport"
check_grep "web/faz5/developer/index.html" "@media" "5-11.6.4 developer responsive"

echo
echo "===== PUBLIC URL KONTROLU ====="

check_url_marker "https://pix2pi.com.tr/faz5/" "Pix2pi FAZ 5 Public Surfaces" "5-11.6.5 public faz5 index" "/tmp/pix2pi_5_11_faz5_index.html"
check_url_marker "https://pix2pi.com.tr/faz5/pricing/" "Public Pricing Surface" "5-11.6.5 public pricing" "/tmp/pix2pi_5_11_pricing.html"
check_url_marker "https://pix2pi.com.tr/faz5/developer/" "Developer Surface" "5-11.6.5 public developer" "/tmp/pix2pi_5_11_developer.html"

echo
echo "===== RAPOR DOSYALARI KONTROLU ====="

for rf in \
  reports/faz5/FAZ_5_3_ENTITLEMENT_MATRIX_REPORT.txt \
  reports/faz5/FAZ_5_4_SUBSCRIPTION_BILLING_PAYMENT_OPS_REPORT.txt \
  reports/faz5/FAZ_5_5_TENANT_LIFECYCLE_COMMERCIAL_OPS_REPORT.txt \
  reports/faz5/FAZ_5_6_LEGAL_COMPLIANCE_KVKK_TERMS_REPORT.txt \
  reports/faz5/FAZ_5_7_SUPPORT_SLA_INCIDENT_ESCALATION_REPORT.txt \
  reports/faz5/FAZ_5_8_SALES_DEMO_CRM_OPERATIONS_REPORT.txt \
  reports/faz5/FAZ_5_9_REVENUE_METRICS_MRR_ARR_CHURN_REPORT.txt \
  reports/faz5/FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SURFACES_REPORT.txt \
  reports/faz5/FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_REPORT.txt
do
  check_file "$rf" "5-11.7.1 report"
done

check_grep "reports/faz5/FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_REPORT.txt" "FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_STATUS=PASS" "5-10 exact route fix pass"

echo
echo "===== 5-11 JSON SUITE KONTROLU ====="

check_json_file_expr "$JSON_FILE" "assert d['catalog_code']=='pix2pi_commercial_readiness_suite_v1'" "suite catalog code"
check_json_file_expr "$JSON_FILE" "assert d['phase']=='FAZ_5' and d['step']=='5-11'" "suite phase step"
check_json_file_expr "$JSON_FILE" "assert d['commercial_blocker_count_required']==0" "5-11.7.4 blocker count required zero"
check_json_file_expr "$JSON_FILE" "assert d['final_readiness_decision']=='GO_TO_5_12'" "5-11.7.5 final readiness decision"
check_json_file_expr "$JSON_FILE" "assert d['seal']['FAZ_5_11_COMMERCIAL_READINESS_STATUS']=='PASS'" "json seal PASS"
check_json_file_expr "$JSON_FILE" "assert d['seal']['FAZ_5_11_COMMERCIAL_READINESS_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_file_expr "$JSON_FILE" "assert d['seal']['FAZ_5_12_READY']=='YES'" "json 5-12 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$BLOCKER_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  READINESS_STATUS="COMMERCIAL_READY ✅"
  STEP12_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  READINESS_STATUS="COMMERCIAL_BLOCKED ❌"
  STEP12_READY="NO ❌"
fi

{
  echo "FAZ_5_11_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_11_COMMERCIAL_READINESS_STATUS=$STEP_STATUS"
  echo "FAZ_5_11_COMMERCIAL_READINESS_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_11_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_11_COMMERCIAL_READY=$READINESS_STATUS"
  echo "FAZ_5_11_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_11_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_11_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_11_BLOCKER_COUNT=$BLOCKER_COUNT"
  echo "FAZ_5_12_READY=$STEP12_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-11 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-11 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "BLOCKER_COUNT=$BLOCKER_COUNT"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$BLOCKER_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-11 COMMERCIAL READINESS TEST SUITE SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-11 COMMERCIAL READINESS TEST SUITE SONUCU: HATA ❌ ====="
  exit 1
fi
