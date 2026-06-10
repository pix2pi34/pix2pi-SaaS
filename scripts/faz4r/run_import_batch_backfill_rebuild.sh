#!/usr/bin/env bash
set -euo pipefail

TENANT_ID="${TENANT_ID:-}"
IMPORT_BATCH_ID="${IMPORT_BATCH_ID:-}"
SCHEMA="${SCHEMA:-public}"
APPLY="${APPLY:-0}"

load_env_files() {
  set +u
  if [ -f ".env" ]; then
    source ".env"
  fi
  if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
    source "/opt/pix2pi/orchestrator/env/common.env"
  fi
  if [ -f "/etc/pix2pi/ports.env" ]; then
    source "/etc/pix2pi/ports.env"
  fi
  set -u
}

resolve_db_dsn() {
  load_env_files

  if [ -n "${DB_WRITE_DSN:-}" ]; then
    echo "$DB_WRITE_DSN"
    return 0
  fi

  if [ -n "${DATABASE_URL:-}" ]; then
    echo "$DATABASE_URL"
    return 0
  fi

  if [ -n "${POSTGRES_DSN:-}" ]; then
    echo "$POSTGRES_DSN"
    return 0
  fi

  if [ -n "${PIX2PI_DB_DSN:-}" ]; then
    echo "$PIX2PI_DB_DSN"
    return 0
  fi

  echo ""
  return 1
}

fail() {
  echo "BACKFILL_REBUILD_ERROR=$1"
  exit 1
}

if [ -z "$TENANT_ID" ]; then
  fail "TENANT_ID_REQUIRED"
fi

if [ -z "$IMPORT_BATCH_ID" ]; then
  fail "IMPORT_BATCH_ID_REQUIRED"
fi

case "$SCHEMA" in
  ''|*[!a-zA-Z0-9_]*)
    fail "INVALID_SCHEMA_NAME"
    ;;
esac

if [ "$APPLY" != "0" ] && [ "$APPLY" != "1" ]; then
  fail "APPLY_MUST_BE_0_OR_1"
fi

DB_DSN="$(resolve_db_dsn || true)"

if [ -z "$DB_DSN" ]; then
  fail "DB_DSN_NOT_FOUND"
fi

if ! command -v psql >/dev/null 2>&1; then
  fail "PSQL_NOT_FOUND"
fi

echo "===== IMPORT BATCH BACKFILL / REBUILD START ====="
echo "TENANT_ID=${TENANT_ID}"
echo "IMPORT_BATCH_ID=${IMPORT_BATCH_ID}"
echo "SCHEMA=${SCHEMA}"
echo "APPLY=${APPLY}"

if [ "$APPLY" = "0" ]; then
  psql "$DB_DSN" -v ON_ERROR_STOP=1 \
    -v tenant_id="$TENANT_ID" \
    -v import_batch_id="$IMPORT_BATCH_ID" \
    -v schema_name="$SCHEMA" <<'SQL_DRY_EOF'
SELECT
  'DRY_RUN_SUMMARY' AS mode,
  COUNT(*) AS total_rows,
  COUNT(*) FILTER (WHERE validation_status = 'VALID') AS valid_rows,
  COUNT(*) FILTER (WHERE validation_status = 'INVALID') AS invalid_rows,
  COUNT(*) FILTER (WHERE validation_status = 'DUPLICATE') AS duplicate_rows,
  COUNT(*) FILTER (WHERE commit_status = 'COMMITTED') AS committed_rows,
  COUNT(*) FILTER (WHERE commit_status = 'COMMIT_FAILED') AS failed_rows
FROM :"schema_name".import_staging_rows
WHERE tenant_id = :'tenant_id'
  AND import_batch_id = :'import_batch_id';

SELECT
  'DRY_RUN_BATCH_BEFORE' AS mode,
  tenant_id,
  import_batch_id,
  status,
  total_rows,
  valid_rows,
  invalid_rows,
  duplicate_rows,
  committed_rows,
  failed_rows
FROM :"schema_name".import_batches
WHERE tenant_id = :'tenant_id'
  AND import_batch_id = :'import_batch_id';
SQL_DRY_EOF

  echo "BACKFILL_REBUILD_STATUS=DRY_RUN_ONLY"
  echo "BACKFILL_REBUILD_MUTATION_APPLIED=NO"
  exit 0
fi

psql "$DB_DSN" -v ON_ERROR_STOP=1 \
  -v tenant_id="$TENANT_ID" \
  -v import_batch_id="$IMPORT_BATCH_ID" \
  -v schema_name="$SCHEMA" <<'SQL_APPLY_EOF'
BEGIN;

WITH error_aggregate AS (
  SELECT
    tenant_id,
    import_batch_id,
    row_number,
    jsonb_agg(
      jsonb_build_object(
        'error_id', error_id,
        'entity_type', entity_type,
        'field_name', field_name,
        'error_code', error_code,
        'error_message', error_message,
        'severity', severity,
        'raw_value', raw_value
      )
      ORDER BY created_at, error_id
    ) AS errors,
    bool_or(severity IN ('ERROR', 'BLOCKER')) AS has_blocker_or_error,
    bool_or(severity = 'WARN') AS has_warn
  FROM :"schema_name".import_validation_errors
  WHERE tenant_id = :'tenant_id'
    AND import_batch_id = :'import_batch_id'
  GROUP BY tenant_id, import_batch_id, row_number
)
UPDATE :"schema_name".import_staging_rows r
SET
  validation_errors = COALESCE(e.errors, '[]'::jsonb),
  validation_status = CASE
    WHEN e.has_blocker_or_error IS TRUE THEN 'INVALID'
    WHEN e.has_warn IS TRUE AND r.validation_status = 'PENDING' THEN 'VALID'
    WHEN e.errors IS NULL AND r.validation_status = 'PENDING' THEN 'VALID'
    ELSE r.validation_status
  END,
  updated_at = now()
FROM (
  SELECT
    r2.tenant_id,
    r2.import_batch_id,
    r2.row_number,
    ea.errors,
    ea.has_blocker_or_error,
    ea.has_warn
  FROM :"schema_name".import_staging_rows r2
  LEFT JOIN error_aggregate ea
    ON ea.tenant_id = r2.tenant_id
   AND ea.import_batch_id = r2.import_batch_id
   AND ea.row_number = r2.row_number
  WHERE r2.tenant_id = :'tenant_id'
    AND r2.import_batch_id = :'import_batch_id'
) e
WHERE r.tenant_id = e.tenant_id
  AND r.import_batch_id = e.import_batch_id
  AND r.row_number = e.row_number;

WITH counter_rebuild AS (
  SELECT
    tenant_id,
    import_batch_id,
    COUNT(*)::INTEGER AS total_rows,
    COUNT(*) FILTER (WHERE validation_status = 'VALID')::INTEGER AS valid_rows,
    COUNT(*) FILTER (WHERE validation_status = 'INVALID')::INTEGER AS invalid_rows,
    COUNT(*) FILTER (WHERE validation_status = 'DUPLICATE')::INTEGER AS duplicate_rows,
    COUNT(*) FILTER (WHERE commit_status = 'COMMITTED')::INTEGER AS committed_rows,
    COUNT(*) FILTER (WHERE commit_status = 'COMMIT_FAILED')::INTEGER AS failed_rows
  FROM :"schema_name".import_staging_rows
  WHERE tenant_id = :'tenant_id'
    AND import_batch_id = :'import_batch_id'
  GROUP BY tenant_id, import_batch_id
)
UPDATE :"schema_name".import_batches b
SET
  total_rows = c.total_rows,
  valid_rows = c.valid_rows,
  invalid_rows = c.invalid_rows,
  duplicate_rows = c.duplicate_rows,
  committed_rows = c.committed_rows,
  failed_rows = c.failed_rows,
  updated_at = now()
FROM counter_rebuild c
WHERE b.tenant_id = c.tenant_id
  AND b.import_batch_id = c.import_batch_id;

SELECT
  'APPLY_REBUILD_RESULT' AS mode,
  tenant_id,
  import_batch_id,
  status,
  total_rows,
  valid_rows,
  invalid_rows,
  duplicate_rows,
  committed_rows,
  failed_rows
FROM :"schema_name".import_batches
WHERE tenant_id = :'tenant_id'
  AND import_batch_id = :'import_batch_id';

COMMIT;
SQL_APPLY_EOF

echo "BACKFILL_REBUILD_STATUS=APPLIED"
echo "BACKFILL_REBUILD_MUTATION_APPLIED=YES"
