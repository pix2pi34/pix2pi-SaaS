#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ERP_TR_DIR}/env/lvl13_payment_closure.env.example"
PAYMENT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_payment_catalog.yaml"
PAYMENT_OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_payment_rules.yaml"
MATRIX_OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_turkiye_compliance_matrix.yaml"
PAYMENT_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_payment_summary.md"
RENDER_SCRIPT="${ERP_TR_DIR}/scripts/render_lvl13_payment_closure.sh"

echo "===== LVL13 ODEME + CLOSURE SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'pos_backbone:' "${PAYMENT_CATALOG_FILE}"
echo "OK ✅ POS entegrasyon omurgasi var"

grep -q 'bank_collection_flow:' "${PAYMENT_CATALOG_FILE}"
echo "OK ✅ banka / tahsilat akisi var"

grep -q 'reconciliation_bridge:' "${PAYMENT_CATALOG_FILE}"
echo "OK ✅ mutabakat koprusu var"

grep -q 'refund_cancel_flows:' "${PAYMENT_CATALOG_FILE}"
echo "OK ✅ iade / iptal akislari var"

grep -q 'audit_trail:' "${PAYMENT_CATALOG_FILE}"
echo "OK ✅ entegrasyon audit izi var"

grep -q 'test_suite:' "${PAYMENT_CATALOG_FILE}"
echo "OK ✅ odeme entegrasyon testleri seti var"

grep -q 'payment_rules:' "${PAYMENT_OUTPUT_FILE}"
echo "OK ✅ odeme rules render edildi"

grep -q 'turkiye_compliance:' "${MATRIX_OUTPUT_FILE}"
echo "OK ✅ turkiye compliance matrix render edildi"

grep -q 'LVL13 Payment Summary' "${PAYMENT_SUMMARY_FILE}"
echo "OK ✅ odeme summary olustu"

echo "===== LVL13 ODEME + CLOSURE SMOKE TAMAM ====="
