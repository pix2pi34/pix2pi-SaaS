#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_2_REAL_IMPLEMENTATION_AUDIT.md"
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
  -o -name '*.toml' \
  -o -name '*.conf' \
  -o -name 'Dockerfile' \
  -o -name 'docker-compose*.yml' \
  \) -print | sort > "$FILE_LIST"

mask_secret() {
  sed -E \
    -e 's/(password=)[^ ]+/\1***MASKED***/g' \
    -e 's/(PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(PASS=).*/\1***MASKED***/g' \
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
      head -n 40 "$out" | mask_secret
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
# FAZ 6-2 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-2'de yazilan DB-L8 maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

Onemli yorum:
- READINESS dokumani PASS olabilir.
- REAL IMPLEMENTATION ancak bu audit'te ilgili pattern'ler bulunursa kanitlanmis sayilir.
- NO_MATCH cikan maddeler "kodda henuz yok" kabul edilir.

---

EOF2

echo "===== FAZ 6-2 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-2.1.1" "DB_WRITE_DSN varlik/kullanim kontrolu" "DB_WRITE_DSN|WRITE_DSN|WriteDSN|writeDsn|write_dsn|DBWriteDSN" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.1.2" "DB_READ_DSN varlik/kullanim kontrolu" "DB_READ_DSN|READ_DSN|ReadDSN|readDsn|read_dsn|DBReadDSN" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.2" "Replica routing / read pool kod izi" "readPool|read_pool|Replica|replica|ReadDB|readDB|readerDB|ReaderDB|UseRead|RouteRead|routeRead" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.3.1" "Connection pool SetMaxOpenConns" "SetMaxOpenConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.3.2" "Connection pool SetMaxIdleConns" "SetMaxIdleConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.3.3" "Connection pool lifetime / idle time" "SetConnMaxLifetime|SetConnMaxIdleTime" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.3.4" "Query timeout / context timeout" "context.WithTimeout|context.WithDeadline|QueryContext|ExecContext|BeginTx" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.4.1" "SQL index migration var mi" "CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX|CREATE[[:space:]]+INDEX[[:space:]]+CONCURRENTLY" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.4.2" "tenant_id index izi var mi" "INDEX.*tenant_id|tenant_id.*INDEX|idx_.*tenant|tenant.*idx_" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.4.3" "slow query / pg_stat_statements izi var mi" "log_min_duration_statement|pg_stat_statements|slow[ _-]?query|auto_explain" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-2.5" "PITR / backup / restore script izi" "archive_mode|archive_command|wal_level|pg_basebackup|pg_dump|pg_restore|restic|restore" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-2.6" "Partition / shard gercek SQL veya routing izi" "PARTITION[[:space:]]+BY|CREATE[[:space:]]+TABLE.*PARTITION|pg_partman|shard|Shard|tenant.*route|route.*tenant" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-2.7" "DB observability metric / health izi" "pg_isready|db.*health|DB.*Health|Prometheus|prometheus|sql.DBStats|Stats\\(\\)" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_2_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_2_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_2_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_2_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_2_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_2_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  else
    echo "FAZ_6_2_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  fi

  echo "FAZ_6_2_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-2 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_2_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_2_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_2_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_2_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_2_REAL_IMPLEMENTATION_STATUS=PASS ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_2_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
else
  echo "FAZ_6_2_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
fi

echo "FAZ_6_2_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
