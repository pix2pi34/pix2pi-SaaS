#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOMAIN_ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_domains.env.example}"
SECURITY_ENV_FILE="${2:-${ROOT_DIR}/deploy/edge/env/lvl10_edge_security.env.example}"

EDGE_TEMPLATE_FILE="${ROOT_DIR}/deploy/edge/nginx/templates/pix2pi_edge.conf.template"
CDN_TEMPLATE_FILE="${ROOT_DIR}/deploy/edge/nginx/templates/pix2pi_cdn_foundation.conf.template"

EDGE_OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_edge.conf"
CDN_OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf"

if [ ! -f "${DOMAIN_ENV_FILE}" ]; then
  echo "HATA ❌ domain env dosyasi yok: ${DOMAIN_ENV_FILE}"
  exit 1
fi

if [ ! -f "${SECURITY_ENV_FILE}" ]; then
  echo "HATA ❌ security env dosyasi yok: ${SECURITY_ENV_FILE}"
  exit 1
fi

if [ ! -f "${EDGE_TEMPLATE_FILE}" ]; then
  echo "HATA ❌ edge template dosyasi yok: ${EDGE_TEMPLATE_FILE}"
  exit 1
fi

if [ ! -f "${CDN_TEMPLATE_FILE}" ]; then
  echo "HATA ❌ cdn template dosyasi yok: ${CDN_TEMPLATE_FILE}"
  exit 1
fi

set -a
source "${DOMAIN_ENV_FILE}"
source "${SECURITY_ENV_FILE}"
set +a

REQUIRED_VARS=(
  ROOT_DOMAIN
  API_DOMAIN
  PANEL_DOMAIN
  AUTH_DOMAIN
  POS_DOMAIN
  API_UPSTREAM
  PANEL_UPSTREAM
  AUTH_UPSTREAM
  POS_UPSTREAM
  HEALTH_ALLOW_CIDR
  TRUSTED_PROXY_CIDR
  RATE_LIMIT_ZONE_SIZE
  RATE_LIMIT_RPS
  RATE_LIMIT_BURST
)

for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "HATA ❌ zorunlu degisken bos: ${v}"
    exit 1
  fi
done

sed \
  -e "s|__TRUSTED_PROXY_CIDR__|${TRUSTED_PROXY_CIDR}|g" \
  "${CDN_TEMPLATE_FILE}" > "${CDN_OUTPUT_FILE}"

sed \
  -e "s|__ROOT_DIR__|${ROOT_DIR}|g" \
  -e "s|__API_DOMAIN__|${API_DOMAIN}|g" \
  -e "s|__PANEL_DOMAIN__|${PANEL_DOMAIN}|g" \
  -e "s|__AUTH_DOMAIN__|${AUTH_DOMAIN}|g" \
  -e "s|__POS_DOMAIN__|${POS_DOMAIN}|g" \
  -e "s|__API_UPSTREAM__|${API_UPSTREAM}|g" \
  -e "s|__PANEL_UPSTREAM__|${PANEL_UPSTREAM}|g" \
  -e "s|__AUTH_UPSTREAM__|${AUTH_UPSTREAM}|g" \
  -e "s|__POS_UPSTREAM__|${POS_UPSTREAM}|g" \
  -e "s|__HEALTH_ALLOW_CIDR__|${HEALTH_ALLOW_CIDR}|g" \
  -e "s|__RATE_LIMIT_ZONE_SIZE__|${RATE_LIMIT_ZONE_SIZE}|g" \
  -e "s|__RATE_LIMIT_RPS__|${RATE_LIMIT_RPS}|g" \
  -e "s|__RATE_LIMIT_BURST__|${RATE_LIMIT_BURST}|g" \
  "${EDGE_TEMPLATE_FILE}" > "${EDGE_OUTPUT_FILE}"

echo "OK ✅ generated edge config hazir: ${EDGE_OUTPUT_FILE}"
echo "OK ✅ generated cdn foundation hazir: ${CDN_OUTPUT_FILE}"
