#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SECURITY_ENV_FILE="${1:-${ROOT_DIR}/deploy/edge/env/lvl10_edge_security.env.example}"
OUTPUT_DIR="${ROOT_DIR}/deploy/edge/systemd/generated"

if [ ! -f "${SECURITY_ENV_FILE}" ]; then
  echo "HATA ❌ security env dosyasi yok: ${SECURITY_ENV_FILE}"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

set -a
source "${SECURITY_ENV_FILE}"
set +a

: "${CERT_RENEW_HOUR:=3}"
: "${CERT_RENEW_MINUTE:=15}"

cat <<SERVICE > "${OUTPUT_DIR}/pix2pi-cert-renew.service"
[Unit]
Description=Pix2pi Certbot Renew Foundation

[Service]
Type=oneshot
ExecStart=${ROOT_DIR}/deploy/edge/scripts/certbot_renew.sh ${SECURITY_ENV_FILE}
SERVICE

cat <<TIMER > "${OUTPUT_DIR}/pix2pi-cert-renew.timer"
[Unit]
Description=Run Pix2pi Certbot Renew Foundation

[Timer]
OnCalendar=*-*-* ${CERT_RENEW_HOUR}:${CERT_RENEW_MINUTE}:00
Persistent=true

[Install]
WantedBy=timers.target
TIMER

echo "OK ✅ generated service hazir: ${OUTPUT_DIR}/pix2pi-cert-renew.service"
echo "OK ✅ generated timer hazir: ${OUTPUT_DIR}/pix2pi-cert-renew.timer"
