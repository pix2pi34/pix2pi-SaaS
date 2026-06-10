#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_ROLLBACK_READINESS_EVIDENCE.md"
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
# FAZ 6-9 Rollback Readiness Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  

Bu script rollback calistirmaz. Sadece rollback icin gerekli kanit ve geri donus kaynaklarini listeler.

FAZ_6_9_ROLLBACK_READINESS=STARTED ✅

---

EOF2

echo "===== PIX2PI ROLLBACK READINESS BASLADI ====="

write_cmd_block "6-9.4.1 Git Rollback Points" bash -lc "git log --oneline -n 10 2>/dev/null || true; echo; git tag --sort=-creatordate 2>/dev/null | head -n 20 || true"

write_cmd_block "6-9.4.2 Backup Directories" bash -lc "find backups -maxdepth 2 -type d 2>/dev/null | sort | tail -n 40 || true"

write_cmd_block "6-9.4.3 Config Backup Candidates" bash -lc "for p in /etc/nginx /etc/systemd/system /etc/pix2pi /opt/pix2pi/orchestrator/env; do if [ -e \"\$p\" ]; then echo ===== \$p =====; find \"\$p\" -maxdepth 3 -type f 2>/dev/null | head -n 80; fi; done"

write_cmd_block "6-9.4.4 DB Backup / Restore Candidates" bash -lc "find . /root/pix2pi-restic-repo /var/backups -maxdepth 5 -type f 2>/dev/null | grep -Ei 'backup|restore|restic|pg_dump|pg_restore|snapshot|dump|sql' | head -n 160 || true"

write_cmd_block "6-9.4.5 Public Static Backup Candidates" bash -lc "find /var/www /opt/pix2pi -maxdepth 5 -type f 2>/dev/null | grep -Ei 'index.html|backup|release|rollback|faz4d|public|static' | head -n 160 || true"

write_cmd_block "6-9.4.6 Rollback Smoke Command Reminder" bash -lc "echo 'After rollback: run scripts/pix2pi_postdeploy_smoke.sh'; echo 'Before nginx reload: nginx -t'; echo 'Before DB restore: confirm backup and target environment'"

{
  echo
  echo "## Rollback Readiness Final Seal"
  echo
  echo '```text'
  echo "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅"
  echo "ROLLBACK_DESTRUCTIVE_ACTION=NO ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_9_ROLLBACK_READINESS_STATUS=COMPLETE ✅"
echo "ROLLBACK_DESTRUCTIVE_ACTION=NO ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
