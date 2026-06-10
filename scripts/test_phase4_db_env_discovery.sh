#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DISCOVERY="scripts/phase4_db_env_discovery.sh"
GATE="scripts/phase4_migration_apply_gate.sh"
REPORT="docs/phase4/14_1_3_migration_db_env_discovery_report.md"

if [ ! -x "$DISCOVERY" ]; then
  echo "TEST_FAIL ❌ discovery executable degil"
  exit 1
fi

if [ ! -x "$GATE" ]; then
  echo "TEST_FAIL ❌ apply gate executable degil"
  exit 1
fi

bash "$DISCOVERY" . status >/tmp/pix2pi_phase4_14_1_3_real.log 2>&1

grep -q "DB_ENV_DISCOVERY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ real discovery PASS degil"
  cat /tmp/pix2pi_phase4_14_1_3_real.log || true
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

echo "PHASE4_DB_ENV_DISCOVERY_REAL_TEST=PASS ✅"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/scripts" "$TMP_ROOT/db/migrations"

cp -a "$DISCOVERY" "$TMP_ROOT/scripts/phase4_db_env_discovery.sh"
cp -a "$GATE" "$TMP_ROOT/scripts/phase4_migration_apply_gate.sh"
chmod +x "$TMP_ROOT/scripts/phase4_db_env_discovery.sh"
chmod +x "$TMP_ROOT/scripts/phase4_migration_apply_gate.sh"

cat <<'SH' > "$TMP_ROOT/scripts/phase4_validate_migration_chain.sh"
#!/usr/bin/env bash
echo "MIGRATION_CHAIN_VALIDATION=PASS ✅"
exit 0
SH
chmod +x "$TMP_ROOT/scripts/phase4_validate_migration_chain.sh"

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260427080000_env_fixture.up.sql"
CREATE TABLE IF NOT EXISTS phase4_env_fixture (
  id BIGSERIAL PRIMARY KEY
);
SQL

cat <<'SQL' > "$TMP_ROOT/db/migrations/20260427080000_env_fixture.down.sql"
DROP TABLE IF EXISTS phase4_env_fixture;
SQL

cat <<'ENV' > "$TMP_ROOT/.env"
DB_WRITE_DSN=postgres://pix2pi:supersecret@127.0.0.1:59999/pix2pi?sslmode=disable
ENV

bash "$TMP_ROOT/scripts/phase4_db_env_discovery.sh" "$TMP_ROOT" status >/tmp/pix2pi_phase4_14_1_3_mask.log 2>&1

grep -q "FOUND_DSN=YES" "$TMP_ROOT/docs/phase4/14_1_3_migration_db_env_discovery_report.md" || {
  echo "TEST_FAIL ❌ fixture DSN bulunamadi"
  cat "$TMP_ROOT/docs/phase4/14_1_3_migration_db_env_discovery_report.md" || true
  exit 1
}

grep -Fq "FOUND_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:59999/pix2pi?sslmode=disable" "$TMP_ROOT/docs/phase4/14_1_3_migration_db_env_discovery_report.md" || {
  echo "TEST_FAIL ❌ DSN maskelenmedi"
  cat "$TMP_ROOT/docs/phase4/14_1_3_migration_db_env_discovery_report.md" || true
  exit 1
}

if grep -R "supersecret" "$TMP_ROOT/docs/phase4/14_1_3_migration_db_env_discovery_report.md"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_ENV_DISCOVERY_MASK_TEST=PASS ✅"

SECRET_ENV_FILE="$TMP_ROOT/secret_db_env.out"

bash "$TMP_ROOT/scripts/phase4_db_env_discovery.sh" "$TMP_ROOT" write-env "$SECRET_ENV_FILE" >/tmp/pix2pi_phase4_14_1_3_write_env.log 2>&1

if [ ! -f "$SECRET_ENV_FILE" ]; then
  echo "TEST_FAIL ❌ write-env dosyasi olusmadi"
  cat /tmp/pix2pi_phase4_14_1_3_write_env.log || true
  exit 1
fi

grep -q "DB_DSN=" "$SECRET_ENV_FILE" || {
  echo "TEST_FAIL ❌ write-env DB_DSN yazmadi"
  exit 1
}

echo "PHASE4_DB_ENV_DISCOVERY_WRITE_ENV_TEST=PASS ✅"

bash "$TMP_ROOT/scripts/phase4_migration_apply_gate.sh" "$TMP_ROOT" status >/tmp/pix2pi_phase4_14_1_3_gate_fixture.log 2>&1

grep -q "DB_ENV_DISCOVERY=LOADED" "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md" || {
  echo "TEST_FAIL ❌ apply gate discovery load etmedi"
  cat "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md" || true
  exit 1
}

grep -q "DB_DSN_STATUS=CONFIGURED" "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md" || {
  echo "TEST_FAIL ❌ apply gate DB_DSN CONFIGURED gormedi"
  cat "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md" || true
  exit 1
}

if grep -R "supersecret" "$TMP_ROOT/docs/phase4/14_1_2_migration_apply_gate_report.md"; then
  echo "TEST_FAIL ❌ secret apply gate raporuna sizdi"
  exit 1
fi

echo "PHASE4_DB_ENV_DISCOVERY_APPLY_GATE_INTEGRATION_TEST=PASS ✅"
