#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_9_revenue_metrics_mrr_arr_churn.md"
PREV_JSON="configs/faz5/revenue_metrics_policy_v1.json"
DOC="docs/faz5/5_10_public_pricing_developer_surfaces.md"
JSON_FILE="configs/faz5/public_pricing_developer_surface_v1.json"
PRICING_HTML="web/faz5/pricing/index.html"
DEVELOPER_HTML="web/faz5/developer/index.html"
REPORT_FILE="reports/faz5/FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SURFACES_REPORT.txt"

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

echo "===== FAZ 5-10 PUBLIC / PRICING / DEVELOPER SURFACES TEST BASLADI ====="

check_file "$PREV_DOC" "5-9 revenue metrics dokumani"
check_file "$PREV_JSON" "5-9 revenue metrics json"
check_file "$DOC" "5-10 public pricing developer dokumani"
check_file "$JSON_FILE" "5-10 public pricing developer json"
check_file "$PRICING_HTML" "pricing html"
check_file "$DEVELOPER_HTML" "developer html"

check_grep "$PREV_DOC" "FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=SEALED" "5-9 sealed"
check_grep "$PREV_DOC" "FAZ_5_10_READY=YES" "5-10 giris izni"

check_grep "$DOC" "STEP_NO=5-10" "step no"
check_grep "$DOC" "STEP_NAME=Public / Pricing / Developer Surfaces" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_10_PUBLIC_PRICING_DEVELOPER_STATUS=PASS" "5-10 pass"
check_grep "$DOC" "FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SEAL_STATUS=SEALED" "5-10 sealed"
check_grep "$DOC" "FAZ_5_11_READY=YES" "5-11 ready"

echo
echo "===== FAZ 5-10 YAPILAN ISLER KONTROLU ====="

check_done "5-10 — Public / Pricing / Developer Surfaces" "FAZ 5-10 — Public / Pricing / Developer Surfaces"

check_done "5-10.1 Public site yüzeyleri" "### 5-10.1 Public site yüzeyleri"
check_done "5-10.1.1 Landing page ticari metinleri" "### 5-10.1.1 Landing page ticari metinleri"
check_done "5-10.1.2 Paket / fiyat sayfası" "### 5-10.1.2 Paket / fiyat sayfası"
check_done "5-10.1.3 Paket karşılaştırma" "### 5-10.1.3 Paket karşılaştırma"
check_done "5-10.1.4 Demo başvuru sayfası" "### 5-10.1.4 Demo başvuru sayfası"
check_done "5-10.1.5 İletişim / satış formu" "### 5-10.1.5 İletişim / satış formu"
check_done "5-10.1.6 Legal footer linkleri" "### 5-10.1.6 Legal footer linkleri"

check_done "5-10.2 Pricing UI" "### 5-10.2 Pricing UI"
check_done "5-10.2.1 Demo kartı" "### 5-10.2.1 Demo kartı"
check_done "5-10.2.2 Starter kartı" "### 5-10.2.2 Starter kartı"
check_done "5-10.2.3 Pro kartı" "### 5-10.2.3 Pro kartı"
check_done "5-10.2.4 Enterprise özel teklif kartı" "### 5-10.2.4 Enterprise özel teklif kartı"
check_done "5-10.2.5 Muhasebeci paket kartı" "### 5-10.2.5 Muhasebeci paket kartı"
check_done "5-10.2.6 Aylık / yıllık toggle" "### 5-10.2.6 Aylık / yıllık toggle"
check_done "5-10.2.7 KDV notu" "### 5-10.2.7 KDV notu"
check_done "5-10.2.8 Public fiyat yayın kararı" "### 5-10.2.8 Public fiyat yayın kararı"

check_done "5-10.3 Developer surface" "### 5-10.3 Developer surface"
check_done "5-10.3.1 Developer docs landing" "### 5-10.3.1 Developer docs landing"
check_done "5-10.3.2 API docs taslak" "### 5-10.3.2 API docs taslak"
check_done "5-10.3.3 Sandbox açıklaması" "### 5-10.3.3 Sandbox açıklaması"
check_done "5-10.3.4 API key yönetim scope" "### 5-10.3.4 API key yönetim scope"
check_done "5-10.3.5 Rate limit / quota açıklaması" "### 5-10.3.5 Rate limit / quota açıklaması"
check_done "5-10.3.6 Webhook docs scope" "### 5-10.3.6 Webhook docs scope"

check_done "5-10.4 Web dosyaları" "### 5-10.4 Web dosyaları"
check_done "5-10.4.1 Public pricing HTML" "### 5-10.4.1 Public pricing HTML"
check_done "5-10.4.2 Developer landing HTML" "### 5-10.4.2 Developer landing HTML"
check_done "5-10.4.3 Nginx / static route hazırlığı" "### 5-10.4.3 Nginx / static route hazırlığı"
check_done "5-10.4.4 Mobile responsive kontrol" "### 5-10.4.4 Mobile responsive kontrol"
check_done "5-10.4.5 İçerik match kontrolü" "### 5-10.4.5 İçerik match kontrolü"

check_done "5-10.5 Test / mühür" "### 5-10.5 Test / mühür"
check_done "5-10.5.1 Public pricing UI test" "### 5-10.5.1 Public pricing UI test"
check_done "5-10.5.2 Developer surface test" "### 5-10.5.2 Developer surface test"
check_done "5-10.5.3 HTML content test" "### 5-10.5.3 HTML content test"
check_done "5-10.5.4 Responsive marker test" "### 5-10.5.4 Responsive marker test"
check_done "5-10.5.5 Report üretimi" "### 5-10.5.5 Report üretimi"
check_done "5-10.5.6 5-11 geçiş izni" "### 5-10.5.6 5-11 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_public_pricing_developer_surface_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-10'" "step dogru"
check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert 'pix2pi_subscription_billing_policy_v1' in d['depends_on']" "subscription dependency dogru"
check_json_expr "assert 'pix2pi_legal_compliance_policy_v1' in d['depends_on']" "legal dependency dogru"
check_json_expr "assert 'pix2pi_sales_demo_crm_policy_v1' in d['depends_on']" "sales crm dependency dogru"
check_json_expr "assert 'pix2pi_revenue_metrics_policy_v1' in d['depends_on']" "revenue dependency dogru"

check_json_expr "assert 'landing_page_commercial_copy' in d['public_site_surfaces']" "surface landing"
check_json_expr "assert 'pricing_page' in d['public_site_surfaces']" "surface pricing"
check_json_expr "assert 'package_comparison' in d['public_site_surfaces']" "surface comparison"
check_json_expr "assert 'demo_request_page' in d['public_site_surfaces']" "surface demo request"
check_json_expr "assert 'contact_sales_form' in d['public_site_surfaces']" "surface contact sales"
check_json_expr "assert 'legal_footer_links' in d['public_site_surfaces']" "surface legal footer"

check_json_expr "cards={x['code']:x for x in d['pricing_cards']}; assert cards['demo']['public_visible'] is True" "pricing demo visible"
check_json_expr "cards={x['code']:x for x in d['pricing_cards']}; assert cards['starter']['monthly_try']==799" "pricing starter monthly"
check_json_expr "cards={x['code']:x for x in d['pricing_cards']}; assert cards['pro']['monthly_try']==1999" "pricing pro monthly"
check_json_expr "cards={x['code']:x for x in d['pricing_cards']}; assert cards['enterprise']['price_display']=='Özel teklif'" "pricing enterprise custom"
check_json_expr "cards={x['code']:x for x in d['pricing_cards']}; assert cards['accountant']['per_company_monthly_try']==149" "pricing accountant per company"

check_json_expr "assert d['pricing_ui']['monthly_annual_toggle_planned'] is True" "pricing toggle planned"
check_json_expr "assert d['pricing_ui']['vat_note_required'] is True" "pricing vat note required"
check_json_expr "assert d['pricing_ui']['vat_policy']=='vat_excluded'" "pricing vat excluded"
check_json_expr "assert d['pricing_ui']['package_comparison_required'] is True" "pricing package comparison required"

check_json_expr "assert d['developer_surface']['developer_docs_landing'] is True" "developer docs landing"
check_json_expr "assert d['developer_surface']['api_docs_draft'] is True" "developer api docs"
check_json_expr "assert d['developer_surface']['sandbox_description'] is True" "developer sandbox"
check_json_expr "assert d['developer_surface']['api_key_management_scope'] is True" "developer api key scope"
check_json_expr "assert d['developer_surface']['rate_limit_quota_description'] is True" "developer quota"
check_json_expr "assert d['developer_surface']['webhook_docs_scope'] is True" "developer webhook"

check_json_expr "assert d['web_files']['pricing_html']=='web/faz5/pricing/index.html'" "web pricing path"
check_json_expr "assert d['web_files']['developer_html']=='web/faz5/developer/index.html'" "web developer path"
check_json_expr "assert d['web_files']['nginx_route_change'] is False" "web nginx route false"
check_json_expr "assert d['web_files']['responsive_required'] is True" "web responsive required"
check_json_expr "assert d['web_files']['content_match_required'] is True" "web content match required"

check_json_expr "assert 'terms_of_service' in d['legal_footer_links']" "footer terms"
check_json_expr "assert 'privacy_policy' in d['legal_footer_links']" "footer privacy"
check_json_expr "assert 'kvkk_notice' in d['legal_footer_links']" "footer kvkk"
check_json_expr "assert 'cookie_policy' in d['legal_footer_links']" "footer cookie"

check_json_expr "assert 'production_public_launch' in d['out_of_scope']" "out of scope production launch"
check_json_expr "assert 'nginx_route_change' in d['out_of_scope']" "out of scope nginx"
check_json_expr "assert 'real_api_key_generation' in d['out_of_scope']" "out of scope api key"
check_json_expr "assert 'runtime_webhook_engine' in d['out_of_scope']" "out of scope webhook"
check_json_expr "assert d['seal']['FAZ_5_10_PUBLIC_PRICING_DEVELOPER_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_11_READY']=='YES'" "json 5-11 ready"

echo
echo "===== HTML ICERIK KONTROLU ====="

check_grep "$PRICING_HTML" "Public Pricing Surface" "pricing title"
check_grep "$PRICING_HTML" "Demo" "pricing demo"
check_grep "$PRICING_HTML" "Starter" "pricing starter"
check_grep "$PRICING_HTML" "Pro" "pricing pro"
check_grep "$PRICING_HTML" "Enterprise" "pricing enterprise"
check_grep "$PRICING_HTML" "Muhasebeci" "pricing accountant"
check_grep "$PRICING_HTML" "KDV hariç" "pricing kdv note"
check_grep "$PRICING_HTML" "viewport" "pricing viewport"
check_grep "$PRICING_HTML" "@media" "pricing responsive media"

check_grep "$DEVELOPER_HTML" "Developer Surface" "developer title"
check_grep "$DEVELOPER_HTML" "API Docs Taslak" "developer api docs"
check_grep "$DEVELOPER_HTML" "Sandbox" "developer sandbox"
check_grep "$DEVELOPER_HTML" "API Key Yönetimi" "developer api key"
check_grep "$DEVELOPER_HTML" "Rate Limit / Quota" "developer quota"
check_grep "$DEVELOPER_HTML" "Webhook Docs" "developer webhook"
check_grep "$DEVELOPER_HTML" "viewport" "developer viewport"
check_grep "$DEVELOPER_HTML" "@media" "developer responsive media"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP11_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP11_READY="NO ❌"
fi

{
  echo "FAZ_5_10_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_10_PUBLIC_PRICING_DEVELOPER_STATUS=$STEP_STATUS"
  echo "FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_10_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_10_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_10_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_10_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_11_READY=$STEP11_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "PRICING_HTML=$PRICING_HTML"
  echo "DEVELOPER_HTML=$DEVELOPER_HTML"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-10 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-10 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-10 PUBLIC / PRICING / DEVELOPER SURFACES TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-10 PUBLIC / PRICING / DEVELOPER SURFACES TEST SONUCU: HATA ❌ ====="
  exit 1
fi
