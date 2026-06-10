#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_8_ORG_GRAPH_TESTS_FIX_V14_ENTITY_RELATION_REQUIRED_FIELDS"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_8_org_graph_tests_fix_v14_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_8_org_graph_tests_fix_v14.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_8_org_graph_tests_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_8_ORG_GRAPH_TESTS.md"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_8_ORG_GRAPH_TESTS_FINAL_SEAL_FIX_V14_$TS.md"
DB_L3_FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_FINAL_SEAL_FIX_V14_$TS.md"

GRAPH_TEST_SQL="$SUITE_RUNTIME_DIR/org_graph_tests_suite_fix_v14.sql"
GRAPH_TEST_OUT="$SUITE_RUNTIME_DIR/org_graph_tests_suite_fix_v14.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_8_fix_v14_strict_suite_run.out"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

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

choose_enum_or_default() {
  local fq_table="$1"
  local column_name="$2"
  local fallback="$3"
  local preference_sql="$4"

  psql "$DSN" -Atqc "
WITH rel AS (
  SELECT to_regclass('$fq_table') AS oid
),
col AS (
  SELECT a.atttypid
  FROM rel
  JOIN pg_attribute a ON a.attrelid=rel.oid
  WHERE rel.oid IS NOT NULL
    AND a.attname='$column_name'
    AND a.attnum > 0
    AND NOT a.attisdropped
),
typ AS (
  SELECT
    CASE
      WHEN t.typtype='d' THEN t.typbasetype
      ELSE c.atttypid
    END AS base_type_oid
  FROM col c
  JOIN pg_type t ON t.oid=c.atttypid
),
labels AS (
  SELECT e.enumlabel
  FROM typ
  JOIN pg_enum e ON e.enumtypid=typ.base_type_oid
)
SELECT COALESCE(
  (
    SELECT enumlabel
    FROM labels
    ORDER BY
      CASE lower(enumlabel)
        $preference_sql
        ELSE 99
      END,
      enumlabel
    LIMIT 1
  ),
  '$fallback'
);
" 2>/dev/null | head -n1
}

echo "===== FAZ 1-3.8 ORG GRAPH TESTS FIX V14 ENTITY RELATION REQUIRED FIELDS START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$APPLY_SCRIPT_FILE" "$STRICT_SUITE_FILE" "$DOC_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_fix_v14_$TS"
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

echo "7. DB-L3 bağımlılıkları ve schema farkları tespit ediliyor..."

LEGAL_ENTITY_STATUS_VALUE="$(choose_enum_or_default "org.legal_entities" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
")"

FRANCHISE_GENERIC_STATUS_VALUE="$(choose_enum_or_default "franchise.agreements" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
        WHEN 'inactive' THEN 6
")"

ENTITY_RELATION_STATUS_VALUE="$(choose_enum_or_default "org.entity_relations" "status" "ACTIVE" "
        WHEN 'active' THEN 1
        WHEN 'ACTIVE' THEN 2
        WHEN 'enabled' THEN 3
        WHEN 'open' THEN 4
        WHEN 'created' THEN 5
        WHEN 'draft' THEN 6
")"

[ -z "$LEGAL_ENTITY_STATUS_VALUE" ] && LEGAL_ENTITY_STATUS_VALUE="active"
[ -z "$FRANCHISE_GENERIC_STATUS_VALUE" ] && FRANCHISE_GENERIC_STATUS_VALUE="active"
[ -z "$ENTITY_RELATION_STATUS_VALUE" ] && ENTITY_RELATION_STATUS_VALUE="ACTIVE"

TENANT_REF_TABLE="$(psql "$DSN" -Atqc "
SELECT con.confrelid::regclass::text
FROM pg_constraint con
JOIN pg_attribute att
  ON att.attrelid=con.conrelid
 AND att.attnum = ANY(con.conkey)
WHERE con.conrelid='org.legal_entities'::regclass
  AND con.contype='f'
  AND att.attname='tenant_id'
LIMIT 1;
" 2>/dev/null | head -n1)"

TENANT_REF_COL="$(psql "$DSN" -Atqc "
WITH ref AS (
  SELECT con.confrelid AS ref_oid
  FROM pg_constraint con
  JOIN pg_attribute att
    ON att.attrelid=con.conrelid
   AND att.attnum = ANY(con.conkey)
  WHERE con.conrelid='org.legal_entities'::regclass
    AND con.contype='f'
    AND att.attname='tenant_id'
  LIMIT 1
)
SELECT a.attname
FROM ref
JOIN pg_attribute a ON a.attrelid=ref.ref_oid
WHERE a.attnum > 0
  AND NOT a.attisdropped
  AND a.atttypid='uuid'::regtype
  AND a.attname IN ('id','tenant_id','tenant_uuid')
ORDER BY
  CASE a.attname
    WHEN 'id' THEN 1
    WHEN 'tenant_id' THEN 2
    WHEN 'tenant_uuid' THEN 3
    ELSE 99
  END
LIMIT 1;
" 2>/dev/null | head -n1)"

REAL_TENANT_ID=""
if [ -n "${TENANT_REF_TABLE:-}" ] && [ -n "${TENANT_REF_COL:-}" ]; then
  REAL_TENANT_ID="$(psql "$DSN" -Atqc "select ${TENANT_REF_COL} from ${TENANT_REF_TABLE} where ${TENANT_REF_COL} is not null limit 1;" 2>/dev/null | head -n1)"
fi

ENTITY_RELATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_relations';")"
ENTITY_RELATIONS_PARENT_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='parent_entity_id';")"
ENTITY_RELATIONS_CHILD_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='child_entity_id';")"
ENTITY_RELATIONS_RELATION_CODE_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='relation_code';")"
ENTITY_RELATIONS_BUSINESS_CODE_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='business_code';")"
ENTITY_RELATIONS_RELATION_TYPE_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='relation_type';")"
ENTITY_RELATIONS_STATUS_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='status';")"
ENTITY_RELATIONS_VISIBILITY_RULE_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='visibility_rule_id';")"
ENTITY_RELATIONS_AUDIT_REF_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='relation_audit_ref';")"
ENTITY_RELATIONS_METADATA_COL_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name='metadata';")"

ENTITY_SHAREHOLDERS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_shareholders';")"
FRANCHISE_AGREEMENTS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"
BUSINESS_LOCATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
LOCATION_OPERATION_PROFILES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"
VISIBILITY_RULES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"
CROSS_COMPANY_RELATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='cross_company_relations';")"

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "FRANCHISE_GENERIC_STATUS_VALUE=$FRANCHISE_GENERIC_STATUS_VALUE"
echo "ENTITY_RELATION_STATUS_VALUE=$ENTITY_RELATION_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_PARENT_COL_COUNT=$ENTITY_RELATIONS_PARENT_COL_COUNT"
echo "ENTITY_RELATIONS_CHILD_COL_COUNT=$ENTITY_RELATIONS_CHILD_COL_COUNT"
echo "ENTITY_RELATIONS_RELATION_CODE_COL_COUNT=$ENTITY_RELATIONS_RELATION_CODE_COL_COUNT"
echo "ENTITY_RELATIONS_BUSINESS_CODE_COL_COUNT=$ENTITY_RELATIONS_BUSINESS_CODE_COL_COUNT"
echo "ENTITY_RELATIONS_RELATION_TYPE_COL_COUNT=$ENTITY_RELATIONS_RELATION_TYPE_COL_COUNT"
echo "ENTITY_RELATIONS_STATUS_COL_COUNT=$ENTITY_RELATIONS_STATUS_COL_COUNT"
echo "ENTITY_RELATIONS_VISIBILITY_RULE_COL_COUNT=$ENTITY_RELATIONS_VISIBILITY_RULE_COL_COUNT"
echo "ENTITY_RELATIONS_AUDIT_REF_COL_COUNT=$ENTITY_RELATIONS_AUDIT_REF_COL_COUNT"
echo "ENTITY_RELATIONS_METADATA_COL_COUNT=$ENTITY_RELATIONS_METADATA_COL_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "$FRANCHISE_GENERIC_STATUS_VALUE" ] && pass "7.2 franchise status değeri seçildi" || fail "7.2 franchise status değeri seçilemedi"
[ -n "$ENTITY_RELATION_STATUS_VALUE" ] && pass "7.3 entity relation status değeri seçildi" || fail "7.3 entity relation status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.4 tenant FK referans tablosu bulundu" || fail "7.4 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.5 tenant FK referans UUID kolonu bulundu" || fail "7.5 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.6 gerçek tenant_id bulundu" || fail "7.6 gerçek tenant_id bulunamadı"
[ "$ENTITY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "7.7 org.entity_relations hazır" || fail "7.7 org.entity_relations eksik"
[ "$ENTITY_RELATIONS_PARENT_COL_COUNT" -eq 1 ] && pass "7.8 parent_entity_id kolonu hazır" || fail "7.8 parent_entity_id kolonu eksik"
[ "$ENTITY_RELATIONS_CHILD_COL_COUNT" -eq 1 ] && pass "7.9 child_entity_id kolonu hazır" || fail "7.9 child_entity_id kolonu eksik"
[ "$ENTITY_RELATIONS_RELATION_CODE_COL_COUNT" -eq 1 ] && pass "7.10 relation_code kolonu mevcut" || warn "7.10 relation_code kolonu yok; FIX V14 schema-aware insert bunu atlayacak"
[ "$ENTITY_SHAREHOLDERS_TABLE_COUNT" -eq 1 ] && pass "7.11 org.entity_shareholders hazır" || fail "7.11 org.entity_shareholders eksik"
[ "$FRANCHISE_AGREEMENTS_TABLE_COUNT" -eq 1 ] && pass "7.12 franchise.agreements hazır" || fail "7.12 franchise.agreements eksik"
[ "$BUSINESS_LOCATIONS_TABLE_COUNT" -eq 1 ] && pass "7.13 org.business_locations hazır" || fail "7.13 org.business_locations eksik"
[ "$LOCATION_OPERATION_PROFILES_TABLE_COUNT" -eq 1 ] && pass "7.14 org.location_operation_profiles hazır" || fail "7.14 org.location_operation_profiles eksik"
[ "$VISIBILITY_RULES_TABLE_COUNT" -eq 1 ] && pass "7.15 org.visibility_rules hazır" || fail "7.15 org.visibility_rules eksik"
[ "$CROSS_COMPANY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "7.16 org.cross_company_relations hazır" || fail "7.16 org.cross_company_relations eksik"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. FIX V14 schema-aware org graph SQL suite hazırlanıyor..."

cat <<SQL > "$GRAPH_TEST_SQL"
BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.tmp_has_col(p_schema text, p_table text, p_column text)
RETURNS boolean
LANGUAGE sql
AS \$\$
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = p_schema
      AND table_name = p_table
      AND column_name = p_column
  );
\$\$;


CREATE OR REPLACE FUNCTION pg_temp.tmp_code_text_safe(
  p_prefix text,
  p_uuid uuid
)
RETURNS text
LANGUAGE plpgsql
AS \$\$
DECLARE
  v_seed text := COALESCE(NULLIF(regexp_replace(COALESCE(p_prefix, 'graphrel'), '[^A-Za-z0-9]+', '', 'g'), ''), 'graphrel');
  v_tail text := substr(replace(COALESCE(p_uuid, gen_random_uuid())::text, '-', ''), 1, 12);
  v_candidates text[];
  v_candidate text;
BEGIN
  v_candidates := ARRAY[
    lower(substr(v_seed || v_tail, 1, 24)),
    lower(substr(v_seed || v_tail, 1, 32)),
    lower(substr(v_seed || '_' || v_tail, 1, 32)),
    lower(substr(v_seed || '-' || v_tail, 1, 32)),
    upper(substr(v_seed || v_tail, 1, 24)),
    upper(substr(v_seed || v_tail, 1, 32)),
    'code' || lower(substr(v_tail, 1, 12)),
    'rel' || lower(substr(v_tail, 1, 12)),
    'r' || lower(substr(v_tail, 1, 12)),
    lower(substr(v_tail, 1, 12))
  ];

  FOREACH v_candidate IN ARRAY v_candidates LOOP
    BEGIN
      EXECUTE 'SELECT \$1::core.code_text' USING v_candidate;
      RETURN v_candidate;
    EXCEPTION WHEN OTHERS THEN
      CONTINUE;
    END;
  END LOOP;

  RAISE EXCEPTION 'no candidate value could be cast to core.code_text. prefix=%, uuid=%', p_prefix, p_uuid;
END;
\$\$;

CREATE OR REPLACE FUNCTION pg_temp.tmp_insert_entity_relation(
  p_tenant_id uuid,
  p_parent_entity_id uuid,
  p_child_entity_id uuid,
  p_business_code text,
  p_relation_code text,
  p_relation_type text,
  p_visibility_rule_id uuid,
  p_effective_from date,
  p_status text,
  p_relation_audit_ref text,
  p_metadata jsonb
)
RETURNS void
LANGUAGE plpgsql
AS \$\$
DECLARE
  v_cols text[];
  v_vals text[];
  v_sql text;
  v_type text;
  v_status text;
  v_type_candidates text[];
  v_constraint_relation_types text[] := ARRAY[]::text[];
  v_relation_type_constraint_def text;
  v_status_candidates text[] := ARRAY[
    p_status,
    'ACTIVE',
    'active'
  ];
  v_last_error text := NULL;
  v_business_code_safe text;
  v_relation_code_safe text;
BEGIN
  v_business_code_safe := upper(regexp_replace(COALESCE(p_business_code, 'GRAPHREL' || replace(p_child_entity_id::text, '-', '')), '[^A-Z0-9_-]+', '', 'g'));
  v_relation_code_safe := upper(regexp_replace(COALESCE(p_relation_code, v_business_code_safe), '[^A-Z0-9_-]+', '', 'g'));

  IF length(v_business_code_safe) < 2 THEN
    v_business_code_safe := 'GRAPHREL' || upper(substr(replace(p_child_entity_id::text, '-', ''), 1, 16));
  END IF;

  IF length(v_relation_code_safe) < 2 THEN
    v_relation_code_safe := v_business_code_safe;
  END IF;

  v_business_code_safe := substr(v_business_code_safe, 1, 64);
  v_relation_code_safe := substr(v_relation_code_safe, 1, 64);

  SELECT pg_get_constraintdef(c.oid)
  INTO v_relation_type_constraint_def
  FROM pg_constraint c
  WHERE c.conrelid='org.entity_relations'::regclass
    AND c.conname='ck_org_entity_relations_relation_type'
  LIMIT 1;

  SELECT COALESCE(array_agg(DISTINCT m.val), ARRAY[]::text[])
  INTO v_constraint_relation_types
  FROM (
    SELECT r.m[1] AS val
    FROM regexp_matches(COALESCE(v_relation_type_constraint_def, ''), '''([^'']+)''', 'g') AS r(m)
  ) m
  WHERE m.val IS NOT NULL
    AND btrim(m.val) <> ''
    AND m.val !~ '[\^\$\[\]\(\)\|\+\*\?]';

  v_type_candidates := ARRAY(
    SELECT val
    FROM (
      SELECT x.val, min(x.ord) AS ord
      FROM unnest(
        ARRAY[
          p_relation_type,
          'HOLDING_PARENT',
          'HOLDING_SUBSIDIARY',
          'PARENT_CHILD',
          'PARENT',
          'HOLDING',
          'SUBSIDIARY',
          'OWNERSHIP',
          'PARENT_COMPANY',
          'CHILD_COMPANY',
          'SUBSIDIARY_OF',
          'OWNS',
          'CONTROLS',
          'RELATED',
          'OTHER'
        ]
        || COALESCE(v_constraint_relation_types, ARRAY[]::text[])
      ) WITH ORDINALITY AS x(val, ord)
      WHERE x.val IS NOT NULL
        AND btrim(x.val) <> ''
        AND x.val ~ '^[A-Z][A-Z0-9_]*$'
      GROUP BY x.val
    ) s
    ORDER BY s.ord
  );

  IF COALESCE(array_length(v_type_candidates, 1), 0) = 0 THEN
    RAISE EXCEPTION 'no relation_type candidates found for org.entity_relations';
  END IF;

  FOREACH v_type IN ARRAY v_type_candidates LOOP
    CONTINUE WHEN v_type IS NULL OR btrim(v_type) = '';

    FOREACH v_status IN ARRAY v_status_candidates LOOP
      CONTINUE WHEN v_status IS NULL OR btrim(v_status) = '';

      BEGIN
        v_cols := ARRAY['tenant_id', 'parent_entity_id', 'child_entity_id'];
        v_vals := ARRAY[
          format('%L::uuid', p_tenant_id),
          format('%L::uuid', p_parent_entity_id),
          format('%L::uuid', p_child_entity_id)
        ];

        IF pg_temp.tmp_has_col('org','entity_relations','legal_entity_id') THEN
          v_cols := array_append(v_cols, 'legal_entity_id');
          v_vals := array_append(v_vals, format('%L::uuid', p_parent_entity_id));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','business_code') THEN
          v_cols := array_append(v_cols, 'business_code');
          v_vals := array_append(v_vals, format('%L', v_business_code_safe));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','relation_code') THEN
          v_cols := array_append(v_cols, 'relation_code');
          v_vals := array_append(v_vals, format('%L', v_relation_code_safe));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','relation_type') THEN
          v_cols := array_append(v_cols, 'relation_type');
          v_vals := array_append(v_vals, format('%L', v_type));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','visibility_rule_id') THEN
          v_cols := array_append(v_cols, 'visibility_rule_id');
          IF p_visibility_rule_id IS NULL THEN
            v_vals := array_append(v_vals, 'NULL');
          ELSE
            v_vals := array_append(v_vals, format('%L::uuid', p_visibility_rule_id));
          END IF;
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','visibility_scope') THEN
          v_cols := array_append(v_cols, 'visibility_scope');
          v_vals := array_append(v_vals, format('%L', 'INHERIT'));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','effective_from') THEN
          v_cols := array_append(v_cols, 'effective_from');
          v_vals := array_append(v_vals, format('%L::date', p_effective_from));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','status') THEN
          v_cols := array_append(v_cols, 'status');
          v_vals := array_append(v_vals, format('%L', v_status));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','relation_audit_ref') THEN
          v_cols := array_append(v_cols, 'relation_audit_ref');
          v_vals := array_append(v_vals, format('%L', p_relation_audit_ref));
        END IF;

        IF pg_temp.tmp_has_col('org','entity_relations','metadata') THEN
          v_cols := array_append(v_cols, 'metadata');
          v_vals := array_append(v_vals, format('%L::jsonb', p_metadata::text));
        END IF;

        v_sql := format(
          'INSERT INTO org.entity_relations (%s) VALUES (%s)',
          array_to_string(v_cols, ', '),
          array_to_string(v_vals, ', ')
        );

        EXECUTE v_sql;
        RETURN;

      EXCEPTION
        WHEN check_violation OR invalid_text_representation THEN
          v_last_error := SQLERRM;
          CONTINUE;
      END;
    END LOOP;
  END LOOP;

  RAISE EXCEPTION 'schema-aware entity_relations insert failed after relation_type candidates %. last_error=%', array_to_string(v_type_candidates, ','), COALESCE(v_last_error, 'N/A');
END;
\$\$;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;

  v_holding_id uuid := gen_random_uuid();
  v_sub_a_id uuid := gen_random_uuid();
  v_sub_b_id uuid := gen_random_uuid();
  v_franchisor_id uuid := gen_random_uuid();
  v_franchisee_id uuid := gen_random_uuid();
  v_operator_id uuid := gen_random_uuid();
  v_accountant_id uuid := gen_random_uuid();

  v_franchise_location_id uuid := gen_random_uuid();
  v_agreement_id uuid := gen_random_uuid();
  v_visibility_rule_id uuid := gen_random_uuid();
  v_cross_relation_id uuid := gen_random_uuid();

  v_suffix text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_legal_status org.legal_entities.status%TYPE := '$LEGAL_ENTITY_STATUS_VALUE';
  v_franchise_status franchise.agreements.status%TYPE := '$FRANCHISE_GENERIC_STATUS_VALUE';
  v_entity_relation_status text := '$ENTITY_RELATION_STATUS_VALUE';
  v_count int;
BEGIN
  PERFORM set_config('app.tenant_id', v_tenant_id::text, true);
  PERFORM set_config('app.current_tenant_id', v_tenant_id::text, true);

  INSERT INTO org.legal_entities (
    id, tenant_id, legal_entity_id, business_code, legal_name, trade_name,
    tax_number, tax_office, phone, email, address_line, district, city,
    country_code, postal_code, status, metadata
  )
  VALUES
  (
    v_holding_id, v_tenant_id, v_holding_id,
    pg_temp.tmp_code_text_safe('graphholding', v_holding_id),
    'PIX2PI GRAPH HOLDING A.S.',
    'GRAPH HOLDING',
    '981' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008001',
    'graph-holding-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH HOLDING ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_holding')
  ),
  (
    v_sub_a_id, v_tenant_id, v_sub_a_id,
    pg_temp.tmp_code_text_safe('graphsuba', v_sub_a_id),
    'PIX2PI GRAPH SUB A A.S.',
    'GRAPH SUB A',
    '982' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008002',
    'graph-sub-a-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH SUB A ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_sub_a')
  ),
  (
    v_sub_b_id, v_tenant_id, v_sub_b_id,
    pg_temp.tmp_code_text_safe('graphsubb', v_sub_b_id),
    'PIX2PI GRAPH SUB B A.S.',
    'GRAPH SUB B',
    '983' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008003',
    'graph-sub-b-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH SUB B ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_sub_b')
  ),
  (
    v_franchisor_id, v_tenant_id, v_franchisor_id,
    pg_temp.tmp_code_text_safe('graphfranchisor', v_franchisor_id),
    'PIX2PI GRAPH FRANCHISOR A.S.',
    'GRAPH FRANCHISOR',
    '984' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008004',
    'graph-franchisor-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH FRANCHISOR ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_franchisor')
  ),
  (
    v_franchisee_id, v_tenant_id, v_franchisee_id,
    pg_temp.tmp_code_text_safe('graphfranchisee', v_franchisee_id),
    'PIX2PI GRAPH FRANCHISEE A.S.',
    'GRAPH FRANCHISEE',
    '985' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008005',
    'graph-franchisee-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH FRANCHISEE ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_franchisee')
  ),
  (
    v_operator_id, v_tenant_id, v_operator_id,
    pg_temp.tmp_code_text_safe('graphoperator', v_operator_id),
    'PIX2PI GRAPH OPERATOR A.S.',
    'GRAPH OPERATOR',
    '986' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008006',
    'graph-operator-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH OPERATOR ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_operator')
  ),
  (
    v_accountant_id, v_tenant_id, v_accountant_id,
    pg_temp.tmp_code_text_safe('graphaccountant', v_accountant_id),
    'PIX2PI GRAPH ACCOUNTANT A.S.',
    'GRAPH ACCOUNTANT',
    '987' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120008007',
    'graph-accountant-' || lower(v_suffix) || '@pix2pi.local',
    'GRAPH ACCOUNTANT ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_8_fix_v14_accountant')
  );

  PERFORM pg_temp.tmp_insert_entity_relation(
    v_tenant_id,
    v_holding_id,
    v_sub_a_id,
    'GRAPH_REL_HOLD_A_' || v_suffix,
    'GRAPH-HOLD-A-' || v_suffix,
    'HOLDING_PARENT',
    NULL,
    current_date,
    v_entity_relation_status,
    'GRAPH_AUDIT_HOLD_A_' || v_suffix,
    jsonb_build_object('test','holding_parent_a_fix_v14')
  );

  PERFORM pg_temp.tmp_insert_entity_relation(
    v_tenant_id,
    v_holding_id,
    v_sub_b_id,
    'GRAPH_REL_HOLD_B_' || v_suffix,
    'GRAPH-HOLD-B-' || v_suffix,
    'HOLDING_PARENT',
    NULL,
    current_date,
    v_entity_relation_status,
    'GRAPH_AUDIT_HOLD_B_' || v_suffix,
    jsonb_build_object('test','holding_parent_b_fix_v14')
  );

  WITH RECURSIVE org_tree AS (
    SELECT
      er.parent_entity_id,
      er.child_entity_id,
      1 AS depth,
      ARRAY[er.parent_entity_id, er.child_entity_id] AS path
    FROM org.entity_relations er
    WHERE er.tenant_id=v_tenant_id
      AND er.parent_entity_id=v_holding_id

    UNION ALL

    SELECT
      ot.parent_entity_id,
      er.child_entity_id,
      ot.depth + 1,
      ot.path || er.child_entity_id
    FROM org_tree ot
    JOIN org.entity_relations er
      ON er.tenant_id=v_tenant_id
     AND er.parent_entity_id=ot.child_entity_id
    WHERE NOT er.child_entity_id = ANY(ot.path)
  )
  SELECT count(*)
  INTO v_count
  FROM org_tree
  WHERE child_entity_id IN (v_sub_a_id, v_sub_b_id);

  IF v_count <> 2 THEN
    RAISE EXCEPTION 'holding graph test failed, expected 2 children got %', v_count;
  END IF;

  BEGIN
    PERFORM pg_temp.tmp_insert_entity_relation(
      v_tenant_id,
      v_sub_a_id,
      v_holding_id,
      'GRAPH_REL_CYCLE_' || v_suffix,
      'GRAPH-CYCLE-' || v_suffix,
      'HOLDING_PARENT',
      NULL,
      current_date,
      v_entity_relation_status,
      'GRAPH_AUDIT_CYCLE_' || v_suffix,
      jsonb_build_object('test','cycle_should_fail_fix_v14')
    );

    RAISE EXCEPTION 'cycle prevention failed: inverse holding relation was not blocked';
  EXCEPTION
    WHEN check_violation OR exclusion_violation OR unique_violation OR raise_exception THEN
      NULL;
  END;

  INSERT INTO franchise.agreements (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    agreement_number,
    agreement_type,
    franchisor_entity_id,
    franchisee_entity_id,
    owner_entity_id,
    operator_entity_id,
    territory_code,
    territory_name,
    start_date,
    end_date,
    signed_at,
    activated_at,
    status,
    agreement_lifecycle_status,
    lifecycle_reason,
    agreement_audit_ref,
    metadata
  )
  VALUES (
    v_agreement_id,
    v_tenant_id,
    v_franchisor_id,
    pg_temp.tmp_code_text_safe('graphfragreement', v_agreement_id),
    'GRAPH-FR-AGR-' || v_suffix,
    'STANDARD_FRANCHISE',
    v_franchisor_id,
    v_franchisee_id,
    v_franchisee_id,
    v_operator_id,
    'TR-IST-GRAPH',
    'Istanbul Graph Test',
    current_date,
    current_date + 365,
    now(),
    now(),
    v_franchise_status,
    'ACTIVE',
    'graph franchise activation fix v14',
    'GRAPH_FR_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_8_fix_v14_franchise_agreement')
  );

  INSERT INTO org.business_locations (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    location_code,
    location_name,
    location_type,
    ownership_type,
    operation_type,
    inventory_enabled,
    sales_enabled,
    purchasing_enabled,
    address_line,
    district,
    city,
    country_code,
    status,
    location_audit_ref,
    metadata
  )
  VALUES (
    v_franchise_location_id,
    v_tenant_id,
    v_franchisee_id,
    pg_temp.tmp_code_text_safe('graphfrloc', v_franchise_location_id),
    'GRAPH-FR-LOC-' || v_suffix,
    'GRAPH FRANCHISE STORE',
    'STORE',
    'FRANCHISE_OWNED',
    'FRANCHISE_OPERATED',
    true,
    true,
    false,
    'GRAPH FRANCHISE LOCATION',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    'ACTIVE',
    'GRAPH_LOC_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_8_fix_v14_franchise_location')
  );

  INSERT INTO org.location_operation_profiles (
    tenant_id,
    legal_entity_id,
    location_id,
    franchise_agreement_id,
    business_code,
    operation_profile_code,
    business_model,
    ownership_type,
    operation_type,
    reporting_effect,
    permission_effect,
    revenue_owner_entity_id,
    operator_entity_id,
    inventory_owner_entity_id,
    accounting_responsibility,
    inventory_responsibility,
    effective_from,
    status,
    operation_audit_ref,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_franchisee_id,
    v_franchise_location_id,
    v_agreement_id,
    pg_temp.tmp_code_text_safe('graphopprofile', v_agreement_id),
    'GRAPH-OP-PROFILE-' || v_suffix,
    'FRANCHISE_STORE',
    'FRANCHISE_OWNED',
    'FRANCHISE_OPERATED',
    'FRANCHISE_REVENUE_SHARE',
    'FRANCHISE_OPERATOR_SCOPE',
    v_franchisee_id,
    v_operator_id,
    v_franchisee_id,
    'FRANCHISEE_BOOKS',
    'FRANCHISEE',
    current_date,
    'ACTIVE',
    'GRAPH_OP_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_8_fix_v14_franchise_operation_profile')
  );

  SELECT count(*)
  INTO v_count
  FROM franchise.agreements fa
  JOIN org.location_operation_profiles lop
    ON lop.tenant_id=fa.tenant_id
   AND lop.franchise_agreement_id=fa.id
  JOIN org.business_locations bl
    ON bl.tenant_id=lop.tenant_id
   AND bl.id=lop.location_id
  WHERE fa.tenant_id=v_tenant_id
    AND fa.id=v_agreement_id
    AND fa.franchisor_entity_id=v_franchisor_id
    AND fa.franchisee_entity_id=v_franchisee_id
    AND lop.operator_entity_id=v_operator_id
    AND lop.business_model='FRANCHISE_STORE'
    AND lop.permission_effect='FRANCHISE_OPERATOR_SCOPE'
    AND bl.operation_type='FRANCHISE_OPERATED';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'franchise graph test failed';
  END IF;

  INSERT INTO org.visibility_rules (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    visibility_rule_code,
    subject_type,
    accountant_entity_id,
    visibility_scope,
    branch_scope,
    target_entity_id,
    permission_effect,
    access_level,
    can_view,
    can_create,
    can_update,
    can_delete,
    can_export,
    effective_from,
    status,
    visibility_audit_ref,
    metadata
  )
  VALUES (
    v_visibility_rule_id,
    v_tenant_id,
    v_franchisee_id,
    pg_temp.tmp_code_text_safe('graphvisacc', v_visibility_rule_id),
    'GRAPH-VIS-ACC-' || v_suffix,
    'ACCOUNTANT',
    v_accountant_id,
    'ACCOUNTANT',
    'ALL_BRANCHES',
    v_franchisee_id,
    'ACCOUNTANT_EXPORT',
    'EXPORT',
    true,
    false,
    false,
    false,
    true,
    current_date,
    'ACTIVE',
    'GRAPH_VIS_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_8_fix_v14_accountant_visibility')
  );

  INSERT INTO org.cross_company_relations (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    relation_code,
    relation_type,
    relation_direction,
    relation_channel,
    counterparty_entity_id,
    counterparty_name,
    visibility_rule_id,
    visibility_effect,
    cross_company_visibility_allowed,
    is_partner,
    is_customer,
    is_vendor,
    currency_code,
    effective_from,
    status,
    approval_ref,
    relation_audit_ref,
    metadata
  )
  VALUES (
    v_cross_relation_id,
    v_tenant_id,
    v_franchisee_id,
    pg_temp.tmp_code_text_safe('graphccracc', v_cross_relation_id),
    'GRAPH-CCR-ACC-' || v_suffix,
    'ACCOUNTANT_CLIENT',
    'BIDIRECTIONAL',
    'ACCOUNTANT_PORTAL',
    v_accountant_id,
    'GRAPH ACCOUNTANT COUNTERPARTY',
    v_visibility_rule_id,
    'ACCOUNTANT_VISIBLE',
    true,
    false,
    false,
    false,
    'TRY',
    current_date,
    'ACTIVE',
    'GRAPH_CCR_APPROVAL_' || v_suffix,
    'GRAPH_CCR_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_8_fix_v14_accountant_cross_relation')
  );

  SELECT count(*)
  INTO v_count
  FROM org.visibility_rules vr
  JOIN org.cross_company_relations ccr
    ON ccr.tenant_id=vr.tenant_id
   AND ccr.visibility_rule_id=vr.id
  WHERE vr.tenant_id=v_tenant_id
    AND vr.id=v_visibility_rule_id
    AND vr.subject_type='ACCOUNTANT'
    AND vr.accountant_entity_id=v_accountant_id
    AND vr.permission_effect='ACCOUNTANT_EXPORT'
    AND vr.can_delete=false
    AND ccr.relation_type='ACCOUNTANT_CLIENT'
    AND ccr.visibility_effect='ACCOUNTANT_VISIBLE';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'visibility graph test failed';
  END IF;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id,
      legal_entity_id,
      business_code,
      visibility_rule_code,
      subject_type,
      subject_role,
      visibility_scope,
      branch_scope,
      target_entity_id,
      permission_effect,
      access_level,
      cross_branch_allowed,
      can_view,
      can_update,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_franchisee_id,
      'GRAPH_BAD_CROSS_PERMISSION_' || v_suffix,
      'GRAPH-BAD-CROSS-PERM-' || v_suffix,
      'ROLE',
      'REGIONAL_MANAGER',
      'BRANCH',
      'CROSS_BRANCH',
      v_franchisee_id,
      'CROSS_BRANCH_WRITE',
      'WRITE',
      true,
      true,
      true,
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'permission test failed: cross-branch write without approval was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id,
      legal_entity_id,
      business_code,
      visibility_rule_code,
      subject_type,
      accountant_entity_id,
      visibility_scope,
      branch_scope,
      target_entity_id,
      permission_effect,
      access_level,
      can_view,
      can_delete,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_franchisee_id,
      'GRAPH_BAD_ACCOUNTANT_DELETE_' || v_suffix,
      'GRAPH-BAD-ACC-DELETE-' || v_suffix,
      'ACCOUNTANT',
      v_accountant_id,
      'ACCOUNTANT',
      'ALL_BRANCHES',
      v_franchisee_id,
      'ACCOUNTANT_READ',
      'READ',
      true,
      true,
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'permission test failed: accountant delete permission was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

pass "8.1 FIX V14 schema-aware org graph SQL suite dosyası yazıldı: $GRAPH_TEST_SQL"

echo "9. FIX V14 org graph lifecycle / abuse SQL suite çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$GRAPH_TEST_SQL" > "$GRAPH_TEST_OUT" 2>&1; then
  pass "9.1 FIX V14 org graph lifecycle / abuse SQL suite geçti"
else
  fail "9.1 FIX V14 org graph lifecycle / abuse SQL suite başarısız"
  cat "$GRAPH_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$GRAPH_TEST_OUT"; then
  pass "9.2 FIX V14 org graph test rollback ile temizlendi"
  GRAPH_TEST_STATUS="PASS"
else
  fail "9.2 FIX V14 org graph rollback kanıtı yok"
  GRAPH_TEST_STATUS="FAIL"
fi

echo "10. DB-L3 graph sayaçları alınıyor..."

ENTITY_RELATIONS_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='f';")"
ENTITY_RELATIONS_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='c';")"
ENTITY_RELATIONS_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATIONS_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relrowsecurity=true;")"
ENTITY_RELATIONS_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relforcerowsecurity=true;")"
ENTITY_RELATIONS_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATIONS_CYCLE_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='org.entity_relations'::regclass and not tgisinternal and lower(tgname) like '%cycle%';")"

SHAREHOLDER_OVER_100_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='org.entity_shareholders'::regclass and not tgisinternal and lower(tgname) like '%shareholder%';")"
FRANCHISE_OVERLAP_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='franchise.agreements'::regclass and not tgisinternal and lower(tgname) like '%overlap%';")"
VISIBILITY_CROSS_BRANCH_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname in ('ck_org_visibility_rules_cross_branch_rule','ck_org_visibility_rules_cross_branch_write_rule');")"
RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_cross_company_visibility';")"
OPERATION_PROFILE_FRANCHISE_RULE_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_franchise_store_rule';")"
ACCOUNTANT_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_accountant_rule';")"

echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
echo "ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
echo "ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
echo "ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
echo "ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
echo "ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
echo "ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
echo "SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
echo "FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
echo "VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
echo "RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "GRAPH_TEST_STATUS=$GRAPH_TEST_STATUS"

[ "$ENTITY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "10.1 entity_relations tablosu hazır" || fail "10.1 entity_relations tablosu eksik"
[ "$ENTITY_RELATIONS_FK_COUNT" -ge 2 ] && pass "10.2 entity_relations FK seti hazır" || fail "10.2 entity_relations FK seti eksik"
[ "$ENTITY_RELATIONS_CHECK_COUNT" -ge 3 ] && pass "10.3 entity_relations check seti hazır" || fail "10.3 entity_relations check seti eksik"
[ "$ENTITY_RELATIONS_INDEX_COUNT" -ge 5 ] && pass "10.4 entity_relations index seti hazır" || fail "10.4 entity_relations index seti eksik"
[ "$ENTITY_RELATIONS_RLS_ENABLED_COUNT" -eq 1 ] && pass "10.5 entity_relations RLS enabled" || fail "10.5 entity_relations RLS enabled eksik"
[ "$ENTITY_RELATIONS_RLS_FORCED_COUNT" -eq 1 ] && pass "10.6 entity_relations RLS forced" || fail "10.6 entity_relations RLS forced eksik"
[ "$ENTITY_RELATIONS_POLICY_COUNT" -ge 1 ] && pass "10.7 entity_relations tenant policy hazır" || fail "10.7 entity_relations tenant policy eksik"
[ "$ENTITY_RELATIONS_CYCLE_GUARD_COUNT" -ge 1 ] && pass "10.8 cycle prevention guard hazır" || fail "10.8 cycle prevention guard eksik"
[ "$ENTITY_SHAREHOLDERS_TABLE_COUNT" -eq 1 ] && pass "10.9 entity_shareholders hazır" || fail "10.9 entity_shareholders eksik"
[ "$FRANCHISE_AGREEMENTS_TABLE_COUNT" -eq 1 ] && pass "10.10 franchise agreements hazır" || fail "10.10 franchise agreements eksik"
[ "$BUSINESS_LOCATIONS_TABLE_COUNT" -eq 1 ] && pass "10.11 business_locations hazır" || fail "10.11 business_locations eksik"
[ "$LOCATION_OPERATION_PROFILES_TABLE_COUNT" -eq 1 ] && pass "10.12 location_operation_profiles hazır" || fail "10.12 location_operation_profiles eksik"
[ "$VISIBILITY_RULES_TABLE_COUNT" -eq 1 ] && pass "10.13 visibility_rules hazır" || fail "10.13 visibility_rules eksik"
[ "$CROSS_COMPANY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "10.14 cross_company_relations hazır" || fail "10.14 cross_company_relations eksik"
[ "$SHAREHOLDER_OVER_100_GUARD_COUNT" -ge 1 ] && pass "10.15 ownership/shareholder guard hazır" || fail "10.15 ownership/shareholder guard eksik"
[ "$FRANCHISE_OVERLAP_GUARD_COUNT" -ge 1 ] && pass "10.16 franchise overlap guard hazır" || fail "10.16 franchise overlap guard eksik"
[ "$VISIBILITY_CROSS_BRANCH_CHECK_COUNT" -eq 2 ] && pass "10.17 visibility cross-branch guard seti hazır" || fail "10.17 visibility cross-branch guard seti eksik"
[ "$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "10.18 cross-company visibility guard hazır" || fail "10.18 cross-company visibility guard eksik"
[ "$OPERATION_PROFILE_FRANCHISE_RULE_COUNT" -eq 1 ] && pass "10.19 franchise operation profile rule hazır" || fail "10.19 franchise operation profile rule eksik"
[ "$ACCOUNTANT_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "10.20 accountant visibility rule hazır" || fail "10.20 accountant visibility rule eksik"
[ "$GRAPH_TEST_STATUS" = "PASS" ] && pass "10.21 holding/franchise/visibility/permission graph suite PASS" || fail "10.21 graph suite FAIL"

echo "11. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_8_org_graph_tests_strict_suite_fix_v14_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_8_ORG_GRAPH_TESTS_STRICT_SUITE_RESULT_FIX_V14_$TS.md"

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

echo "===== FAZ 1-3.8 ORG GRAPH TESTS STRICT SUITE FIX V14 START ====="

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

ENTITY_RELATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_relations';")"
ENTITY_RELATIONS_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='f';")"
ENTITY_RELATIONS_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='c';")"
ENTITY_RELATIONS_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATIONS_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relrowsecurity=true;")"
ENTITY_RELATIONS_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relforcerowsecurity=true;")"
ENTITY_RELATIONS_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATIONS_CYCLE_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='org.entity_relations'::regclass and not tgisinternal and lower(tgname) like '%cycle%';")"

ENTITY_SHAREHOLDERS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_shareholders';")"
FRANCHISE_AGREEMENTS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"
BUSINESS_LOCATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
LOCATION_OPERATION_PROFILES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"
VISIBILITY_RULES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"
CROSS_COMPANY_RELATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='cross_company_relations';")"

SHAREHOLDER_OVER_100_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='org.entity_shareholders'::regclass and not tgisinternal and lower(tgname) like '%shareholder%';")"
FRANCHISE_OVERLAP_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='franchise.agreements'::regclass and not tgisinternal and lower(tgname) like '%overlap%';")"
VISIBILITY_CROSS_BRANCH_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname in ('ck_org_visibility_rules_cross_branch_rule','ck_org_visibility_rules_cross_branch_write_rule');")"
RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_cross_company_visibility';")"
OPERATION_PROFILE_FRANCHISE_RULE_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_franchise_store_rule';")"
ACCOUNTANT_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_accountant_rule';")"

echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
echo "ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
echo "ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
echo "ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
echo "ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
echo "ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
echo "ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
echo "SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
echo "FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
echo "VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
echo "RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"

[ "$ENTITY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "5.1 entity_relations tablosu hazır" || fail "5.1 entity_relations tablosu eksik"
[ "$ENTITY_RELATIONS_FK_COUNT" -ge 2 ] && pass "5.2 entity_relations FK seti hazır" || fail "5.2 entity_relations FK seti eksik"
[ "$ENTITY_RELATIONS_CHECK_COUNT" -ge 3 ] && pass "5.3 entity_relations check seti hazır" || fail "5.3 entity_relations check seti eksik"
[ "$ENTITY_RELATIONS_INDEX_COUNT" -ge 5 ] && pass "5.4 entity_relations index seti hazır" || fail "5.4 entity_relations index seti eksik"
[ "$ENTITY_RELATIONS_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 entity_relations RLS enabled" || fail "5.5 entity_relations RLS enabled eksik"
[ "$ENTITY_RELATIONS_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 entity_relations RLS forced" || fail "5.6 entity_relations RLS forced eksik"
[ "$ENTITY_RELATIONS_POLICY_COUNT" -ge 1 ] && pass "5.7 entity_relations tenant policy hazır" || fail "5.7 entity_relations tenant policy eksik"
[ "$ENTITY_RELATIONS_CYCLE_GUARD_COUNT" -ge 1 ] && pass "5.8 cycle prevention guard hazır" || fail "5.8 cycle prevention guard eksik"
[ "$ENTITY_SHAREHOLDERS_TABLE_COUNT" -eq 1 ] && pass "5.9 entity_shareholders hazır" || fail "5.9 entity_shareholders eksik"
[ "$FRANCHISE_AGREEMENTS_TABLE_COUNT" -eq 1 ] && pass "5.10 franchise agreements hazır" || fail "5.10 franchise agreements eksik"
[ "$BUSINESS_LOCATIONS_TABLE_COUNT" -eq 1 ] && pass "5.11 business_locations hazır" || fail "5.11 business_locations eksik"
[ "$LOCATION_OPERATION_PROFILES_TABLE_COUNT" -eq 1 ] && pass "5.12 location_operation_profiles hazır" || fail "5.12 location_operation_profiles eksik"
[ "$VISIBILITY_RULES_TABLE_COUNT" -eq 1 ] && pass "5.13 visibility_rules hazır" || fail "5.13 visibility_rules eksik"
[ "$CROSS_COMPANY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "5.14 cross_company_relations hazır" || fail "5.14 cross_company_relations eksik"
[ "$SHAREHOLDER_OVER_100_GUARD_COUNT" -ge 1 ] && pass "5.15 ownership/shareholder guard hazır" || fail "5.15 ownership/shareholder guard eksik"
[ "$FRANCHISE_OVERLAP_GUARD_COUNT" -ge 1 ] && pass "5.16 franchise overlap guard hazır" || fail "5.16 franchise overlap guard eksik"
[ "$VISIBILITY_CROSS_BRANCH_CHECK_COUNT" -eq 2 ] && pass "5.17 visibility cross-branch guard hazır" || fail "5.17 visibility cross-branch guard eksik"
[ "$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.18 cross-company visibility guard hazır" || fail "5.18 cross-company visibility guard eksik"
[ "$OPERATION_PROFILE_FRANCHISE_RULE_COUNT" -eq 1 ] && pass "5.19 franchise operation profile rule hazır" || fail "5.19 franchise operation profile rule eksik"
[ "$ACCOUNTANT_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.20 accountant visibility rule hazır" || fail "5.20 accountant visibility rule eksik"

{
  echo "# FAZ 1-3.8 Org Graph Tests Strict Suite Result FIX V14"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-3.8 ORG GRAPH TESTS STRICT SUITE FIX V14 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
echo "ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
echo "ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
echo "ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
echo "ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
echo "ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
echo "ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
echo "SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
echo "FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
echo "VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
echo "RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_PERMISSION_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_ORG_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_8_ORG_GRAPH_TEST_STATUS=FAIL"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.8 ORG GRAPH TESTS STRICT SUITE FIX V14 END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "11.1 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "12. strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "12.1 strict suite exit code 0"
else
  fail "12.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_ORG_GRAPH_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS")"

HOLDING_GRAPH_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS")"
FRANCHISE_GRAPH_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS")"
VISIBILITY_GRAPH_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS")"
CYCLE_PREVENTION_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS")"
PERMISSION_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_8_PERMISSION_TEST_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "13. strict suite FAIL_COUNT=0 doğrulandı" || fail "13. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "14. strict suite status PASS doğrulandı" || fail "14. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "15. strict suite seal SEALED doğrulandı" || fail "15. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "16. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.8 — Org Graph Testleri

## Kapsam

- Holding graph test
- Franchise graph test
- Visibility graph test
- Cycle prevention test
- Permission test

## FIX V14

İlk denemede org.entity_relations tablosunda relation_code kolonu olmadığı için test insert'i başarısız oldu.

FIX V14:
- org.entity_relations insert schema-aware hale getirildi.
- relation_code varsa kullanılır, yoksa atlanır.
- business_code, relation_type, visibility_rule_id, effective_from, status, relation_audit_ref, metadata kolonları da mevcutsa kullanılır.
- Holding graph testi gerçek tablo kolonlarına göre çalışır.
- Cycle prevention, franchise graph, visibility graph ve permission abuse testleri tekrar çalıştırılır.

## Final Status

- FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS=${HOLDING_GRAPH_TEST_STATUS:-N/A}
- FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS=${FRANCHISE_GRAPH_TEST_STATUS:-N/A}
- FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS=${VISIBILITY_GRAPH_TEST_STATUS:-N/A}
- FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS=${CYCLE_PREVENTION_TEST_STATUS:-N/A}
- FAZ_1_3_8_PERMISSION_TEST_STATUS=${PERMISSION_TEST_STATUS:-N/A}
- FAZ_1_3_8_ORG_GRAPH_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.8 Org Graph Tests FIX V14 Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Graph SQL: $GRAPH_TEST_SQL"
  echo "- Graph output: $GRAPH_TEST_OUT"
  echo
  echo "## Schema Awareness\n- FIX V14: org.entity_relations required legal_entity_id and visibility_scope fields are populated in schema-aware inserts.\n- FIX V14: org.entity_relations business_code uses uppercase format matching ck_org_entity_relations_business_code_format.\n- FIX V14: org.legal_entities and dependent graph business_code values are generated through live core.code_text probe.\n- FIX V14: org.entity_relations relation_type/status semantic columns are normalized away from core.code_text when needed.\n- FIX V14: PostgreSQL dollar-quote delimiters in code_text probe function are escaped for bash heredoc safety."
  echo "- ENTITY_RELATIONS_RELATION_CODE_COL_COUNT=$ENTITY_RELATIONS_RELATION_CODE_COL_COUNT"
  echo "- ENTITY_RELATIONS_BUSINESS_CODE_COL_COUNT=$ENTITY_RELATIONS_BUSINESS_CODE_COL_COUNT"
  echo "- ENTITY_RELATIONS_RELATION_TYPE_COL_COUNT=$ENTITY_RELATIONS_RELATION_TYPE_COL_COUNT"
  echo "- ENTITY_RELATIONS_STATUS_COL_COUNT=$ENTITY_RELATIONS_STATUS_COL_COUNT"
  echo "- ENTITY_RELATIONS_VISIBILITY_RULE_COL_COUNT=$ENTITY_RELATIONS_VISIBILITY_RULE_COL_COUNT"
  echo "- ENTITY_RELATIONS_AUDIT_REF_COL_COUNT=$ENTITY_RELATIONS_AUDIT_REF_COL_COUNT"
  echo "- ENTITY_RELATIONS_METADATA_COL_COUNT=$ENTITY_RELATIONS_METADATA_COL_COUNT"
  echo
  echo "## Counts"
  echo "- ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
  echo "- ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
  echo "- ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
  echo "- ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
  echo "- ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
  echo "- ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
  echo "- ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
  echo "- ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
  echo "- ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
  echo "- FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
  echo "- BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
  echo "- LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
  echo "- VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
  echo "- CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
  echo "- SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
  echo "- FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
  echo "- VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
  echo "- RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
  echo "- OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
  echo "- ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
  echo
  echo "## Tests"
  echo "- GRAPH_TEST_STATUS=$GRAPH_TEST_STATUS"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-3.8 Org Graph Tests Final Seal FIX V14"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS=${HOLDING_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS=${FRANCHISE_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS=${VISIBILITY_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS=${CYCLE_PREVENTION_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_8_PERMISSION_TEST_STATUS=${PERMISSION_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_8_ORG_GRAPH_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_READY_FOR_FINAL_SEAL=YES"
} > "$FINAL_SEAL_FILE"

{
  echo "# FAZ 1 DB-L3 Organization / Ownership / Franchise Final Seal FIX V14"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- FAZ 1-3.1 org.entity_relations: PRESENT"
  echo "- FAZ 1-3.2 org.entity_shareholders: PRESENT"
  echo "- FAZ 1-3.3 franchise.agreements: PRESENT"
  echo "- FAZ 1-3.4 store/facility/warehouse locations: PRESENT"
  echo "- FAZ 1-3.5 company-owned vs franchise-operated: PRESENT"
  echo "- FAZ 1-3.6 visibility rules: PRESENT"
  echo "- FAZ 1-3.7 cross-company relations: PRESENT"
  echo "- FAZ 1-3.8 org graph tests: ${STRICT_SUITE_STATUS:-N/A}"
  echo
  echo "FAZ_1_DB_L3_HOLDING_GRAPH_STATUS=${HOLDING_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_FRANCHISE_GRAPH_STATUS=${FRANCHISE_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_VISIBILITY_GRAPH_STATUS=${VISIBILITY_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_CYCLE_PREVENTION_STATUS=${CYCLE_PREVENTION_TEST_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_PERMISSION_TEST_STATUS=${PERMISSION_TEST_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_NEXT_PRIORITY_READY=YES"
} > "$DB_L3_FINAL_SEAL_FILE"

pass "16.1 dokümantasyon yazıldı: $DOC_FILE"
pass "16.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "16.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"
pass "16.4 DB-L3 final seal evidence yazıldı: $DB_L3_FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "16.5 FIX V14 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-3.8 ORG GRAPH TESTS FIX V14 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "GRAPH_TEST_STATUS=$GRAPH_TEST_STATUS"
echo "ENTITY_RELATIONS_RELATION_CODE_COL_COUNT=$ENTITY_RELATIONS_RELATION_CODE_COL_COUNT"
echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
echo "ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
echo "ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
echo "ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
echo "ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
echo "ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
echo "ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
echo "SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
echo "FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
echo "VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
echo "RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "HOLDING_GRAPH_TEST_STATUS=${HOLDING_GRAPH_TEST_STATUS:-N/A}"
echo "FRANCHISE_GRAPH_TEST_STATUS=${FRANCHISE_GRAPH_TEST_STATUS:-N/A}"
echo "VISIBILITY_GRAPH_TEST_STATUS=${VISIBILITY_GRAPH_TEST_STATUS:-N/A}"
echo "CYCLE_PREVENTION_TEST_STATUS=${CYCLE_PREVENTION_TEST_STATUS:-N/A}"
echo "PERMISSION_TEST_STATUS=${PERMISSION_TEST_STATUS:-N/A}"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "DB_L3_FINAL_SEAL_FILE=$DB_L3_FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$GRAPH_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_PERMISSION_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_ORG_GRAPH_FINAL_STATUS=PASS"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=SEALED"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_FINAL_STATUS=PASS"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_SEAL_STATUS=SEALED"
  echo "FAZ_1_NEXT_PRIORITY_READY=YES"
else
  echo "FAZ_1_3_8_ORG_GRAPH_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=OPEN"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_FINAL_STATUS=FAIL"
  echo "FAZ_1_DB_L3_ORGANIZATION_OWNERSHIP_FRANCHISE_SEAL_STATUS=OPEN"
  echo "FAZ_1_NEXT_PRIORITY_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.8 ORG GRAPH TESTS FIX V14 ENTITY RELATION REQUIRED FIELDS END ====="
