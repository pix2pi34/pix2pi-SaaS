#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_2_6_9_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-6.9 PLUGIN LIFECYCLE / STATE REAL IMPLEMENTATION AUDIT START ====="

schema_count="$(sql_scalar "SELECT count(*) FROM information_schema.schemata WHERE schema_name='platform';")"
check_eq "2-6.9 schema platform exists" "$schema_count" "1"

table_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.tables
WHERE table_schema='platform'
AND table_name IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
);
")"
check_eq "2-6.9 required plugin runtime table count" "$table_count" "5"

plugin_lifecycle_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='plugin_lifecycles'
AND column_name IN (
  'tenant_id',
  'plugin_lifecycle_id',
  'plugin_key',
  'plugin_name',
  'provider_key',
  'category',
  'lifecycle_status',
  'lifecycle_stage',
  'distribution_mode',
  'default_plugin_version_id',
  'entitlement_key',
  'marketplace_app_key',
  'sandbox_only',
  'metadata'
);
")"
check_eq "2-6.9 plugin_lifecycles required columns" "$plugin_lifecycle_columns" "14"

plugin_version_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='plugin_versions'
AND column_name IN (
  'tenant_id',
  'plugin_lifecycle_id',
  'plugin_version_id',
  'plugin_key',
  'version_label',
  'semver_major',
  'semver_minor',
  'semver_patch',
  'release_channel',
  'version_status',
  'artifact_ref',
  'manifest_payload',
  'migration_payload',
  'compatibility_payload',
  'required_capabilities',
  'breaking_change'
);
")"
check_eq "2-6.9 plugin_versions required columns" "$plugin_version_columns" "16"

tenant_install_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='tenant_plugin_installs'
AND column_name IN (
  'tenant_id',
  'tenant_plugin_install_id',
  'plugin_lifecycle_id',
  'plugin_version_id',
  'plugin_key',
  'app_id',
  'install_status',
  'install_mode',
  'config_payload',
  'secret_ref_payload',
  'entitlement_key',
  'installed_by',
  'installed_at',
  'suspended_at',
  'uninstalled_at'
);
")"
check_eq "2-6.9 tenant_plugin_installs required columns" "$tenant_install_columns" "15"

plugin_state_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='plugin_states'
AND column_name IN (
  'tenant_id',
  'plugin_state_id',
  'tenant_plugin_install_id',
  'plugin_lifecycle_id',
  'plugin_version_id',
  'plugin_key',
  'runtime_status',
  'health_status',
  'config_hash',
  'worker_ref',
  'last_heartbeat_at',
  'last_error_at',
  'last_error_payload',
  'state_payload',
  'metrics_payload'
);
")"
check_eq "2-6.9 plugin_states required columns" "$plugin_state_columns" "15"

compatibility_columns="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name='plugin_compatibility_states'
AND column_name IN (
  'tenant_id',
  'compatibility_state_id',
  'plugin_lifecycle_id',
  'plugin_version_id',
  'tenant_plugin_install_id',
  'plugin_key',
  'target_runtime',
  'target_runtime_version',
  'compatibility_status',
  'decision',
  'checked_by',
  'check_payload',
  'blocker_payload',
  'warning_payload',
  'checked_at',
  'expires_at'
);
")"
check_eq "2-6.9 plugin_compatibility_states required columns" "$compatibility_columns" "16"

fk_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='FOREIGN KEY'
AND table_name IN (
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
);
")"
check_min "2-6.9 foreign key contract count" "$fk_count" "9"

index_count="$(sql_scalar "
SELECT count(*)
FROM pg_indexes
WHERE schemaname='platform'
AND tablename IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
);
")"
check_min "2-6.9 plugin runtime index coverage" "$index_count" "25"

rls_enabled_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
)
AND c.relrowsecurity = true;
")"
check_eq "2-6.9 RLS enabled table count" "$rls_enabled_count" "5"

rls_forced_count="$(sql_scalar "
SELECT count(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='platform'
AND c.relname IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
)
AND c.relforcerowsecurity = true;
")"
check_eq "2-6.9 RLS forced table count" "$rls_forced_count" "5"

policy_count="$(sql_scalar "
SELECT count(*)
FROM pg_policies
WHERE schemaname='platform'
AND tablename IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
)
AND policyname LIKE '%tenant_isolation';
")"
check_eq "2-6.9 tenant isolation policy count" "$policy_count" "5"

check_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='CHECK'
AND table_name IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
);
")"
check_min "2-6.9 check constraint coverage" "$check_constraint_count" "25"

unique_constraint_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.table_constraints
WHERE constraint_schema='platform'
AND constraint_type='UNIQUE'
AND table_name IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
);
")"
check_min "2-6.9 unique constraint coverage" "$unique_constraint_count" "9"

trigger_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.triggers
WHERE trigger_schema='platform'
AND event_object_table IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
)
AND trigger_name LIKE 'trg_%updated_at';
")"
check_eq "2-6.9 updated_at trigger count" "$trigger_count" "5"

created_at_count="$(sql_scalar "
SELECT count(*)
FROM information_schema.columns
WHERE table_schema='platform'
AND table_name IN (
  'plugin_lifecycles',
  'plugin_versions',
  'tenant_plugin_installs',
  'plugin_states',
  'plugin_compatibility_states'
)
AND column_name='created_at';
")"
check_eq "2-6.9 created_at standard column count" "$created_at_count" "5"

if [ -s "docs/faz2/platform/FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_TABLES.md" ]; then
  pass_check "2-6.9 documentation file"
else
  fail_check "2-6.9 documentation file"
fi

migration_count="$(find db/migrations/faz2 -maxdepth 1 -type f -name '*faz_2_6_9_plugin_lifecycle_state_tables.sql' | wc -l | tr -d ' ')"
check_min "2-6.9 migration file present" "$migration_count" "1"

echo "===== FAZ 2-6.9 PLUGIN LIFECYCLE / STATE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_FINAL_STATUS=PASS"
  echo "FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_MODULE_SEAL_STATUS=SEALED"
  echo "FAZ_2_6_6_READY=YES"
  exit 0
else
  echo "FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_FINAL_STATUS=FAIL"
  echo "FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_MODULE_SEAL_STATUS=OPEN"
  echo "FAZ_2_6_6_READY=NO"
  exit 1
fi
