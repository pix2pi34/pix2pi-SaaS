#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_5_NOTIFICATION_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.5 NOTIFICATION REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.5 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
);
")"
check_eq "2-6.5 required notification table count" "$table_count" "5"

notification_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='notifications'
AND column_name IN (
  'tenant_id',
  'notification_id',
  'notification_key',
  'notification_type',
  'notification_status',
  'priority',
  'subject_type',
  'subject_ref',
  'recipient_type',
  'recipient_ref',
  'title',
  'body',
  'template_key',
  'locale',
  'channels',
  'dedupe_key',
  'idempotency_key',
  'request_id',
  'correlation_id',
  'payload',
  'queued_at',
  'sent_at',
  'failed_at'
);
")"
check_eq "2-6.5 notifications required columns" "$notification_columns" "23"

delivery_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='notification_channel_deliveries'
AND column_name IN (
  'tenant_id',
  'notification_channel_delivery_id',
  'notification_row_id',
  'notification_id',
  'channel',
  'provider_key',
  'provider_message_id',
  'delivery_status',
  'endpoint_ref',
  'destination',
  'content_payload',
  'provider_payload',
  'response_payload',
  'error_payload',
  'attempt_count',
  'max_attempt_count',
  'scheduled_at',
  'next_retry_at',
  'last_attempt_at',
  'sent_at',
  'delivered_at',
  'failed_at',
  'idempotency_key',
  'correlation_id'
);
")"
check_eq "2-6.5 notification_channel_deliveries required columns" "$delivery_columns" "24"

state_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='notification_channel_states'
AND column_name IN (
  'tenant_id',
  'notification_channel_state_id',
  'notification_row_id',
  'notification_channel_delivery_id',
  'notification_id',
  'channel',
  'state_status',
  'email_state',
  'sms_state',
  'push_state',
  'in_app_state',
  'webhook_state',
  'provider_key',
  'provider_ref',
  'recipient_ref',
  'destination_hash',
  'last_provider_status',
  'last_provider_status_at',
  'state_payload',
  'error_payload'
);
")"
check_eq "2-6.5 notification_channel_states required columns" "$state_columns" "20"

retry_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='notification_retry_states'
AND column_name IN (
  'tenant_id',
  'notification_retry_state_id',
  'notification_row_id',
  'notification_channel_delivery_id',
  'notification_id',
  'channel',
  'retry_policy_key',
  'retry_status',
  'attempt_count',
  'max_attempt_count',
  'backoff_strategy',
  'backoff_seconds',
  'jitter_seconds',
  'next_retry_at',
  'last_retry_at',
  'locked_by',
  'locked_at',
  'last_error_code',
  'last_error_payload',
  'retry_payload'
);
")"
check_eq "2-6.5 notification_retry_states required columns" "$retry_columns" "20"

audit_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='notification_delivery_audit_events'
AND column_name IN (
  'tenant_id',
  'notification_delivery_audit_event_id',
  'notification_row_id',
  'notification_channel_delivery_id',
  'notification_channel_state_id',
  'notification_retry_state_id',
  'notification_id',
  'channel',
  'event_type',
  'decision',
  'actor_type',
  'actor_ref',
  'status_before',
  'status_after',
  'provider_key',
  'provider_message_id',
  'request_id',
  'correlation_id',
  'causation_id',
  'idempotency_key',
  'audit_payload'
);
")"
check_eq "2-6.5 notification_delivery_audit_events required columns" "$audit_columns" "21"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
);
")"
check_min "2-6.5 foreign key contract count" "$fk_count" "8"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
);
")"
check_min "2-6.5 notification index coverage" "$index_count" "30"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.5 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.5 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.5 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
);
")"
check_min "2-6.5 check constraint coverage" "$check_constraint_count" "35"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
);
")"
check_min "2-6.5 unique constraint coverage" "$unique_constraint_count" "8"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.5 updated_at trigger count" "$trigger_count" "4"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'notifications',
  'notification_channel_deliveries',
  'notification_channel_states',
  'notification_retry_states',
  'notification_delivery_audit_events'
)
AND column_name='created_at';
")"
check_eq "2-6.5 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_5_NOTIFICATION_TABLES.md" ]; then
  pass_check "2-6.5 documentation file"
else
  fail_check "2-6.5 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_5_notification_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.5 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.5 NOTIFICATION REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_5_NOTIFICATION_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_5_NOTIFICATION_FINAL_STATUS=PASS"
  echo "FAZ_2_6_5_NOTIFICATION_MODULE_SEAL_STATUS=SEALED"
  echo "DB_L4_PLATFORM_RUNTIME_PERSISTENCE_BLOCK_READY=YES"
  exit 0
else
  echo "FAZ_2_6_5_NOTIFICATION_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_5_NOTIFICATION_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_5_NOTIFICATION_MODULE_SEAL_STATUS=OPEN"
  echo "DB_L4_PLATFORM_RUNTIME_PERSISTENCE_BLOCK_READY=NO"
  exit 1
fi
