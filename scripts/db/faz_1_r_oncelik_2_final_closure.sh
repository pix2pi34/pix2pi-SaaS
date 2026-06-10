#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_CLOSURE"

BACKUP_DIR="$REPO/backups/faz1/faz_1_r_oncelik_2_final_closure_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"
MIGRATION_DIR="$REPO/db/migrations/faz1"

CLOSURE_SCRIPT_FILE="$SCRIPT_DIR/faz_1_r_oncelik_2_final_closure.sh"
DOC_FILE="$DOC_DIR/FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_CLOSURE.md"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_CLOSURE_FINAL_SEAL_$TS.md"

MODULE_FILE_LIST="$SUITE_RUNTIME_DIR/module_artifact_files.txt"
DB_SNAPSHOT_FILE="$SUITE_RUNTIME_DIR/db_core_model_standard_snapshot.txt"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

scalar_count() {
  local sql="$1"
  local out=""
  set +e
  out="$(psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}')"
  local ec=$?
  set -e
  if [ "$ec" -ne 0 ] || ! [[ "$out" =~ ^[0-9]+$ ]]; then
    echo 0
  else
    echo "$out"
  fi
}

matching_files() {
  local regex="$1"
  {
    find "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR" -type f 2>/dev/null || true
  } | grep -Eai "$regex" || true
}

module_file_count() {
  local regex="$1"
  matching_files "$regex" | wc -l | awk '{print $1}'
}

module_signal_count() {
  local regex="$1"
  local signal_regex="$2"
  local count=0
  local f=""
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    if grep -Eiq "$signal_regex" "$f"; then
      count=$((count+1))
    fi
  done < <(matching_files "$regex")
  echo "$count"
}

validate_module() {
  local label="$1"
  local file_count="$2"
  local signal_count="$3"
  local ready_var_name="$4"

  if [ "$file_count" -ge 1 ]; then
    pass "$label artifact dosyası mevcut count=$file_count"
  else
    fail "$label artifact dosyası yok"
  fi

  if [ "$signal_count" -ge 1 ]; then
    pass "$label PASS/SEALED/CLOSED izi mevcut count=$signal_count"
    printf -v "$ready_var_name" "PASS"
  else
    fail "$label PASS/SEALED/CLOSED izi yok"
    printf -v "$ready_var_name" "FAIL"
  fi
}

echo "===== FAZ 1-R ONCELIK 2 DB-L1 CORE MODEL STANDARD FINAL CLOSURE START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR"
cd "$REPO"

echo "2. mevcut closure dosyaları yedekleniyor..."

for f in "$CLOSURE_SCRIPT_FILE" "$DOC_FILE" "$EVIDENCE_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. env kaynakları yükleniyor..."

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "3.1 common.env yüklendi"
else
  warn "3.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  source "$REPO/.env"
  set +a
  pass "3.2 repo .env yüklendi"
else
  warn "3.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "${DSN:-}" ]; then
  pass "4. DB DSN bulundu"
else
  fail "4. DB DSN bulunamadı"
  exit 1
fi

if command -v psql >/dev/null 2>&1; then
  pass "5. psql mevcut"
else
  fail "5. psql bulunamadı"
  exit 1
fi

if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then
  pass "6. DB bağlantısı başarılı"
else
  fail "6. DB bağlantısı başarısız"
  exit 1
fi

echo "7. FAZ 1-R / Öncelik 2 artifact ve seal izleri taranıyor..."

MOD_114_FILES="$(module_file_count 'FAZ_1_1_4|COMMON_COLUMN|COMMON.*COLUMN|BUSINESS.*COLUMN|ORTAK.*KOLON')"
MOD_114_SIGNALS="$(module_signal_count 'FAZ_1_1_4|COMMON_COLUMN|COMMON.*COLUMN|BUSINESS.*COLUMN|ORTAK.*KOLON' 'PASS|SEALED|CLOSED')"

MOD_115_FILES="$(module_file_count 'FAZ_1_1_5|PK_BUSINESS_CODE|BUSINESS_CODE|PK.*BUSINESS')"
MOD_115_SIGNALS="$(module_signal_count 'FAZ_1_1_5|PK_BUSINESS_CODE|BUSINESS_CODE|PK.*BUSINESS' 'PASS|SEALED|CLOSED')"

MOD_116_FILES="$(module_file_count 'FAZ_1_1_6|NAMING|INDEX_CONVENTION|CONVENTION')"
MOD_116_SIGNALS="$(module_signal_count 'FAZ_1_1_6|NAMING|INDEX_CONVENTION|CONVENTION' 'PASS|SEALED|CLOSED')"

MOD_118_FILES="$(module_file_count 'FAZ_1_1_8|DATA_DICTIONARY|FIELD_CONTRACT|DICTIONARY')"
MOD_118_SIGNALS="$(module_signal_count 'FAZ_1_1_8|DATA_DICTIONARY|FIELD_CONTRACT|DICTIONARY' 'PASS|SEALED|CLOSED')"

MOD_112_FILES="$(module_file_count 'FAZ_1_1_2|LEGAL_ENTITY|LEGAL.*ENTITY')"
MOD_112_SIGNALS="$(module_signal_count 'FAZ_1_1_2|LEGAL_ENTITY|LEGAL.*ENTITY' 'PASS|SEALED|CLOSED')"

MOD_113_FILES="$(module_file_count 'FAZ_1_1_3|BRANCH_MODEL|BRANCH')"
MOD_113_SIGNALS="$(module_signal_count 'FAZ_1_1_3|BRANCH_MODEL|BRANCH' 'PASS|SEALED|CLOSED')"

MOD_117_FILES="$(module_file_count 'FAZ_1_1_7|SCHEMA_SEPARATION|SCHEMA.*MAP|BOUNDARY_MAP')"
MOD_117_SIGNALS="$(module_signal_count 'FAZ_1_1_7|SCHEMA_SEPARATION|SCHEMA.*MAP|BOUNDARY_MAP' 'PASS|SEALED|CLOSED')"

{
  echo "FAZ 1-R / Öncelik 2 module artifact files"
  echo "Generated at: $(date -Is)"
  echo
  echo "===== 1-1.4 ====="
  matching_files 'FAZ_1_1_4|COMMON_COLUMN|COMMON.*COLUMN|BUSINESS.*COLUMN|ORTAK.*KOLON'
  echo
  echo "===== 1-1.5 ====="
  matching_files 'FAZ_1_1_5|PK_BUSINESS_CODE|BUSINESS_CODE|PK.*BUSINESS'
  echo
  echo "===== 1-1.6 ====="
  matching_files 'FAZ_1_1_6|NAMING|INDEX_CONVENTION|CONVENTION'
  echo
  echo "===== 1-1.8 ====="
  matching_files 'FAZ_1_1_8|DATA_DICTIONARY|FIELD_CONTRACT|DICTIONARY'
  echo
  echo "===== 1-1.2 ====="
  matching_files 'FAZ_1_1_2|LEGAL_ENTITY|LEGAL.*ENTITY'
  echo
  echo "===== 1-1.3 ====="
  matching_files 'FAZ_1_1_3|BRANCH_MODEL|BRANCH'
  echo
  echo "===== 1-1.7 ====="
  matching_files 'FAZ_1_1_7|SCHEMA_SEPARATION|SCHEMA.*MAP|BOUNDARY_MAP'
} > "$MODULE_FILE_LIST"

echo "MOD_114_FILES=$MOD_114_FILES"
echo "MOD_114_SIGNALS=$MOD_114_SIGNALS"
echo "MOD_115_FILES=$MOD_115_FILES"
echo "MOD_115_SIGNALS=$MOD_115_SIGNALS"
echo "MOD_116_FILES=$MOD_116_FILES"
echo "MOD_116_SIGNALS=$MOD_116_SIGNALS"
echo "MOD_118_FILES=$MOD_118_FILES"
echo "MOD_118_SIGNALS=$MOD_118_SIGNALS"
echo "MOD_112_FILES=$MOD_112_FILES"
echo "MOD_112_SIGNALS=$MOD_112_SIGNALS"
echo "MOD_113_FILES=$MOD_113_FILES"
echo "MOD_113_SIGNALS=$MOD_113_SIGNALS"
echo "MOD_117_FILES=$MOD_117_FILES"
echo "MOD_117_SIGNALS=$MOD_117_SIGNALS"
echo "MODULE_FILE_LIST=$MODULE_FILE_LIST"

validate_module "7.1 FAZ 1-1.4 common column standard" "$MOD_114_FILES" "$MOD_114_SIGNALS" "MOD_114_STATUS"
validate_module "7.2 FAZ 1-1.5 PK / business-code standard" "$MOD_115_FILES" "$MOD_115_SIGNALS" "MOD_115_STATUS"
validate_module "7.3 FAZ 1-1.6 naming / index convention" "$MOD_116_FILES" "$MOD_116_SIGNALS" "MOD_116_STATUS"
validate_module "7.4 FAZ 1-1.8 data dictionary / field contract" "$MOD_118_FILES" "$MOD_118_SIGNALS" "MOD_118_STATUS"
validate_module "7.5 FAZ 1-1.2 legal entity model" "$MOD_112_FILES" "$MOD_112_SIGNALS" "MOD_112_STATUS"
validate_module "7.6 FAZ 1-1.3 branch model" "$MOD_113_FILES" "$MOD_113_SIGNALS" "MOD_113_STATUS"
validate_module "7.7 FAZ 1-1.7 schema separation map" "$MOD_117_FILES" "$MOD_117_SIGNALS" "MOD_117_STATUS"

echo "8. DB real implementation spot audit çalıştırılıyor..."

LEGAL_ENTITY_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entities';")"
LEGAL_ENTITY_ADDRESS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entity_addresses';")"

BRANCH_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='branches';")"
BRANCH_ADDRESS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='branch_addresses';")"

SCHEMA_BOUNDARY_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='app_schema' and table_name='schema_boundary_map';")"
SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null and boundary_code in ('AUTH','TENANT','ERP','OPS','REPORTING','MIGRATION_PATH');")"

DATA_DICTIONARY_TABLE_CONTRACT_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='app_dictionary' and table_name='table_contracts';")"
DATA_DICTIONARY_CORE_ROW_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name in ('org','app_schema') and table_name in ('legal_entities','legal_entity_addresses','branches','branch_addresses','schema_boundary_map');")"

COMMON_COLUMN_SPOT_COUNT="$(scalar_count "
  SELECT count(*)
  FROM (
    SELECT table_schema, table_name
    FROM information_schema.columns
    WHERE (table_schema, table_name) IN (
      ('org','legal_entities'),
      ('org','branches'),
      ('org','branch_addresses')
    )
      AND column_name IN ('tenant_id','legal_entity_id','branch_id','created_at','updated_at','created_by','updated_by','deleted_at')
    GROUP BY table_schema, table_name
    HAVING count(*) >= 5
  ) q;
")"

BUSINESS_CODE_SPOT_COUNT="$(scalar_count "
  SELECT count(*)
  FROM information_schema.columns
  WHERE (table_schema, table_name) IN (
    ('org','legal_entities'),
    ('org','legal_entity_addresses'),
    ('org','branches'),
    ('org','branch_addresses')
  )
    AND column_name='business_code';
")"

CORE_INDEX_SPOT_COUNT="$(scalar_count "
  SELECT count(*)
  FROM pg_indexes
  WHERE schemaname IN ('org','app_schema')
    AND tablename IN ('legal_entities','legal_entity_addresses','branches','branch_addresses','schema_boundary_map');
")"

CORE_CONSTRAINT_SPOT_COUNT="$(scalar_count "
  SELECT count(*)
  FROM pg_constraint con
  JOIN pg_class c ON c.oid=con.conrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('org','app_schema')
    AND c.relname IN ('legal_entities','legal_entity_addresses','branches','branch_addresses','schema_boundary_map');
")"

MIGRATION_FILE_COUNT="$(find "$REPO/db/migrations" -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | wc -l | awk '{print $1}')"
FAZ1_MIGRATION_FILE_COUNT="$(find "$REPO/db/migrations/faz1" -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | wc -l | awk '{print $1}')"

{
  echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
  echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
  echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
  echo "BRANCH_ADDRESS_TABLE_COUNT=$BRANCH_ADDRESS_TABLE_COUNT"
  echo "SCHEMA_BOUNDARY_TABLE_COUNT=$SCHEMA_BOUNDARY_TABLE_COUNT"
  echo "SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT=$SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT"
  echo "DATA_DICTIONARY_TABLE_CONTRACT_COUNT=$DATA_DICTIONARY_TABLE_CONTRACT_COUNT"
  echo "DATA_DICTIONARY_CORE_ROW_COUNT=$DATA_DICTIONARY_CORE_ROW_COUNT"
  echo "COMMON_COLUMN_SPOT_COUNT=$COMMON_COLUMN_SPOT_COUNT"
  echo "BUSINESS_CODE_SPOT_COUNT=$BUSINESS_CODE_SPOT_COUNT"
  echo "CORE_INDEX_SPOT_COUNT=$CORE_INDEX_SPOT_COUNT"
  echo "CORE_CONSTRAINT_SPOT_COUNT=$CORE_CONSTRAINT_SPOT_COUNT"
  echo "MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
  echo "FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
} > "$DB_SNAPSHOT_FILE"

cat "$DB_SNAPSHOT_FILE"

[ "$LEGAL_ENTITY_TABLE_COUNT" -eq 1 ] && pass "8.1 legal_entities tablosu mevcut" || fail "8.1 legal_entities tablosu eksik"
[ "$LEGAL_ENTITY_ADDRESS_TABLE_COUNT" -eq 1 ] && pass "8.2 legal_entity_addresses tablosu mevcut" || fail "8.2 legal_entity_addresses tablosu eksik"
[ "$BRANCH_TABLE_COUNT" -eq 1 ] && pass "8.3 branches tablosu mevcut" || fail "8.3 branches tablosu eksik"
[ "$BRANCH_ADDRESS_TABLE_COUNT" -eq 1 ] && pass "8.4 branch_addresses tablosu mevcut" || fail "8.4 branch_addresses tablosu eksik"
[ "$SCHEMA_BOUNDARY_TABLE_COUNT" -eq 1 ] && pass "8.5 schema_boundary_map tablosu mevcut" || fail "8.5 schema_boundary_map tablosu eksik"
[ "$SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT" -eq 6 ] && pass "8.6 zorunlu 6 schema boundary row mevcut" || fail "8.6 zorunlu schema boundary row eksik"
[ "$DATA_DICTIONARY_TABLE_CONTRACT_COUNT" -eq 1 ] && pass "8.7 data dictionary table_contracts mevcut" || fail "8.7 data dictionary table_contracts eksik"
[ "$DATA_DICTIONARY_CORE_ROW_COUNT" -ge 4 ] && pass "8.8 core model dictionary kayıtları mevcut" || fail "8.8 core model dictionary kayıtları eksik"
[ "$COMMON_COLUMN_SPOT_COUNT" -ge 3 ] && pass "8.9 common column spot audit geçti" || fail "8.9 common column spot audit başarısız"
[ "$BUSINESS_CODE_SPOT_COUNT" -ge 4 ] && pass "8.10 business_code spot audit geçti" || fail "8.10 business_code spot audit başarısız"
[ "$CORE_INDEX_SPOT_COUNT" -ge 10 ] && pass "8.11 index convention spot audit geçti" || fail "8.11 index convention spot audit başarısız"
[ "$CORE_CONSTRAINT_SPOT_COUNT" -ge 10 ] && pass "8.12 constraint convention spot audit geçti" || fail "8.12 constraint convention spot audit başarısız"
[ "$MIGRATION_FILE_COUNT" -ge 1 ] && pass "8.13 migration path mevcut" || fail "8.13 migration path yok"
[ "$FAZ1_MIGRATION_FILE_COUNT" -ge 1 ] && pass "8.14 faz1 migration path mevcut" || fail "8.14 faz1 migration path yok"

echo "9. final review status hesaplanıyor..."

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  FINAL_SEAL_STATUS="SEALED"
  READY_NEXT="YES"
  pass "9.1 Öncelik 2 final review status PASS"
else
  FINAL_STATUS="FAIL"
  FINAL_SEAL_STATUS="OPEN"
  READY_NEXT="NO"
  fail "9.1 Öncelik 2 final review status FAIL"
fi

echo "10. final closure dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-R / Öncelik 2 — DB-L1 Core Model Standard Closure

## Kapsam

Bu closure, FAZ 1-R / Öncelik 2 altında tamamlanan DB-L1 core model standard işlerini tek final audit altında kapatır.

## Kapanan işler

| Sıra | İş | Final |
|---:|---|---|
| 8 | FAZ 1-1.4 — Tüm business tablolar için ortak kolon standardı | ${MOD_114_STATUS:-N/A} |
| 9 | FAZ 1-1.5 — PK / business-code standardı | ${MOD_115_STATUS:-N/A} |
| 10 | FAZ 1-1.6 — Naming / index convention standardı | ${MOD_116_STATUS:-N/A} |
| 11 | FAZ 1-1.8 — Data dictionary / field contract omurgası | ${MOD_118_STATUS:-N/A} |
| 12 | FAZ 1-1.2 — Legal entity modeli | ${MOD_112_STATUS:-N/A} |
| 13 | FAZ 1-1.3 — Branch modeli | ${MOD_113_STATUS:-N/A} |
| 14 | FAZ 1-1.7 — Schema ayrım haritası | ${MOD_117_STATUS:-N/A} |

## Final karar

- FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_FINAL_STATUS=$FINAL_STATUS
- FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_SEAL_STATUS=$FINAL_SEAL_STATUS
- FAZ_1_R_ONCELIK_3_READY=$READY_NEXT
DOC

{
  echo "# FAZ 1-R / Öncelik 2 DB-L1 Core Model Standard Closure Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Module file list: $MODULE_FILE_LIST"
  echo "- DB snapshot: $DB_SNAPSHOT_FILE"
  echo
  echo "## Module Artifact Counters"
  echo "- MOD_114_FILES=$MOD_114_FILES"
  echo "- MOD_114_SIGNALS=$MOD_114_SIGNALS"
  echo "- MOD_115_FILES=$MOD_115_FILES"
  echo "- MOD_115_SIGNALS=$MOD_115_SIGNALS"
  echo "- MOD_116_FILES=$MOD_116_FILES"
  echo "- MOD_116_SIGNALS=$MOD_116_SIGNALS"
  echo "- MOD_118_FILES=$MOD_118_FILES"
  echo "- MOD_118_SIGNALS=$MOD_118_SIGNALS"
  echo "- MOD_112_FILES=$MOD_112_FILES"
  echo "- MOD_112_SIGNALS=$MOD_112_SIGNALS"
  echo "- MOD_113_FILES=$MOD_113_FILES"
  echo "- MOD_113_SIGNALS=$MOD_113_SIGNALS"
  echo "- MOD_117_FILES=$MOD_117_FILES"
  echo "- MOD_117_SIGNALS=$MOD_117_SIGNALS"
  echo
  echo "## Module Status"
  echo "- MOD_114_STATUS=${MOD_114_STATUS:-N/A}"
  echo "- MOD_115_STATUS=${MOD_115_STATUS:-N/A}"
  echo "- MOD_116_STATUS=${MOD_116_STATUS:-N/A}"
  echo "- MOD_118_STATUS=${MOD_118_STATUS:-N/A}"
  echo "- MOD_112_STATUS=${MOD_112_STATUS:-N/A}"
  echo "- MOD_113_STATUS=${MOD_113_STATUS:-N/A}"
  echo "- MOD_117_STATUS=${MOD_117_STATUS:-N/A}"
  echo
  echo "## DB Spot Audit"
  echo "- LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
  echo "- BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
  echo "- BRANCH_ADDRESS_TABLE_COUNT=$BRANCH_ADDRESS_TABLE_COUNT"
  echo "- SCHEMA_BOUNDARY_TABLE_COUNT=$SCHEMA_BOUNDARY_TABLE_COUNT"
  echo "- SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT=$SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT"
  echo "- DATA_DICTIONARY_TABLE_CONTRACT_COUNT=$DATA_DICTIONARY_TABLE_CONTRACT_COUNT"
  echo "- DATA_DICTIONARY_CORE_ROW_COUNT=$DATA_DICTIONARY_CORE_ROW_COUNT"
  echo "- COMMON_COLUMN_SPOT_COUNT=$COMMON_COLUMN_SPOT_COUNT"
  echo "- BUSINESS_CODE_SPOT_COUNT=$BUSINESS_CODE_SPOT_COUNT"
  echo "- CORE_INDEX_SPOT_COUNT=$CORE_INDEX_SPOT_COUNT"
  echo "- CORE_CONSTRAINT_SPOT_COUNT=$CORE_CONSTRAINT_SPOT_COUNT"
  echo "- MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
  echo "- FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
  echo
  echo "## Final Status"
  echo "- FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_FINAL_STATUS=$FINAL_STATUS"
  echo "- FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_SEAL_STATUS=$FINAL_SEAL_STATUS"
  echo "- FAZ_1_R_ONCELIK_3_READY=$READY_NEXT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-R / Öncelik 2 DB-L1 Core Model Standard Closure Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "FAZ_1_1_4_COMMON_COLUMN_STANDARD_STATUS=${MOD_114_STATUS:-N/A}"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD_STATUS=${MOD_115_STATUS:-N/A}"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_STATUS=${MOD_116_STATUS:-N/A}"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STATUS=${MOD_118_STATUS:-N/A}"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STATUS=${MOD_112_STATUS:-N/A}"
  echo "FAZ_1_1_3_BRANCH_MODEL_STATUS=${MOD_113_STATUS:-N/A}"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_STATUS=${MOD_117_STATUS:-N/A}"
  echo "FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_FINAL_STATUS=$FINAL_STATUS"
  echo "FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_SEAL_STATUS=$FINAL_SEAL_STATUS"
  echo "FAZ_1_R_ONCELIK_3_READY=$READY_NEXT"
} > "$FINAL_SEAL_FILE"

pass "10.1 dokümantasyon yazıldı: $DOC_FILE"
pass "10.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "10.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$CLOSURE_SCRIPT_FILE"
chmod +x "$CLOSURE_SCRIPT_FILE"
pass "10.4 closure script repo içine kopyalandı: $CLOSURE_SCRIPT_FILE"

echo "===== FAZ 1-R ONCELIK 2 DB-L1 CORE MODEL STANDARD FINAL CLOSURE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "MOD_114_STATUS=${MOD_114_STATUS:-N/A}"
echo "MOD_115_STATUS=${MOD_115_STATUS:-N/A}"
echo "MOD_116_STATUS=${MOD_116_STATUS:-N/A}"
echo "MOD_118_STATUS=${MOD_118_STATUS:-N/A}"
echo "MOD_112_STATUS=${MOD_112_STATUS:-N/A}"
echo "MOD_113_STATUS=${MOD_113_STATUS:-N/A}"
echo "MOD_117_STATUS=${MOD_117_STATUS:-N/A}"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
echo "BRANCH_ADDRESS_TABLE_COUNT=$BRANCH_ADDRESS_TABLE_COUNT"
echo "SCHEMA_BOUNDARY_TABLE_COUNT=$SCHEMA_BOUNDARY_TABLE_COUNT"
echo "SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT=$SCHEMA_BOUNDARY_REQUIRED_ROW_COUNT"
echo "DATA_DICTIONARY_TABLE_CONTRACT_COUNT=$DATA_DICTIONARY_TABLE_CONTRACT_COUNT"
echo "DATA_DICTIONARY_CORE_ROW_COUNT=$DATA_DICTIONARY_CORE_ROW_COUNT"
echo "COMMON_COLUMN_SPOT_COUNT=$COMMON_COLUMN_SPOT_COUNT"
echo "BUSINESS_CODE_SPOT_COUNT=$BUSINESS_CODE_SPOT_COUNT"
echo "CORE_INDEX_SPOT_COUNT=$CORE_INDEX_SPOT_COUNT"
echo "CORE_CONSTRAINT_SPOT_COUNT=$CORE_CONSTRAINT_SPOT_COUNT"
echo "MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
echo "FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FINAL_STATUS" = "PASS" ] && [ "$FINAL_SEAL_STATUS" = "SEALED" ]; then
  echo "FAZ_1_1_4_COMMON_COLUMN_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_MODEL_STATUS=PASS"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_STATUS=PASS"
  echo "FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_FINAL_STATUS=PASS"
  echo "FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_SEAL_STATUS=SEALED"
  echo "FAZ_1_R_ONCELIK_3_READY=YES"
else
  echo "FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_FINAL_STATUS=FAIL"
  echo "FAZ_1_R_ONCELIK_2_DB_L1_CORE_MODEL_STANDARD_SEAL_STATUS=OPEN"
  echo "FAZ_1_R_ONCELIK_3_READY=NO"
  exit 1
fi

echo "===== FAZ 1-R ONCELIK 2 DB-L1 CORE MODEL STANDARD FINAL CLOSURE END ====="
