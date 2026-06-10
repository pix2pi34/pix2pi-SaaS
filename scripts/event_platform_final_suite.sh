#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$ROOT_DIR/reports"
TS="$(date +%Y%m%d_%H%M%S)"

REPORT_TXT="$REPORT_DIR/event_platform_final_suite_${TS}.txt"
REPORT_MD="$REPORT_DIR/event_platform_final_suite_${TS}.md"
LATEST_TXT="$REPORT_DIR/event_platform_final_suite_latest.txt"
LATEST_MD="$REPORT_DIR/event_platform_final_suite_latest.md"

mkdir -p "$REPORT_DIR"

PASSED=0
FAILED=0
declare -a RESULT_LINES=()

export EVENT_STORE_PG_HOST="${EVENT_STORE_PG_HOST:-127.0.0.1}"
export EVENT_STORE_PG_PORT="${EVENT_STORE_PG_PORT:-5433}"
export EVENT_STORE_PG_USER="${EVENT_STORE_PG_USER:-pix2pi}"
export EVENT_STORE_PG_PASSWORD="${EVENT_STORE_PG_PASSWORD:-pix2pi}"
export EVENT_STORE_PG_DBNAME="${EVENT_STORE_PG_DBNAME:-pix2pi}"
export EVENT_STORE_PG_SSLMODE="${EVENT_STORE_PG_SSLMODE:-disable}"

header() {
  local text="$1"
  {
    echo
    echo "============================================================"
    echo "$text"
    echo "============================================================"
  } | tee -a "$REPORT_TXT"
}

run_step() {
  local key="$1"
  local cmd="$2"

  header "$key"

  set +e
  bash -lc "cd '$ROOT_DIR' && $cmd" 2>&1 | tee -a "$REPORT_TXT"
  local status=${PIPESTATUS[0]}
  set -e

  if [ "$status" -eq 0 ]; then
    PASSED=$((PASSED + 1))
    RESULT_LINES+=("$key|OK")
    echo "OK ✅ $key basarili" | tee -a "$REPORT_TXT"
  else
    FAILED=$((FAILED + 1))
    RESULT_LINES+=("$key|FAIL")
    echo "HATA ❌ $key basarisiz" | tee -a "$REPORT_TXT"
  fi
}

write_markdown_report() {
  {
    echo "# Event Platform Final Suite Report"
    echo
    echo "- Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- Klasor: \`$ROOT_DIR\`"
    echo "- Gecen: **$PASSED**"
    echo "- Kalan/Hata: **$FAILED**"
    echo "- Toplam: **$((PASSED + FAILED))**"
    echo

    if [ "$FAILED" -eq 0 ]; then
      echo "> Genel sonuc: **BASARILI ✅**"
    else
      echo "> Genel sonuc: **HATALI ❌**"
    fi

    echo
    echo "## Test Ozeti"
    echo
    echo "| Test | Durum |"
    echo "|---|---|"
    for line in "${RESULT_LINES[@]}"; do
      local_name="${line%%|*}"
      local_status="${line##*|}"
      echo "| $local_name | $local_status |"
    done

    echo
    echo "## Postgres Test Env"
    echo
    echo "- EVENT_STORE_PG_HOST: \`$EVENT_STORE_PG_HOST\`"
    echo "- EVENT_STORE_PG_PORT: \`$EVENT_STORE_PG_PORT\`"
    echo "- EVENT_STORE_PG_USER: \`$EVENT_STORE_PG_USER\`"
    echo "- EVENT_STORE_PG_DBNAME: \`$EVENT_STORE_PG_DBNAME\`"
    echo "- EVENT_STORE_PG_SSLMODE: \`$EVENT_STORE_PG_SSLMODE\`"
    echo "- EVENT_STORE_PG_PASSWORD: \`***hidden***\`"
  } > "$REPORT_MD"
}

{
  echo "EVENT PLATFORM FINAL SUITE BASLIYOR"
  echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Root: $ROOT_DIR"
  echo "Postgres Host: $EVENT_STORE_PG_HOST"
  echo "Postgres Port: $EVENT_STORE_PG_PORT"
  echo "Postgres User: $EVENT_STORE_PG_USER"
  echo "Postgres DB: $EVENT_STORE_PG_DBNAME"
  echo "Postgres SSLMODE: $EVENT_STORE_PG_SSLMODE"
  echo "Postgres Password: ***hidden***"
} | tee "$REPORT_TXT"

run_step "SCHEMA TEST" \
  "go run ./cmd/event-schema-test"

run_step "IDEMPOTENCY TEST" \
  "go run ./cmd/event-idempotency-test"

run_step "METADATA TEST" \
  "go run ./cmd/event-metadata-test"

run_step "LIFECYCLE TEST" \
  "go run ./cmd/event-bus-store-lifecycle-test"

run_step "REPLAY TEST" \
  "go run ./cmd/event-replay-test"

run_step "CONCURRENCY TEST" \
  "command -v gcc >/dev/null 2>&1 && CGO_ENABLED=1 CC=gcc go run -race ./cmd/event-concurrency-test"

run_step "POSTGRES PERSIST TEST" \
  "go run ./cmd/event-store-postgres-test"

write_markdown_report

cp "$REPORT_TXT" "$LATEST_TXT"
cp "$REPORT_MD" "$LATEST_MD"

header "FINAL OZET"

echo "Passed : $PASSED" | tee -a "$REPORT_TXT"
echo "Failed : $FAILED" | tee -a "$REPORT_TXT"
echo "TXT    : $REPORT_TXT" | tee -a "$REPORT_TXT"
echo "MD     : $REPORT_MD" | tee -a "$REPORT_TXT"

if [ "$FAILED" -eq 0 ]; then
  echo "OK ✅ EVENT PLATFORM FINAL SUITE BASARILI" | tee -a "$REPORT_TXT"
  exit 0
else
  echo "HATA ❌ EVENT PLATFORM FINAL SUITE ICIN BASARISIZ ADIM VAR" | tee -a "$REPORT_TXT"
  exit 1
fi
