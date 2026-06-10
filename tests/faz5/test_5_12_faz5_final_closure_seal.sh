#!/usr/bin/env bash
set -u

DOC="docs/faz5/5_12_faz5_final_closure_seal.md"
JSON_FILE="configs/faz5/faz5_final_closure_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_FINAL_CLOSURE_SEAL_REPORT.txt"

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

check_json_expr() {
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

echo "===== FAZ 5-12 FINAL CLOSURE / SEAL TEST BASLADI ====="

echo
echo "===== ANA DOSYA KONTROLU ====="

check_file "$DOC" "5-12 final closure dokumani"
check_file "$JSON_FILE" "5-12 final closure json"

check_grep "$DOC" "STEP_NO=5-12" "step no"
check_grep "$DOC" "STEP_NAME=FAZ 5 Final Closure / Seal" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_FINAL_STATUS=PASS" "faz 5 final pass"
check_grep "$DOC" "FAZ_5_FINAL_SEAL_STATUS=SEALED" "faz 5 final sealed"
check_grep "$DOC" "FAZ_6_READY=YES" "faz 6 ready"

echo
echo "===== FAZ 5-12 YAPILAN ISLER KONTROLU ====="

check_done "5-12 — FAZ 5 Final Closure / Seal" "FAZ 5-12 — FAZ 5 Final Closure / Seal"

check_done "5-12.1 Faz kapanış kontrolü" "### 5-12.1 Faz kapanış kontrolü"
check_done "5-12.1.1 5-1 sealed kontrol" "### 5-12.1.1 5-1 sealed kontrol"
check_done "5-12.1.2 5-2 sealed kontrol" "### 5-12.1.2 5-2 sealed kontrol"
check_done "5-12.1.3 5-3 sealed kontrol" "### 5-12.1.3 5-3 sealed kontrol"
check_done "5-12.1.4 5-4 sealed kontrol" "### 5-12.1.4 5-4 sealed kontrol"
check_done "5-12.1.5 5-5 sealed kontrol" "### 5-12.1.5 5-5 sealed kontrol"
check_done "5-12.1.6 5-6 sealed kontrol" "### 5-12.1.6 5-6 sealed kontrol"
check_done "5-12.1.7 5-7 sealed kontrol" "### 5-12.1.7 5-7 sealed kontrol"
check_done "5-12.1.8 5-8 sealed kontrol" "### 5-12.1.8 5-8 sealed kontrol"
check_done "5-12.1.9 5-9 sealed kontrol" "### 5-12.1.9 5-9 sealed kontrol"
check_done "5-12.1.10 5-10 sealed kontrol" "### 5-12.1.10 5-10 sealed kontrol"
check_done "5-12.1.11 5-11 sealed kontrol" "### 5-12.1.11 5-11 sealed kontrol"

check_done "5-12.2 Commercial blocker kontrolü" "### 5-12.2 Commercial blocker kontrolü"
check_done "5-12.2.1 Pricing blocker" "### 5-12.2.1 Pricing blocker"
check_done "5-12.2.2 Entitlement blocker" "### 5-12.2.2 Entitlement blocker"
check_done "5-12.2.3 Billing blocker" "### 5-12.2.3 Billing blocker"
check_done "5-12.2.4 Tenant lifecycle blocker" "### 5-12.2.4 Tenant lifecycle blocker"
check_done "5-12.2.5 Legal blocker" "### 5-12.2.5 Legal blocker"
check_done "5-12.2.6 Support blocker" "### 5-12.2.6 Support blocker"
check_done "5-12.2.7 Public surface blocker" "### 5-12.2.7 Public surface blocker"

check_done "5-12.3 Go / No-Go kararı" "### 5-12.3 Go / No-Go kararı"
check_done "5-12.3.1 Commercial Go" "### 5-12.3.1 Commercial Go"
check_done "5-12.3.2 Commercial No-Go" "### 5-12.3.2 Commercial No-Go"
check_done "5-12.3.3 Conditional Go" "### 5-12.3.3 Conditional Go"
check_done "5-12.3.4 Open action list" "### 5-12.3.4 Open action list"
check_done "5-12.3.5 FAZ 6 readiness" "### 5-12.3.5 FAZ 6 readiness"

check_done "5-12.4 Final rapor" "### 5-12.4 Final rapor"
check_done "5-12.4.1 FAZ 5 final report" "### 5-12.4.1 FAZ 5 final report"
check_done "5-12.4.2 PASS / FAIL sayımı" "### 5-12.4.2 PASS / FAIL sayımı"
check_done "5-12.4.3 Açık riskler" "### 5-12.4.3 Açık riskler"
check_done "5-12.4.4 FAZ 6’ya devredenler" "### 5-12.4.4 FAZ 6’ya devredenler"
check_done "5-12.4.5 Final seal" "### 5-12.4.5 Final seal"

check_done "5-12.5 Final mühür" "### 5-12.5 Final mühür"
check_done "5-12.5.1 FAZ_5_FINAL_STATUS" "### 5-12.5.1 FAZ_5_FINAL_STATUS"
check_done "5-12.5.2 FAZ_5_FINAL_SEAL_STATUS" "### 5-12.5.2 FAZ_5_FINAL_SEAL_STATUS"
check_done "5-12.5.3 COMMERCIAL_READY" "### 5-12.5.3 COMMERCIAL_READY"
check_done "5-12.5.4 FAZ_6_READY" "### 5-12.5.4 FAZ_6_READY"

echo
echo "===== 5-1 / 5-11 DOKUMAN MUHUR KONTROLU ====="

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
check_file "docs/faz5/5_11_commercial_readiness_test_suite.md" "5-11 doc"

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
check_grep "docs/faz5/5_11_commercial_readiness_test_suite.md" "FAZ_5_11_COMMERCIAL_READINESS_SEAL_STATUS=SEALED" "5-11 sealed"

echo
echo "===== 5-11 RAPOR VE BLOCKER KONTROLU ====="

check_file "reports/faz5/FAZ_5_11_COMMERCIAL_READINESS_TEST_SUITE_REPORT.txt" "5-11 readiness report"
check_grep "reports/faz5/FAZ_5_11_COMMERCIAL_READINESS_TEST_SUITE_REPORT.txt" "FAZ_5_11_TEST_STATUS=PASS" "5-11 report pass"
check_grep "reports/faz5/FAZ_5_11_COMMERCIAL_READINESS_TEST_SUITE_REPORT.txt" "FAZ_5_11_COMMERCIAL_READY=COMMERCIAL_READY" "5-11 commercial ready"
check_grep "reports/faz5/FAZ_5_11_COMMERCIAL_READINESS_TEST_SUITE_REPORT.txt" "FAZ_5_11_BLOCKER_COUNT=0" "5-11 blocker zero"
check_grep "reports/faz5/FAZ_5_11_COMMERCIAL_READINESS_TEST_SUITE_REPORT.txt" "FAZ_5_12_READY=YES" "5-12 ready from 5-11"

echo
echo "===== PUBLIC ROUTE KONTROLU ====="

check_file "reports/faz5/FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_REPORT.txt" "5-10 public exact route report"
check_grep "reports/faz5/FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_REPORT.txt" "FAZ_5_10_PUBLIC_EXACT_ROUTE_FIX_STATUS=PASS" "5-10 public exact route pass"

check_url_marker "https://pix2pi.com.tr/faz5/" "Pix2pi FAZ 5 Public Surfaces" "public faz5 index" "/tmp/pix2pi_5_12_faz5_index.html"
check_url_marker "https://pix2pi.com.tr/faz5/pricing/" "Public Pricing Surface" "public faz5 pricing" "/tmp/pix2pi_5_12_pricing.html"
check_url_marker "https://pix2pi.com.tr/faz5/developer/" "Developer Surface" "public faz5 developer" "/tmp/pix2pi_5_12_developer.html"

echo
echo "===== JSON FORMAT VE FINAL STATUS KONTROLU ====="

for jf in \
  configs/faz5/packages_pricing_v1.json \
  configs/faz5/entitlement_matrix_v1.json \
  configs/faz5/subscription_billing_policy_v1.json \
  configs/faz5/tenant_lifecycle_policy_v1.json \
  configs/faz5/legal_compliance_policy_v1.json \
  configs/faz5/support_sla_incident_policy_v1.json \
  configs/faz5/sales_demo_crm_policy_v1.json \
  configs/faz5/revenue_metrics_policy_v1.json \
  configs/faz5/public_pricing_developer_surface_v1.json \
  configs/faz5/commercial_readiness_suite_v1.json \
  "$JSON_FILE"
do
  if python3 -m json.tool "$jf" >/dev/null 2>&1; then
    pass "json format gecerli: $jf"
  else
    blocker "json format bozuk: $jf"
  fi
done

check_json_expr "$JSON_FILE" "assert d['catalog_code']=='pix2pi_faz5_final_closure_v1'" "final catalog code"
check_json_expr "$JSON_FILE" "assert d['phase']=='FAZ_5' and d['step']=='5-12'" "final phase step"
check_json_expr "$JSON_FILE" "assert len(d['closed_steps'])==12" "closed steps count 12"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_5_12_TEST_STATUS']=='PASS'" "json final 5-12 pass"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_5_FINAL_STATUS']=='PASS'" "json final faz 5 pass"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_5_FINAL_SEAL_STATUS']=='SEALED'" "json final seal sealed"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_5_COMMERCIAL_READY']=='YES'" "json commercial ready"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_5_FINAL_GO_DECISION']=='GO'" "json go decision"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_5_FINAL_BLOCKER_COUNT']==0" "json blocker zero"
check_json_expr "$JSON_FILE" "assert d['final_status']['FAZ_6_READY']=='YES'" "json faz 6 ready"
check_json_expr "$JSON_FILE" "assert 'packages_pricing' in d['commercial_domains_closed']" "domain packages closed"
check_json_expr "$JSON_FILE" "assert 'subscription_billing' in d['commercial_domains_closed']" "domain billing closed"
check_json_expr "$JSON_FILE" "assert 'public_pricing_developer_surfaces' in d['commercial_domains_closed']" "domain public closed"
check_json_expr "$JSON_FILE" "assert d['faz6_readiness']['ready'] is True" "faz6 readiness true"
check_json_expr "$JSON_FILE" "assert d['faz6_readiness']['next_phase']=='FAZ_6'" "faz6 next phase"
check_json_expr "$JSON_FILE" "assert d['seal']['FAZ_5_FINAL_STATUS']=='PASS'" "seal final pass"
check_json_expr "$JSON_FILE" "assert d['seal']['FAZ_5_FINAL_SEAL_STATUS']=='SEALED'" "seal final sealed"
check_json_expr "$JSON_FILE" "assert d['seal']['FAZ_6_READY']=='YES'" "seal faz6 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$BLOCKER_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  FINAL_STATUS="PASS ✅"
  FINAL_SEAL_STATUS="SEALED ✅"
  COMMERCIAL_READY="YES ✅"
  GO_DECISION="GO ✅"
  FAZ6_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  FINAL_STATUS="BLOCKED ❌"
  FINAL_SEAL_STATUS="OPEN ❌"
  COMMERCIAL_READY="NO ❌"
  GO_DECISION="NO-GO ❌"
  FAZ6_READY="NO ❌"
fi

{
  echo "FAZ_5_12_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_FINAL_STATUS=$FINAL_STATUS"
  echo "FAZ_5_FINAL_SEAL_STATUS=$FINAL_SEAL_STATUS"
  echo "FAZ_5_COMMERCIAL_READY=$COMMERCIAL_READY"
  echo "FAZ_5_FINAL_GO_DECISION=$GO_DECISION"
  echo "FAZ_5_FINAL_BLOCKER_COUNT=$BLOCKER_COUNT"
  echo "FAZ_5_12_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_12_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_12_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_6_READY=$FAZ6_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5 FINAL CLOSURE / SEAL RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-12 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "BLOCKER_COUNT=$BLOCKER_COUNT"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$BLOCKER_COUNT" -eq 0 ]; then
  echo "===== FAZ 5 FINAL CLOSURE / SEAL TEST SONUCU: OK ✅ ====="
  echo "===== FAZ 5 TAMAMLANDI VE MUHURLENDI ✅ ====="
  echo "FAZ_5_FINAL_STATUS=PASS ✅"
  echo "FAZ_5_FINAL_SEAL_STATUS=SEALED ✅"
  echo "FAZ_5_COMMERCIAL_READY=YES ✅"
  echo "FAZ_5_FINAL_GO_DECISION=GO ✅"
  echo "FAZ_6_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 5 FINAL CLOSURE / SEAL TEST SONUCU: HATA ❌ ====="
  echo "FAZ_5_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_5_FINAL_SEAL_STATUS=OPEN ❌"
  echo "FAZ_6_READY=NO ❌"
  exit 1
fi
