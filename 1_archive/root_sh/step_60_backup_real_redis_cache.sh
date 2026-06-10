#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

mkdir -p backups/app/manual

cp -f cmd/playground/playground_main.go \
  backups/app/manual/playground_main.go.real_redis_cache.bak 2>/dev/null || true

cp -f internal/platform/cache/service/redis_cache_service.go \
  backups/app/manual/redis_cache_service.go.real_redis_cache.bak 2>/dev/null || true

echo "OK ✅ real redis cache yedegi alindi"
