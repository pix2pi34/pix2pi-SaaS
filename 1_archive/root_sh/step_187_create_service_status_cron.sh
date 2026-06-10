#!/bin/bash
set -e

cat <<'CRON' > /etc/cron.d/pix2pi_service_status
* * * * * root /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
* * * * * root sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
* * * * * root sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
* * * * * root sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
* * * * * root sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
* * * * * root sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
CRON

chmod 644 /etc/cron.d/pix2pi_service_status
systemctl restart cron

echo "OK ✅ service status cron aktif"
