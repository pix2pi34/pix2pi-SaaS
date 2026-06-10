#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_20_6_partition_shard_readiness_modeli.v1.json}"
MODEL_FILE="${2:-configs/faz6r/partition_shard_readiness_model.db_scale.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_20_6_partition_shard_readiness_modeli_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_partition_shard_readiness_model_dry_run.sh}"

python3 - "$CONFIG_FILE" "$MODEL_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
model_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(model_path.exists(), f"model missing: {model_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    model = json.loads(model_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "307", "item must be 307")
    require(config.get("code") == "FAZ_6_20_6", "code must be FAZ_6_20_6")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "partition_create_allowed",
        "partition_drop_allowed",
        "shard_split_allowed",
        "shard_move_allowed",
        "tenant_move_allowed",
        "table_rewrite_allowed",
        "index_rebuild_allowed",
        "sequence_remap_allowed",
        "foreign_key_mutation_allowed",
        "routing_mutation_allowed",
        "dsn_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("candidate_surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    shard_key = config.get("shard_key_readiness_policy", {})
    require(shard_key.get("enabled") is True, "shard key readiness enabled")
    for prop in [
        "deterministic",
        "tenant_scoped",
        "stable_over_time",
        "low_cross_shard_join_risk",
        "supports_read_pool_strategy",
        "supports_backup_restore_scope",
        "supports_reporting_projection"
    ]:
        require(prop in shard_key.get("required_properties", []), f"shard key property missing: {prop}")
    require(shard_key.get("block_if_cross_tenant_key") is True, "cross tenant key block required")
    require(shard_key.get("block_if_non_deterministic_key") is True, "non deterministic key block required")
    require(shard_key.get("block_if_high_cross_shard_transaction_risk") is True, "cross shard transaction block required")

    tenant_dist = config.get("tenant_distribution_model", {})
    require(tenant_dist.get("enabled") is True, "tenant distribution model enabled")
    require(int(tenant_dist.get("minimum_observation_days", 0)) >= 14, "minimum observation days must be >= 14")
    require(tenant_dist.get("requires_hot_tenant_detection") is True, "hot tenant detection required")
    require(tenant_dist.get("requires_period_growth_detection") is True, "period growth detection required")
    metrics = set(tenant_dist.get("required_metrics", []))
    for metric in [
        "tenant_row_count_distribution",
        "tenant_storage_distribution",
        "tenant_write_rate_distribution",
        "hot_tenant_candidates",
        "period_growth_rate",
        "read_pool_query_distribution"
    ]:
        require(metric in metrics, f"tenant distribution metric missing: {metric}")

    guards = config.get("guards", {})
    for guard_name in [
        "cross_shard_transaction_guard",
        "sequence_identity_guard",
        "foreign_key_boundary_guard",
        "reporting_readmodel_impact_guard",
        "migration_rewrite_safety_policy",
        "rollback_reversibility_policy"
    ]:
        require(guards.get(guard_name, {}).get("enabled") is True, f"{guard_name} must be enabled")

    require(guards.get("cross_shard_transaction_guard", {}).get("block_if_financial_consistency_boundary_unknown") is True, "financial boundary block required")
    require(guards.get("foreign_key_boundary_guard", {}).get("block_if_cross_shard_fk_required") is True, "cross shard FK block required")
    require(guards.get("reporting_readmodel_impact_guard", {}).get("block_if_projection_rebuild_plan_missing") is True, "projection rebuild plan block required")
    require(guards.get("migration_rewrite_safety_policy", {}).get("mode") == "dry_run_only", "migration rewrite must be dry-run only")
    require(guards.get("rollback_reversibility_policy", {}).get("block_if_reverse_migration_missing") is True, "reverse migration block required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in [
        "partition_create_execute",
        "partition_drop_execute",
        "shard_split_execute",
        "shard_move_execute",
        "tenant_move_execute",
        "table_rewrite_execute",
        "index_rebuild_execute",
        "sequence_remap_execute",
        "foreign_key_mutation_execute",
        "routing_mutation_execute",
        "dsn_mutation_execute"
    ]:
        require(action in manual.get("required_for", []), f"manual action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in [
        "provider_mutation_allowed",
        "partition_create_allowed",
        "partition_drop_allowed",
        "shard_split_allowed",
        "shard_move_allowed",
        "tenant_move_allowed",
        "table_rewrite_allowed",
        "index_rebuild_allowed",
        "sequence_remap_allowed",
        "foreign_key_mutation_allowed",
        "routing_mutation_allowed",
        "dsn_mutation_allowed"
    ]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in [
        "readiness_id",
        "surface",
        "candidate_type",
        "preferred_key",
        "tenant_distribution_status",
        "shard_key_status",
        "cross_shard_guard_status",
        "reporting_impact_status",
        "migration_safety_status",
        "risk_level",
        "approval_required",
        "mutation_allowed",
        "timestamp"
    ]:
        require(field in fields, f"evidence field missing: {field}")

    require(model.get("status") == fixture.get("expected_status"), "model status mismatch")
    records = model.get("readiness_records", [])
    require(len(records) >= fixture.get("expected_min_record_count"), "record count below minimum")

    record_surfaces = {r.get("surface") for r in records}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in record_surfaces, f"record surface missing: {surface}")

    for r in records:
        require(bool(r.get("readiness_id")), "readiness id missing")
        require(r.get("surface") in surfaces, f"invalid surface: {r.get('surface')}")
        require(bool(r.get("candidate_type")), f"candidate type missing: {r.get('readiness_id')}")
        require(bool(r.get("preferred_key")), f"preferred key missing: {r.get('readiness_id')}")
        require(r.get("approval_required") is True, f"approval must be required: {r.get('readiness_id')}")
        require(r.get("mutation_allowed") is False, f"mutation must be false: {r.get('readiness_id')}")
        require(bool(r.get("tenant_distribution_status")), f"tenant distribution missing: {r.get('readiness_id')}")
        require(bool(r.get("shard_key_status")), f"shard key status missing: {r.get('readiness_id')}")
        require(bool(r.get("cross_shard_guard_status")), f"cross shard guard missing: {r.get('readiness_id')}")
        require(bool(r.get("reporting_impact_status")), f"reporting impact missing: {r.get('readiness_id')}")
        require(bool(r.get("migration_safety_status")), f"migration safety missing: {r.get('readiness_id')}")

    next_step = model.get("next_step", {})
    require(next_step.get("step") == fixture.get("expected_next_step"), "next step mismatch")
    require(next_step.get("runtime_mutation_allowed_now") is False, "next runtime mutation flag must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(model_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "partition_shard_readiness_model_dry_run", "runtime mode mismatch")
        for field in [
            "provider_mutation_allowed",
            "partition_create_allowed",
            "partition_drop_allowed",
            "shard_split_allowed",
            "shard_move_allowed",
            "tenant_move_allowed",
            "table_rewrite_allowed",
            "index_rebuild_allowed",
            "sequence_remap_allowed",
            "foreign_key_mutation_allowed",
            "routing_mutation_allowed",
            "dsn_mutation_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("record_count") >= fixture.get("expected_min_record_count"), "runtime record count too low")
        require(runtime.get("next_step") == fixture.get("expected_next_step"), "runtime next step mismatch")
        for row in runtime.get("readiness_records", []):
            require(row.get("status") == "DRY_RUN_PARTITION_SHARD_READINESS_RECORD", "runtime row status mismatch")
            require(row.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Partition / shard readiness modeli config, model, fixture and dry-run runtime are semantically valid")
PY
