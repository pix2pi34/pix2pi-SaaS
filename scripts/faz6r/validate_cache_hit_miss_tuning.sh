#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_3_3_cache_hit_miss_tuning.v1.json}"
TUNING_FILE="${2:-configs/faz6r/cache_hit_miss_tuning.performance_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_3_3_cache_hit_miss_tuning_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_cache_hit_miss_tuning_dry_run.sh}"

python3 - "$CONFIG_FILE" "$TUNING_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
tuning_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(tuning_path.exists(), f"tuning missing: {tuning_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    tuning = json.loads(tuning_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "298", "item must be 298")
    require(config.get("code") == "FAZ_6_21_3_3", "code must be FAZ_6_21_3_3")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "redis_mutation_allowed",
        "cache_flush_allowed",
        "cache_key_delete_allowed",
        "cache_ttl_mutation_allowed",
        "namespace_mutation_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    surfaces = {s.get("surface") for s in config.get("cache_surfaces", [])}
    for surface in fixture.get("expected_cache_surfaces", []):
        require(surface in surfaces, f"cache surface missing: {surface}")

    metric_model = config.get("metric_model", {})
    require(metric_model.get("requires_per_tenant_breakdown") is True, "per-tenant breakdown required")
    require(int(metric_model.get("minimum_observation_days", 0)) >= 7, "minimum observation days must be >= 7")
    metrics = set(metric_model.get("required_metrics", []))
    for metric in ["cache_hit_ratio", "cache_miss_ratio", "cache_eviction_count", "hot_key_candidates", "ttl_missing_key_count", "tenant_namespace_distribution"]:
        require(metric in metrics, f"metric missing: {metric}")

    tuning_policy = config.get("tuning_policy", {})
    require(tuning_policy.get("ttl_tuning_mode") == "recommendation_only", "TTL tuning must be recommendation-only")
    require(tuning_policy.get("hot_key_action_mode") == "review_only", "hot key action must be review-only")
    require(tuning_policy.get("cache_bypass_action_mode") == "review_only", "cache bypass action must be review-only")
    require(tuning_policy.get("fallback_safety_required") is True, "fallback safety required")
    require(tuning_policy.get("stale_data_guard_required") is True, "stale data guard required")
    require(tuning_policy.get("rate_limit_cache_guard_required") is True, "rate limit cache guard required")

    guards = config.get("guards", {})
    require(guards.get("tenant_namespace_guard", {}).get("enabled") is True, "tenant namespace guard enabled")
    require(guards.get("tenant_namespace_guard", {}).get("block_if_key_without_tenant_namespace") is True, "tenant namespace block missing")
    require(guards.get("fallback_safety_policy", {}).get("enabled") is True, "fallback safety enabled")
    require(guards.get("stale_data_guard", {}).get("enabled") is True, "stale data guard enabled")
    require(guards.get("rate_limit_cache_guard", {}).get("enabled") is True, "rate limit cache guard enabled")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in ["cache_flush_execute", "cache_key_delete_execute", "cache_ttl_change_execute", "namespace_change_execute", "rate_limit_cache_policy_change_execute"]:
        require(action in manual.get("required_for", []), f"manual approval action missing: {action}")

    closed = config.get("production_mutation_closed_policy", {})
    require(closed.get("enabled") is True, "production mutation closed policy enabled")
    for field in ["provider_mutation_allowed", "redis_mutation_allowed", "cache_flush_allowed", "cache_key_delete_allowed", "cache_ttl_mutation_allowed", "namespace_mutation_allowed"]:
        require(closed.get(field) is False, f"closed policy {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in ["tuning_id", "cache_surface", "current_signal", "recommended_action", "expected_hit_ratio_impact", "risk_level", "tenant_namespace_guard_status", "fallback_safety_status", "stale_data_guard_status", "approval_required", "mutation_allowed", "timestamp"]:
        require(field in fields, f"evidence field missing: {field}")

    require(tuning.get("status") == fixture.get("expected_status"), "tuning status mismatch")
    recs = tuning.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("tuning_id")), "tuning id missing")
        require(rec.get("cache_surface") in surfaces, f"invalid cache surface: {rec.get('cache_surface')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('tuning_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('tuning_id')}")
        require(bool(rec.get("tenant_namespace_guard_status")), f"tenant namespace guard missing: {rec.get('tuning_id')}")
        require(bool(rec.get("fallback_safety_status")), f"fallback safety missing: {rec.get('tuning_id')}")
        require(bool(rec.get("stale_data_guard_status")), f"stale data guard missing: {rec.get('tuning_id')}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(tuning_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "cache_hit_miss_tuning_dry_run", "runtime mode mismatch")
        for field in ["provider_mutation_allowed", "redis_mutation_allowed", "cache_flush_allowed", "cache_key_delete_allowed", "cache_ttl_mutation_allowed", "namespace_mutation_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        for rec in runtime.get("recommendations", []):
            require(rec.get("status") == "DRY_RUN_CACHE_TUNING_RECOMMENDATION_ONLY", "runtime recommendation status mismatch")
            require(rec.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Cache hit/miss tuning config, tuning, fixture and dry-run runtime are semantically valid")
PY
