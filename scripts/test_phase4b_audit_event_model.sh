#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_audit_event_model.sh"
PY_SCRIPT="scripts/phase4b_audit_event_model.py"
REPORT="docs/phase4/21_3_audit_event_model_report.md"
INVENTORY="docs/phase4/21_3_audit_event_model_inventory.tsv"
MATRIX="docs/phase4/21_3_audit_event_model_matrix.tsv"
UP_FILE="db/migrations/20260429_213001_security_audit_event_model.up.sql"
DOWN_FILE="db/migrations/20260429_213001_security_audit_event_model.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ audit event model wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ audit event model python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_21_3_audit_event_model.log 2>&1 || {
  echo "TEST_FAIL ❌ audit event model script hata verdi"
  cat /tmp/pix2pi_21_3_audit_event_model.log || true
  sed -n '1,1900p' "$REPORT" || true
  exit 1
}

for required in \
  "AUDIT_EVENT_MODEL=PASS" \
  "FAZ4B_21_3_FINAL_STATUS=PASS" \
  "PREVIOUS_21_2_FINAL_STATUS=PASS" \
  "PREVIOUS_21_2_PERMISSION_GUARD=PASS" \
  "AUDIT_EVENT_MODEL_MIGRATION_PAIR=PASS" \
  "AUDIT_EVENT_MODEL_SCHEMA_STATUS=PASS" \
  "AUDIT_EVENT_MODEL_TABLE_STATUS=PASS" \
  "AUDIT_EVENT_MODEL_TENANT_SAFETY_STATUS=PASS" \
  "AUDIT_EVENT_MODEL_ACTOR_STATUS=PASS" \
  "AUDIT_EVENT_MODEL_RESOURCE_STATUS=PASS" \
  "AUDIT_EVENT_MODEL_DECISION_READY=PASS" \
  "AUDIT_EVENT_MODEL_TRACE_READY=PASS" \
  "AUDIT_EVENT_MODEL_IMMUTABLE_READY=PASS" \
  "AUDIT_EVENT_MODEL_BOUNDARY_READY=PASS" \
  "AUDIT_EVENT_MODEL_INDEX_STATUS=PASS" \
  "AUDIT_EVENT_MODEL_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "AUDIT_LOG_WRITE_EXECUTED=NO" \
  "AUDIT_INTEGRITY_CHAIN_EXECUTED=NO" \
  "PERMISSION_GUARD_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1900p' "$REPORT" || true
    exit 1
  }
done

for f in "$INVENTORY" "$MATRIX" "$UP_FILE" "$DOWN_FILE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for table in \
  audit_event_streams \
  audit_events \
  audit_actor_contexts \
  audit_resource_contexts \
  audit_decision_contexts \
  audit_integrity_chain
do
  grep -q "$table" "$UP_FILE" || {
    echo "TEST_FAIL ❌ up migration table eksik: $table"
    exit 1
  }

  grep -q "$table" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory table eksik: $table"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "tenant_id text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ tenant_id not null yok"
  exit 1
}

grep -q "event_hash text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ event_hash yok"
  exit 1
}

grep -q "previous_event_hash text" "$UP_FILE" || {
  echo "TEST_FAIL ❌ previous_event_hash yok"
  exit 1
}

grep -q "chain_hash text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ chain_hash yok"
  exit 1
}

grep -q "decision text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ decision yok"
  exit 1
}

if grep -Ei "ALTER SYSTEM|docker|systemctl|psql " "$UP_FILE"; then
  echo "TEST_FAIL ❌ up migration icinde sistem tokeni var"
  exit 1
fi

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_AUDIT_EVENT_MODEL_TEST=PASS ✅"
echo "PHASE4B_AUDIT_EVENT_MODEL_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_AUDIT_EVENT_MODEL_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_AUDIT_EVENT_MODEL_TRACE_TEST=PASS ✅"
echo "PHASE4B_AUDIT_EVENT_MODEL_IMMUTABLE_TEST=PASS ✅"
echo "PHASE4B_AUDIT_EVENT_MODEL_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_AUDIT_EVENT_MODEL_SECRET_TEST=PASS ✅"
