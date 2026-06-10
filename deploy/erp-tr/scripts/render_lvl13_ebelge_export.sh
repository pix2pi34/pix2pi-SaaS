#!/usr/bin/env bash
set -euo pipefail

ERP_TR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${ERP_TR_DIR}/env/lvl13_ebelge_export.env.example}"
EBELGE_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_ebelge_catalog.yaml"
EXPORT_CATALOG_FILE="${ERP_TR_DIR}/config/lvl13_export_catalog.yaml"
TEMPLATE_FILE="${ERP_TR_DIR}/config/lvl13_ebelge_export_rules.yaml.template"
OUTPUT_FILE="${ERP_TR_DIR}/generated/lvl13_ebelge_export_rules.yaml"
EBELGE_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_ebelge_summary.md"
EXPORT_SUMMARY_FILE="${ERP_TR_DIR}/generated/lvl13_export_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${EBELGE_CATALOG_FILE}" ]; then
  echo "HATA ❌ ebelge catalog yok: ${EBELGE_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${EXPORT_CATALOG_FILE}" ]; then
  echo "HATA ❌ export catalog yok: ${EXPORT_CATALOG_FILE}"
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
  EBELGE_EFATURA_ENABLED
  EBELGE_EARSIV_ENABLED
  EBELGE_EADISYON_ENABLED
  EBELGE_STATUS_SYNC_MODE
  EBELGE_RETRY_MAX
  EBELGE_CANCEL_FLOW
  EBELGE_ERROR_MODE
  EBELGE_TEST_PROFILE
  EXPORT_LOGO_ENABLED
  EXPORT_MIKRO_ENABLED
  EXPORT_ZIRVE_ENABLED
  EXPORT_ETA_ENABLED
  EXPORT_VALIDATION_MODE
  EXPORT_BATCH_LIMIT
  EXPORT_TEST_PROFILE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__EBELGE_EFATURA_ENABLED__|${EBELGE_EFATURA_ENABLED}|g" \
  -e "s|__EBELGE_EARSIV_ENABLED__|${EBELGE_EARSIV_ENABLED}|g" \
  -e "s|__EBELGE_EADISYON_ENABLED__|${EBELGE_EADISYON_ENABLED}|g" \
  -e "s|__EBELGE_STATUS_SYNC_MODE__|${EBELGE_STATUS_SYNC_MODE}|g" \
  -e "s|__EBELGE_RETRY_MAX__|${EBELGE_RETRY_MAX}|g" \
  -e "s|__EBELGE_CANCEL_FLOW__|${EBELGE_CANCEL_FLOW}|g" \
  -e "s|__EBELGE_ERROR_MODE__|${EBELGE_ERROR_MODE}|g" \
  -e "s|__EBELGE_TEST_PROFILE__|${EBELGE_TEST_PROFILE}|g" \
  -e "s|__EXPORT_LOGO_ENABLED__|${EXPORT_LOGO_ENABLED}|g" \
  -e "s|__EXPORT_MIKRO_ENABLED__|${EXPORT_MIKRO_ENABLED}|g" \
  -e "s|__EXPORT_ZIRVE_ENABLED__|${EXPORT_ZIRVE_ENABLED}|g" \
  -e "s|__EXPORT_ETA_ENABLED__|${EXPORT_ETA_ENABLED}|g" \
  -e "s|__EXPORT_VALIDATION_MODE__|${EXPORT_VALIDATION_MODE}|g" \
  -e "s|__EXPORT_BATCH_LIMIT__|${EXPORT_BATCH_LIMIT}|g" \
  -e "s|__EXPORT_TEST_PROFILE__|${EXPORT_TEST_PROFILE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<EBELGESUMMARY > "${EBELGE_SUMMARY_FILE}"
# LVL13 e-Belge Summary

- e-Fatura enabled: ${EBELGE_EFATURA_ENABLED}
- e-Arsiv enabled: ${EBELGE_EARSIV_ENABLED}
- e-Adisyon enabled: ${EBELGE_EADISYON_ENABLED}
- Status sync mode: ${EBELGE_STATUS_SYNC_MODE}
- Retry max: ${EBELGE_RETRY_MAX}
- Cancel flow: ${EBELGE_CANCEL_FLOW}
- Error mode: ${EBELGE_ERROR_MODE}
- Test profile: ${EBELGE_TEST_PROFILE}
EBELGESUMMARY

cat <<EXPORTSUMMARY > "${EXPORT_SUMMARY_FILE}"
# LVL13 Export Summary

- Logo enabled: ${EXPORT_LOGO_ENABLED}
- Mikro enabled: ${EXPORT_MIKRO_ENABLED}
- Zirve enabled: ${EXPORT_ZIRVE_ENABLED}
- ETA enabled: ${EXPORT_ETA_ENABLED}
- Validation mode: ${EXPORT_VALIDATION_MODE}
- Batch limit: ${EXPORT_BATCH_LIMIT}
- Test profile: ${EXPORT_TEST_PROFILE}
EXPORTSUMMARY

echo "OK ✅ generated ebelge/export rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated ebelge summary hazir: ${EBELGE_SUMMARY_FILE}"
echo "OK ✅ generated export summary hazir: ${EXPORT_SUMMARY_FILE}"
