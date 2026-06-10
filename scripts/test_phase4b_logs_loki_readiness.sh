#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_logs_loki_readiness.sh"
PY_SCRIPT="scripts/phase4b_logs_loki_readiness.py"
REPORT="docs/phase4/22_3_logs_loki_readiness_report.md"
MATRIX="docs/phase4/22_3_logs_loki_readiness_matrix.tsv"
SOURCES="docs/phase4/22_3_logs_source_inventory.tsv"
PROBES="docs/phase4/22_3_loki_endpoint_probe.tsv"
PIPELINE="docs/phase4/22_3_log_pipeline_inventory.tsv"
PUBLIC_POLICY="docs/phase4/22_3_logs_public_surface_policy.tsv"
POLICY="docs/phase4/22_3_logs_loki_readiness_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ logs loki readiness wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ logs loki readiness python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_22_3_logs_loki_readiness.log 2>&1 || {
  echo "TEST_FAIL ❌ logs loki readiness script hata verdi"
  cat /tmp/pix2pi_22_3_logs_loki_readiness.log || true
  sed -n '1,2800p' "$REPORT" || true
  exit 1
}

for required in \
  "LOGS_LOKI_READINESS=PASS" \
  "FAZ4B_22_3_FINAL_STATUS=PASS" \
  "LOGS_PREVIOUS_22_2=PASS" \
  "LOGS_LOKI_ENDPOINT_PROBE=PASS" \
  "LOGS_SOURCE_INVENTORY=PASS" \
  "LOGS_PIPELINE_INVENTORY=PASS" \
  "LOGS_PUBLIC_SURFACE_POLICY=PASS" \
  "LOGS_BODY_NOT_PRINTED=PASS" \
  "LOGS_NO_RESTART=PASS" \
  "LOGS_NO_CONFIG_CHANGE=PASS" \
  "LOGS_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "LOKI_CONFIG_CHANGED=NO" \
  "LOKI_RELOAD_EXECUTED=NO" \
  "LOKI_RESTARTED=NO" \
  "PROMTAIL_CONFIG_CHANGED=NO" \
  "LOG_AGENT_CONFIG_CHANGED=NO" \
  "GRAFANA_DASHBOARD_CHANGED=NO" \
  "ALERT_RULE_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
  "LOKI_QUERY_BODY_PRINTED=NO" \
  "JOURNAL_LOG_BODY_PRINTED=NO" \
  "DOCKER_LOG_BODY_PRINTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2800p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$SOURCES" "$PROBES" "$PIPELINE" "$PUBLIC_POLICY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_22_2 \
  loki_endpoint_probe \
  loki_ready_metadata \
  log_source_inventory \
  log_pipeline_inventory \
  public_surface_policy \
  body_not_printed \
  no_restart \
  no_config_change \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for header in \
  "source_type" \
  "source_name" \
  "log_driver_or_source" \
  "risk" \
  "note"
do
  grep -q "$header" "$SOURCES" || {
    echo "TEST_FAIL ❌ source inventory header eksik: $header"
    cat "$SOURCES" || true
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

for header in \
  "config_path" \
  "loki_marker_count" \
  "promtail_marker_count" \
  "redaction_marker_count"
do
  grep -q "$header" "$PIPELINE" || {
    echo "TEST_FAIL ❌ pipeline inventory header eksik: $header"
    cat "$PIPELINE" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$SOURCES" "$PROBES" "$PIPELINE" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$SOURCES" "$PROBES" "$PIPELINE" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$SOURCES" "$PROBES" "$PIPELINE" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_LOGS_LOKI_READINESS_TEST=PASS ✅"
echo "PHASE4B_LOGS_SOURCE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_LOGS_LOKI_ENDPOINT_PROBE_TEST=PASS ✅"
echo "PHASE4B_LOGS_PIPELINE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_LOGS_PUBLIC_SURFACE_POLICY_TEST=PASS ✅"
echo "PHASE4B_LOGS_NO_RESTART_TEST=PASS ✅"
echo "PHASE4B_LOGS_SECRET_TEST=PASS ✅"
