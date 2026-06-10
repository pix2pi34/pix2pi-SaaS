#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_12_RUNTIME_AUDIT.md"
mkdir -p docs/faz6/evidence

mask_secret() {
  sed -E \
    -e 's/(password=)[^ ]+/\1***MASKED***/g' \
    -e 's/(PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(JWT_SECRET=).*/\1***MASKED***/g' \
    -e 's/(SECRET=).*/\1***MASKED***/g' \
    -e 's/(TOKEN=).*/\1***MASKED***/g'
}

write_cmd_block() {
  local title="$1"
  shift

  {
    echo
    echo "## $title"
    echo
    echo '~~~text'
    "$@" 2>&1 | mask_secret || true
    echo '~~~'
  } >> "$EVIDENCE_FILE"
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-12 Runtime Audit Evidence

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit final production readiness gate icin runtime snapshot toplar.
Degisiklik yapmaz.

FAZ_6_12_RUNTIME_AUDIT=STARTED ✅

---

EOF2

echo "===== FAZ 6-12 RUNTIME AUDIT BASLADI ====="

write_cmd_block "6-12.1 Host / Kernel" uname -a

write_cmd_block "6-12.2 Docker Services Snapshot" bash -lc "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true"

write_cmd_block "6-12.3 Systemd / Nginx Snapshot" bash -lc "systemctl is-active nginx 2>/dev/null || true; nginx -t 2>&1 || true; systemctl list-units --type=service --all 2>/dev/null | grep -Ei 'pix2pi|gateway|identity|mission|registry|event|nginx|docker|prometheus|grafana' || true"

write_cmd_block "6-12.4 Safe Service Smoke" bash -lc "bash scripts/pix2pi_postdeploy_smoke.sh 2>&1 || true"

write_cmd_block "6-12.5 Edge Smoke" bash -lc "bash scripts/pix2pi_edge_http_smoke.sh 2>&1 || true"

write_cmd_block "6-12.6 Ops Console Probe" bash -lc "bash scripts/pix2pi_ops_console_probe.sh 2>&1 || true"

write_cmd_block "6-12.7 Final Gate Probe" bash -lc "bash scripts/pix2pi_faz6_final_gate_probe.sh 2>&1 || true"

write_cmd_block "6-12.8 Disk / Memory / Load" bash -lc "uptime; echo; free -h; echo; df -h"

write_cmd_block "6-12.9 Final Evidence Inventory" bash -lc "find docs/faz6/evidence -maxdepth 1 -type f | sort | sed -n '1,240p'"

{
  echo
  echo "## 6-12 Runtime Audit Final Seal"
  echo
  echo '~~~text'
  echo "FAZ_6_12_RUNTIME_AUDIT=COMPLETE ✅"
  echo '~~~'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_12_RUNTIME_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
