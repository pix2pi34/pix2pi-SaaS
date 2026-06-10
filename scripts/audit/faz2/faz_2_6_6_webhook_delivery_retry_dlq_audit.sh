#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md}"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

exec > >(tee "$EVIDENCE_FILE") 2>&1

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_NAME="${DB_NAME:-pix2pi}"
DB_USER="${DB_USER:-pix2pi}"
PSQL_CONN="${DB_WRITE_DSN:-${DATABASE_URL:-}}"

run_psql() {
  if [ -n "$PSQL_CONN" ]; then
    psql "$PSQL_CONN" "$@"
  else
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" "$@"
  fi
}

sql_scalar() {
  run_psql -Atc "$1" | tr -d '[:space:]'
}

pass_check() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_INVALID / FAIL ❌"
}

check_eq() {
  local label="$1"
  local actual="$2"
  local expected="$3"

  if [ "$actual" = "$expected" ]; then
    pass_check "$label"
  else
    fail_check "$label expected=${expected} actual=${actual}"
  fi
}

check_min() {
  local label="$1"
  local actual="$2"
  local minimum="$3"

  if [ "$actual" -ge "$minimum" ]; then
    pass_check "$label"
  else
    fail_check "$label expected_min=${minimum} actual=${actual}"
  fi
}

echo "===== FAZ 2-6.6 WEBHOOK DELIVERY / RETRY / DLQ REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.6 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
);
")"
check_eq "2-6.6 required webhook runtime table count" "$table_count" "5"

delivery_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='webhook_deliveries'
AND column_name IN (
  'tenant_id',
  'webhook_delivery_id',
  'webhook_endpoint_id',
  'app_id',
  'integration_key',
  'event_id',
  'event_type',
  'target_url',
  'method',
  'status',
  'attempt_count',
  'max_attempt_count',
  'next_retry_at',
  'last_attempt_at',
  'delivered_at',
  'failed_at',
  'dlq_at',
  'request_headers',
  'request_payload',
  'response_status_code',
  'response_headers',
  'response_body',
  'error_payload',
  'correlation_id',
  'idempotency_key'
);
")"
check_eq "2-6.6 webhook_deliveries required columns" "$delivery_columns" "25"

retry_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='webhook_retry_states'
AND column_name IN (
  'tenant_id',
  'webhook_retry_state_id',
  'webhook_delivery_id',
  'retry_policy_key',
  'retry_status',
  'attempt_count',
  'max_attempt_count',
  'backoff_strategy',
  'backoff_seconds',
  'next_retry_at',
  'last_retry_at',
  'locked_by',
  'locked_at',
  'last_error_code',
  'last_error_payload'
);
")"
check_eq "2-6.6 webhook_retry_states required columns" "$retry_columns" "15"

dlq_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='webhook_dlq_states'
AND column_name IN (
  'tenant_id',
  'webhook_dlq_state_id',
  'webhook_delivery_id',
  'dlq_reason',
  'dlq_status',
  'poison_message',
  'failed_attempt_count',
  'last_error_code',
  'last_error_payload',
  'replay_requested_by',
  'replay_request_reason',
  'replay_requested_at',
  'replayed_by',
  'replayed_at',
  'archived_at'
);
")"
check_eq "2-6.6 webhook_dlq_states required columns" "$dlq_columns" "15"

signature_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='webhook_signature_metadata'
AND column_name IN (
  'tenant_id',
  'webhook_signature_metadata_id',
  'webhook_delivery_id',
  'signature_version',
  'signature_algorithm',
  'signature_header_name',
  'timestamp_header_name',
  'secret_ref',
  'payload_hash',
  'signature_hash',
  'signing_status',
  'verification_status',
  'signed_at',
  'verified_at'
);
")"
check_eq "2-6.6 webhook_signature_metadata required columns" "$signature_columns" "14"

audit_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='webhook_delivery_audit_events'
AND column_name IN (
  'tenant_id',
  'webhook_delivery_audit_event_id',
  'webhook_delivery_id',
  'webhook_retry_state_id',
  'webhook_dlq_state_id',
  'webhook_signature_metadata_id',
  'event_type',
  'decision',
  'actor_type',
  'actor_ref',
  'request_id',
  'correlation_id',
  'causation_id',
  'status_before',
  'status_after',
  'audit_payload'
);
")"
check_eq "2-6.6 webhook_delivery_audit_events required columns" "$audit_columns" "16"

raw_secret_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='webhook_signature_metadata'
AND column_name IN ('secret', 'raw_secret', 'webhook_secret', 'plain_secret', 'signing_secret');
")"
check_eq "2-6.6 raw webhook secret columns absent" "$raw_secret_count" "0"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
);
")"
check_min "2-6.6 foreign key contract count" "$fk_count" "7"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
);
")"
check_min "2-6.6 webhook runtime index coverage" "$index_count" "25"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.6 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.6 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.6 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
);
")"
check_min "2-6.6 check constraint coverage" "$check_constraint_count" "25"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
);
")"
check_min "2-6.6 unique constraint coverage" "$unique_constraint_count" "8"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.6 updated_at trigger count" "$trigger_count" "4"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'webhook_deliveries',
  'webhook_retry_states',
  'webhook_dlq_states',
  'webhook_signature_metadata',
  'webhook_delivery_audit_events'
)
AND column_name='created_at';
")"
check_eq "2-6.6 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_TABLES.md" ]; then
  pass_check "2-6.6 documentation file"
else
  fail_check "2-6.6 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_6_webhook_delivery_retry_dlq_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.6 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.6 WEBHOOK DELIVERY / RETRY / DLQ REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_FINAL_STATUS=PASS"
  echo "FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_2_READY=YES"
  exit 0
else
  echo "FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_2_READY=NO"
  exit 1
fi
