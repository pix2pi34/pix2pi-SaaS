#!/usr/bin/env bash
set -u

PREV="docs/faz5/5_1_commercial_master_plan_scope_freeze.md"
DOC="docs/faz5/5_2_packages_pricing_architecture.md"
JSON_FILE="configs/faz5/packages_pricing_v1.json"

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

echo "===== FAZ 5-2 PACKAGES / PRICING TEST BASLADI ====="

check_file "$PREV" "5-1 scope freeze dokumani"
check_file "$DOC" "5-2 packages pricing dokumani"
check_file "$JSON_FILE" "pricing json catalog"

check_grep "$PREV" "FAZ_5_1_SCOPE_FREEZE_SEAL_STATUS=SEALED" "5-1 sealed"
check_grep "$PREV" "FAZ_5_2_READY=YES" "5-2 giris izni"

check_grep "$DOC" "STEP_NO=5-2" "step no"
check_grep "$DOC" "STEP_NAME=Packages / Pricing Architecture" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_2_PACKAGES_PRICING_STATUS=PASS" "5-2 pass"
check_grep "$DOC" "FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS=SEALED" "5-2 sealed"
check_grep "$DOC" "FAZ_5_3_READY=YES" "5-3 ready"

check_grep "$DOC" "demo" "demo paketi"
check_grep "$DOC" "starter" "starter paketi"
check_grep "$DOC" "pro" "pro paketi"
check_grep "$DOC" "enterprise" "enterprise paketi"
check_grep "$DOC" "accountant" "accountant paketi"
check_grep "$DOC" "Aylık: 799 TRY" "starter aylik fiyat"
check_grep "$DOC" "Aylık: 1.999 TRY" "pro aylik fiyat"
check_grep "$DOC" "Workspace aylık: 999 TRY" "accountant aylik fiyat"
check_grep "$DOC" "Özel teklif" "enterprise ozel teklif"
check_grep "$DOC" "UPSELL_READY" "upsell hazir"
check_grep "$DOC" "TRY_INTERNAL_V1" "try internal v1"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_packages_pricing_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-2'" "step dogru"
check_json_expr "assert d['currency']=='TRY'" "currency TRY"
check_json_expr "assert d['tax_policy']=='vat_excluded'" "tax policy dogru"
check_json_expr "codes=sorted([p['code'] for p in d['packages']]); assert codes==sorted(['demo','starter','pro','enterprise','accountant'])" "5 paket kodu dogru"
check_json_expr "codes=[p['code'] for p in d['packages']]; assert len(codes)==len(set(codes))" "duplicate paket kodu yok"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['demo']['monthly_try']==0" "demo monthly 0"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['demo']['trial_days']==14" "demo trial 14 gun"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['starter']['monthly_try']==799" "starter monthly 799"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['starter']['annual_try']==7990" "starter annual 7990"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['pro']['monthly_try']==1999" "pro monthly 1999"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['pro']['annual_try']==19990" "pro annual 19990"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['custom_pricing'] is True" "enterprise custom pricing"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['monthly_try'] is None" "enterprise monthly null"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['enterprise']['annual_try'] is None" "enterprise annual null"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['monthly_try']==999" "accountant monthly 999"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['annual_try']==9990" "accountant annual 9990"
check_json_expr "p={x['code']:x for x in d['packages']}; assert p['accountant']['per_company_monthly_try']==149" "accountant firma basi 149"
check_json_expr "assert len(d['upsell_items']) >= 10" "upsell sayisi yeterli"
check_json_expr "assert d['seal']['FAZ_5_2_PACKAGES_PRICING_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_3_READY']=='YES'" "json 5-3 ready"

echo
echo "===== FAZ 5-2 TEST OZETI ====="
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-2 PACKAGES / PRICING TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-2 PACKAGES / PRICING TEST SONUCU: HATA ❌ ====="
  exit 1
fi
