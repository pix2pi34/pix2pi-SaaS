#!/usr/bin/env bash
set -euo pipefail

QUALITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${QUALITY_DIR}/env/lvl14_test_contract.env.example}"
TEST_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_test_inventory_catalog.yaml"
CONTRACT_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_contract_gate_catalog.yaml"
TEMPLATE_FILE="${QUALITY_DIR}/config/lvl14_test_contract_rules.yaml.template"
OUTPUT_FILE="${QUALITY_DIR}/generated/lvl14_test_contract_rules.yaml"
TEST_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_test_inventory_summary.md"
CONTRACT_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_contract_gate_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${TEST_CATALOG_FILE}" ]; then
  echo "HATA ❌ test inventory catalog yok: ${TEST_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${CONTRACT_CATALOG_FILE}" ]; then
  echo "HATA ❌ contract gate catalog yok: ${CONTRACT_CATALOG_FILE}"
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
  QUALITY_BASELINE_MODE
  QUALITY_MIN_UNIT_COVERAGE_PERCENT
  QUALITY_MIN_INTEGRATION_COVERAGE_PERCENT
  QUALITY_MIN_E2E_COVERAGE_PERCENT
  QUALITY_OWNER_MODE
  QUALITY_MISSING_TEST_POLICY
  CONTRACT_API_GATE_ENABLED
  CONTRACT_EVENT_GATE_ENABLED
  CONTRACT_ENVELOPE_GATE_ENABLED
  CONTRACT_INTEGRATION_DEP_GATE_ENABLED
  CONTRACT_BACKWARD_COMPAT_ENABLED
  CONTRACT_TEST_PROFILE
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__QUALITY_BASELINE_MODE__|${QUALITY_BASELINE_MODE}|g" \
  -e "s|__QUALITY_MIN_UNIT_COVERAGE_PERCENT__|${QUALITY_MIN_UNIT_COVERAGE_PERCENT}|g" \
  -e "s|__QUALITY_MIN_INTEGRATION_COVERAGE_PERCENT__|${QUALITY_MIN_INTEGRATION_COVERAGE_PERCENT}|g" \
  -e "s|__QUALITY_MIN_E2E_COVERAGE_PERCENT__|${QUALITY_MIN_E2E_COVERAGE_PERCENT}|g" \
  -e "s|__QUALITY_OWNER_MODE__|${QUALITY_OWNER_MODE}|g" \
  -e "s|__QUALITY_MISSING_TEST_POLICY__|${QUALITY_MISSING_TEST_POLICY}|g" \
  -e "s|__CONTRACT_API_GATE_ENABLED__|${CONTRACT_API_GATE_ENABLED}|g" \
  -e "s|__CONTRACT_EVENT_GATE_ENABLED__|${CONTRACT_EVENT_GATE_ENABLED}|g" \
  -e "s|__CONTRACT_ENVELOPE_GATE_ENABLED__|${CONTRACT_ENVELOPE_GATE_ENABLED}|g" \
  -e "s|__CONTRACT_INTEGRATION_DEP_GATE_ENABLED__|${CONTRACT_INTEGRATION_DEP_GATE_ENABLED}|g" \
  -e "s|__CONTRACT_BACKWARD_COMPAT_ENABLED__|${CONTRACT_BACKWARD_COMPAT_ENABLED}|g" \
  -e "s|__CONTRACT_TEST_PROFILE__|${CONTRACT_TEST_PROFILE}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<TESTSUMMARY > "${TEST_SUMMARY_FILE}"
# LVL14 Test Inventory Summary

- Baseline mode: ${QUALITY_BASELINE_MODE}
- Min unit coverage: ${QUALITY_MIN_UNIT_COVERAGE_PERCENT}%
- Min integration coverage: ${QUALITY_MIN_INTEGRATION_COVERAGE_PERCENT}%
- Min e2e coverage: ${QUALITY_MIN_E2E_COVERAGE_PERCENT}%
- Owner mode: ${QUALITY_OWNER_MODE}
- Missing test policy: ${QUALITY_MISSING_TEST_POLICY}
TESTSUMMARY

cat <<CONTRACTSUMMARY > "${CONTRACT_SUMMARY_FILE}"
# LVL14 Contract Gate Summary

- API gate enabled: ${CONTRACT_API_GATE_ENABLED}
- Event gate enabled: ${CONTRACT_EVENT_GATE_ENABLED}
- Envelope gate enabled: ${CONTRACT_ENVELOPE_GATE_ENABLED}
- Integration dependency gate enabled: ${CONTRACT_INTEGRATION_DEP_GATE_ENABLED}
- Backward compatibility enabled: ${CONTRACT_BACKWARD_COMPAT_ENABLED}
- Test profile: ${CONTRACT_TEST_PROFILE}
CONTRACTSUMMARY

echo "OK ✅ generated test/contract rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated test inventory summary hazir: ${TEST_SUMMARY_FILE}"
echo "OK ✅ generated contract gate summary hazir: ${CONTRACT_SUMMARY_FILE}"
