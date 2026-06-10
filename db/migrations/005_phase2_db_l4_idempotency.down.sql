BEGIN;

DROP TABLE IF EXISTS runtime.dedupe_records;
DROP TABLE IF EXISTS runtime.idempotency_keys;

DROP FUNCTION IF EXISTS runtime.touch_last_seen_at();

DROP TYPE IF EXISTS runtime.dedupe_status_enum;
DROP TYPE IF EXISTS runtime.idempotency_status_enum;

COMMIT;
