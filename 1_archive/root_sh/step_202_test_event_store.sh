#!/bin/bash
set -e

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -c "SELECT * FROM event_store LIMIT 5;"

echo "OK event store test bitti"
