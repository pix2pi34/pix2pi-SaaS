#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ERP_TR_DIR}/env/lvl13_tdhp_tax.env.example"
TDHP_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_tdhp_catalog.yaml"
TAX_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_tax_catalog.yaml"
OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_tdhp_tax_rules.yaml"
TDHP_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_tdhp_summary.md"
TAX_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_tax_summary.md"
RENDER_SCRIPT="${ERP_TR_DIR}/scripts/render_lvl13_tdhp_tax.sh"

echo "===== LVL13 TDHP + VERGI SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'advanced_mapping:' "${TDHP_CATALOG_FILE}"
echo "OK ✅ gelismis TDHP mapping var"

grep -q 'chart_versioning:' "${TDHP_CATALOG_FILE}"
echo "OK ✅ hesap plani versiyonlama var"

grep -q 'document_scoped_rules:' "${TDHP_CATALOG_FILE}"
echo "OK ✅ belge bazli muhasebe kurali var"

grep -q 'audit_trace:' "${TDHP_CATALOG_FILE}"
echo "OK ✅ audit trace var"

grep -q 'reconciliation:' "${TDHP_CATALOG_FILE}"
echo "OK ✅ reconciliation var"

grep -q 'validation_suite:' "${TDHP_CATALOG_FILE}"
echo "OK ✅ muhasebe dogrulama seti var"

grep -q 'vat_rule_engine:' "${TAX_CATALOG_FILE}"
echo "OK ✅ KDV kural motoru var"

grep -q 'withholding_prep:' "${TAX_CATALOG_FILE}"
echo "OK ✅ stopaj / ozel vergi hazirligi var"

grep -q 'exemption_flow:' "${TAX_CATALOG_FILE}"
echo "OK ✅ istisna / muafiyet akisi var"

grep -q 'rule_versioning:' "${TAX_CATALOG_FILE}"
echo "OK ✅ rule versioning var"

grep -q 'audit_trail:' "${TAX_CATALOG_FILE}"
echo "OK ✅ vergi audit izi var"

grep -q 'validation_suite:' "${TAX_CATALOG_FILE}"
echo "OK ✅ vergi testleri seti var"

grep -q 'tdhp_rules:' "${OUTPUT_FILE}"
echo "OK ✅ TDHP rules render edildi"

grep -q 'tax_rules:' "${OUTPUT_FILE}"
echo "OK ✅ vergi rules render edildi"

grep -q 'LVL13 TDHP Summary' "${TDHP_SUMMARY_FILE}"
echo "OK ✅ TDHP summary olustu"

grep -q 'LVL13 Tax Summary' "${TAX_SUMMARY_FILE}"
echo "OK ✅ vergi summary olustu"

echo "===== LVL13 TDHP + VERGI SMOKE TAMAM ====="
