#!/usr/bin/env bash
set -u

PREV_DOC="docs/faz5/5_6_legal_compliance_kvkk_terms.md"
PREV_JSON="configs/faz5/legal_compliance_policy_v1.json"
DOC="docs/faz5/5_7_support_sla_incident_escalation.md"
JSON_FILE="configs/faz5/support_sla_incident_policy_v1.json"
REPORT_FILE="reports/faz5/FAZ_5_7_SUPPORT_SLA_INCIDENT_ESCALATION_REPORT.txt"

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

echo "===== FAZ 5-7 SUPPORT / SLA / INCIDENT / ESCALATION TEST BASLADI ====="

check_file "$PREV_DOC" "5-6 legal compliance dokumani"
check_file "$PREV_JSON" "5-6 legal compliance json"
check_file "$DOC" "5-7 support sla dokumani"
check_file "$JSON_FILE" "5-7 support sla json"

check_grep "$PREV_DOC" "FAZ_5_6_LEGAL_COMPLIANCE_SEAL_STATUS=SEALED" "5-6 sealed"
check_grep "$PREV_DOC" "FAZ_5_7_READY=YES" "5-7 giris izni"

check_grep "$DOC" "STEP_NO=5-7" "step no"
check_grep "$DOC" "STEP_NAME=Support / SLA / Incident / Escalation" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_7_SUPPORT_SLA_STATUS=PASS" "5-7 pass"
check_grep "$DOC" "FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=SEALED" "5-7 sealed"
check_grep "$DOC" "FAZ_5_8_READY=YES" "5-8 ready"

echo
echo "===== FAZ 5-7 YAPILAN ISLER KONTROLU ====="

check_done "5-7 — Support / SLA / Incident / Escalation" "FAZ 5-7 — Support / SLA / Incident / Escalation"

check_done "5-7.1 Destek kanalları" "### 5-7.1 Destek kanalları"
check_done "5-7.1.1 E-posta destek" "### 5-7.1.1 E-posta destek"
check_done "5-7.1.2 WhatsApp / telefon destek kararı" "### 5-7.1.2 WhatsApp / telefon destek kararı"
check_done "5-7.1.3 Panel içi destek talebi" "### 5-7.1.3 Panel içi destek talebi"
check_done "5-7.1.4 Enterprise özel kanal" "### 5-7.1.4 Enterprise özel kanal"
check_done "5-7.1.5 Muhasebeci destek kanalı" "### 5-7.1.5 Muhasebeci destek kanalı"

check_done "5-7.2 SLA seviyeleri" "### 5-7.2 SLA seviyeleri"
check_done "5-7.2.1 Demo SLA yok / best effort" "### 5-7.2.1 Demo SLA yok / best effort"
check_done "5-7.2.2 Starter standart destek" "### 5-7.2.2 Starter standart destek"
check_done "5-7.2.3 Pro öncelikli destek" "### 5-7.2.3 Pro öncelikli destek"
check_done "5-7.2.4 Enterprise SLA" "### 5-7.2.4 Enterprise SLA"
check_done "5-7.2.5 Muhasebeci operasyon desteği" "### 5-7.2.5 Muhasebeci operasyon desteği"

check_done "5-7.3 Incident sınıfları" "### 5-7.3 Incident sınıfları"
check_done "5-7.3.1 P0 kritik sistem kesintisi" "### 5-7.3.1 P0 kritik sistem kesintisi"
check_done "5-7.3.2 P1 finansal / veri riski" "### 5-7.3.2 P1 finansal / veri riski"
check_done "5-7.3.3 P2 iş akışı bozulması" "### 5-7.3.3 P2 iş akışı bozulması"
check_done "5-7.3.4 P3 düşük öncelikli hata" "### 5-7.3.4 P3 düşük öncelikli hata"
check_done "5-7.3.5 P4 soru / istek" "### 5-7.3.5 P4 soru / istek"

check_done "5-7.4 Escalation matrix" "### 5-7.4 Escalation matrix"
check_done "5-7.4.1 İlk triage" "### 5-7.4.1 İlk triage"
check_done "5-7.4.2 Teknik inceleme" "### 5-7.4.2 Teknik inceleme"
check_done "5-7.4.3 Güvenlik escalation" "### 5-7.4.3 Güvenlik escalation"
check_done "5-7.4.4 Finansal escalation" "### 5-7.4.4 Finansal escalation"
check_done "5-7.4.5 Müşteri bilgilendirme" "### 5-7.4.5 Müşteri bilgilendirme"
check_done "5-7.4.6 Kapanış ve postmortem" "### 5-7.4.6 Kapanış ve postmortem"

check_done "5-7.5 Destek şablonları" "### 5-7.5 Destek şablonları"
check_done "5-7.5.1 Talep alındı mesajı" "### 5-7.5.1 Talep alındı mesajı"
check_done "5-7.5.2 Kesinti bildirimi" "### 5-7.5.2 Kesinti bildirimi"
check_done "5-7.5.3 Çözüm bildirimi" "### 5-7.5.3 Çözüm bildirimi"
check_done "5-7.5.4 Planlı bakım bildirimi" "### 5-7.5.4 Planlı bakım bildirimi"
check_done "5-7.5.5 Gecikme bildirimi" "### 5-7.5.5 Gecikme bildirimi"

check_done "5-7.6 Test / mühür" "### 5-7.6 Test / mühür"
check_done "5-7.6.1 Support doc test" "### 5-7.6.1 Support doc test"
check_done "5-7.6.2 SLA JSON test" "### 5-7.6.2 SLA JSON test"
check_done "5-7.6.3 Incident class test" "### 5-7.6.3 Incident class test"
check_done "5-7.6.4 Escalation matrix test" "### 5-7.6.4 Escalation matrix test"
check_done "5-7.6.5 Report üretimi" "### 5-7.6.5 Report üretimi"
check_done "5-7.6.6 5-8 geçiş izni" "### 5-7.6.6 5-8 geçiş izni"

echo
echo "===== JSON FORMAT KONTROLU ====="

if python3 -m json.tool "$JSON_FILE" >/dev/null 2>&1; then
  pass "json format gecerli"
else
  fail_soft "json format bozuk"
fi

echo
echo "===== JSON ICERIK KONTROLU ====="

check_json_expr "assert d['catalog_code']=='pix2pi_support_sla_incident_policy_v1'" "catalog_code dogru"
check_json_expr "assert d['phase']=='FAZ_5'" "phase dogru"
check_json_expr "assert d['step']=='5-7'" "step dogru"
check_json_expr "assert 'pix2pi_packages_pricing_v1' in d['depends_on']" "pricing dependency dogru"
check_json_expr "assert 'pix2pi_entitlement_matrix_v1' in d['depends_on']" "entitlement dependency dogru"
check_json_expr "assert 'pix2pi_subscription_billing_policy_v1' in d['depends_on']" "subscription dependency dogru"
check_json_expr "assert 'pix2pi_tenant_lifecycle_policy_v1' in d['depends_on']" "tenant lifecycle dependency dogru"
check_json_expr "assert 'pix2pi_legal_compliance_policy_v1' in d['depends_on']" "legal dependency dogru"

check_json_expr "channels={x['code']:x for x in d['support_channels']}; assert channels['email_support']['enabled'] is True" "email support enabled"
check_json_expr "channels={x['code']:x for x in d['support_channels']}; assert 'starter' in channels['email_support']['available_for']" "starter email support"
check_json_expr "channels={x['code']:x for x in d['support_channels']}; assert channels['whatsapp_phone_limited']['starter_default'] is False" "whatsapp starter default false"
check_json_expr "channels={x['code']:x for x in d['support_channels']}; assert channels['in_panel_ticket']['enabled_future'] is True" "panel ticket future"
check_json_expr "channels={x['code']:x for x in d['support_channels']}; assert channels['enterprise_private_channel']['contract_based'] is True" "enterprise private contract"
check_json_expr "channels={x['code']:x for x in d['support_channels']}; assert channels['accountant_support_channel']['company_based_support'] is True" "accountant company support"

check_json_expr "assert d['sla_levels']['demo']['level']=='best_effort'" "demo best effort"
check_json_expr "assert d['sla_levels']['demo']['guaranteed_sla'] is False" "demo no guaranteed sla"
check_json_expr "assert d['sla_levels']['starter']['level']=='standard'" "starter standard"
check_json_expr "assert d['sla_levels']['pro']['level']=='priority'" "pro priority"
check_json_expr "assert d['sla_levels']['enterprise']['guaranteed_sla'] is True" "enterprise guaranteed sla"
check_json_expr "assert d['sla_levels']['accountant']['level']=='accountant_operations'" "accountant operations"

check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P0']['severity']=='critical'" "P0 critical"
check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P0']['requires_immediate_escalation'] is True" "P0 escalation"
check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P1']['severity']=='high'" "P1 high"
check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P1']['requires_immediate_escalation'] is True" "P1 escalation"
check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P2']['severity']=='medium'" "P2 medium"
check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P3']['severity']=='low'" "P3 low"
check_json_expr "classes={x['code']:x for x in d['incident_classes']}; assert classes['P4']['severity']=='request'" "P4 request"

check_json_expr "assert 'tenant_id' in d['escalation_matrix']['first_triage']['required_fields']" "triage tenant id"
check_json_expr "assert 'user_id' in d['escalation_matrix']['first_triage']['required_fields']" "triage user id"
check_json_expr "assert 'package_code' in d['escalation_matrix']['first_triage']['required_fields']" "triage package code"
check_json_expr "assert 'incident_class' in d['escalation_matrix']['first_triage']['required_fields']" "triage incident class"
check_json_expr "assert d['escalation_matrix']['technical_review']['enabled'] is True" "technical review enabled"
check_json_expr "assert 'P0' in d['escalation_matrix']['technical_review']['applies_to']" "technical review P0"
check_json_expr "assert 'auth_bypass' in d['escalation_matrix']['security_escalation']['triggers']" "security auth bypass"
check_json_expr "assert 'tenant_isolation_risk' in d['escalation_matrix']['security_escalation']['triggers']" "security tenant risk"
check_json_expr "assert 'wrong_accounting_record' in d['escalation_matrix']['financial_escalation']['triggers']" "financial accounting trigger"
check_json_expr "assert 'payment_issue' in d['escalation_matrix']['financial_escalation']['triggers']" "financial payment trigger"
check_json_expr "assert d['escalation_matrix']['customer_communication']['enabled'] is True" "customer communication enabled"
check_json_expr "assert d['escalation_matrix']['closure_postmortem']['root_cause_required'] is True" "postmortem root cause"

check_json_expr "templates={x['code']:x for x in d['support_templates']}; assert templates['ticket_received']['required'] is True" "template ticket received"
check_json_expr "templates={x['code']:x for x in d['support_templates']}; assert 'P0' in templates['outage_notice']['required_for']" "template outage P0"
check_json_expr "templates={x['code']:x for x in d['support_templates']}; assert templates['resolution_notice']['required'] is True" "template resolution"
check_json_expr "templates={x['code']:x for x in d['support_templates']}; assert templates['planned_maintenance_notice']['required'] is True" "template planned maintenance"
check_json_expr "templates={x['code']:x for x in d['support_templates']}; assert templates['delay_notice']['required'] is True" "template delay"

check_json_expr "assert d['package_support_map']['demo']=='best_effort'" "support map demo"
check_json_expr "assert d['package_support_map']['starter']=='standard'" "support map starter"
check_json_expr "assert d['package_support_map']['pro']=='priority'" "support map pro"
check_json_expr "assert d['package_support_map']['enterprise']=='contract_sla'" "support map enterprise"
check_json_expr "assert d['package_support_map']['accountant']=='accountant_operations'" "support map accountant"

check_json_expr "assert 'real_ticket_system_setup' in d['out_of_scope']" "out of scope ticket system"
check_json_expr "assert 'automatic_sla_timer_worker' in d['out_of_scope']" "out of scope sla worker"
check_json_expr "assert 'automatic_customer_notification_service' in d['out_of_scope']" "out of scope notification service"
check_json_expr "assert d['seal']['FAZ_5_7_SUPPORT_SLA_STATUS']=='PASS'" "json seal PASS"
check_json_expr "assert d['seal']['FAZ_5_7_SUPPORT_SLA_SEAL_STATUS']=='SEALED'" "json seal SEALED"
check_json_expr "assert d['seal']['FAZ_5_8_READY']=='YES'" "json 5-8 ready"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  TEST_STATUS="PASS ✅"
  STEP_STATUS="PASS ✅"
  SEAL_STATUS="SEALED ✅"
  DONE_STATUS="PASS ✅"
  STEP8_READY="YES ✅"
else
  TEST_STATUS="HATA ❌"
  STEP_STATUS="BLOCKED ❌"
  SEAL_STATUS="OPEN ❌"
  DONE_STATUS="HATA ❌"
  STEP8_READY="NO ❌"
fi

{
  echo "FAZ_5_7_TEST_STATUS=$TEST_STATUS"
  echo "FAZ_5_7_SUPPORT_SLA_STATUS=$STEP_STATUS"
  echo "FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=$SEAL_STATUS"
  echo "FAZ_5_7_DONE_CHECKLIST_STATUS=$DONE_STATUS"
  echo "FAZ_5_7_DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
  echo "FAZ_5_7_OK_COUNT=$OK_COUNT"
  echo "FAZ_5_7_FAIL_COUNT=$FAIL_COUNT"
  echo "FAZ_5_8_READY=$STEP8_READY"
  echo "DOC_FILE=$DOC"
  echo "JSON_FILE=$JSON_FILE"
  echo "REPORT_CREATED_AT=$(date -Is)"
} > "$REPORT_FILE"

echo
echo "===== FAZ 5-7 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 5-7 TEST OZETI ====="
echo "DONE_CHECK_COUNT=$DONE_CHECK_COUNT"
echo "OK_COUNT=$OK_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 5-7 SUPPORT / SLA / INCIDENT / ESCALATION TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-7 SUPPORT / SLA / INCIDENT / ESCALATION TEST SONUCU: HATA ❌ ====="
  exit 1
fi
