#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

DOMAIN_ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_domains.env.example}"
SECURITY_ENV_FILE="${2:-${ROOT_DIR}/deploy/edge/env/lvl10_edge_security.env.example}"
OPS_ENV_FILE="${3:-${ROOT_DIR}/deploy/edge/env/lvl10_ops_validation.env.example}"

OPS_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/lvl10_ops_validation.sh"

set -a
source "${OPS_ENV_FILE}"
set +a

OPS_REPORT_DIR="${OPS_REPORT_DIR:-deploy/edge/reports}"
REPORT_DIR_ABS="${ROOT_DIR}/${OPS_REPORT_DIR}"
mkdir -p "${REPORT_DIR_ABS}"

SUMMARY_FILE="${REPORT_DIR_ABS}/lvl10_ops_validation_summary.env"
PHASE_REPORT_FILE="${REPORT_DIR_ABS}/lvl10_phase_closure_report.md"

echo "===== LVL10 PHASE CLOSURE CHECK BASLIYOR ====="

bash "${OPS_SCRIPT}" "${DOMAIN_ENV_FILE}" "${SECURITY_ENV_FILE}" "${OPS_ENV_FILE}"

if [ ! -f "${SUMMARY_FILE}" ]; then
  echo "HATA ❌ summary dosyasi olusmadi: ${SUMMARY_FILE}"
  exit 1
fi

set -a
source "${SUMMARY_FILE}"
set +a

PHASE_STATUS="FOUNDATION_READY"

if [ "${FOUNDATION_PASS}" != "true" ]; then
  PHASE_STATUS="BLOCKED"
elif [ "${LIVE_CHECKS_STATUS}" = "fail" ]; then
  PHASE_STATUS="BLOCKED"
elif [ "${LIVE_CHECKS_STATUS}" = "pass" ]; then
  PHASE_STATUS="LIVE_READY"
fi

cat <<REPORT > "${PHASE_REPORT_FILE}"
# LVL10 Phase Closure Report

- PHASE_STATUS=${PHASE_STATUS}
- FOUNDATION_PASS=${FOUNDATION_PASS}
- DOMAIN_MATRIX_PASS=${DOMAIN_MATRIX_PASS}
- PUBLIC_PRIVATE_POLICY_PASS=${PUBLIC_PRIVATE_POLICY_PASS}
- TLS_POLICY_PASS=${TLS_POLICY_PASS}
- CERT_OPS_FOUNDATION_PASS=${CERT_OPS_FOUNDATION_PASS}
- LIVE_CHECKS_STATUS=${LIVE_CHECKS_STATUS}

## 10.7 Checklist
- 10.7.1 domain duzenli => ${DOMAIN_MATRIX_PASS}
- 10.7.2 subdomainler oturmus => ${DOMAIN_MATRIX_PASS}
- 10.7.3 SSL guvenli foundation hazir => ${TLS_POLICY_PASS}
- 10.7.4 reverse proxy standardi sabit => ${FOUNDATION_PASS}
- 10.7.5 public / private sinir net => ${PUBLIC_PRIVATE_POLICY_PASS}
- 10.7.6 edge guvenligi hazir => ${CERT_OPS_FOUNDATION_PASS}
REPORT

if [ "${PHASE_STATUS}" = "BLOCKED" ]; then
  echo "HATA ❌ phase closure blocked"
  echo "HATA ❌ rapor: ${PHASE_REPORT_FILE}"
  exit 1
fi

if [ "${PHASE_STATUS}" = "LIVE_READY" ]; then
  echo "OK ✅ phase closure live ready"
  echo "OK ✅ rapor: ${PHASE_REPORT_FILE}"
  exit 0
fi

echo "OK ✅ phase closure foundation ready"
echo "OK ✅ rapor: ${PHASE_REPORT_FILE}"
