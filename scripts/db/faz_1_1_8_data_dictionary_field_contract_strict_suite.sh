#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_8_data_dictionary_field_contract_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT STRICT SUITE START ====="

mkdir -p "$BACKUP_DIR" "$EVIDENCE_DIR"
cd "$REPO"

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "1.1 common.env yüklendi"
else
  warn "1.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  source "$REPO/.env"
  set +a
  pass "1.2 repo .env yüklendi"
else
  warn "1.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "${DSN:-}" ]; then pass "2. DB DSN bulundu"; else fail "2. DB DSN bulunamadı"; exit 1; fi
if command -v psql >/dev/null 2>&1; then pass "3. psql mevcut"; else fail "3. psql bulunamadı"; exit 1; fi
if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then pass "4. DB bağlantısı başarılı"; else fail "4. DB bağlantısı başarısız"; exit 1; fi

echo "5. data dictionary / field contract sayaçları alınıyor..."

SOURCE_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%';
")"

SOURCE_FIELD_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns c
  join information_schema.tables t
    on t.table_schema=c.table_schema
   and t.table_name=c.table_name
   and t.table_type='BASE TABLE'
  where c.table_schema not in ('pg_catalog','information_schema','pg_toast')
    and c.table_schema not like 'pg_%';
")"

DICT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='app_dictionary'
    and table_name in ('table_contracts','field_contracts','field_contract_audit');
")"

DICT_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='app_dictionary'
    and p.proname in ('derive_owner_domain','derive_field_type_standard','derive_required_policy');
")"

TABLE_CONTRACT_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts;")"
FIELD_CONTRACT_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts;")"
OWNER_DOMAIN_COUNT="$(scalar_count "select count(distinct owner_domain) from app_dictionary.field_contracts;")"
OWNER_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(owner_domain,''))='';")"
REQUIRED_POLICY_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(required_policy,''))='';")"
TYPE_STANDARD_MISSING_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where btrim(coalesce(field_type_standard,''))='';")"
AUDIT_FAIL_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contract_audit where audit_run_id='FAZ_1_1_8_CURRENT' and audit_status='FAIL';")"
AUDIT_PASS_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contract_audit where audit_run_id='FAZ_1_1_8_CURRENT' and audit_status='PASS';")"
REQUIRED_STANDARD_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where required_policy='REQUIRED_STANDARD';")"
OPTIONAL_POLICY_COUNT="$(scalar_count "select count(*) from app_dictionary.field_contracts where required_policy in ('OPTIONAL','OPTIONAL_CONTEXTUAL','SYSTEM_DEFAULT');")"
TYPE_STANDARD_COUNT="$(scalar_count "select count(distinct field_type_standard) from app_dictionary.field_contracts;")"

echo "SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
echo "SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
echo "DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
echo "DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
echo "TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
echo "FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
echo "OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
echo "OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
echo "REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
echo "TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
echo "AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
echo "AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
echo "REQUIRED_STANDARD_COUNT=$REQUIRED_STANDARD_COUNT"
echo "OPTIONAL_POLICY_COUNT=$OPTIONAL_POLICY_COUNT"
echo "TYPE_STANDARD_COUNT=$TYPE_STANDARD_COUNT"

[ "$DICT_TABLE_COUNT" -ge 3 ] && pass "5.1 data dictionary tablo seti hazır" || fail "5.1 data dictionary tablo seti eksik"
[ "$DICT_FUNCTION_COUNT" -ge 3 ] && pass "5.2 helper function seti hazır" || fail "5.2 helper function seti eksik"
[ "$TABLE_CONTRACT_COUNT" -eq "$SOURCE_TABLE_COUNT" ] && pass "5.3 data dictionary tablo kapsamı tam" || fail "5.3 data dictionary tablo kapsamı eksik"
[ "$FIELD_CONTRACT_COUNT" -eq "$SOURCE_FIELD_COUNT" ] && pass "5.4 field contract kapsamı tam" || fail "5.4 field contract kapsamı eksik"
[ "$OWNER_DOMAIN_COUNT" -gt 0 ] && pass "5.5 field ownership domain üretildi" || fail "5.5 field ownership domain yok"
[ "$OWNER_MISSING_COUNT" -eq 0 ] && pass "5.6 field ownership eksik yok" || fail "5.6 field ownership eksik var"
[ "$REQUIRED_POLICY_MISSING_COUNT" -eq 0 ] && pass "5.7 required/nullable standardı eksik yok" || fail "5.7 required/nullable standardı eksik var"
[ "$TYPE_STANDARD_MISSING_COUNT" -eq 0 ] && pass "5.8 field type standardı eksik yok" || fail "5.8 field type standardı eksik var"
[ "$AUDIT_FAIL_COUNT" -eq 0 ] && pass "5.9 field contract audit fail yok" || fail "5.9 field contract audit fail var"
[ "$AUDIT_PASS_COUNT" -gt 0 ] && pass "5.10 field contract audit pass kaydı var" || fail "5.10 field contract audit pass kaydı yok"
[ "$REQUIRED_STANDARD_COUNT" -gt 0 ] && pass "5.11 required standard policy kayıtları var" || fail "5.11 required standard policy kaydı yok"
[ "$OPTIONAL_POLICY_COUNT" -gt 0 ] && pass "5.12 optional/contextual policy kayıtları var" || fail "5.12 optional/contextual policy kaydı yok"
[ "$TYPE_STANDARD_COUNT" -gt 0 ] && pass "5.13 field type standard çeşitliliği var" || fail "5.13 field type standard çeşitliliği yok"

echo "6. strict SQL assertion suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/data_dictionary_field_contract_strict_assertion.sql"
SQL_SUITE_OUT="$BACKUP_DIR/data_dictionary_field_contract_strict_assertion.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_source_tables int;
  v_source_fields int;
  v_table_contracts int;
  v_field_contracts int;
  v_missing_owner int;
  v_missing_required int;
  v_missing_type int;
  v_audit_fail int;
  v_audit_pass int;
  v_missing_table_contracts int;
  v_missing_field_contracts int;
BEGIN
  SELECT count(*)
  INTO v_source_tables
  FROM information_schema.tables
  WHERE table_type='BASE TABLE'
    AND table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND table_schema NOT LIKE 'pg_%';

  SELECT count(*)
  INTO v_source_fields
  FROM information_schema.columns c
  JOIN information_schema.tables t
    ON t.table_schema=c.table_schema
   AND t.table_name=c.table_name
   AND t.table_type='BASE TABLE'
  WHERE c.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND c.table_schema NOT LIKE 'pg_%';

  SELECT count(*) INTO v_table_contracts FROM app_dictionary.table_contracts;
  SELECT count(*) INTO v_field_contracts FROM app_dictionary.field_contracts;

  IF v_table_contracts <> v_source_tables THEN
    RAISE EXCEPTION 'table contract coverage mismatch source=% contract=%', v_source_tables, v_table_contracts;
  END IF;

  IF v_field_contracts <> v_source_fields THEN
    RAISE EXCEPTION 'field contract coverage mismatch source=% contract=%', v_source_fields, v_field_contracts;
  END IF;

  SELECT count(*) INTO v_missing_owner
  FROM app_dictionary.field_contracts
  WHERE btrim(coalesce(owner_domain,''))='';

  IF v_missing_owner <> 0 THEN
    RAISE EXCEPTION 'missing owner_domain count=%', v_missing_owner;
  END IF;

  SELECT count(*) INTO v_missing_required
  FROM app_dictionary.field_contracts
  WHERE btrim(coalesce(required_policy,''))='';

  IF v_missing_required <> 0 THEN
    RAISE EXCEPTION 'missing required_policy count=%', v_missing_required;
  END IF;

  SELECT count(*) INTO v_missing_type
  FROM app_dictionary.field_contracts
  WHERE btrim(coalesce(field_type_standard,''))='';

  IF v_missing_type <> 0 THEN
    RAISE EXCEPTION 'missing field_type_standard count=%', v_missing_type;
  END IF;

  SELECT count(*) INTO v_missing_table_contracts
  FROM information_schema.tables t
  WHERE t.table_type='BASE TABLE'
    AND t.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND t.table_schema NOT LIKE 'pg_%'
    AND NOT EXISTS (
      SELECT 1 FROM app_dictionary.table_contracts tc
      WHERE tc.schema_name=t.table_schema
        AND tc.table_name=t.table_name
    );

  IF v_missing_table_contracts <> 0 THEN
    RAISE EXCEPTION 'missing table contracts count=%', v_missing_table_contracts;
  END IF;

  SELECT count(*) INTO v_missing_field_contracts
  FROM information_schema.columns c
  JOIN information_schema.tables t
    ON t.table_schema=c.table_schema
   AND t.table_name=c.table_name
   AND t.table_type='BASE TABLE'
  WHERE c.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND c.table_schema NOT LIKE 'pg_%'
    AND NOT EXISTS (
      SELECT 1 FROM app_dictionary.field_contracts fc
      WHERE fc.schema_name=c.table_schema
        AND fc.table_name=c.table_name
        AND fc.column_name=c.column_name
    );

  IF v_missing_field_contracts <> 0 THEN
    RAISE EXCEPTION 'missing field contracts count=%', v_missing_field_contracts;
  END IF;

  SELECT count(*) INTO v_audit_fail
  FROM app_dictionary.field_contract_audit
  WHERE audit_run_id='FAZ_1_1_8_CURRENT'
    AND audit_status='FAIL';

  IF v_audit_fail <> 0 THEN
    RAISE EXCEPTION 'field contract audit fail count=%', v_audit_fail;
  END IF;

  SELECT count(*) INTO v_audit_pass
  FROM app_dictionary.field_contract_audit
  WHERE audit_run_id='FAZ_1_1_8_CURRENT'
    AND audit_status='PASS';

  IF v_audit_pass < 1 THEN
    RAISE EXCEPTION 'field contract audit pass marker missing';
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "6.1 strict SQL assertion suite geçti"
else
  fail "6.1 strict SQL assertion suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "6.2 strict SQL suite rollback ile temizlendi"
else
  fail "6.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-1.8 Data Dictionary / Field Contract Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
  echo "- SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
  echo "- DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
  echo "- DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
  echo "- TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
  echo "- FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
  echo "- OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
  echo "- OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
  echo "- REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
  echo "- TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
  echo "- AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
  echo "- AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
  echo "- REQUIRED_STANDARD_COUNT=$REQUIRED_STANDARD_COUNT"
  echo "- OPTIONAL_POLICY_COUNT=$OPTIONAL_POLICY_COUNT"
  echo "- TYPE_STANDARD_COUNT=$TYPE_STANDARD_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "SOURCE_TABLE_COUNT=$SOURCE_TABLE_COUNT"
echo "SOURCE_FIELD_COUNT=$SOURCE_FIELD_COUNT"
echo "DICT_TABLE_COUNT=$DICT_TABLE_COUNT"
echo "DICT_FUNCTION_COUNT=$DICT_FUNCTION_COUNT"
echo "TABLE_CONTRACT_COUNT=$TABLE_CONTRACT_COUNT"
echo "FIELD_CONTRACT_COUNT=$FIELD_CONTRACT_COUNT"
echo "OWNER_DOMAIN_COUNT=$OWNER_DOMAIN_COUNT"
echo "OWNER_MISSING_COUNT=$OWNER_MISSING_COUNT"
echo "REQUIRED_POLICY_MISSING_COUNT=$REQUIRED_POLICY_MISSING_COUNT"
echo "TYPE_STANDARD_MISSING_COUNT=$TYPE_STANDARD_MISSING_COUNT"
echo "AUDIT_PASS_COUNT=$AUDIT_PASS_COUNT"
echo "AUDIT_FAIL_COUNT=$AUDIT_FAIL_COUNT"
echo "REQUIRED_STANDARD_COUNT=$REQUIRED_STANDARD_COUNT"
echo "OPTIONAL_POLICY_COUNT=$OPTIONAL_POLICY_COUNT"
echo "TYPE_STANDARD_COUNT=$TYPE_STANDARD_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_8_DATA_DICTIONARY_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_OWNERSHIP_STATUS=PASS"
  echo "FAZ_1_1_8_REQUIRED_NULLABLE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_TYPE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_8_FIELD_CONTRACT_AUDIT_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_8_DATA_DICTIONARY_FIELD_CONTRACT_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.8 DATA DICTIONARY / FIELD CONTRACT STRICT SUITE END ====="
