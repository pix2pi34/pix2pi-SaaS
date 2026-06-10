#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_alert_rule_catalog.sh"
PY_SCRIPT="scripts/phase4b_alert_rule_catalog.py"
REPORT="docs/phase4/22_5_alert_rule_catalog_report.md"
MATRIX="docs/phase4/22_5_alert_rule_catalog_matrix.tsv"
CATALOG="docs/phase4/22_5_alert_rule_catalog.tsv"
SEVERITY="docs/phase4/22_5_alert_severity_matrix.tsv"
MAPPING="docs/phase4/22_5_alert_signal_mapping.tsv"
ESCALATION="docs/phase4/22_5_alert_escalation_matrix.tsv"
POLICY="docs/phase4/22_5_alert_rule_catalog_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ alert rule catalog wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ alert rule catalog python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_22_5_alert_rule_catalog.log 2>&1 || {
  echo "TEST_FAIL ❌ alert rule catalog script hata verdi"
  cat /tmp/pix2pi_22_5_alert_rule_catalog.log || true
  sed -n '1,3000p' "$REPORT" || true
  exit 1
}

for required in \
  "ALERT_RULE_CATALOG=PASS" \
  "FAZ4B_22_5_FINAL_STATUS=PASS" \
  "ALERT_PREVIOUS_22_4=PASS" \
  "ALERT_RULE_INVENTORY=PASS" \
  "ALERT_SEVERITY_MATRIX=PASS" \
  "ALERT_SIGNAL_MAPPING=PASS" \
  "ALERT_ESCALATION_MATRIX=PASS" \
  "ALERT_RUNBOOK_PLACEHOLDER=PASS" \
  "ALERT_NO_CONFIG_CHANGE=PASS" \
  "ALERT_NO_RESTART=PASS" \
  "ALERT_BODY_NOT_PRINTED=PASS" \
  "ALERT_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "PROMETHEUS_CONFIG_CHANGED=NO" \
  "PROMETHEUS_RELOAD_EXECUTED=NO" \
  "PROMETHEUS_RESTARTED=NO" \
  "ALERTMANAGER_CONFIG_CHANGED=NO" \
  "ALERTMANAGER_RELOAD_EXECUTED=NO" \
  "ALERTMANAGER_RESTARTED=NO" \
  "GRAFANA_DASHBOARD_CHANGED=NO" \
  "GRAFANA_ALERT_CHANGED=NO" \
  "ALERT_RULE_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "METRIC_BODY_PRINTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
  "TRACE_BODY_PRINTED=NO" \
  "PROMETHEUS_QUERY_BODY_PRINTED=NO" \
  "LOKI_QUERY_BODY_PRINTED=NO" \
  "TEMPO_QUERY_BODY_PRINTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,3000p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CATALOG" "$SEVERITY" "$MAPPING" "$ESCALATION" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_22_4 \
  alert_rule_inventory \
  severity_matrix \
  signal_mapping \
  escalation_matrix \
  runbook_placeholder \
  security_alerts \
  runtime_alerts \
  db_alerts \
  event_bus_alerts \
  observability_alerts \
  body_not_printed \
  no_config_change \
  no_restart \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for header in \
  "alert_name" \
  "category" \
  "signal_source" \
  "severity" \
  "condition_hint" \
  "runbook_placeholder"
do
  grep -q "$header" "$CATALOG" || {
    echo "TEST_FAIL ❌ alert catalog header eksik: $header"
    cat "$CATALOG" || true
    exit 1
  }
done

for severity in CRITICAL HIGH MEDIUM LOW; do
  grep -q "$severity" "$SEVERITY" || {
    echo "TEST_FAIL ❌ severity eksik: $severity"
    cat "$SEVERITY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CATALOG" "$SEVERITY" "$MAPPING" "$ESCALATION" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CATALOG" "$SEVERITY" "$MAPPING" "$ESCALATION" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CATALOG" "$SEVERITY" "$MAPPING" "$ESCALATION" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_ALERT_RULE_CATALOG_TEST=PASS ✅"
echo "PHASE4B_ALERT_RULE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_ALERT_SEVERITY_MATRIX_TEST=PASS ✅"
echo "PHASE4B_ALERT_SIGNAL_MAPPING_TEST=PASS ✅"
echo "PHASE4B_ALERT_ESCALATION_MATRIX_TEST=PASS ✅"
echo "PHASE4B_ALERT_NO_CONFIG_CHANGE_TEST=PASS ✅"
echo "PHASE4B_ALERT_SECRET_TEST=PASS ✅"
