#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${ERP_TR_DIR}/env/lvl13_accountant_portal_document_ai.env.example}"
ACCOUNTANT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_accountant_portal_catalog.yaml"
DOCUMENT_AI_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_document_ai_catalog.yaml"
TEMPLATE_FILE="${ERP_TR_DIR}/config/lvl13_accountant_portal_document_ai_rules.yaml.template"
OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_accountant_portal_document_ai_rules.yaml"
ACCOUNTANT_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_accountant_portal_summary.md"
DOCUMENT_AI_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_document_ai_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${ACCOUNTANT_CATALOG_FILE}" ]; then
  echo "HATA ❌ accountant portal catalog yok: ${ACCOUNTANT_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${DOCUMENT_AI_CATALOG_FILE}" ]; then
  echo "HATA ❌ document ai catalog yok: ${DOCUMENT_AI_CATALOG_FILE}"
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
  ACCOUNTANT_MULTI_COMPANY_ENABLED
  ACCOUNTANT_COMPANY_SCOPE_MODE
  ACCOUNTANT_EXPORT_EXCEL_ENABLED
  ACCOUNTANT_EXPORT_PDF_ENABLED
  ACCOUNTANT_EXPORT_TDHP_ENABLED
  ACCOUNTANT_SUBSCRIPTION_MODE
  ACCOUNTANT_VISIBILITY_MODE
  ACCOUNTANT_TEST_PROFILE
  DOCUMENT_AI_ENABLED
  DOCUMENT_AI_FLOW_MODE
  DOCUMENT_AI_TAX_FIELDS_REQUIRED
  DOCUMENT_AI_CONTACT_FIELDS_ENABLED
  DOCUMENT_AI_CONFIDENCE_THRESHOLD
  DOCUMENT_AI_MANUAL_REVIEW_ENABLED
  DOCUMENT_AI_TEST_PROFILE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__ACCOUNTANT_MULTI_COMPANY_ENABLED__|${ACCOUNTANT_MULTI_COMPANY_ENABLED}|g" \
  -e "s|__ACCOUNTANT_COMPANY_SCOPE_MODE__|${ACCOUNTANT_COMPANY_SCOPE_MODE}|g" \
  -e "s|__ACCOUNTANT_EXPORT_EXCEL_ENABLED__|${ACCOUNTANT_EXPORT_EXCEL_ENABLED}|g" \
  -e "s|__ACCOUNTANT_EXPORT_PDF_ENABLED__|${ACCOUNTANT_EXPORT_PDF_ENABLED}|g" \
  -e "s|__ACCOUNTANT_EXPORT_TDHP_ENABLED__|${ACCOUNTANT_EXPORT_TDHP_ENABLED}|g" \
  -e "s|__ACCOUNTANT_SUBSCRIPTION_MODE__|${ACCOUNTANT_SUBSCRIPTION_MODE}|g" \
  -e "s|__ACCOUNTANT_VISIBILITY_MODE__|${ACCOUNTANT_VISIBILITY_MODE}|g" \
  -e "s|__ACCOUNTANT_TEST_PROFILE__|${ACCOUNTANT_TEST_PROFILE}|g" \
  -e "s|__DOCUMENT_AI_ENABLED__|${DOCUMENT_AI_ENABLED}|g" \
  -e "s|__DOCUMENT_AI_FLOW_MODE__|${DOCUMENT_AI_FLOW_MODE}|g" \
  -e "s|__DOCUMENT_AI_TAX_FIELDS_REQUIRED__|${DOCUMENT_AI_TAX_FIELDS_REQUIRED}|g" \
  -e "s|__DOCUMENT_AI_CONTACT_FIELDS_ENABLED__|${DOCUMENT_AI_CONTACT_FIELDS_ENABLED}|g" \
  -e "s|__DOCUMENT_AI_CONFIDENCE_THRESHOLD__|${DOCUMENT_AI_CONFIDENCE_THRESHOLD}|g" \
  -e "s|__DOCUMENT_AI_MANUAL_REVIEW_ENABLED__|${DOCUMENT_AI_MANUAL_REVIEW_ENABLED}|g" \
  -e "s|__DOCUMENT_AI_TEST_PROFILE__|${DOCUMENT_AI_TEST_PROFILE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<ACCOUNTANTSUMMARY > "${ACCOUNTANT_SUMMARY_FILE}"
# LVL13 Accountant Portal Summary

- Multi company enabled: ${ACCOUNTANT_MULTI_COMPANY_ENABLED}
- Company scope mode: ${ACCOUNTANT_COMPANY_SCOPE_MODE}
- Excel export enabled: ${ACCOUNTANT_EXPORT_EXCEL_ENABLED}
- PDF export enabled: ${ACCOUNTANT_EXPORT_PDF_ENABLED}
- TDHP export enabled: ${ACCOUNTANT_EXPORT_TDHP_ENABLED}
- Subscription mode: ${ACCOUNTANT_SUBSCRIPTION_MODE}
- Visibility mode: ${ACCOUNTANT_VISIBILITY_MODE}
- Test profile: ${ACCOUNTANT_TEST_PROFILE}
ACCOUNTANTSUMMARY

cat <<DOCAISUMMARY > "${DOCUMENT_AI_SUMMARY_FILE}"
# LVL13 Document AI Summary

- Enabled: ${DOCUMENT_AI_ENABLED}
- Flow mode: ${DOCUMENT_AI_FLOW_MODE}
- Tax fields required: ${DOCUMENT_AI_TAX_FIELDS_REQUIRED}
- Contact fields enabled: ${DOCUMENT_AI_CONTACT_FIELDS_ENABLED}
- Confidence threshold: ${DOCUMENT_AI_CONFIDENCE_THRESHOLD}
- Manual review enabled: ${DOCUMENT_AI_MANUAL_REVIEW_ENABLED}
- Test profile: ${DOCUMENT_AI_TEST_PROFILE}
DOCAISUMMARY

echo "OK ✅ generated accountant/document ai rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated accountant portal summary hazir: ${ACCOUNTANT_SUMMARY_FILE}"
echo "OK ✅ generated document ai summary hazir: ${DOCUMENT_AI_SUMMARY_FILE}"
