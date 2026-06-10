#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
backups/app/manual/playground_main.go.event_replay.bak

echo "OK ✅ event replay yedegi alindi"
