#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_observability_ops_console_final_closure.sh"
PY_SCRIPT="scripts/phase4b_observability_ops_console_final_closure.py"
REPORT="docs/phase4/22_8_observability_ops_console_final_closure_report.md"
MATRIX="docs/phase4/22_8_observability_ops_console_final_closure_matrix.tsv"
INVENTORY="docs/phase4/22_8_observability_ops_console_final_closure_inventory.tsv"
CLOSURE="docs/phase4/22_observability_ops_console_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ observability final closure wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ observability final closure python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_22_8_observability_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ observability final closure script hata verdi"
  cat /tmp/pix2pi_22_8_observability_final_closure.log || true
  sed -n '1,3800p' "$REPORT" || true
  exit 1
}

for required in \
  "OBSERVABILITY_OPS_CONSOLE_FINAL_CLOSURE=PASS" \
  "FAZ4B_22_8_FINAL_STATUS=PASS" \
  "FAZ4B_22_FINAL_STATUS=PASS" \
  "OBS_FINAL_BASELINE=PASS" \
  "OBS_FINAL_METRICS=PASS" \
  "OBS_FINAL_LOGS=PASS" \
  "OBS_FINAL_TRACES=PASS" \
  "OBS_FINAL_ALERTS=PASS" \
  "OBS_FINAL_OPS_CONSOLE=PASS" \
  "OBS_FINAL_TESTS=PASS" \
  "OBS_FINAL_ARTIFACT_COVERAGE=PASS" \
  "OBS_FINAL_NO_RUNTIME_CHANGE=PASS" \
  "OBS_FINAL_NO_CONFIG_CHANGE=PASS" \
  "OBS_FINAL_BODY_NOT_PRINTED=PASS" \
  "OBS_FINAL_SECRET_SAFE=PASS" \
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
    sed -n '1,3800p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_22_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure report final status PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  baseline \
  metrics \
  logs \
  traces \
  alerts \
  ops_console \
  observability_tests \
  artifact_coverage \
  no_runtime_change \
  no_config_change \
  body_not_printed \
  secret_safe \
  metric_evidence
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for block in \
  "22.1" \
  "22.2" \
  "22.3" \
  "22.4" \
  "22.5" \
  "22.6" \
  "22.7"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_22_8_OBSERVABILITY_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_22_FINAL_STATUS_TEST=PASS ✅"
echo "PHASE4B_22_OBS_FINAL_ARTIFACT_TEST=PASS ✅"
echo "PHASE4B_22_OBS_FINAL_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_22_OBS_FINAL_NO_CONFIG_CHANGE_TEST=PASS ✅"
echo "PHASE4B_22_OBS_FINAL_BODY_NOT_PRINTED_TEST=PASS ✅"
echo "PHASE4B_22_OBS_FINAL_SECRET_TEST=PASS ✅"
