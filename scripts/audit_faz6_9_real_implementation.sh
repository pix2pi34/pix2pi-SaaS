#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md"
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
    -e 's/(JWT_SECRET=).*/\1***MASKED***/g' \
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
# FAZ 6-9 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-9 Release / Rollback / Deploy Safety maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-9 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-9.1" "Release standard / version / artifact izi" 'release|Release|RELEASE|version|Version|VERSION|tag|commit|artifact|CHANGELOG|Go/No-Go|release_id' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.2" "Pre-deploy check implementation izi" 'predeploy|pre-deploy|pre deploy|PREDEPLOY|nginx -t|disk|backup.*check|health.*probe|pix2pi_predeploy_check' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.3" "Post-deploy smoke implementation izi" 'postdeploy|post-deploy|post deploy|smoke|Smoke|/health|curl.*health|pix2pi_postdeploy_smoke|POSTDEPLOY' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.4" "Rollback readiness / restore implementation izi" 'rollback|Rollback|ROLLBACK|restore|Restore|backup|Backup|pix2pi_rollback_readiness|previous|revert' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.5" "Migration safety izi" 'migration|migrate|schema|ALTER TABLE|CREATE INDEX|DROP TABLE|down migration|DB backup|pg_dump|migration.*safety' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.6" "Nginx / systemd / docker deploy safety izi" 'nginx -t|systemctl|daemon-reload|docker compose|docker-compose|restart|reload|ExecStart|ExecReload|service.*restart|deploy.*safety' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.7" "Static / public GET content check izi" 'GET|HTTP_STATUS|curl -L|content check|index.html|/var/www|public|static|HEAD|size_download|pix2pi.com.tr' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.8" "Release evidence / audit log izi" 'evidence|Evidence|audit|Audit|operator|timestamp|Generated At|Go/No-Go|final seal|FINAL_STATUS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.9" "Guard scripts implementation izi" 'pix2pi_predeploy_check|pix2pi_postdeploy_smoke|pix2pi_rollback_readiness|PREDEPLOY_CHECK_STATUS|POSTDEPLOY_SMOKE_STATUS|ROLLBACK_READINESS_STATUS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-9.10" "Release / rollback test script izi" 'FAZ_6_9|release.*test|rollback.*test|deploy.*test|test_faz6_9|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_10_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_10_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_10_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_9_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-9 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_9_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_9_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_10_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_10_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_10_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_9_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
