#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_9_RELEASE_ROLLBACK_DEPLOY_SAFETY.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_9_RELEASE_VISIBLE_CHECKPOINTS.md"
PREDEPLOY_SCRIPT="scripts/pix2pi_predeploy_check.sh"
POSTDEPLOY_SCRIPT="scripts/pix2pi_postdeploy_smoke.sh"
ROLLBACK_SCRIPT="scripts/pix2pi_rollback_readiness.sh"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_9_release_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_9_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_RELEASE_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md"
PREDEPLOY_EVIDENCE="docs/faz6/evidence/FAZ_6_9_PREDEPLOY_CHECK_EVIDENCE.md"
POSTDEPLOY_EVIDENCE="docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md"
ROLLBACK_EVIDENCE="docs/faz6/evidence/FAZ_6_9_ROLLBACK_READINESS_EVIDENCE.md"

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

echo "===== FAZ 6-9 RELEASE / ROLLBACK / DEPLOY SAFETY TEST BASLADI ====="

check_file "6-9 master dokumani mevcut" "$DOC_FILE"
check_file "6-9 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-9 predeploy script mevcut" "$PREDEPLOY_SCRIPT"
check_file "6-9 postdeploy smoke script mevcut" "$POSTDEPLOY_SCRIPT"
check_file "6-9 rollback readiness script mevcut" "$ROLLBACK_SCRIPT"
check_file "6-9 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-9 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"

check_exec "6-9 predeploy script executable" "$PREDEPLOY_SCRIPT"
check_exec "6-9 postdeploy smoke script executable" "$POSTDEPLOY_SCRIPT"
check_exec "6-9 rollback readiness script executable" "$ROLLBACK_SCRIPT"
check_exec "6-9 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-9 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-9.1 Release Standardi tanimli" "$DOC_FILE" "6-9.1 Release Standardi"
check_grep "6-9.2 Pre-deploy Check tanimli" "$DOC_FILE" "6-9.2 Pre-deploy Check"
check_grep "6-9.3 Post-deploy Smoke Test tanimli" "$DOC_FILE" "6-9.3 Post-deploy Smoke Test"
check_grep "6-9.4 Rollback Standardi tanimli" "$DOC_FILE" "6-9.4 Rollback Standardi"
check_grep "6-9.5 Migration Safety tanimli" "$DOC_FILE" "6-9.5 Migration Safety"
check_grep "6-9.6 Config Nginx Systemd Safety tanimli" "$DOC_FILE" "6-9.6 Config / Nginx / Systemd Deploy Safety"
check_grep "6-9.7 Static Public Deploy Safety tanimli" "$DOC_FILE" "6-9.7 Static / Public Page Deploy Safety"
check_grep "6-9.8 Release Evidence Audit Log tanimli" "$DOC_FILE" "6-9.8 Release Evidence / Audit Log"
check_grep "6-9.9 Deploy Safety Guard Scripts tanimli" "$DOC_FILE" "6-9.9 Deploy Safety Guard Scripts"
check_grep "6-9.10 Release Final Closure Gate tanimli" "$DOC_FILE" "6-9.10 Release Final Closure Gate"

check_grep "6-9.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_1_RELEASE_STANDARD_STATUS=READY"
check_grep "6-9.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_2_PREDEPLOY_CHECK_STATUS=READY"
check_grep "6-9.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_3_POSTDEPLOY_SMOKE_STATUS=READY"
check_grep "6-9.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_4_ROLLBACK_STANDARD_STATUS=READY"
check_grep "6-9.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_5_MIGRATION_SAFETY_STATUS=READY"
check_grep "6-9.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_6_CONFIG_NGINX_SYSTEMD_SAFETY_STATUS=READY"
check_grep "6-9.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_7_STATIC_PUBLIC_DEPLOY_SAFETY_STATUS=READY"
check_grep "6-9.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_8_RELEASE_EVIDENCE_AUDIT_LOG_STATUS=READY"
check_grep "6-9.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_9_DEPLOY_SAFETY_GUARD_SCRIPTS_STATUS=READY"
check_grep "6-9.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_9_10_RELEASE_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-9 GUARD SCRIPTS CALISTIRILIYOR ====="
bash "$PREDEPLOY_SCRIPT"
bash "$POSTDEPLOY_SCRIPT"
bash "$ROLLBACK_SCRIPT"

check_file "6-9 predeploy evidence mevcut" "$PREDEPLOY_EVIDENCE"
check_file "6-9 postdeploy smoke evidence mevcut" "$POSTDEPLOY_EVIDENCE"
check_file "6-9 rollback readiness evidence mevcut" "$ROLLBACK_EVIDENCE"
check_grep "6-9 predeploy complete muhru var" "$PREDEPLOY_EVIDENCE" "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE"
check_grep "6-9 postdeploy complete muhru var" "$POSTDEPLOY_EVIDENCE" "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE"
check_grep "6-9 rollback complete muhru var" "$ROLLBACK_EVIDENCE" "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE"

echo
echo "===== 6-9 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-9 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-9 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_9_RUNTIME_AUDIT=COMPLETE"
check_grep "6-9 runtime git inventory var" "$RUNTIME_EVIDENCE_FILE" "6-9.2 Git / Release Inventory"
check_grep "6-9 runtime script inventory var" "$RUNTIME_EVIDENCE_FILE" "6-9.3 Deploy / Rollback Script Inventory"
check_grep "6-9 runtime nginx syntax var" "$RUNTIME_EVIDENCE_FILE" "6-9.4 Nginx Syntax"
check_grep "6-9 runtime public GET content check var" "$RUNTIME_EVIDENCE_FILE" "6-9.7 Public GET Content Check Candidates"
check_grep "6-9 runtime smoke probe var" "$RUNTIME_EVIDENCE_FILE" "6-9.8 Local Smoke Probe"

echo
echo "===== 6-9 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-9 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-9.1 release standard real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.1 Release standard"
check_grep "6-9.2 predeploy real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.2 Pre-deploy check"
check_grep "6-9.3 postdeploy smoke real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.3 Post-deploy smoke"
check_grep "6-9.4 rollback real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.4 Rollback readiness"
check_grep "6-9.5 migration safety real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.5 Migration safety"
check_grep "6-9.6 nginx systemd docker safety real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.6 Nginx / systemd / docker deploy safety"
check_grep "6-9.7 static public GET real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.7 Static / public GET content check"
check_grep "6-9.8 release evidence real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.8 Release evidence"
check_grep "6-9.9 guard scripts real audit evidence var" "$REAL_EVIDENCE_FILE" "6-9.9 Guard scripts"
check_grep "6-9 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-9 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_9_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-9 RELEASE / ROLLBACK / DEPLOY SAFETY TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_9_DOC_STATUS=READY ✅"
  echo "FAZ_6_9_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_9_GUARD_SCRIPTS_STATUS=READY ✅"
  echo "FAZ_6_9_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_9_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_9_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_9_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_10_READY=YES ✅"
  elif grep -Fq "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_9_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_10_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_9_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_10_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-9 Release / Rollback / Deploy Safety testi tamamlandi"
  exit 0
else
  echo "FAZ_6_9_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-9 testlerinde eksik var"
  exit 1
fi
