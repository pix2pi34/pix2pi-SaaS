#!/bin/bash
set -e

mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway

cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rewrite.bak

echo "OK ✅ api gateway dosya yedegi alindi"
