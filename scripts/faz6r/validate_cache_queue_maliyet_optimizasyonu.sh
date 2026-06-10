#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_4_cache_queue_maliyet_optimizasyonu.v1.json}"
PLAN_FILE="${2:-configs/faz6r/cache_queue_cost_optimization.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_4_cache_queue_maliyet_optimizasyonu_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_cache_queue_cost_optimization_dry_run.sh}"

python3 - "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(plan_path.exists(), f"plan missing: {plan_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "296", "item must be 296")
    require(config.get("code") == "FAZ_6_21_5_4", "code must be FAZ_6_21_5_4")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "cache_flush_allowed",
        "cache_key_delete_allowed",
        "cache_ttl_mutation_allowed",
        "queue_purge_allowed",
        "stream_delete_allowed",
        "consumer_delete_allowed",
        "queue_retention_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("surfaces", [])}
    for surface in fixture.get("expected_surfaces", []):
        require(surface in surfaces, f"surface missing: {surface}")

    signals = set(config.get("signals", []))
    for signal in ["cache_memory_usage", "cache_hit_ratio", "hot_key_candidates", "ttl_missing_key_count", "queue_stream_storage_bytes", "queue_consumer_lag", "dlq_message_count", "idempotency_replay_count"]:
        require(signal in signals, f"signal missing: {signal}")

    rec_policy = config.get("recommendation_policy", {})
    for key in [
        "cache_ttl_review_enabled",
        "cache_hot_key_review_enabled",
        "cache_memory_review_enabled",
        "queue_retention_review_enabled",
        "queue_consumer_lag_review_enabled",
        "dlq_growth_review_enabled",
        "stream_storage_review_enabled"
    ]:
        require(rec_policy.get(key) is True, f"{key} must be true")
    require(rec_policy.get("recommendation_only") is True, "recommendation_only must be true")
    require(rec_policy.get("requires_tenant_namespace_confirmation") is True, "tenant namespace confirmation required")
    require(rec_policy.get("requires_idempotency_confirmation") is True, "idempotency confirmation required")

    guards = config.get("guards", {})
    require(guards.get("tenant_namespace_guard", {}).get("enabled") is True, "tenant namespace guard enabled")
    require(guards.get("tenant_namespace_guard", {}).get("block_if_key_without_tenant_namespace") is True, "tenant namespace block missing")
    require(guards.get("idempotency_safety_guard", {}).get("enabled") is True, "idempotency guard enabled")
    require(guards.get("idempotency_safety_guard", {}).get("block_if_replay_or_dedup_risk") is True, "idempotency block missing")
    require(guards.get("queue_replay_guard", {}).get("enabled") is True, "queue replay guard enabled")
    require(guards.get("performance_slo_guard", {}).get("enabled") is True, "performance SLO guard enabled")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in ["cache_flush_execute", "cache_key_delete_execute", "cache_ttl_change_execute", "queue_purge_execute", "stream_delete_execute", "consumer_delete_execute", "queue_retention_change_execute", "dlq_cleanup_execute"]:
        require(action in manual.get("required_for", []), f"manual approval action missing: {action}")

    provider = config.get("provider_mutation_closed_policy", {})
    require(provider.get("enabled") is True, "provider mutation closed policy enabled")
    for field in ["provider_mutation_allowed", "cache_flush_allowed", "cache_key_delete_allowed", "cache_ttl_mutation_allowed", "queue_purge_allowed", "stream_delete_allowed", "consumer_delete_allowed", "queue_retention_mutation_allowed"]:
        require(provider.get(field) is False, f"provider {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in ["recommendation_id", "surface", "resource_class", "current_cost_driver", "recommended_action", "estimated_savings_level", "risk_level", "tenant_namespace_guard_status", "idempotency_guard_status", "approval_required", "mutation_allowed", "timestamp"]:
        require(field in fields, f"evidence field missing: {field}")

    require(plan.get("status") == fixture.get("expected_status"), "plan status mismatch")
    recs = plan.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("recommendation_id")), "recommendation id missing")
        require(rec.get("surface") in surfaces, f"invalid surface: {rec.get('surface')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('recommendation_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('recommendation_id')}")
        require(bool(rec.get("tenant_namespace_guard_status")), f"tenant namespace guard missing: {rec.get('recommendation_id')}")
        require(bool(rec.get("idempotency_guard_status")), f"idempotency guard missing: {rec.get('recommendation_id')}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(plan_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "cache_queue_cost_optimization_dry_run", "runtime mode mismatch")
        for field in ["provider_mutation_allowed", "cache_flush_allowed", "cache_key_delete_allowed", "cache_ttl_mutation_allowed", "queue_purge_allowed", "stream_delete_allowed", "consumer_delete_allowed", "queue_retention_mutation_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        for rec in runtime.get("recommendations", []):
            require(rec.get("status") == "DRY_RUN_CACHE_QUEUE_COST_RECOMMENDATION_ONLY", "runtime recommendation status mismatch")
            require(rec.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Cache / queue maliyet optimizasyonu config, plan, fixture and dry-run runtime are semantically valid")
PY
