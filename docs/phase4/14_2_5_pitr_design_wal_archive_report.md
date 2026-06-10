# FAZ 4 / 14.2.5 - PITR Design / WAL Archive Plan Report

Generated at: 2026-04-27 14:00:58 +0300

## Summary
ROOT_DIR=.
READINESS_REPORT=docs/phase4/14_2_1_db_backup_pitr_readiness_report.md
RESTORE_REPORT=docs/phase4/14_2_4_restore_drill_test_report.md
PLAN_FILE=docs/phase4/14_2_5_pitr_enable_candidate_plan.sh
PITR_ENABLE_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO
RESTORE_DRILL_TEST=PASS
RESTORED_TABLE_COUNT=106
DB_DSN_STATUS=CONFIGURED
DB_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_CONNECTION_CHECK=PASS
PG_IS_IN_RECOVERY=f
DB_ROLE=PRIMARY_WRITE
POSTGRES_WAL_LEVEL=replica
POSTGRES_ARCHIVE_MODE=off
POSTGRES_ARCHIVE_COMMAND_STATUS=DISABLED
POSTGRES_MAX_WAL_SENDERS=10
POSTGRES_WAL_KEEP_SIZE=0
POSTGRES_CONFIG_FILE=/var/lib/postgresql/data/postgresql.conf
POSTGRES_DATA_DIRECTORY=/var/lib/postgresql/data
PRIMARY_CONTAINER=pix2pi_pg
PRIMARY_IMAGE=postgres:16
PRIMARY_DB=pix2pi
PRIMARY_PORT=5433
COMPOSE_FILE_COUNT=9
HOST_WAL_ARCHIVE_DIR=backups/db/wal_archive
CONTAINER_WAL_ARCHIVE_DIR=/var/lib/postgresql/wal_archive
ARCHIVE_COMMAND_PLAN=test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f
WAL_LEVEL_READY=YES
ARCHIVE_MODE_READY=NO
ARCHIVE_COMMAND_READY=NO
PITR_CURRENT_READY=NO
PITR_ENABLE_CANDIDATE_PLAN_CREATED=YES
PITR_ENABLE_CANDIDATE_PLAN_BLOCKED_BY_DEFAULT=YES
FAIL_COUNT=0
WARN_COUNT=1
PITR_DESIGN_WAL_ARCHIVE_PLAN=PASS

## Tool Status
TOOL_docker=FOUND
TOOL_psql=FOUND
TOOL_restic=FOUND

## Primary Container Mounts
/var/lib/docker/volumes/dev_pix2pi_pg_data/_data -> /var/lib/postgresql/data


## Compose File Candidates
./deploy/api-gateway/docker-compose.yml
./deploy/dev/docker-compose.pg.yml
./deploy/docker-compose.yml
./deploy/event-bus/docker-compose.yml
./deploy/nats/docker-compose.yml
./deploy/observability/docker-compose.yml
./deploy/redis/docker-compose.yml
./infra/observability/docker-compose.override.yml
./infra/observability/docker-compose.yml

## Risks
RISK_ARCHIVE_MODE_OFF=archive_mode off oldugu icin WAL dosyalari arsivlenmiyor
RISK_ARCHIVE_COMMAND_DISABLED=archive_command disabled oldugu icin PITR noktasi olusmaz

## Planned Execution
PITR_ENABLE_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO

## Issues
WARN ⚠️ PITR su an aktif degil; 14.2.6 enable gate gerekir

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
