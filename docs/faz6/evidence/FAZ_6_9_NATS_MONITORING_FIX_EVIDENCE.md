# FAZ 6-9 NATS Monitoring Fix Evidence

Generated At: 2026-05-01T15:23:30+03:00

NATS_CONTAINER=pix2pi_nats
COMPOSE_SERVICE=nats
COMPOSE_WORKDIR=/root/pix2pi/pix2pi-SaaS/deploy/nats
COMPOSE_FILES_RAW=/root/pix2pi/pix2pi-SaaS/deploy/nats/docker-compose.yml


## Docker PS
```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_nats               nats:2.10-alpine                  Up 1 second           0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
```

## Container Command
```text
["-js","-sd","/data","-m","8222"]
```

## Listening Check
```text
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=1036365,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=1036391,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=1036374,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=1036398,fd=8))                                                                                                                                                                                                                  
```

## NATS varz Sample
```text
{
  "server_id": "NABF4X66UDT6XKLFMTC3PIZXUGU2U4SQAOBTCO6EK35RGEC3M6GC2HKC",
  "server_name": "NABF4X66UDT6XKLFMTC3PIZXUGU2U4SQAOBTCO6EK35RGEC3M6GC2HKC",
  "version": "2.10.29",
  "proto": 1,
  "git_commit": "f91ddd8",
  "go": "go1.24.2",
  "host": "0.0.0.0",
  "port": 4222,
  "max_connections": 65536,
  "ping_interval": 120000000000,
  "ping_max": 2,
  "http_host": "0.0.0.0",
  "http_port": 8222,
  "http_base_path": "",
  "https_port": 0,
  "auth_timeout": 2,
  "max_control_line": 4096,
  "max_payload": 1048576,
  "max_pending": 67108864,
  "cluster": {},
  "gateway": {},
  "leaf": {},
  "mqtt": {},
  "websocket": {},
  "jetstream": {
    "config": {
      "max_memory": 12573321216,
      "max_storage": 82196336640,
      "store_dir": "/data/jetstream",
      "sync_interval": 120000000000
    },
    "stats": {
      "memory": 0,
      "storage": 0,
      "reserved_memory": 0,
      "reserved_storage": 0,
      "accounts": 1,
      "ha_assets": 0,
      "api": {
        "total": 0,
        "errors": 0
      }
    }
  },
  "tls_timeout": 2,
  "write_deadline": 10000000000,
  "start": "2026-05-01T12:23:31.186623886Z",
  "now": "2026-05-01T12:23:32.203443411Z",
  "uptime": "1s",
  "mem": 12689408,
  "cores": 8,
  "gomaxprocs": 8,
  "cpu": 2,
  "connections": 0,
  "total_connections": 0,
  "routes": 0,
  "remotes": 0,
  "leafnodes": 0,
  "in_msgs": 0,
  "out_msgs": 0,
  "in_bytes": 0,
  "out_bytes": 0,
  "slow_consumers": 0,
  "subscriptions": 78,
  "http_req_stats": {
    "/varz": 1
  },
  "config_load_time": "2026-05-01T12:23:31.186623886Z",
  "system_account": "$SYS",
  "slow_consumer_stats": {
    "clients": 0,
    "routes": 0,
    "gateways": 0,
    "leafs": 0
  }
}
```
FAZ_6_9_NATS_MONITORING_FIX_STATUS=PASS ✅
