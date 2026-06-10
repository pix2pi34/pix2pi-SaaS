#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_migration_timestamp_order_guard.sh"
REPORT="docs/phase4/14_1_5B_migration_timestamp_order_guard_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ timestamp order guard executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_5B_real.log 2>&1 || {
  echo "TEST_FAIL ❌ real timestamp order guard hata verdi"
  cat /tmp/pix2pi_14_1_5B_real.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_TIMESTAMP_ORDER_GUARD=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ real guard PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "SAFE_LATEST_FILE=" "$REPORT" || {
  echo "TEST_FAIL ❌ safe latest raporda yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

echo "PHASE4_TIMESTAMP_ORDER_GUARD_REAL_TEST=PASS ✅"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/scripts" "$TMP_ROOT/db/migrations"

cp -a "$SCRIPT" "$TMP_ROOT/scripts/phase4_migration_timestamp_order_guard.sh"
chmod +x "$TMP_ROOT/scripts/phase4_migration_timestamp_order_guard.sh"

cat <<'SQL' > "$TMP_ROOT/db/migrations/001_alpha.up.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/001_alpha.down.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260426_0911001_bad_anomaly.up.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260426_0911001_bad_anomaly.down.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260426_111001_good_latest.up.sql"
select 1;
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260426_111001_good_latest.down.sql"
select 1;
SQL

bash "$TMP_ROOT/scripts/phase4_migration_timestamp_order_guard.sh" "$TMP_ROOT" >/tmp/pix2pi_14_1_5B_fixture.log 2>&1

FIXTURE_REPORT="$TMP_ROOT/docs/phase4/14_1_5B_migration_timestamp_order_guard_report.md"

grep -q "MIGRATION_TIMESTAMP_ORDER_GUARD=PASS" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture guard PASS degil"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

grep -q "TIMESTAMP_ANOMALY_COUNT=1" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture anomaly yakalanmadi"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

grep -q "SAFE_LATEST_FILE=20260426_111001_good_latest.up.sql" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture safe latest yanlis"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

grep -q "NAIVE_LATEST_FILE=20260426_0911001_bad_anomaly.up.sql" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture naive latest beklenen anomaly degil"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

grep -q "LATEST_ORDER_MISMATCH=YES" "$FIXTURE_REPORT" || {
  echo "TEST_FAIL ❌ fixture latest mismatch yakalanmadi"
  cat "$FIXTURE_REPORT" || true
  exit 1
}

echo "PHASE4_TIMESTAMP_ORDER_GUARD_FIXTURE_TEST=PASS ✅"
echo "PHASE4_TIMESTAMP_ORDER_GUARD_SAFE_LATEST_TEST=PASS ✅"
