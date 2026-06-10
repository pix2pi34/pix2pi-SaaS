#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_workflow_realtime_baseline.sh"
PY_SCRIPT="scripts/phase4b_workflow_realtime_baseline.py"
REPORT="docs/phase4/17_1_workflow_realtime_baseline_report.md"
MATRIX="docs/phase4/17_1_workflow_realtime_baseline_matrix.tsv"
DOMAINS="docs/phase4/17_1_workflow_domain_inventory.tsv"
REALTIME="docs/phase4/17_1_realtime_signal_contract.tsv"
UI="docs/phase4/17_1_ui_surface_contract.tsv"
API="docs/phase4/17_1_api_surface_candidate_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow realtime baseline wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow realtime baseline python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_17_1_workflow_realtime_baseline.log 2>&1 || {
  echo "TEST_FAIL ❌ workflow realtime baseline script hata verdi"
  cat /tmp/pix2pi_17_1_workflow_realtime_baseline.log || true
  sed -n '1,2600p' "$REPORT" || true
  exit 1
}

for required in \
  "WORKFLOW_REALTIME_BASELINE=PASS" \
  "FAZ4B_17_1_FINAL_STATUS=PASS" \
  "WORKFLOW_PREVIOUS_22=PASS" \
  "WORKFLOW_DOMAIN_INVENTORY=PASS" \
  "WORKFLOW_REALTIME_SIGNAL_CONTRACT=PASS" \
  "WORKFLOW_UI_SURFACE_CONTRACT=PASS" \
  "WORKFLOW_API_SURFACE_CANDIDATES=PASS" \
  "WORKFLOW_NO_RUNTIME_CHANGE=PASS" \
  "WORKFLOW_NO_CONFIG_CHANGE=PASS" \
  "WORKFLOW_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "UI_CODE_CHANGED=NO" \
  "API_ROUTE_CREATED=NO" \
  "API_IMPLEMENTATION_CHANGED=NO" \
  "WEBSOCKET_SERVER_STARTED=NO" \
  "SSE_SERVER_STARTED=NO" \
  "WORKFLOW_RUNTIME_CHANGED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO" \
  "TOKEN_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$DOMAINS" "$REALTIME" "$UI" "$API"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_22 \
  workflow_domain_inventory \
  realtime_signal_contract \
  ui_surface_contract \
  api_surface_candidates \
  no_runtime_change \
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
  "domain_name" \
  "tenant_scope" \
  "security_policy" \
  "implementation_status"
do
  grep -q "$header" "$DOMAINS" || {
    echo "TEST_FAIL ❌ domain inventory header eksik: $header"
    cat "$DOMAINS" || true
    exit 1
  }
done

for header in \
  "signal_name" \
  "tenant_scope" \
  "payload_policy" \
  "visibility_scope"
do
  grep -q "$header" "$REALTIME" || {
    echo "TEST_FAIL ❌ realtime contract header eksik: $header"
    cat "$REALTIME" || true
    exit 1
  }
done

for header in \
  "page_name" \
  "widget_name" \
  "required_permission" \
  "audit_required"
do
  grep -q "$header" "$UI" || {
    echo "TEST_FAIL ❌ ui surface header eksik: $header"
    cat "$UI" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$DOMAINS" "$REALTIME" "$UI" "$API"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$DOMAINS" "$REALTIME" "$UI" "$API"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$DOMAINS" "$REALTIME" "$UI" "$API"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_WORKFLOW_REALTIME_BASELINE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_DOMAIN_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_REALTIME_SIGNAL_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_UI_SURFACE_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_API_SURFACE_CANDIDATES_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_SECRET_TEST=PASS ✅"
