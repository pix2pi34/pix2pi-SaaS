# FAZ 4 / 14.2.2 - Logical Backup Smoke Report

Generated at: 2026-04-27 18:01:45 +0300

## Summary
ROOT_DIR=.
ENV_FILE=./.env
OUTPUT_DIR=backups/db/logical/phase4_14_2_2_20260427_180144
DUMP_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pix2pi_schema_only.dump
RESTORE_LIST_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pg_restore_list.txt
DB_MUTATION=NO
RESTORE_EXECUTED=NO
PITR_CONFIG_CHANGE=NO
BACKUP_TYPE=SCHEMA_ONLY_CUSTOM_FORMAT
FALLBACK_ENABLED=YES
DB_DSN_STATUS=CONFIGURED
DB_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_CONNECTION_CHECK=PASS
PG_IS_IN_RECOVERY=f
DB_ROLE=PRIMARY_WRITE
SCHEMA_MIGRATIONS_EXISTS=t
SCHEMA_MIGRATIONS_DIRTY_STATE=f
HOST_PG_DUMP_ERROR_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pg_dump_error_sanitized.txt
PRIMARY_CONTAINER=pix2pi_pg
PRIMARY_CONTAINER_DB=pix2pi
PG_DUMP_METHOD=DOCKER_PRIMARY_PG_DUMP
PG_DUMP_SMOKE=PASS
DUMP_SIZE_BYTES=567611
DUMP_SHA256_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pix2pi_schema_only.dump.sha256
DUMP_SHA256=973b95724878d52e2faf6e1e24f893b8ce2f75c3e814dc20b6e5ee199c7bd075
PG_RESTORE_LIST_METHOD=DOCKER_PRIMARY_PG_RESTORE
PG_RESTORE_LIST_CHECK=PASS
PG_RESTORE_LIST_LINE_COUNT=1208
FAIL_COUNT=0
WARN_COUNT=2
LOGICAL_BACKUP_SMOKE=PASS

## Tool Status
TOOL_psql=FOUND
TOOL_pg_dump=FOUND
TOOL_pg_restore=FOUND
TOOL_sha256sum=FOUND
TOOL_docker=FOUND

## Output Files
DUMP_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pix2pi_schema_only.dump
SHA_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pix2pi_schema_only.dump.sha256
RESTORE_LIST_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pg_restore_list.txt
PG_DUMP_ERROR_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pg_dump_error_sanitized.txt
PG_RESTORE_ERROR_FILE=backups/db/logical/phase4_14_2_2_20260427_180144/pg_restore_error_sanitized.txt

## Issues
WARN ⚠️ host pg_dump failed; docker primary pg_dump fallback denenecek
WARN ⚠️ host pg_restore --list failed; docker pg_restore fallback denenecek

## Secret Safety
RAW_DSN_PRINTED=NO
PASSWORD_MASKING=ENABLED
