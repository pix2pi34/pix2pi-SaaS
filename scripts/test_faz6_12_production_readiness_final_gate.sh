#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_12_FINAL_GATE_VISIBLE_CHECKPOINTS.md"
MANIFEST_FILE="docs/faz6/FAZ_6_FINAL_CLOSURE_MANIFEST.md"

FINAL_GATE_SCRIPT="scripts/pix2pi_faz6_final_gate_probe.sh"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_12_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_12_real_implementation.sh"

FINAL_GATE_EVIDENCE="docs/faz6/evidence/FAZ_6_12_FINAL_GATE_PROBE_EVIDENCE.md"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_12_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_12_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-12 PRODUCTION READINESS FINAL GATE TEST BASLADI ====="

check_file "6-12 master dokumani mevcut" "$DOC_FILE"
check_file "6-12 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "FAZ 6 final closure manifest mevcut" "$MANIFEST_FILE"
check_file "6-12 final gate probe script mevcut" "$FINAL_GATE_SCRIPT"
check_file "6-12 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-12 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"

check_exec "6-12 final gate probe script executable" "$FINAL_GATE_SCRIPT"
check_exec "6-12 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-12 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-12.1 master seal check tanimli" "$DOC_FILE" "6-12.1 FAZ 6 Master Seal Check"
check_grep "6-12.2 runtime audit closure tanimli" "$DOC_FILE" "6-12.2 Runtime Audit Closure"
check_grep "6-12.3 real implementation closure tanimli" "$DOC_FILE" "6-12.3 Real Implementation Audit Closure"
check_grep "6-12.4 critical fix closure tanimli" "$DOC_FILE" "6-12.4 Critical Fix Closure"
check_grep "6-12.5 cloudflare decision gate tanimli" "$DOC_FILE" "6-12.5 Cloudflare Decision Gate"
check_grep "6-12.6 production blocker gate tanimli" "$DOC_FILE" "6-12.6 Production Blocker Gate"
check_grep "6-12.7 production readiness decision tanimli" "$DOC_FILE" "6-12.7 Production Readiness Decision"
check_grep "6-12.8 final closure gate tanimli" "$DOC_FILE" "6-12.8 FAZ 6 Final Closure Gate"

check_grep "6-12.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_1_MASTER_SEAL_CHECK_STATUS=READY"
check_grep "6-12.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_2_RUNTIME_AUDIT_CLOSURE_STATUS=READY"
check_grep "6-12.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_3_REAL_IMPLEMENTATION_CLOSURE_STATUS=READY"
check_grep "6-12.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_4_CRITICAL_FIX_CLOSURE_STATUS=READY"
check_grep "6-12.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_5_CLOUDFLARE_DECISION_STATUS=READY"
check_grep "6-12.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_6_PRODUCTION_BLOCKER_GATE_STATUS=READY"
check_grep "6-12.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_7_PRODUCTION_READINESS_DECISION_STATUS=READY"
check_grep "6-12.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_12_8_FINAL_CLOSURE_GATE_STATUS=READY"

check_grep "manifest FAZ 6 scope var" "$MANIFEST_FILE" "FAZ 6 Scope"
check_grep "manifest critical fixes var" "$MANIFEST_FILE" "Critical Fixes During FAZ 6"
check_grep "manifest cloudflare decision var" "$MANIFEST_FILE" "Cloudflare Decision"

echo
echo "===== 6-12 FINAL GATE PROBE CALISTIRILIYOR ====="
bash "$FINAL_GATE_SCRIPT"

check_file "6-12 final gate evidence mevcut" "$FINAL_GATE_EVIDENCE"
check_grep "6-12 final gate probe complete muhru var" "$FINAL_GATE_EVIDENCE" "FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE"
check_grep "6-12 final gate required pass muhru var" "$FINAL_GATE_EVIDENCE" "FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=PASS"

echo
echo "===== 6-12 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-12 runtime evidence mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-12 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_12_RUNTIME_AUDIT=COMPLETE"
check_grep "6-12 runtime final gate probe var" "$RUNTIME_EVIDENCE_FILE" "6-12.7 Final Gate Probe"

echo
echo "===== 6-12 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-12 real implementation evidence mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-12.1 final gate doc real evidence var" "$REAL_EVIDENCE_FILE" "6-12.1 FAZ 6 final gate"
check_grep "6-12.2 step final status real evidence var" "$REAL_EVIDENCE_FILE" "6-12.2 Tum FAZ 6 step"
check_grep "6-12.3 runtime audit closure real evidence var" "$REAL_EVIDENCE_FILE" "6-12.3 Runtime audit"
check_grep "6-12.4 real implementation closure real evidence var" "$REAL_EVIDENCE_FILE" "6-12.4 Real implementation"
check_grep "6-12.5 critical fix closure real evidence var" "$REAL_EVIDENCE_FILE" "6-12.5 Critical fix"
check_grep "6-12.6 cloudflare decision real evidence var" "$REAL_EVIDENCE_FILE" "6-12.6 Cloudflare gray"
check_grep "6-12.7 production blocker gate real evidence var" "$REAL_EVIDENCE_FILE" "6-12.7 Production blocker"
check_grep "6-12 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-12 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_12_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-12 PRODUCTION READINESS FINAL GATE TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_12_DOC_STATUS=READY ✅"
  echo "FAZ_6_12_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE ✅"
  echo "FAZ_6_12_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_12_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_12_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_12_FINAL_BLOCKER_COUNT=0"
    echo "FAZ_6_12_FINAL_GO_DECISION=GO_FOR_NEXT_PHASE ✅"
    echo "FAZ_6_12_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_FINAL_SEAL_STATUS=SEALED ✅"
    echo "FAZ_7_READY=YES ✅"
  elif grep -Fq "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_12_FINAL_BLOCKER_COUNT=0"
    echo "FAZ_6_12_FINAL_GO_DECISION=GO_FOR_NEXT_PHASE_WITH_WARNINGS ⚠️"
    echo "FAZ_6_12_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_FINAL_SEAL_STATUS=SEALED_WITH_WARNINGS ⚠️"
    echo "FAZ_7_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_12_FINAL_GO_DECISION=NO_GO ❌"
    echo "FAZ_6_12_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_FINAL_STATUS=NOT_SEALED ❌"
    echo "FAZ_7_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-12 Production Readiness / Final Hardening Gate testi tamamlandi"
  exit 0
else
  echo "FAZ_6_12_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-12 testlerinde eksik var"
  exit 1
fi
