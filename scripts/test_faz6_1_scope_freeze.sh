#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_MASTER_PLAN_SCOPE_FREEZE.md"

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

echo "===== FAZ 6-1 TEST BASLADI ====="

check_file "6-1 Master plan dosyasi mevcut" "$DOC_FILE"

check_grep "6-1.1 Faz 6 ana hedefi tanimli" "$DOC_FILE" "FAZ 6'nin ana hedefi"
check_grep "6-1.2 Faz 6 kapsami tanimli" "$DOC_FILE" "Scale / SRE / DR / Production Hardening"
check_grep "6-1.3 Faz disi isler tanimli" "$DOC_FILE" "FAZ 6 yeni ticari ozellik fazi degildir"
check_grep "6-1.4 Test ve cikis kurali tanimli" "$DOC_FILE" "PASS olmadan sonraki adima gecilmez"
check_grep "6-1.5 Faz 6-1 muhur hedefi tanimli" "$DOC_FILE" "FAZ_6_1_FINAL_STATUS=PASS"
check_grep "6-1.6 Sonraki adim hazirlik tanimli" "$DOC_FILE" "FAZ_6_2_READY=YES"

check_grep "6-2 DB-L8 HA / Scale / Ops Readiness tanimli" "$DOC_FILE" "6-2 DB-L8 HA / Scale / Ops Readiness"
check_grep "6-2.1 Read / write split readiness tanimli" "$DOC_FILE" "6-2.1 Read / write split readiness"
check_grep "6-2.1.1 Write path tanimli" "$DOC_FILE" "6-2.1.1 Write path"
check_grep "6-2.1.2 Read path tanimli" "$DOC_FILE" "6-2.1.2 Read path"
check_grep "6-2.1.3 Fallback tanimli" "$DOC_FILE" "6-2.1.3 Fallback"
check_grep "6-2.8 DB final closure gate tanimli" "$DOC_FILE" "6-2.8 DB final closure gate"

check_grep "6-3 Multi-node Foundation tanimli" "$DOC_FILE" "6-3 Multi-node Foundation / Scale-out Readiness"
check_grep "6-3.1 Cok node servis yerlesimi tanimli" "$DOC_FILE" "6-3.1 Cok node servis yerlesimi"
check_grep "6-3.2 Stateful stateless ayrimi tanimli" "$DOC_FILE" "6-3.2 Stateful / stateless ayrimi"
check_grep "6-3.6 Scale-out closure gate tanimli" "$DOC_FILE" "6-3.6 Scale-out closure gate"

check_grep "6-4 Event Bus SRE tanimli" "$DOC_FILE" "6-4 Event Bus / Queue / Backlog SRE Readiness"
check_grep "6-4.1 Event bus runtime health tanimli" "$DOC_FILE" "6-4.1 Event bus runtime health"
check_grep "6-4.2 Backlog olcum standardi tanimli" "$DOC_FILE" "6-4.2 Backlog olcum standardi"
check_grep "6-4.3 DLQ operasyon standardi tanimli" "$DOC_FILE" "6-4.3 DLQ operasyon standardi"
check_grep "6-4.4 Replay operasyon standardi tanimli" "$DOC_FILE" "6-4.4 Replay operasyon standardi"
check_grep "6-4.6 Event bus closure gate tanimli" "$DOC_FILE" "6-4.6 Event bus closure gate"

check_grep "6-5 Observability tanimli" "$DOC_FILE" "6-5 Observability / Early Warning / SRE Dashboard"
check_grep "6-5.1 Prometheus metrik standardi tanimli" "$DOC_FILE" "6-5.1 Prometheus metrik standardi"
check_grep "6-5.2 Grafana dashboard seti tanimli" "$DOC_FILE" "6-5.2 Grafana dashboard seti"
check_grep "6-5.3 Early warning alarm matrisi tanimli" "$DOC_FILE" "6-5.3 Early warning alarm matrisi"
check_grep "6-5.5 SRE dashboard closure gate tanimli" "$DOC_FILE" "6-5.5 SRE dashboard closure gate"

check_grep "6-6 Backup Restore DR tanimli" "$DOC_FILE" "6-6 Backup / Restore / Disaster Recovery"
check_grep "6-6.1 Backup inventory tanimli" "$DOC_FILE" "6-6.1 Backup inventory"
check_grep "6-6.2 Restore drill tanimli" "$DOC_FILE" "6-6.2 Restore drill"
check_grep "6-6.3 RPO RTO hedefleri tanimli" "$DOC_FILE" "6-6.3 RPO / RTO hedefleri"
check_grep "6-6.5 DR closure gate tanimli" "$DOC_FILE" "6-6.5 DR closure gate"

check_grep "6-7 Security Hardening tanimli" "$DOC_FILE" "6-7 Security Hardening / Production Guardrails"
check_grep "6-7.1 Secret env hardening tanimli" "$DOC_FILE" "6-7.1 Secret / env hardening"
check_grep "6-7.2 Nginx hardening tanimli" "$DOC_FILE" "6-7.2 Nginx hardening"
check_grep "6-7.3 Firewall port policy tanimli" "$DOC_FILE" "6-7.3 Firewall / port policy"
check_grep "6-7.5 Security closure gate tanimli" "$DOC_FILE" "6-7.5 Security closure gate"

check_grep "6-8 Performance Load Stress tanimli" "$DOC_FILE" "6-8 Performance / Load / Stress Readiness"
check_grep "6-8.1 Baseline performance tanimli" "$DOC_FILE" "6-8.1 Baseline performance"
check_grep "6-8.2 Load test tanimli" "$DOC_FILE" "6-8.2 Load test"
check_grep "6-8.3 Stress test tanimli" "$DOC_FILE" "6-8.3 Stress test"
check_grep "6-8.5 Performance closure gate tanimli" "$DOC_FILE" "6-8.5 Performance closure gate"

check_grep "6-9 Release Rollback Deploy Safety tanimli" "$DOC_FILE" "6-9 Release / Rollback / Deploy Safety"
check_grep "6-9.1 Release standardi tanimli" "$DOC_FILE" "6-9.1 Release standardi"
check_grep "6-9.2 Rollback standardi tanimli" "$DOC_FILE" "6-9.2 Rollback standardi"
check_grep "6-9.3 Pre-deploy check tanimli" "$DOC_FILE" "6-9.3 Pre-deploy check"
check_grep "6-9.5 Release closure gate tanimli" "$DOC_FILE" "6-9.5 Release closure gate"

check_grep "6-10 CDN WAF DNS Edge tanimli" "$DOC_FILE" "6-10 CDN / WAF / DNS / Edge Readiness"
check_grep "6-10.1 DNS inventory tanimli" "$DOC_FILE" "6-10.1 DNS inventory"
check_grep "6-10.2 CDN policy tanimli" "$DOC_FILE" "6-10.2 CDN policy"
check_grep "6-10.3 WAF policy tanimli" "$DOC_FILE" "6-10.3 WAF policy"
check_grep "6-10.5 Edge closure gate tanimli" "$DOC_FILE" "6-10.5 Edge closure gate"

check_grep "6-11 Ops Console Incident Runbook tanimli" "$DOC_FILE" "6-11 Ops Console / Incident / Runbook Readiness"
check_grep "6-11.1 Ops console inventory tanimli" "$DOC_FILE" "6-11.1 Ops console inventory"
check_grep "6-11.2 Incident severity matrix tanimli" "$DOC_FILE" "6-11.2 Incident severity matrix"
check_grep "6-11.3 Runbook seti tanimli" "$DOC_FILE" "6-11.3 Runbook seti"
check_grep "6-11.5 Ops closure gate tanimli" "$DOC_FILE" "6-11.5 Ops closure gate"

check_grep "6-12 Production Readiness Final Gate tanimli" "$DOC_FILE" "6-12 Production Readiness / Final Hardening Gate"
check_grep "6-12.1 Final checklist tanimli" "$DOC_FILE" "6-12.1 Final checklist"
check_grep "6-12.2 Blocker review tanimli" "$DOC_FILE" "6-12.2 Blocker review"
check_grep "6-12.3 Final smoke test tanimli" "$DOC_FILE" "6-12.3 Final smoke test"
check_grep "6-12.4 Final Go No-Go tanimli" "$DOC_FILE" "6-12.4 Final Go / No-Go"
check_grep "6-12.5 Final seal tanimli" "$DOC_FILE" "6-12.5 Final seal"

echo
echo "===== FAZ 6-1 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_1_PLAN_FILE=READY ✅"
  echo "FAZ_6_1_SCOPE_FREEZE=YES ✅"
  echo "FAZ_6_1_TEST_SCRIPT=READY ✅"
  echo "FAZ_6_1_TEST_STATUS=PASS ✅"
  echo "FAZ_6_1_FINAL_STATUS=PASS ✅"
  echo "FAZ_6_2_READY=YES ✅"
  echo "OK ✅ FAZ 6-1 Master Plan / Scope Freeze tamamlandi"
  exit 0
else
  echo "FAZ_6_1_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-1 testlerinde eksik var"
  exit 1
fi
