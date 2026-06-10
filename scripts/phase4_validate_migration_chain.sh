#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
ACTIVE_MIGRATION_DIR_REL="${2:-db/migrations}"
ACTIVE_MIGRATION_DIR="$ROOT_DIR/$ACTIVE_MIGRATION_DIR_REL"
REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_1_migration_chain_validation.md"

mkdir -p "$REPORT_DIR"

FAIL_COUNT=0
WARN_COUNT=0

classify_base() {
  local base="$1"

  if [[ "$base" =~ ^[0-9]{14}_[a-z0-9][a-z0-9_]*$ ]]; then
    echo "NEW_STANDARD"
    return 0
  fi

  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6,7}_[a-z0-9][a-z0-9_]*$ ]]; then
    echo "LEGACY_SPLIT_TIMESTAMP"
    return 0
  fi

  if [[ "$base" =~ ^[0-9]{3,4}_[a-z0-9][a-z0-9_]*$ ]]; then
    echo "LEGACY_SEQUENCE"
    return 0
  fi

  echo "INVALID"
  return 1
}

TMP_FILE="$(mktemp)"
BAD_FILE="$(mktemp)"
PAIR_FILE="$(mktemp)"
STYLE_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE" "$BAD_FILE" "$PAIR_FILE" "$STYLE_FILE"' EXIT

if [ ! -d "$ACTIVE_MIGRATION_DIR" ]; then
  echo "FAIL active migration dir not found: $ACTIVE_MIGRATION_DIR_REL" >> "$BAD_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  find "$ACTIVE_MIGRATION_DIR" -maxdepth 1 -type f -name '*.sql' | sort > "$TMP_FILE"
fi

SQL_COUNT="$(wc -l < "$TMP_FILE" | tr -d ' ')"

if [ "$SQL_COUNT" -eq 0 ]; then
  echo "FAIL active migration sql file not found" >> "$BAD_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

while IFS= read -r file; do
  name="$(basename "$file")"

  case "$name" in
    *.up.sql)
      base="${name%.up.sql}"
      ;;
    *.down.sql)
      base="${name%.down.sql}"
      ;;
    *)
      echo "STYLE_FAIL ❌ $name -> not .up.sql or .down.sql" >> "$STYLE_FILE"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      continue
      ;;
  esac

  style="$(classify_base "$base")"

  case "$style" in
    NEW_STANDARD)
      echo "STYLE_OK ✅ $name -> $style" >> "$STYLE_FILE"
      ;;
    LEGACY_SPLIT_TIMESTAMP|LEGACY_SEQUENCE)
      echo "STYLE_WARN ⚠️ $name -> $style" >> "$STYLE_FILE"
      WARN_COUNT=$((WARN_COUNT + 1))
      ;;
    INVALID)
      echo "STYLE_FAIL ❌ $name -> INVALID" >> "$STYLE_FILE"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      ;;
  esac
done < "$TMP_FILE"

while IFS= read -r file; do
  name="$(basename "$file")"

  case "$name" in
    *.up.sql)
      pair="${file%.up.sql}.down.sql"
      if [ -f "$pair" ]; then
        echo "PAIR_OK ✅ $name" >> "$PAIR_FILE"
      else
        echo "PAIR_MISSING_DOWN ❌ $name" >> "$PAIR_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
      ;;
    *.down.sql)
      pair="${file%.down.sql}.up.sql"
      if [ -f "$pair" ]; then
        true
      else
        echo "PAIR_MISSING_UP ❌ $name" >> "$PAIR_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
      ;;
  esac
done < "$TMP_FILE"

{
  echo "# FAZ 4 / 14.1.1 - Migration Chain Validation"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## Summary"
  echo
  echo "ROOT_DIR=$ROOT_DIR"
  echo "ACTIVE_MIGRATION_DIR=$ACTIVE_MIGRATION_DIR_REL"
  echo "ACTIVE_MIGRATION_SQL_COUNT=$SQL_COUNT"
  echo "FAIL_COUNT=$FAIL_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "MIGRATION_CHAIN_VALIDATION=PASS"
  else
    echo "MIGRATION_CHAIN_VALIDATION=FAIL"
  fi
  echo
  echo "## Style Status"
  echo
  cat "$STYLE_FILE"
  echo
  echo "## Pair Status"
  echo
  cat "$PAIR_FILE"
  echo
  echo "## Bad Files / Errors"
  if [ -s "$BAD_FILE" ]; then
    cat "$BAD_FILE"
  else
    echo "OK ✅ hata yok"
  fi
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "MIGRATION_CHAIN_VALIDATION=FAIL ❌"
  exit 1
fi

echo "MIGRATION_CHAIN_VALIDATION=PASS ✅"
