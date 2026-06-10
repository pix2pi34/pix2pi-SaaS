#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PLATFORM_DIR}/env/lvl12_plugin_public_api.env.example"
PLUGIN_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_plugin_catalog.yaml"
API_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_public_api_catalog.yaml"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_plugin_public_api_rules.yaml"
PLUGIN_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_plugin_summary.md"
API_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_public_api_summary.md"
RENDER_SCRIPT="${PLATFORM_DIR}/scripts/render_lvl12_plugin_public_api.sh"

echo "===== LVL12 PLUGIN + PUBLIC API SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'contract:' "${PLUGIN_CATALOG_FILE}"
echo "OK ✅ plugin contract var"

grep -q 'lifecycle:' "${PLUGIN_CATALOG_FILE}"
echo "OK ✅ plugin lifecycle var"

grep -q 'permission_boundary:' "${PLUGIN_CATALOG_FILE}"
echo "OK ✅ permission boundary var"

grep -q 'tenant_safe_runtime:' "${PLUGIN_CATALOG_FILE}"
echo "OK ✅ tenant-safe plugin calismasi var"

grep -q 'version_compatibility:' "${PLUGIN_CATALOG_FILE}"
echo "OK ✅ version compatibility var"

grep -q 'gateway_contract:' "${API_CATALOG_FILE}"
echo "OK ✅ public API gateway contract var"

grep -q 'api_key_auth:' "${API_CATALOG_FILE}"
echo "OK ✅ API key / app auth var"

grep -q 'rate_limit_quota:' "${API_CATALOG_FILE}"
echo "OK ✅ rate limit / quota var"

grep -q 'developer_docs:' "${API_CATALOG_FILE}"
echo "OK ✅ developer docs var"

grep -q 'sandbox_mode:' "${API_CATALOG_FILE}"
echo "OK ✅ sandbox mode var"

grep -q 'plugin_rules:' "${OUTPUT_FILE}"
echo "OK ✅ plugin rules render edildi"

grep -q 'public_api_rules:' "${OUTPUT_FILE}"
echo "OK ✅ public API rules render edildi"

grep -q 'LVL12 Plugin Summary' "${PLUGIN_SUMMARY_FILE}"
echo "OK ✅ plugin summary olustu"

grep -q 'LVL12 Public API Summary' "${API_SUMMARY_FILE}"
echo "OK ✅ public API summary olustu"

echo "===== LVL12 PLUGIN + PUBLIC API SMOKE TAMAM ====="
