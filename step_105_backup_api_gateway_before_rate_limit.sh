#!/bin/bash
set -e

mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway

cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rate_limit.bak

echo "OK ✅ api gateway rate limit oncesi yedek alindi"
