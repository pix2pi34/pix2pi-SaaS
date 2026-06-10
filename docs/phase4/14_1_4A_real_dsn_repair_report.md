# FAZ 4 / 14.1.4A - Real DB DSN Repair Report

Generated at: 2026-04-27 07:50:42 +0300

## Summary
ROOT_DIR=.
ENV_FILE=./.env
CONTAINER_CANDIDATE=pix2pi_pg_replica
WORKING_DSN_LABEL=docker:pix2pi_pg_replica:127.0.0.1:5434/pix2pi
WORKING_DSN_MASKED=postgres://pix2pi:***@127.0.0.1:5434/pix2pi?sslmode=disable
ENV_REPAIR_STATUS=UPDATED
FOUND_WORKING_DSN=1
FAIL_COUNT=0
WARN_COUNT=0
REAL_DSN_REPAIR=PASS

## Candidates
docker:pix2pi_pg_replica:127.0.0.1:5434/pix2pi | postgres://pix2pi:***@127.0.0.1:5434/pix2pi?sslmode=disable

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
PASSWORD_MASKING=ENABLED
