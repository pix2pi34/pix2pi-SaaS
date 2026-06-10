#!/usr/bin/env bash
set -euo pipefail

QUALITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${QUALITY_DIR}/env/lvl14_test_contract.env.example"
TEST_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_test_inventory_catalog.yaml"
CONTRACT_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_contract_gate_catalog.yaml"
OUTPUT_FILE="${QUALITY_DIR}/generated/lvl14_test_contract_rules.yaml"
TEST_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_test_inventory_summary.md"
CONTRACT_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_contract_gate_summary.md"
RENDER_SCRIPT="${QUALITY_DIR}/scripts/render_lvl14_test_contract.sh"

echo "===== LVL14 TEST + CONTRACT SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'layers:' "${TEST_CATALOG_FILE}"
echo "OK ✅ test katmanlarinin envanteri var"

grep -q 'quality_ownership:' "${TEST_CATALOG_FILE}"
echo "OK ✅ quality ownership var"

grep -q 'missing_test_classes:' "${TEST_CATALOG_FILE}"
echo "OK ✅ eksik test siniflari listesi var"

grep -q 'baseline_quality:' "${TEST_CATALOG_FILE}"
echo "OK ✅ baseline kalite ozeti var"

grep -q 'api_contract_gate:' "${CONTRACT_CATALOG_FILE}"
echo "OK ✅ API contract gate var"

grep -q 'event_contract_gate:' "${CONTRACT_CATALOG_FILE}"
echo "OK ✅ event contract gate var"

grep -q 'envelope_error_gate:' "${CONTRACT_CATALOG_FILE}"
echo "OK ✅ envelope / error standard gate var"

grep -q 'integration_dependency_gate:' "${CONTRACT_CATALOG_FILE}"
echo "OK ✅ integration dependency gate var"

grep -q 'backward_compatibility_gate:' "${CONTRACT_CATALOG_FILE}"
echo "OK ✅ backward compatibility gate var"

grep -q 'test_rules:' "${OUTPUT_FILE}"
echo "OK ✅ test rules render edildi"

grep -q 'contract_rules:' "${OUTPUT_FILE}"
echo "OK ✅ contract rules render edildi"

grep -q 'LVL14 Test Inventory Summary' "${TEST_SUMMARY_FILE}"
echo "OK ✅ test inventory summary olustu"

grep -q 'LVL14 Contract Gate Summary' "${CONTRACT_SUMMARY_FILE}"
echo "OK ✅ contract gate summary olustu"

echo "===== LVL14 TEST + CONTRACT SMOKE TAMAM ====="
