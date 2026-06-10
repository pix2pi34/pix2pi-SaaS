#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_ops_console_signal_contract.sh"
PY_SCRIPT="scripts/phase4b_ops_console_signal_contract.py"
REPORT="docs/phase4/22_6_ops_console_signal_contract_report.md"
MATRIX="docs/phase4/22_6_ops_console_signal_contract_matrix.tsv"
SIGNALS="docs/phase4/22_6_ops_console_signal_contract.tsv"
WIDGETS="docs/phase4/22_6_ops_console_widget_contract.tsv"
API="docs/phase4/22_6_ops_console_api_contract.tsv"
ALERTS="docs/phase4/22_6_ops_console_alert_binding.tsv"
RUNBOOKS="docs/phase4/22_6_ops_console_runbook_binding.tsv"
POLICY="docs/phase4/22_6_ops_console_signal_contract_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ ops console signal contract wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ ops console signal contract python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_22_6_ops_console_signal_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ ops console signal contract script hata verdi"
  cat /tmp/pix2pi_22_6_ops_console_signal_contract.log || true
  sed -n '1,3200p' "$REPORT" || true
  exit 1
}

for required in \
  "OPS_CONSOLE_SIGNAL_CONTRACT=PASS" \
  "FAZ4B_22_6_FINAL_STATUS=PASS" \
  "OPS_PREVIOUS_22_5=PASS" \
  "OPS_SIGNAL_CONTRACT=PASS" \
  "OPS_WIDGET_CONTRACT=PASS" \
  "OPS_API_CONTRACT=PASS" \
  "OPS_ALERT_BINDING=PASS" \
  "OPS_RUNBOOK_BINDING=PASS" \
  "OPS_CONTRACT_COVERAGE=PASS" \
  "OPS_NO_RUNTIME_CHANGE=PASS" \
  "OPS_NO_CONFIG_CHANGE=PASS" \
  "OPS_BODY_NOT_PRINTED=PASS" \
  "OPS_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "OPS_CONSOLE_CODE_CHANGED=NO" \
  "OPS_CONSOLE_API_IMPLEMENTED=NO" \
  "OPS_CONSOLE_UI_CHANGED=NO" \
  "PROMETHEUS_CONFIG_CHANGED=NO" \
  "ALERTMANAGER_CONFIG_CHANGED=NO" \
  "GRAFANA_DASHBOARD_CHANGED=NO" \
  "GRAFANA_ALERT_CHANGED=NO" \
  "ALERT_RULE_CHANGED=NO" \
  "LOKI_CONFIG_CHANGED=NO" \
  "TEMPO_CONFIG_CHANGED=NO" \
  "OTEL_CONFIG_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "METRIC_BODY_PRINTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
  "TRACE_BODY_PRINTED=NO" \
  "QUERY_BODY_PRINTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,3200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$SIGNALS" "$WIDGETS" "$API" "$ALERTS" "$RUNBOOKS" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_22_5 \
  signal_contract \
  widget_contract \
  api_contract \
  alert_binding \
  runbook_binding \
  contract_coverage \
  security_signals \
  runtime_signals \
  observability_signals \
  no_runtime_change \
  no_config_change \
  body_not_printed \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for header in \
  "signal_name" \
  "category" \
  "default_severity" \
  "widget_ref" \
  "api_endpoint" \
  "envelope_contract"
do
  grep -q "$header" "$SIGNALS" || {
    echo "TEST_FAIL ❌ signal contract header eksik: $header"
    cat "$SIGNALS" || true
    exit 1
  }
done

for header in \
  "widget_name" \
  "widget_type" \
  "signal_refs" \
  "minimum_fields" \
  "visibility_scope"
do
  grep -q "$header" "$WIDGETS" || {
    echo "TEST_FAIL ❌ widget contract header eksik: $header"
    cat "$WIDGETS" || true
    exit 1
  }
done

for header in \
  "method" \
  "path" \
  "category" \
  "response_contract" \
  "rbac_scope"
do
  grep -q "$header" "$API" || {
    echo "TEST_FAIL ❌ api contract header eksik: $header"
    cat "$API" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$SIGNALS" "$WIDGETS" "$API" "$ALERTS" "$RUNBOOKS" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$SIGNALS" "$WIDGETS" "$API" "$ALERTS" "$RUNBOOKS" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$SIGNALS" "$WIDGETS" "$API" "$ALERTS" "$RUNBOOKS" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_OPS_CONSOLE_SIGNAL_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_OPS_SIGNAL_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_OPS_WIDGET_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_OPS_API_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_OPS_ALERT_BINDING_TEST=PASS ✅"
echo "PHASE4B_OPS_RUNBOOK_BINDING_TEST=PASS ✅"
echo "PHASE4B_OPS_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_OPS_SECRET_TEST=PASS ✅"
