#!/bin/bash
set -e

mkdir -p ~/pix2pi/pix2pi-SaaS/backups/scripts

cp ~/pix2pi/pix2pi-SaaS/step_99_run_api_gateway.sh \
  ~/pix2pi/pix2pi-SaaS/backups/scripts/step_99_run_api_gateway.sh.bak

echo "OK ✅ api gateway run script yedegi alindi"
