#!/bin/bash
set -e

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi <<'SQLEOF'
GRANT USAGE, SELECT ON SEQUENCE snapshots_id_seq TO pix2pi_app;
SQLEOF

echo "OK ✅ snapshot sequence yetkisi verildi"
