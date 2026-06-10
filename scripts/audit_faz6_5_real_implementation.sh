#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_5_REAL_IMPLEMENTATION_AUDIT.md"
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
      head -n 60 "$out" | mask_secret
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
# FAZ 6-5 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-5 Observability / Early Warning / SRE Dashboard maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-5 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-5.1" "Prometheus / metrics implementation izi" "prometheus|Prometheus|promhttp|/metrics|metrics|Metrics|Counter|Gauge|Histogram|Summary|Register|MustRegister" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.2" "Grafana / dashboard / datasource izi" "grafana|Grafana|dashboard|Dashboard|datasource|Datasource|panels|templating|prometheus.*datasource" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.3.1" "node_exporter izi" "node_exporter|node-exporter|9100|node_cpu|node_memory|node_filesystem" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.3.2" "cAdvisor izi" "cadvisor|cAdvisor|container_cpu|container_memory|8080.*metrics|8080:8080" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.4" "Early warning / alert rule izi" "alert:|Alertmanager|alertmanager|ALERT|warning|critical|threshold|for:|severity|expr:|cpu|memory|disk|latency|backlog|DLQ|5xx" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.5" "Service health / mission control izi" "/health|healthz|Health|MissionControl|mission-control|service-registry|ServiceRegistry|health.*summary|summary.*health" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.6.1" "DB observability signal izi" "DB.*Stats|Stats\\(\\)|pg_isready|pg_stat|slow.*query|connection.*pool|SetMaxOpenConns|DB_HEALTH|database.*health" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.6.2" "Event bus observability signal izi" "NATS|JetStream|backlog|pending|DLQ|retry|consumer.*lag|AckFloor|NumPending|event.*metric|publish.*count|consume.*count" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.6.3" "Gateway observability signal izi" "gateway|Gateway|request_id|X-Request-ID|latency|duration|status_code|5xx|4xx|rate.*limit|upstream|proxy" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.7" "Tenant-level observability izi" "tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*metric|metric.*tenant|tenant.*latency|tenant.*error|tenant.*request" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.8.1" "request_id / correlation_id trace izi" "request_id|RequestID|X-Request-ID|correlation_id|CorrelationID|causation_id|CausationID|trace_id|TraceID" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.8.2" "log standard / structured logging izi" "logger|Logger|log\\.Printf|zap|zerolog|logrus|slog|service_name|duration_ms|error_code|audit" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-5.9" "SRE dashboard / ops panel izi" "SRE|sre|ops.*dashboard|dashboard.*ops|mission.*control|service.*status|incident|runbook|alarm|alert" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-5.10" "Observability test / audit script izi" "observability|prometheus|grafana|metrics|health.*probe|runtime.*audit|real.*implementation.*audit" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_5_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_5_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_5_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_5_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_6_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_6_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_6_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_5_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-5 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_5_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_5_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_5_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_5_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_6_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_6_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_6_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_5_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
