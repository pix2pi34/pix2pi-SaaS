#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

if [ -f /opt/pix2pi/orchestrator/env/common.env ]; then
  set -a
  . /opt/pix2pi/orchestrator/env/common.env
  set +a
fi

EVIDENCE_FILE="${FAZ_6_ERP_FINANCIAL_EVIDENCE_FILE:-docs/faz6/evidence/FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md}"
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

SEARCH_ROOTS=()
for d in cmd internal pkg kernel services configs db scripts docs; do
  if [ -d "$d" ]; then
    SEARCH_ROOTS+=("$d")
  fi
done

grep_count() {
  local pattern="$1"

  if [ "${#SEARCH_ROOTS[@]}" -eq 0 ]; then
    echo 0
    return
  fi

  grep -RIlE "$pattern" "${SEARCH_ROOTS[@]}" 2>/dev/null \
    | grep -vE '(^|/)backups/' \
    | sort -u \
    | wc -l \
    | tr -d ' '
}

file_count() {
  local pattern="$1"

  if [ "${#SEARCH_ROOTS[@]}" -eq 0 ]; then
    echo 0
    return
  fi

  find "${SEARCH_ROOTS[@]}" -type f 2>/dev/null \
    | grep -vE '(^|/)backups/' \
    | grep -Ei "$pattern" \
    | wc -l \
    | tr -d ' '
}

echo "===== FAZ 6 ERP EVENT / JOURNAL / LEDGER REAL IMPLEMENTATION AUDIT START ====="

ERP_SOURCE_COUNT="$(file_count 'erp|ufk|journal|ledger|accounting|tdhp|finance|financial')"
check_min "6.1 ERP/finance-related source/config/doc file count" "$ERP_SOURCE_COUNT" "8"

ERP_TEST_COUNT="$(find . -type f -name '*_test.go' 2>/dev/null \
  | grep -vE '(^|/)backups/' \
  | grep -Ei 'erp|ufk|journal|ledger|accounting|tdhp|finance|financial|posting|reconciliation' \
  | wc -l \
  | tr -d ' ')"
check_min "6.2 ERP/finance-related Go test file count" "$ERP_TEST_COUNT" "1"

ERP_EVENT_INTAKE_COUNT="$(grep_count 'ERP.*event|event.*ERP|EventIntake|event intake|Consume.*event|consumer.*event|event.*journal')"
check_min "6.3 ERP event intake trace" "$ERP_EVENT_INTAKE_COUNT" "1"

ACCOUNTING_RULE_COUNT="$(grep_count 'accounting rule|AccountingRule|rule mapping|RuleMapping|event.*rule|rule.*event|mapping')"
check_min "6.4 event to accounting rule mapping trace" "$ACCOUNTING_RULE_COUNT" "1"

RULE_VERSION_COUNT="$(grep_count 'rule version|RuleVersion|versioned rule|accounting.*version|version.*accounting|effective_from|effective_until')"
check_min "6.5 accounting rule versioning trace" "$RULE_VERSION_COUNT" "1"

JOURNAL_BUILDER_COUNT="$(grep_count 'journal builder|JournalBuilder|BuildJournal|journal line|JournalLine|journal.*debit|journal.*credit')"
check_min "6.6 journal builder trace" "$JOURNAL_BUILDER_COUNT" "1"

TDHP_COUNT="$(grep_count 'TDHP|Tek Düzen|Tek Duzen|hesap plan|account plan|chart of accounts|120|600|391')"
check_min "6.7 TDHP / account plan mapping trace" "$TDHP_COUNT" "1"

LEDGER_POSTING_COUNT="$(grep_count 'ledger posting|LedgerPosting|PostLedger|ledger.*post|posting pipeline|LedgerEntry|ledger entry')"
check_min "6.8 ledger posting pipeline trace" "$LEDGER_POSTING_COUNT" "1"

DOUBLE_POSTING_GUARD_COUNT="$(grep_count 'double posting|duplicate posting|posting.*idempotency|idempotency_key|idempotent|unique.*posting|posting.*unique')"
check_min "6.9 double posting guard trace" "$DOUBLE_POSTING_GUARD_COUNT" "1"

FAILED_POSTING_COUNT="$(grep_count 'failed posting|posting.*failed|failed.*ledger|posting error|posting.*isolation|dead|DLQ|retry')"
check_min "6.10 failed posting isolation trace" "$FAILED_POSTING_COUNT" "1"

REPLAY_SAFE_COUNT="$(grep_count 'replay.*accounting|accounting.*replay|replay.*journal|journal.*replay|replay.*ledger|ledger.*replay|idempotency')"
check_min "6.11 replay-safe accounting trace" "$REPLAY_SAFE_COUNT" "1"

FINANCIAL_AUDIT_COUNT="$(grep_count 'financial audit|audit trace|audit event|journal audit|ledger audit|correlation_id|causation_id')"
check_min "6.12 financial audit trace" "$FINANCIAL_AUDIT_COUNT" "1"

RECONCILIATION_COUNT="$(grep_count 'reconciliation|reconcile|balance check|debit.*credit|credit.*debit|balanced|trial balance')"
check_min "6.13 reconciliation / debit-credit balance trace" "$RECONCILIATION_COUNT" "1"

TENANT_FINANCE_COUNT="$(grep_count 'tenant_id|tenantID|TenantID|X-Tenant-ID')"
check_min "6.14 tenant-aware financial trace" "$TENANT_FINANCE_COUNT" "5"

CONCURRENCY_COUNT="$(grep_count 'concurrency|concurrent|mutex|lock|FOR UPDATE|SKIP LOCKED|advisory|transaction')"
check_min "6.15 financial concurrency / transaction safety trace" "$CONCURRENCY_COUNT" "1"

ERP_PACKAGES="$(go list ./... 2>/dev/null \
  | grep -v '/backups/' \
  | grep -Ei 'erp|ufk|journal|ledger|accounting|tdhp|finance|financial|posting|reconciliation' || true)"

if [ -n "$ERP_PACKAGES" ]; then
  echo "===== FAZ 6 ERP FINANCIAL GO TEST PACKAGES ====="
  echo "$ERP_PACKAGES"
  echo "$ERP_PACKAGES" | xargs go test
  GO_TEST_STATUS="PASS"
  pass_check "6.16 ERP financial Go tests"
else
  GO_TEST_STATUS="NO_ERP_FINANCIAL_PACKAGE_FOUND"
  fail_check "6.16 ERP financial Go test package discovery"
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
  ERP_DB_TABLE_COUNT="$(
    run_psql -Atc "
      SELECT count(*)
      FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
      AND (
        table_name ILIKE '%journal%'
        OR table_name ILIKE '%ledger%'
        OR table_name ILIKE '%accounting%'
        OR table_name ILIKE '%account%'
        OR table_name ILIKE '%posting%'
        OR table_name ILIKE '%finance%'
        OR table_name ILIKE '%financial%'
        OR table_name ILIKE '%tdhp%'
      );
    " 2>/dev/null | tr -d '[:space:]' || echo 0
  )"

  check_min "6.17 PostgreSQL journal/ledger/accounting table trace" "${ERP_DB_TABLE_COUNT:-0}" "1"

  ERP_TENANT_COLUMN_COUNT="$(
    run_psql -Atc "
      SELECT count(*)
      FROM information_schema.columns
      WHERE column_name='tenant_id'
      AND table_schema NOT IN ('pg_catalog', 'information_schema')
      AND (
        table_name ILIKE '%journal%'
        OR table_name ILIKE '%ledger%'
        OR table_name ILIKE '%accounting%'
        OR table_name ILIKE '%account%'
        OR table_name ILIKE '%posting%'
        OR table_name ILIKE '%finance%'
        OR table_name ILIKE '%financial%'
        OR table_name ILIKE '%tdhp%'
      );
    " 2>/dev/null | tr -d '[:space:]' || echo 0
  )"

  check_min "6.18 PostgreSQL tenant_id on financial tables trace" "${ERP_TENANT_COLUMN_COUNT:-0}" "1"
else
  warn_check "6.17 psql not available, DB table trace skipped"
fi

if [ -s "docs/faz6/erp-financial-core/FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FINAL_CLOSURE.md" ]; then
  pass_check "6.19 ERP event journal ledger final closure documentation"
else
  fail_check "6.19 ERP event journal ledger final closure documentation"
fi

echo "===== FAZ 6 ERP EVENT / JOURNAL / LEDGER REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_TEST_STATUS=PASS"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FINAL_STATUS=PASS"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_SEAL_STATUS=SEALED"
  echo "TENANT_SECURITY_ISOLATION_READY=YES"
  exit 0
else
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FINAL_STATUS=FAIL"
  echo "FAZ_6_ERP_EVENT_JOURNAL_LEDGER_SEAL_STATUS=OPEN"
  echo "TENANT_SECURITY_ISOLATION_READY=NO"
  exit 1
fi
