#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_domains.env.example}"
RENDER_SCRIPT="${ROOT_DIR}/deploy/edge/scripts/render_edge_config.sh"
OUTPUT_FILE="${ROOT_DIR}/deploy/edge/nginx/generated/pix2pi_edge.conf"

echo "===== LVL10 EDGE SMOKE BASLIYOR ====="

bash "${RENDER_SCRIPT}" "${ENV_FILE}"

source "${ENV_FILE}"

grep -q "server_name ${API_DOMAIN};" "${OUTPUT_FILE}"
echo "OK ✅ api domain render edildi"

grep -q "server_name ${PANEL_DOMAIN};" "${OUTPUT_FILE}"
echo "OK ✅ panel domain render edildi"

grep -q "server_name ${AUTH_DOMAIN};" "${OUTPUT_FILE}"
echo "OK ✅ auth domain render edildi"

grep -q "server_name ${POS_DOMAIN};" "${OUTPUT_FILE}"
echo "OK ✅ pos domain render edildi"

grep -q "location /internal/" "${OUTPUT_FILE}"
echo "OK ✅ internal route deny kuralı var"

grep -q "location = /health" "${OUTPUT_FILE}"
echo "OK ✅ health policy var"

grep -q "allow ${HEALTH_ALLOW_CIDR};" "${OUTPUT_FILE}"
echo "OK ✅ health allowlist render edildi"

grep -q 'add_header X-Frame-Options "SAMEORIGIN" always;' \
  "${ROOT_DIR}/deploy/edge/nginx/includes/pix2pi_security_headers.conf"
echo "OK ✅ security headers include hazir"

echo "===== LVL10 EDGE SMOKE TAMAM ====="
