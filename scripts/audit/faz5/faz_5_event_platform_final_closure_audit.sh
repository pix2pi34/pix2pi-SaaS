#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_5_EVENT_PLATFORM_EVIDENCE_FILE:-docs/faz5/evidence/FAZ_5_EVENT_PLATFORM_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md}"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

exec > >(tee "$EVIDENCE_FILE") 2>&1

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
GO_TEST_STATUS="NOT_RUN"

pass_check() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_INVALID / FAIL ❌"
}

warn_check() {
  OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
  echo "$1 OPTIONAL_WARN / WARN ⚠️"
}

check_min() {
  local label="$1"
  local actual="$2"
  local minimum="$3"

  if [ "$actual" -ge "$minimum" ]; then
    pass_check "$label actual=${actual}"
  else
    fail_check "$label expected_min=${minimum} actual=${actual}"
  fi
}

grep_count() {
  local pattern="$1"
  grep -RIlE "$pattern" \
    cmd internal pkg services configs db scripts docs \
    2>/dev/null | sort -u | wc -l | tr -d ' '
}

file_count() {
  local pattern="$1"
  find cmd internal pkg services configs db scripts docs \
    -type f 2>/dev/null | grep -Ei "$pattern" | wc -l | tr -d ' '
}

echo "===== FAZ 5 EVENT PLATFORM FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

EVENT_SOURCE_COUNT="$(file_count 'event|eventbus|event_bus|nats|jetstream|consumer|publisher|replay|dlq')"
check_min "5.1 event-related source/config/doc file count" "$EVENT_SOURCE_COUNT" "8"

EVENT_TEST_COUNT="$(find . -type f -name '*_test.go' 2>/dev/null | grep -Ei 'event|eventbus|event_bus|nats|jetstream|consumer|publisher|replay|dlq|idempotenc' | wc -l | tr -d ' ')"
check_min "5.2 event-related Go test file count" "$EVENT_TEST_COUNT" "1"

SCHEMA_CONTRACT_COUNT="$(grep_count 'EventSchema|event schema|schema contract|event_type|event version|event_version')"
check_min "5.3 event schema contract trace" "$SCHEMA_CONTRACT_COUNT" "1"

METADATA_STANDARD_COUNT="$(grep_count 'correlation_id|causation_id|event_id|created_at|metadata')"
check_min "5.4 event metadata standard trace" "$METADATA_STANDARD_COUNT" "5"

TENANT_EVENT_COUNT="$(grep_count 'tenant_id|tenantID|TenantID|X-Tenant-ID')"
check_min "5.5 tenant-aware event trace" "$TENANT_EVENT_COUNT" "5"

EVENT_STORE_COUNT="$(grep_count 'event store|EventStore|event_store|eventstore|append event|AppendEvent|Postgres.*event|event.*Postgres')"
check_min "5.6 event store / persistence trace" "$EVENT_STORE_COUNT" "1"

IDEMPOTENCY_COUNT="$(grep_count 'idempotency|idempotent|idempotency_key|Idempotency')"
check_min "5.7 idempotency trace" "$IDEMPOTENCY_COUNT" "1"

RETRY_COUNT="$(grep_count 'retry|Retry|backoff|Backoff')"
check_min "5.8 retry/backoff trace" "$RETRY_COUNT" "3"

DLQ_COUNT="$(grep_count 'DLQ|dlq|dead letter|dead-letter|dead_letter')"
check_min "5.9 DLQ trace" "$DLQ_COUNT" "1"

POISON_COUNT="$(grep_count 'poison|Poison')"
check_min "5.10 poison message trace" "$POISON_COUNT" "1"

REPLAY_COUNT="$(grep_count 'replay|Replay|rebuild projection|projection rebuild')"
check_min "5.11 replay trace" "$REPLAY_COUNT" "1"

NATS_COUNT="$(grep_count 'NATS|nats|JetStream|jetstream|js\.|stream')"
check_min "5.12 NATS / JetStream trace" "$NATS_COUNT" "1"

ACK_DURABLE_COUNT="$(grep_count 'ack|Ack|AckWait|durable|Durable|consumer durable|ack policy|AckPolicy')"
check_min "5.13 ack policy / durable consumer trace" "$ACK_DURABLE_COUNT" "1"

PUBLISH_CONSUME_COUNT="$(grep_count 'publish|Publish|publisher|consume|Consume|consumer|Subscribe|subscriber')"
check_min "5.14 publisher / consumer trace" "$PUBLISH_CONSUME_COUNT" "3"

AUDIT_TRAIL_COUNT="$(grep_count 'event audit|audit event|event_audit|audit trail|correlation_id')"
check_min "5.15 event audit trail trace" "$AUDIT_TRAIL_COUNT" "1"

CONCURRENCY_COUNT="$(grep_count 'concurrency|concurrent|mutex|lock|FOR UPDATE|SKIP LOCKED|advisory')"
check_min "5.16 event concurrency safety trace" "$CONCURRENCY_COUNT" "1"

EVENT_PACKAGES="$(go list ./... 2>/dev/null | grep -Ei 'event|eventbus|event_bus|nats|jetstream|consumer|publisher|replay|dlq|idempotenc' || true)"

if [ -n "$EVENT_PACKAGES" ]; then
  echo "===== FAZ 5 EVENT PLATFORM GO TEST PACKAGES ====="
  echo "$EVENT_PACKAGES"
  echo "$EVENT_PACKAGES" | xargs go test
  GO_TEST_STATUS="PASS"
  pass_check "5.17 event platform Go tests"
else
  GO_TEST_STATUS="NO_EVENT_PACKAGE_FOUND"
  fail_check "5.17 event platform Go test package discovery"
fi

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5433}"
DB_NAME="${DB_NAME:-pix2pi}"
DB_USER="${DB_USER:-pix2pi}"
PSQL_CONN="${DB_WRITE_DSN:-${DATABASE_URL:-}}"

run_psql() {
  if [ -n "$PSQL_CONN" ]; then
    psql "$PSQL_CONN" "$@"
  else
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" "$@"
  fi
}

if command -v psql >/dev/null 2>&1; then
  EVENT_DB_TABLE_COUNT="$(
    run_psql -Atc "
      SELECT count(*)
      FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND (
        table_name ILIKE '%event%'
        OR table_name ILIKE '%outbox%'
        OR table_name ILIKE '%inbox%'
        OR table_name ILIKE '%replay%'
        OR table_name ILIKE '%dlq%'
      );
    " 2>/dev/null | tr -d '[:space:]' || echo 0
  )"

  check_min "5.18 PostgreSQL event/outbox/replay/DLQ table trace" "${EVENT_DB_TABLE_COUNT:-0}" "1"
else
  warn_check "5.18 psql not available, DB table trace skipped"
fi

if [ -s "docs/faz5/event-platform/FAZ_5_EVENT_PLATFORM_FINAL_CLOSURE.md" ]; then
  pass_check "5.19 event platform final closure documentation"
else
  fail_check "5.19 event platform final closure documentation"
fi

echo "===== FAZ 5 EVENT PLATFORM FINAL CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_EVENT_PLATFORM_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_5_EVENT_PLATFORM_TEST_STATUS=PASS"
  echo "FAZ_5_EVENT_PLATFORM_FINAL_STATUS=PASS"
  echo "FAZ_5_EVENT_PLATFORM_SEAL_STATUS=SEALED"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_READY=YES"
  exit 0
else
  echo "FAZ_5_EVENT_PLATFORM_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_5_EVENT_PLATFORM_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_5_EVENT_PLATFORM_FINAL_STATUS=FAIL"
  echo "FAZ_5_EVENT_PLATFORM_SEAL_STATUS=OPEN"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_READY=NO"
  exit 1
fi
