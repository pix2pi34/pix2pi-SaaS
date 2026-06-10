#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_5_sre_metric_review.v1.json}"
METRIC_FILE="${2:-configs/faz6r/sre_metric_review.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_5_sre_metric_review_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_sre_metric_review_snapshot.sh}"

python3 - "$CONFIG_FILE" "$METRIC_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
metric_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(metric_path.exists(), f"metric file missing: {metric_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    metrics = json.loads(metric_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == "FAZ_6_R", "phase must be FAZ_6_R")
    require(config.get("item") == "289", "item must be 289")
    require(config.get("code") == "FAZ_6_21_7_5", "code must be FAZ_6_21_7_5")
    require(fixture.get("expected_dependency") in config.get("depends_on", []), "dependency missing")

    require(config.get("runtime_mutation_allowed") is False, "runtime mutation must be false")
    require(config.get("alert_provider_enabled") is False, "alert provider must be false")
    require(config.get("grafana_mutation_allowed") is False, "grafana mutation must be false")
    require(config.get("prometheus_rule_mutation_allowed") is False, "prometheus rule mutation must be false")

    required = set(config.get("required_controls", []))
    expected_required = set(fixture.get("expected_required_controls", []))
    require(expected_required.issubset(required), "required controls incomplete")

    golden = {g.get("signal") for g in config.get("golden_signals", [])}
    for signal in fixture.get("expected_golden_signals", []):
        require(signal in golden, f"golden signal missing: {signal}")

    threshold = config.get("threshold_policy", {})
    require(threshold.get("enabled") is True, "threshold policy must be enabled")
    require(threshold.get("p0_requires_escalation") is True, "P0 must require escalation")
    require(threshold.get("p1_requires_escalation") is True, "P1 must require escalation")
    require(threshold.get("manual_approval_required_for_auto_action") is True, "manual approval must be required for auto action")
    require(threshold.get("alert_provider_mode") == fixture.get("expected_provider_mode"), "alert provider mode mismatch")

    provider = config.get("provider_closed_policy", {})
    require(provider.get("enabled") is True, "provider closed policy must be enabled")
    require(provider.get("alert_provider_enabled") is False, "provider alert must be disabled")
    require(provider.get("grafana_mutation_allowed") is False, "provider grafana mutation must be false")
    require(provider.get("prometheus_rule_mutation_allowed") is False, "provider prometheus mutation must be false")
    require(provider.get("pager_enabled") is False, "pager must be disabled")
    require(provider.get("sms_enabled") is False, "sms must be disabled")
    require(provider.get("email_enabled") is False, "email must be disabled")

    evidence = config.get("evidence_policy", {})
    require(evidence.get("required") is True, "evidence must be required")
    evidence_fields = set(evidence.get("minimum_fields", []))
    for field in ["metric_id", "surface", "signal", "severity_mapping", "threshold", "dashboard", "owner", "review_status", "timestamp"]:
        require(field in evidence_fields, f"evidence field missing: {field}")

    groups = metrics.get("metric_groups", [])
    group_names = {g.get("group") for g in groups}
    for group in fixture.get("expected_metric_groups", []):
        require(group in group_names, f"metric group missing: {group}")

    metric_count = sum(len(g.get("metrics", [])) for g in groups)
    require(metric_count >= fixture.get("expected_min_metric_count"), "metric count below expected minimum")

    seen_signals = set()
    for group in groups:
        require(bool(group.get("dashboard")), f"dashboard missing for group {group.get('group')}")
        require(bool(group.get("owner")), f"owner missing for group {group.get('group')}")
        for metric in group.get("metrics", []):
            require(bool(metric.get("metric_id")), "metric_id missing")
            require(bool(metric.get("surface")), f"surface missing for {metric.get('metric_id')}")
            require(metric.get("signal") in fixture.get("expected_golden_signals", []), f"invalid signal for {metric.get('metric_id')}")
            require(bool(metric.get("severity_mapping")), f"severity mapping missing for {metric.get('metric_id')}")
            require(bool(metric.get("threshold")), f"threshold missing for {metric.get('metric_id')}")
            require(metric.get("required") is True, f"metric must be required: {metric.get('metric_id')}")
            seen_signals.add(metric.get("signal"))

    for signal in fixture.get("expected_golden_signals", []):
        require(signal in seen_signals, f"no metric uses golden signal: {signal}")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(metric_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime_status must be PASS")
        require(runtime.get("mode") == "dry_run_metric_snapshot", "runtime mode mismatch")
        require(runtime.get("alert_provider_enabled") is False, "runtime alert provider must be false")
        require(runtime.get("grafana_mutation_allowed") is False, "runtime grafana mutation must be false")
        require(runtime.get("prometheus_rule_mutation_allowed") is False, "runtime prometheus mutation must be false")
        require(runtime.get("metric_count") >= fixture.get("expected_min_metric_count"), "runtime metric count too low")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: SRE metric review config, metric catalog, fixture and dry-run snapshot are semantically valid")
PY
