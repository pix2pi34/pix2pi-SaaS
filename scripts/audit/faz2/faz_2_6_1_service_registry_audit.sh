#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_1_SERVICE_REGISTRY_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.1 SERVICE REGISTRY REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.1 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
);
")"
check_eq "2-6.1 required service registry table count" "$table_count" "5"

service_instance_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='service_instances'
AND column_name IN (
  'tenant_id',
  'service_instance_id',
  'service_key',
  'service_name',
  'service_type',
  'environment',
  'instance_ref',
  'host_name',
  'ip_address',
  'port',
  'protocol',
  'base_url',
  'version_label',
  'deployment_ref',
  'node_ref',
  'region',
  'zone',
  'runtime_status',
  'health_status',
  'registration_source',
  'last_seen_at',
  'started_at',
  'metadata'
);
")"
check_eq "2-6.1 service_instances required columns" "$service_instance_columns" "23"

heartbeat_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='service_instance_heartbeats'
AND column_name IN (
  'tenant_id',
  'service_heartbeat_id',
  'service_instance_row_id',
  'service_instance_id',
  'service_key',
  'heartbeat_status',
  'health_status',
  'observed_at',
  'latency_ms',
  'uptime_seconds',
  'cpu_usage_percent',
  'memory_usage_bytes',
  'disk_usage_percent',
  'backlog_count',
  'error_count',
  'heartbeat_payload',
  'request_id',
  'correlation_id'
);
")"
check_eq "2-6.1 service_instance_heartbeats required columns" "$heartbeat_columns" "18"

metadata_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='service_instance_metadata'
AND column_name IN (
  'tenant_id',
  'service_metadata_id',
  'service_instance_row_id',
  'service_instance_id',
  'service_key',
  'metadata_key',
  'metadata_type',
  'metadata_value',
  'metadata_payload',
  'visibility',
  'is_sensitive',
  'created_by',
  'updated_by'
);
")"
check_eq "2-6.1 service_instance_metadata required columns" "$metadata_columns" "13"

visibility_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='service_tenant_visibility'
AND column_name IN (
  'tenant_id',
  'service_tenant_visibility_id',
  'service_instance_row_id',
  'service_instance_id',
  'service_key',
  'visible_tenant_id',
  'visibility_status',
  'access_mode',
  'route_scope',
  'allow_public',
  'reason',
  'effective_from',
  'effective_until',
  'created_by',
  'metadata'
);
")"
check_eq "2-6.1 service_tenant_visibility required columns" "$visibility_columns" "15"

stale_marker_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='service_stale_instance_markers'
AND column_name IN (
  'tenant_id',
  'service_stale_instance_marker_id',
  'service_instance_row_id',
  'service_heartbeat_row_id',
  'service_instance_id',
  'service_key',
  'stale_status',
  'stale_reason',
  'stale_threshold_seconds',
  'last_seen_at',
  'stale_detected_at',
  'marked_by',
  'cleared_by',
  'cleared_at',
  'marker_payload',
  'metadata'
);
")"
check_eq "2-6.1 service_stale_instance_markers required columns" "$stale_marker_columns" "16"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
);
")"
check_min "2-6.1 foreign key contract count" "$fk_count" "5"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
);
")"
check_min "2-6.1 service registry index coverage" "$index_count" "25"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.1 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.1 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.1 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
);
")"
check_min "2-6.1 check constraint coverage" "$check_constraint_count" "30"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
);
")"
check_min "2-6.1 unique constraint coverage" "$unique_constraint_count" "8"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.1 updated_at trigger count" "$trigger_count" "5"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'service_instances',
  'service_instance_heartbeats',
  'service_instance_metadata',
  'service_tenant_visibility',
  'service_stale_instance_markers'
)
AND column_name='created_at';
")"
check_eq "2-6.1 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_1_SERVICE_REGISTRY_TABLES.md" ]; then
  pass_check "2-6.1 documentation file"
else
  fail_check "2-6.1 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_1_service_registry_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.1 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.1 SERVICE REGISTRY REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_1_SERVICE_REGISTRY_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_1_SERVICE_REGISTRY_FINAL_STATUS=PASS"
  echo "FAZ_2_6_1_SERVICE_REGISTRY_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_3_READY=YES"
  exit 0
else
  echo "FAZ_2_6_1_SERVICE_REGISTRY_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_1_SERVICE_REGISTRY_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_1_SERVICE_REGISTRY_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_3_READY=NO"
  exit 1
fi
