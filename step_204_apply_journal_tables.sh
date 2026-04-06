#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

PGPASSWORD='pix2pi' psql -h localhost -p 5433 -U pix2pi -d pix2pi -f step_203_create_journal_tables.sql

echo "OK ✅ journal tabloları olusturuldu"
