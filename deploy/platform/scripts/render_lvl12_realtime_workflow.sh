#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${PLATFORM_DIR}/env/lvl12_realtime_workflow.env.example}"
REALTIME_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_realtime_catalog.yaml"
WORKFLOW_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_workflow_catalog.yaml"
TEMPLATE_FILE="${PLATFORM_DIR}/config/lvl12_realtime_workflow_rules.yaml.template"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_realtime_workflow_rules.yaml"
REALTIME_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_realtime_summary.md"
WORKFLOW_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_workflow_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${REALTIME_CATALOG_FILE}" ]; then
  echo "HATA ❌ realtime catalog yok: ${REALTIME_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${WORKFLOW_CATALOG_FILE}" ]; then
  echo "HATA ❌ workflow catalog yok: ${WORKFLOW_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${TEMPLATE_FILE}" ]; then
  echo "HATA ❌ template dosyasi yok: ${TEMPLATE_FILE}"
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

REQUIRED_VARS=(
  REALTIME_CORE_ENABLED
  REALTIME_WEBSOCKET_ENABLED
  REALTIME_SSE_ENABLED
  REALTIME_CHANNEL_MODE
  REALTIME_HEARTBEAT_SECONDS
  REALTIME_MAX_CONNECTIONS_PER_TENANT
  REALTIME_DEFAULT_TOPIC
  WORKFLOW_ENGINE_ENABLED
  WORKFLOW_DEFAULT_TIMEOUT_SECONDS
  WORKFLOW_RETRY_MAX
  WORKFLOW_COMPENSATION_ENABLED
  WORKFLOW_APPROVAL_ENABLED
  WORKFLOW_OBSERVABILITY_ENABLED
  WORKFLOW_DEFAULT_QUEUE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__REALTIME_CORE_ENABLED__|${REALTIME_CORE_ENABLED}|g" \
  -e "s|__REALTIME_WEBSOCKET_ENABLED__|${REALTIME_WEBSOCKET_ENABLED}|g" \
  -e "s|__REALTIME_SSE_ENABLED__|${REALTIME_SSE_ENABLED}|g" \
  -e "s|__REALTIME_CHANNEL_MODE__|${REALTIME_CHANNEL_MODE}|g" \
  -e "s|__REALTIME_HEARTBEAT_SECONDS__|${REALTIME_HEARTBEAT_SECONDS}|g" \
  -e "s|__REALTIME_MAX_CONNECTIONS_PER_TENANT__|${REALTIME_MAX_CONNECTIONS_PER_TENANT}|g" \
  -e "s|__REALTIME_DEFAULT_TOPIC__|${REALTIME_DEFAULT_TOPIC}|g" \
  -e "s|__WORKFLOW_ENGINE_ENABLED__|${WORKFLOW_ENGINE_ENABLED}|g" \
  -e "s|__WORKFLOW_DEFAULT_TIMEOUT_SECONDS__|${WORKFLOW_DEFAULT_TIMEOUT_SECONDS}|g" \
  -e "s|__WORKFLOW_RETRY_MAX__|${WORKFLOW_RETRY_MAX}|g" \
  -e "s|__WORKFLOW_COMPENSATION_ENABLED__|${WORKFLOW_COMPENSATION_ENABLED}|g" \
  -e "s|__WORKFLOW_APPROVAL_ENABLED__|${WORKFLOW_APPROVAL_ENABLED}|g" \
  -e "s|__WORKFLOW_OBSERVABILITY_ENABLED__|${WORKFLOW_OBSERVABILITY_ENABLED}|g" \
  -e "s|__WORKFLOW_DEFAULT_QUEUE__|${WORKFLOW_DEFAULT_QUEUE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<REALTIMESUMMARY > "${REALTIME_SUMMARY_FILE}"
# LVL12 Realtime Summary

- Core enabled: ${REALTIME_CORE_ENABLED}
- WebSocket enabled: ${REALTIME_WEBSOCKET_ENABLED}
- SSE enabled: ${REALTIME_SSE_ENABLED}
- Channel mode: ${REALTIME_CHANNEL_MODE}
- Heartbeat: ${REALTIME_HEARTBEAT_SECONDS} sec
- Max connections per tenant: ${REALTIME_MAX_CONNECTIONS_PER_TENANT}
- Default topic: ${REALTIME_DEFAULT_TOPIC}
REALTIMESUMMARY

cat <<WORKFLOWSUMMARY > "${WORKFLOW_SUMMARY_FILE}"
# LVL12 Workflow Summary

- Engine enabled: ${WORKFLOW_ENGINE_ENABLED}
- Default timeout: ${WORKFLOW_DEFAULT_TIMEOUT_SECONDS} sec
- Retry max: ${WORKFLOW_RETRY_MAX}
- Compensation enabled: ${WORKFLOW_COMPENSATION_ENABLED}
- Approval enabled: ${WORKFLOW_APPROVAL_ENABLED}
- Observability enabled: ${WORKFLOW_OBSERVABILITY_ENABLED}
- Default queue: ${WORKFLOW_DEFAULT_QUEUE}
WORKFLOWSUMMARY

echo "OK ✅ generated realtime/workflow rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated realtime summary hazir: ${REALTIME_SUMMARY_FILE}"
echo "OK ✅ generated workflow summary hazir: ${WORKFLOW_SUMMARY_FILE}"
