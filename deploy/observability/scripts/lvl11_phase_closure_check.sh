#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY_ENV_FILE="${OBS_DIR}/generated/lvl11_phase_closure_summary.env"
REPORT_FILE="${OBS_DIR}/generated/lvl11_phase_closure_report.md"

REQUIRED_FILES=(
  "${OBS_DIR}/generated/lvl11_threshold_rules.yaml"
  "${OBS_DIR}/generated/lvl11_threshold_summary.md"
  "${OBS_DIR}/generated/lvl11_scale_trigger_matrix.yaml"
  "${OBS_DIR}/generated/lvl11_correlation_summary.md"
  "${OBS_DIR}/generated/lvl11_validation_matrix.yaml"
  "${OBS_DIR}/generated/lvl11_delivery_summary.md"
)

echo "===== LVL11 PHASE CLOSURE CHECK BASLIYOR ====="

SIGNAL_THRESHOLD_READY=true
CORRELATION_SCALE_READY=true
DELIVERY_VALIDATION_READY=true

for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "${f}" ]; then
    echo "HATA ❌ eksik dosya: ${f}"
    case "${f}" in
      *threshold*) SIGNAL_THRESHOLD_READY=false ;;
      *scale_trigger*|*correlation*) CORRELATION_SCALE_READY=false ;;
      *validation*|*delivery*) DELIVERY_VALIDATION_READY=false ;;
    esac
  else
    echo "OK ✅ dosya var: ${f}"
  fi
done

PHASE_STATUS="READY"

if [ "${SIGNAL_THRESHOLD_READY}" != "true" ] || \
   [ "${CORRELATION_SCALE_READY}" != "true" ] || \
   [ "${DELIVERY_VALIDATION_READY}" != "true" ]; then
  PHASE_STATUS="BLOCKED"
fi

cat <<SUMMARY > "${SUMMARY_ENV_FILE}"
SIGNAL_THRESHOLD_READY=${SIGNAL_THRESHOLD_READY}
CORRELATION_SCALE_READY=${CORRELATION_SCALE_READY}
DELIVERY_VALIDATION_READY=${DELIVERY_VALIDATION_READY}
PHASE_STATUS=${PHASE_STATUS}
SUMMARY

cat <<REPORT > "${REPORT_FILE}"
# LVL11 Phase Closure Report

- SIGNAL_THRESHOLD_READY=${SIGNAL_THRESHOLD_READY}
- CORRELATION_SCALE_READY=${CORRELATION_SCALE_READY}
- DELIVERY_VALIDATION_READY=${DELIVERY_VALIDATION_READY}
- PHASE_STATUS=${PHASE_STATUS}

## 11.7 Checklist
- 11.7.1 darboğazlar görünür => ${SIGNAL_THRESHOLD_READY}
- 11.7.2 level-up alarmı var => ${CORRELATION_SCALE_READY}
- 11.7.3 scale trigger’lar görünür => ${CORRELATION_SCALE_READY}
- 11.7.4 alarm gürültüsü kontrol altında => ${DELIVERY_VALIDATION_READY}
- 11.7.5 aksiyona dönük ops yüzeyi var => ${DELIVERY_VALIDATION_READY}
REPORT

if [ "${PHASE_STATUS}" != "READY" ]; then
  echo "HATA ❌ LVL11 phase closure blocked"
  echo "HATA ❌ rapor: ${REPORT_FILE}"
  exit 1
fi

echo "OK ✅ lvl11 phase closure ready"
echo "OK ✅ summary: ${SUMMARY_ENV_FILE}"
echo "OK ✅ rapor: ${REPORT_FILE}"
