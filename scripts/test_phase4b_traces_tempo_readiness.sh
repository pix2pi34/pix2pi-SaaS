#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_traces_tempo_readiness.sh"
PY_SCRIPT="scripts/phase4b_traces_tempo_readiness.py"
REPORT="docs/phase4/22_4_traces_tempo_readiness_report.md"
MATRIX="docs/phase4/22_4_traces_tempo_readiness_matrix.tsv"
PROBES="docs/phase4/22_4_trace_endpoint_probe.tsv"
PIPELINE="docs/phase4/22_4_trace_pipeline_inventory.tsv"
CONTRACT="docs/phase4/22_4_trace_signal_contract.tsv"
PUBLIC_POLICY="docs/phase4/22_4_trace_public_surface_policy.tsv"
POLICY="docs/phase4/22_4_traces_tempo_readiness_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ traces tempo readiness wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ traces tempo readiness python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_22_4_traces_tempo_readiness.log 2>&1 || {
  echo "TEST_FAIL ❌ traces tempo readiness script hata verdi"
  cat /tmp/pix2pi_22_4_traces_tempo_readiness.log || true
  sed -n '1,3000p' "$REPORT" || true
  exit 1
}

for required in \
  "TRACES_TEMPO_READINESS=PASS" \
  "FAZ4B_22_4_FINAL_STATUS=PASS" \
  "TRACES_PREVIOUS_22_3=PASS" \
  "TRACES_TEMPO_ENDPOINT_PROBE=PASS" \
  "TRACES_PIPELINE_INVENTORY=PASS" \
  "TRACES_SIGNAL_CONTRACT=PASS" \
  "TRACES_PUBLIC_SURFACE_POLICY=PASS" \
  "TRACES_BODY_NOT_PRINTED=PASS" \
  "TRACES_NO_RESTART=PASS" \
  "TRACES_NO_CONFIG_CHANGE=PASS" \
  "TRACES_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "TEMPO_CONFIG_CHANGED=NO" \
  "TEMPO_RELOAD_EXECUTED=NO" \
  "TEMPO_RESTARTED=NO" \
  "OTEL_CONFIG_CHANGED=NO" \
  "OTEL_RELOAD_EXECUTED=NO" \
  "OTEL_RESTARTED=NO" \
  "GRAFANA_DASHBOARD_CHANGED=NO" \
  "ALERT_RULE_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "TRACE_BODY_PRINTED=NO" \
  "TEMPO_QUERY_BODY_PRINTED=NO" \
  "OTEL_PAYLOAD_PRINTED=NO" \
  "SPAN_ATTRIBUTE_PRINTED=NO" \
  "METRIC_BODY_PRINTED=NO" \
  "LOG_CONTENT_PRINTED=NO" \
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

for f in "$MATRIX" "$PROBES" "$PIPELINE" "$CONTRACT" "$PUBLIC_POLICY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_22_3 \
  tempo_endpoint_probe \
  tempo_ready_metadata \
  otel_reachability \
  trace_pipeline_inventory \
  trace_signal_contract \
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
  "probe_name" \
  "probe_type" \
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
  "tempo_marker_count" \
  "otel_marker_count" \
  "trace_id_marker_count" \
  "redaction_marker_count"
do
  grep -q "$header" "$PIPELINE" || {
    echo "TEST_FAIL ❌ pipeline inventory header eksik: $header"
    cat "$PIPELINE" || true
    exit 1
  }
done

for header in \
  "field_name" \
  "requirement" \
  "category" \
  "readiness_status"
do
  grep -q "$header" "$CONTRACT" || {
    echo "TEST_FAIL ❌ trace signal contract header eksik: $header"
    cat "$CONTRACT" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$PROBES" "$PIPELINE" "$CONTRACT" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$PROBES" "$PIPELINE" "$CONTRACT" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$PROBES" "$PIPELINE" "$CONTRACT" "$PUBLIC_POLICY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_TRACES_TEMPO_READINESS_TEST=PASS ✅"
echo "PHASE4B_TRACES_ENDPOINT_PROBE_TEST=PASS ✅"
echo "PHASE4B_TRACES_PIPELINE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_TRACES_SIGNAL_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_TRACES_PUBLIC_SURFACE_POLICY_TEST=PASS ✅"
echo "PHASE4B_TRACES_NO_RESTART_TEST=PASS ✅"
echo "PHASE4B_TRACES_SECRET_TEST=PASS ✅"
