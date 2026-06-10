#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_5_COMPANY_OWNED_VS_FRANCHISE_OPERATED"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_5_company_owned_vs_franchise_operated_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_5_company_owned_vs_franchise_operated.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_5_company_owned_vs_franchise_operated_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_5_COMPANY_OWNED_VS_FRANCHISE_OPERATED.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_3_5_company_owned_vs_franchise_operated.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_5_COMPANY_OWNED_VS_FRANCHISE_OPERATED_FINAL_SEAL_$TS.md"

OPERATION_TEST_SQL="$SUITE_RUNTIME_DIR/company_owned_vs_franchise_operated_suite.sql"
OPERATION_TEST_OUT="$SUITE_RUNTIME_DIR/company_owned_vs_franchise_operated_suite.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_5_strict_suite_run.out"

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

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED START ====="

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

FRANCHISE_GENERIC_STATUS_VALUE="$(choose_enum_or_default "franchise.agreements" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
        WHEN 'inactive' THEN 6
")"

[ -z "$LEGAL_ENTITY_STATUS_VALUE" ] && LEGAL_ENTITY_STATUS_VALUE="active"
[ -z "$FRANCHISE_GENERIC_STATUS_VALUE" ] && FRANCHISE_GENERIC_STATUS_VALUE="active"

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

LOCATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
FRANCHISE_AGREEMENT_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "FRANCHISE_GENERIC_STATUS_VALUE=$FRANCHISE_GENERIC_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
echo "FRANCHISE_AGREEMENT_TABLE_COUNT=$FRANCHISE_AGREEMENT_TABLE_COUNT"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "$FRANCHISE_GENERIC_STATUS_VALUE" ] && pass "7.2 franchise generic status değeri seçildi" || fail "7.2 franchise generic status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.3 tenant FK referans tablosu bulundu" || fail "7.3 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.4 tenant FK referans UUID kolonu bulundu" || fail "7.4 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.5 gerçek tenant_id bulundu" || fail "7.5 gerçek tenant_id bulunamadı"
[ "$LOCATION_TABLE_COUNT" -eq 1 ] && pass "7.6 org.business_locations hazır" || fail "7.6 org.business_locations eksik"
[ "$FRANCHISE_AGREEMENT_TABLE_COUNT" -eq 1 ] && pass "7.7 franchise.agreements hazır" || fail "7.7 franchise.agreements eksik"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. company-owned vs franchise-operated migration hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS org;
CREATE SCHEMA IF NOT EXISTS franchise;

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

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_business_locations_id_tenant_id_fk
  ON org.business_locations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_franchise_agreements_id_tenant_id_fk
  ON franchise.agreements(id, tenant_id);

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
END $$;

CREATE TABLE IF NOT EXISTS org.location_operation_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,
  branch_id uuid,
  location_id uuid NOT NULL,
  franchise_agreement_id uuid,
  business_code text NOT NULL,
  operation_profile_code text NOT NULL,
  business_model text NOT NULL,
  ownership_type text NOT NULL,
  operation_type text NOT NULL,
  reporting_effect text NOT NULL,
  permission_effect text NOT NULL,
  revenue_owner_entity_id uuid NOT NULL,
  operator_entity_id uuid NOT NULL,
  inventory_owner_entity_id uuid NOT NULL,
  accounting_responsibility text NOT NULL DEFAULT 'LEGAL_ENTITY_BOOKS',
  inventory_responsibility text NOT NULL DEFAULT 'LOCATION_OPERATOR',
  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',
  lifecycle_reason text,
  operation_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS branch_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS location_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS franchise_agreement_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operation_profile_code text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS business_model text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS ownership_type text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operation_type text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS reporting_effect text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS permission_effect text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS revenue_owner_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operator_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS inventory_owner_entity_id uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS accounting_responsibility text DEFAULT 'LEGAL_ENTITY_BOOKS';
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS inventory_responsibility text DEFAULT 'LOCATION_OPERATOR';
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS operation_audit_ref text;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.location_operation_profiles ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.location_operation_profiles SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.location_operation_profiles SET business_code='OP_PROFILE_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.location_operation_profiles SET operation_profile_code=business_code WHERE operation_profile_code IS NULL OR btrim(operation_profile_code::text)='';
UPDATE org.location_operation_profiles SET business_model='COMPANY_BRANCH' WHERE business_model IS NULL OR btrim(business_model::text)='';
UPDATE org.location_operation_profiles SET ownership_type='COMPANY_OWNED' WHERE ownership_type IS NULL OR btrim(ownership_type::text)='';
UPDATE org.location_operation_profiles SET operation_type='COMPANY_OPERATED' WHERE operation_type IS NULL OR btrim(operation_type::text)='';
UPDATE org.location_operation_profiles SET reporting_effect='CONSOLIDATED' WHERE reporting_effect IS NULL OR btrim(reporting_effect::text)='';
UPDATE org.location_operation_profiles SET permission_effect='INTERNAL_FULL_SCOPE' WHERE permission_effect IS NULL OR btrim(permission_effect::text)='';
UPDATE org.location_operation_profiles SET accounting_responsibility='LEGAL_ENTITY_BOOKS' WHERE accounting_responsibility IS NULL OR btrim(accounting_responsibility::text)='';
UPDATE org.location_operation_profiles SET inventory_responsibility='LOCATION_OPERATOR' WHERE inventory_responsibility IS NULL OR btrim(inventory_responsibility::text)='';
UPDATE org.location_operation_profiles SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.location_operation_profiles SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.location_operation_profiles SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.location_operation_profiles SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.location_operation_profiles SET created_at=now() WHERE created_at IS NULL;
UPDATE org.location_operation_profiles SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='location_operation_profiles'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.location_operation_profiles ADD CONSTRAINT pk_org_location_operation_profiles PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_id_tenant_id_fk
  ON org.location_operation_profiles(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_tenant_business_code
  ON org.location_operation_profiles(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_tenant_profile_code
  ON org.location_operation_profiles(tenant_id, operation_profile_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_location_operation_profiles_active_location
  ON org.location_operation_profiles(tenant_id, location_id)
  WHERE deleted_at IS NULL
    AND status='ACTIVE'
    AND effective_to IS NULL;

CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_tenant_id ON org.location_operation_profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_legal_entity_id ON org.location_operation_profiles(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_branch_id ON org.location_operation_profiles(branch_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_location_id ON org.location_operation_profiles(location_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_franchise_agreement_id ON org.location_operation_profiles(franchise_agreement_id);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_business_model ON org.location_operation_profiles(business_model);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_ownership_operation ON org.location_operation_profiles(ownership_type, operation_type);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_reporting_effect ON org.location_operation_profiles(reporting_effect);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_permission_effect ON org.location_operation_profiles(permission_effect);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_status ON org.location_operation_profiles(status);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_effective_dates ON org.location_operation_profiles(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_org_location_operation_profiles_audit_ref ON org.location_operation_profiles(operation_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_legal_entity_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_location_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_location_tenant
      FOREIGN KEY (location_id, tenant_id)
      REFERENCES org.business_locations(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_revenue_owner_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_revenue_owner_tenant
      FOREIGN KEY (revenue_owner_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_operator_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_operator_tenant
      FOREIGN KEY (operator_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_inventory_owner_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_inventory_owner_tenant
      FOREIGN KEY (inventory_owner_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_location_operation_profiles_franchise_agreement_tenant'
      AND conrelid='org.location_operation_profiles'::regclass
  ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_franchise_agreement_tenant
      FOREIGN KEY (franchise_agreement_id, tenant_id)
      REFERENCES franchise.agreements(id, tenant_id)
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
       WHERE conname='fk_org_location_operation_profiles_branch_tenant'
         AND conrelid='org.location_operation_profiles'::regclass
     ) THEN
    ALTER TABLE org.location_operation_profiles
      ADD CONSTRAINT fk_org_location_operation_profiles_branch_tenant
      FOREIGN KEY (branch_id, tenant_id)
      REFERENCES org.branches(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_required_fields;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND location_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND operation_profile_code IS NOT NULL AND btrim(operation_profile_code::text) <> ''
    AND business_model IS NOT NULL AND btrim(business_model::text) <> ''
    AND ownership_type IS NOT NULL AND btrim(ownership_type::text) <> ''
    AND operation_type IS NOT NULL AND btrim(operation_type::text) <> ''
    AND reporting_effect IS NOT NULL AND btrim(reporting_effect::text) <> ''
    AND permission_effect IS NOT NULL AND btrim(permission_effect::text) <> ''
    AND revenue_owner_entity_id IS NOT NULL
    AND operator_entity_id IS NOT NULL
    AND inventory_owner_entity_id IS NOT NULL
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_business_model;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_business_model
  CHECK (
    business_model IN (
      'COMPANY_BRANCH',
      'FRANCHISE_STORE',
      'PARTNER_STORE',
      'HYBRID_OPERATION',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_ownership_type;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_ownership_type
  CHECK (
    ownership_type IN (
      'COMPANY_OWNED',
      'FRANCHISE_OWNED',
      'PARTNER_OWNED',
      'LEASED',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_operation_type;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_operation_type
  CHECK (
    operation_type IN (
      'COMPANY_OPERATED',
      'FRANCHISE_OPERATED',
      'PARTNER_OPERATED',
      'THIRD_PARTY_OPERATED',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_reporting_effect;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_reporting_effect
  CHECK (
    reporting_effect IN (
      'CONSOLIDATED',
      'FRANCHISE_REVENUE_SHARE',
      'FRANCHISE_SEPARATE_BOOKS',
      'PARTNER_SETTLEMENT',
      'EXTERNAL_OPERATOR',
      'EXCLUDED'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_permission_effect;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_permission_effect
  CHECK (
    permission_effect IN (
      'INTERNAL_FULL_SCOPE',
      'FRANCHISE_OPERATOR_SCOPE',
      'PARTNER_LIMITED_SCOPE',
      'READ_ONLY',
      'NO_ACCESS'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_responsibility;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_responsibility
  CHECK (
    accounting_responsibility IN (
      'LEGAL_ENTITY_BOOKS',
      'FRANCHISEE_BOOKS',
      'PARTNER_BOOKS',
      'EXTERNAL_BOOKS'
    )
    AND inventory_responsibility IN (
      'LOCATION_OPERATOR',
      'LEGAL_ENTITY',
      'FRANCHISEE',
      'PARTNER'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_status;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','CLOSED')
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_effective_dates;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_company_branch_rule;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_company_branch_rule
  CHECK (
    business_model <> 'COMPANY_BRANCH'
    OR (
      ownership_type='COMPANY_OWNED'
      AND operation_type='COMPANY_OPERATED'
      AND reporting_effect='CONSOLIDATED'
      AND permission_effect='INTERNAL_FULL_SCOPE'
      AND franchise_agreement_id IS NULL
      AND accounting_responsibility='LEGAL_ENTITY_BOOKS'
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_franchise_store_rule;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_franchise_store_rule
  CHECK (
    business_model <> 'FRANCHISE_STORE'
    OR (
      ownership_type IN ('FRANCHISE_OWNED','LEASED','COMPANY_OWNED')
      AND operation_type='FRANCHISE_OPERATED'
      AND reporting_effect IN ('FRANCHISE_REVENUE_SHARE','FRANCHISE_SEPARATE_BOOKS')
      AND permission_effect='FRANCHISE_OPERATOR_SCOPE'
      AND franchise_agreement_id IS NOT NULL
      AND accounting_responsibility IN ('FRANCHISEE_BOOKS','LEGAL_ENTITY_BOOKS')
      AND inventory_responsibility IN ('LOCATION_OPERATOR','FRANCHISEE')
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_partner_rule;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_partner_rule
  CHECK (
    business_model <> 'PARTNER_STORE'
    OR (
      ownership_type='PARTNER_OWNED'
      AND operation_type IN ('PARTNER_OPERATED','THIRD_PARTY_OPERATED')
      AND reporting_effect IN ('PARTNER_SETTLEMENT','EXTERNAL_OPERATOR')
      AND permission_effect='PARTNER_LIMITED_SCOPE'
      AND accounting_responsibility IN ('PARTNER_BOOKS','EXTERNAL_BOOKS')
    )
  ) NOT VALID;

ALTER TABLE org.location_operation_profiles DROP CONSTRAINT IF EXISTS ck_org_location_operation_profiles_audit_for_closed;
ALTER TABLE org.location_operation_profiles
  ADD CONSTRAINT ck_org_location_operation_profiles_audit_for_closed
  CHECK (
    status <> 'CLOSED'
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND operation_audit_ref IS NOT NULL
      AND btrim(operation_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_location_operation_profiles_set_updated_at ON org.location_operation_profiles;
CREATE TRIGGER trg_org_location_operation_profiles_set_updated_at
BEFORE UPDATE ON org.location_operation_profiles
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.location_operation_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.location_operation_profiles FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_location_operation_profiles_tenant_rw ON org.location_operation_profiles;
CREATE POLICY allow_org_location_operation_profiles_tenant_rw
ON org.location_operation_profiles
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
      'location_operation_profiles',
      'organization_operation_model',
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
          AND c.table_name='location_operation_profiles'
      ),
      jsonb_build_object(
        'phase','FAZ_1_3_5',
        'source','company_owned_vs_franchise_operated',
        'business_models', jsonb_build_array('COMPANY_BRANCH','FRANCHISE_STORE','PARTNER_STORE','HYBRID_OPERATION')
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
GRANT SELECT, INSERT, UPDATE ON org.location_operation_profiles TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
SQL

pass "8.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. company-owned vs franchise-operated migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 migration başarıyla uygulandı"
else
  fail "9.1 migration uygulanamadı"
  exit 1
fi

echo "10. operation profile lifecycle / abuse SQL suite hazırlanıyor..."

cat <<SQL > "$OPERATION_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_company_entity_id uuid := gen_random_uuid();
  v_franchisor_id uuid := gen_random_uuid();
  v_franchisee_id uuid := gen_random_uuid();
  v_operator_id uuid := gen_random_uuid();
  v_company_location_id uuid := gen_random_uuid();
  v_franchise_location_id uuid := gen_random_uuid();
  v_franchise_agreement_id uuid := gen_random_uuid();
  v_suffix text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_legal_status org.legal_entities.status%TYPE := '$LEGAL_ENTITY_STATUS_VALUE';
  v_franchise_status franchise.agreements.status%TYPE := '$FRANCHISE_GENERIC_STATUS_VALUE';
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
    'CO_ENTITY_' || v_suffix,
    'PIX2PI COMPANY OWNED TEST A.S.',
    'PIX2PI COMPANY',
    '951' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120005001',
    'company-' || lower(v_suffix) || '@pix2pi.local',
    'COMPANY TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_5_company_entity')
  ),
  (
    v_franchisor_id, v_tenant_id, v_franchisor_id,
    'OP_FRANCHISOR_' || v_suffix,
    'PIX2PI OP FRANCHISOR TEST A.S.',
    'PIX2PI OP FRANCHISOR',
    '952' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120005002',
    'op-franchisor-' || lower(v_suffix) || '@pix2pi.local',
    'FRANCHISOR TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_5_franchisor')
  ),
  (
    v_franchisee_id, v_tenant_id, v_franchisee_id,
    'OP_FRANCHISEE_' || v_suffix,
    'PIX2PI OP FRANCHISEE TEST A.S.',
    'PIX2PI OP FRANCHISEE',
    '953' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120005003',
    'op-franchisee-' || lower(v_suffix) || '@pix2pi.local',
    'FRANCHISEE TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_5_franchisee')
  ),
  (
    v_operator_id, v_tenant_id, v_operator_id,
    'OP_OPERATOR_' || v_suffix,
    'PIX2PI OPERATOR TEST A.S.',
    'PIX2PI OPERATOR',
    '954' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120005004',
    'op-operator-' || lower(v_suffix) || '@pix2pi.local',
    'OPERATOR TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_5_operator')
  );

  INSERT INTO org.business_locations (
    id, tenant_id, legal_entity_id, business_code, location_code, location_name,
    location_type, ownership_type, operation_type,
    inventory_enabled, sales_enabled, purchasing_enabled, is_default,
    address_line, district, city, country_code,
    status, location_audit_ref, metadata
  )
  VALUES
  (
    v_company_location_id, v_tenant_id, v_company_entity_id,
    'CO_LOC_' || v_suffix,
    'CO_STORE_' || v_suffix,
    'COMPANY OWNED STORE',
    'STORE',
    'COMPANY_OWNED',
    'COMPANY_OPERATED',
    true,
    true,
    false,
    true,
    'COMPANY STORE ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    'ACTIVE',
    'CO_LOCATION_AUDIT_' || v_suffix,
    jsonb_build_object('test','company_owned_location')
  ),
  (
    v_franchise_location_id, v_tenant_id, v_franchisee_id,
    'FR_LOC_' || v_suffix,
    'FR_STORE_' || v_suffix,
    'FRANCHISE OPERATED STORE',
    'STORE',
    'FRANCHISE_OWNED',
    'FRANCHISE_OPERATED',
    true,
    true,
    false,
    false,
    'FRANCHISE STORE ADRES',
    'BESIKTAS',
    'ISTANBUL',
    'TR',
    'ACTIVE',
    'FR_LOCATION_AUDIT_' || v_suffix,
    jsonb_build_object('test','franchise_operated_location')
  );

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
    v_franchise_agreement_id,
    v_tenant_id,
    v_franchisor_id,
    'OP_FR_AGREEMENT_' || v_suffix,
    'OP-FR-AGR-' || v_suffix,
    'STANDARD_FRANCHISE',
    v_franchisor_id,
    v_franchisee_id,
    v_franchisee_id,
    v_operator_id,
    'TR-IST-BESIKTAS',
    'Istanbul Besiktas',
    current_date,
    current_date + 365,
    now(),
    now(),
    v_franchise_status,
    'ACTIVE',
    'operation profile test activation',
    'OP_FR_AGREEMENT_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_5_franchise_agreement')
  );

  INSERT INTO org.location_operation_profiles (
    tenant_id,
    legal_entity_id,
    location_id,
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
    v_company_entity_id,
    v_company_location_id,
    'OP_PROFILE_COMPANY_' || v_suffix,
    'OP-COMPANY-' || v_suffix,
    'COMPANY_BRANCH',
    'COMPANY_OWNED',
    'COMPANY_OPERATED',
    'CONSOLIDATED',
    'INTERNAL_FULL_SCOPE',
    v_company_entity_id,
    v_company_entity_id,
    v_company_entity_id,
    'LEGAL_ENTITY_BOOKS',
    'LEGAL_ENTITY',
    current_date,
    'ACTIVE',
    'OP_AUDIT_COMPANY_' || v_suffix,
    jsonb_build_object('test','company_owned_branch_profile')
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
    v_franchise_agreement_id,
    'OP_PROFILE_FRANCHISE_' || v_suffix,
    'OP-FRANCHISE-' || v_suffix,
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
    'OP_AUDIT_FRANCHISE_' || v_suffix,
    jsonb_build_object('test','franchise_operated_store_profile')
  );

  SELECT count(*)
  INTO v_count
  FROM org.location_operation_profiles
  WHERE tenant_id=v_tenant_id
    AND business_model='COMPANY_BRANCH'
    AND ownership_type='COMPANY_OWNED'
    AND operation_type='COMPANY_OPERATED'
    AND reporting_effect='CONSOLIDATED'
    AND permission_effect='INTERNAL_FULL_SCOPE';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'company-owned branch operation profile was not persisted correctly';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.location_operation_profiles
  WHERE tenant_id=v_tenant_id
    AND business_model='FRANCHISE_STORE'
    AND ownership_type='FRANCHISE_OWNED'
    AND operation_type='FRANCHISE_OPERATED'
    AND reporting_effect='FRANCHISE_REVENUE_SHARE'
    AND permission_effect='FRANCHISE_OPERATOR_SCOPE'
    AND franchise_agreement_id=v_franchise_agreement_id;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'franchise-operated store operation profile was not persisted correctly';
  END IF;

  BEGIN
    INSERT INTO org.location_operation_profiles (
      tenant_id, legal_entity_id, location_id,
      business_code, operation_profile_code,
      business_model, ownership_type, operation_type,
      reporting_effect, permission_effect,
      revenue_owner_entity_id, operator_entity_id, inventory_owner_entity_id,
      accounting_responsibility, inventory_responsibility,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id, v_company_location_id,
      'OP_BAD_COMPANY_' || v_suffix,
      'OP-BAD-COMPANY-' || v_suffix,
      'COMPANY_BRANCH',
      'FRANCHISE_OWNED',
      'COMPANY_OPERATED',
      'CONSOLIDATED',
      'INTERNAL_FULL_SCOPE',
      v_company_entity_id,
      v_company_entity_id,
      v_company_entity_id,
      'LEGAL_ENTITY_BOOKS',
      'LEGAL_ENTITY',
      current_date + 1000,
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad company-owned branch ownership rule was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.location_operation_profiles (
      tenant_id, legal_entity_id, location_id,
      business_code, operation_profile_code,
      business_model, ownership_type, operation_type,
      reporting_effect, permission_effect,
      revenue_owner_entity_id, operator_entity_id, inventory_owner_entity_id,
      accounting_responsibility, inventory_responsibility,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_franchisee_id, v_franchise_location_id,
      'OP_BAD_FR_NO_AGR_' || v_suffix,
      'OP-BAD-FR-NO-AGR-' || v_suffix,
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
      current_date + 1000,
      'ACTIVE'
    );

    RAISE EXCEPTION 'franchise store without agreement was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.location_operation_profiles (
      tenant_id, legal_entity_id, location_id, franchise_agreement_id,
      business_code, operation_profile_code,
      business_model, ownership_type, operation_type,
      reporting_effect, permission_effect,
      revenue_owner_entity_id, operator_entity_id, inventory_owner_entity_id,
      accounting_responsibility, inventory_responsibility,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_franchisee_id, v_franchise_location_id, v_franchise_agreement_id,
      'OP_BAD_FR_PERMISSION_' || v_suffix,
      'OP-BAD-FR-PERM-' || v_suffix,
      'FRANCHISE_STORE',
      'FRANCHISE_OWNED',
      'FRANCHISE_OPERATED',
      'FRANCHISE_REVENUE_SHARE',
      'INTERNAL_FULL_SCOPE',
      v_franchisee_id,
      v_operator_id,
      v_franchisee_id,
      'FRANCHISEE_BOOKS',
      'FRANCHISEE',
      current_date + 1000,
      'ACTIVE'
    );

    RAISE EXCEPTION 'franchise store bad permission effect was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.location_operation_profiles (
      tenant_id, legal_entity_id, location_id,
      business_code, operation_profile_code,
      business_model, ownership_type, operation_type,
      reporting_effect, permission_effect,
      revenue_owner_entity_id, operator_entity_id, inventory_owner_entity_id,
      accounting_responsibility, inventory_responsibility,
      effective_from, effective_to, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id, v_company_location_id,
      'OP_BAD_DATE_' || v_suffix,
      'OP-BAD-DATE-' || v_suffix,
      'COMPANY_BRANCH',
      'COMPANY_OWNED',
      'COMPANY_OPERATED',
      'CONSOLIDATED',
      'INTERNAL_FULL_SCOPE',
      v_company_entity_id,
      v_company_entity_id,
      v_company_entity_id,
      'LEGAL_ENTITY_BOOKS',
      'LEGAL_ENTITY',
      current_date + 10,
      current_date + 9,
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad effective date range was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.location_operation_profiles (
      tenant_id, legal_entity_id, location_id,
      business_code, operation_profile_code,
      business_model, ownership_type, operation_type,
      reporting_effect, permission_effect,
      revenue_owner_entity_id, operator_entity_id, inventory_owner_entity_id,
      accounting_responsibility, inventory_responsibility,
      effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id, v_company_location_id,
      'OP_BAD_MODEL_' || v_suffix,
      'OP-BAD-MODEL-' || v_suffix,
      'BAD_MODEL',
      'COMPANY_OWNED',
      'COMPANY_OPERATED',
      'CONSOLIDATED',
      'INTERNAL_FULL_SCOPE',
      v_company_entity_id,
      v_company_entity_id,
      v_company_entity_id,
      'LEGAL_ENTITY_BOOKS',
      'LEGAL_ENTITY',
      current_date + 1000,
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad business_model was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "10.1 operation profile SQL suite dosyası yazıldı: $OPERATION_TEST_SQL / OK ✅"

echo "11. operation profile lifecycle / abuse SQL suite çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$OPERATION_TEST_SQL" > "$OPERATION_TEST_OUT" 2>&1; then
  pass "11.1 operation profile lifecycle / abuse SQL suite geçti"
else
  fail "11.1 operation profile lifecycle / abuse SQL suite başarısız"
  cat "$OPERATION_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$OPERATION_TEST_OUT"; then
  pass "11.2 operation profile test rollback ile temizlendi"
  OPERATION_TEST_STATUS="PASS"
else
  fail "11.2 operation profile rollback kanıtı yok"
  OPERATION_TEST_STATUS="FAIL"
fi

echo "12. operation profile model sayaçları alınıyor..."

OP_PROFILE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"

OP_PROFILE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='location_operation_profiles'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','location_id','franchise_agreement_id',
      'business_code','operation_profile_code',
      'business_model','ownership_type','operation_type',
      'reporting_effect','permission_effect',
      'revenue_owner_entity_id','operator_entity_id','inventory_owner_entity_id',
      'accounting_responsibility','inventory_responsibility',
      'effective_from','effective_to','status',
      'lifecycle_reason','operation_audit_ref',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

OP_PROFILE_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and contype='f';")"
OP_PROFILE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and contype='c';")"
OP_PROFILE_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='location_operation_profiles';")"
OP_PROFILE_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='location_operation_profiles' and c.relrowsecurity=true;")"
OP_PROFILE_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='location_operation_profiles' and c.relforcerowsecurity=true;")"
OP_PROFILE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='location_operation_profiles';")"
OP_PROFILE_UPDATED_AT_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_location_operation_profiles_set_updated_at' and tgrelid='org.location_operation_profiles'::regclass and not tgisinternal;")"
OP_PROFILE_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='location_operation_profiles' and column_name in ('lifecycle_reason','operation_audit_ref','audit_metadata');")"
OP_PROFILE_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='location_operation_profiles';")"

COMPANY_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_company_branch_rule';")"
FRANCHISE_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_franchise_store_rule';")"
REPORTING_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_reporting_effect';")"
PERMISSION_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_permission_effect';")"

LOCATION_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
FRANCHISE_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"

echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
echo "OP_PROFILE_COLUMN_COUNT=$OP_PROFILE_COLUMN_COUNT"
echo "OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
echo "OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
echo "OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
echo "OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
echo "OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
echo "OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
echo "OP_PROFILE_UPDATED_AT_TRIGGER_COUNT=$OP_PROFILE_UPDATED_AT_TRIGGER_COUNT"
echo "OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
echo "OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
echo "COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
echo "FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
echo "REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
echo "FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"
echo "OPERATION_TEST_STATUS=$OPERATION_TEST_STATUS"

[ "$OP_PROFILE_TABLE_COUNT" -eq 1 ] && pass "12.1 location_operation_profiles tablosu hazır" || fail "12.1 operation profile tablosu eksik"
[ "$OP_PROFILE_COLUMN_COUNT" -ge 30 ] && pass "12.2 operation profile kolon kapsamı tam" || fail "12.2 operation profile kolon kapsamı eksik"
[ "$OP_PROFILE_FK_COUNT" -ge 6 ] && pass "12.3 operation profile FK seti hazır" || fail "12.3 operation profile FK seti eksik"
[ "$OP_PROFILE_CHECK_COUNT" -ge 12 ] && pass "12.4 operation profile check constraint seti hazır" || fail "12.4 operation profile check seti eksik"
[ "$OP_PROFILE_INDEX_COUNT" -ge 12 ] && pass "12.5 operation profile index seti hazır" || fail "12.5 operation profile index seti eksik"
[ "$OP_PROFILE_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.6 operation profile RLS enabled" || fail "12.6 operation profile RLS enabled eksik"
[ "$OP_PROFILE_RLS_FORCED_COUNT" -eq 1 ] && pass "12.7 operation profile RLS forced" || fail "12.7 operation profile RLS forced eksik"
[ "$OP_PROFILE_POLICY_COUNT" -ge 1 ] && pass "12.8 operation profile tenant policy hazır" || fail "12.8 operation profile tenant policy eksik"
[ "$OP_PROFILE_UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "12.9 operation profile updated_at trigger hazır" || fail "12.9 operation profile updated_at trigger eksik"
[ "$OP_PROFILE_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "12.10 operation profile audit kolonları hazır" || fail "12.10 operation profile audit kolonları eksik"
[ "$OP_PROFILE_DICTIONARY_COUNT" -ge 1 ] && pass "12.11 operation profile data dictionary kaydı mevcut" || warn "12.11 operation profile data dictionary kaydı eksik"
[ "$COMPANY_RULE_CHECK_COUNT" -eq 1 ] && pass "12.12 company-owned rule constraint hazır" || fail "12.12 company-owned rule constraint eksik"
[ "$FRANCHISE_RULE_CHECK_COUNT" -eq 1 ] && pass "12.13 franchise-operated rule constraint hazır" || fail "12.13 franchise-operated rule constraint eksik"
[ "$REPORTING_EFFECT_CHECK_COUNT" -eq 1 ] && pass "12.14 reporting effect constraint hazır" || fail "12.14 reporting effect constraint eksik"
[ "$PERMISSION_EFFECT_CHECK_COUNT" -eq 1 ] && pass "12.15 permission effect constraint hazır" || fail "12.15 permission effect constraint eksik"
[ "$LOCATION_DEPENDENCY_COUNT" -eq 1 ] && pass "12.16 business_locations dependency hazır" || fail "12.16 business_locations dependency eksik"
[ "$FRANCHISE_DEPENDENCY_COUNT" -eq 1 ] && pass "12.17 franchise agreements dependency hazır" || fail "12.17 franchise agreements dependency eksik"
[ "$OPERATION_TEST_STATUS" = "PASS" ] && pass "12.18 operation profile lifecycle / abuse suite PASS" || fail "12.18 operation profile lifecycle / abuse suite FAIL"

echo "13. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_5_company_owned_vs_franchise_operated_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_5_COMPANY_OWNED_VS_FRANCHISE_OPERATED_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED STRICT SUITE START ====="

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

OP_PROFILE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"
OP_PROFILE_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and contype='f';")"
OP_PROFILE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and contype='c';")"
OP_PROFILE_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='location_operation_profiles';")"
OP_PROFILE_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='location_operation_profiles' and c.relrowsecurity=true;")"
OP_PROFILE_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='location_operation_profiles' and c.relforcerowsecurity=true;")"
OP_PROFILE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='location_operation_profiles';")"
OP_PROFILE_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='location_operation_profiles' and column_name in ('lifecycle_reason','operation_audit_ref','audit_metadata');")"
OP_PROFILE_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='location_operation_profiles';")"

COMPANY_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_company_branch_rule';")"
FRANCHISE_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_franchise_store_rule';")"
REPORTING_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_reporting_effect';")"
PERMISSION_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_permission_effect';")"
LOCATION_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
FRANCHISE_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"

echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
echo "OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
echo "OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
echo "OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
echo "OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
echo "OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
echo "OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
echo "OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
echo "OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
echo "COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
echo "FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
echo "REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
echo "FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"

[ "$OP_PROFILE_TABLE_COUNT" -eq 1 ] && pass "5.1 operation profile tablosu hazır" || fail "5.1 operation profile tablosu eksik"
[ "$OP_PROFILE_FK_COUNT" -ge 6 ] && pass "5.2 operation profile FK seti hazır" || fail "5.2 operation profile FK seti eksik"
[ "$OP_PROFILE_CHECK_COUNT" -ge 12 ] && pass "5.3 operation profile check seti hazır" || fail "5.3 operation profile check seti eksik"
[ "$OP_PROFILE_INDEX_COUNT" -ge 12 ] && pass "5.4 operation profile index seti hazır" || fail "5.4 operation profile index seti eksik"
[ "$OP_PROFILE_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 operation profile RLS enabled" || fail "5.5 operation profile RLS enabled eksik"
[ "$OP_PROFILE_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 operation profile RLS forced" || fail "5.6 operation profile RLS forced eksik"
[ "$OP_PROFILE_POLICY_COUNT" -ge 1 ] && pass "5.7 operation profile tenant policy hazır" || fail "5.7 operation profile tenant policy eksik"
[ "$OP_PROFILE_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.8 operation audit kolonları hazır" || fail "5.8 operation audit kolonları eksik"
[ "$OP_PROFILE_DICTIONARY_COUNT" -ge 1 ] && pass "5.9 operation profile data dictionary mevcut" || warn "5.9 operation profile data dictionary eksik"
[ "$COMPANY_RULE_CHECK_COUNT" -eq 1 ] && pass "5.10 company-owned branch rule hazır" || fail "5.10 company-owned branch rule eksik"
[ "$FRANCHISE_RULE_CHECK_COUNT" -eq 1 ] && pass "5.11 franchise-operated store rule hazır" || fail "5.11 franchise-operated store rule eksik"
[ "$REPORTING_EFFECT_CHECK_COUNT" -eq 1 ] && pass "5.12 reporting effect rule hazır" || fail "5.12 reporting effect rule eksik"
[ "$PERMISSION_EFFECT_CHECK_COUNT" -eq 1 ] && pass "5.13 permission effect rule hazır" || fail "5.13 permission effect rule eksik"
[ "$LOCATION_DEPENDENCY_COUNT" -eq 1 ] && pass "5.14 business_locations dependency hazır" || fail "5.14 business_locations dependency eksik"
[ "$FRANCHISE_DEPENDENCY_COUNT" -eq 1 ] && pass "5.15 franchise agreements dependency hazır" || fail "5.15 franchise agreements dependency eksik"

{
  echo "# FAZ 1-3.5 Company-owned vs Franchise-operated Strict Suite Result"
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

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
echo "OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
echo "OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
echo "OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
echo "OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
echo "OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
echo "OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
echo "OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
echo "OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
echo "COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
echo "FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
echo "REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
echo "FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_5_OWNERSHIP_TYPE_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_TYPE_STATUS=PASS"
  echo "FAZ_1_3_5_REPORTING_EFFECT_STATUS=PASS"
  echo "FAZ_1_3_5_PERMISSION_EFFECT_STATUS=PASS"
  echo "FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS=PASS"
  echo "FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_PROFILE_TEST_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_5_OPERATION_PROFILE_TEST_STATUS=FAIL"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_OPERATION_PROFILE_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS")"

OWNERSHIP_TYPE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_OWNERSHIP_TYPE_STATUS")"
OPERATION_TYPE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_OPERATION_TYPE_STATUS")"
REPORTING_EFFECT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_REPORTING_EFFECT_STATUS")"
PERMISSION_EFFECT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_PERMISSION_EFFECT_STATUS")"
COMPANY_BRANCH_RULE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS")"
FRANCHISE_STORE_RULE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "15. strict suite FAIL_COUNT=0 doğrulandı" || fail "15. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "16. strict suite status PASS doğrulandı" || fail "16. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "17. strict suite seal SEALED doğrulandı" || fail "17. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "18. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.5 — Company-owned branch vs franchise-operated store ayrımı

## Kapsam

- Ownership type
- Operation type
- Reporting effect
- Permission effect
- Test

## Uygulama

Bu adım org.location_operation_profiles tablosunu kurar.

Model ayrımları:
- COMPANY_BRANCH
- FRANCHISE_STORE
- PARTNER_STORE
- HYBRID_OPERATION
- OTHER

Company-owned branch kuralı:
- ownership_type = COMPANY_OWNED
- operation_type = COMPANY_OPERATED
- reporting_effect = CONSOLIDATED
- permission_effect = INTERNAL_FULL_SCOPE
- franchise_agreement_id boş olmalı

Franchise-operated store kuralı:
- operation_type = FRANCHISE_OPERATED
- franchise_agreement_id zorunlu
- reporting_effect = FRANCHISE_REVENUE_SHARE veya FRANCHISE_SEPARATE_BOOKS
- permission_effect = FRANCHISE_OPERATOR_SCOPE

## Final Status

- FAZ_1_3_5_OWNERSHIP_TYPE_STATUS=${OWNERSHIP_TYPE_STATUS:-N/A}
- FAZ_1_3_5_OPERATION_TYPE_STATUS=${OPERATION_TYPE_STATUS:-N/A}
- FAZ_1_3_5_REPORTING_EFFECT_STATUS=${REPORTING_EFFECT_STATUS:-N/A}
- FAZ_1_3_5_PERMISSION_EFFECT_STATUS=${PERMISSION_EFFECT_STATUS:-N/A}
- FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS=${COMPANY_BRANCH_RULE_STATUS:-N/A}
- FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS=${FRANCHISE_STORE_RULE_STATUS:-N/A}
- FAZ_1_3_5_OPERATION_PROFILE_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.5 Company-owned vs Franchise-operated Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Operation SQL: $OPERATION_TEST_SQL"
  echo "- Operation output: $OPERATION_TEST_OUT"
  echo
  echo "## Counts"
  echo "- OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
  echo "- OP_PROFILE_COLUMN_COUNT=$OP_PROFILE_COLUMN_COUNT"
  echo "- OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
  echo "- OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
  echo "- OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
  echo "- OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
  echo "- OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
  echo "- OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
  echo "- OP_PROFILE_UPDATED_AT_TRIGGER_COUNT=$OP_PROFILE_UPDATED_AT_TRIGGER_COUNT"
  echo "- OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
  echo "- OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
  echo "- COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
  echo "- FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
  echo "- REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
  echo "- PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
  echo "- LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
  echo "- FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"
  echo
  echo "## Tests"
  echo "- OPERATION_TEST_STATUS=$OPERATION_TEST_STATUS"
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
  echo "# FAZ 1-3.5 Company-owned vs Franchise-operated Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_5_OWNERSHIP_TYPE_STATUS=${OWNERSHIP_TYPE_STATUS:-N/A}"
  echo "FAZ_1_3_5_OPERATION_TYPE_STATUS=${OPERATION_TYPE_STATUS:-N/A}"
  echo "FAZ_1_3_5_REPORTING_EFFECT_STATUS=${REPORTING_EFFECT_STATUS:-N/A}"
  echo "FAZ_1_3_5_PERMISSION_EFFECT_STATUS=${PERMISSION_EFFECT_STATUS:-N/A}"
  echo "FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS=${COMPANY_BRANCH_RULE_STATUS:-N/A}"
  echo "FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS=${FRANCHISE_STORE_RULE_STATUS:-N/A}"
  echo "FAZ_1_3_5_OPERATION_PROFILE_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_6_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "18.1 dokümantasyon yazıldı: $DOC_FILE"
pass "18.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "18.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "18.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "OPERATION_TEST_STATUS=$OPERATION_TEST_STATUS"
echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
echo "OP_PROFILE_COLUMN_COUNT=$OP_PROFILE_COLUMN_COUNT"
echo "OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
echo "OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
echo "OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
echo "OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
echo "OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
echo "OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
echo "OP_PROFILE_UPDATED_AT_TRIGGER_COUNT=$OP_PROFILE_UPDATED_AT_TRIGGER_COUNT"
echo "OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
echo "OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
echo "COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
echo "FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
echo "REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
echo "FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "OWNERSHIP_TYPE_STATUS=${OWNERSHIP_TYPE_STATUS:-N/A}"
echo "OPERATION_TYPE_STATUS=${OPERATION_TYPE_STATUS:-N/A}"
echo "REPORTING_EFFECT_STATUS=${REPORTING_EFFECT_STATUS:-N/A}"
echo "PERMISSION_EFFECT_STATUS=${PERMISSION_EFFECT_STATUS:-N/A}"
echo "COMPANY_BRANCH_RULE_STATUS=${COMPANY_BRANCH_RULE_STATUS:-N/A}"
echo "FRANCHISE_STORE_RULE_STATUS=${FRANCHISE_STORE_RULE_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$OPERATION_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_5_OWNERSHIP_TYPE_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_TYPE_STATUS=PASS"
  echo "FAZ_1_3_5_REPORTING_EFFECT_STATUS=PASS"
  echo "FAZ_1_3_5_PERMISSION_EFFECT_STATUS=PASS"
  echo "FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS=PASS"
  echo "FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_PROFILE_FINAL_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_6_READY=YES"
else
  echo "FAZ_1_3_5_OPERATION_PROFILE_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_6_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED END ====="
