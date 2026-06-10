#!/bin/bash
set -e

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'

ALTER ROLE pix2pi_app WITH PASSWORD 'pix2pi_app_pass';

SQLEOF

echo "OK ✅ password reset"
