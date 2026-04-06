#!/bin/bash
set -e

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'

DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_roles WHERE rolname = 'pix2pi_app'
   ) THEN
      CREATE ROLE pix2pi_app LOGIN PASSWORD 'pix2pi_app_pass';
   END IF;
END
$$;

GRANT CONNECT ON DATABASE pix2pi TO pix2pi_app;
GRANT USAGE ON SCHEMA public TO pix2pi_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pix2pi_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pix2pi_app;

SQLEOF

echo "OK ✅ app user olustu"
