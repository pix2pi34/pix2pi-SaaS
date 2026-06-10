#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

GATE="scripts/phase4_migration_apply_gate.sh"
REPORT="docs/phase4/14_1_2_migration_apply_gate_report.md"

if [ ! -x "$GATE" ]; then
  echo "TEST_FAIL ❌ apply gate executable degil"
  exit 1
fi

bash "$GATE" . status >/tmp/pix2pi_phase4_14_1_2_status.log 2>&1

grep -q "MIGRATION_APPLY_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ status gate PASS degil"
  cat /tmp/pix2pi_phase4_14_1_2_status.log || true
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

echo "PHASE4_MIGRATION_APPLY_GATE_STATUS_TEST=PASS ✅"

bash "$GATE" . dry-run >/tmp/pix2pi_phase4_14_1_2_dry_run.log 2>&1

grep -q "DRY_RUN_MODE=ON" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run raporda yok"
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_APPLY_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run gate PASS degil"
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

echo "PHASE4_MIGRATION_APPLY_GATE_DRY_RUN_TEST=PASS ✅"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/scripts"
cp -a "$GATE" "$TMP_ROOT/scripts/phase4_migration_apply_gate.sh"
chmod +x "$TMP_ROOT/scripts/phase4_migration_apply_gate.sh"

if bash "$TMP_ROOT/scripts/phase4_migration_apply_gate.sh" "$TMP_ROOT" status >/tmp/pix2pi_phase4_14_1_2_bad_fixture.log 2>&1; then
  echo "TEST_FAIL ❌ missing migration dir yakalanmadi"
  cat /tmp/pix2pi_phase4_14_1_2_bad_fixture.log || true
  exit 1
fi

grep -q "active migration dir not found" "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md" || {
  echo "TEST_FAIL ❌ missing migration dir raporda yok"
  cat "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md" || true
  exit 1
}

echo "PHASE4_MIGRATION_APPLY_GATE_BAD_FIXTURE_TEST=PASS ✅"

if bash "$GATE" . apply-check >/tmp/pix2pi_phase4_14_1_2_apply_lock.log 2>&1; then
  echo "TEST_FAIL ❌ apply-check kilidi calismadi"
  cat /tmp/pix2pi_phase4_14_1_2_apply_lock.log || true
  exit 1
fi

grep -q "APPLY_REQUIRES_EXPLICIT_CONFIRMATION" "$REPORT" || {
  echo "TEST_FAIL ❌ APPLY kilidi raporda yok"
  sed -n '1,180p' "$REPORT" || true
  exit 1
}

echo "PHASE4_MIGRATION_APPLY_GATE_APPLY_LOCK_TEST=PASS ✅"

bash "$GATE" . status >/tmp/pix2pi_phase4_14_1_2_final_reset.log 2>&1
