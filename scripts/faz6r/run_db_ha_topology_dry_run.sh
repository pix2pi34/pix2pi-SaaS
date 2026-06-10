#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_2_1_db_ha_topolojisi.v1.json}"
TOPOLOGY_FILE="${2:-configs/faz6r/db_ha_topology.ha_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_2_1_db_ha_topolojisi_test.json}"

python3 - "$CONFIG_FILE" "$TOPOLOGY_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
topology = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for node in topology.get("nodes", []):
    rows.append({
        "topology_id": topology.get("topology_id"),
        "role": node.get("role"),
        "node": node.get("node"),
        "write_allowed": node.get("write_allowed"),
        "read_allowed": node.get("read_allowed"),
        "failover_candidate": node.get("failover_candidate"),
        "replication_health_status": node.get("replication_health_status"),
        "split_brain_guard_status": node.get("split_brain_guard_status"),
        "rto_minutes": node.get("rto_minutes"),
        "rpo_minutes": node.get("rpo_minutes"),
        "mutation_allowed": node.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_DB_HA_TOPOLOGY_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "db_ha_topology_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "db_promotion_allowed": config.get("db_promotion_allowed"),
    "replica_attach_allowed": config.get("replica_attach_allowed"),
    "replica_detach_allowed": config.get("replica_detach_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "dsn_mutation_allowed": config.get("dsn_mutation_allowed"),
    "read_write_route_mutation_allowed": config.get("read_write_route_mutation_allowed"),
    "node_count": len(rows),
    "write_primary_count": sum(1 for r in rows if r.get("role") == "primary" and r.get("write_allowed") is True),
    "next_step": topology.get("next_rehearsal", {}).get("step"),
    "nodes": rows
}, indent=2, ensure_ascii=False))
PY
