#!/bin/bash
set -e

RUN_FILE=~/pix2pi/run_snapshot.sh

cp $RUN_FILE ${RUN_FILE}.bak

# log yazmayı tamamen kaldır
sed -i 's/>> \/tmp\/pix2pi_service_snapshot_cron.log//g' $RUN_FILE

echo "OK ✅ snapshot log kapatildi"
