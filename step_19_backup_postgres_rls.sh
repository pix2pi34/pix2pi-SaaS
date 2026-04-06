#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f deploy/sql/rls_tenant_policy.sql \
  backups/app/manual/rls_tenant_policy.sql.bak 2>/dev/null || true

echo "OK ✅ postgres rls yedegi alindi"
