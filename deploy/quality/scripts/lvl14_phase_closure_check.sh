#!/usr/bin/env bash
set -euo pipefail

QUALITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUMMARY_ENV_FILE="${QUALITY_DIR}/generated/lvl14_phase_closure_summary.env"
REPORT_FILE="${QUALITY_DIR}/generated/lvl14_phase_closure_report.md"

TEST_CONTRACT_SCRIPT="${QUALITY_DIR}/scripts/lvl14_test_contract_smoke.sh"
E2E_SECURITY_SCRIPT="${QUALITY_DIR}/scripts/lvl14_e2e_security_smoke.sh"
PERF_RELEASE_SCRIPT="${QUALITY_DIR}/scripts/lvl14_performance_release_smoke.sh"

REQUIRED_FILES=(
  "${QUALITY_DIR}/generated/lvl14_test_contract_rules.yaml"
  "${QUALITY_DIR}/generated/lvl14_test_inventory_summary.md"
  "${QUALITY_DIR}/generated/lvl14_contract_gate_summary.md"
  "${QUALITY_DIR}/generated/lvl14_e2e_security_rules.yaml"
  "${QUALITY_DIR}/generated/lvl14_e2e_summary.md"
  "${QUALITY_DIR}/generated/lvl14_security_regression_summary.md"
  "${QUALITY_DIR}/generated/lvl14_performance_release_rules.yaml"
  "${QUALITY_DIR}/generated/lvl14_performance_summary.md"
  "${QUALITY_DIR}/generated/lvl14_release_readiness_summary.md"
)

echo "===== LVL14 PHASE CLOSURE CHECK BASLIYOR ====="

bash "${TEST_CONTRACT_SCRIPT}"
echo "OK ✅ quality gates smoke gecti"

bash "${E2E_SECURITY_SCRIPT}"
echo "OK ✅ kritik senaryolar ve security regression smoke gecti"

bash "${PERF_RELEASE_SCRIPT}"
echo "OK ✅ performance / release smoke gecti"

TEST_CONTRACT_READY=true
E2E_SECURITY_READY=true
PERF_RELEASE_READY=true

for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "${f}" ]; then
    echo "HATA ❌ eksik dosya: ${f}"
    case "${f}" in
      *test_contract*|*test_inventory*|*contract_gate*) TEST_CONTRACT_READY=false ;;
      *e2e*|*security_regression*) E2E_SECURITY_READY=false ;;
      *performance_release*|*performance_summary*|*release_readiness_summary*) PERF_RELEASE_READY=false ;;
    esac
  else
    echo "OK ✅ dosya var: ${f}"
  fi
done

PHASE_STATUS="READY"

if [ "${TEST_CONTRACT_READY}" != "true" ] || \
   [ "${E2E_SECURITY_READY}" != "true" ] || \
   [ "${PERF_RELEASE_READY}" != "true" ]; then
  PHASE_STATUS="BLOCKED"
fi

cat <<SUMMARY > "${SUMMARY_ENV_FILE}"
TEST_CONTRACT_READY=${TEST_CONTRACT_READY}
E2E_SECURITY_READY=${E2E_SECURITY_READY}
PERF_RELEASE_READY=${PERF_RELEASE_READY}
PHASE_STATUS=${PHASE_STATUS}
SUMMARY

cat <<REPORT > "${REPORT_FILE}"
# LVL14 Phase Closure Report

- TEST_CONTRACT_READY=${TEST_CONTRACT_READY}
- E2E_SECURITY_READY=${E2E_SECURITY_READY}
- PERF_RELEASE_READY=${PERF_RELEASE_READY}
- PHASE_STATUS=${PHASE_STATUS}

## 14.7 Checklist
- 14.7.1 quality gates green => ${TEST_CONTRACT_READY}
- 14.7.2 kritik senaryolar green => ${E2E_SECURITY_READY}
- 14.7.3 guvenlik regresyonlari green => ${E2E_SECURITY_READY}
- 14.7.4 performans / reliability gate green => ${PERF_RELEASE_READY}
- 14.7.5 final production readiness => ${PHASE_STATUS}
REPORT

if [ "${PHASE_STATUS}" != "READY" ]; then
  echo "HATA ❌ LVL14 phase closure blocked"
  echo "HATA ❌ rapor: ${REPORT_FILE}"
  exit 1
fi

echo "OK ✅ lvl14 phase closure ready"
echo "OK ✅ summary: ${SUMMARY_ENV_FILE}"
echo "OK ✅ rapor: ${REPORT_FILE}"
