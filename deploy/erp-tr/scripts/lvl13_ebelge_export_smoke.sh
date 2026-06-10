#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ERP_TR_DIR}/env/lvl13_ebelge_export.env.example"
EBELGE_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_ebelge_catalog.yaml"
EXPORT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_export_catalog.yaml"
OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_ebelge_export_rules.yaml"
EBELGE_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_ebelge_summary.md"
EXPORT_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_export_summary.md"
RENDER_SCRIPT="${ERP_TR_DIR}/scripts/render_lvl13_ebelge_export.sh"

echo "===== LVL13 E-BELGE + EXPORT SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'efatura:' "${EBELGE_CATALOG_FILE}"
echo "OK ✅ e-Fatura var"

grep -q 'earsiv:' "${EBELGE_CATALOG_FILE}"
echo "OK ✅ e-Arsiv var"

grep -q 'eadisyon:' "${EBELGE_CATALOG_FILE}"
echo "OK ✅ e-Adisyon var"

grep -q 'status_sync:' "${EBELGE_CATALOG_FILE}"
echo "OK ✅ belge durum senkronu var"

grep -q 'error_cancel_retry:' "${EBELGE_CATALOG_FILE}"
echo "OK ✅ hata / iptal / tekrar akisi var"

grep -q 'validation_suite:' "${EBELGE_CATALOG_FILE}"
echo "OK ✅ e-Belge testleri seti var"

grep -q 'logo:' "${EXPORT_CATALOG_FILE}"
echo "OK ✅ Logo export var"

grep -q 'mikro:' "${EXPORT_CATALOG_FILE}"
echo "OK ✅ Mikro export var"

grep -q 'zirve:' "${EXPORT_CATALOG_FILE}"
echo "OK ✅ Zirve export var"

grep -q 'eta:' "${EXPORT_CATALOG_FILE}"
echo "OK ✅ ETA export var"

grep -q 'validation_matrix:' "${EXPORT_CATALOG_FILE}"
echo "OK ✅ export dogrulama matrisi var"

grep -q 'test_suite:' "${EXPORT_CATALOG_FILE}"
echo "OK ✅ export testleri seti var"

grep -q 'ebelge_rules:' "${OUTPUT_FILE}"
echo "OK ✅ e-Belge rules render edildi"

grep -q 'export_rules:' "${OUTPUT_FILE}"
echo "OK ✅ export rules render edildi"

grep -q 'LVL13 e-Belge Summary' "${EBELGE_SUMMARY_FILE}"
echo "OK ✅ e-Belge summary olustu"

grep -q 'LVL13 Export Summary' "${EXPORT_SUMMARY_FILE}"
echo "OK ✅ export summary olustu"

echo "===== LVL13 E-BELGE + EXPORT SMOKE TAMAM ====="
