#!/usr/bin/env bash
set -euo pipefail

echo "==== STEP 48A / READ_USERS PROJECTION REBUILD ===="

docker exec -i pix2pi_pg psql -U pix2pi -d pix2pi <<'SQL'
BEGIN;

CREATE TABLE IF NOT EXISTS read_user_projection (
    user_id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS read_users (
    id SMALLINT PRIMARY KEY,
    total_count BIGINT NOT NULL DEFAULT 0
);

DELETE FROM read_users WHERE id <> 1;

INSERT INTO read_users (id, total_count)
VALUES (1, 0)
ON CONFLICT (id) DO NOTHING;

UPDATE read_users
SET total_count = COALESCE(
    (SELECT COUNT(*) FROM read_user_projection),
    0
)
WHERE id = 1;

ALTER TABLE read_users
DROP CONSTRAINT IF EXISTS read_users_singleton_check;

ALTER TABLE read_users
ADD CONSTRAINT read_users_singleton_check CHECK (id = 1);

COMMIT;

SELECT 'READ_USERS' AS section, id, total_count
FROM read_users
ORDER BY id;

SELECT 'READ_USER_PROJECTION_COUNT' AS section, COUNT(*) AS total_count
FROM read_user_projection;
SQL

echo "OK ✅ read_users projection rebuild tamam"
