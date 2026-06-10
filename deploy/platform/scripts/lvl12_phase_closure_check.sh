#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY_ENV_FILE="${PLATFORM_DIR}/generated/lvl12_phase_closure_summary.env"
REPORT_FILE="${PLATFORM_DIR}/generated/lvl12_phase_closure_report.md"

REQUIRED_FILES=(
  "${PLATFORM_DIR}/generated/lvl12_registry_rules.yaml"
  "${PLATFORM_DIR}/generated/lvl12_registry_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_mission_control_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_jobs_notifications_rules.yaml"
  "${PLATFORM_DIR}/generated/lvl12_jobs_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_notifications_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_realtime_workflow_rules.yaml"
  "${PLATFORM_DIR}/generated/lvl12_realtime_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_workflow_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_plugin_public_api_rules.yaml"
  "${PLATFORM_DIR}/generated/lvl12_plugin_summary.md"
  "${PLATFORM_DIR}/generated/lvl12_public_api_summary.md"
)

echo "===== LVL12 PHASE CLOSURE CHECK BASLIYOR ====="

REGISTRY_MISSION_READY=true
JOBS_NOTIFICATIONS_READY=true
REALTIME_WORKFLOW_READY=true
PLUGIN_PUBLIC_API_READY=true

for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "${f}" ]; then
    echo "HATA ❌ eksik dosya: ${f}"
    case "${f}" in
      *registry*|*mission_control*) REGISTRY_MISSION_READY=false ;;
      *jobs*|*notifications*) JOBS_NOTIFICATIONS_READY=false ;;
      *realtime*|*workflow*) REALTIME_WORKFLOW_READY=false ;;
      *plugin*|*public_api*) PLUGIN_PUBLIC_API_READY=false ;;
    esac
  else
    echo "OK ✅ dosya var: ${f}"
  fi
done

PHASE_STATUS="READY"

if [ "${REGISTRY_MISSION_READY}" != "true" ] || \
   [ "${JOBS_NOTIFICATIONS_READY}" != "true" ] || \
   [ "${REALTIME_WORKFLOW_READY}" != "true" ] || \
   [ "${PLUGIN_PUBLIC_API_READY}" != "true" ]; then
  PHASE_STATUS="BLOCKED"
fi

cat <<SUMMARY > "${SUMMARY_ENV_FILE}"
REGISTRY_MISSION_READY=${REGISTRY_MISSION_READY}
JOBS_NOTIFICATIONS_READY=${JOBS_NOTIFICATIONS_READY}
REALTIME_WORKFLOW_READY=${REALTIME_WORKFLOW_READY}
PLUGIN_PUBLIC_API_READY=${PLUGIN_PUBLIC_API_READY}
PHASE_STATUS=${PHASE_STATUS}
SUMMARY

cat <<REPORT > "${REPORT_FILE}"
# LVL12 Phase Closure Report

- REGISTRY_MISSION_READY=${REGISTRY_MISSION_READY}
- JOBS_NOTIFICATIONS_READY=${JOBS_NOTIFICATIONS_READY}
- REALTIME_WORKFLOW_READY=${REALTIME_WORKFLOW_READY}
- PLUGIN_PUBLIC_API_READY=${PLUGIN_PUBLIC_API_READY}
- PHASE_STATUS=${PHASE_STATUS}

## 12.x Checklist
- 12.1-12.2 service registry + mission control => ${REGISTRY_MISSION_READY}
- 12.3-12.4 background jobs + notifications => ${JOBS_NOTIFICATIONS_READY}
- 12.5-12.6 realtime + workflow => ${REALTIME_WORKFLOW_READY}
- 12.7-12.8 plugin + public api => ${PLUGIN_PUBLIC_API_READY}
REPORT

if [ "${PHASE_STATUS}" != "READY" ]; then
  echo "HATA ❌ LVL12 phase closure blocked"
  echo "HATA ❌ rapor: ${REPORT_FILE}"
  exit 1
fi

echo "OK ✅ lvl12 phase closure ready"
echo "OK ✅ summary: ${SUMMARY_ENV_FILE}"
echo "OK ✅ rapor: ${REPORT_FILE}"
