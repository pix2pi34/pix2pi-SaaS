#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_backup_restore_verification.sh"
PY_SCRIPT="scripts/phase4b_backup_restore_verification.py"
REPORT="docs/phase4/14_6_backup_restore_verification_report.md"
MATRIX="docs/phase4/14_6_backup_restore_verification_matrix.tsv"
MANIFEST="config/backup/backup_restore_verification_manifest.tsv"
DOC_MANIFEST="docs/phase4/14_6_backup_restore_verification_manifest.tsv"
PLAN="docs/phase4/14_6_backup_restore_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ backup restore wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ backup restore python executable degil"
  exit 1
fi

if [ ! -x "$PLAN" ]; then
  echo "TEST_FAIL ❌ candidate plan executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash -n "$PLAN" || {
  echo "TEST_FAIL ❌ candidate plan bash syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_14_6_backup_restore_verification.log 2>&1 || {
  echo "TEST_FAIL ❌ backup restore verification script hata verdi"
  cat /tmp/pix2pi_14_6_backup_restore_verification.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "BACKUP_RESTORE_VERIFICATION_SET=PASS" \
  "FAZ4B_14_6_FINAL_STATUS=PASS" \
  "PREVIOUS_14_1_FINAL_STATUS=PASS" \
  "PREVIOUS_14_2_FINAL_STATUS=PASS" \
  "PREVIOUS_14_3_FINAL_STATUS=PASS" \
  "PREVIOUS_14_4_FINAL_STATUS=PASS" \
  "PREVIOUS_14_5_FINAL_STATUS=PASS" \
  "BACKUP_RESTORE_MANIFEST_STATUS=PASS" \
  "BACKUP_RESTORE_PRE_IMPORT_GATE_STATUS=PASS" \
  "BACKUP_RESTORE_POST_IMPORT_RESTORE_STATUS=PASS" \
  "BACKUP_RESTORE_PITR_DEFERRED_STATUS=PASS" \
  "BACKUP_RESTORE_CANDIDATE_PLAN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "BACKUP_EXECUTED=NO" \
  "RESTORE_EXECUTED=NO" \
  "PITR_APPLY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$PLAN"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  pre_import_backup_gate \
  pre_import_backup_evidence \
  post_import_restore_safety \
  logical_backup_evidence \
  restore_drill_evidence \
  pitr_design_ready \
  pitr_enable_gate_ready \
  pitr_active_apply \
  import_staging_backup_alignment \
  retention_backup_alignment \
  restore_runbook_safety \
  secret_safety
do
  grep -q "$gate" "$MANIFEST" || {
    echo "TEST_FAIL ❌ backup/restore gate eksik: $gate"
    cat "$MANIFEST" || true
    exit 1
  }
done

PLAN_OUT="$(bash "$PLAN")"

echo "$PLAN_OUT" | grep -q "BACKUP_RESTORE_PLAN_BLOCKED_BY_DEFAULT=YES" || {
  echo "TEST_FAIL ❌ candidate plan blocked by default degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "BACKUP_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ backup executed no degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "RESTORE_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ restore executed no degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "PITR_APPLY_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ PITR apply no degil"
  echo "$PLAN_OUT"
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_BACKUP_RESTORE_VERIFICATION_TEST=PASS ✅"
echo "PHASE4B_BACKUP_RESTORE_PITR_DEFERRED_TEST=PASS ✅"
echo "PHASE4B_BACKUP_RESTORE_PRE_POST_IMPORT_GATE_TEST=PASS ✅"
echo "PHASE4B_BACKUP_RESTORE_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_BACKUP_RESTORE_SECRET_TEST=PASS ✅"
