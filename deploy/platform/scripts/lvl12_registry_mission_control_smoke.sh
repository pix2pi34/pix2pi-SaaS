#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PLATFORM_DIR}/env/lvl12_registry_mission_control.env.example"
REGISTRY_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_service_registry_catalog.yaml"
MISSION_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_mission_control_catalog.yaml"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_registry_rules.yaml"
REGISTRY_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_registry_summary.md"
MISSION_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_mission_control_summary.md"
RENDER_SCRIPT="${PLATFORM_DIR}/scripts/render_lvl12_registry_mission_control.sh"

echo "===== LVL12 REGISTRY + MISSION CONTROL SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'registration_standard:' "${REGISTRY_CATALOG_FILE}"
echo "OK ✅ service kayit standardi var"

grep -q 'health_sync:' "${REGISTRY_CATALOG_FILE}"
echo "OK ✅ health sync var"

grep -q 'instance_metadata:' "${REGISTRY_CATALOG_FILE}"
echo "OK ✅ instance metadata var"

grep -q 'stale_instance_cleanup:' "${REGISTRY_CATALOG_FILE}"
echo "OK ✅ stale instance cleanup var"

grep -q 'tenant_visibility:' "${REGISTRY_CATALOG_FILE}"
echo "OK ✅ tenant-aware visibility var"

grep -q 'service_status_view:' "${MISSION_CATALOG_FILE}"
echo "OK ✅ servis durum gorunumu var"

grep -q 'manual_actions:' "${MISSION_CATALOG_FILE}"
echo "OK ✅ manuel kontrol aksiyonlari var"

grep -q 'maintenance_mode:' "${MISSION_CATALOG_FILE}"
echo "OK ✅ bakim modu var"

grep -q 'incident_notes:' "${MISSION_CATALOG_FILE}"
echo "OK ✅ incident notlari var"

grep -q 'health_ttl_seconds:' "${OUTPUT_FILE}"
echo "OK ✅ registry rule render edildi"

grep -q 'allow_restart:' "${OUTPUT_FILE}"
echo "OK ✅ mission control rule render edildi"

grep -q 'LVL12 Registry Summary' "${REGISTRY_SUMMARY_FILE}"
echo "OK ✅ registry summary olustu"

grep -q 'LVL12 Mission Control Summary' "${MISSION_SUMMARY_FILE}"
echo "OK ✅ mission control summary olustu"

echo "===== LVL12 REGISTRY + MISSION CONTROL SMOKE TAMAM ====="
