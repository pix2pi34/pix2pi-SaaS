#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SECURITY_ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_edge_security.env.example}"

if [ ! -f "${SECURITY_ENV_FILE}" ]; then
  echo "HATA ❌ security env dosyasi yok: ${SECURITY_ENV_FILE}"
  exit 1
fi

set -a
source "${SECURITY_ENV_FILE}"
set +a

if [ -z "${CERTBOT_EMAIL:-}" ]; then
  echo "HATA ❌ CERTBOT_EMAIL bos"
  exit 1
fi

echo "INFO ℹ️ certbot renew foundation basliyor"
echo "INFO ℹ️ email: ${CERTBOT_EMAIL}"
echo "INFO ℹ️ domains: ${CERTBOT_DOMAINS:-belirtilmedi}"

echo certbot renew --quiet --deploy-hook "systemctl reload nginx"
