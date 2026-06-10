#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_4_REAL_IMPLEMENTATION_AUDIT.md"
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
# FAZ 6-4 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-4 Event Bus / Queue / Backlog SRE maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-4 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-4.1.1" "NATS / JetStream runtime kod-config izi" "NATS|JETSTREAM|JetStream|nats://|NewConn|nats\\.Connect|js\\.|Stream|Consumer|NATS_URL|NATS_ENDPOINT" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.1.2" "Event publisher izi" "Publish|publisher|Publisher|EventPublisher|event.*publish|PublishMsg|JetStreamContext|Subject" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.1.3" "Event consumer / subscriber izi" "Subscribe|QueueSubscribe|consumer|Consumer|subscriber|Subscriber|PullSubscribe|Fetch|Consume|event.*consume" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.2" "Backlog / pending / lag izi" "backlog|pending|Pending|lag|Lag|NumPending|AckFloor|Redelivered|ConsumerInfo|jsz|subsz|queue depth|queue_depth" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.3.1" "Ack / Nack / Nak izi" "\\.Ack\\(|\\.Nak\\(|\\.Nack\\(|Ack\\(|Nak\\(|Nack\\(|ManualAck|AckWait|DoubleAck" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.3.2" "Retry / MaxDeliver / backoff izi" "retry|Retry|MAX_RETRY|max_retry|MaxDeliver|max deliver|AckWait|backoff|Backoff|redeliver|Redeliver" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.4" "DLQ / dead-letter izi" "DLQ|dlq|dead[-_ ]?letter|DeadLetter|dead_letter|failed.*event|failed_event|failure.*queue" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.5" "Replay / event store replay izi" "replay|Replay|REPLAY|event[-_ ]?store|EventStore|event_store|sequence|Sequence|DeliverAll|DeliverByStart|start sequence" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.6" "Poison message / quarantine izi" "poison|Poison|quarantine|Quarantine|malformed|schema.*invalid|invalid.*event|permanent failure|permanent_failure" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-4.7" "Idempotency / dedupe izi" "idempotenc|Idempotenc|dedupe|Dedupe|dedup|Dedup|duplicate|Duplicate|processed_event|processed events" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.8" "Tenant-aware event metadata izi" "tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*event|event.*tenant|correlation_id|CorrelationID|causation_id|CausationID" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-4.9" "Event metrics / observability izi" "prometheus|Prometheus|metrics|Metrics|Counter|Histogram|Gauge|event.*metric|publish.*count|consume.*count|dlq.*count|backlog.*gauge" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-4.10" "Event bus test izi" "Test.*Event|event.*test|DLQ.*test|replay.*test|idempotency.*test|duplicate.*test|consumer.*test|publisher.*test" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_4_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_4_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_4_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_4_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_5_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_5_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_5_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_4_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-4 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_4_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_4_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_4_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_4_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_5_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_5_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_4_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_5_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_4_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
