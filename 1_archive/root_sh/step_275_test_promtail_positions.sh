#!/bin/bash
set -e

echo "=== PROMTAIL LOG ==="
docker logs pix2pi_promtail --tail 50 || true
echo

echo "=== POSITION FILE ==="
ls -lah ~/pix2pi/pix2pi-SaaS/infra/observability/promtail/data || true
echo

echo "=== POSITION CONTENT ==="
cat ~/pix2pi/pix2pi-SaaS/infra/observability/promtail/data/positions.yaml || true
echo

echo "OK ✅ promtail positions test bitti"
