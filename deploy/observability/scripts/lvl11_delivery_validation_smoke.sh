#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${OBS_DIR}/env/lvl11_delivery_validation.env.example"
CATALOG_FILE="${OBS_DIR}/config/lvl11_delivery_catalog.yaml"
OUTPUT_FILE="${OBS_DIR}/generated/lvl11_validation_matrix.yaml"
SUMMARY_FILE="${OBS_DIR}/generated/lvl11_delivery_summary.md"
RENDER_SCRIPT="${OBS_DIR}/scripts/render_lvl11_delivery_validation.sh"

echo "===== LVL11 DELIVERY + VALIDATION SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'grafana_route:' "${CATALOG_FILE}"
echo "OK ✅ grafana alert rotasi var"

grep -q 'channels:' "${CATALOG_FILE}"
echo "OK ✅ mail / mesajlasma kanali var"

grep -q 'severity_routing:' "${CATALOG_FILE}"
echo "OK ✅ severity routing var"

grep -q 'ack_silence_policy:' "${CATALOG_FILE}"
echo "OK ✅ ack / silence policy var"

grep -q 'escalation_ladder:' "${CATALOG_FILE}"
echo "OK ✅ escalation ladder var"

grep -q 'id: threshold_simulation' "${OUTPUT_FILE}"
echo "OK ✅ threshold simulation validation render edildi"

grep -q 'id: false_positive_test' "${OUTPUT_FILE}"
echo "OK ✅ false positive validation render edildi"

grep -q 'id: false_negative_test' "${OUTPUT_FILE}"
echo "OK ✅ false negative validation render edildi"

grep -q 'id: dry_run_alarm_mode' "${OUTPUT_FILE}"
echo "OK ✅ dry-run validation render edildi"

grep -q 'id: correlation_test' "${OUTPUT_FILE}"
echo "OK ✅ correlation validation render edildi"

grep -q 'id: early_warning_suite' "${OUTPUT_FILE}"
echo "OK ✅ early warning suite render edildi"

grep -q 'LVL11 Delivery Summary' "${SUMMARY_FILE}"
echo "OK ✅ delivery summary olustu"

echo "===== LVL11 DELIVERY + VALIDATION SMOKE TAMAM ====="
