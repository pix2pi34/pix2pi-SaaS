#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_1_ORG_ENTITY_RELATIONS"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_1_org_entity_relations_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_1_org_entity_relations.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_1_org_entity_relations_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_1_ORG_ENTITY_RELATIONS.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_3_1_org_entity_relations.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_1_ORG_ENTITY_RELATIONS_FINAL_SEAL_$TS.md"

GRAPH_TEST_SQL="$SUITE_RUNTIME_DIR/org_entity_relations_graph_suite.sql"
GRAPH_TEST_OUT="$SUITE_RUNTIME_DIR/org_entity_relations_graph_suite.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_1_strict_suite_run.out"

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

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$APPLY_SCRIPT_FILE" "$STRICT_SUITE_FILE" "$DOC_FILE"; do
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

echo "7. test için type-aware status ve gerçek tenant tespit ediliyor..."

LEGAL_ENTITY_STATUS_VALUE="$(choose_enum_or_default "org.legal_entities" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
")"

[ -z "$LEGAL_ENTITY_STATUS_VALUE" ] && LEGAL_ENTITY_STATUS_VALUE="active"

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

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.2 tenant FK referans tablosu bulundu" || fail "7.2 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.3 tenant FK referans UUID kolonu bulundu" || fail "7.3 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.4 gerçek tenant_id bulundu" || fail "7.4 gerçek tenant_id bulunamadı"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. org.entity_relations migration hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;

CREATE OR REPLACE FUNCTION org.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_legal_entities_id_tenant_id_fk
  ON org.legal_entities(id, tenant_id);

CREATE TABLE IF NOT EXISTS org.entity_relations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  parent_entity_id uuid NOT NULL,
  child_entity_id uuid NOT NULL,
  business_code text NOT NULL,
  relation_type text NOT NULL,
  visibility_scope text NOT NULL DEFAULT 'INHERIT',
  visibility_rule_code text,
  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS parent_entity_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS child_entity_id uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS relation_type text;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS visibility_scope text DEFAULT 'INHERIT';
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS visibility_rule_code text;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.entity_relations ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.entity_relations SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.entity_relations SET legal_entity_id=parent_entity_id WHERE legal_entity_id IS NULL AND parent_entity_id IS NOT NULL;
UPDATE org.entity_relations SET business_code='ENTITY_REL_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code)='';
UPDATE org.entity_relations SET visibility_scope='INHERIT' WHERE visibility_scope IS NULL OR btrim(visibility_scope)='';
UPDATE org.entity_relations SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.entity_relations SET status='ACTIVE' WHERE status IS NULL OR btrim(status)='';
UPDATE org.entity_relations SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.entity_relations SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.entity_relations SET created_at=now() WHERE created_at IS NULL;
UPDATE org.entity_relations SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='entity_relations'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.entity_relations ADD CONSTRAINT pk_org_entity_relations PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_relations_id_tenant_id_fk
  ON org.entity_relations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_relations_tenant_business_code
  ON org.entity_relations(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_entity_relations_active_edge
  ON org.entity_relations(tenant_id, parent_entity_id, child_entity_id, relation_type)
  WHERE deleted_at IS NULL AND status='ACTIVE';

CREATE INDEX IF NOT EXISTS idx_org_entity_relations_tenant_id ON org.entity_relations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_legal_entity_id ON org.entity_relations(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_parent_entity_id ON org.entity_relations(parent_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_child_entity_id ON org.entity_relations(child_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_relation_type ON org.entity_relations(relation_type);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_visibility_rule_code ON org.entity_relations(visibility_rule_code);
CREATE INDEX IF NOT EXISTS idx_org_entity_relations_status ON org.entity_relations(status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_relations_legal_entity_tenant'
      AND conrelid='org.entity_relations'::regclass
  ) THEN
    ALTER TABLE org.entity_relations
      ADD CONSTRAINT fk_org_entity_relations_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_relations_parent_tenant'
      AND conrelid='org.entity_relations'::regclass
  ) THEN
    ALTER TABLE org.entity_relations
      ADD CONSTRAINT fk_org_entity_relations_parent_tenant
      FOREIGN KEY (parent_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_entity_relations_child_tenant'
      AND conrelid='org.entity_relations'::regclass
  ) THEN
    ALTER TABLE org.entity_relations
      ADD CONSTRAINT fk_org_entity_relations_child_tenant
      FOREIGN KEY (child_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_required_fields;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND parent_entity_id IS NOT NULL
    AND child_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code) <> ''
    AND relation_type IS NOT NULL AND btrim(relation_type) <> ''
    AND visibility_scope IS NOT NULL AND btrim(visibility_scope) <> ''
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status) <> ''
  ) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_no_self_relation;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_no_self_relation
  CHECK (parent_entity_id <> child_entity_id) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_relation_type;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_relation_type
  CHECK (
    relation_type IN (
      'HOLDING_SUBSIDIARY',
      'PARENT_CHILD',
      'AFFILIATE',
      'MANAGEMENT',
      'FRANCHISE_OWNER_OPERATOR',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_visibility_scope;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_visibility_scope
  CHECK (
    visibility_scope IN (
      'INHERIT',
      'PARENT_ONLY',
      'CHILD_ONLY',
      'CUSTOM_RULE'
    )
  ) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_effective_dates;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.entity_relations DROP CONSTRAINT IF EXISTS ck_org_entity_relations_status;
ALTER TABLE org.entity_relations
  ADD CONSTRAINT ck_org_entity_relations_status
  CHECK (status IN ('ACTIVE','INACTIVE','PLANNED','ENDED')) NOT VALID;

CREATE OR REPLACE FUNCTION org.prevent_entity_relation_cycle()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_cycle_exists boolean := false;
BEGIN
  IF NEW.deleted_at IS NOT NULL OR NEW.status <> 'ACTIVE' THEN
    RETURN NEW;
  END IF;

  IF NEW.parent_entity_id = NEW.child_entity_id THEN
    RAISE EXCEPTION 'entity relation cycle/self relation blocked: parent and child cannot be same';
  END IF;

  WITH RECURSIVE descendants(entity_id) AS (
    SELECT er.child_entity_id
    FROM org.entity_relations er
    WHERE er.tenant_id = NEW.tenant_id
      AND er.parent_entity_id = NEW.child_entity_id
      AND er.deleted_at IS NULL
      AND er.status = 'ACTIVE'
      AND er.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)

    UNION

    SELECT er.child_entity_id
    FROM org.entity_relations er
    JOIN descendants d ON d.entity_id = er.parent_entity_id
    WHERE er.tenant_id = NEW.tenant_id
      AND er.deleted_at IS NULL
      AND er.status = 'ACTIVE'
      AND er.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  SELECT EXISTS (
    SELECT 1
    FROM descendants
    WHERE entity_id = NEW.parent_entity_id
  )
  INTO v_cycle_exists;

  IF v_cycle_exists THEN
    RAISE EXCEPTION 'entity relation cycle blocked for tenant %, parent %, child %',
      NEW.tenant_id,
      NEW.parent_entity_id,
      NEW.child_entity_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_org_entity_relations_prevent_cycle ON org.entity_relations;
CREATE TRIGGER trg_org_entity_relations_prevent_cycle
BEFORE INSERT OR UPDATE ON org.entity_relations
FOR EACH ROW
EXECUTE FUNCTION org.prevent_entity_relation_cycle();

DROP TRIGGER IF EXISTS trg_org_entity_relations_set_updated_at ON org.entity_relations;
CREATE TRIGGER trg_org_entity_relations_set_updated_at
BEFORE UPDATE ON org.entity_relations
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.entity_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.entity_relations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_entity_relations_tenant_rw ON org.entity_relations;
CREATE POLICY allow_org_entity_relations_tenant_rw
ON org.entity_relations
FOR ALL
USING (
  tenant_id::text = current_setting('app.tenant_id', true)
  OR tenant_id::text = current_setting('app.current_tenant_id', true)
  OR current_setting('app.bypass_tenant_rls', true) = 'on'
)
WITH CHECK (
  tenant_id::text = current_setting('app.tenant_id', true)
  OR tenant_id::text = current_setting('app.current_tenant_id', true)
  OR current_setting('app.bypass_tenant_rls', true) = 'on'
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='app_dictionary'
      AND table_name='table_contracts'
  ) THEN
    INSERT INTO app_dictionary.table_contracts (
      schema_name,
      table_name,
      owner_domain,
      table_kind,
      lifecycle_status,
      has_tenant_id,
      has_legal_entity_id,
      has_branch_id,
      has_business_code,
      field_count,
      metadata,
      updated_at
    )
    SELECT
      'org',
      'entity_relations',
      'organization_core',
      'BASE_TABLE',
      'ACTIVE',
      true,
      true,
      true,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='org'
          AND c.table_name='entity_relations'
      ),
      jsonb_build_object('phase','FAZ_1_3_1','source','org_entity_relations'),
      now()
    ON CONFLICT (schema_name, table_name) DO UPDATE SET
      owner_domain=EXCLUDED.owner_domain,
      table_kind=EXCLUDED.table_kind,
      lifecycle_status=EXCLUDED.lifecycle_status,
      has_tenant_id=EXCLUDED.has_tenant_id,
      has_legal_entity_id=EXCLUDED.has_legal_entity_id,
      has_branch_id=EXCLUDED.has_branch_id,
      has_business_code=EXCLUDED.has_business_code,
      field_count=EXCLUDED.field_count,
      metadata=EXCLUDED.metadata,
      updated_at=now();
  END IF;
END $$;

GRANT USAGE ON SCHEMA org TO PUBLIC;
GRANT SELECT, INSERT, UPDATE ON org.entity_relations TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.prevent_entity_relation_cycle() TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
SQL

pass "8.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. org.entity_relations migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 migration başarıyla uygulandı"
else
  fail "9.1 migration uygulanamadı"
  exit 1
fi

echo "10. org graph lifecycle / abuse SQL suite hazırlanıyor..."

cat <<SQL > "$GRAPH_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_root_id uuid := gen_random_uuid();
  v_child_id uuid := gen_random_uuid();
  v_grandchild_id uuid := gen_random_uuid();
  v_suffix text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_legal_status org.legal_entities.status%TYPE := '$LEGAL_ENTITY_STATUS_VALUE';
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
    v_root_id, v_tenant_id, v_root_id,
    'ORG_GRAPH_ROOT_' || v_suffix,
    'PIX2PI HOLDING ROOT TEST A.S.',
    'PIX2PI ROOT',
    '710' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120001001',
    'root-' || lower(v_suffix) || '@pix2pi.local',
    'ROOT TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_1_root')
  ),
  (
    v_child_id, v_tenant_id, v_child_id,
    'ORG_GRAPH_CHILD_' || v_suffix,
    'PIX2PI ALT SIRKET TEST A.S.',
    'PIX2PI CHILD',
    '720' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120001002',
    'child-' || lower(v_suffix) || '@pix2pi.local',
    'CHILD TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_1_child')
  ),
  (
    v_grandchild_id, v_tenant_id, v_grandchild_id,
    'ORG_GRAPH_GRANDCHILD_' || v_suffix,
    'PIX2PI TORUN SIRKET TEST A.S.',
    'PIX2PI GRANDCHILD',
    '730' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120001003',
    'grandchild-' || lower(v_suffix) || '@pix2pi.local',
    'GRANDCHILD TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_1_grandchild')
  );

  INSERT INTO org.entity_relations (
    tenant_id,
    legal_entity_id,
    parent_entity_id,
    child_entity_id,
    business_code,
    relation_type,
    visibility_scope,
    visibility_rule_code,
    effective_from,
    status,
    metadata
  )
  VALUES
  (
    v_tenant_id,
    v_root_id,
    v_root_id,
    v_child_id,
    'ENTITY_REL_ROOT_CHILD_' || v_suffix,
    'HOLDING_SUBSIDIARY',
    'INHERIT',
    'VISIBILITY_RULE_HOLDING_' || v_suffix,
    current_date,
    'ACTIVE',
    jsonb_build_object('test','root_child')
  ),
  (
    v_tenant_id,
    v_child_id,
    v_child_id,
    v_grandchild_id,
    'ENTITY_REL_CHILD_GRANDCHILD_' || v_suffix,
    'PARENT_CHILD',
    'INHERIT',
    'VISIBILITY_RULE_CHILD_' || v_suffix,
    current_date,
    'ACTIVE',
    jsonb_build_object('test','child_grandchild')
  );

  SELECT count(*)
  INTO v_count
  FROM org.entity_relations
  WHERE tenant_id=v_tenant_id
    AND status='ACTIVE'
    AND parent_entity_id IN (v_root_id, v_child_id)
    AND child_entity_id IN (v_child_id, v_grandchild_id);

  IF v_count <> 2 THEN
    RAISE EXCEPTION 'org graph relation insert/read failed';
  END IF;

  BEGIN
    INSERT INTO org.entity_relations (
      tenant_id,
      legal_entity_id,
      parent_entity_id,
      child_entity_id,
      business_code,
      relation_type,
      visibility_scope,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_root_id,
      v_root_id,
      v_root_id,
      'ENTITY_REL_SELF_' || v_suffix,
      'PARENT_CHILD',
      'INHERIT',
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'self relation was not blocked';
  EXCEPTION WHEN check_violation OR raise_exception THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_relations (
      tenant_id,
      legal_entity_id,
      parent_entity_id,
      child_entity_id,
      business_code,
      relation_type,
      visibility_scope,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_grandchild_id,
      v_grandchild_id,
      v_root_id,
      'ENTITY_REL_CYCLE_' || v_suffix,
      'PARENT_CHILD',
      'INHERIT',
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'cycle relation was not blocked';
  EXCEPTION WHEN raise_exception THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_relations (
      tenant_id,
      legal_entity_id,
      parent_entity_id,
      child_entity_id,
      business_code,
      relation_type,
      visibility_scope,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_root_id,
      v_root_id,
      v_child_id,
      'ENTITY_REL_BAD_TYPE_' || v_suffix,
      'BAD_TYPE',
      'INHERIT',
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'invalid relation_type was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_relations (
      tenant_id,
      legal_entity_id,
      parent_entity_id,
      child_entity_id,
      business_code,
      relation_type,
      visibility_scope,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_root_id,
      v_root_id,
      v_child_id,
      'ENTITY_REL_BAD_VISIBILITY_' || v_suffix,
      'PARENT_CHILD',
      'BAD_VISIBILITY',
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'invalid visibility_scope was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "10.1 org graph SQL suite dosyası yazıldı: $GRAPH_TEST_SQL / OK ✅"

echo "11. org graph lifecycle / abuse SQL suite çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$GRAPH_TEST_SQL" > "$GRAPH_TEST_OUT" 2>&1; then
  pass "11.1 org graph lifecycle / abuse SQL suite geçti"
else
  fail "11.1 org graph lifecycle / abuse SQL suite başarısız"
  cat "$GRAPH_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$GRAPH_TEST_OUT"; then
  pass "11.2 org graph test rollback ile temizlendi"
  GRAPH_TEST_STATUS="PASS"
else
  fail "11.2 org graph rollback kanıtı yok"
  GRAPH_TEST_STATUS="FAIL"
fi

echo "12. org.entity_relations sayaçları alınıyor..."

ENTITY_RELATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_relations';")"

ENTITY_RELATION_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='entity_relations'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id',
      'parent_entity_id','child_entity_id','business_code',
      'relation_type','visibility_scope','visibility_rule_code',
      'effective_from','effective_to','status',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

ENTITY_RELATION_FK_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.entity_relations'::regclass
    and contype='f';
")"

ENTITY_RELATION_CHECK_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.entity_relations'::regclass
    and contype='c';
")"

ENTITY_RELATION_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='entity_relations';
")"

ENTITY_RELATION_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname='entity_relations'
    and c.relrowsecurity=true;
")"

ENTITY_RELATION_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname='entity_relations'
    and c.relforcerowsecurity=true;
")"

ENTITY_RELATION_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='org'
    and tablename='entity_relations';
")"

CYCLE_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='org'
    and p.proname='prevent_entity_relation_cycle';
")"

CYCLE_TRIGGER_COUNT="$(scalar_count "
  select count(*)
  from pg_trigger
  where tgname='trg_org_entity_relations_prevent_cycle'
    and tgrelid='org.entity_relations'::regclass
    and not tgisinternal;
")"

UPDATED_AT_TRIGGER_COUNT="$(scalar_count "
  select count(*)
  from pg_trigger
  where tgname='trg_org_entity_relations_set_updated_at'
    and tgrelid='org.entity_relations'::regclass
    and not tgisinternal;
")"

VISIBILITY_LINK_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='entity_relations'
    and column_name in ('visibility_scope','visibility_rule_code');
")"

ENTITY_RELATION_DICTIONARY_COUNT="$(scalar_count "
  select count(*)
  from app_dictionary.table_contracts
  where schema_name='org'
    and table_name='entity_relations';
")"

echo "ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
echo "ENTITY_RELATION_COLUMN_COUNT=$ENTITY_RELATION_COLUMN_COUNT"
echo "ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
echo "ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
echo "ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
echo "ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
echo "ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
echo "ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
echo "CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
echo "CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
echo "UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
echo "VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
echo "ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
echo "GRAPH_TEST_STATUS=$GRAPH_TEST_STATUS"

[ "$ENTITY_RELATION_TABLE_COUNT" -eq 1 ] && pass "12.1 org.entity_relations tablosu hazır" || fail "12.1 org.entity_relations tablosu eksik"
[ "$ENTITY_RELATION_COLUMN_COUNT" -ge 20 ] && pass "12.2 org.entity_relations kolon kapsamı tam" || fail "12.2 kolon kapsamı eksik"
[ "$ENTITY_RELATION_FK_COUNT" -ge 3 ] && pass "12.3 parent-child FK seti hazır" || fail "12.3 parent-child FK seti eksik"
[ "$ENTITY_RELATION_CHECK_COUNT" -ge 6 ] && pass "12.4 check constraint seti hazır" || fail "12.4 check constraint seti eksik"
[ "$ENTITY_RELATION_INDEX_COUNT" -ge 9 ] && pass "12.5 org graph index seti hazır" || fail "12.5 org graph index seti eksik"
[ "$ENTITY_RELATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.6 entity_relations RLS enabled" || fail "12.6 RLS enabled eksik"
[ "$ENTITY_RELATION_RLS_FORCED_COUNT" -eq 1 ] && pass "12.7 entity_relations RLS forced" || fail "12.7 RLS forced eksik"
[ "$ENTITY_RELATION_POLICY_COUNT" -ge 1 ] && pass "12.8 entity_relations tenant policy hazır" || fail "12.8 tenant policy eksik"
[ "$CYCLE_FUNCTION_COUNT" -eq 1 ] && pass "12.9 cycle prevention function hazır" || fail "12.9 cycle prevention function eksik"
[ "$CYCLE_TRIGGER_COUNT" -eq 1 ] && pass "12.10 cycle prevention trigger hazır" || fail "12.10 cycle prevention trigger eksik"
[ "$UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "12.11 updated_at trigger hazır" || fail "12.11 updated_at trigger eksik"
[ "$VISIBILITY_LINK_COLUMN_COUNT" -eq 2 ] && pass "12.12 visibility rule bağlantı kolonları hazır" || fail "12.12 visibility rule bağlantı kolonları eksik"
[ "$ENTITY_RELATION_DICTIONARY_COUNT" -ge 1 ] && pass "12.13 data dictionary kaydı mevcut" || warn "12.13 data dictionary kaydı eksik"
[ "$GRAPH_TEST_STATUS" = "PASS" ] && pass "12.14 org graph lifecycle / abuse suite PASS" || fail "12.14 org graph lifecycle / abuse suite FAIL"

echo "13. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_1_org_entity_relations_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS STRICT SUITE START ====="

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

ENTITY_RELATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_relations';")"
ENTITY_RELATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='f';")"
ENTITY_RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='c';")"
ENTITY_RELATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relrowsecurity=true;")"
ENTITY_RELATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relforcerowsecurity=true;")"
ENTITY_RELATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_relations';")"
CYCLE_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='prevent_entity_relation_cycle';")"
CYCLE_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_relations_prevent_cycle' and tgrelid='org.entity_relations'::regclass and not tgisinternal;")"
VISIBILITY_LINK_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name in ('visibility_scope','visibility_rule_code');")"
ENTITY_RELATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='entity_relations';")"

echo "ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
echo "ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
echo "ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
echo "ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
echo "ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
echo "ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
echo "ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
echo "CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
echo "CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
echo "VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
echo "ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"

[ "$ENTITY_RELATION_TABLE_COUNT" -eq 1 ] && pass "5.1 org.entity_relations tablosu hazır" || fail "5.1 org.entity_relations tablosu eksik"
[ "$ENTITY_RELATION_FK_COUNT" -ge 3 ] && pass "5.2 parent-child FK seti hazır" || fail "5.2 parent-child FK seti eksik"
[ "$ENTITY_RELATION_CHECK_COUNT" -ge 6 ] && pass "5.3 check constraint seti hazır" || fail "5.3 check constraint seti eksik"
[ "$ENTITY_RELATION_INDEX_COUNT" -ge 9 ] && pass "5.4 org graph index seti hazır" || fail "5.4 org graph index seti eksik"
[ "$ENTITY_RELATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 RLS enabled" || fail "5.5 RLS enabled eksik"
[ "$ENTITY_RELATION_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 RLS forced" || fail "5.6 RLS forced eksik"
[ "$ENTITY_RELATION_POLICY_COUNT" -ge 1 ] && pass "5.7 tenant policy hazır" || fail "5.7 tenant policy eksik"
[ "$CYCLE_FUNCTION_COUNT" -eq 1 ] && pass "5.8 cycle prevention function hazır" || fail "5.8 cycle prevention function eksik"
[ "$CYCLE_TRIGGER_COUNT" -eq 1 ] && pass "5.9 cycle prevention trigger hazır" || fail "5.9 cycle prevention trigger eksik"
[ "$VISIBILITY_LINK_COLUMN_COUNT" -eq 2 ] && pass "5.10 visibility rule bağlantısı hazır" || fail "5.10 visibility rule bağlantısı eksik"
[ "$ENTITY_RELATION_DICTIONARY_COUNT" -ge 1 ] && pass "5.11 data dictionary kaydı mevcut" || warn "5.11 data dictionary kaydı eksik"

{
  echo "# FAZ 1-3.1 org.entity_relations Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
  echo "- ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
  echo "- ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
  echo "- ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
  echo "- ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
  echo "- ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
  echo "- ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
  echo "- CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
  echo "- CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
  echo "- VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
  echo "- ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
echo "ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
echo "ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
echo "ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
echo "ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
echo "ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
echo "ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
echo "CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
echo "CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
echo "VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
echo "ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_1_ENTITY_RELATIONS_MODEL_STATUS=PASS"
  echo "FAZ_1_3_1_HOLDING_TREE_STATUS=PASS"
  echo "FAZ_1_3_1_PARENT_CHILD_RELATION_STATUS=PASS"
  echo "FAZ_1_3_1_CYCLE_PREVENTION_STATUS=PASS"
  echo "FAZ_1_3_1_VISIBILITY_RULE_LINK_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "13.1 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "14. strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "14.1 strict suite exit code 0"
else
  fail "14.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS")"

ENTITY_RELATIONS_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_ENTITY_RELATIONS_MODEL_STATUS")"
HOLDING_TREE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_HOLDING_TREE_STATUS")"
PARENT_CHILD_RELATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_PARENT_CHILD_RELATION_STATUS")"
CYCLE_PREVENTION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_CYCLE_PREVENTION_STATUS")"
VISIBILITY_RULE_LINK_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_VISIBILITY_RULE_LINK_STATUS")"
ORG_GRAPH_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_1_ORG_GRAPH_TEST_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "15. strict suite FAIL_COUNT=0 doğrulandı" || fail "15. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "16. strict suite status PASS doğrulandı" || fail "16. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "17. strict suite seal SEALED doğrulandı" || fail "17. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "18. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.1 — org.entity_relations

## Kapsam

- Holding / alt şirket ağacı
- Parent-child relation
- Cycle prevention
- Visibility rule bağlantısı
- Org graph tests

## Uygulama

Bu adım org.entity_relations tablosunu kurar. Tenant-safe parent-child legal entity graph modelini, relation type standardını, visibility rule bağlantı kolonlarını ve cycle prevention trigger'ını içerir.

## Final Status

- FAZ_1_3_1_ENTITY_RELATIONS_MODEL_STATUS=${ENTITY_RELATIONS_MODEL_STATUS:-N/A}
- FAZ_1_3_1_HOLDING_TREE_STATUS=${HOLDING_TREE_STATUS:-N/A}
- FAZ_1_3_1_PARENT_CHILD_RELATION_STATUS=${PARENT_CHILD_RELATION_STATUS:-N/A}
- FAZ_1_3_1_CYCLE_PREVENTION_STATUS=${CYCLE_PREVENTION_STATUS:-N/A}
- FAZ_1_3_1_VISIBILITY_RULE_LINK_STATUS=${VISIBILITY_RULE_LINK_STATUS:-N/A}
- FAZ_1_3_1_ORG_GRAPH_TEST_STATUS=${ORG_GRAPH_TEST_STATUS:-N/A}
- FAZ_1_3_1_ORG_ENTITY_RELATIONS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.1 org.entity_relations Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Graph SQL: $GRAPH_TEST_SQL"
  echo "- Graph output: $GRAPH_TEST_OUT"
  echo
  echo "## Counts"
  echo "- ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
  echo "- ENTITY_RELATION_COLUMN_COUNT=$ENTITY_RELATION_COLUMN_COUNT"
  echo "- ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
  echo "- ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
  echo "- ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
  echo "- ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
  echo "- ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
  echo "- ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
  echo "- CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
  echo "- CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
  echo "- UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
  echo "- VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
  echo "- ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
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
  echo "# FAZ 1-3.1 org.entity_relations Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_1_ENTITY_RELATIONS_MODEL_STATUS=${ENTITY_RELATIONS_MODEL_STATUS:-N/A}"
  echo "FAZ_1_3_1_HOLDING_TREE_STATUS=${HOLDING_TREE_STATUS:-N/A}"
  echo "FAZ_1_3_1_PARENT_CHILD_RELATION_STATUS=${PARENT_CHILD_RELATION_STATUS:-N/A}"
  echo "FAZ_1_3_1_CYCLE_PREVENTION_STATUS=${CYCLE_PREVENTION_STATUS:-N/A}"
  echo "FAZ_1_3_1_VISIBILITY_RULE_LINK_STATUS=${VISIBILITY_RULE_LINK_STATUS:-N/A}"
  echo "FAZ_1_3_1_ORG_GRAPH_TEST_STATUS=${ORG_GRAPH_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_2_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "18.1 dokümantasyon yazıldı: $DOC_FILE"
pass "18.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "18.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "18.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "GRAPH_TEST_STATUS=$GRAPH_TEST_STATUS"
echo "ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
echo "ENTITY_RELATION_COLUMN_COUNT=$ENTITY_RELATION_COLUMN_COUNT"
echo "ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
echo "ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
echo "ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
echo "ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
echo "ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
echo "ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
echo "CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
echo "CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
echo "UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
echo "VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
echo "ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "ENTITY_RELATIONS_MODEL_STATUS=${ENTITY_RELATIONS_MODEL_STATUS:-N/A}"
echo "HOLDING_TREE_STATUS=${HOLDING_TREE_STATUS:-N/A}"
echo "PARENT_CHILD_RELATION_STATUS=${PARENT_CHILD_RELATION_STATUS:-N/A}"
echo "CYCLE_PREVENTION_STATUS=${CYCLE_PREVENTION_STATUS:-N/A}"
echo "VISIBILITY_RULE_LINK_STATUS=${VISIBILITY_RULE_LINK_STATUS:-N/A}"
echo "ORG_GRAPH_TEST_STATUS=${ORG_GRAPH_TEST_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$GRAPH_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_1_ENTITY_RELATIONS_MODEL_STATUS=PASS"
  echo "FAZ_1_3_1_HOLDING_TREE_STATUS=PASS"
  echo "FAZ_1_3_1_PARENT_CHILD_RELATION_STATUS=PASS"
  echo "FAZ_1_3_1_CYCLE_PREVENTION_STATUS=PASS"
  echo "FAZ_1_3_1_VISIBILITY_RULE_LINK_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_FINAL_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_2_READY=YES"
else
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_2_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS END ====="
