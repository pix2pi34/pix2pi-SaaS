#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_3_entitlement_matrix_module_rights.md"
PREV_JSON="configs/faz5/entitlement_matrix_v1.json"
DOC="docs/faz5/5_4_subscription_billing_payment_ops.md"
JSON_FILE="configs/faz5/subscription_billing_policy_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_4_SUBSCRIPTION_BILLING_PAYMENT_OPS_REPORT.txt"

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

echo "===== FAZ 5-4 SUBSCRIPTION / BILLING / PAYMENT OPS TEST BASLADI ====="

check_file "$PREV_DOC" "5-3 entitlement dokumani"
check_file "$PREV_JSON" "5-3 entitlement json"
check_file "$DOC" "5-4 subscription billing dokumani"
check_file "$JSON_FILE" "5-4 subscription billing json"

check_grep "$PREV_DOC" "FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=SEALED" "5-3 sealed"
check_grep "$PREV_DOC" "FAZ_5_4_READY=YES" "5-4 giris izni"

check_grep "$DOC" "STEP_NO=5-4" "step no"
check_grep "$DOC" "STEP_NAME=Subscription / Billing / Payment Ops" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_4_SUBSCRIPTION_BILLING_STATUS=PASS" "5-4 pass"
check_grep "$DOC" "FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=SEALED" "5-4 sealed"
check_grep "$DOC" "FAZ_5_5_READY=YES" "5-5 ready"

echo
echo "===== FAZ 5-4 YAPILAN ISLER KONTROLU ====="

check_done "5-4 — Subscription / Billing / Payment Ops" "FAZ 5-4 — Subscription / Billing / Payment Ops"

check_done "5-4.1 Subscription lifecycle" "### 5-4.1 Subscription lifecycle"
check_done "5-4.1.1 Trial başlatma" "### 5-4.1.1 Trial başlatma"
check_done "5-4.1.2 Abonelik başlatma" "### 5-4.1.2 Abonelik başlatma"
check_done "5-4.1.3 Abonelik yenileme" "### 5-4.1.3 Abonelik yenileme"
check_done "5-4.1.4 Paket upgrade" "### 5-4.1.4 Paket upgrade"
check_done "5-4.1.5 Paket downgrade" "### 5-4.1.5 Paket downgrade"
check_done "5-4.1.6 Abonelik iptali" "### 5-4.1.6 Abonelik iptali"
check_done "5-4.1.7 Abonelik yeniden açma" "### 5-4.1.7 Abonelik yeniden açma"
check_done "5-4.1.8 Enterprise özel sözleşme durumu" "### 5-4.1.8 Enterprise özel sözleşme durumu"

check_done "5-4.2 Billing model" "### 5-4.2 Billing model"
check_done "5-4.2.1 Aylık faturalama" "### 5-4.2.1 Aylık faturalama"
check_done "5-4.2.2 Yıllık faturalama" "### 5-4.2.2 Yıllık faturalama"
check_done "5-4.2.3 Kullanıcı bazlı ek ücret" "### 5-4.2.3 Kullanıcı bazlı ek ücret"
check_done "5-4.2.4 Şube bazlı ek ücret" "### 5-4.2.4 Şube bazlı ek ücret"
check_done "5-4.2.5 Firma bazlı muhasebeci ücretlendirme" "### 5-4.2.5 Firma bazlı muhasebeci ücretlendirme"
check_done "5-4.2.6 Enterprise özel fiyatlama" "### 5-4.2.6 Enterprise özel fiyatlama"
check_done "5-4.2.7 KDV hariç / iç gösterim kararı" "### 5-4.2.7 KDV hariç / iç gösterim kararı"
check_done "5-4.2.8 Fatura dönem başlangıç / bitiş kuralı" "### 5-4.2.8 Fatura dönem başlangıç / bitiş kuralı"

check_done "5-4.3 Payment ops" "### 5-4.3 Payment ops"
check_done "5-4.3.1 Ödeme başarılı akışı" "### 5-4.3.1 Ödeme başarılı akışı"
check_done "5-4.3.2 Ödeme başarısız akışı" "### 5-4.3.2 Ödeme başarısız akışı"
check_done "5-4.3.3 Retry / tekrar deneme politikası" "### 5-4.3.3 Retry / tekrar deneme politikası"
check_done "5-4.3.4 Grace period" "### 5-4.3.4 Grace period"
check_done "5-4.3.5 Past due durumu" "### 5-4.3.5 Past due durumu"
check_done "5-4.3.6 Suspended durumu" "### 5-4.3.6 Suspended durumu"
check_done "5-4.3.7 Cancelled durumu" "### 5-4.3.7 Cancelled durumu"
check_done "5-4.3.8 Manual payment / banka havale opsiyonu" "### 5-4.3.8 Manual payment / banka havale opsiyonu"
check_done "5-4.3.9 İade / iptal politikası" "### 5-4.3.9 İade / iptal politikası"

check_done "5-4.4 Subscription → entitlement etkisi" "### 5-4.4 Subscription → entitlement etkisi"
check_done "5-4.4.1 Active durumda tam paket hakları" "### 5-4.4.1 Active durumda tam paket hakları"
check_done "5-4.4.2 Trialing durumda demo / trial limitleri" "### 5-4.4.2 Trialing durumda demo / trial limitleri"
check_done "5-4.4.3 Past due durumda yazma kısıtı" "### 5-4.4.3 Past due durumda yazma kısıtı"
check_done "5-4.4.4 Suspended durumda erişim kısıtı" "### 5-4.4.4 Suspended durumda erişim kısıtı"
check_done "5-4.4.5 Cancelled durumda erişim kapatma" "### 5-4.4.5 Cancelled durumda erişim kapatma"
check_done "5-4.4.6 Enterprise hold özel kural" "### 5-4.4.6 Enterprise hold özel kural"

check_done "5-4.5 Billing JSON contract" "### 5-4.5 Billing JSON contract"
check_done "5-4.5.1 Subscription state catalog" "### 5-4.5.1 Subscription state catalog"
check_done "5-4.5.2 Billing cycle catalog" "### 5-4.5.2 Billing cycle catalog"
check_done "5-4.5.3 Payment state catalog" "### 5-4.5.3 Payment state catalog"
check_done "5-4.5.4 Grace period config" "### 5-4.5.4 Grace period config"
check_done "5-4.5.5 Retry policy config" "### 5-4.5.5 Retry policy config"
check_done "5-4.5.6 Package transition rules" "### 5-4.5.6 Package transition rules"

check_done "5-4.6 Test / mühür" "### 5-4.6 Test / mühür"
check_done "5-4.6.1 Subscription doc test" "### 5-4.6.1 Subscription doc test"
check_done "5-4.6.2 Billing JSON test" "### 5-4.6.2 Billing JSON test"
check_done "5-4.6.3 Payment state test" "### 5-4.6.3 Payment state test"
check_done "5-4.6.4 Entitlement dependency test" "### 5-4.6.4 Entitlement dependency test"
check_done "5-4.6.5 Report üretimi" "### 5-4.6.5 Report üretimi"
check_done "5-4.6.6 5-5 geçiş izni" "### 5-4.6.6 5-5 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_subscription_billing_policy_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-4'" "step dogru"
check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert d['currency']=='TRY'" "currency TRY"
check_json_expr "assert d['tax_policy']=='vat_excluded_internal_catalog'" "tax policy dogru"

check_json_expr "assert 'trialing' in d['subscription_states']" "subscription state trialing"
check_json_expr "assert 'active' in d['subscription_states']" "subscription state active"
check_json_expr "assert 'past_due' in d['subscription_states']" "subscription state past_due"
check_json_expr "assert 'suspended' in d['subscription_states']" "subscription state suspended"
check_json_expr "assert 'cancelled' in d['subscription_states']" "subscription state cancelled"
check_json_expr "assert 'enterprise_hold' in d['subscription_states']" "subscription state enterprise_hold"

check_json_expr "cycles={x['code']:x for x in d['billing_cycles']}; assert cycles['monthly']['period_months']==1" "monthly billing cycle"
check_json_expr "cycles={x['code']:x for x in d['billing_cycles']}; assert cycles['annual']['period_months']==12" "annual billing cycle"
check_json_expr "cycles={x['code']:x for x in d['billing_cycles']}; assert cycles['custom_enterprise']['custom_contract'] is True" "enterprise custom billing cycle"

check_json_expr "assert 'paid' in d['payment_states']" "payment state paid"
check_json_expr "assert 'failed' in d['payment_states']" "payment state failed"
check_json_expr "assert 'retrying' in d['payment_states']" "payment state retrying"
check_json_expr "assert 'manual_review' in d['payment_states']" "payment state manual_review"

check_json_expr "assert d['retry_policy']['enabled'] is True" "retry enabled"
check_json_expr "assert d['retry_policy']['retry_days']==[0,3,7]" "retry days dogru"
check_json_expr "assert d['retry_policy']['after_last_retry']=='candidate_for_suspension'" "retry final action dogru"

check_json_expr "assert d['grace_period_days']['starter']==3" "starter grace 3"
check_json_expr "assert d['grace_period_days']['pro']==7" "pro grace 7"
check_json_expr "assert d['grace_period_days']['accountant']==7" "accountant grace 7"
check_json_expr "assert d['grace_period_days']['enterprise']=='contract_based'" "enterprise grace contract"

check_json_expr "assert d['subscription_to_entitlement_effect']['active']=='full_package_rights'" "active entitlement effect"
check_json_expr "assert d['subscription_to_entitlement_effect']['trialing']=='trial_or_demo_limits'" "trialing entitlement effect"
check_json_expr "assert d['subscription_to_entitlement_effect']['past_due']=='restricted_write_possible'" "past_due entitlement effect"
check_json_expr "assert d['subscription_to_entitlement_effect']['suspended']=='commercial_access_restricted'" "suspended entitlement effect"
check_json_expr "assert d['subscription_to_entitlement_effect']['cancelled']=='commercial_access_closed'" "cancelled entitlement effect"
check_json_expr "assert d['subscription_to_entitlement_effect']['enterprise_hold']=='contract_based_decision'" "enterprise hold entitlement effect"

check_json_expr "assert d['package_transition_rules']['upgrade']['activation']=='immediate'" "upgrade immediate"
check_json_expr "assert d['package_transition_rules']['downgrade']['activation']=='period_end_preferred'" "downgrade period end"
check_json_expr "assert d['package_transition_rules']['downgrade']['requires_limit_check'] is True" "downgrade limit check"
check_json_expr "assert d['package_transition_rules']['reactivation']['requires_payment_or_manual_approval'] is True" "reactivation approval"

check_json_expr "assert d['accountant_billing']['workspace_monthly_try']==999" "accountant monthly 999"
check_json_expr "assert d['accountant_billing']['workspace_annual_try']==9990" "accountant annual 9990"
check_json_expr "assert d['accountant_billing']['included_company_limit']==10" "accountant included company 10"
check_json_expr "assert d['accountant_billing']['per_company_monthly_try']==149" "accountant company monthly 149"
check_json_expr "assert d['accountant_billing']['company_based_billing'] is True" "accountant company based billing"

check_json_expr "assert d['manual_payment']['enabled'] is True" "manual payment enabled"
check_json_expr "assert 'bank_transfer' in d['manual_payment']['methods']" "manual payment bank transfer"
check_json_expr "assert 'manual_approval' in d['manual_payment']['methods']" "manual payment approval"
check_json_expr "assert 'enterprise_contract' in d['manual_payment']['methods']" "manual payment enterprise"

check_json_expr "assert 'start_at' in d['invoice_period_fields']" "invoice start_at"
check_json_expr "assert 'end_at' in d['invoice_period_fields']" "invoice end_at"
check_json_expr "assert 'due_at' in d['invoice_period_fields']" "invoice due_at"
check_json_expr "assert 'paid_at' in d['invoice_period_fields']" "invoice paid_at"

check_json_expr "assert 'live_payment_gateway_integration' in d['out_of_scope']" "out of scope live payment"
check_json_expr "assert 'runtime_subscription_middleware' in d['out_of_scope']" "out of scope runtime middleware"
check_json_expr "assert d['seal']['FAZ_5_4_SUBSCRIPTION_BILLING_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_5_READY']=='YES'" "json 5-5 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP5_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP5_READY="NO ❌"
fi

{
  echo "FAZ_5_4_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_4_SUBSCRIPTION_BILLING_STATUS=$STEP_STATUS"
  echo "FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_4_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_4_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_4_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_4_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_5_READY=$STEP5_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-4 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-4 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-4 SUBSCRIPTION / BILLING / PAYMENT OPS TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-4 SUBSCRIPTION / BILLING / PAYMENT OPS TEST SONUCU: HATA ❌ ====="
  exit 1
fi
