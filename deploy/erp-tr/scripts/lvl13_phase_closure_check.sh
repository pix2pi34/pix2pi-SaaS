#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY_ENV_FILE="${ERP_TR_DIR}/generated/lvl13_phase_closure_summary.env"
REPORT_FILE="${ERP_TR_DIR}/generated/lvl13_phase_closure_report.md"

TDHP_SCRIPT="${ERP_TR_DIR}/scripts/lvl13_tdhp_tax_smoke.sh"
EBELGE_SCRIPT="${ERP_TR_DIR}/scripts/lvl13_ebelge_export_smoke.sh"
ACCOUNTANT_SCRIPT="${ERP_TR_DIR}/scripts/lvl13_accountant_portal_document_ai_smoke.sh"
PAYMENT_SCRIPT="${ERP_TR_DIR}/scripts/lvl13_payment_closure_smoke.sh"

REQUIRED_FILES=(
  "${ERP_TR_DIR}/generated/lvl13_tdhp_tax_rules.yaml"
  "${ERP_TR_DIR}/generated/lvl13_tdhp_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_tax_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_ebelge_export_rules.yaml"
  "${ERP_TR_DIR}/generated/lvl13_ebelge_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_export_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_accountant_portal_document_ai_rules.yaml"
  "${ERP_TR_DIR}/generated/lvl13_accountant_portal_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_document_ai_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_payment_rules.yaml"
  "${ERP_TR_DIR}/generated/lvl13_payment_summary.md"
  "${ERP_TR_DIR}/generated/lvl13_turkiye_compliance_matrix.yaml"
)

echo "===== LVL13 PHASE CLOSURE CHECK BASLIYOR ====="

bash "${TDHP_SCRIPT}"
echo "OK ✅ Turkiye muhasebe smoke gecti"

bash "${EBELGE_SCRIPT}"
echo "OK ✅ e-Belge smoke gecti"

bash "${ACCOUNTANT_SCRIPT}"
echo "OK ✅ muhasebeci portali smoke gecti"

bash "${PAYMENT_SCRIPT}"
echo "OK ✅ odeme entegrasyon smoke gecti"

TDHP_TAX_READY=true
EBELGE_EXPORT_READY=true
ACCOUNTANT_DOCUMENT_READY=true
PAYMENT_READY=true

for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "${f}" ]; then
    echo "HATA ❌ eksik dosya: ${f}"
    case "${f}" in
      *tdhp*|*tax*) TDHP_TAX_READY=false ;;
      *ebelge*|*export*) EBELGE_EXPORT_READY=false ;;
      *accountant*|*document_ai*) ACCOUNTANT_DOCUMENT_READY=false ;;
      *payment*|*compliance*) PAYMENT_READY=false ;;
    esac
  else
    echo "OK ✅ dosya var: ${f}"
  fi
done

PHASE_STATUS="READY"

if [ "${TDHP_TAX_READY}" != "true" ] || \
   [ "${EBELGE_EXPORT_READY}" != "true" ] || \
   [ "${ACCOUNTANT_DOCUMENT_READY}" != "true" ] || \
   [ "${PAYMENT_READY}" != "true" ]; then
  PHASE_STATUS="BLOCKED"
fi

cat <<SUMMARY > "${SUMMARY_ENV_FILE}"
TDHP_TAX_READY=${TDHP_TAX_READY}
EBELGE_EXPORT_READY=${EBELGE_EXPORT_READY}
ACCOUNTANT_DOCUMENT_READY=${ACCOUNTANT_DOCUMENT_READY}
PAYMENT_READY=${PAYMENT_READY}
PHASE_STATUS=${PHASE_STATUS}
SUMMARY

cat <<REPORT > "${REPORT_FILE}"
# LVL13 Phase Closure Report

- TDHP_TAX_READY=${TDHP_TAX_READY}
- EBELGE_EXPORT_READY=${EBELGE_EXPORT_READY}
- ACCOUNTANT_DOCUMENT_READY=${ACCOUNTANT_DOCUMENT_READY}
- PAYMENT_READY=${PAYMENT_READY}
- PHASE_STATUS=${PHASE_STATUS}

## 13.8 Checklist
- 13.8.1 Turkiye muhasebe smoke => ${TDHP_TAX_READY}
- 13.8.2 e-Belge smoke => ${EBELGE_EXPORT_READY}
- 13.8.3 export smoke => ${EBELGE_EXPORT_READY}
- 13.8.4 muhasebeci portali smoke => ${ACCOUNTANT_DOCUMENT_READY}
- 13.8.5 odeme entegrasyon smoke => ${PAYMENT_READY}
- 13.8.6 Turkiye uyum kapanisi => ${PHASE_STATUS}
REPORT

if [ "${PHASE_STATUS}" != "READY" ]; then
  echo "HATA ❌ LVL13 phase closure blocked"
  echo "HATA ❌ rapor: ${REPORT_FILE}"
  exit 1
fi

echo "OK ✅ lvl13 phase closure ready"
echo "OK ✅ summary: ${SUMMARY_ENV_FILE}"
echo "OK ✅ rapor: ${REPORT_FILE}"
