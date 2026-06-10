# FAZ 4 / 14.1.4B - Primary Write DSN Guard Report

Generated at: 2026-04-27 07:52:28 +0300

## Summary
ROOT_DIR=.
ENV_FILE=./.env
CONTAINER_CANDIDATE=pix2pi_pg_replica
CONTAINER_CANDIDATE=pix2pi_pg
PRIMARY_DSN_LABEL=docker:pix2pi_pg:127.0.0.1:5433/pix2pi
PRIMARY_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
ENV_PRIMARY_WRITE_DSN_UPDATE=UPDATED
PRIMARY_DSN_FOUND=1
REPLICA_DSN_FOUND=1
FAIL_COUNT=0
WARN_COUNT=0
PRIMARY_WRITE_DSN_GUARD=PASS

## DB Candidates
LABEL | ROLE | MASKED_DSN
docker:pix2pi_pg_replica:127.0.0.1:5434/pix2pi | REPLICA_READ_ONLY | postgres://pix2pi:***@127.0.0.1:5434/pix2pi?sslmode=disable
docker:pix2pi_pg:127.0.0.1:5433/pix2pi | PRIMARY_WRITE | postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
PASSWORD_MASKING=ENABLED
