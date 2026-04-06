#!/bin/bash
set -e

cat <<'ROTEOF' > /etc/logrotate.d/pix2pi_snapshot
/tmp/pix2pi_service_snapshot_cron.log {
    daily
    rotate 3
    compress
    missingok
    notifempty
    copytruncate
}
ROTEOF

echo "OK ✅ logrotate eklendi"
