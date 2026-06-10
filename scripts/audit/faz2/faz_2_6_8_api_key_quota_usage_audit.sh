#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_8_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_8_API_KEY_QUOTA_USAGE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.8 API KEY / QUOTA / USAGE REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.8 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
);
")"
check_eq "2-6.8 required API runtime table count" "$table_count" "5"

api_key_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='api_keys'
AND column_name IN (
  'tenant_id',
  'api_key_id',
  'app_id',
  'key_name',
  'key_prefix',
  'key_hash',
  'status',
  'scopes',
  'allowed_ips',
  'rate_limit_policy_id',
  'quota_policy_id',
  'environment',
  'created_by',
  'metadata',
  'last_used_at'
);
")"
check_eq "2-6.8 api_keys required columns" "$api_key_columns" "15"

api_key_raw_secret_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='api_keys'
AND column_name IN ('raw_key', 'secret', 'api_secret', 'plain_secret', 'plain_api_key');
")"
check_eq "2-6.8 api_keys raw secret columns absent" "$api_key_raw_secret_count" "0"

quota_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='api_quota_policies'
AND column_name IN (
  'tenant_id',
  'quota_policy_id',
  'policy_name',
  'subject_type',
  'subject_ref',
  'quota_scope',
  'window_type',
  'max_requests',
  'max_units',
  'burst_limit',
  'reset_policy',
  'overage_policy',
  'status'
);
")"
check_eq "2-6.8 api_quota_policies required columns" "$quota_columns" "13"

app_auth_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='app_auth_relations'
AND column_name IN (
  'tenant_id',
  'app_auth_relation_id',
  'app_id',
  'app_name',
  'api_key_id',
  'auth_type',
  'auth_subject_type',
  'auth_subject_ref',
  'status',
  'allowed_scopes',
  'allowed_routes',
  'environment',
  'created_by',
  'last_auth_at'
);
")"
check_eq "2-6.8 app_auth_relations required columns" "$app_auth_columns" "14"

usage_meter_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='api_usage_meters'
AND column_name IN (
  'tenant_id',
  'usage_meter_id',
  'api_key_id',
  'quota_policy_id',
  'app_auth_relation_id',
  'subject_type',
  'subject_ref',
  'usage_scope',
  'route_key',
  'method',
  'window_type',
  'window_start_at',
  'window_end_at',
  'request_count',
  'success_count',
  'failure_count',
  'unit_count',
  'last_request_at'
);
")"
check_eq "2-6.8 api_usage_meters required columns" "$usage_meter_columns" "18"

usage_audit_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='api_usage_audit_events'
AND column_name IN (
  'tenant_id',
  'usage_audit_event_id',
  'api_key_id',
  'quota_policy_id',
  'usage_meter_id',
  'app_auth_relation_id',
  'event_type',
  'decision',
  'subject_type',
  'subject_ref',
  'route_key',
  'method',
  'status_code',
  'request_id',
  'correlation_id',
  'request_units'
);
")"
check_eq "2-6.8 api_usage_audit_events required columns" "$usage_audit_columns" "16"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
);
")"
check_min "2-6.8 foreign key contract count" "$fk_count" "8"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
);
")"
check_min "2-6.8 API runtime index coverage" "$index_count" "28"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.8 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.8 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.8 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
);
")"
check_min "2-6.8 check constraint coverage" "$check_constraint_count" "25"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
);
")"
check_min "2-6.8 unique constraint coverage" "$unique_constraint_count" "6"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.8 updated_at trigger count" "$trigger_count" "4"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'api_keys',
  'api_quota_policies',
  'api_usage_meters',
  'app_auth_relations',
  'api_usage_audit_events'
)
AND column_name='created_at';
")"
check_eq "2-6.8 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_8_API_KEY_QUOTA_USAGE_TABLES.md" ]; then
  pass_check "2-6.8 documentation file"
else
  fail_check "2-6.8 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_8_api_key_quota_usage_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.8 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.8 API KEY / QUOTA / USAGE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_8_API_KEY_QUOTA_USAGE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_8_API_KEY_QUOTA_USAGE_FINAL_STATUS=PASS"
  echo "FAZ_2_6_8_API_KEY_QUOTA_USAGE_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_9_READY=YES"
  exit 0
else
  echo "FAZ_2_6_8_API_KEY_QUOTA_USAGE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_8_API_KEY_QUOTA_USAGE_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_8_API_KEY_QUOTA_USAGE_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_9_READY=NO"
  exit 1
fi
