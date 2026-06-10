#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${OBS_DIR}/env/lvl11_scale_trigger.env.example"
CATALOG_FILE="${OBS_DIR}/config/lvl11_correlation_catalog.yaml"
OUTPUT_FILE="${OBS_DIR}/generated/lvl11_scale_trigger_matrix.yaml"
SUMMARY_FILE="${OBS_DIR}/generated/lvl11_correlation_summary.md"
RENDER_SCRIPT="${OBS_DIR}/scripts/render_lvl11_correlation_scale.sh"

echo "===== LVL11 CORRELATION + SCALE TRIGGER SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'id: service_to_service' "${CATALOG_FILE}"
echo "OK ✅ service-to-service correlation var"

grep -q 'id: request_chain' "${CATALOG_FILE}"
echo "OK ✅ request/correlation chain var"

grep -q 'incident_grouping:' "${CATALOG_FILE}"
echo "OK ✅ incident grouping var"

grep -q 'noisy_alert_suppression:' "${CATALOG_FILE}"
echo "OK ✅ noisy alert suppression var"

grep -q 'root_cause_hints:' "${CATALOG_FILE}"
echo "OK ✅ root-cause hints var"

grep -q 'id: db_bottleneck' "${OUTPUT_FILE}"
echo "OK ✅ db bottleneck trigger render edildi"

grep -q 'id: event_backlog' "${OUTPUT_FILE}"
echo "OK ✅ event backlog trigger render edildi"

grep -q 'id: reporting_impact' "${OUTPUT_FILE}"
echo "OK ✅ reporting impact trigger render edildi"

grep -q 'id: single_node_risk' "${OUTPUT_FILE}"
echo "OK ✅ single-node risk trigger render edildi"

grep -q 'id: deploy_risk_growth' "${OUTPUT_FILE}"
echo "OK ✅ deploy risk trigger render edildi"

grep -q 'id: cluster_transition' "${OUTPUT_FILE}"
echo "OK ✅ cluster transition trigger render edildi"

grep -q 'LVL11 Correlation Summary' "${SUMMARY_FILE}"
echo "OK ✅ correlation summary olustu"

echo "===== LVL11 CORRELATION + SCALE TRIGGER SMOKE TAMAM ====="
