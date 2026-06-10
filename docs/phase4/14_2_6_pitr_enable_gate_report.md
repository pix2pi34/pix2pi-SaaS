# FAZ 4 / 14.2.6 - PITR Enable Gate Report

Generated at: 2026-04-27 14:03:31 +0300

## Summary
ROOT_DIR=.
APPLY_PITR=0
APPLY_PITR_DEFAULT=0
PITR_ENABLE_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO
WAL_ARCHIVE_DIR_CREATED=NO
CANDIDATE_PLAN_FILE=docs/phase4/14_2_6_pitr_enable_candidate_execution.sh
READINESS_ASSESSMENT=PASS
RESTORE_DRILL_TEST=PASS
PITR_DESIGN_WAL_ARCHIVE_PLAN=PASS
DB_DSN_STATUS=CONFIGURED
DB_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_CONNECTION_CHECK=PASS
PG_IS_IN_RECOVERY=f
DB_ROLE=PRIMARY_WRITE
POSTGRES_WAL_LEVEL=replica
POSTGRES_ARCHIVE_MODE=off
POSTGRES_ARCHIVE_COMMAND_STATUS=DISABLED
POSTGRES_CONFIG_FILE=/var/lib/postgresql/data/postgresql.conf
POSTGRES_DATA_DIRECTORY=/var/lib/postgresql/data
PRIMARY_CONTAINER=pix2pi_pg
PRIMARY_IMAGE=postgres:16
PRIMARY_DB=pix2pi
PRIMARY_PORT=5433
HOST_WAL_ARCHIVE_DIR=backups/db/wal_archive
CONTAINER_WAL_ARCHIVE_DIR=/var/lib/postgresql/wal_archive
ARCHIVE_COMMAND_PLAN=test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f
HOST_WAL_ARCHIVE_DIR_STATUS=NOT_FOUND
WAL_ARCHIVE_MOUNT_STATUS=NOT_FOUND
COMPOSE_FILE_COUNT=9
WAL_LEVEL_READY=YES
ARCHIVE_MODE_READY=NO
ARCHIVE_COMMAND_READY=NO
PITR_CURRENT_READY=NO
PITR_ENABLE_DECISION=PLAN_READY_APPLY_NOT_EXECUTED
PITR_ENABLE_CANDIDATE_EXECUTION_CREATED=YES
PITR_ENABLE_CANDIDATE_EXECUTION_BLOCKED_BY_DEFAULT=YES
FAIL_COUNT=0
WARN_COUNT=2
PITR_ENABLE_GATE=PASS

## Tool Status
TOOL_docker=FOUND
TOOL_psql=FOUND

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
RISK_ARCHIVE_MODE_OFF=archive_mode on yapilmadan PITR aktif olmaz
RISK_ARCHIVE_COMMAND_DISABLED=archive_command tanimlanmadan WAL archive olusmaz

## Planned Execution
PITR_ENABLE_EXECUTED=NO
POSTGRES_CONFIG_CHANGED=NO
CONTAINER_RESTARTED=NO
DB_MUTATION=NO
WAL_ARCHIVE_DIR_CREATED=NO

## Issues
WARN ⚠️ host WAL archive dizini henuz yok; 14.2.6 apply adiminda olusturulmali
WARN ⚠️ primary container icinde WAL archive mount henuz yok

## Secret Safety
RAW_DSN_PRINTED=NO
POSTGRES_PASSWORD_PRINTED=NO
