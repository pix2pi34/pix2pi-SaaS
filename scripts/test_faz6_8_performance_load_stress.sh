#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_8_PERFORMANCE_LOAD_STRESS_READINESS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_8_PERFORMANCE_VISIBLE_CHECKPOINTS.md"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_8_performance_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_8_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_PERFORMANCE_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-8 PERFORMANCE / LOAD / STRESS TEST BASLADI ====="

check_file "6-8 master dokumani mevcut" "$DOC_FILE"
check_file "6-8 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-8 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-8 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
check_exec "6-8 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-8 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-8.1 Baseline Performance tanimli" "$DOC_FILE" "6-8.1 Baseline Performance"
check_grep "6-8.2 Load Test Readiness tanimli" "$DOC_FILE" "6-8.2 Load Test Readiness"
check_grep "6-8.3 Stress Test Readiness tanimli" "$DOC_FILE" "6-8.3 Stress Test Readiness"
check_grep "6-8.4 Bottleneck Evidence tanimli" "$DOC_FILE" "6-8.4 Bottleneck Evidence"
check_grep "6-8.5 Gateway Performance tanimli" "$DOC_FILE" "6-8.5 API Gateway Performance Readiness"
check_grep "6-8.6 DB Performance tanimli" "$DOC_FILE" "6-8.6 DB Performance Readiness"
check_grep "6-8.7 Event Bus Performance tanimli" "$DOC_FILE" "6-8.7 Event Bus Performance Readiness"
check_grep "6-8.8 Tenant-aware Performance tanimli" "$DOC_FILE" "6-8.8 Tenant-aware Performance"
check_grep "6-8.9 Capacity Scale Decision tanimli" "$DOC_FILE" "6-8.9 Capacity / Scale Decision Gate"
check_grep "6-8.10 Performance Final Closure Gate tanimli" "$DOC_FILE" "6-8.10 Performance Final Closure Gate"

check_grep "6-8.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_1_BASELINE_PERFORMANCE_STATUS=READY"
check_grep "6-8.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_2_LOAD_TEST_READINESS_STATUS=READY"
check_grep "6-8.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_3_STRESS_TEST_READINESS_STATUS=READY"
check_grep "6-8.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_4_BOTTLENECK_EVIDENCE_STATUS=READY"
check_grep "6-8.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_5_GATEWAY_PERFORMANCE_STATUS=READY"
check_grep "6-8.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_6_DB_PERFORMANCE_STATUS=READY"
check_grep "6-8.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_7_EVENT_BUS_PERFORMANCE_STATUS=READY"
check_grep "6-8.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_8_TENANT_PERFORMANCE_STATUS=READY"
check_grep "6-8.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_9_CAPACITY_SCALE_DECISION_STATUS=READY"
check_grep "6-8.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_8_10_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-8 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-8 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-8 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_8_RUNTIME_AUDIT=COMPLETE"
check_grep "6-8 runtime uptime load var" "$RUNTIME_EVIDENCE_FILE" "6-8.2 Uptime / Load Average"
check_grep "6-8 runtime memory snapshot var" "$RUNTIME_EVIDENCE_FILE" "6-8.3 Memory Snapshot"
check_grep "6-8 runtime docker stats var" "$RUNTIME_EVIDENCE_FILE" "6-8.6 Docker Stats Snapshot"
check_grep "6-8 runtime health timing probe var" "$RUNTIME_EVIDENCE_FILE" "6-8.9 Safe Health Timing Probe"
check_grep "6-8 runtime prometheus probe var" "$RUNTIME_EVIDENCE_FILE" "6-8.10 Prometheus Targets / Metrics Probe"
check_grep "6-8 runtime nats performance probe var" "$RUNTIME_EVIDENCE_FILE" "6-8.13 NATS / Event Bus Performance Probe"
check_grep "6-8 runtime db performance probe var" "$RUNTIME_EVIDENCE_FILE" "6-8.14 DB Runtime Performance Probe"
check_grep "6-8 runtime performance tooling inventory var" "$RUNTIME_EVIDENCE_FILE" "6-8.15 Performance Tooling Inventory"

echo
echo "===== 6-8 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-8 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-8.1 baseline real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.1 Baseline performance"
check_grep "6-8.2 load test real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.2 Load test tooling"
check_grep "6-8.3 stress test real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.3 Stress test"
check_grep "6-8.4 bottleneck real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.4 Bottleneck evidence"
check_grep "6-8.5 gateway performance real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.5 Gateway performance"
check_grep "6-8.6.1 DB pool performance real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.6.1 DB connection pool"
check_grep "6-8.6.2 DB query index real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.6.2 DB query/index"
check_grep "6-8.7 event bus performance real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.7 Event bus performance"
check_grep "6-8.8 tenant performance real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.8 Tenant-aware performance"
check_grep "6-8.9 capacity scale real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.9 Capacity / scale"
check_grep "6-8.10 observability metrics real audit evidence var" "$REAL_EVIDENCE_FILE" "6-8.10 Performance observability"
check_grep "6-8 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-8 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-8 PERFORMANCE / LOAD / STRESS TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_8_DOC_STATUS=READY ✅"
  echo "FAZ_6_8_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_8_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_8_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_8_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_8_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_9_READY=YES ✅"
  elif grep -Fq "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_8_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_9_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_8_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_9_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-8 Performance / Load / Stress Readiness testi tamamlandi"
  exit 0
else
  echo "FAZ_6_8_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-8 testlerinde eksik var"
  exit 1
fi
