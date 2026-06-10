#!/usr/bin/env bash
set -euo pipefail

QUALITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${QUALITY_DIR}/env/lvl14_performance_release.env.example}"
PERF_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_performance_gate_catalog.yaml"
RELEASE_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_release_readiness_catalog.yaml"
TEMPLATE_FILE="${QUALITY_DIR}/config/lvl14_performance_release_rules.yaml.template"
OUTPUT_FILE="${QUALITY_DIR}/generated/lvl14_performance_release_rules.yaml"
PERF_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_performance_summary.md"
RELEASE_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_release_readiness_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${PERF_CATALOG_FILE}" ]; then
  echo "HATA ❌ performance gate catalog yok: ${PERF_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${RELEASE_CATALOG_FILE}" ]; then
  echo "HATA ❌ release readiness catalog yok: ${RELEASE_CATALOG_FILE}"
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
  PERF_LATENCY_GATE_MS
  PERF_ERROR_BUDGET_PERCENT
  PERF_BACKLOG_GATE_COUNT
  PERF_DB_SATURATION_PERCENT
  PERF_CACHE_SATURATION_PERCENT
  PERF_FAILOVER_RETRY_REQUIRED
  PERF_TEST_PROFILE
  RELEASE_CHECKLIST_REQUIRED
  RELEASE_ROLLBACK_READY
  RELEASE_OBSERVABILITY_EVIDENCE_REQUIRED
  RELEASE_OPS_HANDOFF_REQUIRED
  RELEASE_REPORT_MODE
  FINAL_PRODUCTION_READINESS_MODE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__PERF_LATENCY_GATE_MS__|${PERF_LATENCY_GATE_MS}|g" \
  -e "s|__PERF_ERROR_BUDGET_PERCENT__|${PERF_ERROR_BUDGET_PERCENT}|g" \
  -e "s|__PERF_BACKLOG_GATE_COUNT__|${PERF_BACKLOG_GATE_COUNT}|g" \
  -e "s|__PERF_DB_SATURATION_PERCENT__|${PERF_DB_SATURATION_PERCENT}|g" \
  -e "s|__PERF_CACHE_SATURATION_PERCENT__|${PERF_CACHE_SATURATION_PERCENT}|g" \
  -e "s|__PERF_FAILOVER_RETRY_REQUIRED__|${PERF_FAILOVER_RETRY_REQUIRED}|g" \
  -e "s|__PERF_TEST_PROFILE__|${PERF_TEST_PROFILE}|g" \
  -e "s|__RELEASE_CHECKLIST_REQUIRED__|${RELEASE_CHECKLIST_REQUIRED}|g" \
  -e "s|__RELEASE_ROLLBACK_READY__|${RELEASE_ROLLBACK_READY}|g" \
  -e "s|__RELEASE_OBSERVABILITY_EVIDENCE_REQUIRED__|${RELEASE_OBSERVABILITY_EVIDENCE_REQUIRED}|g" \
  -e "s|__RELEASE_OPS_HANDOFF_REQUIRED__|${RELEASE_OPS_HANDOFF_REQUIRED}|g" \
  -e "s|__RELEASE_REPORT_MODE__|${RELEASE_REPORT_MODE}|g" \
  -e "s|__FINAL_PRODUCTION_READINESS_MODE__|${FINAL_PRODUCTION_READINESS_MODE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<PERFSUMMARY > "${PERF_SUMMARY_FILE}"
# LVL14 Performance Summary

- Latency gate: ${PERF_LATENCY_GATE_MS} ms
- Error budget: ${PERF_ERROR_BUDGET_PERCENT}%
- Backlog gate: ${PERF_BACKLOG_GATE_COUNT}
- DB saturation gate: ${PERF_DB_SATURATION_PERCENT}%
- Cache saturation gate: ${PERF_CACHE_SATURATION_PERCENT}%
- Failover / retry required: ${PERF_FAILOVER_RETRY_REQUIRED}
- Test profile: ${PERF_TEST_PROFILE}
PERFSUMMARY

cat <<RELEASESUMMARY > "${RELEASE_SUMMARY_FILE}"
# LVL14 Release Readiness Summary

- Checklist required: ${RELEASE_CHECKLIST_REQUIRED}
- Rollback ready: ${RELEASE_ROLLBACK_READY}
- Observability evidence required: ${RELEASE_OBSERVABILITY_EVIDENCE_REQUIRED}
- Ops handoff required: ${RELEASE_OPS_HANDOFF_REQUIRED}
- Report mode: ${RELEASE_REPORT_MODE}
- Final production readiness mode: ${FINAL_PRODUCTION_READINESS_MODE}
RELEASESUMMARY

echo "OK ✅ generated performance/release rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated performance summary hazir: ${PERF_SUMMARY_FILE}"
echo "OK ✅ generated release readiness summary hazir: ${RELEASE_SUMMARY_FILE}"
