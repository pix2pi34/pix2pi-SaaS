#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_realtime_channel_contract.sh"
PY_SCRIPT="scripts/phase4b_realtime_channel_contract.py"
REPORT="docs/phase4/17_4_realtime_channel_contract_report.md"
MATRIX="docs/phase4/17_4_realtime_channel_contract_matrix.tsv"
CHANNELS="docs/phase4/17_4_realtime_channel_catalog.tsv"
PAYLOAD="docs/phase4/17_4_realtime_payload_envelope.tsv"
DELIVERY="docs/phase4/17_4_realtime_delivery_policy.tsv"
RBAC="docs/phase4/17_4_realtime_rbac_tenant_matrix.tsv"
RECONNECT="docs/phase4/17_4_realtime_reconnect_heartbeat_policy.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ realtime channel contract wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ realtime channel contract python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_17_4_realtime_channel_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ realtime channel contract script hata verdi"
  cat /tmp/pix2pi_17_4_realtime_channel_contract.log || true
  sed -n '1,3200p' "$REPORT" || true
  exit 1
}

for required in \
  "REALTIME_CHANNEL_CONTRACT=PASS" \
  "FAZ4B_17_4_FINAL_STATUS=PASS" \
  "REALTIME_PREVIOUS_17_3=PASS" \
  "REALTIME_CHANNEL_CATALOG=PASS" \
  "REALTIME_PAYLOAD_ENVELOPE=PASS" \
  "REALTIME_DELIVERY_POLICY=PASS" \
  "REALTIME_RBAC_TENANT_MATRIX=PASS" \
  "REALTIME_RECONNECT_HEARTBEAT_POLICY=PASS" \
  "REALTIME_NO_RUNTIME_CHANGE=PASS" \
  "REALTIME_NO_CONFIG_CHANGE=PASS" \
  "REALTIME_SECRET_SAFE=PASS" \
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
  "REALTIME_RUNTIME_CHANGED=NO" \
  "REALTIME_SERVER_STARTED=NO" \
  "WORKFLOW_RUNTIME_CHANGED=NO" \
  "APPROVAL_RUNTIME_CHANGED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "NOTIFICATION_SENT=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "RAW_PAYLOAD_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO" \
  "TOKEN_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,3200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$CHANNELS" "$PAYLOAD" "$DELIVERY" "$RBAC" "$RECONNECT"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_17_3 \
  channel_catalog \
  payload_envelope \
  delivery_policy \
  rbac_tenant_matrix \
  reconnect_heartbeat_policy \
  transport_coverage \
  metadata_only_payload \
  auth_audit_coverage \
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

for channel in \
  "tenant.workflow.events" \
  "tenant.approval.events" \
  "tenant.task.events" \
  "tenant.notification.events" \
  "tenant.audit.events" \
  "ops.workflow.events" \
  "ops.workflow.backlog" \
  "ops.workflow.dlq" \
  "security.workflow.events" \
  "security.tenant_isolation.events" \
  "platform.realtime.health"
do
  grep -q "$channel" "$CHANNELS" || {
    echo "TEST_FAIL ❌ realtime channel eksik: $channel"
    cat "$CHANNELS" || true
    exit 1
  }
done

for field in \
  event_id \
  event_type \
  channel \
  tenant_id \
  request_id \
  trace_id \
  severity \
  status \
  summary \
  metadata \
  occurred_at
do
  grep -q "$field" "$PAYLOAD" || {
    echo "TEST_FAIL ❌ payload envelope field eksik: $field"
    cat "$PAYLOAD" || true
    exit 1
  }
done

for transport in \
  SSE \
  WebSocket
do
  grep -q "$transport" "$RECONNECT" || {
    echo "TEST_FAIL ❌ reconnect transport eksik: $transport"
    cat "$RECONNECT" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$CHANNELS" "$PAYLOAD" "$DELIVERY" "$RBAC" "$RECONNECT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$CHANNELS" "$PAYLOAD" "$DELIVERY" "$RBAC" "$RECONNECT"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$CHANNELS" "$PAYLOAD" "$DELIVERY" "$RBAC" "$RECONNECT"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_REALTIME_CHANNEL_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_REALTIME_CHANNEL_CATALOG_TEST=PASS ✅"
echo "PHASE4B_REALTIME_PAYLOAD_ENVELOPE_TEST=PASS ✅"
echo "PHASE4B_REALTIME_DELIVERY_POLICY_TEST=PASS ✅"
echo "PHASE4B_REALTIME_RBAC_TENANT_MATRIX_TEST=PASS ✅"
echo "PHASE4B_REALTIME_RECONNECT_HEARTBEAT_POLICY_TEST=PASS ✅"
echo "PHASE4B_REALTIME_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_REALTIME_SECRET_TEST=PASS ✅"
