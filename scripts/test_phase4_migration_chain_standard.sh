#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_validate_migration_chain.sh"
REPORT="docs/phase4/14_1_1_migration_chain_validation.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ validator executable degil: $SCRIPT"
  exit 1
fi

bash "$SCRIPT" . db/migrations >/tmp/pix2pi_phase4_migration_chain_real.log 2>&1

if [ ! -f "$REPORT" ]; then
  echo "TEST_FAIL ❌ validation report olusmadi: $REPORT"
  cat /tmp/pix2pi_phase4_migration_chain_real.log || true
  exit 1
fi

grep -q "MIGRATION_CHAIN_VALIDATION=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ real repo validation PASS degil"
  cat /tmp/pix2pi_phase4_migration_chain_real.log || true
  sed -n '1,120p' "$REPORT" || true
  exit 1
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/db/migrations"

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260427071500_valid_alpha.up.sql"
CREATE TABLE IF NOT EXISTS phase4_valid_alpha (
  id BIGSERIAL PRIMARY KEY
);
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260427071500_valid_alpha.down.sql"
DROP TABLE IF EXISTS phase4_valid_alpha;
SQL

bash "$SCRIPT" "$TMP_ROOT" db/migrations >/tmp/pix2pi_phase4_migration_chain_fixture_ok.log 2>&1

grep -q "MIGRATION_CHAIN_VALIDATION=PASS" "$TMP_ROOT/docs/phase4/14_1_1_migration_chain_validation.md" || {
  echo "TEST_FAIL ❌ valid fixture PASS olmadi"
  cat /tmp/pix2pi_phase4_migration_chain_fixture_ok.log || true
  exit 1
}

mkdir -p "$TMP_ROOT/bad/db/migrations"

cat <<'SQL' > "$TMP_ROOT/bad/db/migrations/20260427071600_missing_down.up.sql"
CREATE TABLE IF NOT EXISTS phase4_missing_down (
  id BIGSERIAL PRIMARY KEY
);
SQL

if bash "$SCRIPT" "$TMP_ROOT/bad" db/migrations >/tmp/pix2pi_phase4_migration_chain_fixture_bad.log 2>&1; then
  echo "TEST_FAIL ❌ missing down migration yakalanmadi"
  cat /tmp/pix2pi_phase4_migration_chain_fixture_bad.log || true
  exit 1
fi

grep -q "PAIR_MISSING_DOWN" "$TMP_ROOT/bad/docs/phase4/14_1_1_migration_chain_validation.md" || {
  echo "TEST_FAIL ❌ missing down issue raporda yok"
  cat "$TMP_ROOT/bad/docs/phase4/14_1_1_migration_chain_validation.md" || true
  exit 1
}

echo "PHASE4_MIGRATION_CHAIN_REAL_REPO_TEST=PASS ✅"
echo "PHASE4_MIGRATION_CHAIN_VALID_FIXTURE_TEST=PASS ✅"
echo "PHASE4_MIGRATION_CHAIN_BAD_FIXTURE_TEST=PASS ✅"
