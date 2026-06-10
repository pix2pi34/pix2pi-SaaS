#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_connection_evidence.sh"
REPORT="docs/phase4/14_1_4_db_connection_evidence_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ db connection evidence script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_phase4_14_1_4_real.log 2>&1 || {
  echo "TEST_FAIL ❌ real evidence script hata verdi"
  cat /tmp/pix2pi_phase4_14_1_4_real.log || true
  exit 1
}

grep -Eq "DB_CONNECTION_EVIDENCE=(PASS|NEEDS_REAL_DSN)" "$REPORT" || {
  echo "TEST_FAIL ❌ real evidence sonucu raporda yok"
  sed -n '1,180p' "$REPORT" || true
  exit 1
}

echo "PHASE4_DB_CONNECTION_EVIDENCE_REAL_TEST=PASS ✅"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/scripts"

cp -a "$SCRIPT" "$TMP_ROOT/scripts/phase4_db_connection_evidence.sh"
chmod +x "$TMP_ROOT/scripts/phase4_db_connection_evidence.sh"

cat <<'ENV' > "$TMP_ROOT/.env"
DB_WRITE_DSN=postgres://pix2pi:supersecret@127.0.0.1:59999/pix2pi?sslmode=disable
ENV

bash "$TMP_ROOT/scripts/phase4_db_connection_evidence.sh" "$TMP_ROOT" >/tmp/pix2pi_phase4_14_1_4_mask.log 2>&1 || {
  echo "TEST_FAIL ❌ mask fixture script hata verdi"
  cat /tmp/pix2pi_phase4_14_1_4_mask.log || true
  exit 1
}

grep -Fq "postgres://pix2pi:***@127.0.0.1:59999/pix2pi?sslmode=disable" "$TMP_ROOT/docs/phase4/14_1_4_db_connection_evidence_report.md" || {
  echo "TEST_FAIL ❌ masked DSN raporda yok"
  cat "$TMP_ROOT/docs/phase4/14_1_4_db_connection_evidence_report.md" || true
  exit 1
}

if grep -R "supersecret" "$TMP_ROOT/docs/phase4/14_1_4_db_connection_evidence_report.md"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

grep -q "DB_CONNECTION_EVIDENCE=NEEDS_REAL_DSN" "$TMP_ROOT/docs/phase4/14_1_4_db_connection_evidence_report.md" || {
  echo "TEST_FAIL ❌ calismayan fixture NEEDS_REAL_DSN vermedi"
  cat "$TMP_ROOT/docs/phase4/14_1_4_db_connection_evidence_report.md" || true
  exit 1
}

echo "PHASE4_DB_CONNECTION_EVIDENCE_MASK_TEST=PASS ✅"
echo "PHASE4_DB_CONNECTION_EVIDENCE_NEEDS_DSN_TEST=PASS ✅"
