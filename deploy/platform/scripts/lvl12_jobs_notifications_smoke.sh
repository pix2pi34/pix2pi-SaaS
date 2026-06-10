#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PLATFORM_DIR}/env/lvl12_jobs_notifications.env.example"
JOBS_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_jobs_catalog.yaml"
NOTIFY_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_notifications_catalog.yaml"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_jobs_notifications_rules.yaml"
JOBS_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_jobs_summary.md"
NOTIFY_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_notifications_summary.md"
RENDER_SCRIPT="${PLATFORM_DIR}/scripts/render_lvl12_jobs_notifications.sh"

echo "===== LVL12 JOBS + NOTIFICATIONS SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'engine:' "${JOBS_CATALOG_FILE}"
echo "OK ✅ background job engine var"

grep -q 'retryable_jobs:' "${JOBS_CATALOG_FILE}"
echo "OK ✅ retryable jobs var"

grep -q 'idempotent_jobs:' "${JOBS_CATALOG_FILE}"
echo "OK ✅ idempotent jobs var"

grep -q 'tenant_aware_jobs:' "${JOBS_CATALOG_FILE}"
echo "OK ✅ tenant-aware jobs var"

grep -q 'audit_trail:' "${JOBS_CATALOG_FILE}"
echo "OK ✅ job audit trail var"

grep -q 'service:' "${NOTIFY_CATALOG_FILE}"
echo "OK ✅ notification service var"

grep -q 'mail_channel:' "${NOTIFY_CATALOG_FILE}"
echo "OK ✅ mail channel var"

grep -q 'sms_push_channel:' "${NOTIFY_CATALOG_FILE}"
echo "OK ✅ sms / push channel var"

grep -q 'webhook_delivery:' "${NOTIFY_CATALOG_FILE}"
echo "OK ✅ webhook delivery var"

grep -q 'webhook_retry_dlq:' "${NOTIFY_CATALOG_FILE}"
echo "OK ✅ webhook retry / DLQ var"

grep -q 'jobs_rules:' "${OUTPUT_FILE}"
echo "OK ✅ jobs rules render edildi"

grep -q 'notifications_rules:' "${OUTPUT_FILE}"
echo "OK ✅ notifications rules render edildi"

grep -q 'LVL12 Jobs Summary' "${JOBS_SUMMARY_FILE}"
echo "OK ✅ jobs summary olustu"

grep -q 'LVL12 Notifications Summary' "${NOTIFY_SUMMARY_FILE}"
echo "OK ✅ notifications summary olustu"

echo "===== LVL12 JOBS + NOTIFICATIONS SMOKE TAMAM ====="
