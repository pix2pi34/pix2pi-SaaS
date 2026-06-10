#!/bin/bash
set -e

CONFIG=~/pix2pi/pix2pi-SaaS/infra/observability/loki/loki-config.yml

cat <<'YAMLEOF' > $CONFIG
auth_enabled: false

server:
  http_listen_port: 3100

limits_config:
  ingestion_rate_mb: 20
  ingestion_burst_size_mb: 40

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/index
    cache_location: /tmp/loki/cache
    shared_store: filesystem

  filesystem:
    directory: /tmp/loki/chunks
YAMLEOF

echo "OK ✅ loki limit arttirildi"
