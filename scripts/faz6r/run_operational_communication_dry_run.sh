#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_21_6_4_operasyonel_iletisim_plani.v1.json}"
PLAN_FILE="${2:-configs/faz6r/operational_communication_plan.dr_ops.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_21_6_4_operasyonel_iletisim_plani_test.json}"

python3 - "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
plan = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

mapping = {m["severity"]: m for m in config.get("severity_communication_mapping", [])}
templates = plan.get("templates", [])

communications = []
for incident in plan.get("sample_incidents", []):
    severity = incident.get("severity")
    m = mapping.get(severity, {})
    for t in templates:
        include = False
        if t.get("audience") == "internal" and m.get("internal_update_required"):
            include = True
        if t.get("audience") == "external" and incident.get("customer_impact") and m.get("customer_update_required_if_customer_impact"):
            include = True
        if t.get("channel") == "status_page_draft" and incident.get("public_impact") and m.get("status_page_update_required_if_public_impact"):
            include = True
        if t.get("audience") == "security" and incident.get("security_impact") and m.get("security_owner_approval_required_if_security_impact"):
            include = True
        if t.get("audience") == "customer_support" and severity in ["P0", "P1", "P2"]:
            include = True

        if include:
            approval_required = t.get("audience") in ["external", "security"] or severity in ["P0", "P1"]
            communications.append({
                "communication_id": f"COMM-{incident.get('incident_id')}-{t.get('template_id')}",
                "incident_id": incident.get("incident_id"),
                "severity": severity,
                "audience": t.get("audience"),
                "channel": t.get("channel"),
                "message_template": t.get("template_id"),
                "approval_required": approval_required,
                "approval_owner": t.get("approval_owner"),
                "send_mode": "record_only_no_real_send",
                "next_update_minutes": m.get("next_update_minutes"),
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "status": "DRY_RUN_COMMUNICATION_RECORD"
            })

print(json.dumps({
    "runtime_status": "PASS",
    "mode": "operational_communication_dry_run",
    "real_customer_notification_enabled": config.get("real_customer_notification_enabled"),
    "real_status_page_enabled": config.get("real_status_page_enabled"),
    "real_email_enabled": config.get("real_email_enabled"),
    "real_sms_enabled": config.get("real_sms_enabled"),
    "real_phone_call_enabled": config.get("real_phone_call_enabled"),
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "communication_count": len(communications),
    "communications": communications
}, indent=2, ensure_ascii=False))
PY
