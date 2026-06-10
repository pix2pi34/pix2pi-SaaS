#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_4_subscription_billing_payment_ops.md"
PREV_JSON="configs/faz5/subscription_billing_policy_v1.json"
DOC="docs/faz5/5_5_tenant_lifecycle_commercial_ops.md"
JSON_FILE="configs/faz5/tenant_lifecycle_policy_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_5_TENANT_LIFECYCLE_COMMERCIAL_OPS_REPORT.txt"

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

echo "===== FAZ 5-5 TENANT LIFECYCLE / COMMERCIAL OPS TEST BASLADI ====="

check_file "$PREV_DOC" "5-4 subscription billing dokumani"
check_file "$PREV_JSON" "5-4 subscription billing json"
check_file "$DOC" "5-5 tenant lifecycle dokumani"
check_file "$JSON_FILE" "5-5 tenant lifecycle json"

check_grep "$PREV_DOC" "FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=SEALED" "5-4 sealed"
check_grep "$PREV_DOC" "FAZ_5_5_READY=YES" "5-5 giris izni"

check_grep "$DOC" "STEP_NO=5-5" "step no"
check_grep "$DOC" "STEP_NAME=Tenant Lifecycle / Commercial Ops" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_5_TENANT_LIFECYCLE_STATUS=PASS" "5-5 pass"
check_grep "$DOC" "FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS=SEALED" "5-5 sealed"
check_grep "$DOC" "FAZ_5_6_READY=YES" "5-6 ready"

echo
echo "===== FAZ 5-5 YAPILAN ISLER KONTROLU ====="

check_done "5-5 — Tenant Lifecycle / Commercial Ops" "FAZ 5-5 — Tenant Lifecycle / Commercial Ops"

check_done "5-5.1 Tenant açılış akışı" "### 5-5.1 Tenant açılış akışı"
check_done "5-5.1.1 Demo tenant açma" "### 5-5.1.1 Demo tenant açma"
check_done "5-5.1.2 Paid tenant açma" "### 5-5.1.2 Paid tenant açma"
check_done "5-5.1.3 Enterprise tenant açma" "### 5-5.1.3 Enterprise tenant açma"
check_done "5-5.1.4 Accountant workspace açma" "### 5-5.1.4 Accountant workspace açma"
check_done "5-5.1.5 Tenant owner belirleme" "### 5-5.1.5 Tenant owner belirleme"
check_done "5-5.1.6 İlk kullanıcı oluşturma" "### 5-5.1.6 İlk kullanıcı oluşturma"
check_done "5-5.1.7 Başlangıç paketi atama" "### 5-5.1.7 Başlangıç paketi atama"

check_done "5-5.2 Tenant upgrade / downgrade" "### 5-5.2 Tenant upgrade / downgrade"
check_done "5-5.2.1 Starter → Pro" "### 5-5.2.1 Starter → Pro"
check_done "5-5.2.2 Pro → Enterprise" "### 5-5.2.2 Pro → Enterprise"
check_done "5-5.2.3 Pro → Starter downgrade" "### 5-5.2.3 Pro → Starter downgrade"
check_done "5-5.2.4 Paket geçişinde limit kontrolü" "### 5-5.2.4 Paket geçişinde limit kontrolü"
check_done "5-5.2.5 Fazla kullanıcı / şube durumu" "### 5-5.2.5 Fazla kullanıcı / şube durumu"
check_done "5-5.2.6 Entitlement yenileme" "### 5-5.2.6 Entitlement yenileme"

check_done "5-5.3 Tenant freeze" "### 5-5.3 Tenant freeze"
check_done "5-5.3.1 Ödeme gecikmesi nedeniyle freeze" "### 5-5.3.1 Ödeme gecikmesi nedeniyle freeze"
check_done "5-5.3.2 Güvenlik nedeniyle freeze" "### 5-5.3.2 Güvenlik nedeniyle freeze"
check_done "5-5.3.3 Sözleşme nedeniyle freeze" "### 5-5.3.3 Sözleşme nedeniyle freeze"
check_done "5-5.3.4 Read-only mode kararı" "### 5-5.3.4 Read-only mode kararı"
check_done "5-5.3.5 API erişimi kapatma" "### 5-5.3.5 API erişimi kapatma"
check_done "5-5.3.6 Yazma işlemi kapatma" "### 5-5.3.6 Yazma işlemi kapatma"

check_done "5-5.4 Tenant close" "### 5-5.4 Tenant close"
check_done "5-5.4.1 Müşteri iptali" "### 5-5.4.1 Müşteri iptali"
check_done "5-5.4.2 Ödeme iptali" "### 5-5.4.2 Ödeme iptali"
check_done "5-5.4.3 Sözleşme bitişi" "### 5-5.4.3 Sözleşme bitişi"
check_done "5-5.4.4 Veri saklama süresi" "### 5-5.4.4 Veri saklama süresi"
check_done "5-5.4.5 Veri export hakkı" "### 5-5.4.5 Veri export hakkı"
check_done "5-5.4.6 Veri silme / imha policy" "### 5-5.4.6 Veri silme / imha policy"

check_done "5-5.5 Tenant data handoff" "### 5-5.5 Tenant data handoff"
check_done "5-5.5.1 Excel export" "### 5-5.5.1 Excel export"
check_done "5-5.5.2 PDF export" "### 5-5.5.2 PDF export"
check_done "5-5.5.3 TDHP export" "### 5-5.5.3 TDHP export"
check_done "5-5.5.4 Muhasebeci devir dosyası" "### 5-5.5.4 Muhasebeci devir dosyası"
check_done "5-5.5.5 Enterprise özel handoff" "### 5-5.5.5 Enterprise özel handoff"
check_done "5-5.5.6 Data ownership notu" "### 5-5.5.6 Data ownership notu"

check_done "5-5.6 Test / mühür" "### 5-5.6 Test / mühür"
check_done "5-5.6.1 Tenant lifecycle doc test" "### 5-5.6.1 Tenant lifecycle doc test"
check_done "5-5.6.2 Lifecycle JSON test" "### 5-5.6.2 Lifecycle JSON test"
check_done "5-5.6.3 Freeze policy test" "### 5-5.6.3 Freeze policy test"
check_done "5-5.6.4 Close policy test" "### 5-5.6.4 Close policy test"
check_done "5-5.6.5 Report üretimi" "### 5-5.6.5 Report üretimi"
check_done "5-5.6.6 5-6 geçiş izni" "### 5-5.6.6 5-6 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_tenant_lifecycle_policy_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-5'" "step dogru"
check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert 'pix2pi_subscription_billing_policy_v1' in d['depends_on']" "subscription dependency dogru"

check_json_expr "assert 'demo' in d['tenant_states']" "tenant state demo"
check_json_expr "assert 'active' in d['tenant_states']" "tenant state active"
check_json_expr "assert 'suspended' in d['tenant_states']" "tenant state suspended"
check_json_expr "assert 'frozen' in d['tenant_states']" "tenant state frozen"
check_json_expr "assert 'read_only' in d['tenant_states']" "tenant state read_only"
check_json_expr "assert 'closing' in d['tenant_states']" "tenant state closing"
check_json_expr "assert 'closed' in d['tenant_states']" "tenant state closed"
check_json_expr "assert 'enterprise_hold' in d['tenant_states']" "tenant state enterprise_hold"

check_json_expr "assert d['open_flows']['demo_tenant']['default_package']=='demo'" "demo default package"
check_json_expr "assert d['open_flows']['demo_tenant']['trial_days']==14" "demo trial 14"
check_json_expr "assert d['open_flows']['demo_tenant']['live_financial_operation'] is False" "demo live finance false"
check_json_expr "assert d['open_flows']['paid_tenant']['requires_package'] is True" "paid requires package"
check_json_expr "assert d['open_flows']['paid_tenant']['requires_owner'] is True" "paid requires owner"
check_json_expr "assert d['open_flows']['enterprise_tenant']['requires_contract'] is True" "enterprise requires contract"
check_json_expr "assert d['open_flows']['enterprise_tenant']['custom_limits'] is True" "enterprise custom limits"
check_json_expr "assert d['open_flows']['accountant_workspace']['company_based_billing'] is True" "accountant company billing"
check_json_expr "assert d['open_flows']['accountant_workspace']['direct_pos_operation'] is False" "accountant direct pos false"

check_json_expr "assert 'tenant_owner' in d['required_on_open']" "required tenant owner"
check_json_expr "assert 'first_user' in d['required_on_open']" "required first user"
check_json_expr "assert 'package_code' in d['required_on_open']" "required package code"
check_json_expr "assert 'subscription_state' in d['required_on_open']" "required subscription state"
check_json_expr "assert 'entitlement_profile' in d['required_on_open']" "required entitlement profile"

check_json_expr "assert d['package_transitions']['starter_to_pro']['type']=='upgrade'" "starter to pro upgrade"
check_json_expr "assert d['package_transitions']['starter_to_pro']['new_user_limit']==10" "starter to pro user limit"
check_json_expr "assert d['package_transitions']['starter_to_pro']['new_branch_limit']==3" "starter to pro branch limit"
check_json_expr "assert d['package_transitions']['pro_to_enterprise']['requires_contract'] is True" "pro to enterprise contract"
check_json_expr "assert d['package_transitions']['pro_to_enterprise']['opens_sla'] is True" "pro to enterprise sla"
check_json_expr "assert d['package_transitions']['pro_to_starter']['type']=='downgrade'" "pro to starter downgrade"
check_json_expr "assert d['package_transitions']['pro_to_starter']['requires_limit_check'] is True" "downgrade requires limit check"

check_json_expr "assert 'user_limit' in d['limit_checks']" "limit check user"
check_json_expr "assert 'branch_limit' in d['limit_checks']" "limit check branch"
check_json_expr "assert 'api_access' in d['limit_checks']" "limit check api"
check_json_expr "assert 'export_access' in d['limit_checks']" "limit check export"

check_json_expr "assert 'payment_delay' in d['freeze_reasons']" "freeze reason payment"
check_json_expr "assert 'security_risk' in d['freeze_reasons']" "freeze reason security"
check_json_expr "assert 'contract_violation' in d['freeze_reasons']" "freeze reason contract"
check_json_expr "assert d['freeze_policy']['delete_data'] is False" "freeze delete_data false"
check_json_expr "assert d['freeze_policy']['api_access']=='disabled'" "freeze api disabled"
check_json_expr "assert d['freeze_policy']['write_access']=='disabled'" "freeze write disabled"
check_json_expr "assert d['freeze_policy']['read_only_mode_future'] is True" "freeze read only future"

check_json_expr "assert 'customer_cancellation' in d['close_reasons']" "close reason customer"
check_json_expr "assert 'payment_cancellation' in d['close_reasons']" "close reason payment"
check_json_expr "assert 'contract_end' in d['close_reasons']" "close reason contract"
check_json_expr "assert d['close_policy']['state_before_close']=='closing'" "close state before closing"
check_json_expr "assert d['close_policy']['final_state']=='closed'" "close final state"
check_json_expr "assert d['close_policy']['data_retention_policy_source']=='FAZ_5_6_LEGAL_COMPLIANCE'" "close data retention source"
check_json_expr "assert d['close_policy']['data_delete_policy_source']=='FAZ_5_6_LEGAL_COMPLIANCE'" "close data delete source"

check_json_expr "assert d['data_handoff']['excel_export'] is True" "handoff excel"
check_json_expr "assert d['data_handoff']['pdf_export'] is True" "handoff pdf"
check_json_expr "assert d['data_handoff']['tdhp_export'] is True" "handoff tdhp"
check_json_expr "assert d['data_handoff']['accountant_handoff_file'] is True" "handoff accountant file"
check_json_expr "assert d['data_handoff']['enterprise_custom_handoff'] is True" "handoff enterprise custom"
check_json_expr "assert d['data_handoff']['data_ownership_policy_source']=='FAZ_5_6_LEGAL_COMPLIANCE'" "handoff ownership source"

check_json_expr "assert 'runtime_tenant_create_api' in d['out_of_scope']" "out of scope tenant create api"
check_json_expr "assert 'runtime_tenant_freeze_middleware' in d['out_of_scope']" "out of scope freeze middleware"
check_json_expr "assert 'real_data_deletion' in d['out_of_scope']" "out of scope real data deletion"
check_json_expr "assert d['seal']['FAZ_5_5_TENANT_LIFECYCLE_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_6_READY']=='YES'" "json 5-6 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP6_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP6_READY="NO ❌"
fi

{
  echo "FAZ_5_5_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_5_TENANT_LIFECYCLE_STATUS=$STEP_STATUS"
  echo "FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_5_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_5_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_5_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_5_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_6_READY=$STEP6_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-5 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-5 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-5 TENANT LIFECYCLE / COMMERCIAL OPS TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-5 TENANT LIFECYCLE / COMMERCIAL OPS TEST SONUCU: HATA ❌ ====="
  exit 1
fi
