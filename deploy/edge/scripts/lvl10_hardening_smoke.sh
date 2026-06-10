#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_domains.env.example}"
RENDER_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/render_edge_config.sh"
OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_edge.conf"

echo "===== LVL10 HARDENING SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

grep -q 'ssl_protocols TLSv1.2 TLSv1.3;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_tls_policy.conf"
echo "OK ✅ tls protocols hardening var"

grep -q 'Strict-Transport-Security "max-age=31536000; includeSubDomains" always;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_tls_policy.conf"
echo "OK ✅ hsts politikasi var"

grep -q 'client_max_body_size 10m;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_request_limits.conf"
echo "OK ✅ body size limiti var"

grep -q 'server_tokens off;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_request_limits.conf"
echo "OK ✅ server_tokens kapali"

grep -q 'proxy_next_upstream error timeout http_502 http_503 http_504;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_proxy_common.conf"
echo "OK ✅ upstream failover kurali var"

grep -q 'proxy_intercept_errors on;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_error_handling.conf"
echo "OK ✅ error intercept aktif"

grep -q 'log_format pix2pi_edge_main' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_logging.conf"
echo "OK ✅ log format standardi var"

grep -q 'include .*/pix2pi_tls_policy.conf;' "${OUTPUT_FILE}"
echo "OK ✅ generated config tls include aldi"

grep -q 'include .*/pix2pi_request_limits.conf;' "${OUTPUT_FILE}"
echo "OK ✅ generated config request limits include aldi"

grep -q 'include .*/pix2pi_proxy_common.conf;' "${OUTPUT_FILE}"
echo "OK ✅ generated config proxy common include aldi"

grep -q 'location /internal/' "${OUTPUT_FILE}"
echo "OK ✅ private route deny policy duruyor"

grep -q 'location = /health' "${OUTPUT_FILE}"
echo "OK ✅ health allowlist policy duruyor"

echo "===== LVL10 HARDENING SMOKE TAMAM ====="
