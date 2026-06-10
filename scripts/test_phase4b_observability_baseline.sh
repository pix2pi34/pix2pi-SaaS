#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_observability_baseline.sh"
PY_SCRIPT="scripts/phase4b_observability_baseline.py"
REPORT="docs/phase4/22_1_observability_baseline_report.md"
MATRIX="docs/phase4/22_1_observability_baseline_matrix.tsv"
SIGNALS="docs/phase4/22_1_observability_signal_inventory.tsv"
TARGETS="docs/phase4/22_1_observability_target_inventory.tsv"
PROBES="docs/phase4/22_1_observability_endpoint_probe.tsv"
ALERTS="docs/phase4/22_1_observability_alert_readiness.tsv"
POLICY="docs/phase4/22_1_observability_baseline_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ observability baseline wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ observability baseline python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_22_1_observability_baseline.log 2>&1 || {
  echo "TEST_FAIL ❌ observability baseline script hata verdi"
  cat /tmp/pix2pi_22_1_observability_baseline.log || true
  sed -n '1,2600p' "$REPORT" || true
  exit 1
}

for required in \
  "OBSERVABILITY_BASELINE=PASS" \
  "FAZ4B_22_1_FINAL_STATUS=PASS" \
  "OBSERVABILITY_PREVIOUS_20=PASS" \
  "OBSERVABILITY_PREVIOUS_21=PASS" \
  "OBSERVABILITY_SIGNAL_INVENTORY=PASS" \
  "OBSERVABILITY_TARGET_INVENTORY=PASS" \
  "OBSERVABILITY_ENDPOINT_PROBE=PASS" \
  "OBSERVABILITY_ALERT_READINESS=PASS" \
  "OBSERVABILITY_NO_RESTART=PASS" \
  "OBSERVABILITY_NO_DEPLOY=PASS" \
  "OBSERVABILITY_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "DASHBOARD_CHANGED=NO" \
  "ALERT_RULE_CHANGED=NO" \
  "PROMETHEUS_CONFIG_CHANGED=NO" \
  "GRAFANA_CONFIG_CHANGED=NO" \
  "LOKI_CONFIG_CHANGED=NO" \
  "TEMPO_CONFIG_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
  "METRIC_BODY_PRINTED=NO" \
  "TRACE_BODY_PRINTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$SIGNALS" "$TARGETS" "$PROBES" "$ALERTS" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_20 \
  previous_21 \
  signal_inventory \
  target_inventory \
  endpoint_probe \
  alert_readiness \
  public_observability_risk \
  service_risk_evidence \
  container_risk_evidence \
  no_restart \
  no_deploy \
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
  "evidence_source" \
  "category" \
  "severity" \
  "baseline_status"
do
  grep -q "$header" "$SIGNALS" || {
    echo "TEST_FAIL ❌ signal inventory header eksik: $header"
    cat "$SIGNALS" || true
    exit 1
  }
done

for header in \
  "probe_name" \
  "status_code" \
  "body_policy" \
  "reachable"
do
  grep -q "$header" "$PROBES" || {
    echo "TEST_FAIL ❌ endpoint probe header eksik: $header"
    cat "$PROBES" || true
    exit 1
  }
done

for header in \
  "alert_name" \
  "severity" \
  "signal_name" \
  "readiness_status"
do
  grep -q "$header" "$ALERTS" || {
    echo "TEST_FAIL ❌ alert readiness header eksik: $header"
    cat "$ALERTS" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$SIGNALS" "$TARGETS" "$PROBES" "$ALERTS" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$SIGNALS" "$TARGETS" "$PROBES" "$ALERTS" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$SIGNALS" "$TARGETS" "$PROBES" "$ALERTS" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_OBSERVABILITY_BASELINE_TEST=PASS ✅"
echo "PHASE4B_OBSERVABILITY_SIGNAL_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_OBSERVABILITY_TARGET_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_OBSERVABILITY_ENDPOINT_PROBE_TEST=PASS ✅"
echo "PHASE4B_OBSERVABILITY_ALERT_READINESS_TEST=PASS ✅"
echo "PHASE4B_OBSERVABILITY_NO_RESTART_TEST=PASS ✅"
echo "PHASE4B_OBSERVABILITY_SECRET_TEST=PASS ✅"
