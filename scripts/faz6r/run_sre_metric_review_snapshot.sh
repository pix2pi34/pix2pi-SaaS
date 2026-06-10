#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_5_sre_metric_review.v1.json}"
METRIC_FILE="${2:-configs/faz6r/sre_metric_review.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_5_sre_metric_review_test.json}"

python3 - "$CONFIG_FILE" "$METRIC_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
metrics = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
fixture = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

snapshot = []
for group in metrics.get("metric_groups", []):
    for metric in group.get("metrics", []):
        snapshot.append({
            "metric_id": metric.get("metric_id"),
            "surface": metric.get("surface"),
            "signal": metric.get("signal"),
            "severity_mapping": metric.get("severity_mapping"),
            "threshold": metric.get("threshold"),
            "dashboard": group.get("dashboard"),
            "owner": group.get("owner"),
            "review_status": "REVIEW_READY",
            "timestamp": datetime.now(timezone.utc).isoformat()
        })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "dry_run_metric_snapshot",
    "alert_provider_enabled": config.get("alert_provider_enabled"),
    "grafana_mutation_allowed": config.get("grafana_mutation_allowed"),
    "prometheus_rule_mutation_allowed": config.get("prometheus_rule_mutation_allowed"),
    "metric_count": len(snapshot),
    "expected_min_metric_count": fixture.get("expected_min_metric_count"),
    "metrics": snapshot
}, indent=2, ensure_ascii=False))
PY
