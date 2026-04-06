#!/bin/bash
set -e

echo "Snapshot log truncate FIX uygulanıyor..."

RUN_FILE=~/pix2pi/run_snapshot.sh

# yedek al
cp $RUN_FILE ${RUN_FILE}.bak

# log yazımını append yap
sed -i 's/> \/tmp\/pix2pi_service_snapshot_cron.log/>> \/tmp\/pix2pi_service_snapshot_cron.log/g' $RUN_FILE

echo "OK ✅ snapshot log append moduna alindi"
