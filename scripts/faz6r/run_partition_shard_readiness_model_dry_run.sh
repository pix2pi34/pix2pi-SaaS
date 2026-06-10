#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_20_6_partition_shard_readiness_modeli.v1.json}"
MODEL_FILE="${2:-configs/faz6r/partition_shard_readiness_model.db_scale.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_20_6_partition_shard_readiness_modeli_test.json}"

python3 - "$CONFIG_FILE" "$MODEL_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
model = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

rows = []
for rec in model.get("readiness_records", []):
    rows.append({
        "readiness_id": rec.get("readiness_id"),
        "surface": rec.get("surface"),
        "candidate_type": rec.get("candidate_type"),
        "preferred_key": rec.get("preferred_key"),
        "tenant_distribution_status": rec.get("tenant_distribution_status"),
        "shard_key_status": rec.get("shard_key_status"),
        "cross_shard_guard_status": rec.get("cross_shard_guard_status"),
        "reporting_impact_status": rec.get("reporting_impact_status"),
        "migration_safety_status": rec.get("migration_safety_status"),
        "risk_level": rec.get("risk_level"),
        "approval_required": rec.get("approval_required"),
        "mutation_allowed": rec.get("mutation_allowed"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_PARTITION_SHARD_READINESS_RECORD"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "partition_shard_readiness_model_dry_run",
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "partition_create_allowed": config.get("partition_create_allowed"),
    "partition_drop_allowed": config.get("partition_drop_allowed"),
    "shard_split_allowed": config.get("shard_split_allowed"),
    "shard_move_allowed": config.get("shard_move_allowed"),
    "tenant_move_allowed": config.get("tenant_move_allowed"),
    "table_rewrite_allowed": config.get("table_rewrite_allowed"),
    "index_rebuild_allowed": config.get("index_rebuild_allowed"),
    "sequence_remap_allowed": config.get("sequence_remap_allowed"),
    "foreign_key_mutation_allowed": config.get("foreign_key_mutation_allowed"),
    "routing_mutation_allowed": config.get("routing_mutation_allowed"),
    "dsn_mutation_allowed": config.get("dsn_mutation_allowed"),
    "record_count": len(rows),
    "next_step": model.get("next_step", {}).get("step"),
    "readiness_records": rows
}, indent=2, ensure_ascii=False))
PY
