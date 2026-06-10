#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ERP_TR_DIR}/env/lvl13_accountant_portal_document_ai.env.example"
ACCOUNTANT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_accountant_portal_catalog.yaml"
DOCUMENT_AI_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_document_ai_catalog.yaml"
OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_accountant_portal_document_ai_rules.yaml"
ACCOUNTANT_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_accountant_portal_summary.md"
DOCUMENT_AI_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_document_ai_summary.md"
RENDER_SCRIPT="${ERP_TR_DIR}/scripts/render_lvl13_accountant_portal_document_ai.sh"

echo "===== LVL13 MUHASEBECI PORTALI + AKILLI BELGE SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'multi_company_access:' "${ACCOUNTANT_CATALOG_FILE}"
echo "OK ✅ cok firmali erisim var"

grep -q 'company_scoped_permissions:' "${ACCOUNTANT_CATALOG_FILE}"
echo "OK ✅ firma bazli yetki var"

grep -q 'export_surfaces:' "${ACCOUNTANT_CATALOG_FILE}"
echo "OK ✅ Excel / PDF / TDHP export var"

grep -q 'subscription_model:' "${ACCOUNTANT_CATALOG_FILE}"
echo "OK ✅ aylik abonelik mantigi var"

grep -q 'company_visibility:' "${ACCOUNTANT_CATALOG_FILE}"
echo "OK ✅ firma bazli gorunurluk var"

grep -q 'test_suite:' "${ACCOUNTANT_CATALOG_FILE}"
echo "OK ✅ muhasebeci portali testleri seti var"

grep -q 'ocr_lens_flow:' "${DOCUMENT_AI_CATALOG_FILE}"
echo "OK ✅ belge / kart OCR-Lens akisi var"

grep -q 'tax_field_extraction:' "${DOCUMENT_AI_CATALOG_FILE}"
echo "OK ✅ vergi no / vergi dairesi extraction var"

grep -q 'contact_field_extraction:' "${DOCUMENT_AI_CATALOG_FILE}"
echo "OK ✅ adres / telefon / email extraction var"

grep -q 'confidence_and_review:' "${DOCUMENT_AI_CATALOG_FILE}"
echo "OK ✅ guven skoru / manuel duzeltme var"

grep -q 'test_suite:' "${DOCUMENT_AI_CATALOG_FILE}"
echo "OK ✅ belge okuma testleri seti var"

grep -q 'accountant_portal_rules:' "${OUTPUT_FILE}"
echo "OK ✅ muhasebeci portali rules render edildi"

grep -q 'document_ai_rules:' "${OUTPUT_FILE}"
echo "OK ✅ document ai rules render edildi"

grep -q 'LVL13 Accountant Portal Summary' "${ACCOUNTANT_SUMMARY_FILE}"
echo "OK ✅ muhasebeci portali summary olustu"

grep -q 'LVL13 Document AI Summary' "${DOCUMENT_AI_SUMMARY_FILE}"
echo "OK ✅ document ai summary olustu"

echo "===== LVL13 MUHASEBECI PORTALI + AKILLI BELGE SMOKE TAMAM ====="
