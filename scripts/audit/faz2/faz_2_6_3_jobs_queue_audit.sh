#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_3_JOBS_QUEUE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.3 JOBS QUEUE REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.3 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
);
")"
check_eq "2-6.3 required jobs queue table count" "$table_count" "5"

job_queue_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='job_queues'
AND column_name IN (
  'tenant_id',
  'job_id',
  'job_key',
  'job_type',
  'queue_name',
  'worker_group',
  'priority',
  'job_status',
  'schedule_status',
  'payload',
  'result_payload',
  'error_payload',
  'attempt_count',
  'max_attempt_count',
  'scheduled_at',
  'available_at',
  'locked_by',
  'locked_at',
  'lock_expires_at',
  'last_attempt_at',
  'next_retry_at',
  'completed_at',
  'failed_at',
  'dead_at',
  'idempotency_key',
  'correlation_id'
);
")"
check_eq "2-6.3 job_queues required columns" "$job_queue_columns" "26"

retry_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='job_retry_states'
AND column_name IN (
  'tenant_id',
  'job_retry_state_id',
  'job_queue_id',
  'job_id',
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
check_eq "2-6.3 job_retry_states required columns" "$retry_columns" "18"

scope_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='tenant_job_scopes'
AND column_name IN (
  'tenant_id',
  'tenant_job_scope_id',
  'scope_key',
  'queue_name',
  'job_type',
  'scope_status',
  'worker_group',
  'concurrency_limit',
  'rate_limit_per_minute',
  'priority_floor',
  'priority_ceiling',
  'max_pending_jobs',
  'max_running_jobs',
  'allow_retry',
  'allow_dlq',
  'scope_payload',
  'effective_from',
  'effective_until'
);
")"
check_eq "2-6.3 tenant_job_scopes required columns" "$scope_columns" "18"

dead_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='dead_job_states'
AND column_name IN (
  'tenant_id',
  'dead_job_state_id',
  'job_queue_id',
  'job_id',
  'queue_name',
  'job_type',
  'dead_reason',
  'dead_status',
  'poison_job',
  'failed_attempt_count',
  'last_error_code',
  'last_error_payload',
  'replay_requested_by',
  'replay_request_reason',
  'replay_requested_at',
  'replayed_by',
  'replayed_at',
  'archived_at',
  'dead_payload'
);
")"
check_eq "2-6.3 dead_job_states required columns" "$dead_columns" "19"

audit_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='job_audit_events'
AND column_name IN (
  'tenant_id',
  'job_audit_event_id',
  'job_queue_id',
  'job_retry_state_id',
  'dead_job_state_id',
  'job_id',
  'queue_name',
  'job_type',
  'event_type',
  'decision',
  'actor_type',
  'actor_ref',
  'status_before',
  'status_after',
  'request_id',
  'correlation_id',
  'causation_id',
  'idempotency_key',
  'audit_payload'
);
")"
check_eq "2-6.3 job_audit_events required columns" "$audit_columns" "19"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'job_retry_states',
  'dead_job_states',
  'job_audit_events'
);
")"
check_min "2-6.3 foreign key contract count" "$fk_count" "5"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
);
")"
check_min "2-6.3 jobs queue index coverage" "$index_count" "30"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.3 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.3 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.3 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
);
")"
check_min "2-6.3 check constraint coverage" "$check_constraint_count" "35"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
);
")"
check_min "2-6.3 unique constraint coverage" "$unique_constraint_count" "8"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'dead_job_states'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.3 updated_at trigger count" "$trigger_count" "4"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'job_queues',
  'job_retry_states',
  'tenant_job_scopes',
  'job_audit_events',
  'dead_job_states'
)
AND column_name='created_at';
")"
check_eq "2-6.3 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_3_JOBS_QUEUE_TABLES.md" ]; then
  pass_check "2-6.3 documentation file"
else
  fail_check "2-6.3 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_3_jobs_queue_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.3 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.3 JOBS QUEUE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_3_JOBS_QUEUE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_3_JOBS_QUEUE_FINAL_STATUS=PASS"
  echo "FAZ_2_6_3_JOBS_QUEUE_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_5_READY=YES"
  exit 0
else
  echo "FAZ_2_6_3_JOBS_QUEUE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_3_JOBS_QUEUE_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_3_JOBS_QUEUE_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_5_READY=NO"
  exit 1
fi
