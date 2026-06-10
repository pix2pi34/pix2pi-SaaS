#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${OBS_DIR}/env/lvl11_delivery_validation.env.example}"
CATALOG_FILE="${OBS_DIR}/config/lvl11_delivery_catalog.yaml"
TEMPLATE_FILE="${OBS_DIR}/config/lvl11_validation_matrix.yaml.template"
OUTPUT_FILE="${OBS_DIR}/generated/lvl11_validation_matrix.yaml"
SUMMARY_FILE="${OBS_DIR}/generated/lvl11_delivery_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${CATALOG_FILE}" ]; then
  echo "HATA ❌ delivery catalog yok: ${CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${TEMPLATE_FILE}" ]; then
  echo "HATA ❌ validation template yok: ${TEMPLATE_FILE}"
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

REQUIRED_VARS=(
  GRAFANA_ALERT_ROUTE
  EMAIL_CHANNEL
  CHAT_CHANNEL
  SEVERITY_WARN_ROUTE
  SEVERITY_CRIT_ROUTE
  ACK_TIMEOUT_MINUTES
  SILENCE_WINDOW_MINUTES
  ESCALATION_LEVEL1_MINUTES
  ESCALATION_LEVEL2_MINUTES
  ESCALATION_LEVEL3_MINUTES
  THRESHOLD_SIMULATION_ENABLED
  FALSE_POSITIVE_MAX_PERCENT
  FALSE_NEGATIVE_MAX_PERCENT
  DRY_RUN_MODE
  CORRELATION_VALIDATION_REQUIRED
  EARLY_WARNING_SUITE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

python3 - <<PY
from pathlib import Path
catalog = Path("${CATALOG_FILE}")
text = catalog.read_text()
replacements = {
    "ops-grafana-route": "${GRAFANA_ALERT_ROUTE}",
    "ops@pix2pi.com.tr": "${EMAIL_CHANNEL}",
    "#pix2pi-alerts": "${CHAT_CHANNEL}",
    "warning-oncall": "${SEVERITY_WARN_ROUTE}",
    "critical-oncall": "${SEVERITY_CRIT_ROUTE}",
    "ack_timeout_minutes: 15": "ack_timeout_minutes: ${ACK_TIMEOUT_MINUTES}",
    "silence_window_minutes: 30": "silence_window_minutes: ${SILENCE_WINDOW_MINUTES}",
    "after_minutes: 10": "after_minutes: ${ESCALATION_LEVEL1_MINUTES}",
    "after_minutes: 20": "after_minutes: ${ESCALATION_LEVEL2_MINUTES}",
    "after_minutes: 30": "after_minutes: ${ESCALATION_LEVEL3_MINUTES}",
}
for old, new in replacements.items():
    text = text.replace(old, new, 1)
catalog.write_text(text)
PY

sed \
  -e "s|__THRESHOLD_SIMULATION_ENABLED__|${THRESHOLD_SIMULATION_ENABLED}|g" \
  -e "s|__FALSE_POSITIVE_MAX_PERCENT__|${FALSE_POSITIVE_MAX_PERCENT}|g" \
  -e "s|__FALSE_NEGATIVE_MAX_PERCENT__|${FALSE_NEGATIVE_MAX_PERCENT}|g" \
  -e "s|__DRY_RUN_MODE__|${DRY_RUN_MODE}|g" \
  -e "s|__CORRELATION_VALIDATION_REQUIRED__|${CORRELATION_VALIDATION_REQUIRED}|g" \
  -e "s|__EARLY_WARNING_SUITE__|${EARLY_WARNING_SUITE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<SUMMARY > "${SUMMARY_FILE}"
# LVL11 Delivery Summary

## Delivery
- Grafana route: ${GRAFANA_ALERT_ROUTE}
- Email channel: ${EMAIL_CHANNEL}
- Chat channel: ${CHAT_CHANNEL}

## Severity Routing
- Warn route: ${SEVERITY_WARN_ROUTE}
- Crit route: ${SEVERITY_CRIT_ROUTE}

## Ack / Silence
- Ack timeout: ${ACK_TIMEOUT_MINUTES} min
- Silence window: ${SILENCE_WINDOW_MINUTES} min

## Escalation
- Level 1: ${ESCALATION_LEVEL1_MINUTES} min
- Level 2: ${ESCALATION_LEVEL2_MINUTES} min
- Level 3: ${ESCALATION_LEVEL3_MINUTES} min

## Validation
- Threshold simulation: ${THRESHOLD_SIMULATION_ENABLED}
- False positive max: ${FALSE_POSITIVE_MAX_PERCENT}%
- False negative max: ${FALSE_NEGATIVE_MAX_PERCENT}%
- Dry run mode: ${DRY_RUN_MODE}
- Correlation validation: ${CORRELATION_VALIDATION_REQUIRED}
- Early warning suite: ${EARLY_WARNING_SUITE}
SUMMARY

echo "OK ✅ generated validation matrix hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated delivery summary hazir: ${SUMMARY_FILE}"
