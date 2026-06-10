#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_PREDEPLOY_CHECK_EVIDENCE.md"
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
    echo '```text'
    "$@" 2>&1 | mask_secret || true
    echo '```'
  } >> "$EVIDENCE_FILE"
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-9 Predeploy Check Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  

Bu script deploy yapmaz. Sadece deploy oncesi guvenli kontrol evidence uretir.

FAZ_6_9_PREDEPLOY_CHECK=STARTED ✅

---

EOF2

echo "===== PIX2PI PREDEPLOY CHECK BASLADI ====="

write_cmd_block "6-9.2.1 Git Status" bash -lc "git rev-parse --short HEAD 2>/dev/null || true; git status --short 2>/dev/null || true"

write_cmd_block "6-9.2.2 Disk / Memory" bash -lc "df -h; echo; free -h; echo; uptime"

write_cmd_block "6-9.2.3 Backup Directory Check" bash -lc "ls -ld backups docs/faz6/evidence 2>/dev/null || true; find backups -maxdepth 2 -type d 2>/dev/null | tail -n 20 || true"

write_cmd_block "6-9.2.4 Nginx Syntax Check" bash -lc "nginx -t 2>&1 || true"

write_cmd_block "6-9.2.5 Docker / Systemd Inventory" bash -lc "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true; echo; systemctl list-units --type=service --all 2>/dev/null | grep -Ei 'pix2pi|gateway|identity|mission|registry|event|nginx|docker' || true"

write_cmd_block "6-9.2.6 Env File Presence" bash -lc "for f in .env .env.production /etc/pix2pi/ports.env /opt/pix2pi/orchestrator/env/common.env; do if [ -f \"\$f\" ]; then echo OK ✅ \$f; ls -la \"\$f\"; else echo WARN ⚠️ missing \$f; fi; done"

write_cmd_block "6-9.2.7 Listening Ports" bash -lc "ss -lntp 2>/dev/null | grep -E ':80|:443|:9001|:9010|:9090|:3000|:9100|:8080|:4222|:8222|:5433|:6379' || true"

write_cmd_block "6-9.2.8 Health Timing Probe" bash -lc "
for url in \
  http://127.0.0.1:9001/health \
  http://127.0.0.1:9010/health \
  http://127.0.0.1:9090/-/ready \
  http://127.0.0.1:3000/api/health \
  http://127.0.0.1:8222/varz
do
  echo ===== \$url =====
  curl -o /dev/null -sS --max-time 4 -w 'http_code=%{http_code} time_total=%{time_total}\n' \"\$url\" || echo 'WARN ⚠️ probe failed'
done
"

{
  echo
  echo "## Predeploy Final Seal"
  echo
  echo '```text'
  echo "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅"
  echo "PREDEPLOY_DESTRUCTIVE_ACTION=NO ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_9_PREDEPLOY_CHECK_STATUS=COMPLETE ✅"
echo "PREDEPLOY_DESTRUCTIVE_ACTION=NO ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
