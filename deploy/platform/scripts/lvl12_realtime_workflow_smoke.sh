#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PLATFORM_DIR}/env/lvl12_realtime_workflow.env.example"
REALTIME_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_realtime_catalog.yaml"
WORKFLOW_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_workflow_catalog.yaml"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_realtime_workflow_rules.yaml"
REALTIME_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_realtime_summary.md"
WORKFLOW_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_workflow_summary.md"
RENDER_SCRIPT="${PLATFORM_DIR}/scripts/render_lvl12_realtime_workflow.sh"

echo "===== LVL12 REALTIME + WORKFLOW SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'core:' "${REALTIME_CATALOG_FILE}"
echo "OK ✅ realtime core var"

grep -q 'websocket:' "${REALTIME_CATALOG_FILE}"
echo "OK ✅ websocket var"

grep -q 'sse:' "${REALTIME_CATALOG_FILE}"
echo "OK ✅ sse var"

grep -q 'tenant_safe_channels:' "${REALTIME_CATALOG_FILE}"
echo "OK ✅ tenant-safe channel ayrimi var"

grep -q 'connection_policy:' "${REALTIME_CATALOG_FILE}"
echo "OK ✅ realtime connection policy var"

grep -q 'engine:' "${WORKFLOW_CATALOG_FILE}"
echo "OK ✅ workflow engine var"

grep -q 'definition_model:' "${WORKFLOW_CATALOG_FILE}"
echo "OK ✅ workflow tanim modeli var"

grep -q 'manual_approval:' "${WORKFLOW_CATALOG_FILE}"
echo "OK ✅ manual step / approval var"

grep -q 'retry_compensation:' "${WORKFLOW_CATALOG_FILE}"
echo "OK ✅ retry / compensation var"

grep -q 'observability:' "${WORKFLOW_CATALOG_FILE}"
echo "OK ✅ workflow observability var"

grep -q 'realtime_rules:' "${OUTPUT_FILE}"
echo "OK ✅ realtime rules render edildi"

grep -q 'workflow_rules:' "${OUTPUT_FILE}"
echo "OK ✅ workflow rules render edildi"

grep -q 'LVL12 Realtime Summary' "${REALTIME_SUMMARY_FILE}"
echo "OK ✅ realtime summary olustu"

grep -q 'LVL12 Workflow Summary' "${WORKFLOW_SUMMARY_FILE}"
echo "OK ✅ workflow summary olustu"

echo "===== LVL12 REALTIME + WORKFLOW SMOKE TAMAM ====="
