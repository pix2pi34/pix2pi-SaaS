#!/usr/bin/env bash
set -euo pipefail

QUALITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${QUALITY_DIR}/env/lvl14_e2e_security.env.example"
E2E_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_e2e_catalog.yaml"
SECURITY_CATALOG_FILE="${QUALITY_DIR}/config/lvl14_security_regression_catalog.yaml"
OUTPUT_FILE="${QUALITY_DIR}/generated/lvl14_e2e_security_rules.yaml"
E2E_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_e2e_summary.md"
SECURITY_SUMMARY_FILE="${QUALITY_DIR}/generated/lvl14_security_regression_summary.md"
RENDER_SCRIPT="${QUALITY_DIR}/scripts/render_lvl14_e2e_security.sh"

echo "===== LVL14 E2E + SECURITY SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'auth_tenant_flow:' "${E2E_CATALOG_FILE}"
echo "OK ✅ auth + tenant akisi var"

grep -q 'dashboard_monitoring_flow:' "${E2E_CATALOG_FILE}"
echo "OK ✅ dashboard + monitoring akisi var"

grep -q 'erp_accounting_flow:' "${E2E_CATALOG_FILE}"
echo "OK ✅ ERP muhasebe akisi var"

grep -q 'ebelge_export_flow:' "${E2E_CATALOG_FILE}"
echo "OK ✅ e-Belge + export akisi var"

grep -q 'payment_reconciliation_flow:' "${E2E_CATALOG_FILE}"
echo "OK ✅ odeme / mutabakat akisi var"

grep -q 'smoke_suite:' "${E2E_CATALOG_FILE}"
echo "OK ✅ E2E smoke suite var"

grep -q 'cross_tenant_regression:' "${SECURITY_CATALOG_FILE}"
echo "OK ✅ cross-tenant regression var"

grep -q 'auth_forbidden_regression:' "${SECURITY_CATALOG_FILE}"
echo "OK ✅ auth / forbidden regression var"

grep -q 'rate_limit_abuse_regression:' "${SECURITY_CATALOG_FILE}"
echo "OK ✅ rate limit / abuse regression var"

grep -q 'secret_config_regression:' "${SECURITY_CATALOG_FILE}"
echo "OK ✅ secret / config regression var"

grep -q 'audit_export_isolation_regression:' "${SECURITY_CATALOG_FILE}"
echo "OK ✅ audit / export isolation regression var"

grep -q 'security_suite:' "${SECURITY_CATALOG_FILE}"
echo "OK ✅ security regression suite var"

grep -q 'e2e_rules:' "${OUTPUT_FILE}"
echo "OK ✅ e2e rules render edildi"

grep -q 'security_rules:' "${OUTPUT_FILE}"
echo "OK ✅ security rules render edildi"

grep -q 'LVL14 E2E Summary' "${E2E_SUMMARY_FILE}"
echo "OK ✅ e2e summary olustu"

grep -q 'LVL14 Security Regression Summary' "${SECURITY_SUMMARY_FILE}"
echo "OK ✅ security regression summary olustu"

echo "===== LVL14 E2E + SECURITY SMOKE TAMAM ====="
