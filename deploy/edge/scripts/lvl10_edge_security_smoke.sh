#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOMAIN_ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_domains.env.example}"
SECURITY_ENV_FILE="${2:-${ROOT_DIR}/deploy/edge/env/lvl10_edge_security.env.example}"

RENDER_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/render_edge_config.sh"
INSTALL_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/install_certbot_renew_foundation.sh"
CERTBOT_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/certbot_renew.sh"

EDGE_OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_edge.conf"
CDN_OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf"
SERVICE_FILE="${ROOT_DIR}/deploy/edge/systemd/generated/pix2pi-cert-renew.service"
TIMER_FILE="${ROOT_DIR}/deploy/edge/systemd/generated/pix2pi-cert-renew.timer"

echo "===== LVL10 EDGE SECURITY SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${DOMAIN_ENV_FILE}" "${SECURITY_ENV_FILE}"
bash "${INSTALL_SCRIPT}" "${SECURITY_ENV_FILE}"

grep -q 'limit_req_zone \$binary_remote_addr zone=pix2pi_edge:' "${EDGE_OUTPUT_FILE}"
echo "OK ✅ rate limit zone render edildi"

grep -q 'limit_req zone=pix2pi_edge burst=' "${EDGE_OUTPUT_FILE}"
echo "OK ✅ rate limit rule render edildi"

grep -q 'pix2pi_waf_foundation.conf;' "${EDGE_OUTPUT_FILE}"
echo "OK ✅ waf include render edildi"

grep -q 'pix2pi_cdn_foundation.conf;' "${EDGE_OUTPUT_FILE}"
echo "OK ✅ cdn include render edildi"

grep -q 'location \^~ /.well-known/acme-challenge/' "${EDGE_OUTPUT_FILE}"
echo "OK ✅ acme challenge route render edildi"

grep -q 'set_real_ip_from' "${CDN_OUTPUT_FILE}"
echo "OK ✅ trusted proxy render edildi"

grep -q 'certbot renew --quiet --deploy-hook "systemctl reload nginx"' "${CERTBOT_SCRIPT}"
echo "OK ✅ cert renew komutu hazir"

grep -q 'ExecStart=.*certbot_renew.sh' "${SERVICE_FILE}"
echo "OK ✅ cert renew service hazir"

grep -q 'OnCalendar=' "${TIMER_FILE}"
echo "OK ✅ cert renew timer hazir"

echo "===== LVL10 EDGE SECURITY SMOKE TAMAM ====="
