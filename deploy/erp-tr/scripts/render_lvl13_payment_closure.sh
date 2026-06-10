#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${ERP_TR_DIR}/env/lvl13_payment_closure.env.example}"
PAYMENT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_payment_catalog.yaml"
TEMPLATE_FILE="${ERP_TR_DIR}/config/lvl13_turkiye_compliance_matrix.yaml.template"
PAYMENT_OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_payment_rules.yaml"
MATRIX_OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_turkiye_compliance_matrix.yaml"
PAYMENT_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_payment_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${PAYMENT_CATALOG_FILE}" ]; then
  echo "HATA ❌ payment catalog yok: ${PAYMENT_CATALOG_FILE}"
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
  PAYMENT_POS_BACKBONE_ENABLED
  PAYMENT_POS_PROVIDER_MODE
  PAYMENT_BANK_COLLECTION_ENABLED
  PAYMENT_BANK_SETTLEMENT_MODE
  PAYMENT_RECONCILIATION_BRIDGE_MODE
  PAYMENT_REFUND_FLOW_ENABLED
  PAYMENT_CANCEL_FLOW_ENABLED
  PAYMENT_AUDIT_ENABLED
  PAYMENT_TEST_PROFILE
  TURKIYE_ACCOUNTING_SMOKE_REQUIRED
  TURKIYE_EBELGE_SMOKE_REQUIRED
  TURKIYE_EXPORT_SMOKE_REQUIRED
  TURKIYE_ACCOUNTANT_PORTAL_SMOKE_REQUIRED
  TURKIYE_PAYMENT_SMOKE_REQUIRED
  TURKIYE_CLOSURE_MODE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

cat <<PAYRULES > "${PAYMENT_OUTPUT_FILE}"
version: v1
payment_rules:
  pos_backbone_enabled: ${PAYMENT_POS_BACKBONE_ENABLED}
  pos_provider_mode: ${PAYMENT_POS_PROVIDER_MODE}
  bank_collection_enabled: ${PAYMENT_BANK_COLLECTION_ENABLED}
  bank_settlement_mode: ${PAYMENT_BANK_SETTLEMENT_MODE}
  reconciliation_bridge_mode: ${PAYMENT_RECONCILIATION_BRIDGE_MODE}
  refund_flow_enabled: ${PAYMENT_REFUND_FLOW_ENABLED}
  cancel_flow_enabled: ${PAYMENT_CANCEL_FLOW_ENABLED}
  audit_enabled: ${PAYMENT_AUDIT_ENABLED}
  test_profile: ${PAYMENT_TEST_PROFILE}
PAYRULES

sed \
  -e "s|__PAYMENT_POS_BACKBONE_ENABLED__|${PAYMENT_POS_BACKBONE_ENABLED}|g" \
  -e "s|__PAYMENT_POS_PROVIDER_MODE__|${PAYMENT_POS_PROVIDER_MODE}|g" \
  -e "s|__PAYMENT_BANK_COLLECTION_ENABLED__|${PAYMENT_BANK_COLLECTION_ENABLED}|g" \
  -e "s|__PAYMENT_BANK_SETTLEMENT_MODE__|${PAYMENT_BANK_SETTLEMENT_MODE}|g" \
  -e "s|__PAYMENT_RECONCILIATION_BRIDGE_MODE__|${PAYMENT_RECONCILIATION_BRIDGE_MODE}|g" \
  -e "s|__PAYMENT_REFUND_FLOW_ENABLED__|${PAYMENT_REFUND_FLOW_ENABLED}|g" \
  -e "s|__PAYMENT_CANCEL_FLOW_ENABLED__|${PAYMENT_CANCEL_FLOW_ENABLED}|g" \
  -e "s|__PAYMENT_AUDIT_ENABLED__|${PAYMENT_AUDIT_ENABLED}|g" \
  -e "s|__PAYMENT_TEST_PROFILE__|${PAYMENT_TEST_PROFILE}|g" \
  -e "s|__TURKIYE_ACCOUNTING_SMOKE_REQUIRED__|${TURKIYE_ACCOUNTING_SMOKE_REQUIRED}|g" \
  -e "s|__TURKIYE_EBELGE_SMOKE_REQUIRED__|${TURKIYE_EBELGE_SMOKE_REQUIRED}|g" \
  -e "s|__TURKIYE_EXPORT_SMOKE_REQUIRED__|${TURKIYE_EXPORT_SMOKE_REQUIRED}|g" \
  -e "s|__TURKIYE_ACCOUNTANT_PORTAL_SMOKE_REQUIRED__|${TURKIYE_ACCOUNTANT_PORTAL_SMOKE_REQUIRED}|g" \
  -e "s|__TURKIYE_PAYMENT_SMOKE_REQUIRED__|${TURKIYE_PAYMENT_SMOKE_REQUIRED}|g" \
  -e "s|__TURKIYE_CLOSURE_MODE__|${TURKIYE_CLOSURE_MODE}|g" \
  "${TEMPLATE_FILE}" > "${MATRIX_OUTPUT_FILE}"

cat <<SUMMARY > "${PAYMENT_SUMMARY_FILE}"
# LVL13 Payment Summary

- POS backbone enabled: ${PAYMENT_POS_BACKBONE_ENABLED}
- POS provider mode: ${PAYMENT_POS_PROVIDER_MODE}
- Bank collection enabled: ${PAYMENT_BANK_COLLECTION_ENABLED}
- Bank settlement mode: ${PAYMENT_BANK_SETTLEMENT_MODE}
- Reconciliation bridge mode: ${PAYMENT_RECONCILIATION_BRIDGE_MODE}
- Refund flow enabled: ${PAYMENT_REFUND_FLOW_ENABLED}
- Cancel flow enabled: ${PAYMENT_CANCEL_FLOW_ENABLED}
- Audit enabled: ${PAYMENT_AUDIT_ENABLED}
- Test profile: ${PAYMENT_TEST_PROFILE}

# Turkiye Compliance
- Accounting smoke required: ${TURKIYE_ACCOUNTING_SMOKE_REQUIRED}
- e-Belge smoke required: ${TURKIYE_EBELGE_SMOKE_REQUIRED}
- Export smoke required: ${TURKIYE_EXPORT_SMOKE_REQUIRED}
- Accountant portal smoke required: ${TURKIYE_ACCOUNTANT_PORTAL_SMOKE_REQUIRED}
- Payment smoke required: ${TURKIYE_PAYMENT_SMOKE_REQUIRED}
- Closure mode: ${TURKIYE_CLOSURE_MODE}
SUMMARY

echo "OK ✅ generated payment rules hazir: ${PAYMENT_OUTPUT_FILE}"
echo "OK ✅ generated turkiye compliance matrix hazir: ${MATRIX_OUTPUT_FILE}"
echo "OK ✅ generated payment summary hazir: ${PAYMENT_SUMMARY_FILE}"
