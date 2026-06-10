#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${OBS_DIR}/env/lvl11_scale_trigger.env.example}"
CATALOG_FILE="${OBS_DIR}/config/lvl11_correlation_catalog.yaml"
TEMPLATE_FILE="${OBS_DIR}/config/lvl11_scale_trigger_matrix.yaml.template"
OUTPUT_FILE="${OBS_DIR}/generated/lvl11_scale_trigger_matrix.yaml"
SUMMARY_FILE="${OBS_DIR}/generated/lvl11_correlation_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${CATALOG_FILE}" ]; then
  echo "HATA ❌ correlation catalog yok: ${CATALOG_FILE}"
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
  DB_BOTTLENECK_WARN_MS
  DB_BOTTLENECK_CRIT_MS
  EVENT_BACKLOG_WARN_COUNT
  EVENT_BACKLOG_CRIT_COUNT
  REPORTING_IMPACT_WARN_MS
  REPORTING_IMPACT_CRIT_MS
  SINGLE_NODE_CPU_WARN_PERCENT
  SINGLE_NODE_CPU_CRIT_PERCENT
  DEPLOY_RISK_WARN_COUNT
  DEPLOY_RISK_CRIT_COUNT
  CLUSTER_TRANSITION_WARN_SCORE
  CLUSTER_TRANSITION_CRIT_SCORE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__DB_BOTTLENECK_WARN_MS__|${DB_BOTTLENECK_WARN_MS}|g" \
  -e "s|__DB_BOTTLENECK_CRIT_MS__|${DB_BOTTLENECK_CRIT_MS}|g" \
  -e "s|__EVENT_BACKLOG_WARN_COUNT__|${EVENT_BACKLOG_WARN_COUNT}|g" \
  -e "s|__EVENT_BACKLOG_CRIT_COUNT__|${EVENT_BACKLOG_CRIT_COUNT}|g" \
  -e "s|__REPORTING_IMPACT_WARN_MS__|${REPORTING_IMPACT_WARN_MS}|g" \
  -e "s|__REPORTING_IMPACT_CRIT_MS__|${REPORTING_IMPACT_CRIT_MS}|g" \
  -e "s|__SINGLE_NODE_CPU_WARN_PERCENT__|${SINGLE_NODE_CPU_WARN_PERCENT}|g" \
  -e "s|__SINGLE_NODE_CPU_CRIT_PERCENT__|${SINGLE_NODE_CPU_CRIT_PERCENT}|g" \
  -e "s|__DEPLOY_RISK_WARN_COUNT__|${DEPLOY_RISK_WARN_COUNT}|g" \
  -e "s|__DEPLOY_RISK_CRIT_COUNT__|${DEPLOY_RISK_CRIT_COUNT}|g" \
  -e "s|__CLUSTER_TRANSITION_WARN_SCORE__|${CLUSTER_TRANSITION_WARN_SCORE}|g" \
  -e "s|__CLUSTER_TRANSITION_CRIT_SCORE__|${CLUSTER_TRANSITION_CRIT_SCORE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<SUMMARY > "${SUMMARY_FILE}"
# LVL11 Correlation Summary

## Correlation
- service_to_service => trace_id/request_id/source_service/target_service
- request_chain => request_id/correlation_id/tenant_id/route
- incident_grouping => fingerprint_window
- noisy_alert_suppression => dedupe_and_cooldown
- root_cause_hints => db_bottleneck_hint,event_backlog_hint,reporting_impact_hint

## Scale Triggers
- DB bottleneck: warn=${DB_BOTTLENECK_WARN_MS}ms crit=${DB_BOTTLENECK_CRIT_MS}ms
- Event backlog: warn=${EVENT_BACKLOG_WARN_COUNT} crit=${EVENT_BACKLOG_CRIT_COUNT}
- Reporting impact: warn=${REPORTING_IMPACT_WARN_MS}ms crit=${REPORTING_IMPACT_CRIT_MS}ms
- Single-node risk: warn=${SINGLE_NODE_CPU_WARN_PERCENT}% crit=${SINGLE_NODE_CPU_CRIT_PERCENT}%
- Deploy risk growth: warn=${DEPLOY_RISK_WARN_COUNT} crit=${DEPLOY_RISK_CRIT_COUNT}
- Cluster transition: warn=${CLUSTER_TRANSITION_WARN_SCORE} crit=${CLUSTER_TRANSITION_CRIT_SCORE}
SUMMARY

echo "OK ✅ generated scale trigger matrix hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated correlation summary hazir: ${SUMMARY_FILE}"
