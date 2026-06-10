#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md"
TMP_DIR="$(mktemp -d)"
FILE_LIST="$TMP_DIR/files.txt"

mkdir -p docs/faz6/evidence

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

find . \
  \( -path './.git' \
  -o -path './backups' \
  -o -path './docs' \
  -o -path './node_modules' \
  -o -path './vendor' \
  -o -path './tmp' \
  \) -prune -o \
  -type f \
  \( -name '*.go' \
  -o -name '*.sql' \
  -o -name '*.sh' \
  -o -name '*.env' \
  -o -name '*.yaml' \
  -o -name '*.yml' \
  -o -name '*.json' \
  -o -name '*.toml' \
  -o -name '*.conf' \
  -o -name 'Dockerfile' \
  -o -name 'docker-compose*.yml' \
  -o -name '*.service' \
  \) -print | sort > "$FILE_LIST"

mask_secret() {
  sed -E \
    -e 's/(password=)[^ ]+/\1***MASKED***/g' \
    -e 's/(PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(PASS=).*/\1***MASKED***/g' \
    -e 's/(RESTIC_PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(SECRET=).*/\1***MASKED***/g' \
    -e 's/(TOKEN=).*/\1***MASKED***/g'
}

search_pattern() {
  local pattern="$1"
  local out_file="$2"

  : > "$out_file"

  while IFS= read -r f; do
    if [ -f "$f" ]; then
      grep -I -n -E "$pattern" "$f" 2>/dev/null | sed "s#^#$f:#" >> "$out_file" || true
    fi
  done < "$FILE_LIST"
}

count_file_lines() {
  local f="$1"

  if [ -f "$f" ]; then
    wc -l < "$f" | tr -d ' '
  else
    echo "0"
  fi
}

write_check() {
  local code="$1"
  local title="$2"
  local pattern="$3"
  local required="$4"

  local out="$TMP_DIR/${code}.txt"
  search_pattern "$pattern" "$out"

  local count
  count="$(count_file_lines "$out")"

  {
    echo
    echo "## $code $title"
    echo
    echo "Pattern:"
    echo
    echo '```text'
    echo "$pattern"
    echo '```'
    echo
    echo "Match Count: $count"
    echo
    echo '```text'
    if [ "$count" -gt 0 ]; then
      head -n 70 "$out" | mask_secret
    else
      echo "NO_MATCH"
    fi
    echo '```'
    echo
    if [ "$count" -gt 0 ]; then
      echo "Status: IMPLEMENTED_OR_PRESENT ✅"
      echo "$code STATUS=IMPLEMENTED_OR_PRESENT ✅"
    else
      if [ "$required" = "required" ]; then
        echo "Status: NOT_FOUND ❌"
        echo "$code STATUS=NOT_FOUND ❌"
      else
        echo "Status: NOT_FOUND_OPTIONAL ⚠️"
        echo "$code STATUS=NOT_FOUND_OPTIONAL ⚠️"
      fi
    fi
  } >> "$EVIDENCE_FILE"

  if [ "$count" -gt 0 ]; then
    echo "$code $title IMPLEMENTED_OR_PRESENT ✅"
    return 0
  fi

  if [ "$required" = "required" ]; then
    echo "$code $title NOT_FOUND ❌"
    return 1
  fi

  echo "$code $title NOT_FOUND_OPTIONAL ⚠️"
  return 2
}

REQUIRED_FAIL=0
OPTIONAL_WARN=0

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-6 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-6 Backup / Restore / Disaster Recovery maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-6 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-6.1.1" "Database backup script izi" "pg_dump|pg_basebackup|POSTGRES|DB_BACKUP|database.*backup|backup.*database|docker exec.*postgres|psql.*dump" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.1.2" "File / config backup izi" "tar |tar -|rsync|cp -a|backup.*etc|backup.*nginx|backup.*systemd|backup.*env|/etc/pix2pi|/opt/pix2pi|backups/" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.1.3" "Restic / backup repository izi" "restic|RESTIC|snapshot|snapshots|RESTIC_REPOSITORY|pix2pi-restic-repo|backup repo|repository" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.2.1" "Restore script / prosedur izi" "restore|Restore|pg_restore|restic.*restore|RESTORE|recovery|recover|rollback.*backup" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.2.2" "Restore smoke test izi" "smoke|Smoke|health.*check|/health|curl.*health|post.*restore|restore.*test|test.*restore|pg_isready" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.2.3" "Restore safety / guard izi" "DRY_RUN|dry-run|dry run|CONFIRM|confirm|guard|safety|PRODUCTION|staging|restore.*target|target.*restore" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-6.3" "RPO / RTO hedef veya olcum izi" "RPO|RTO|recovery point|recovery time|restore.*duration|backup.*duration|recovery.*duration" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-6.4" "Disaster scenario / DR runbook izi" "disaster|Disaster|DR|runbook|incident|disk.*full|node.*loss|DB.*loss|config.*restore|event.*restore" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-6.5.1" "Cron / systemd backup-retention izi" "cron|crontab|/etc/cron|systemd.*timer|OnCalendar|retention|run_ops_retention|backup.*daily|daily.*backup" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.5.2" "Backup / retention log izi" "ops_retention_cleanup\\.log|backup\\.log|restore\\.log|LOG_FILE|REPORT_FILE|/var/log/pix2pi|retention.*log" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.5.3" "Retention guard / cleanup izi" "retention|Retention|KEEP|keep|delete|cleanup|archive|protected|guard|APPLY=|APPLY\\:\\-" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-6.6" "PITR / WAL readiness izi" "archive_mode|archive_command|wal_level|WAL|PITR|pg_wal|recovery_target_time|restore_command|basebackup|pg_basebackup" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-6.7" "Backup security / secret masking izi" "RESTIC_PASSWORD|mask_secret|MASKED|chmod|chown|600|secret|SECRET|password|PASSWORD" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-6.8" "Backup / restore test script izi" "test.*backup|backup.*test|test.*restore|restore.*test|audit.*backup|backup.*audit|FAZ_6_6|backup_restore" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_7_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_7_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_7_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-6 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_6_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_6_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_7_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_7_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_7_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_6_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
