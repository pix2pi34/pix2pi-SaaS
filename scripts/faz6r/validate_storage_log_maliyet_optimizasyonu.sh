#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_5_3_storage_log_maliyet_optimizasyonu.v1.json}"
PLAN_FILE="${2:-configs/faz6r/storage_log_cost_optimization.cost_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_5_3_storage_log_maliyet_optimizasyonu_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_storage_log_cost_optimization_dry_run.sh}"

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
    require(config.get("item") == "295", "item must be 295")
    require(config.get("code") == "FAZ_6_21_5_3", "code must be FAZ_6_21_5_3")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "storage_delete_allowed",
        "log_delete_allowed",
        "backup_delete_allowed",
        "audit_delete_allowed",
        "evidence_delete_allowed",
        "retention_delete_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    classes = {c.get("class") for c in config.get("storage_classes", [])}
    for cls in fixture.get("expected_storage_classes", []):
        require(cls in classes, f"storage class missing: {cls}")

    signals = set(config.get("signals", []))
    for signal in ["log_volume_growth_rate", "audit_log_growth_rate", "backup_storage_growth_rate", "evidence_artifact_growth_rate", "tenant_storage_distribution"]:
        require(signal in signals, f"signal missing: {signal}")

    retention = config.get("retention_tier_policy", {})
    require(retention.get("enabled") is True, "retention tier policy must be enabled")
    require(retention.get("delete_requires_explicit_approval") is True, "delete must require explicit approval")
    require(retention.get("audit_evidence_never_auto_delete") is True, "audit evidence must never auto delete")
    require(len(retention.get("tiers", [])) >= 3, "retention tiers incomplete")

    guards = config.get("guards", {})
    for guard_name in ["evidence_retention_guard", "audit_log_retention_guard", "tenant_data_retention_guard", "backup_storage_guard"]:
        guard = guards.get(guard_name, {})
        require(guard.get("enabled") is True, f"{guard_name} must be enabled")
        require(guard.get("auto_delete_allowed") is False, f"{guard_name} auto delete must be false")

    rec_policy = config.get("recommendation_policy", {})
    for key in ["log_volume_review_enabled", "backup_storage_review_enabled", "artifact_storage_review_enabled", "compression_archive_review_enabled", "lifecycle_transition_review_enabled"]:
        require(rec_policy.get(key) is True, f"{key} must be true")
    require(rec_policy.get("recommendation_only") is True, "recommendation_only must be true")
    require(rec_policy.get("requires_retention_confirmation") is True, "retention confirmation required")
    require(rec_policy.get("requires_tenant_scope_confirmation") is True, "tenant scope confirmation required")

    manual = config.get("manual_approval_policy", {})
    require(manual.get("required") is True, "manual approval required")
    for action in ["storage_delete_execute", "log_delete_execute", "backup_delete_execute", "audit_delete_execute", "evidence_delete_execute", "retention_delete_execute"]:
        require(action in manual.get("required_for", []), f"manual approval action missing: {action}")

    provider = config.get("provider_mutation_closed_policy", {})
    require(provider.get("enabled") is True, "provider mutation closed policy must be enabled")
    for field in ["provider_mutation_allowed", "storage_delete_allowed", "log_delete_allowed", "backup_delete_allowed", "audit_delete_allowed", "evidence_delete_allowed", "retention_delete_allowed", "lifecycle_transition_allowed", "compression_archive_allowed"]:
        require(provider.get(field) is False, f"provider {field} must be false")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence policy required")
    fields = set(evidence.get("minimum_fields", []))
    for field in ["recommendation_id", "storage_surface", "storage_class", "current_cost_driver", "recommended_action", "estimated_savings_level", "risk_level", "retention_guard_status", "tenant_scope_guard_status", "approval_required", "mutation_allowed", "timestamp"]:
        require(field in fields, f"evidence field missing: {field}")

    require(plan.get("status") == fixture.get("expected_status"), "plan status mismatch")
    recs = plan.get("recommendations", [])
    require(len(recs) >= fixture.get("expected_min_recommendation_count"), "recommendation count below minimum")

    for rec in recs:
        require(bool(rec.get("recommendation_id")), "recommendation id missing")
        require(rec.get("storage_class") in classes, f"invalid storage class: {rec.get('storage_class')}")
        require(rec.get("approval_required") is True, f"approval must be required: {rec.get('recommendation_id')}")
        require(rec.get("mutation_allowed") is False, f"mutation must be false: {rec.get('recommendation_id')}")
        require(bool(rec.get("retention_guard_status")), f"retention guard missing: {rec.get('recommendation_id')}")
        require(bool(rec.get("tenant_scope_guard_status")), f"tenant scope guard missing: {rec.get('recommendation_id')}")

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
        require(runtime.get("mode") == "storage_log_cost_optimization_dry_run", "runtime mode mismatch")
        for field in ["provider_mutation_allowed", "storage_delete_allowed", "log_delete_allowed", "backup_delete_allowed", "audit_delete_allowed", "evidence_delete_allowed", "retention_delete_allowed"]:
            require(runtime.get(field) is False, f"runtime {field} must be false")
        require(runtime.get("recommendation_count") >= fixture.get("expected_min_recommendation_count"), "runtime recommendation count too low")
        for rec in runtime.get("recommendations", []):
            require(rec.get("status") == "DRY_RUN_STORAGE_LOG_COST_RECOMMENDATION_ONLY", "runtime recommendation status mismatch")
            require(rec.get("mutation_allowed") is False, "runtime mutation must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: Storage / log maliyet optimizasyonu config, plan, fixture and dry-run runtime are semantically valid")
PY
