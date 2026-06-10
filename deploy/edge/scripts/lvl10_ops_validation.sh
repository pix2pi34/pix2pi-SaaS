#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

DOMAIN_ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_domains.env.example}"
SECURITY_ENV_FILE="${2:-${ROOT_DIR}/deploy/edge/env/lvl10_edge_security.env.example}"
OPS_ENV_FILE="${3:-${ROOT_DIR}/deploy/edge/env/lvl10_ops_validation.env.example}"

RENDER_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/render_edge_config.sh"
EDGE_OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_edge.conf"
CDN_OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_cdn_foundation.conf"
SERVICE_FILE="${ROOT_DIR}/deploy/edge/systemd/generated/pix2pi-cert-renew.service"
TIMER_FILE="${ROOT_DIR}/deploy/edge/systemd/generated/pix2pi-cert-renew.timer"

if [ ! -f "${DOMAIN_ENV_FILE}" ]; then
  echo "HATA ❌ domain env dosyasi yok: ${DOMAIN_ENV_FILE}"
  exit 1
fi

if [ ! -f "${SECURITY_ENV_FILE}" ]; then
  echo "HATA ❌ security env dosyasi yok: ${SECURITY_ENV_FILE}"
  exit 1
fi

if [ ! -f "${OPS_ENV_FILE}" ]; then
  echo "HATA ❌ ops validation env dosyasi yok: ${OPS_ENV_FILE}"
  exit 1
fi

set -a
source "${DOMAIN_ENV_FILE}"
source "${SECURITY_ENV_FILE}"
source "${OPS_ENV_FILE}"
set +a

OPS_REPORT_DIR="${OPS_REPORT_DIR:-deploy/edge/reports}"
REPORT_DIR_ABS="${ROOT_DIR}/${OPS_REPORT_DIR}"
mkdir -p "${REPORT_DIR_ABS}"

SUMMARY_FILE="${REPORT_DIR_ABS}/lvl10_ops_validation_summary.env"
REPORT_FILE="${REPORT_DIR_ABS}/lvl10_ops_validation_report.md"

FOUNDATION_PASS=true
DOMAIN_MATRIX_PASS=true
PUBLIC_PRIVATE_POLICY_PASS=true
TLS_POLICY_PASS=true
CERT_OPS_FOUNDATION_PASS=true
LIVE_CHECKS_STATUS="skipped"

echo "===== LVL10 OPS VALIDATION BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${DOMAIN_ENV_FILE}" "${SECURITY_ENV_FILE}"

check_file() {
  local path="$1"
  local label="$2"
  if [ -f "${path}" ]; then
    echo "OK ✅ ${label}"
  else
    echo "HATA ❌ ${label}"
    FOUNDATION_PASS=false
    return 1
  fi
}

check_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -q "${pattern}" "${file}"; then
    echo "OK ✅ ${label}"
  else
    echo "HATA ❌ ${label}"
    FOUNDATION_PASS=false
    return 1
  fi
}

check_file "${EDGE_OUTPUT_FILE}" "generated edge config var"
check_file "${CDN_OUTPUT_FILE}" "generated cdn config var"
check_file "${SERVICE_FILE}" "cert renew service var"
check_file "${TIMER_FILE}" "cert renew timer var"

check_grep "${EDGE_OUTPUT_FILE}" "server_name ${API_DOMAIN};" "api domain render edildi" || DOMAIN_MATRIX_PASS=false
check_grep "${EDGE_OUTPUT_FILE}" "server_name ${PANEL_DOMAIN};" "panel domain render edildi" || DOMAIN_MATRIX_PASS=false
check_grep "${EDGE_OUTPUT_FILE}" "server_name ${AUTH_DOMAIN};" "auth domain render edildi" || DOMAIN_MATRIX_PASS=false
check_grep "${EDGE_OUTPUT_FILE}" "server_name ${POS_DOMAIN};" "pos domain render edildi" || DOMAIN_MATRIX_PASS=false

check_grep "${EDGE_OUTPUT_FILE}" "location /internal/" "internal route deny policy var" || PUBLIC_PRIVATE_POLICY_PASS=false
check_grep "${EDGE_OUTPUT_FILE}" "location = /health" "health policy var" || PUBLIC_PRIVATE_POLICY_PASS=false
check_grep "${EDGE_OUTPUT_FILE}" "allow ${HEALTH_ALLOW_CIDR};" "health allowlist render edildi" || PUBLIC_PRIVATE_POLICY_PASS=false

check_grep "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_tls_policy.conf" "ssl_protocols TLSv1.2 TLSv1.3;" "tls policy var" || TLS_POLICY_PASS=false
check_grep "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_tls_policy.conf" "Strict-Transport-Security" "hsts var" || TLS_POLICY_PASS=false

check_grep "${SERVICE_FILE}" "ExecStart=.*certbot_renew.sh" "cert renew exec var" || CERT_OPS_FOUNDATION_PASS=false
check_grep "${TIMER_FILE}" "OnCalendar=" "cert renew timer var" || CERT_OPS_FOUNDATION_PASS=false

if [ "${ENABLE_LIVE_EDGE_CHECKS:-false}" = "true" ]; then
  LIVE_CHECKS_STATUS="pass"

  for domain in "${API_DOMAIN}" "${PANEL_DOMAIN}" "${AUTH_DOMAIN}" "${POS_DOMAIN}"; do
    if getent hosts "${domain}" >/dev/null 2>&1; then
      echo "OK ✅ dns resolve: ${domain}"
    else
      echo "HATA ❌ dns resolve: ${domain}"
      LIVE_CHECKS_STATUS="fail"
    fi
  done

  if [ "${EXPECT_HTTP_TO_HTTPS_REDIRECT:-false}" = "true" ]; then
    for domain in "${API_DOMAIN}" "${PANEL_DOMAIN}"; do
      HEADERS="$(curl -I -s --max-time 8 "http://${domain}" || true)"
      if printf "%s" "${HEADERS}" | grep -Eq 'HTTP/.* (301|308)' && printf "%s" "${HEADERS}" | grep -qi "Location: https://"; then
        echo "OK ✅ http->https redirect: ${domain}"
      else
        echo "HATA ❌ http->https redirect: ${domain}"
        LIVE_CHECKS_STATUS="fail"
      fi
    done
  fi

  if [ "${EXPECT_HTTPS_HANDSHAKE:-false}" = "true" ]; then
    for domain in "${API_DOMAIN}" "${PANEL_DOMAIN}"; do
      if echo | openssl s_client -servername "${domain}" -connect "${domain}:443" 2>/dev/null | grep -q "BEGIN CERTIFICATE"; then
        echo "OK ✅ https handshake: ${domain}"
      else
        echo "HATA ❌ https handshake: ${domain}"
        LIVE_CHECKS_STATUS="fail"
      fi
    done
  fi
fi

cat <<SUMMARY > "${SUMMARY_FILE}"
FOUNDATION_PASS=${FOUNDATION_PASS}
DOMAIN_MATRIX_PASS=${DOMAIN_MATRIX_PASS}
PUBLIC_PRIVATE_POLICY_PASS=${PUBLIC_PRIVATE_POLICY_PASS}
TLS_POLICY_PASS=${TLS_POLICY_PASS}
CERT_OPS_FOUNDATION_PASS=${CERT_OPS_FOUNDATION_PASS}
LIVE_CHECKS_STATUS=${LIVE_CHECKS_STATUS}
SUMMARY

cat <<REPORT > "${REPORT_FILE}"
# LVL10 Ops Validation Report

- FOUNDATION_PASS=${FOUNDATION_PASS}
- DOMAIN_MATRIX_PASS=${DOMAIN_MATRIX_PASS}
- PUBLIC_PRIVATE_POLICY_PASS=${PUBLIC_PRIVATE_POLICY_PASS}
- TLS_POLICY_PASS=${TLS_POLICY_PASS}
- CERT_OPS_FOUNDATION_PASS=${CERT_OPS_FOUNDATION_PASS}
- LIVE_CHECKS_STATUS=${LIVE_CHECKS_STATUS}

## Checked artifacts
- ${EDGE_OUTPUT_FILE}
- ${CDN_OUTPUT_FILE}
- ${SERVICE_FILE}
- ${TIMER_FILE}
REPORT

echo "OK ✅ ops validation summary hazir: ${SUMMARY_FILE}"
echo "OK ✅ ops validation raporu hazir: ${REPORT_FILE}"
echo "===== LVL10 OPS VALIDATION TAMAM ====="
