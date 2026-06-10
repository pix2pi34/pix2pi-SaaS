#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_migration_version_normalization.sh"
REPORT="docs/phase4/14_1_5A_migration_version_normalization_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ version normalization script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_5A_real.log 2>&1 || {
  echo "TEST_FAIL ❌ real normalization script hata verdi"
  cat /tmp/pix2pi_14_1_5A_real.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_VERSION_NORMALIZATION=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ real normalization PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_LOCAL_CHAIN_MISMATCH_ANALYZED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ mismatch analiz edilmedi"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

echo "PHASE4_MIGRATION_VERSION_NORMALIZATION_REAL_TEST=PASS ✅"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/scripts" "$TMP_ROOT/db/migrations"

cp -a "$SCRIPT" "$TMP_ROOT/scripts/phase4_migration_version_normalization.sh"
chmod +x "$TMP_ROOT/scripts/phase4_migration_version_normalization.sh"

cat <<'SQL' > "$TMP_ROOT/db/migrations/001_alpha.up.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/001_alpha.down.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/002_beta.up.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/002_beta.down.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260425_090101_gamma.up.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260425_090101_gamma.down.sql"
select 1;
SQL

PHASE4_TEST_DB_VERSION=2 \
PHASE4_TEST_DB_DIRTY_STATE=f \
PHASE4_TEST_DB_ROLE=PRIMARY_WRITE \
PHASE4_TEST_SCHEMA_EXISTS=t \
bash "$TMP_ROOT/scripts/phase4_migration_version_normalization.sh" "$TMP_ROOT" >/tmp/pix2pi_14_1_5A_fixture.log 2>&1

FIXTURE_REPORT="$TMP_ROOT/docs/phase4/14_1_5A_migration_version_normalization_report.md"

grep -q "DB_VERSION_MATCH_LOCAL=YES" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture DB version local ile eslesmedi"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

grep -q "DB_VERSION_MATCHED_LOCAL_FILE=002_beta.up.sql" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture matched file yanlis"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

grep -q "DB_LOCAL_CHAIN_MISMATCH=YES" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture mismatch yakalanmadi"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

echo "PHASE4_MIGRATION_VERSION_NORMALIZATION_FIXTURE_TEST=PASS ✅"

if grep -R "POSTGRES_PASSWORD" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_MIGRATION_VERSION_NORMALIZATION_SECRET_TEST=PASS ✅"
