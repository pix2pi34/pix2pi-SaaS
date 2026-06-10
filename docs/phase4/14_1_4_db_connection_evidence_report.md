# FAZ 4 / 14.1.4 - Real DB Connection Evidence Report

Generated at: 2026-04-27 07:52:28 +0300

## Summary
ROOT_DIR=.
SCHEMA_MIGRATIONS_EXISTS=t
SCHEMA_MIGRATIONS_HAS_DIRTY_COLUMN=t
SCHEMA_MIGRATIONS_DIRTY_STATE=f
SCHEMA_MIGRATIONS_EXISTS=t
SCHEMA_MIGRATIONS_HAS_DIRTY_COLUMN=t
SCHEMA_MIGRATIONS_DIRTY_STATE=f
DSN_CANDIDATE_COUNT=3
WORKING_DSN_COUNT=2
DB_CONNECTION_CHECK=PASS
FAIL_COUNT=0
WARN_COUNT=0
DB_CONNECTION_EVIDENCE=PASS

## DSN Candidates
KEY | SOURCE | PLACEHOLDER | MASKED_DSN
DB_DSN	./.env	NO	postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_WRITE_DSN	./.env	NO	postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_WRITE_DSN	/opt/pix2pi/orchestrator/env/common.env	YES	host=localhost port=5433 user=pix2pi password=*** dbname=pix2pi sslmode=disable

## Working DSN
KEY | SOURCE | MASKED_DSN
DB_DSN	./.env	postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable
DB_WRITE_DSN	./.env	postgres://pix2pi:***@127.0.0.1:5433/pix2pi?sslmode=disable

## Issues
OK ✅ issue yok

## Secret Safety
RAW_DSN_PRINTED=NO
PASSWORD_MASKING=ENABLED
