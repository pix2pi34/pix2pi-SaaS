#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_3_MULTI_NODE_FOUNDATION_SCALE_OUT_READINESS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_3_MULTI_NODE_VISIBLE_CHECKPOINTS.md"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_3_multinode_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_3_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_3_MULTI_NODE_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_3_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-3 MULTI-NODE READINESS TEST BASLADI ====="

check_file "6-3 master dokumani mevcut" "$DOC_FILE"
check_file "6-3 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-3 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-3 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
check_exec "6-3 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-3 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-3.1 cok node servis yerlesimi tanimli" "$DOC_FILE" "6-3.1 Cok Node Servis Yerlesimi"
check_grep "6-3.2 stateful stateless ayrimi tanimli" "$DOC_FILE" "6-3.2 Stateful / Stateless Ayrimi"
check_grep "6-3.3 service discovery runtime tuning tanimli" "$DOC_FILE" "6-3.3 Service Discovery Runtime Tuning"
check_grep "6-3.4 load balancer upstream tanimli" "$DOC_FILE" "6-3.4 Load Balancer / Upstream Hazirligi"
check_grep "6-3.5 health readiness liveness tanimli" "$DOC_FILE" "6-3.5 Health / Readiness / Liveness Standardi"
check_grep "6-3.6 graceful shutdown deploy safety tanimli" "$DOC_FILE" "6-3.6 Graceful Shutdown / Deploy Safety"
check_grep "6-3.7 scale-out blocker listesi tanimli" "$DOC_FILE" "6-3.7 Scale-out Blocker Listesi"
check_grep "6-3.8 final closure gate tanimli" "$DOC_FILE" "6-3.8 Multi-node Final Closure Gate"

check_grep "6-3.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_1_MULTI_NODE_SERVICE_PLACEMENT_STATUS=READY"
check_grep "6-3.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_2_STATEFUL_STATELESS_STATUS=READY"
check_grep "6-3.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_3_SERVICE_DISCOVERY_STATUS=READY"
check_grep "6-3.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_4_LOAD_BALANCER_UPSTREAM_STATUS=READY"
check_grep "6-3.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_5_HEALTH_READINESS_LIVENESS_STATUS=READY"
check_grep "6-3.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_6_GRACEFUL_DEPLOY_SAFETY_STATUS=READY"
check_grep "6-3.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_7_SCALE_OUT_BLOCKER_LIST_STATUS=READY"
check_grep "6-3.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_3_8_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-3 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-3 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-3 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_3_RUNTIME_AUDIT=COMPLETE"
check_grep "6-3 runtime systemd inventory var" "$RUNTIME_EVIDENCE_FILE" "6-3.2 Pix2pi Systemd Services"
check_grep "6-3 runtime docker inventory var" "$RUNTIME_EVIDENCE_FILE" "6-3.3 Docker Runtime Services"
check_grep "6-3 runtime listening ports inventory var" "$RUNTIME_EVIDENCE_FILE" "6-3.4 Listening Ports"
check_grep "6-3 runtime nginx inventory var" "$RUNTIME_EVIDENCE_FILE" "6-3.5 Nginx Upstream / Proxy Inventory"
check_grep "6-3 runtime health probe var" "$RUNTIME_EVIDENCE_FILE" "6-3.7 Local Health Endpoint Probe"

echo
echo "===== 6-3 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-3 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-3.1 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.1 Cok node servis yerlesimi"
check_grep "6-3.2 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.2 Stateful / stateless"
check_grep "6-3.3 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.3 Service discovery"
check_grep "6-3.4 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.4 Load balancer"
check_grep "6-3.5.1 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.5.1 Health endpoint"
check_grep "6-3.6.1 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.6.1 Graceful shutdown"
check_grep "6-3.7.1 real audit evidence var" "$REAL_EVIDENCE_FILE" "6-3.7.1 Hard-coded localhost"
check_grep "6-3 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-3 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_3_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-3 MULTI-NODE READINESS TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_3_DOC_STATUS=READY ✅"
  echo "FAZ_6_3_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_3_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_3_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_3_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_3_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_4_READY=YES ✅"
  elif grep -Fq "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_3_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_4_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_3_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_4_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-3 Multi-node Foundation / Scale-out Readiness testi tamamlandi"
  exit 0
else
  echo "FAZ_6_3_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-3 testlerinde eksik var"
  exit 1
fi
