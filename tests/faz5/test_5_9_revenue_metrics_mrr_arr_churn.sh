#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_8_sales_demo_crm_operations.md"
PREV_JSON="configs/faz5/sales_demo_crm_policy_v1.json"
DOC="docs/faz5/5_9_revenue_metrics_mrr_arr_churn.md"
JSON_FILE="configs/faz5/revenue_metrics_policy_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_9_REVENUE_METRICS_MRR_ARR_CHURN_REPORT.txt"

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

echo "===== FAZ 5-9 REVENUE METRICS / MRR / ARR / CHURN TEST BASLADI ====="

check_file "$PREV_DOC" "5-8 sales demo crm dokumani"
check_file "$PREV_JSON" "5-8 sales demo crm json"
check_file "$DOC" "5-9 revenue metrics dokumani"
check_file "$JSON_FILE" "5-9 revenue metrics json"

check_grep "$PREV_DOC" "FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=SEALED" "5-8 sealed"
check_grep "$PREV_DOC" "FAZ_5_9_READY=YES" "5-9 giris izni"

check_grep "$DOC" "STEP_NO=5-9" "step no"
check_grep "$DOC" "STEP_NAME=Revenue Metrics / MRR / ARR / Churn" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_9_REVENUE_METRICS_STATUS=PASS" "5-9 pass"
check_grep "$DOC" "FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=SEALED" "5-9 sealed"
check_grep "$DOC" "FAZ_5_10_READY=YES" "5-10 ready"

echo
echo "===== FAZ 5-9 YAPILAN ISLER KONTROLU ====="

check_done "5-9 — Revenue Metrics / MRR / ARR / Churn" "FAZ 5-9 — Revenue Metrics / MRR / ARR / Churn"

check_done "5-9.1 Ana gelir metrikleri" "### 5-9.1 Ana gelir metrikleri"
check_done "5-9.1.1 MRR" "### 5-9.1.1 MRR"
check_done "5-9.1.2 ARR" "### 5-9.1.2 ARR"
check_done "5-9.1.3 Churn" "### 5-9.1.3 Churn"
check_done "5-9.1.4 Expansion revenue" "### 5-9.1.4 Expansion revenue"
check_done "5-9.1.5 Contraction revenue" "### 5-9.1.5 Contraction revenue"
check_done "5-9.1.6 Net revenue retention" "### 5-9.1.6 Net revenue retention"
check_done "5-9.1.7 Gross revenue retention" "### 5-9.1.7 Gross revenue retention"

check_done "5-9.2 Paket bazlı metrikler" "### 5-9.2 Paket bazlı metrikler"
check_done "5-9.2.1 Demo sayısı" "### 5-9.2.1 Demo sayısı"
check_done "5-9.2.2 Starter müşteri sayısı" "### 5-9.2.2 Starter müşteri sayısı"
check_done "5-9.2.3 Pro müşteri sayısı" "### 5-9.2.3 Pro müşteri sayısı"
check_done "5-9.2.4 Enterprise müşteri sayısı" "### 5-9.2.4 Enterprise müşteri sayısı"
check_done "5-9.2.5 Muhasebeci workspace sayısı" "### 5-9.2.5 Muhasebeci workspace sayısı"
check_done "5-9.2.6 Firma başı gelir" "### 5-9.2.6 Firma başı gelir"

check_done "5-9.3 Tahsilat metrikleri" "### 5-9.3 Tahsilat metrikleri"
check_done "5-9.3.1 Başarılı ödeme oranı" "### 5-9.3.1 Başarılı ödeme oranı"
check_done "5-9.3.2 Başarısız ödeme oranı" "### 5-9.3.2 Başarısız ödeme oranı"
check_done "5-9.3.3 Past due müşteri sayısı" "### 5-9.3.3 Past due müşteri sayısı"
check_done "5-9.3.4 Suspended tenant sayısı" "### 5-9.3.4 Suspended tenant sayısı"
check_done "5-9.3.5 İptal oranı" "### 5-9.3.5 İptal oranı"
check_done "5-9.3.6 Ortalama gelir / tenant" "### 5-9.3.6 Ortalama gelir / tenant"

check_done "5-9.4 Raporlama kaynakları" "### 5-9.4 Raporlama kaynakları"
check_done "5-9.4.1 Subscription data" "### 5-9.4.1 Subscription data"
check_done "5-9.4.2 Billing data" "### 5-9.4.2 Billing data"
check_done "5-9.4.3 Tenant lifecycle data" "### 5-9.4.3 Tenant lifecycle data"
check_done "5-9.4.4 Sales CRM data" "### 5-9.4.4 Sales CRM data"
check_done "5-9.4.5 Support churn sinyalleri" "### 5-9.4.5 Support churn sinyalleri"

check_done "5-9.5 Revenue JSON contract" "### 5-9.5 Revenue JSON contract"
check_done "5-9.5.1 Metric catalog" "### 5-9.5.1 Metric catalog"
check_done "5-9.5.2 Formula catalog" "### 5-9.5.2 Formula catalog"
check_done "5-9.5.3 Data source mapping" "### 5-9.5.3 Data source mapping"
check_done "5-9.5.4 Dashboard readiness" "### 5-9.5.4 Dashboard readiness"
check_done "5-9.5.5 Alert threshold readiness" "### 5-9.5.5 Alert threshold readiness"

check_done "5-9.6 Test / mühür" "### 5-9.6 Test / mühür"
check_done "5-9.6.1 Revenue doc test" "### 5-9.6.1 Revenue doc test"
check_done "5-9.6.2 Metrics JSON test" "### 5-9.6.2 Metrics JSON test"
check_done "5-9.6.3 Formula test" "### 5-9.6.3 Formula test"
check_done "5-9.6.4 Dashboard source test" "### 5-9.6.4 Dashboard source test"
check_done "5-9.6.5 Report üretimi" "### 5-9.6.5 Report üretimi"
check_done "5-9.6.6 5-10 geçiş izni" "### 5-9.6.6 5-10 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_revenue_metrics_policy_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-9'" "step dogru"
check_json_expr "assert d['currency']=='TRY'" "currency TRY"

check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert 'pix2pi_subscription_billing_policy_v1' in d['depends_on']" "subscription dependency dogru"
check_json_expr "assert 'pix2pi_tenant_lifecycle_policy_v1' in d['depends_on']" "tenant lifecycle dependency dogru"
check_json_expr "assert 'pix2pi_sales_demo_crm_policy_v1' in d['depends_on']" "sales crm dependency dogru"

check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'mrr' in codes" "metric mrr"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'arr' in codes" "metric arr"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'logo_churn' in codes" "metric logo churn"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'revenue_churn' in codes" "metric revenue churn"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'expansion_revenue' in codes" "metric expansion"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'contraction_revenue' in codes" "metric contraction"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'net_revenue_retention' in codes" "metric nrr"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'gross_revenue_retention' in codes" "metric grr"
check_json_expr "codes={x['code']:x for x in d['metric_catalog']}; assert 'average_revenue_per_tenant' in codes" "metric arpt"

check_json_expr "assert d['formula_catalog']['arr']=='mrr * 12'" "formula arr"
check_json_expr "assert 'active_monthly_recurring_revenue' in d['formula_catalog']['mrr']" "formula mrr"
check_json_expr "assert 'cancelled_customers' in d['formula_catalog']['logo_churn']" "formula logo churn"
check_json_expr "assert 'lost_mrr' in d['formula_catalog']['revenue_churn']" "formula revenue churn"
check_json_expr "assert 'upgrade_revenue' in d['formula_catalog']['expansion_revenue']" "formula expansion"
check_json_expr "assert 'downgrade_loss' in d['formula_catalog']['contraction_revenue']" "formula contraction"
check_json_expr "assert 'starting_mrr' in d['formula_catalog']['net_revenue_retention']" "formula nrr"
check_json_expr "assert 'starting_mrr' in d['formula_catalog']['gross_revenue_retention']" "formula grr"
check_json_expr "assert 'active_mrr' in d['formula_catalog']['average_revenue_per_tenant']" "formula arpt"

check_json_expr "assert d['package_metrics']['demo_count'] is True" "package demo count"
check_json_expr "assert d['package_metrics']['starter_customer_count'] is True" "package starter count"
check_json_expr "assert d['package_metrics']['pro_customer_count'] is True" "package pro count"
check_json_expr "assert d['package_metrics']['enterprise_customer_count'] is True" "package enterprise count"
check_json_expr "assert d['package_metrics']['accountant_workspace_count'] is True" "package accountant workspace"
check_json_expr "assert d['package_metrics']['accountant_company_revenue'] is True" "package accountant company revenue"
check_json_expr "assert d['package_metrics']['package_distribution'] is True" "package distribution"

check_json_expr "assert d['collection_metrics']['successful_payment_rate'] is True" "collection successful payment"
check_json_expr "assert d['collection_metrics']['failed_payment_rate'] is True" "collection failed payment"
check_json_expr "assert d['collection_metrics']['past_due_customer_count'] is True" "collection past due"
check_json_expr "assert d['collection_metrics']['suspended_tenant_count'] is True" "collection suspended"
check_json_expr "assert d['collection_metrics']['cancelled_subscription_rate'] is True" "collection cancelled"
check_json_expr "assert d['collection_metrics']['average_revenue_per_tenant'] is True" "collection arpt"

check_json_expr "assert 'subscription_state' in d['data_source_mapping']['subscription_data']" "source subscription state"
check_json_expr "assert 'package_code' in d['data_source_mapping']['subscription_data']" "source package code"
check_json_expr "assert 'invoice_amount' in d['data_source_mapping']['billing_data']" "source invoice amount"
check_json_expr "assert 'payment_state' in d['data_source_mapping']['billing_data']" "source payment state"
check_json_expr "assert 'tenant_state' in d['data_source_mapping']['tenant_lifecycle_data']" "source tenant state"
check_json_expr "assert 'lead_state' in d['data_source_mapping']['sales_crm_data']" "source lead state"
check_json_expr "assert 'proposal_state' in d['data_source_mapping']['sales_crm_data']" "source proposal state"
check_json_expr "assert 'incident_class' in d['data_source_mapping']['support_signal_data']" "source incident class"

check_json_expr "assert d['dashboard_readiness']['revenue_overview_required'] is True" "dashboard revenue overview"
check_json_expr "assert d['dashboard_readiness']['package_distribution_required'] is True" "dashboard package distribution"
check_json_expr "assert d['dashboard_readiness']['collection_health_required'] is True" "dashboard collection health"
check_json_expr "assert d['dashboard_readiness']['churn_view_required'] is True" "dashboard churn view"
check_json_expr "assert d['dashboard_readiness']['sales_funnel_required'] is True" "dashboard sales funnel"
check_json_expr "assert d['dashboard_readiness']['support_churn_signal_required'] is True" "dashboard support churn"

check_json_expr "assert d['alert_threshold_readiness']['mrr_drop_alert'] is True" "alert mrr drop"
check_json_expr "assert d['alert_threshold_readiness']['payment_failure_alert'] is True" "alert payment failure"
check_json_expr "assert d['alert_threshold_readiness']['past_due_spike_alert'] is True" "alert past due spike"
check_json_expr "assert d['alert_threshold_readiness']['churn_spike_alert'] is True" "alert churn spike"
check_json_expr "assert d['alert_threshold_readiness']['support_p1_spike_alert'] is True" "alert support p1 spike"

check_json_expr "assert 'demo' in d['excluded_from_mrr']" "excluded demo"
check_json_expr "assert 'cancelled' in d['excluded_from_mrr']" "excluded cancelled"
check_json_expr "assert 'starter_active' in d['included_in_mrr']" "included starter"
check_json_expr "assert 'pro_active' in d['included_in_mrr']" "included pro"
check_json_expr "assert 'enterprise_active_normalized' in d['included_in_mrr']" "included enterprise"
check_json_expr "assert 'accountant_workspace_active' in d['included_in_mrr']" "included accountant workspace"
check_json_expr "assert 'accountant_company_addons' in d['included_in_mrr']" "included accountant addons"

check_json_expr "assert 'real_revenue_dashboard' in d['out_of_scope']" "out of scope dashboard"
check_json_expr "assert 'runtime_mrr_worker' in d['out_of_scope']" "out of scope mrr worker"
check_json_expr "assert 'automatic_churn_prediction' in d['out_of_scope']" "out of scope churn prediction"
check_json_expr "assert d['seal']['FAZ_5_9_REVENUE_METRICS_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_9_REVENUE_METRICS_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_10_READY']=='YES'" "json 5-10 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP10_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP10_READY="NO ❌"
fi

{
  echo "FAZ_5_9_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_9_REVENUE_METRICS_STATUS=$STEP_STATUS"
  echo "FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_9_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_9_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_9_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_9_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_10_READY=$STEP10_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-9 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-9 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-9 REVENUE METRICS / MRR / ARR / CHURN TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-9 REVENUE METRICS / MRR / ARR / CHURN TEST SONUCU: HATA ❌ ====="
  exit 1
fi
