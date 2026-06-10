#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
MIGRATION_DIR="$ROOT_DIR/db/migrations"

REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_5B_migration_timestamp_order_guard_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
ROWS_FILE="$(mktemp)"
SAFE_SORT_FILE="$(mktemp)"
NAIVE_SORT_FILE="$(mktemp)"
ANOMALY_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$ROWS_FILE" "$SAFE_SORT_FILE" "$NAIVE_SORT_FILE" "$ANOMALY_FILE"' EXIT

detail() {
  echo "$1" >> "$DETAILS_FILE"
}

warn() {
  echo "WARN ⚠️ $1" >> "$ISSUES_FILE"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "FAIL ❌ $1" >> "$ISSUES_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

naive_key() {
  local raw="$1"
  local key=""

  key="$(printf '%s' "$raw" | tr -d '_' | sed -E 's/^0+//')"

  if [ -z "$key" ]; then
    key="0"
  fi

  echo "$key"
}

parse_up_file() {
  local f="$1"
  local base=""
  local raw_version=""
  local safe_order_key=""
  local naive_order_key=""
  local style=""
  local anomaly="NO"
  local file_name=""

  file_name="$(basename "$f")"
  base="${file_name%.up.sql}"

  if [[ "$base" =~ ^([0-9]{14})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}"
    safe_order_key="$raw_version"
    style="NEW_STANDARD_TIMESTAMP"
  elif [[ "$base" =~ ^([0-9]{8})_([0-9]{6})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}"
    safe_order_key="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    style="LEGACY_SPLIT_TIMESTAMP"
  elif [[ "$base" =~ ^([0-9]{8})_([0-9]{7})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}"
    safe_order_key="EXCLUDED"
    style="TIMESTAMP_ANOMALY_7_DIGIT_TIME"
    anomaly="YES"
  elif [[ "$base" =~ ^([0-9]{3,4})_([a-z0-9][a-z0-9_]*)$ ]]; then
    raw_version="${BASH_REMATCH[1]}"
    safe_order_key="$(printf '%014d' "$((10#$raw_version))")"
    style="LEGACY_SEQUENCE"
  else
    raw_version="INVALID"
    safe_order_key="INVALID"
    style="INVALID"
    anomaly="YES"
  fi

  naive_order_key="$(naive_key "$raw_version")"

  printf '%s|%s|%s|%s|%s|%s\n' \
    "$safe_order_key" \
    "$naive_order_key" \
    "$raw_version" \
    "$style" \
    "$anomaly" \
    "$file_name"
}

detail "ROOT_DIR=$ROOT_DIR"
detail "MIGRATION_DIR=db/migrations"
detail "MUTATION=NO"
detail "APPLY=NO"
detail "RENAME=NO"

if [ ! -d "$MIGRATION_DIR" ]; then
  fail "migration dir not found: db/migrations"
else
  while IFS= read -r f; do
    parse_up_file "$f" >> "$ROWS_FILE"
  done < <(find "$MIGRATION_DIR" -maxdepth 1 -type f -name '*.up.sql' | sort)
fi

UP_COUNT="$(wc -l < "$ROWS_FILE" | tr -d ' ')"
INVALID_COUNT="$(awk -F'|' '$4=="INVALID" {c++} END {print c+0}' "$ROWS_FILE")"
ANOMALY_COUNT="$(awk -F'|' '$5=="YES" {c++} END {print c+0}' "$ROWS_FILE")"

detail "LOCAL_UP_MIGRATION_COUNT=$UP_COUNT"
detail "INVALID_FILENAME_COUNT=$INVALID_COUNT"
detail "TIMESTAMP_ANOMALY_COUNT=$ANOMALY_COUNT"

if [ "$UP_COUNT" -eq 0 ]; then
  fail "local up migration bulunamadi"
fi

if [ "$INVALID_COUNT" -gt 0 ]; then
  fail "invalid migration filename var"
fi

if [ "$ANOMALY_COUNT" -gt 0 ]; then
  warn "timestamp anomaly tespit edildi; anomaly dosyalari safe latest hesabindan dislandi"
fi

awk -F'|' '$1!="EXCLUDED" && $1!="INVALID" {print $1 "|" $6}' "$ROWS_FILE" | sort -t'|' -k1,1n > "$SAFE_SORT_FILE"
awk -F'|' '$2!="INVALID" {print $2 "|" $6}' "$ROWS_FILE" | sort -t'|' -k1,1n > "$NAIVE_SORT_FILE"
awk -F'|' '$5=="YES" {print $0}' "$ROWS_FILE" > "$ANOMALY_FILE"

SAFE_LATEST_ORDER_KEY="$(tail -n 1 "$SAFE_SORT_FILE" | cut -d'|' -f1 || true)"
SAFE_LATEST_FILE="$(tail -n 1 "$SAFE_SORT_FILE" | cut -d'|' -f2- || true)"

NAIVE_LATEST_ORDER_KEY="$(tail -n 1 "$NAIVE_SORT_FILE" | cut -d'|' -f1 || true)"
NAIVE_LATEST_FILE="$(tail -n 1 "$NAIVE_SORT_FILE" | cut -d'|' -f2- || true)"

detail "SAFE_LATEST_ORDER_KEY=$SAFE_LATEST_ORDER_KEY"
detail "SAFE_LATEST_FILE=$SAFE_LATEST_FILE"
detail "NAIVE_LATEST_ORDER_KEY=$NAIVE_LATEST_ORDER_KEY"
detail "NAIVE_LATEST_FILE=$NAIVE_LATEST_FILE"

if [ -z "$SAFE_LATEST_FILE" ]; then
  fail "safe latest hesaplanamadi"
fi

if [ "$SAFE_LATEST_FILE" != "$NAIVE_LATEST_FILE" ]; then
  detail "LATEST_ORDER_MISMATCH=YES"
  warn "naive latest ile safe latest farkli; guard devrede"
else
  detail "LATEST_ORDER_MISMATCH=NO"
fi

{
  echo "# FAZ 4 / 14.1.5B - Migration Timestamp Order Guard Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_TIMESTAMP_ORDER_GUARD=PASS"
  else
    echo "MIGRATION_TIMESTAMP_ORDER_GUARD=FAIL"
  fi

  echo
  echo "## Parsed Migrations"
  echo "SAFE_ORDER_KEY | NAIVE_ORDER_KEY | RAW_VERSION | STYLE | ANOMALY | FILE"
  if [ -s "$ROWS_FILE" ]; then
    cat "$ROWS_FILE"
  else
    echo "local migration yok"
  fi

  echo
  echo "## Timestamp Anomalies"
  if [ -s "$ANOMALY_FILE" ]; then
    cat "$ANOMALY_FILE"
  else
    echo "timestamp anomaly yok"
  fi

  echo
  echo "## Issues"
  if [ -s "$ISSUES_FILE" ]; then
    cat "$ISSUES_FILE"
  else
    echo "OK ✅ issue yok"
  fi
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "MIGRATION_TIMESTAMP_ORDER_GUARD=FAIL ❌"
  exit 1
fi

echo "MIGRATION_TIMESTAMP_ORDER_GUARD=PASS ✅"
