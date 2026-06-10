#!/usr/bin/env bash
set -euo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-${PLATFORM_DIR}/env/lvl12_jobs_notifications.env.example}"
JOBS_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_jobs_catalog.yaml"
NOTIFY_CATALOG_FILE="${PLATFORM_DIR}/config/lvl12_notifications_catalog.yaml"
TEMPLATE_FILE="${PLATFORM_DIR}/config/lvl12_jobs_notifications_rules.yaml.template"
OUTPUT_FILE="${PLATFORM_DIR}/generated/lvl12_jobs_notifications_rules.yaml"
JOBS_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_jobs_summary.md"
NOTIFY_SUMMARY_FILE="${PLATFORM_DIR}/generated/lvl12_notifications_summary.md"

if [ ! -f "${ENV_FILE}" ]; then
  echo "HATA ❌ env dosyasi yok: ${ENV_FILE}"
  exit 1
fi

if [ ! -f "${JOBS_CATALOG_FILE}" ]; then
  echo "HATA ❌ jobs catalog yok: ${JOBS_CATALOG_FILE}"
  exit 1
fi

if [ ! -f "${NOTIFY_CATALOG_FILE}" ]; then
  echo "HATA ❌ notifications catalog yok: ${NOTIFY_CATALOG_FILE}"
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
  JOB_MAX_RETRY
  JOB_RETRY_BACKOFF_SECONDS
  JOB_IDEMPOTENCY_TTL_SECONDS
  JOB_AUDIT_RETENTION_DAYS
  JOB_TENANT_MODE
  JOB_DEFAULT_QUEUE
  NOTIFY_EMAIL_ENABLED
  NOTIFY_SMS_ENABLED
  NOTIFY_PUSH_ENABLED
  NOTIFY_WEBHOOK_ENABLED
  NOTIFY_WEBHOOK_MAX_RETRY
  NOTIFY_WEBHOOK_DLQ_ENABLED
  NOTIFY_DEFAULT_SEVERITY
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__JOB_DEFAULT_QUEUE__|${JOB_DEFAULT_QUEUE}|g" \
  -e "s|__JOB_MAX_RETRY__|${JOB_MAX_RETRY}|g" \
  -e "s|__JOB_RETRY_BACKOFF_SECONDS__|${JOB_RETRY_BACKOFF_SECONDS}|g" \
  -e "s|__JOB_IDEMPOTENCY_TTL_SECONDS__|${JOB_IDEMPOTENCY_TTL_SECONDS}|g" \
  -e "s|__JOB_AUDIT_RETENTION_DAYS__|${JOB_AUDIT_RETENTION_DAYS}|g" \
  -e "s|__JOB_TENANT_MODE__|${JOB_TENANT_MODE}|g" \
  -e "s|__NOTIFY_EMAIL_ENABLED__|${NOTIFY_EMAIL_ENABLED}|g" \
  -e "s|__NOTIFY_SMS_ENABLED__|${NOTIFY_SMS_ENABLED}|g" \
  -e "s|__NOTIFY_PUSH_ENABLED__|${NOTIFY_PUSH_ENABLED}|g" \
  -e "s|__NOTIFY_WEBHOOK_ENABLED__|${NOTIFY_WEBHOOK_ENABLED}|g" \
  -e "s|__NOTIFY_WEBHOOK_MAX_RETRY__|${NOTIFY_WEBHOOK_MAX_RETRY}|g" \
  -e "s|__NOTIFY_WEBHOOK_DLQ_ENABLED__|${NOTIFY_WEBHOOK_DLQ_ENABLED}|g" \
  -e "s|__NOTIFY_DEFAULT_SEVERITY__|${NOTIFY_DEFAULT_SEVERITY}|g" \
  "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"

cat <<JOBSUMMARY > "${JOBS_SUMMARY_FILE}"
# LVL12 Jobs Summary

- Default queue: ${JOB_DEFAULT_QUEUE}
- Max retry: ${JOB_MAX_RETRY}
- Retry backoff: ${JOB_RETRY_BACKOFF_SECONDS} sec
- Idempotency TTL: ${JOB_IDEMPOTENCY_TTL_SECONDS} sec
- Audit retention: ${JOB_AUDIT_RETENTION_DAYS} days
- Tenant mode: ${JOB_TENANT_MODE}
JOBSUMMARY

cat <<NOTIFYSUMMARY > "${NOTIFY_SUMMARY_FILE}"
# LVL12 Notifications Summary

- Email enabled: ${NOTIFY_EMAIL_ENABLED}
- SMS enabled: ${NOTIFY_SMS_ENABLED}
- Push enabled: ${NOTIFY_PUSH_ENABLED}
- Webhook enabled: ${NOTIFY_WEBHOOK_ENABLED}
- Webhook max retry: ${NOTIFY_WEBHOOK_MAX_RETRY}
- Webhook DLQ enabled: ${NOTIFY_WEBHOOK_DLQ_ENABLED}
- Default severity: ${NOTIFY_DEFAULT_SEVERITY}
NOTIFYSUMMARY

echo "OK ✅ generated jobs/notifications rules hazir: ${OUTPUT_FILE}"
echo "OK ✅ generated jobs summary hazir: ${JOBS_SUMMARY_FILE}"
echo "OK ✅ generated notifications summary hazir: ${NOTIFY_SUMMARY_FILE}"
