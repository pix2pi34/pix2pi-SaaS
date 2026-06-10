#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_7_2_otomatik_remediation.v1.json}"
RULES_FILE="${2:-configs/faz6r/auto_remediation.sre_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_7_2_otomatik_remediation_test.json}"

python3 - "$CONFIG_FILE" "$RULES_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
rules_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
fixture = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

rules_by_signal = {r["signal"]: r for r in rules_doc.get("rules", [])}
safe_allowlist = set(config.get("safe_action_allowlist", []))
unsafe_denylist = set(config.get("unsafe_action_denylist", []))

results = []

for incident in fixture.get("sample_incidents", []):
    signal = incident.get("signal")
    severity = incident.get("severity")
    rule = rules_by_signal.get(signal)

    if not rule:
        results.append({
            "incident_id": incident.get("incident_id"),
            "status": "NO_RULE",
            "signal": signal
        })
        continue

    safe_actions = [a for a in rule.get("safe_actions", []) if a in safe_allowlist]
    blocked_unsafe = [a for a in rule.get("unsafe_actions_blocked", []) if a in unsafe_denylist]

    approval_required = (
        severity in config.get("approval_policy", {}).get("required_for_severities", [])
        or bool(blocked_unsafe)
    )

    results.append({
        "incident_id": incident.get("incident_id"),
        "severity": severity,
        "signal": signal,
        "recommended_action": safe_actions[0] if safe_actions else "recommend_runbook",
        "all_safe_recommendations": safe_actions,
        "blocked_unsafe_actions": blocked_unsafe,
        "action_mode": config.get("auto_remediation_mode"),
        "approval_required": approval_required,
        "runbook_id": rule.get("runbook_id"),
        "decision_reason": "dry_run_guarded_mode_no_production_mutation",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "DRY_RUN_RECOMMENDATION"
    })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": config.get("auto_remediation_mode"),
    "production_mutation_allowed": config.get("production_mutation_allowed"),
    "destructive_action_default_allowed": config.get("destructive_action_default_allowed"),
    "decision_count": len(results),
    "decisions": results
}, indent=2, ensure_ascii=False))
PY
