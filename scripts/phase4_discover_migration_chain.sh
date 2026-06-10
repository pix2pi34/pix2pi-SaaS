#!/usr/bin/env bash
set -u

ROOT_DIR="${1:-$(pwd)}"
REPORT_DIR="$ROOT_DIR/docs/phase4"
REPORT_FILE="$REPORT_DIR/14_1_migration_chain_discovery.md"

mkdir -p "$REPORT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR" || {
  echo "ERROR ❌ repo köküne girilemedi: $ROOT_DIR"
  exit 1
}

MIGRATION_DIRS_FILE="$TMP_DIR/migration_dirs.txt"
MIGRATION_SQL_FILE="$TMP_DIR/migration_sql_files.txt"
ALL_SQL_FILE="$TMP_DIR/all_sql_files.txt"
CODE_REFS_FILE="$TMP_DIR/migration_code_refs.txt"
MAKE_REFS_FILE="$TMP_DIR/migration_make_refs.txt"
DUP_VERSIONS_FILE="$TMP_DIR/duplicate_versions.txt"
NON_STANDARD_FILE="$TMP_DIR/non_standard_files.txt"
PAIR_STATUS_FILE="$TMP_DIR/up_down_pair_status.txt"
SUMMARY_FILE="$TMP_DIR/summary.txt"

find . \
  \( -path './.git' \
     -o -path './vendor' \
     -o -path './node_modules' \
     -o -path './tmp' \
     -o -path './backups' \
     -o -path './archive' \
     -o -path './dist' \
     -o -path './build' \) -prune \
  -o -type d \
  \( -iname '*migration*' \
     -o -ipath './db' \
     -o -ipath './db/*' \
     -o -ipath './database' \
     -o -ipath './database/*' \
     -o -ipath './internal/*/db' \
     -o -ipath './internal/*/database' \) \
  -print | sort > "$MIGRATION_DIRS_FILE"

find . \
  \( -path './.git' \
     -o -path './vendor' \
     -o -path './node_modules' \
     -o -path './tmp' \
     -o -path './backups' \
     -o -path './archive' \
     -o -path './dist' \
     -o -path './build' \) -prune \
  -o -type f -iname '*.sql' -print | sort > "$ALL_SQL_FILE"

grep -Ei '(^|/)(migrations?|db|database|schema|tenant|rls|policy)(/|_)|migration' "$ALL_SQL_FILE" \
  | sort > "$MIGRATION_SQL_FILE" || true

find . \
  \( -path './.git' \
     -o -path './vendor' \
     -o -path './node_modules' \
     -o -path './tmp' \
     -o -path './backups' \
     -o -path './archive' \
     -o -path './dist' \
     -o -path './build' \) -prune \
  -o -type f \
  \( -iname '*.go' \
     -o -iname '*.sh' \
     -o -iname '*.yml' \
     -o -iname '*.yaml' \
     -o -iname 'Dockerfile' \
     -o -iname 'Makefile' \
     -o -iname '*.env' \
     -o -iname '*.md' \) \
  -print0 \
  | xargs -0 grep -InE 'golang-migrate|goose|atlas|schema_migrations|migration|migrate|dirty|up\.sql|down\.sql' \
  2>/dev/null \
  | sort > "$CODE_REFS_FILE" || true

find . \
  \( -path './.git' \
     -o -path './vendor' \
     -o -path './node_modules' \
     -o -path './tmp' \
     -o -path './backups' \
     -o -path './archive' \
     -o -path './dist' \
     -o -path './build' \) -prune \
  -o -type f \
  \( -iname 'Makefile' \
     -o -iname '*.mk' \
     -o -iname '*.sh' \
     -o -iname '*.yml' \
     -o -iname '*.yaml' \) \
  -print0 \
  | xargs -0 grep -InE 'migrate|migration|db-up|db-down|schema' \
  2>/dev/null \
  | sort > "$MAKE_REFS_FILE" || true

awk '
function base_name(path, parts, n) {
  n = split(path, parts, "/")
  return parts[n]
}
{
  b = base_name($0)
  version = "NO_NUMERIC_PREFIX"
  if (match(b, /^[0-9]+/)) {
    version = substr(b, RSTART, RLENGTH)
  }
  print version "\t" $0
}
' "$MIGRATION_SQL_FILE" > "$TMP_DIR/version_map.tsv"

awk -F'\t' '
$1 != "NO_NUMERIC_PREFIX" {
  count[$1]++
  files[$1] = files[$1] "\n  - " $2
}
END {
  found=0
  for (v in count) {
    if (count[v] > 1) {
      found=1
      print "DUPLICATE_VERSION=" v files[v] "\n"
    }
  }
  if (found == 0) {
    print "OK ✅ duplicate numeric migration version bulunmadi"
  }
}
' "$TMP_DIR/version_map.tsv" > "$DUP_VERSIONS_FILE"

awk -F'\t' '
$1 == "NO_NUMERIC_PREFIX" {
  print "- " $2
}
' "$TMP_DIR/version_map.tsv" > "$NON_STANDARD_FILE"

if [ ! -s "$NON_STANDARD_FILE" ]; then
  echo "OK ✅ numeric prefixsiz migration adayi bulunmadi" > "$NON_STANDARD_FILE"
fi

while IFS= read -r f; do
  case "$f" in
    *.up.sql)
      down="${f%.up.sql}.down.sql"
      if [ -f "$down" ]; then
        echo "PAIR_OK ✅ $f <-> $down"
      else
        echo "PAIR_MISSING_DOWN ⚠️ $f -> beklenen: $down"
      fi
      ;;
    *_up.sql)
      down="${f%_up.sql}_down.sql"
      if [ -f "$down" ]; then
        echo "PAIR_OK ✅ $f <-> $down"
      else
        echo "PAIR_MISSING_DOWN ⚠️ $f -> beklenen: $down"
      fi
      ;;
    *.down.sql|*_down.sql)
      true
      ;;
    *)
      echo "PAIR_NOT_APPLICABLE ℹ️ $f"
      ;;
  esac
done < "$MIGRATION_SQL_FILE" > "$PAIR_STATUS_FILE"

MIGRATION_DIR_COUNT="$(wc -l < "$MIGRATION_DIRS_FILE" | tr -d ' ')"
ALL_SQL_COUNT="$(wc -l < "$ALL_SQL_FILE" | tr -d ' ')"
MIGRATION_SQL_COUNT="$(wc -l < "$MIGRATION_SQL_FILE" | tr -d ' ')"
CODE_REF_COUNT="$(wc -l < "$CODE_REFS_FILE" | tr -d ' ')"
MAKE_REF_COUNT="$(wc -l < "$MAKE_REFS_FILE" | tr -d ' ')"

{
  echo "MIGRATION_DIR_COUNT=$MIGRATION_DIR_COUNT"
  echo "ALL_SQL_COUNT=$ALL_SQL_COUNT"
  echo "MIGRATION_SQL_COUNT=$MIGRATION_SQL_COUNT"
  echo "CODE_REF_COUNT=$CODE_REF_COUNT"
  echo "MAKE_REF_COUNT=$MAKE_REF_COUNT"
} > "$SUMMARY_FILE"

{
  echo "# FAZ 4 / 14.1 — Migration Chain Discovery Report"
  echo
  echo "Generated at: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo
  echo "## 1. Ozet"
  echo
  echo '```text'
  cat "$SUMMARY_FILE"
  echo '```'
  echo
  echo "## 2. Migration dizin adaylari"
  echo
  echo '```text'
  if [ -s "$MIGRATION_DIRS_FILE" ]; then
    cat "$MIGRATION_DIRS_FILE"
  else
    echo "Migration dizin adayi bulunamadi."
  fi
  echo '```'
  echo
  echo "## 3. Migration SQL adaylari"
  echo
  echo '```text'
  if [ -s "$MIGRATION_SQL_FILE" ]; then
    cat "$MIGRATION_SQL_FILE"
  else
    echo "Migration SQL adayi bulunamadi."
  fi
  echo '```'
  echo
  echo "## 4. Duplicate numeric version kontrolu"
  echo
  echo '```text'
  cat "$DUP_VERSIONS_FILE"
  echo '```'
  echo
  echo "## 5. Numeric prefixsiz / standart disi adaylar"
  echo
  echo '```text'
  cat "$NON_STANDARD_FILE"
  echo '```'
  echo
  echo "## 6. Up / Down pair kontrolu"
  echo
  echo '```text'
  if [ -s "$PAIR_STATUS_FILE" ]; then
    cat "$PAIR_STATUS_FILE"
  else
    echo "Pair kontrol edilecek migration SQL adayi yok."
  fi
  echo '```'
  echo
  echo "## 7. Kod icindeki migration referanslari"
  echo
  echo '```text'
  if [ -s "$CODE_REFS_FILE" ]; then
    head -n 200 "$CODE_REFS_FILE"
  else
    echo "Kod icinde migration referansi bulunamadi."
  fi
  echo '```'
  echo
  echo "## 8. Make / script / compose migration referanslari"
  echo
  echo '```text'
  if [ -s "$MAKE_REFS_FILE" ]; then
    head -n 200 "$MAKE_REFS_FILE"
  else
    echo "Make/script/compose icinde migration referansi bulunamadi."
  fi
  echo '```'
  echo
  echo "## 9. Ilk karar notu"
  echo
  echo "- Bu rapor migration chain standardi yazilmadan once mevcut durumu kanitlamak icin uretildi."
  echo "- 14.1.1 adiminda bu rapora gore tek migration naming/version/pair standardi belirlenecek."
  echo "- Bu adim migration dosyalarini degistirmez."
} > "$REPORT_FILE"

echo "REPORT_FILE=$REPORT_FILE"
echo "OK ✅ migration chain discovery raporu üretildi"
