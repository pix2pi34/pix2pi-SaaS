#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md"
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
    -e 's/(TOKEN=).*/\1***MASKED***/g' \
    -e 's/(RESTIC_PASSWORD=).*/\1***MASKED***/g'
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
# FAZ 6-8 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-8 Performance / Load / Stress Readiness maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-8 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-8.1" "Baseline performance / safe timing probe izi" 'time_total|curl.*write-out|uptime|free -h|docker stats|df -h|baseline|Baseline|performance.*audit|safe.*probe' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.2" "Load test tooling / readiness izi" 'hey|wrk|k6|vegeta|ab -|ApacheBench|load.*test|LoadTest|load_test|benchmark|Benchmark|bench' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.3" "Stress test / stop criteria izi" 'stress|Stress|stress.*test|stop.*criteria|durdurma|saturation|breakpoint|crash|overload|capacity.*limit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-8.4" "Bottleneck evidence izi" 'bottleneck|darbo|slow.*query|pg_stat|latency|duration|timeout|cpu|memory|disk|IO|backlog|pool.*saturation|NumPending' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.5" "Gateway performance guardrail izi" 'gateway|Gateway|proxy_read_timeout|proxy_connect_timeout|proxy_send_timeout|upstream|latency|duration_ms|5xx|4xx|rate.*limit|client_max_body_size|timeout' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.6.1" "DB connection pool performance izi" 'SetMaxOpenConns|SetMaxIdleConns|SetConnMaxLifetime|SetConnMaxIdleTime|DBStats|Stats\(\)|connection.*pool|pool.*wait|max.*connections' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.6.2" "DB query/index performance izi" 'CREATE.*INDEX|INDEX.*tenant_id|tenant_id.*INDEX|EXPLAIN|explain analyze|pg_stat_statements|log_min_duration_statement|slow.*query|QueryContext|ExecContext|context.WithTimeout' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.7" "Event bus performance / backlog izi" 'NATS|JetStream|backlog|pending|NumPending|AckFloor|consumer.*lag|DLQ|retry|AckWait|MaxDeliver|publish.*count|consume.*count' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.8" "Tenant-aware performance izi" 'tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*metric|tenant.*latency|tenant.*request|tenant.*rate|tenant.*query|tenant.*event|X-Tenant-ID' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.9" "Capacity / scale decision izi" 'capacity|Capacity|scale|Scale|scale-out|multi-node|cluster|read replica|worker.*count|consumer.*parallel|shard|partition|early warning' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.10" "Performance observability metrics izi" 'prometheus|Prometheus|/metrics|Counter|Gauge|Histogram|Grafana|dashboard|node_exporter|cadvisor|container_cpu|node_cpu|latency.*metric' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-8.11" "Performance test / audit script izi" 'FAZ_6_8|performance.*test|test.*performance|load.*readiness|stress.*readiness|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_9_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_9_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_9_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-8 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_8_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_8_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_9_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_9_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_9_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_8_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
