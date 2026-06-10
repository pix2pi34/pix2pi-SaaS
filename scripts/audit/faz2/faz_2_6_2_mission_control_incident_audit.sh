#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_2_MISSION_CONTROL_INCIDENT_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.2 MISSION CONTROL / INCIDENT REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.2 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
);
")"
check_eq "2-6.2 required mission control table count" "$table_count" "5"

action_log_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='mission_control_action_logs'
AND column_name IN (
  'tenant_id',
  'mission_control_action_log_id',
  'action_type',
  'action_status',
  'target_type',
  'target_ref',
  'target_service_key',
  'target_instance_ref',
  'operator_ref',
  'actor_type',
  'decision',
  'priority',
  'request_id',
  'correlation_id',
  'idempotency_key',
  'action_payload',
  'result_payload',
  'error_payload',
  'requested_at'
);
")"
check_eq "2-6.2 mission_control_action_logs required columns" "$action_log_columns" "19"

incident_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='incident_logs'
AND column_name IN (
  'tenant_id',
  'incident_log_id',
  'incident_key',
  'severity',
  'incident_status',
  'source_type',
  'source_ref',
  'service_key',
  'service_instance_ref',
  'affected_tenant_id',
  'title',
  'description',
  'owner_ref',
  'detected_by',
  'acknowledged_by',
  'resolved_by',
  'closed_by',
  'impact_payload',
  'root_cause_payload',
  'remediation_payload',
  'detected_at'
);
")"
check_eq "2-6.2 incident_logs required columns" "$incident_columns" "21"

operator_action_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='operator_actions'
AND column_name IN (
  'tenant_id',
  'operator_action_id',
  'mission_control_action_log_id',
  'incident_log_id',
  'maintenance_state_id',
  'quarantine_state_id',
  'operator_ref',
  'action_type',
  'action_scope',
  'target_type',
  'target_ref',
  'decision',
  'risk_level',
  'action_status',
  'reason',
  'approval_ref',
  'break_glass_session_ref',
  'request_id',
  'correlation_id',
  'idempotency_key',
  'action_payload',
  'result_payload',
  'audit_payload',
  'performed_at'
);
")"
check_eq "2-6.2 operator_actions required columns" "$operator_action_columns" "24"

maintenance_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='maintenance_states'
AND column_name IN (
  'tenant_id',
  'maintenance_state_id',
  'maintenance_key',
  'maintenance_type',
  'maintenance_status',
  'target_type',
  'target_ref',
  'service_key',
  'service_instance_ref',
  'reason',
  'approval_status',
  'approved_by',
  'created_by',
  'started_by',
  'completed_by',
  'notification_payload',
  'maintenance_payload',
  'result_payload',
  'window_start_at',
  'window_end_at'
);
")"
check_eq "2-6.2 maintenance_states required columns" "$maintenance_columns" "20"

quarantine_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='quarantine_states'
AND column_name IN (
  'tenant_id',
  'quarantine_state_id',
  'quarantine_key',
  'quarantine_type',
  'quarantine_status',
  'target_type',
  'target_ref',
  'service_key',
  'service_instance_ref',
  'severity',
  'reason_code',
  'reason',
  'isolated_by',
  'released_by',
  'release_reason',
  'request_id',
  'correlation_id',
  'evidence_payload',
  'isolation_payload',
  'release_payload',
  'isolated_at',
  'released_at',
  'expires_at'
);
")"
check_eq "2-6.2 quarantine_states required columns" "$quarantine_columns" "23"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name='operator_actions';
")"
check_min "2-6.2 operator action foreign key contract count" "$fk_count" "4"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
);
")"
check_min "2-6.2 mission control index coverage" "$index_count" "25"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.2 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.2 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.2 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
);
")"
check_min "2-6.2 check constraint coverage" "$check_constraint_count" "30"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
);
")"
check_min "2-6.2 unique constraint coverage" "$unique_constraint_count" "8"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.2 updated_at trigger count" "$trigger_count" "5"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'mission_control_action_logs',
  'incident_logs',
  'operator_actions',
  'maintenance_states',
  'quarantine_states'
)
AND column_name='created_at';
")"
check_eq "2-6.2 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_2_MISSION_CONTROL_INCIDENT_TABLES.md" ]; then
  pass_check "2-6.2 documentation file"
else
  fail_check "2-6.2 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_2_mission_control_incident_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.2 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.2 MISSION CONTROL / INCIDENT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_2_MISSION_CONTROL_INCIDENT_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_2_MISSION_CONTROL_INCIDENT_FINAL_STATUS=PASS"
  echo "FAZ_2_6_2_MISSION_CONTROL_INCIDENT_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_1_READY=YES"
  exit 0
else
  echo "FAZ_2_6_2_MISSION_CONTROL_INCIDENT_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_2_MISSION_CONTROL_INCIDENT_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_2_MISSION_CONTROL_INCIDENT_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_1_READY=NO"
  exit 1
fi
