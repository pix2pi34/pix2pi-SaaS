#!/bin/bash
set -e

echo "Snapshot cron log spam azaltiliyor..."

CRON_FILE=~/pix2pi/pix2pi-SaaS/snapshot_cron.conf

cat <<'CRONEOF' > $CRON_FILE
# eski: her 5 saniye gibi spam olabilir

# yeni:
*/1 * * * * /usr/bin/bash ~/pix2pi/run_snapshot.sh >> /tmp/pix2pi_service_snapshot_cron.log 2>&1
CRONEOF

echo "OK ✅ snapshot frequency dusuruldu (1 dk)"
