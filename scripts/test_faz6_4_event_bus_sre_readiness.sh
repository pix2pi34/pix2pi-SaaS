#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_4_EVENT_BUS_QUEUE_BACKLOG_SRE_READINESS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_4_EVENT_BUS_VISIBLE_CHECKPOINTS.md"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_4_event_bus_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_4_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_4_EVENT_BUS_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_4_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-4 EVENT BUS SRE READINESS TEST BASLADI ====="

check_file "6-4 master dokumani mevcut" "$DOC_FILE"
check_file "6-4 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-4 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-4 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
check_exec "6-4 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-4 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-4.1 Event Bus Runtime Health tanimli" "$DOC_FILE" "6-4.1 Event Bus Runtime Health"
check_grep "6-4.2 Backlog Pending Lag tanimli" "$DOC_FILE" "6-4.2 Backlog / Pending / Lag Standardi"
check_grep "6-4.3 Retry Ack Nack tanimli" "$DOC_FILE" "6-4.3 Retry / Ack / Nack Standardi"
check_grep "6-4.4 DLQ Dead-letter tanimli" "$DOC_FILE" "6-4.4 DLQ / Dead-letter Standardi"
check_grep "6-4.5 Replay tanimli" "$DOC_FILE" "6-4.5 Replay Standardi"
check_grep "6-4.6 Poison Message tanimli" "$DOC_FILE" "6-4.6 Poison Message Runbook"
check_grep "6-4.7 Idempotency Dedupe tanimli" "$DOC_FILE" "6-4.7 Idempotency / Dedupe Standardi"
check_grep "6-4.8 Tenant-aware Event Safety tanimli" "$DOC_FILE" "6-4.8 Tenant-aware Event Safety"
check_grep "6-4.9 Event Observability tanimli" "$DOC_FILE" "6-4.9 Event Observability"
check_grep "6-4.10 Final Closure Gate tanimli" "$DOC_FILE" "6-4.10 Event Bus Final Closure Gate"

check_grep "6-4.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_1_EVENT_BUS_RUNTIME_HEALTH_STATUS=READY"
check_grep "6-4.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_2_BACKLOG_LAG_STATUS=READY"
check_grep "6-4.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_3_RETRY_ACK_NACK_STATUS=READY"
check_grep "6-4.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_4_DLQ_DEAD_LETTER_STATUS=READY"
check_grep "6-4.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_5_REPLAY_STATUS=READY"
check_grep "6-4.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_6_POISON_MESSAGE_RUNBOOK_STATUS=READY"
check_grep "6-4.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_7_IDEMPOTENCY_DEDUPE_STATUS=READY"
check_grep "6-4.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_8_TENANT_AWARE_EVENT_STATUS=READY"
check_grep "6-4.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_9_EVENT_OBSERVABILITY_STATUS=READY"
check_grep "6-4.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_4_10_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-4 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-4 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-4 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_4_RUNTIME_AUDIT=COMPLETE"
check_grep "6-4 runtime docker inventory var" "$RUNTIME_EVIDENCE_FILE" "6-4.2 Docker Event Bus Containers"
check_grep "6-4 runtime systemd inventory var" "$RUNTIME_EVIDENCE_FILE" "6-4.3 Event-related Systemd Services"
check_grep "6-4 runtime port inventory var" "$RUNTIME_EVIDENCE_FILE" "6-4.4 NATS / Event Ports"
check_grep "6-4 runtime varz probe var" "$RUNTIME_EVIDENCE_FILE" "6-4.5 NATS Monitoring varz Probe"
check_grep "6-4 runtime jsz probe var" "$RUNTIME_EVIDENCE_FILE" "6-4.6 NATS JetStream jsz Probe"
check_grep "6-4 runtime event env inventory var" "$RUNTIME_EVIDENCE_FILE" "6-4.9 Event Env Inventory"
check_grep "6-4 runtime event scripts inventory var" "$RUNTIME_EVIDENCE_FILE" "6-4.10 Event Scripts Inventory"

echo
echo "===== 6-4 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-4 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-4.1.1 NATS JetStream real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.1.1 NATS / JetStream"
check_grep "6-4.1.2 publisher real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.1.2 Event publisher"
check_grep "6-4.1.3 consumer real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.1.3 Event consumer"
check_grep "6-4.2 backlog lag real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.2 Backlog / pending / lag"
check_grep "6-4.3.1 ack nack real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.3.1 Ack / Nack / Nak"
check_grep "6-4.3.2 retry real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.3.2 Retry / MaxDeliver"
check_grep "6-4.4 DLQ real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.4 DLQ / dead-letter"
check_grep "6-4.5 Replay real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.5 Replay / event store replay"
check_grep "6-4.6 Poison real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.6 Poison message"
check_grep "6-4.7 Idempotency real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.7 Idempotency / dedupe"
check_grep "6-4.8 Tenant-aware event real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.8 Tenant-aware event metadata"
check_grep "6-4.9 Event metrics real audit evidence var" "$REAL_EVIDENCE_FILE" "6-4.9 Event metrics"
check_grep "6-4 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-4 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_4_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-4 EVENT BUS SRE READINESS TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_4_DOC_STATUS=READY ✅"
  echo "FAZ_6_4_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_4_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_4_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_4_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_4_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_5_READY=YES ✅"
  elif grep -Fq "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_4_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_5_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_4_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_5_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-4 Event Bus / Queue / Backlog SRE Readiness testi tamamlandi"
  exit 0
else
  echo "FAZ_6_4_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-4 testlerinde eksik var"
  exit 1
fi
