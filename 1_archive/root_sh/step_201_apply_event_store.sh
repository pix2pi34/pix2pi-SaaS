#!/bin/bash
set -e

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_200_create_event_store_table.sql

echo "OK event store table olusturuldu"
