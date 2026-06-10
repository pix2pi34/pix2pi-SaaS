#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_10_CDN_WAF_DNS_EDGE_READINESS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_10_EDGE_VISIBLE_CHECKPOINTS.md"
DNS_SCRIPT="scripts/pix2pi_edge_dns_probe.sh"
HTTP_SCRIPT="scripts/pix2pi_edge_http_smoke.sh"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_10_edge_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_10_real_implementation.sh"

DNS_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_EDGE_DNS_PROBE_EVIDENCE.md"
HTTP_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_EDGE_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_exec() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 6-10 CDN / WAF / DNS / EDGE TEST BASLADI ====="

check_file "6-10 master dokumani mevcut" "$DOC_FILE"
check_file "6-10 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-10 DNS probe script mevcut" "$DNS_SCRIPT"
check_file "6-10 HTTP smoke script mevcut" "$HTTP_SCRIPT"
check_file "6-10 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-10 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"

check_exec "6-10 DNS probe script executable" "$DNS_SCRIPT"
check_exec "6-10 HTTP smoke script executable" "$HTTP_SCRIPT"
check_exec "6-10 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-10 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-10.1 DNS Readiness tanimli" "$DOC_FILE" "6-10.1 DNS Readiness"
check_grep "6-10.2 TLS HTTPS tanimli" "$DOC_FILE" "6-10.2 TLS / HTTPS Readiness"
check_grep "6-10.3 CDN Cache tanimli" "$DOC_FILE" "6-10.3 CDN / Cache Readiness"
check_grep "6-10.4 WAF DDoS Bot tanimli" "$DOC_FILE" "6-10.4 WAF / DDoS / Bot Guardrails"
check_grep "6-10.5 Nginx Edge tanimli" "$DOC_FILE" "6-10.5 Nginx Edge / Reverse Proxy Readiness"
check_grep "6-10.6 Public Route Smoke tanimli" "$DOC_FILE" "6-10.6 Public Route Smoke"
check_grep "6-10.7 Origin Exposure tanimli" "$DOC_FILE" "6-10.7 Origin Exposure / Internal Port Safety"
check_grep "6-10.8 Edge Observability tanimli" "$DOC_FILE" "6-10.8 Edge Observability"
check_grep "6-10.9 Edge Incident Runbook tanimli" "$DOC_FILE" "6-10.9 Edge Incident / Runbook"
check_grep "6-10.10 Edge Final Closure Gate tanimli" "$DOC_FILE" "6-10.10 Edge Final Closure Gate"

check_grep "6-10.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_1_DNS_READINESS_STATUS=READY"
check_grep "6-10.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_2_TLS_HTTPS_STATUS=READY"
check_grep "6-10.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_3_CDN_CACHE_STATUS=READY"
check_grep "6-10.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_4_WAF_DDOS_BOT_STATUS=READY"
check_grep "6-10.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_5_NGINX_EDGE_PROXY_STATUS=READY"
check_grep "6-10.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_6_PUBLIC_ROUTE_SMOKE_STATUS=READY"
check_grep "6-10.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_7_ORIGIN_EXPOSURE_STATUS=READY"
check_grep "6-10.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_8_EDGE_OBSERVABILITY_STATUS=READY"
check_grep "6-10.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_9_EDGE_INCIDENT_RUNBOOK_STATUS=READY"
check_grep "6-10.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_10_10_EDGE_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-10 EDGE GUARD SCRIPTS CALISTIRILIYOR ====="
bash "$DNS_SCRIPT"
bash "$HTTP_SCRIPT"

check_file "6-10 DNS evidence mevcut" "$DNS_EVIDENCE_FILE"
check_file "6-10 HTTP smoke evidence mevcut" "$HTTP_EVIDENCE_FILE"
check_grep "6-10 DNS probe complete muhru var" "$DNS_EVIDENCE_FILE" "FAZ_6_10_EDGE_DNS_PROBE_STATUS=COMPLETE"
check_grep "6-10 HTTP smoke complete muhru var" "$HTTP_EVIDENCE_FILE" "FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE"

echo
echo "===== 6-10 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-10 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-10 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_10_RUNTIME_AUDIT=COMPLETE"
check_grep "6-10 runtime DNS var" "$RUNTIME_EVIDENCE_FILE" "6-10.2 DNS Resolution Runtime"
check_grep "6-10 runtime TLS var" "$RUNTIME_EVIDENCE_FILE" "6-10.3 TLS Certificate Probe"
check_grep "6-10 runtime HTTPS header var" "$RUNTIME_EVIDENCE_FILE" "6-10.4 Public HTTPS Header Probe"
check_grep "6-10 runtime GET content var" "$RUNTIME_EVIDENCE_FILE" "6-10.5 Public GET Content Probe"
check_grep "6-10 runtime pilot GET content var" "$RUNTIME_EVIDENCE_FILE" "6-10.6 Public Pilot GET Content Probe"
check_grep "6-10 runtime nginx inventory var" "$RUNTIME_EVIDENCE_FILE" "6-10.8 Nginx Edge Config Inventory"
check_grep "6-10 runtime origin exposure var" "$RUNTIME_EVIDENCE_FILE" "6-10.9 Origin / Internal Port Exposure Inventory"

echo
echo "===== 6-10 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-10 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-10.1 DNS real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.1 DNS readiness"
check_grep "6-10.2 TLS real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.2 TLS / HTTPS"
check_grep "6-10.3 CDN cache real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.3 CDN / cache"
check_grep "6-10.4 WAF DDoS real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.4 WAF / DDoS"
check_grep "6-10.5 Nginx edge real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.5 Nginx edge"
check_grep "6-10.6 Public GET real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.6 Public route GET"
check_grep "6-10.7 Origin exposure real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.7 Origin exposure"
check_grep "6-10.8 Edge observability real audit evidence var" "$REAL_EVIDENCE_FILE" "6-10.8 Edge observability"
check_grep "6-10 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-10 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_10_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-10 CDN / WAF / DNS / EDGE TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_10_DOC_STATUS=READY ✅"
  echo "FAZ_6_10_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_10_EDGE_GUARD_SCRIPTS_STATUS=READY ✅"
  echo "FAZ_6_10_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_10_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_10_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_10_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_11_READY=YES ✅"
  elif grep -Fq "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_10_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_11_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_10_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_11_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-10 CDN / WAF / DNS / Edge Readiness testi tamamlandi"
  exit 0
else
  echo "FAZ_6_10_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-10 testlerinde eksik var"
  exit 1
fi
