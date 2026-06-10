#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${OBS_DIR}/env/lvl11_early_warning.env.example}"
TEMPLATE_FILE="${OBS_DIR}/config/lvl11_threshold_rules.yaml.template"
OUTPUT_FILE="${OBS_DIR}/generated/lvl11_threshold_rules.yaml"
SUMMARY_FILE="${OBS_DIR}/generated/lvl11_threshold_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
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
  CPU_WARN_PERCENT
  CPU_CRIT_PERCENT
  MEM_WARN_PERCENT
  MEM_CRIT_PERCENT
  IO_WARN_PERCENT
  IO_CRIT_PERCENT
  LATENCY_WARN_MS
  LATENCY_CRIT_MS
  ERROR_RATE_WARN_PERCENT
  ERROR_RATE_CRIT_PERCENT
  QUEUE_WARN_COUNT
  QUEUE_CRIT_COUNT
  STORAGE_WARN_PERCENT
  STORAGE_CRIT_PERCENT
  CONNECTION_WARN_PERCENT
  CONNECTION_CRIT_PERCENT
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__CPU_WARN_PERCENT__|${CPU_WARN_PERCENT}|g" \
  -e "s|__CPU_CRIT_PERCENT__|${CPU_CRIT_PERCENT}|g" \
  -e "s|__MEM_WARN_PERCENT__|${MEM_WARN_PERCENT}|g" \
  -e "s|__MEM_CRIT_PERCENT__|${MEM_CRIT_PERCENT}|g" \
  -e "s|__IO_WARN_PERCENT__|${IO_WARN_PERCENT}|g" \
  -e "s|__IO_CRIT_PERCENT__|${IO_CRIT_PERCENT}|g" \
  -e "s|__LATENCY_WARN_MS__|${LATENCY_WARN_MS}|g" \
  -e "s|__LATENCY_CRIT_MS__|${LATENCY_CRIT_MS}|g" \
  -e "s|__ERROR_RATE_WARN_PERCENT__|${ERROR_RATE_WARN_PERCENT}|g" \
  -e "s|__ERROR_RATE_CRIT_PERCENT__|${ERROR_RATE_CRIT_PERCENT}|g" \
  -e "s|__QUEUE_WARN_COUNT__|${QUEUE_WARN_COUNT}|g" \
  -e "s|__QUEUE_CRIT_COUNT__|${QUEUE_CRIT_COUNT}|g" \
  -e "s|__STORAGE_WARN_PERCENT__|${STORAGE_WARN_PERCENT}|g" \
  -e "s|__STORAGE_CRIT_PERCENT__|${STORAGE_CRIT_PERCENT}|g" \
  -e "s|__CONNECTION_WARN_PERCENT__|${CONNECTION_WARN_PERCENT}|g" \
  -e "s|__CONNECTION_CRIT_PERCENT__|${CONNECTION_CRIT_PERCENT}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<SUMMARY > "${SUMMARY_FILE}"
# LVL11 Threshold Summary

- CPU: warn=${CPU_WARN_PERCENT} crit=${CPU_CRIT_PERCENT}
- MEM: warn=${MEM_WARN_PERCENT} crit=${MEM_CRIT_PERCENT}
- IO: warn=${IO_WARN_PERCENT} crit=${IO_CRIT_PERCENT}
- LATENCY: warn=${LATENCY_WARN_MS}ms crit=${LATENCY_CRIT_MS}ms
- ERROR RATE: warn=${ERROR_RATE_WARN_PERCENT}% crit=${ERROR_RATE_CRIT_PERCENT}%
- QUEUE: warn=${QUEUE_WARN_COUNT} crit=${QUEUE_CRIT_COUNT}
- STORAGE: warn=${STORAGE_WARN_PERCENT}% crit=${STORAGE_CRIT_PERCENT}%
- CONNECTION: warn=${CONNECTION_WARN_PERCENT}% crit=${CONNECTION_CRIT_PERCENT}%
SUMMARY

echo "OK ✅ generated threshold rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated threshold summary hazir: ${SUMMARY_FILE}"
