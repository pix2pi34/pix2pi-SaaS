#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_2_packages_pricing_architecture.md"
PREV_JSON="configs/faz5/packages_pricing_v1.json"
DOC="docs/faz5/5_3_entitlement_matrix_module_rights.md"
JSON_FILE="configs/faz5/entitlement_matrix_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_3_ENTITLEMENT_MATRIX_REPORT.txt"

FAIL_COUNT=0
OK_COUNT=0

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

check_json_expr() {
  local expr="$1"
  local label="$2"

  if python3 -c "import json; d=json.load(open('$JSON_FILE', encoding='utf-8')); $expr" >/dev/null 2>&1; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 5-3 ENTITLEMENT MATRIX TEST BASLADI ====="

check_file "$PREV_DOC" "5-2 packages pricing dokumani"
check_file "$PREV_JSON" "5-2 pricing json catalog"
check_file "$DOC" "5-3 entitlement dokumani"
check_file "$JSON_FILE" "5-3 entitlement json catalog"

check_grep "$PREV_DOC" "FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS=SEALED" "5-2 sealed"
check_grep "$PREV_DOC" "FAZ_5_3_READY=YES" "5-3 giris izni"

check_grep "$DOC" "STEP_NO=5-3" "step no"
check_grep "$DOC" "STEP_NAME=Entitlement Matrix / Module Rights" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_3_ENTITLEMENT_MATRIX_STATUS=PASS" "5-3 pass"
check_grep "$DOC" "FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=SEALED" "5-3 sealed"
check_grep "$DOC" "FAZ_5_4_READY=YES" "5-4 ready"

check_grep "$DOC" "Default deny" "default deny prensibi"
check_grep "$DOC" "Tenant güvenliği ticari haktan ayrılmaz" "tenant safety prensibi"
check_grep "$DOC" "Subscription durumu hakları etkiler" "subscription state prensibi"
check_grep "$DOC" "Muhasebeci paketi işletme paketinden ayrıdır" "accountant ayrimi"

check_grep "$DOC" "identity_core" "identity_core modulu"
check_grep "$DOC" "tenant_core" "tenant_core modulu"
check_grep "$DOC" "erp_core" "erp_core modulu"
check_grep "$DOC" "pos_core" "pos_core modulu"
check_grep "$DOC" "reporting_advanced" "reporting_advanced modulu"
check_grep "$DOC" "accounting_export" "accounting_export modulu"
check_grep "$DOC" "api_access" "api_access modulu"
check_grep "$DOC" "accountant_portal" "accountant_portal modulu"

check_grep "$DOC" "Paket Hakları — Demo" "demo entitlement"
check_grep "$DOC" "Paket Hakları — Starter" "starter entitlement"
check_grep "$DOC" "Paket Hakları — Pro" "pro entitlement"
check_grep "$DOC" "Paket Hakları — Enterprise" "enterprise entitlement"
check_grep "$DOC" "Paket Hakları — Accountant" "accountant entitlement"
check_grep "$DOC" "FREEZE_POLICY_DEFINED" "freeze policy defined"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_entitlement_matrix_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-3'" "step dogru"
check_json_expr "assert d['depends_on']=='pix2pi_packages_pricing_v1'" "depends_on dogru"
check_json_expr "assert d['default_policy']=='deny_unless_allowed'" "default policy dogru"
check_json_expr "assert d['tenant_safety']=='tenant_aware_required'" "tenant safety dogru"
check_json_expr "codes=sorted([p['code'] for p in d['packages']]); assert codes==sorted(['demo','starter','pro','enterprise','accountant'])" "5 paket entitlement kodu dogru"
check_json_expr "codes=[p['code'] for p in d['packages']]; assert len(codes)==len(set(codes))" "duplicate paket kodu yok"

check_json_expr "p={x['code']:x for x in d['packages']}; assert p['demo']['limits']['trial_days']==14" "demo trial 14"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['demo']['modules']['api_access']=='disabled'" "demo api disabled"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['demo']['live_financial_operation'] is False" "demo live finance false"

check_json_expr "p={x['code']:x for x in d['packages']}; assert p['starter']['limits']['user_limit']==3" "starter user limit 3"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['starter']['modules']['api_access']=='disabled'" "starter api disabled"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['starter']['modules']['export_basic']=='limited'" "starter export limited"

check_json_expr "p={x['code']:x for x in d['packages']}; assert p['pro']['limits']['branch_limit']==3" "pro branch limit 3"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['pro']['limits']['user_limit']==10" "pro user limit 10"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['pro']['modules']['reporting_advanced']=='enabled'" "pro reporting advanced enabled"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['pro']['modules']['api_access']=='limited'" "pro api limited"

check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['limits']['user_limit']=='custom'" "enterprise user custom"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['modules']['api_access']=='enabled'" "enterprise api enabled"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['modules']['audit_compliance']=='advanced'" "enterprise audit advanced"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['custom_override_allowed'] is True" "enterprise custom override"

check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['limits']['included_company_limit']==10" "accountant included company 10"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['limits']['per_company_monthly_try']==149" "accountant company monthly 149"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['modules']['accountant_portal']=='enabled'" "accountant portal enabled"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['company_based_billing'] is True" "accountant company billing true"

check_json_expr "assert d['subscription_state_policy']['active']=='full_package_rights'" "active policy dogru"
check_json_expr "assert d['subscription_state_policy']['past_due']=='restricted_write_possible'" "past_due policy dogru"
check_json_expr "assert d['subscription_state_policy']['suspended']=='commercial_access_restricted'" "suspended policy dogru"
check_json_expr "assert d['freeze_policy']['delete_data'] is False" "freeze delete_data false"
check_json_expr "assert d['freeze_policy']['api_access_on_suspend']=='disabled'" "freeze api disabled"
check_json_expr "assert d['seal']['FAZ_5_3_ENTITLEMENT_MATRIX_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_4_READY']=='YES'" "json 5-4 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  STEP4_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  STEP4_READY="NO ❌"
fi

{
  echo "FAZ_5_3_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_3_ENTITLEMENT_MATRIX_STATUS=$STEP_STATUS"
  echo "FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_3_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_3_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_4_READY=$STEP4_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-3 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-3 TEST OZETI ====="
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-3 ENTITLEMENT MATRIX TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-3 ENTITLEMENT MATRIX TEST SONUCU: HATA ❌ ====="
  exit 1
fi
