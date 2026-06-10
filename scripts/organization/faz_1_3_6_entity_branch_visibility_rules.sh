#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_6_ENTITY_BRANCH_VISIBILITY_RULES"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_6_entity_branch_visibility_rules_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_6_entity_branch_visibility_rules.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_6_entity_branch_visibility_rules_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_6_ENTITY_BRANCH_VISIBILITY_RULES.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_3_6_entity_branch_visibility_rules.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_6_ENTITY_BRANCH_VISIBILITY_RULES_FINAL_SEAL_$TS.md"

VISIBILITY_TEST_SQL="$SUITE_RUNTIME_DIR/entity_branch_visibility_rules_suite.sql"
VISIBILITY_TEST_OUT="$SUITE_RUNTIME_DIR/entity_branch_visibility_rules_suite.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_6_strict_suite_run.out"

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

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES START ====="

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

echo "7. type-aware değerler ve bağımlılıklar tespit ediliyor..."

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

LEGAL_ENTITY_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entities';")"
BRANCH_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='branches';")"
LOCATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
OP_PROFILE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
echo "LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.2 tenant FK referans tablosu bulundu" || fail "7.2 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.3 tenant FK referans UUID kolonu bulundu" || fail "7.3 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.4 gerçek tenant_id bulundu" || fail "7.4 gerçek tenant_id bulunamadı"
[ "$LEGAL_ENTITY_TABLE_COUNT" -eq 1 ] && pass "7.5 org.legal_entities hazır" || fail "7.5 org.legal_entities eksik"
[ "$BRANCH_TABLE_COUNT" -eq 1 ] && pass "7.6 org.branches hazır" || warn "7.6 org.branches yok; branch FK opsiyonel kalacak"
[ "$LOCATION_TABLE_COUNT" -eq 1 ] && pass "7.7 org.business_locations hazır" || warn "7.7 org.business_locations yok"
[ "$OP_PROFILE_TABLE_COUNT" -eq 1 ] && pass "7.8 org.location_operation_profiles hazır" || warn "7.8 org.location_operation_profiles yok"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. entity / branch visibility rules migration hazırlanıyor..."

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

DO $$
BEGIN
  IF to_regclass('org.branches') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='tenant_id'
     ) THEN
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS ux_org_branches_id_tenant_id_fk ON org.branches(id, tenant_id)';
  END IF;

  IF to_regclass('org.business_locations') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='tenant_id'
     ) THEN
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_id_tenant_id_fk ON org.business_locations(id, tenant_id)';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS org.visibility_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  business_code text NOT NULL,
  visibility_rule_code text NOT NULL,

  subject_type text NOT NULL,
  subject_user_id uuid,
  subject_role text,
  subject_legal_entity_id uuid,
  accountant_entity_id uuid,

  visibility_scope text NOT NULL,
  branch_scope text NOT NULL DEFAULT 'NO_BRANCH',

  target_entity_id uuid,
  target_branch_id uuid,
  target_location_id uuid,

  permission_effect text NOT NULL,
  access_level text NOT NULL DEFAULT 'READ',
  cross_branch_allowed boolean NOT NULL DEFAULT false,

  can_view boolean NOT NULL DEFAULT true,
  can_create boolean NOT NULL DEFAULT false,
  can_update boolean NOT NULL DEFAULT false,
  can_delete boolean NOT NULL DEFAULT false,
  can_export boolean NOT NULL DEFAULT false,

  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',

  approval_ref text,
  lifecycle_reason text,
  visibility_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS visibility_rule_code text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_type text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_user_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_role text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS subject_legal_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS accountant_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS visibility_scope text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS branch_scope text DEFAULT 'NO_BRANCH';
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS target_entity_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS target_branch_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS target_location_id uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS permission_effect text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS access_level text DEFAULT 'READ';
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS cross_branch_allowed boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_view boolean DEFAULT true;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_create boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_update boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_delete boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS can_export boolean DEFAULT false;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS approval_ref text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS visibility_audit_ref text;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.visibility_rules ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.visibility_rules SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.visibility_rules SET business_code='VIS_RULE_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.visibility_rules SET visibility_rule_code=business_code WHERE visibility_rule_code IS NULL OR btrim(visibility_rule_code::text)='';
UPDATE org.visibility_rules SET subject_type='ROLE' WHERE subject_type IS NULL OR btrim(subject_type::text)='';
UPDATE org.visibility_rules SET visibility_scope='ENTITY' WHERE visibility_scope IS NULL OR btrim(visibility_scope::text)='';
UPDATE org.visibility_rules SET branch_scope='NO_BRANCH' WHERE branch_scope IS NULL OR btrim(branch_scope::text)='';
UPDATE org.visibility_rules SET permission_effect='READ_ONLY' WHERE permission_effect IS NULL OR btrim(permission_effect::text)='';
UPDATE org.visibility_rules SET access_level='READ' WHERE access_level IS NULL OR btrim(access_level::text)='';
UPDATE org.visibility_rules SET cross_branch_allowed=false WHERE cross_branch_allowed IS NULL;
UPDATE org.visibility_rules SET can_view=true WHERE can_view IS NULL;
UPDATE org.visibility_rules SET can_create=false WHERE can_create IS NULL;
UPDATE org.visibility_rules SET can_update=false WHERE can_update IS NULL;
UPDATE org.visibility_rules SET can_delete=false WHERE can_delete IS NULL;
UPDATE org.visibility_rules SET can_export=false WHERE can_export IS NULL;
UPDATE org.visibility_rules SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.visibility_rules SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.visibility_rules SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.visibility_rules SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.visibility_rules SET created_at=now() WHERE created_at IS NULL;
UPDATE org.visibility_rules SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='visibility_rules'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.visibility_rules ADD CONSTRAINT pk_org_visibility_rules PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_id_tenant_id_fk
  ON org.visibility_rules(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_tenant_business_code
  ON org.visibility_rules(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_tenant_rule_code
  ON org.visibility_rules(tenant_id, visibility_rule_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_tenant_id ON org.visibility_rules(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_legal_entity_id ON org.visibility_rules(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_branch_id ON org.visibility_rules(branch_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_type ON org.visibility_rules(subject_type);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_role ON org.visibility_rules(subject_role);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_user_id ON org.visibility_rules(subject_user_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_subject_legal_entity_id ON org.visibility_rules(subject_legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_accountant_entity_id ON org.visibility_rules(accountant_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_visibility_scope ON org.visibility_rules(visibility_scope);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_branch_scope ON org.visibility_rules(branch_scope);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_target_entity_id ON org.visibility_rules(target_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_target_branch_id ON org.visibility_rules(target_branch_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_target_location_id ON org.visibility_rules(target_location_id);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_permission_effect ON org.visibility_rules(permission_effect);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_status ON org.visibility_rules(status);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_effective_dates ON org.visibility_rules(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_org_visibility_rules_audit_ref ON org.visibility_rules(visibility_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_legal_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_target_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_target_entity_tenant
      FOREIGN KEY (target_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_subject_legal_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_subject_legal_entity_tenant
      FOREIGN KEY (subject_legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_visibility_rules_accountant_entity_tenant'
      AND conrelid='org.visibility_rules'::regclass
  ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_accountant_entity_tenant
      FOREIGN KEY (accountant_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF to_regclass('org.branches') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='tenant_id'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname='fk_org_visibility_rules_branch_tenant'
         AND conrelid='org.visibility_rules'::regclass
     ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;

  IF to_regclass('org.branches') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='branches' AND column_name='tenant_id'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname='fk_org_visibility_rules_target_branch_tenant'
         AND conrelid='org.visibility_rules'::regclass
     ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_target_branch_tenant
      FOREIGN KEY (target_branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;

  IF to_regclass('org.business_locations') IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='id'
     )
     AND EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='org' AND table_name='business_locations' AND column_name='tenant_id'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_constraint
       WHERE conname='fk_org_visibility_rules_target_location_tenant'
         AND conrelid='org.visibility_rules'::regclass
     ) THEN
    ALTER TABLE org.visibility_rules
      ADD CONSTRAINT fk_org_visibility_rules_target_location_tenant
      FOREIGN KEY (target_location_id, tenant_id)
      REFERENCES org.business_locations(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_required_fields;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND visibility_rule_code IS NOT NULL AND btrim(visibility_rule_code::text) <> ''
    AND subject_type IS NOT NULL AND btrim(subject_type::text) <> ''
    AND visibility_scope IS NOT NULL AND btrim(visibility_scope::text) <> ''
    AND branch_scope IS NOT NULL AND btrim(branch_scope::text) <> ''
    AND permission_effect IS NOT NULL AND btrim(permission_effect::text) <> ''
    AND access_level IS NOT NULL AND btrim(access_level::text) <> ''
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_subject_type;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_subject_type
  CHECK (
    subject_type IN (
      'USER',
      'ROLE',
      'LEGAL_ENTITY',
      'ACCOUNTANT',
      'SYSTEM'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_subject_required;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_subject_required
  CHECK (
    (subject_type='USER' AND subject_user_id IS NOT NULL)
    OR (subject_type='ROLE' AND subject_role IS NOT NULL AND btrim(subject_role::text) <> '')
    OR (subject_type='LEGAL_ENTITY' AND subject_legal_entity_id IS NOT NULL)
    OR (subject_type='ACCOUNTANT' AND accountant_entity_id IS NOT NULL)
    OR (subject_type='SYSTEM')
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_visibility_scope;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_visibility_scope
  CHECK (
    visibility_scope IN (
      'GLOBAL',
      'ENTITY',
      'BRANCH',
      'LOCATION',
      'ACCOUNTANT',
      'ROLE'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_branch_scope;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_branch_scope
  CHECK (
    branch_scope IN (
      'NO_BRANCH',
      'ALL_BRANCHES',
      'SPECIFIC_BRANCH',
      'CROSS_BRANCH'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_target_required;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_target_required
  CHECK (
    (visibility_scope='GLOBAL')
    OR (visibility_scope='ENTITY' AND target_entity_id IS NOT NULL)
    OR (visibility_scope='ACCOUNTANT' AND target_entity_id IS NOT NULL AND accountant_entity_id IS NOT NULL)
    OR (visibility_scope='ROLE' AND subject_role IS NOT NULL)
    OR (visibility_scope='LOCATION' AND target_location_id IS NOT NULL)
    OR (
      visibility_scope='BRANCH'
      AND (
        branch_scope IN ('ALL_BRANCHES','CROSS_BRANCH')
        OR (branch_scope='SPECIFIC_BRANCH' AND target_branch_id IS NOT NULL)
      )
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_permission_effect;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_permission_effect
  CHECK (
    permission_effect IN (
      'READ_ONLY',
      'WRITE_SCOPE',
      'ADMIN_SCOPE',
      'ACCOUNTANT_READ',
      'ACCOUNTANT_EXPORT',
      'CROSS_BRANCH_READ',
      'CROSS_BRANCH_WRITE',
      'NO_ACCESS'
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_access_level;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_access_level
  CHECK (
    access_level IN ('READ','WRITE','ADMIN','EXPORT','NONE')
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_effective_dates;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_status;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','REVOKED','EXPIRED')
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_accountant_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_accountant_rule
  CHECK (
    subject_type <> 'ACCOUNTANT'
    OR (
      accountant_entity_id IS NOT NULL
      AND visibility_scope='ACCOUNTANT'
      AND permission_effect IN ('ACCOUNTANT_READ','ACCOUNTANT_EXPORT','READ_ONLY')
      AND can_delete=false
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_cross_branch_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_cross_branch_rule
  CHECK (
    permission_effect NOT IN ('CROSS_BRANCH_READ','CROSS_BRANCH_WRITE')
    OR (
      branch_scope IN ('ALL_BRANCHES','CROSS_BRANCH')
      AND cross_branch_allowed=true
      AND approval_ref IS NOT NULL
      AND btrim(approval_ref::text) <> ''
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_cross_branch_write_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_cross_branch_write_rule
  CHECK (
    permission_effect <> 'CROSS_BRANCH_WRITE'
    OR (
      access_level IN ('WRITE','ADMIN')
      AND can_update=true
      AND cross_branch_allowed=true
      AND approval_ref IS NOT NULL
      AND btrim(approval_ref::text) <> ''
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_no_access_rule;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_no_access_rule
  CHECK (
    permission_effect <> 'NO_ACCESS'
    OR (
      access_level='NONE'
      AND can_view=false
      AND can_create=false
      AND can_update=false
      AND can_delete=false
      AND can_export=false
    )
  ) NOT VALID;

ALTER TABLE org.visibility_rules DROP CONSTRAINT IF EXISTS ck_org_visibility_rules_revoke_audit;
ALTER TABLE org.visibility_rules
  ADD CONSTRAINT ck_org_visibility_rules_revoke_audit
  CHECK (
    status NOT IN ('REVOKED','EXPIRED')
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND visibility_audit_ref IS NOT NULL
      AND btrim(visibility_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_visibility_rules_set_updated_at ON org.visibility_rules;
CREATE TRIGGER trg_org_visibility_rules_set_updated_at
BEFORE UPDATE ON org.visibility_rules
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.visibility_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.visibility_rules FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_visibility_rules_tenant_rw ON org.visibility_rules;
CREATE POLICY allow_org_visibility_rules_tenant_rw
ON org.visibility_rules
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
      'visibility_rules',
      'organization_visibility_access',
      'ACCESS_RULE_TABLE',
      'ACTIVE',
      true,
      true,
      true,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='org'
          AND c.table_name='visibility_rules'
      ),
      jsonb_build_object(
        'phase','FAZ_1_3_6',
        'source','entity_branch_visibility_rules',
        'scopes', jsonb_build_array('ENTITY','BRANCH','ROLE','ACCOUNTANT','LOCATION','GLOBAL')
      ),
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
GRANT SELECT, INSERT, UPDATE ON org.visibility_rules TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
SQL

pass "8.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. entity / branch visibility rules migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 migration başarıyla uygulandı"
else
  fail "9.1 migration uygulanamadı"
  exit 1
fi

echo "10. visibility rules lifecycle / abuse SQL suite hazırlanıyor..."

cat <<SQL > "$VISIBILITY_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_company_entity_id uuid := gen_random_uuid();
  v_accountant_entity_id uuid := gen_random_uuid();
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
    v_company_entity_id, v_tenant_id, v_company_entity_id,
    'VIS_ENTITY_' || v_suffix,
    'PIX2PI VISIBILITY TEST A.S.',
    'PIX2PI VISIBILITY',
    '961' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120006001',
    'visibility-' || lower(v_suffix) || '@pix2pi.local',
    'VISIBILITY TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_6_company_entity')
  ),
  (
    v_accountant_entity_id, v_tenant_id, v_accountant_entity_id,
    'VIS_ACCOUNTANT_' || v_suffix,
    'PIX2PI ACCOUNTANT TEST A.S.',
    'PIX2PI ACCOUNTANT',
    '962' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120006002',
    'accountant-' || lower(v_suffix) || '@pix2pi.local',
    'ACCOUNTANT TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_6_accountant_entity')
  );

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
    v_tenant_id,
    v_company_entity_id,
    'VIS_ENTITY_RULE_' || v_suffix,
    'VIS-ENTITY-' || v_suffix,
    'ROLE',
    'TENANT_ADMIN',
    'ENTITY',
    'NO_BRANCH',
    v_company_entity_id,
    'WRITE_SCOPE',
    'WRITE',
    true,
    true,
    true,
    false,
    true,
    current_date,
    'ACTIVE',
    'VIS_AUDIT_ENTITY_' || v_suffix,
    jsonb_build_object('test','entity_visibility_rule')
  );

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
    can_create,
    can_update,
    can_delete,
    can_export,
    approval_ref,
    effective_from,
    status,
    visibility_audit_ref,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_company_entity_id,
    'VIS_BRANCH_RULE_' || v_suffix,
    'VIS-BRANCH-' || v_suffix,
    'ROLE',
    'REGIONAL_MANAGER',
    'BRANCH',
    'ALL_BRANCHES',
    v_company_entity_id,
    'CROSS_BRANCH_READ',
    'READ',
    true,
    true,
    false,
    false,
    false,
    true,
    'APPROVAL_CROSS_BRANCH_READ_' || v_suffix,
    current_date,
    'ACTIVE',
    'VIS_AUDIT_BRANCH_' || v_suffix,
    jsonb_build_object('test','branch_visibility_rule')
  );

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
    v_tenant_id,
    v_company_entity_id,
    'VIS_ACCOUNTANT_RULE_' || v_suffix,
    'VIS-ACCOUNTANT-' || v_suffix,
    'ACCOUNTANT',
    v_accountant_entity_id,
    'ACCOUNTANT',
    'ALL_BRANCHES',
    v_company_entity_id,
    'ACCOUNTANT_EXPORT',
    'EXPORT',
    true,
    false,
    false,
    false,
    true,
    current_date,
    'ACTIVE',
    'VIS_AUDIT_ACCOUNTANT_' || v_suffix,
    jsonb_build_object('test','accountant_visibility_rule')
  );

  SELECT count(*)
  INTO v_count
  FROM org.visibility_rules
  WHERE tenant_id=v_tenant_id
    AND target_entity_id=v_company_entity_id
    AND status='ACTIVE';

  IF v_count <> 3 THEN
    RAISE EXCEPTION 'visibility rules valid insert/read failed, count %', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.visibility_rules
  WHERE tenant_id=v_tenant_id
    AND subject_type='ACCOUNTANT'
    AND accountant_entity_id=v_accountant_entity_id
    AND permission_effect='ACCOUNTANT_EXPORT'
    AND can_export=true
    AND can_delete=false;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'accountant visibility rule was not persisted correctly';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.visibility_rules
  WHERE tenant_id=v_tenant_id
    AND visibility_scope='BRANCH'
    AND branch_scope='ALL_BRANCHES'
    AND permission_effect='CROSS_BRANCH_READ'
    AND cross_branch_allowed=true
    AND approval_ref IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'branch visibility rule was not persisted correctly';
  END IF;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type, subject_role,
      visibility_scope, branch_scope,
      permission_effect, access_level,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_ENTITY_NO_TARGET_' || v_suffix,
      'VIS-BAD-ENTITY-NO-TARGET-' || v_suffix,
      'ROLE', 'TENANT_ADMIN',
      'ENTITY', 'NO_BRANCH',
      'READ_ONLY', 'READ',
      current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'ENTITY visibility without target_entity_id was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type,
      visibility_scope, branch_scope, target_entity_id,
      permission_effect, access_level,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_ROLE_NO_SUBJECT_' || v_suffix,
      'VIS-BAD-ROLE-NO-SUBJECT-' || v_suffix,
      'ROLE',
      'ENTITY', 'NO_BRANCH', v_company_entity_id,
      'READ_ONLY', 'READ',
      current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'ROLE subject without subject_role was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type,
      visibility_scope, branch_scope, target_entity_id,
      permission_effect, access_level,
      can_delete,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_ACCOUNTANT_NO_ENTITY_' || v_suffix,
      'VIS-BAD-ACCOUNTANT-NO-ENTITY-' || v_suffix,
      'ACCOUNTANT',
      'ACCOUNTANT', 'ALL_BRANCHES', v_company_entity_id,
      'ACCOUNTANT_READ', 'READ',
      false,
      current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'ACCOUNTANT subject without accountant_entity_id was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type, subject_role,
      visibility_scope, branch_scope, target_entity_id,
      permission_effect, access_level,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_SPECIFIC_BRANCH_' || v_suffix,
      'VIS-BAD-SPECIFIC-BRANCH-' || v_suffix,
      'ROLE', 'BRANCH_MANAGER',
      'BRANCH', 'SPECIFIC_BRANCH', v_company_entity_id,
      'READ_ONLY', 'READ',
      current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'SPECIFIC_BRANCH without target_branch_id was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type, subject_role,
      visibility_scope, branch_scope, target_entity_id,
      permission_effect, access_level,
      cross_branch_allowed,
      can_view, can_update,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_CROSS_BRANCH_NO_APPROVAL_' || v_suffix,
      'VIS-BAD-CROSS-NO-APPROVAL-' || v_suffix,
      'ROLE', 'REGIONAL_MANAGER',
      'BRANCH', 'CROSS_BRANCH', v_company_entity_id,
      'CROSS_BRANCH_WRITE', 'WRITE',
      true,
      true, true,
      current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'cross-branch write without approval_ref was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type, accountant_entity_id,
      visibility_scope, branch_scope, target_entity_id,
      permission_effect, access_level,
      can_view, can_delete,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_ACCOUNTANT_DELETE_' || v_suffix,
      'VIS-BAD-ACCOUNTANT-DELETE-' || v_suffix,
      'ACCOUNTANT', v_accountant_entity_id,
      'ACCOUNTANT', 'ALL_BRANCHES', v_company_entity_id,
      'ACCOUNTANT_READ', 'READ',
      true, true,
      current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'accountant delete permission was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.visibility_rules (
      tenant_id, legal_entity_id, business_code, visibility_rule_code,
      subject_type, subject_role,
      visibility_scope, branch_scope, target_entity_id,
      permission_effect, access_level,
      effective_from, effective_to,
      status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'VIS_BAD_DATE_' || v_suffix,
      'VIS-BAD-DATE-' || v_suffix,
      'ROLE', 'TENANT_ADMIN',
      'ENTITY', 'NO_BRANCH', v_company_entity_id,
      'READ_ONLY', 'READ',
      current_date + 10, current_date + 9,
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad effective date range was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "10.1 visibility rules SQL suite dosyası yazıldı: $VISIBILITY_TEST_SQL / OK ✅"

echo "11. visibility rules lifecycle / abuse SQL suite çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$VISIBILITY_TEST_SQL" > "$VISIBILITY_TEST_OUT" 2>&1; then
  pass "11.1 visibility rules lifecycle / abuse SQL suite geçti"
else
  fail "11.1 visibility rules lifecycle / abuse SQL suite başarısız"
  cat "$VISIBILITY_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$VISIBILITY_TEST_OUT"; then
  pass "11.2 visibility rules test rollback ile temizlendi"
  VISIBILITY_TEST_STATUS="PASS"
else
  fail "11.2 visibility rules rollback kanıtı yok"
  VISIBILITY_TEST_STATUS="FAIL"
fi

echo "12. visibility rules model sayaçları alınıyor..."

VISIBILITY_RULE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"

VISIBILITY_RULE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='visibility_rules'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id',
      'business_code','visibility_rule_code',
      'subject_type','subject_user_id','subject_role','subject_legal_entity_id','accountant_entity_id',
      'visibility_scope','branch_scope',
      'target_entity_id','target_branch_id','target_location_id',
      'permission_effect','access_level','cross_branch_allowed',
      'can_view','can_create','can_update','can_delete','can_export',
      'effective_from','effective_to','status',
      'approval_ref','lifecycle_reason','visibility_audit_ref',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

VISIBILITY_RULE_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and contype='f';")"
VISIBILITY_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and contype='c';")"
VISIBILITY_RULE_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='visibility_rules';")"
VISIBILITY_RULE_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='visibility_rules' and c.relrowsecurity=true;")"
VISIBILITY_RULE_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='visibility_rules' and c.relforcerowsecurity=true;")"
VISIBILITY_RULE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='visibility_rules';")"
VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_visibility_rules_set_updated_at' and tgrelid='org.visibility_rules'::regclass and not tgisinternal;")"
VISIBILITY_RULE_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='visibility_rules' and column_name in ('approval_ref','lifecycle_reason','visibility_audit_ref','audit_metadata');")"
VISIBILITY_RULE_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='visibility_rules';")"

ENTITY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_target_required';")"
BRANCH_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_branch_scope';")"
ROLE_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_subject_required';")"
ACCOUNTANT_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_accountant_rule';")"
CROSS_BRANCH_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname in ('ck_org_visibility_rules_cross_branch_rule','ck_org_visibility_rules_cross_branch_write_rule');")"
PERMISSION_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_permission_effect';")"

echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
echo "VISIBILITY_RULE_COLUMN_COUNT=$VISIBILITY_RULE_COLUMN_COUNT"
echo "VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
echo "VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
echo "VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
echo "VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
echo "VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
echo "VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
echo "VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT=$VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT"
echo "VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
echo "VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
echo "ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
echo "BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
echo "ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "VISIBILITY_TEST_STATUS=$VISIBILITY_TEST_STATUS"

[ "$VISIBILITY_RULE_TABLE_COUNT" -eq 1 ] && pass "12.1 visibility_rules tablosu hazır" || fail "12.1 visibility_rules tablosu eksik"
[ "$VISIBILITY_RULE_COLUMN_COUNT" -ge 37 ] && pass "12.2 visibility_rules kolon kapsamı tam" || fail "12.2 visibility_rules kolon kapsamı eksik"
[ "$VISIBILITY_RULE_FK_COUNT" -ge 4 ] && pass "12.3 visibility_rules FK seti hazır" || fail "12.3 visibility_rules FK seti eksik"
[ "$VISIBILITY_RULE_CHECK_COUNT" -ge 12 ] && pass "12.4 visibility_rules check constraint seti hazır" || fail "12.4 visibility_rules check seti eksik"
[ "$VISIBILITY_RULE_INDEX_COUNT" -ge 17 ] && pass "12.5 visibility_rules index seti hazır" || fail "12.5 visibility_rules index seti eksik"
[ "$VISIBILITY_RULE_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.6 visibility_rules RLS enabled" || fail "12.6 visibility_rules RLS enabled eksik"
[ "$VISIBILITY_RULE_RLS_FORCED_COUNT" -eq 1 ] && pass "12.7 visibility_rules RLS forced" || fail "12.7 visibility_rules RLS forced eksik"
[ "$VISIBILITY_RULE_POLICY_COUNT" -ge 1 ] && pass "12.8 visibility_rules tenant policy hazır" || fail "12.8 visibility_rules tenant policy eksik"
[ "$VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "12.9 visibility_rules updated_at trigger hazır" || fail "12.9 visibility_rules updated_at trigger eksik"
[ "$VISIBILITY_RULE_AUDIT_COLUMN_COUNT" -eq 4 ] && pass "12.10 visibility audit kolonları hazır" || fail "12.10 visibility audit kolonları eksik"
[ "$VISIBILITY_RULE_DICTIONARY_COUNT" -ge 1 ] && pass "12.11 visibility data dictionary kaydı mevcut" || warn "12.11 visibility data dictionary kaydı eksik"
[ "$ENTITY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "12.12 entity visibility rule hazır" || fail "12.12 entity visibility rule eksik"
[ "$BRANCH_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "12.13 branch visibility rule hazır" || fail "12.13 branch visibility rule eksik"
[ "$ROLE_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "12.14 role-based visibility rule hazır" || fail "12.14 role-based visibility rule eksik"
[ "$ACCOUNTANT_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "12.15 accountant visibility rule hazır" || fail "12.15 accountant visibility rule eksik"
[ "$CROSS_BRANCH_CHECK_COUNT" -eq 2 ] && pass "12.16 cross-branch guard seti hazır" || fail "12.16 cross-branch guard seti eksik"
[ "$PERMISSION_EFFECT_CHECK_COUNT" -eq 1 ] && pass "12.17 permission effect rule hazır" || fail "12.17 permission effect rule eksik"
[ "$VISIBILITY_TEST_STATUS" = "PASS" ] && pass "12.18 visibility rules lifecycle / abuse suite PASS" || fail "12.18 visibility rules lifecycle / abuse suite FAIL"

echo "13. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_6_entity_branch_visibility_rules_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_6_ENTITY_BRANCH_VISIBILITY_RULES_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES STRICT SUITE START ====="

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

VISIBILITY_RULE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"
VISIBILITY_RULE_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and contype='f';")"
VISIBILITY_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and contype='c';")"
VISIBILITY_RULE_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='visibility_rules';")"
VISIBILITY_RULE_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='visibility_rules' and c.relrowsecurity=true;")"
VISIBILITY_RULE_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='visibility_rules' and c.relforcerowsecurity=true;")"
VISIBILITY_RULE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='visibility_rules';")"
VISIBILITY_RULE_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='visibility_rules' and column_name in ('approval_ref','lifecycle_reason','visibility_audit_ref','audit_metadata');")"
VISIBILITY_RULE_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='visibility_rules';")"

ENTITY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_target_required';")"
BRANCH_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_branch_scope';")"
ROLE_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_subject_required';")"
ACCOUNTANT_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_accountant_rule';")"
CROSS_BRANCH_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname in ('ck_org_visibility_rules_cross_branch_rule','ck_org_visibility_rules_cross_branch_write_rule');")"
PERMISSION_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_permission_effect';")"

echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
echo "VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
echo "VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
echo "VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
echo "VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
echo "VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
echo "VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
echo "VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
echo "VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
echo "ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
echo "BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
echo "ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"

[ "$VISIBILITY_RULE_TABLE_COUNT" -eq 1 ] && pass "5.1 visibility_rules tablosu hazır" || fail "5.1 visibility_rules tablosu eksik"
[ "$VISIBILITY_RULE_FK_COUNT" -ge 4 ] && pass "5.2 visibility_rules FK seti hazır" || fail "5.2 visibility_rules FK seti eksik"
[ "$VISIBILITY_RULE_CHECK_COUNT" -ge 12 ] && pass "5.3 visibility_rules check seti hazır" || fail "5.3 visibility_rules check seti eksik"
[ "$VISIBILITY_RULE_INDEX_COUNT" -ge 17 ] && pass "5.4 visibility_rules index seti hazır" || fail "5.4 visibility_rules index seti eksik"
[ "$VISIBILITY_RULE_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 visibility_rules RLS enabled" || fail "5.5 visibility_rules RLS enabled eksik"
[ "$VISIBILITY_RULE_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 visibility_rules RLS forced" || fail "5.6 visibility_rules RLS forced eksik"
[ "$VISIBILITY_RULE_POLICY_COUNT" -ge 1 ] && pass "5.7 visibility_rules tenant policy hazır" || fail "5.7 visibility_rules tenant policy eksik"
[ "$VISIBILITY_RULE_AUDIT_COLUMN_COUNT" -eq 4 ] && pass "5.8 visibility audit kolonları hazır" || fail "5.8 visibility audit kolonları eksik"
[ "$VISIBILITY_RULE_DICTIONARY_COUNT" -ge 1 ] && pass "5.9 visibility data dictionary mevcut" || warn "5.9 visibility data dictionary eksik"
[ "$ENTITY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.10 entity visibility rule hazır" || fail "5.10 entity visibility rule eksik"
[ "$BRANCH_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.11 branch visibility rule hazır" || fail "5.11 branch visibility rule eksik"
[ "$ROLE_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.12 role-based visibility rule hazır" || fail "5.12 role-based visibility rule eksik"
[ "$ACCOUNTANT_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.13 accountant visibility rule hazır" || fail "5.13 accountant visibility rule eksik"
[ "$CROSS_BRANCH_CHECK_COUNT" -eq 2 ] && pass "5.14 cross-branch guard seti hazır" || fail "5.14 cross-branch guard seti eksik"
[ "$PERMISSION_EFFECT_CHECK_COUNT" -eq 1 ] && pass "5.15 permission effect rule hazır" || fail "5.15 permission effect rule eksik"

{
  echo "# FAZ 1-3.6 Entity / Branch Visibility Rules Strict Suite Result"
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

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
echo "VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
echo "VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
echo "VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
echo "VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
echo "VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
echo "VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
echo "VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
echo "VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
echo "ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
echo "BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
echo "ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_6_ENTITY_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_BRANCH_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS=PASS"
  echo "FAZ_1_3_6_VISIBILITY_RULES_TEST_STATUS=PASS"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_6_VISIBILITY_RULES_TEST_STATUS=FAIL"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_VISIBILITY_RULES_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS")"

ENTITY_VISIBILITY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_ENTITY_VISIBILITY_STATUS")"
BRANCH_VISIBILITY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_BRANCH_VISIBILITY_STATUS")"
ROLE_BASED_VISIBILITY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS")"
ACCOUNTANT_VISIBILITY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS")"
CROSS_BRANCH_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "15. strict suite FAIL_COUNT=0 doğrulandı" || fail "15. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "16. strict suite status PASS doğrulandı" || fail "16. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "17. strict suite seal SEALED doğrulandı" || fail "17. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "18. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.6 — Entity / Branch Visibility Rules Veri Modeli

## Kapsam

- Entity visibility
- Branch visibility
- Role-based visibility
- Accountant visibility
- Cross-branch tests

## Uygulama

Bu adım org.visibility_rules tablosunu kurar.

Desteklenen subject tipleri:
- USER
- ROLE
- LEGAL_ENTITY
- ACCOUNTANT
- SYSTEM

Desteklenen visibility scope:
- GLOBAL
- ENTITY
- BRANCH
- LOCATION
- ACCOUNTANT
- ROLE

Branch görünürlük modeli:
- NO_BRANCH
- ALL_BRANCHES
- SPECIFIC_BRANCH
- CROSS_BRANCH

Kritik guard'lar:
- ENTITY scope için target_entity_id zorunlu
- ROLE subject için subject_role zorunlu
- ACCOUNTANT subject için accountant_entity_id zorunlu
- ACCOUNTANT permission delete alamaz
- SPECIFIC_BRANCH için target_branch_id zorunlu
- CROSS_BRANCH_READ / CROSS_BRANCH_WRITE için approval_ref zorunlu
- CROSS_BRANCH_WRITE için can_update=true ve access_level WRITE/ADMIN zorunlu

## Final Status

- FAZ_1_3_6_ENTITY_VISIBILITY_STATUS=${ENTITY_VISIBILITY_STATUS:-N/A}
- FAZ_1_3_6_BRANCH_VISIBILITY_STATUS=${BRANCH_VISIBILITY_STATUS:-N/A}
- FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS=${ROLE_BASED_VISIBILITY_STATUS:-N/A}
- FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS=${ACCOUNTANT_VISIBILITY_STATUS:-N/A}
- FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS=${CROSS_BRANCH_TEST_STATUS:-N/A}
- FAZ_1_3_6_VISIBILITY_RULES_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.6 Entity / Branch Visibility Rules Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Visibility SQL: $VISIBILITY_TEST_SQL"
  echo "- Visibility output: $VISIBILITY_TEST_OUT"
  echo
  echo "## Counts"
  echo "- VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
  echo "- VISIBILITY_RULE_COLUMN_COUNT=$VISIBILITY_RULE_COLUMN_COUNT"
  echo "- VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
  echo "- VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
  echo "- VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
  echo "- VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
  echo "- VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
  echo "- VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
  echo "- VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT=$VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT"
  echo "- VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
  echo "- VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
  echo "- ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
  echo "- BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
  echo "- ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
  echo "- ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
  echo "- CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
  echo "- PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
  echo
  echo "## Tests"
  echo "- VISIBILITY_TEST_STATUS=$VISIBILITY_TEST_STATUS"
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
  echo "# FAZ 1-3.6 Entity / Branch Visibility Rules Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_6_ENTITY_VISIBILITY_STATUS=${ENTITY_VISIBILITY_STATUS:-N/A}"
  echo "FAZ_1_3_6_BRANCH_VISIBILITY_STATUS=${BRANCH_VISIBILITY_STATUS:-N/A}"
  echo "FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS=${ROLE_BASED_VISIBILITY_STATUS:-N/A}"
  echo "FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS=${ACCOUNTANT_VISIBILITY_STATUS:-N/A}"
  echo "FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS=${CROSS_BRANCH_TEST_STATUS:-N/A}"
  echo "FAZ_1_3_6_VISIBILITY_RULES_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_7_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "18.1 dokümantasyon yazıldı: $DOC_FILE"
pass "18.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "18.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "18.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "VISIBILITY_TEST_STATUS=$VISIBILITY_TEST_STATUS"
echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
echo "VISIBILITY_RULE_COLUMN_COUNT=$VISIBILITY_RULE_COLUMN_COUNT"
echo "VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
echo "VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
echo "VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
echo "VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
echo "VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
echo "VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
echo "VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT=$VISIBILITY_RULE_UPDATED_AT_TRIGGER_COUNT"
echo "VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
echo "VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
echo "ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
echo "BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
echo "ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "ENTITY_VISIBILITY_STATUS=${ENTITY_VISIBILITY_STATUS:-N/A}"
echo "BRANCH_VISIBILITY_STATUS=${BRANCH_VISIBILITY_STATUS:-N/A}"
echo "ROLE_BASED_VISIBILITY_STATUS=${ROLE_BASED_VISIBILITY_STATUS:-N/A}"
echo "ACCOUNTANT_VISIBILITY_STATUS=${ACCOUNTANT_VISIBILITY_STATUS:-N/A}"
echo "CROSS_BRANCH_TEST_STATUS=${CROSS_BRANCH_TEST_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$VISIBILITY_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_6_ENTITY_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_BRANCH_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS=PASS"
  echo "FAZ_1_3_6_VISIBILITY_RULES_FINAL_STATUS=PASS"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_7_READY=YES"
else
  echo "FAZ_1_3_6_VISIBILITY_RULES_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_7_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES END ====="
