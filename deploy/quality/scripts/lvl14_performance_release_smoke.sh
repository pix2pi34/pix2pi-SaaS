#!/usr/bin/env bash
set -euo pipefail

QUALITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${QUALITY_DIR}/env/lvl14_performance_release.env.example"
PERF_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_performance_gate_catalog.yaml"
RELEASE_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_release_readiness_catalog.yaml"
OUTPUT_FILE="${QUALITY_DIR}/generated/lvl14_performance_release_rules.yaml"
PERF_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_performance_summary.md"
RELEASE_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_release_readiness_summary.md"
RENDER_SCRIPT="${QUALITY_DIR}/scripts/render_lvl14_performance_release.sh"

echo "===== LVL14 PERFORMANCE + RELEASE SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'latency_gate:' "${PERF_CATALOG_FILE}"
echo "OK ✅ latency gate var"

grep -q 'error_budget_gate:' "${PERF_CATALOG_FILE}"
echo "OK ✅ error budget gate var"

grep -q 'backlog_queue_gate:' "${PERF_CATALOG_FILE}"
echo "OK ✅ backlog / queue gate var"

grep -q 'db_cache_saturation_gate:' "${PERF_CATALOG_FILE}"
echo "OK ✅ DB / cache saturation gate var"

grep -q 'failover_retry_gate:' "${PERF_CATALOG_FILE}"
echo "OK ✅ failover / retry reliability gate var"

grep -q 'regression_suite:' "${PERF_CATALOG_FILE}"
echo "OK ✅ performance regression suite var"

grep -q 'checklist:' "${RELEASE_CATALOG_FILE}"
echo "OK ✅ release checklist var"

grep -q 'rollback_readiness:' "${RELEASE_CATALOG_FILE}"
echo "OK ✅ rollback readiness var"

grep -q 'observability_evidence:' "${RELEASE_CATALOG_FILE}"
echo "OK ✅ observability evidence var"

grep -q 'ops_handoff:' "${RELEASE_CATALOG_FILE}"
echo "OK ✅ ops handoff paketi var"

grep -q 'release_report:' "${RELEASE_CATALOG_FILE}"
echo "OK ✅ release report var"

grep -q 'performance_rules:' "${OUTPUT_FILE}"
echo "OK ✅ performance rules render edildi"

grep -q 'release_rules:' "${OUTPUT_FILE}"
echo "OK ✅ release rules render edildi"

grep -q 'LVL14 Performance Summary' "${PERF_SUMMARY_FILE}"
echo "OK ✅ performance summary olustu"

grep -q 'LVL14 Release Readiness Summary' "${RELEASE_SUMMARY_FILE}"
echo "OK ✅ release readiness summary olustu"

echo "===== LVL14 PERFORMANCE + RELEASE SMOKE TAMAM ====="
