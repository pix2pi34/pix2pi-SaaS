#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${PLATFORM_DIR}/env/lvl12_registry_mission_control.env.example}"
REGISTRY_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_service_registry_catalog.yaml"
MISSION_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_mission_control_catalog.yaml"
TEMPLATE_FILE="${PLATFORM_DIR}/config/lvl12_registry_rules.yaml.template"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_registry_rules.yaml"
REGISTRY_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_registry_summary.md"
MISSION_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_mission_control_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${REGISTRY_CATALOG_FILE}" ]; then
  echo "HATA ❌ registry catalog yok: ${REGISTRY_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${MISSION_CATALOG_FILE}" ]; then
  echo "HATA ❌ mission control catalog yok: ${MISSION_CATALOG_FILE}"
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
  REGISTRY_HEALTH_TTL_SECONDS
  REGISTRY_STALE_AFTER_SECONDS
  REGISTRY_MAX_INSTANCES_PER_SERVICE
  REGISTRY_TENANT_VISIBILITY_MODE
  MISSION_CONTROL_ALLOW_RESTART
  MISSION_CONTROL_ALLOW_ISOLATE
  MISSION_CONTROL_ALLOW_MAINTENANCE
  MISSION_CONTROL_INCIDENT_NOTES
  MISSION_CONTROL_DEFAULT_VIEW
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__REGISTRY_HEALTH_TTL_SECONDS__|${REGISTRY_HEALTH_TTL_SECONDS}|g" \
  -e "s|__REGISTRY_STALE_AFTER_SECONDS__|${REGISTRY_STALE_AFTER_SECONDS}|g" \
  -e "s|__REGISTRY_MAX_INSTANCES_PER_SERVICE__|${REGISTRY_MAX_INSTANCES_PER_SERVICE}|g" \
  -e "s|__REGISTRY_TENANT_VISIBILITY_MODE__|${REGISTRY_TENANT_VISIBILITY_MODE}|g" \
  -e "s|__MISSION_CONTROL_ALLOW_RESTART__|${MISSION_CONTROL_ALLOW_RESTART}|g" \
  -e "s|__MISSION_CONTROL_ALLOW_ISOLATE__|${MISSION_CONTROL_ALLOW_ISOLATE}|g" \
  -e "s|__MISSION_CONTROL_ALLOW_MAINTENANCE__|${MISSION_CONTROL_ALLOW_MAINTENANCE}|g" \
  -e "s|__MISSION_CONTROL_INCIDENT_NOTES__|${MISSION_CONTROL_INCIDENT_NOTES}|g" \
  -e "s|__MISSION_CONTROL_DEFAULT_VIEW__|${MISSION_CONTROL_DEFAULT_VIEW}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<REGSUMMARY > "${REGISTRY_SUMMARY_FILE}"
# LVL12 Registry Summary

- Health TTL: ${REGISTRY_HEALTH_TTL_SECONDS} sec
- Stale after: ${REGISTRY_STALE_AFTER_SECONDS} sec
- Max instances per service: ${REGISTRY_MAX_INSTANCES_PER_SERVICE}
- Tenant visibility mode: ${REGISTRY_TENANT_VISIBILITY_MODE}
REGSUMMARY

cat <<MISSIONSUMMARY > "${MISSION_SUMMARY_FILE}"
# LVL12 Mission Control Summary

- Allow restart: ${MISSION_CONTROL_ALLOW_RESTART}
- Allow isolate: ${MISSION_CONTROL_ALLOW_ISOLATE}
- Allow maintenance: ${MISSION_CONTROL_ALLOW_MAINTENANCE}
- Incident notes: ${MISSION_CONTROL_INCIDENT_NOTES}
- Default view: ${MISSION_CONTROL_DEFAULT_VIEW}
MISSIONSUMMARY

echo "OK ✅ generated registry rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated registry summary hazir: ${REGISTRY_SUMMARY_FILE}"
echo "OK ✅ generated mission control summary hazir: ${MISSION_SUMMARY_FILE}"
