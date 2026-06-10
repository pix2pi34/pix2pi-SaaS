#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_metrics_scrape_readiness.sh"
PY_SCRIPT="scripts/phase4b_metrics_scrape_readiness.py"
REPORT="docs/phase4/22_2_metrics_scrape_readiness_report.md"
MATRIX="docs/phase4/22_2_metrics_scrape_readiness_matrix.tsv"
TARGETS="docs/phase4/22_2_metrics_target_inventory.tsv"
PROBES="docs/phase4/22_2_metrics_endpoint_probe.tsv"
PUBLIC_POLICY="docs/phase4/22_2_metrics_public_surface_policy.tsv"
POLICY="docs/phase4/22_2_metrics_scrape_readiness_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ metrics scrape readiness wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ metrics scrape readiness python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_22_2_metrics_scrape_readiness.log 2>&1 || {
  echo "TEST_FAIL ❌ metrics scrape readiness script hata verdi"
  cat /tmp/pix2pi_22_2_metrics_scrape_readiness.log || true
  sed -n '1,2600p' "$REPORT" || true
  exit 1
}

for required in \
  "METRICS_SCRAPE_READINESS=PASS" \
  "FAZ4B_22_2_FINAL_STATUS=PASS" \
  "METRICS_PREVIOUS_22_1=PASS" \
  "METRICS_TARGET_INVENTORY=PASS" \
  "METRICS_ENDPOINT_PROBE=PASS" \
  "METRICS_PROMETHEUS_READINESS=PASS" \
  "METRICS_PUBLIC_SURFACE_POLICY=PASS" \
  "METRICS_NO_RESTART=PASS" \
  "METRICS_NO_CONFIG_CHANGE=PASS" \
  "METRICS_BODY_NOT_PRINTED=PASS" \
  "METRICS_SECRET_SAFE=PASS" \
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
  "GRAFANA_DASHBOARD_CHANGED=NO" \
  "ALERT_RULE_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "METRIC_BODY_PRINTED=NO" \
  "PROMETHEUS_QUERY_BODY_PRINTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
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

for f in "$MATRIX" "$TARGETS" "$PROBES" "$PUBLIC_POLICY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_22_1 \
  target_inventory \
  endpoint_probe \
  prometheus_readiness \
  prometheus_targets_metadata \
  public_surface_policy \
  no_restart \
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
  "target_name" \
  "service_hint" \
  "port" \
  "target_role" \
  "readiness_hint"
do
  grep -q "$header" "$TARGETS" || {
    echo "TEST_FAIL ❌ target inventory header eksik: $header"
    cat "$TARGETS" || true
    exit 1
  }
done

for header in \
  "probe_name" \
  "status_code" \
  "reachable" \
  "body_policy"
do
  grep -q "$header" "$PROBES" || {
    echo "TEST_FAIL ❌ endpoint probe header eksik: $header"
    cat "$PROBES" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$TARGETS" "$PROBES" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$TARGETS" "$PROBES" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$TARGETS" "$PROBES" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_METRICS_SCRAPE_READINESS_TEST=PASS ✅"
echo "PHASE4B_METRICS_TARGET_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_METRICS_ENDPOINT_PROBE_TEST=PASS ✅"
echo "PHASE4B_METRICS_PROMETHEUS_READINESS_TEST=PASS ✅"
echo "PHASE4B_METRICS_PUBLIC_SURFACE_POLICY_TEST=PASS ✅"
echo "PHASE4B_METRICS_NO_RESTART_TEST=PASS ✅"
echo "PHASE4B_METRICS_SECRET_TEST=PASS ✅"
