#!/usr/bin/env bash
set -euo pipefail

OBS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${OBS_DIR}/env/lvl11_early_warning.env.example"
CATALOG_FILE="${OBS_DIR}/config/lvl11_signal_catalog.yaml"
OUTPUT_FILE="${OBS_DIR}/generated/lvl11_threshold_rules.yaml"
SUMMARY_FILE="${OBS_DIR}/generated/lvl11_threshold_summary.md"
RENDER_SCRIPT="${OBS_DIR}/scripts/render_lvl11_thresholds.sh"

echo "===== LVL11 SIGNAL + THRESHOLD SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'id: infra' "${CATALOG_FILE}"
echo "OK ✅ infra signal grubu var"

grep -q 'id: app' "${CATALOG_FILE}"
echo "OK ✅ app signal grubu var"

grep -q 'id: db' "${CATALOG_FILE}"
echo "OK ✅ db signal grubu var"

grep -q 'id: event_bus' "${CATALOG_FILE}"
echo "OK ✅ event_bus signal grubu var"

grep -q 'id: cache' "${CATALOG_FILE}"
echo "OK ✅ cache signal grubu var"

grep -q 'id: tenant_security' "${CATALOG_FILE}"
echo "OK ✅ tenant/security signal grubu var"

grep -q 'warn: 70' "${OUTPUT_FILE}"
echo "OK ✅ warning threshold render edildi"

grep -q 'crit: 85' "${OUTPUT_FILE}"
echo "OK ✅ critical threshold render edildi"

grep -q 'unit: ms' "${OUTPUT_FILE}"
echo "OK ✅ latency unit render edildi"

grep -q 'LVL11 Threshold Summary' "${SUMMARY_FILE}"
echo "OK ✅ threshold summary olustu"

echo "===== LVL11 SIGNAL + THRESHOLD SMOKE TAMAM ====="
