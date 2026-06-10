#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_7_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_7_WORKFLOW_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.7 WORKFLOW PERSISTENCE REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.7 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
);
")"
check_eq "2-6.7 required workflow table count" "$table_count" "5"

workflow_state_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='workflow_states'
AND column_name IN (
  'tenant_id',
  'workflow_instance_id',
  'workflow_key',
  'status',
  'current_step_key',
  'correlation_id',
  'idempotency_key',
  'state_payload',
  'error_payload',
  'updated_at'
);
")"
check_eq "2-6.7 workflow_states required columns" "$workflow_state_columns" "10"

workflow_step_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='workflow_steps'
AND column_name IN (
  'tenant_id',
  'workflow_state_id',
  'step_key',
  'step_order',
  'step_type',
  'status',
  'retry_count',
  'max_retry_count',
  'input_payload',
  'output_payload',
  'error_payload',
  'retry_after_at'
);
")"
check_eq "2-6.7 workflow_steps required columns" "$workflow_step_columns" "12"

approval_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='workflow_approval_records'
AND column_name IN (
  'tenant_id',
  'workflow_state_id',
  'workflow_step_id',
  'approval_record_id',
  'approver_type',
  'approver_ref',
  'status',
  'requested_by',
  'decided_by',
  'decision_payload'
);
")"
check_eq "2-6.7 workflow_approval_records required columns" "$approval_columns" "10"

compensation_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='workflow_compensation_states'
AND column_name IN (
  'tenant_id',
  'workflow_state_id',
  'workflow_step_id',
  'compensation_state_id',
  'compensation_key',
  'status',
  'attempt_count',
  'max_attempt_count',
  'trigger_reason',
  'error_payload'
);
")"
check_eq "2-6.7 workflow_compensation_states required columns" "$compensation_columns" "10"

audit_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='workflow_audit_events'
AND column_name IN (
  'tenant_id',
  'workflow_state_id',
  'workflow_step_id',
  'approval_record_id',
  'compensation_state_id',
  'workflow_audit_event_id',
  'event_type',
  'actor_type',
  'correlation_id',
  'event_payload'
);
")"
check_eq "2-6.7 workflow_audit_events required columns" "$audit_columns" "10"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
);
")"
check_min "2-6.7 foreign key contract count" "$fk_count" "9"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
);
")"
check_min "2-6.7 workflow index coverage" "$index_count" "25"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.7 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.7 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.7 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
);
")"
check_min "2-6.7 check constraint coverage" "$check_constraint_count" "15"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
);
")"
check_min "2-6.7 unique constraint coverage" "$unique_constraint_count" "7"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states'
)
AND trigger_name LIKE 'trg_workflow%updated_at';
")"
check_eq "2-6.7 updated_at trigger count" "$trigger_count" "4"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'workflow_states',
  'workflow_steps',
  'workflow_approval_records',
  'workflow_compensation_states',
  'workflow_audit_events'
)
AND column_name='created_at';
")"
check_eq "2-6.7 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_7_WORKFLOW_STATE_STEP_APPROVAL_TABLES.md" ]; then
  pass_check "2-6.7 documentation file"
else
  fail_check "2-6.7 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_7_workflow_state_step_approval_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.7 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.7 WORKFLOW PERSISTENCE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_7_WORKFLOW_PERSISTENCE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_7_WORKFLOW_PERSISTENCE_FINAL_STATUS=PASS"
  echo "FAZ_2_6_7_WORKFLOW_PERSISTENCE_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_8_READY=YES"
  exit 0
else
  echo "FAZ_2_6_7_WORKFLOW_PERSISTENCE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_7_WORKFLOW_PERSISTENCE_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_7_WORKFLOW_PERSISTENCE_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_8_READY=NO"
  exit 1
fi
