#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${ERP_TR_DIR}/env/lvl13_tdhp_tax.env.example}"
TDHP_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_tdhp_catalog.yaml"
TAX_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_tax_catalog.yaml"
TEMPLATE_FILE="${ERP_TR_DIR}/config/lvl13_tdhp_tax_rules.yaml.template"
OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_tdhp_tax_rules.yaml"
TDHP_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_tdhp_summary.md"
TAX_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_tax_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${TDHP_CATALOG_FILE}" ]; then
  echo "HATA ❌ tdhp catalog yok: ${TDHP_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${TAX_CATALOG_FILE}" ]; then
  echo "HATA ❌ tax catalog yok: ${TAX_CATALOG_FILE}"
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
  TDHP_VERSION
  TDHP_DEFAULT_CURRENCY
  TDHP_RECONCILIATION_MODE
  TDHP_AUDIT_TRACE_ENABLED
  TDHP_DOCUMENT_RULE_MODE
  TDHP_VALIDATION_PROFILE
  KDV_DEFAULT_PERCENT
  KDV_REDUCED_PERCENT
  KDV_SUPER_REDUCED_PERCENT
  WITHHOLDING_ENABLED
  WITHHOLDING_DEFAULT_PERCENT
  TAX_EXEMPTION_MODE
  TAX_RULE_VERSION
  TAX_AUDIT_ENABLED
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__TDHP_VERSION__|${TDHP_VERSION}|g" \
  -e "s|__TDHP_DEFAULT_CURRENCY__|${TDHP_DEFAULT_CURRENCY}|g" \
  -e "s|__TDHP_RECONCILIATION_MODE__|${TDHP_RECONCILIATION_MODE}|g" \
  -e "s|__TDHP_AUDIT_TRACE_ENABLED__|${TDHP_AUDIT_TRACE_ENABLED}|g" \
  -e "s|__TDHP_DOCUMENT_RULE_MODE__|${TDHP_DOCUMENT_RULE_MODE}|g" \
  -e "s|__TDHP_VALIDATION_PROFILE__|${TDHP_VALIDATION_PROFILE}|g" \
  -e "s|__KDV_DEFAULT_PERCENT__|${KDV_DEFAULT_PERCENT}|g" \
  -e "s|__KDV_REDUCED_PERCENT__|${KDV_REDUCED_PERCENT}|g" \
  -e "s|__KDV_SUPER_REDUCED_PERCENT__|${KDV_SUPER_REDUCED_PERCENT}|g" \
  -e "s|__WITHHOLDING_ENABLED__|${WITHHOLDING_ENABLED}|g" \
  -e "s|__WITHHOLDING_DEFAULT_PERCENT__|${WITHHOLDING_DEFAULT_PERCENT}|g" \
  -e "s|__TAX_EXEMPTION_MODE__|${TAX_EXEMPTION_MODE}|g" \
  -e "s|__TAX_RULE_VERSION__|${TAX_RULE_VERSION}|g" \
  -e "s|__TAX_AUDIT_ENABLED__|${TAX_AUDIT_ENABLED}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<TDHPSUMMARY > "${TDHP_SUMMARY_FILE}"
# LVL13 TDHP Summary

- Version: ${TDHP_VERSION}
- Default currency: ${TDHP_DEFAULT_CURRENCY}
- Reconciliation mode: ${TDHP_RECONCILIATION_MODE}
- Audit trace enabled: ${TDHP_AUDIT_TRACE_ENABLED}
- Document rule mode: ${TDHP_DOCUMENT_RULE_MODE}
- Validation profile: ${TDHP_VALIDATION_PROFILE}
TDHPSUMMARY

cat <<TAXSUMMARY > "${TAX_SUMMARY_FILE}"
# LVL13 Tax Summary

- KDV default: ${KDV_DEFAULT_PERCENT}
- KDV reduced: ${KDV_REDUCED_PERCENT}
- KDV super reduced: ${KDV_SUPER_REDUCED_PERCENT}
- Withholding enabled: ${WITHHOLDING_ENABLED}
- Withholding default: ${WITHHOLDING_DEFAULT_PERCENT}
- Exemption mode: ${TAX_EXEMPTION_MODE}
- Rule version: ${TAX_RULE_VERSION}
- Tax audit enabled: ${TAX_AUDIT_ENABLED}
TAXSUMMARY

echo "OK ✅ generated tdhp/tax rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated tdhp summary hazir: ${TDHP_SUMMARY_FILE}"
echo "OK ✅ generated tax summary hazir: ${TAX_SUMMARY_FILE}"
