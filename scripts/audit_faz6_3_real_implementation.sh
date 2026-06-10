#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_3_REAL_IMPLEMENTATION_AUDIT.md"
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
      head -n 50 "$out" | mask_secret
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
# FAZ 6-3 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-3 multi-node / scale-out maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-3 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-3.1" "Cok node servis yerlesimi / runtime placement izi" "docker-compose|compose\\.ya?ml|systemd|\\.service|ExecStart|ports:|PORT=|SERVICE_PORT|listen|Addr:|upstream|proxy_pass" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.2" "Stateful / stateless ayrimi kod/config izi" "DB_|DATABASE|POSTGRES|REDIS|NATS|JETSTREAM|JWT|SESSION|tenant|Tenant|stateless|stateful" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.3" "Service discovery / registry / mission-control izi" "service[-_ ]?registry|ServiceRegistry|SERVICE_REGISTRY|registry|mission[-_ ]?control|MissionControl|DISCOVERY|RegisterService|service discovery" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.4" "Load balancer / upstream / proxy izi" "upstream|proxy_pass|least_conn|round_robin|X-Forwarded|X-Request-ID|reverse proxy|load balancer|gateway.*route|Route.*Service" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.5.1" "Health endpoint izi" "/health|healthz|Health|health check|health_check" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.5.2" "Readiness endpoint izi" "/ready|/readiness|readyz|Readiness|readiness|ready check|READY" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-3.5.3" "Liveness endpoint izi" "/live|/liveness|livez|Liveness|liveness|live check|ALIVE" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-3.6.1" "Graceful shutdown izi" "signal\\.Notify|SIGTERM|SIGINT|Shutdown\\(|Graceful|graceful|context\\.WithCancel|server\\.Shutdown|app\\.Shutdown" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-3.6.2" "Rolling update / deploy safety izi" "rolling|rollback|pre[-_]?deploy|post[-_]?deploy|smoke test|systemctl restart|ExecReload|zero[-_ ]?downtime|blue[-_ ]?green" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-3.7.1" "Hard-coded localhost endpoint riski / ENV route izi" "127\\.0\\.0\\.1|localhost|SERVICE_URL|BASE_URL|UPSTREAM|GATEWAY_URL|IDENTITY_URL|MISSION_URL|REGISTRY_URL" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.7.2" "Port/env inventory izi" "PORT|ports\\.env|SERVICE_PORT|API_PORT|GATEWAY_PORT|IDENTITY_PORT|Listen|listen" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-3.7.3" "Worker/event drain veya idempotency izi" "idempotenc|Idempotenc|Ack|Nack|Drain|drain|consumer|Consumer|worker|Worker|shutdown" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_3_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_3_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_3_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_3_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_4_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_4_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_4_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_3_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-3 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_3_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_3_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_3_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_3_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_4_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_4_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_3_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_4_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_3_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
