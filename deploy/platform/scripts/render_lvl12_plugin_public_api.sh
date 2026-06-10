#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${PLATFORM_DIR}/env/lvl12_plugin_public_api.env.example}"
PLUGIN_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_plugin_catalog.yaml"
API_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_public_api_catalog.yaml"
TEMPLATE_FILE="${PLATFORM_DIR}/config/lvl12_plugin_public_api_rules.yaml.template"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_plugin_public_api_rules.yaml"
PLUGIN_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_plugin_summary.md"
API_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_public_api_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${PLUGIN_CATALOG_FILE}" ]; then
  echo "HATA ❌ plugin catalog yok: ${PLUGIN_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${API_CATALOG_FILE}" ]; then
  echo "HATA ❌ public api catalog yok: ${API_CATALOG_FILE}"
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
  PLUGIN_RUNTIME
  PLUGIN_CONTRACT_VERSION
  PLUGIN_DEFAULT_STATE
  PLUGIN_TENANT_MODE
  PLUGIN_PERMISSION_MODE
  PLUGIN_MIN_COMPATIBLE_CORE
  PUBLIC_API_GATEWAY_MODE
  PUBLIC_API_AUTH_MODE
  PUBLIC_API_RATE_LIMIT_PER_MINUTE
  PUBLIC_API_QUOTA_PER_DAY
  PUBLIC_API_SANDBOX_MODE
  PUBLIC_API_DOCS_MODE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__PLUGIN_RUNTIME__|${PLUGIN_RUNTIME}|g" \
  -e "s|__PLUGIN_CONTRACT_VERSION__|${PLUGIN_CONTRACT_VERSION}|g" \
  -e "s|__PLUGIN_DEFAULT_STATE__|${PLUGIN_DEFAULT_STATE}|g" \
  -e "s|__PLUGIN_TENANT_MODE__|${PLUGIN_TENANT_MODE}|g" \
  -e "s|__PLUGIN_PERMISSION_MODE__|${PLUGIN_PERMISSION_MODE}|g" \
  -e "s|__PLUGIN_MIN_COMPATIBLE_CORE__|${PLUGIN_MIN_COMPATIBLE_CORE}|g" \
  -e "s|__PUBLIC_API_GATEWAY_MODE__|${PUBLIC_API_GATEWAY_MODE}|g" \
  -e "s|__PUBLIC_API_AUTH_MODE__|${PUBLIC_API_AUTH_MODE}|g" \
  -e "s|__PUBLIC_API_RATE_LIMIT_PER_MINUTE__|${PUBLIC_API_RATE_LIMIT_PER_MINUTE}|g" \
  -e "s|__PUBLIC_API_QUOTA_PER_DAY__|${PUBLIC_API_QUOTA_PER_DAY}|g" \
  -e "s|__PUBLIC_API_SANDBOX_MODE__|${PUBLIC_API_SANDBOX_MODE}|g" \
  -e "s|__PUBLIC_API_DOCS_MODE__|${PUBLIC_API_DOCS_MODE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<PLUGINSUMMARY > "${PLUGIN_SUMMARY_FILE}"
# LVL12 Plugin Summary

- Runtime: ${PLUGIN_RUNTIME}
- Contract version: ${PLUGIN_CONTRACT_VERSION}
- Default state: ${PLUGIN_DEFAULT_STATE}
- Tenant mode: ${PLUGIN_TENANT_MODE}
- Permission mode: ${PLUGIN_PERMISSION_MODE}
- Min compatible core: ${PLUGIN_MIN_COMPATIBLE_CORE}
PLUGINSUMMARY

cat <<APISUMMARY > "${API_SUMMARY_FILE}"
# LVL12 Public API Summary

- Gateway mode: ${PUBLIC_API_GATEWAY_MODE}
- Auth mode: ${PUBLIC_API_AUTH_MODE}
- Rate limit per minute: ${PUBLIC_API_RATE_LIMIT_PER_MINUTE}
- Quota per day: ${PUBLIC_API_QUOTA_PER_DAY}
- Sandbox mode: ${PUBLIC_API_SANDBOX_MODE}
- Docs mode: ${PUBLIC_API_DOCS_MODE}
APISUMMARY

echo "OK ✅ generated plugin/public api rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated plugin summary hazir: ${PLUGIN_SUMMARY_FILE}"
echo "OK ✅ generated public api summary hazir: ${API_SUMMARY_FILE}"
