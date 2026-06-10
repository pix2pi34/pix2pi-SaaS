#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
INPUT_REPORT="$ROOT_DIR/docs/phase4/14_1_6_migration_drift_evidence_report.md"
REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_6B_drift_classification_report.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

DETAILS_FILE="$(mktemp)"
ISSUES_FILE="$(mktemp)"
MISSING_FILE="$(mktemp)"
BY_TYPE_FILE="$(mktemp)"
BY_FILE_FILE="$(mktemp)"
BY_DOMAIN_FILE="$(mktemp)"
TOP_FILE_FILE="$(mktemp)"
trap 'rm -f "$DETAILS_FILE" "$ISSUES_FILE" "$MISSING_FILE" "$BY_TYPE_FILE" "$BY_FILE_FILE" "$BY_DOMAIN_FILE" "$TOP_FILE_FILE"' EXIT

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

classify_domain() {
  local file="$1"

  case "$file" in
    *erp_*|*runtime_e2e*|*chart_of_accounts*|*ledger*|*journal*|*inventory*|*sales*|*procurement*|*cashbank*|*tax*|*product_catalog*|*master_party*)
      echo "ERP"
      ;;
    *phase1_foundation*)
      echo "FOUNDATION"
      ;;
    *service_registry*|*mission_control*|*jobs_queue*|*idempotency*|*notifications*|*webhooks*|*workflows*|*api_keys*|*plugins*)
      echo "PLATFORM"
      ;;
    *)
      echo "OTHER"
      ;;
  esac
}

detail "ROOT_DIR=$ROOT_DIR"
detail "INPUT_REPORT=docs/phase4/14_1_6_migration_drift_evidence_report.md"
detail "MUTATION=NO"
detail "APPLY=NO"
detail "COUNT_MODE=DEDUPED_UNIQUE_MISSING_LINES"

if [ ! -f "$INPUT_REPORT" ]; then
  fail "input drift evidence report not found"
else
  grep '^MISSING|' "$INPUT_REPORT" | sort -u > "$MISSING_FILE" || true
fi

MISSING_TOTAL_COUNT="$(wc -l < "$MISSING_FILE" | tr -d ' ')"
MISSING_SCHEMA_COUNT="$(awk -F'|' '$2=="SCHEMA" {c++} END {print c+0}' "$MISSING_FILE")"
MISSING_TABLE_COUNT="$(awk -F'|' '$2=="TABLE" {c++} END {print c+0}' "$MISSING_FILE")"
MISSING_INDEX_COUNT="$(awk -F'|' '$2=="INDEX" {c++} END {print c+0}' "$MISSING_FILE")"

detail "MISSING_TOTAL_COUNT=$MISSING_TOTAL_COUNT"
detail "MISSING_SCHEMA_COUNT=$MISSING_SCHEMA_COUNT"
detail "MISSING_TABLE_COUNT=$MISSING_TABLE_COUNT"
detail "MISSING_INDEX_COUNT=$MISSING_INDEX_COUNT"

if [ "$MISSING_TOTAL_COUNT" -eq 0 ]; then
  DRIFT_RISK_LEVEL="LOW"
elif [ "$MISSING_SCHEMA_COUNT" -gt 0 ] || [ "$MISSING_TABLE_COUNT" -gt 0 ]; then
  DRIFT_RISK_LEVEL="HIGH"
else
  DRIFT_RISK_LEVEL="MEDIUM"
fi

detail "DRIFT_RISK_LEVEL=$DRIFT_RISK_LEVEL"

case "$DRIFT_RISK_LEVEL" in
  HIGH)
    warn "missing schema/table var; migration apply plani once reconciliation ister"
    ;;
  MEDIUM)
    warn "missing index var; apply riski orta, index-only reconciliation gerekebilir"
    ;;
  LOW)
    true
    ;;
esac

awk -F'|' '
  /^MISSING\|/ {
    type[$2]++
  }
  END {
    for (t in type) {
      print t "|" type[t]
    }
  }
' "$MISSING_FILE" | sort > "$BY_TYPE_FILE"

awk -F'|' '
  /^MISSING\|/ {
    file=$5
    if (file == "") file=$4
    count[file]++
  }
  END {
    for (f in count) {
      print count[f] "|" f
    }
  }
' "$MISSING_FILE" | sort -t'|' -k1,1nr > "$BY_FILE_FILE"

head -n 20 "$BY_FILE_FILE" > "$TOP_FILE_FILE"

while IFS='|' read -r count file; do
  [ -n "$file" ] || continue
  domain="$(classify_domain "$file")"
  echo "$domain|$count|$file" >> "$BY_DOMAIN_FILE"
done < "$BY_FILE_FILE"

ERP_MISSING_COUNT="$(awk -F'|' '$1=="ERP" {s+=$2} END {print s+0}' "$BY_DOMAIN_FILE")"
PLATFORM_MISSING_COUNT="$(awk -F'|' '$1=="PLATFORM" {s+=$2} END {print s+0}' "$BY_DOMAIN_FILE")"
FOUNDATION_MISSING_COUNT="$(awk -F'|' '$1=="FOUNDATION" {s+=$2} END {print s+0}' "$BY_DOMAIN_FILE")"
OTHER_MISSING_COUNT="$(awk -F'|' '$1=="OTHER" {s+=$2} END {print s+0}' "$BY_DOMAIN_FILE")"

detail "ERP_MISSING_COUNT=$ERP_MISSING_COUNT"
detail "PLATFORM_MISSING_COUNT=$PLATFORM_MISSING_COUNT"
detail "FOUNDATION_MISSING_COUNT=$FOUNDATION_MISSING_COUNT"
detail "OTHER_MISSING_COUNT=$OTHER_MISSING_COUNT"

{
  echo "# FAZ 4 / 14.1.6B - Drift Classification Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  cat "$DETAILS_FILE"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "DRIFT_CLASSIFICATION=PASS"
  else
    echo "DRIFT_CLASSIFICATION=FAIL"
  fi

  echo
  echo "## Missing By Type"
  if [ -s "$BY_TYPE_FILE" ]; then
    cat "$BY_TYPE_FILE"
  else
    echo "missing object yok"
  fi

  echo
  echo "## Missing By Domain"
  echo "DOMAIN | COUNT | FILE"
  if [ -s "$BY_DOMAIN_FILE" ]; then
    cat "$BY_DOMAIN_FILE"
  else
    echo "domain missing yok"
  fi

  echo
  echo "## Top Missing Migration Files"
  echo "COUNT | FILE"
  if [ -s "$TOP_FILE_FILE" ]; then
    cat "$TOP_FILE_FILE"
  else
    echo "missing file yok"
  fi

  echo
  echo "## First 120 Missing Objects"
  if [ -s "$MISSING_FILE" ]; then
    head -n 120 "$MISSING_FILE"
  else
    echo "missing object yok"
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
echo "MISSING_TOTAL_COUNT=$MISSING_TOTAL_COUNT"
echo "DRIFT_RISK_LEVEL=$DRIFT_RISK_LEVEL"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "DRIFT_CLASSIFICATION=FAIL ❌"
  exit 1
fi

echo "DRIFT_CLASSIFICATION=PASS ✅"
