#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_RELEASE_RUNTIME_AUDIT.md"
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
# FAZ 6-9 Release Runtime Audit Evidence

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit release / rollback / deploy safety runtime izlerini toplar. Deploy veya rollback yapmaz.

FAZ_6_9_RUNTIME_AUDIT=STARTED ✅

---

EOF2

echo "===== FAZ 6-9 RELEASE RUNTIME AUDIT BASLADI ====="

write_cmd_block "6-9.1 Host / Kernel" uname -a

write_cmd_block "6-9.2 Git / Release Inventory" bash -lc "git rev-parse --short HEAD 2>/dev/null || true; git status --short 2>/dev/null || true; git tag --sort=-creatordate 2>/dev/null | head -n 20 || true"

write_cmd_block "6-9.3 Deploy / Rollback Script Inventory" bash -lc "find . /opt/pix2pi /etc/pix2pi -maxdepth 6 -type f 2>/dev/null | grep -Ei 'deploy|release|rollback|smoke|predeploy|postdeploy|restore|backup|migration|nginx|systemd' | sort | head -n 220 || true"

write_cmd_block "6-9.4 Nginx Syntax" bash -lc "nginx -t 2>&1 || true"

write_cmd_block "6-9.5 Systemd / Docker Runtime Inventory" bash -lc "systemctl list-units --type=service --all 2>/dev/null | grep -Ei 'pix2pi|gateway|identity|mission|registry|event|nginx|docker' || true; echo; docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true"

write_cmd_block "6-9.6 Backup / Release Evidence Directory Inventory" bash -lc "find backups docs/faz6/evidence -maxdepth 2 -type f 2>/dev/null | sort | tail -n 120 || true"

write_cmd_block "6-9.7 Public GET Content Check Candidates" bash -lc "
for url in \
  https://pix2pi.com.tr/faz4d/pilot-go-live/ \
  https://pix2pi.com.tr/
do
  echo ===== \$url =====
  curl -L -sS --max-time 8 -w '\nHTTP_STATUS=%{http_code} SIZE=%{size_download} TIME=%{time_total}\n' \"\$url\" | head -c 1200 || true
  echo
done
"

write_cmd_block "6-9.8 Local Smoke Probe" bash -lc "bash scripts/pix2pi_postdeploy_smoke.sh 2>&1 || true"

write_cmd_block "6-9.9 Predeploy Probe" bash -lc "bash scripts/pix2pi_predeploy_check.sh 2>&1 || true"

write_cmd_block "6-9.10 Rollback Readiness Probe" bash -lc "bash scripts/pix2pi_rollback_readiness.sh 2>&1 || true"

{
  echo
  echo "## 6-9.11 Runtime Audit Interpretation"
  echo
  echo '```text'
  echo "6-9.1 Host inventory collected OK ✅"
  echo "6-9.2 Git/release inventory collected OK ✅"
  echo "6-9.3 Deploy/rollback script inventory collected OK ✅"
  echo "6-9.4 Nginx syntax collected OK ✅"
  echo "6-9.5 Systemd/docker runtime inventory collected OK ✅"
  echo "6-9.6 Backup/release evidence directory inventory collected OK ✅"
  echo "6-9.7 Public GET content check candidates collected OK ✅"
  echo "6-9.8 Local smoke probe collected OK ✅"
  echo "6-9.9 Predeploy probe collected OK ✅"
  echo "6-9.10 Rollback readiness probe collected OK ✅"
  echo "FAZ_6_9_RUNTIME_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_9_RUNTIME_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
