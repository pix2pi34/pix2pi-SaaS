#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_7_PARTNER_CUSTOMER_VENDOR_CROSS_COMPANY_RELATIONS"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_7_partner_customer_vendor_cross_company_relations_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_7_partner_customer_vendor_cross_company_relations.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_7_partner_customer_vendor_cross_company_relations_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_7_PARTNER_CUSTOMER_VENDOR_CROSS_COMPANY_RELATIONS.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_3_7_partner_customer_vendor_cross_company_relations.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_7_PARTNER_CUSTOMER_VENDOR_CROSS_COMPANY_RELATIONS_FINAL_SEAL_$TS.md"

RELATION_TEST_SQL="$SUITE_RUNTIME_DIR/partner_customer_vendor_cross_company_relations_suite.sql"
RELATION_TEST_OUT="$SUITE_RUNTIME_DIR/partner_customer_vendor_cross_company_relations_suite.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_7_strict_suite_run.out"

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

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS START ====="

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
VISIBILITY_RULE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.2 tenant FK referans tablosu bulundu" || fail "7.2 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.3 tenant FK referans UUID kolonu bulundu" || fail "7.3 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.4 gerçek tenant_id bulundu" || fail "7.4 gerçek tenant_id bulunamadı"
[ "$LEGAL_ENTITY_TABLE_COUNT" -eq 1 ] && pass "7.5 org.legal_entities hazır" || fail "7.5 org.legal_entities eksik"
[ "$VISIBILITY_RULE_TABLE_COUNT" -eq 1 ] && pass "7.6 org.visibility_rules hazır" || fail "7.6 org.visibility_rules eksik"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. partner/customer/vendor cross-company relation migration hazırlanıyor..."

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

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_visibility_rules_id_tenant_id_fk
  ON org.visibility_rules(id, tenant_id);

CREATE TABLE IF NOT EXISTS org.cross_company_relations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  legal_entity_id uuid NOT NULL,

  business_code text NOT NULL,
  relation_code text NOT NULL,

  relation_type text NOT NULL,
  relation_direction text NOT NULL DEFAULT 'OUTBOUND',
  relation_channel text NOT NULL DEFAULT 'DIRECT',

  counterparty_entity_id uuid,
  counterparty_external_ref text,
  counterparty_name text NOT NULL,

  visibility_rule_id uuid,
  visibility_effect text NOT NULL DEFAULT 'INTERNAL_ONLY',
  cross_company_visibility_allowed boolean NOT NULL DEFAULT false,

  is_partner boolean NOT NULL DEFAULT false,
  is_customer boolean NOT NULL DEFAULT false,
  is_vendor boolean NOT NULL DEFAULT false,

  credit_limit numeric(18,2),
  payment_term_days integer,
  currency_code text NOT NULL DEFAULT 'TRY',

  effective_from date NOT NULL DEFAULT current_date,
  effective_to date,
  status text NOT NULL DEFAULT 'ACTIVE',

  approval_ref text,
  lifecycle_reason text,
  relation_audit_ref text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  audit_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,
  deleted_at timestamptz
);

ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS tenant_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS legal_entity_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS business_code text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_code text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_type text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_direction text DEFAULT 'OUTBOUND';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_channel text DEFAULT 'DIRECT';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS counterparty_entity_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS counterparty_external_ref text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS counterparty_name text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS visibility_rule_id uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS visibility_effect text DEFAULT 'INTERNAL_ONLY';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS cross_company_visibility_allowed boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS is_partner boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS is_customer boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS is_vendor boolean DEFAULT false;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS credit_limit numeric(18,2);
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS payment_term_days integer;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS currency_code text DEFAULT 'TRY';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS effective_from date DEFAULT current_date;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS effective_to date;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS status text DEFAULT 'ACTIVE';
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS approval_ref text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS lifecycle_reason text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS relation_audit_ref text;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS audit_metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS created_by uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS updated_by uuid;
ALTER TABLE org.cross_company_relations ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE org.cross_company_relations SET id=gen_random_uuid() WHERE id IS NULL;
UPDATE org.cross_company_relations SET business_code='CCR_' || upper(substr(replace(id::text,'-',''),1,12)) WHERE business_code IS NULL OR btrim(business_code::text)='';
UPDATE org.cross_company_relations SET relation_code=business_code WHERE relation_code IS NULL OR btrim(relation_code::text)='';
UPDATE org.cross_company_relations SET relation_type='PARTNER' WHERE relation_type IS NULL OR btrim(relation_type::text)='';
UPDATE org.cross_company_relations SET relation_direction='OUTBOUND' WHERE relation_direction IS NULL OR btrim(relation_direction::text)='';
UPDATE org.cross_company_relations SET relation_channel='DIRECT' WHERE relation_channel IS NULL OR btrim(relation_channel::text)='';
UPDATE org.cross_company_relations SET counterparty_name=COALESCE(counterparty_name, counterparty_external_ref, 'UNKNOWN_COUNTERPARTY') WHERE counterparty_name IS NULL OR btrim(counterparty_name::text)='';
UPDATE org.cross_company_relations SET visibility_effect='INTERNAL_ONLY' WHERE visibility_effect IS NULL OR btrim(visibility_effect::text)='';
UPDATE org.cross_company_relations SET cross_company_visibility_allowed=false WHERE cross_company_visibility_allowed IS NULL;
UPDATE org.cross_company_relations SET is_partner=false WHERE is_partner IS NULL;
UPDATE org.cross_company_relations SET is_customer=false WHERE is_customer IS NULL;
UPDATE org.cross_company_relations SET is_vendor=false WHERE is_vendor IS NULL;
UPDATE org.cross_company_relations SET currency_code='TRY' WHERE currency_code IS NULL OR btrim(currency_code::text)='';
UPDATE org.cross_company_relations SET effective_from=current_date WHERE effective_from IS NULL;
UPDATE org.cross_company_relations SET status='ACTIVE' WHERE status IS NULL OR btrim(status::text)='';
UPDATE org.cross_company_relations SET metadata='{}'::jsonb WHERE metadata IS NULL;
UPDATE org.cross_company_relations SET audit_metadata='{}'::jsonb WHERE audit_metadata IS NULL;
UPDATE org.cross_company_relations SET created_at=now() WHERE created_at IS NULL;
UPDATE org.cross_company_relations SET updated_at=now() WHERE updated_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='org'
      AND table_name='cross_company_relations'
      AND constraint_type='PRIMARY KEY'
  ) THEN
    ALTER TABLE org.cross_company_relations ADD CONSTRAINT pk_org_cross_company_relations PRIMARY KEY (id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_id_tenant_id_fk
  ON org.cross_company_relations(id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_tenant_business_code
  ON org.cross_company_relations(tenant_id, business_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_tenant_relation_code
  ON org.cross_company_relations(tenant_id, relation_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_internal_active
  ON org.cross_company_relations(tenant_id, legal_entity_id, counterparty_entity_id, relation_type)
  WHERE deleted_at IS NULL
    AND status='ACTIVE'
    AND counterparty_entity_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_org_cross_company_relations_external_active
  ON org.cross_company_relations(tenant_id, legal_entity_id, counterparty_external_ref, relation_type)
  WHERE deleted_at IS NULL
    AND status='ACTIVE'
    AND counterparty_external_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_tenant_id ON org.cross_company_relations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_legal_entity_id ON org.cross_company_relations(legal_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_counterparty_entity_id ON org.cross_company_relations(counterparty_entity_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_counterparty_external_ref ON org.cross_company_relations(counterparty_external_ref);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_relation_type ON org.cross_company_relations(relation_type);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_relation_direction ON org.cross_company_relations(relation_direction);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_visibility_rule_id ON org.cross_company_relations(visibility_rule_id);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_visibility_effect ON org.cross_company_relations(visibility_effect);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_partner_flag ON org.cross_company_relations(is_partner);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_customer_flag ON org.cross_company_relations(is_customer);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_vendor_flag ON org.cross_company_relations(is_vendor);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_status ON org.cross_company_relations(status);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_effective_dates ON org.cross_company_relations(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_org_cross_company_relations_audit_ref ON org.cross_company_relations(relation_audit_ref);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_cross_company_relations_legal_entity_tenant'
      AND conrelid='org.cross_company_relations'::regclass
  ) THEN
    ALTER TABLE org.cross_company_relations
      ADD CONSTRAINT fk_org_cross_company_relations_legal_entity_tenant
      FOREIGN KEY (legal_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_cross_company_relations_counterparty_entity_tenant'
      AND conrelid='org.cross_company_relations'::regclass
  ) THEN
    ALTER TABLE org.cross_company_relations
      ADD CONSTRAINT fk_org_cross_company_relations_counterparty_entity_tenant
      FOREIGN KEY (counterparty_entity_id, tenant_id)
      REFERENCES org.legal_entities(id, tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='fk_org_cross_company_relations_visibility_rule_tenant'
      AND conrelid='org.cross_company_relations'::regclass
  ) THEN
    ALTER TABLE org.cross_company_relations
      ADD CONSTRAINT fk_org_cross_company_relations_visibility_rule_tenant
      FOREIGN KEY (visibility_rule_id, tenant_id)
      REFERENCES org.visibility_rules(id, tenant_id)
      NOT VALID;
  END IF;
END $$;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_required_fields;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_required_fields
  CHECK (
    tenant_id IS NOT NULL
    AND legal_entity_id IS NOT NULL
    AND business_code IS NOT NULL AND btrim(business_code::text) <> ''
    AND relation_code IS NOT NULL AND btrim(relation_code::text) <> ''
    AND relation_type IS NOT NULL AND btrim(relation_type::text) <> ''
    AND relation_direction IS NOT NULL AND btrim(relation_direction::text) <> ''
    AND relation_channel IS NOT NULL AND btrim(relation_channel::text) <> ''
    AND counterparty_name IS NOT NULL AND btrim(counterparty_name::text) <> ''
    AND visibility_effect IS NOT NULL AND btrim(visibility_effect::text) <> ''
    AND currency_code IS NOT NULL AND btrim(currency_code::text) <> ''
    AND effective_from IS NOT NULL
    AND status IS NOT NULL AND btrim(status::text) <> ''
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_counterparty_required;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_counterparty_required
  CHECK (
    counterparty_entity_id IS NOT NULL
    OR (
      counterparty_external_ref IS NOT NULL
      AND btrim(counterparty_external_ref::text) <> ''
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_no_self_relation;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_no_self_relation
  CHECK (
    counterparty_entity_id IS NULL
    OR counterparty_entity_id <> legal_entity_id
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_relation_type;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_relation_type
  CHECK (
    relation_type IN (
      'PARTNER',
      'CUSTOMER',
      'VENDOR',
      'CUSTOMER_VENDOR',
      'STRATEGIC_PARTNER',
      'ACCOUNTANT_CLIENT',
      'OTHER'
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_relation_direction;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_relation_direction
  CHECK (
    relation_direction IN ('OUTBOUND','INBOUND','BIDIRECTIONAL')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_relation_channel;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_relation_channel
  CHECK (
    relation_channel IN ('DIRECT','MARKETPLACE','FRANCHISE','ACCOUNTANT_PORTAL','INTEGRATION','OTHER')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_flags_match_type;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_flags_match_type
  CHECK (
    (relation_type='PARTNER' AND is_partner=true)
    OR (relation_type='STRATEGIC_PARTNER' AND is_partner=true)
    OR (relation_type='CUSTOMER' AND is_customer=true)
    OR (relation_type='VENDOR' AND is_vendor=true)
    OR (relation_type='CUSTOMER_VENDOR' AND is_customer=true AND is_vendor=true)
    OR (relation_type='ACCOUNTANT_CLIENT')
    OR (relation_type='OTHER')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_visibility_effect;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_visibility_effect
  CHECK (
    visibility_effect IN (
      'INTERNAL_ONLY',
      'COUNTERPARTY_VISIBLE',
      'ACCOUNTANT_VISIBLE',
      'CROSS_COMPANY_VISIBLE',
      'NO_VISIBILITY'
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_cross_company_visibility;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_cross_company_visibility
  CHECK (
    visibility_effect <> 'CROSS_COMPANY_VISIBLE'
    OR (
      cross_company_visibility_allowed=true
      AND (
        visibility_rule_id IS NOT NULL
        OR (
          approval_ref IS NOT NULL
          AND btrim(approval_ref::text) <> ''
        )
      )
    )
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_accountant_visibility;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_accountant_visibility
  CHECK (
    relation_type <> 'ACCOUNTANT_CLIENT'
    OR visibility_effect IN ('ACCOUNTANT_VISIBLE','CROSS_COMPANY_VISIBLE')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_money_terms;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_money_terms
  CHECK (
    (credit_limit IS NULL OR credit_limit >= 0)
    AND (payment_term_days IS NULL OR payment_term_days >= 0)
    AND currency_code ~ '^[A-Z]{3}$'
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_effective_dates;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_effective_dates
  CHECK (effective_to IS NULL OR effective_to >= effective_from) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_status;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_status
  CHECK (
    status IN ('DRAFT','ACTIVE','INACTIVE','SUSPENDED','TERMINATED','ARCHIVED')
  ) NOT VALID;

ALTER TABLE org.cross_company_relations DROP CONSTRAINT IF EXISTS ck_org_cross_company_relations_termination_audit;
ALTER TABLE org.cross_company_relations
  ADD CONSTRAINT ck_org_cross_company_relations_termination_audit
  CHECK (
    status NOT IN ('TERMINATED','ARCHIVED')
    OR (
      lifecycle_reason IS NOT NULL
      AND btrim(lifecycle_reason::text) <> ''
      AND relation_audit_ref IS NOT NULL
      AND btrim(relation_audit_ref::text) <> ''
    )
  ) NOT VALID;

DROP TRIGGER IF EXISTS trg_org_cross_company_relations_set_updated_at ON org.cross_company_relations;
CREATE TRIGGER trg_org_cross_company_relations_set_updated_at
BEFORE UPDATE ON org.cross_company_relations
FOR EACH ROW
EXECUTE FUNCTION org.set_updated_at();

ALTER TABLE org.cross_company_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE org.cross_company_relations FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allow_org_cross_company_relations_tenant_rw ON org.cross_company_relations;
CREATE POLICY allow_org_cross_company_relations_tenant_rw
ON org.cross_company_relations
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
      'cross_company_relations',
      'organization_partner_relation',
      'RELATION_TABLE',
      'ACTIVE',
      true,
      true,
      false,
      true,
      (
        SELECT count(*)::int
        FROM information_schema.columns c
        WHERE c.table_schema='org'
          AND c.table_name='cross_company_relations'
      ),
      jsonb_build_object(
        'phase','FAZ_1_3_7',
        'source','partner_customer_vendor_cross_company_relations',
        'relation_types', jsonb_build_array('PARTNER','CUSTOMER','VENDOR','CUSTOMER_VENDOR','ACCOUNTANT_CLIENT')
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
GRANT SELECT, INSERT, UPDATE ON org.cross_company_relations TO PUBLIC;
GRANT EXECUTE ON FUNCTION org.set_updated_at() TO PUBLIC;

COMMIT;
SQL

pass "8.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. partner/customer/vendor cross-company relation migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 migration başarıyla uygulandı"
else
  fail "9.1 migration uygulanamadı"
  exit 1
fi

echo "10. cross-company relation lifecycle / abuse SQL suite hazırlanıyor..."

cat <<SQL > "$RELATION_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_company_entity_id uuid := gen_random_uuid();
  v_partner_entity_id uuid := gen_random_uuid();
  v_accountant_entity_id uuid := gen_random_uuid();
  v_visibility_rule_id uuid := gen_random_uuid();
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
    'CCR_COMPANY_' || v_suffix,
    'PIX2PI CCR COMPANY TEST A.S.',
    'PIX2PI CCR COMPANY',
    '971' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120007001',
    'ccr-company-' || lower(v_suffix) || '@pix2pi.local',
    'CCR COMPANY TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_7_company_entity')
  ),
  (
    v_partner_entity_id, v_tenant_id, v_partner_entity_id,
    'CCR_PARTNER_' || v_suffix,
    'PIX2PI CCR PARTNER TEST A.S.',
    'PIX2PI CCR PARTNER',
    '972' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120007002',
    'ccr-partner-' || lower(v_suffix) || '@pix2pi.local',
    'CCR PARTNER TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_7_partner_entity')
  ),
  (
    v_accountant_entity_id, v_tenant_id, v_accountant_entity_id,
    'CCR_ACCOUNTANT_' || v_suffix,
    'PIX2PI CCR ACCOUNTANT TEST A.S.',
    'PIX2PI CCR ACCOUNTANT',
    '973' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120007003',
    'ccr-accountant-' || lower(v_suffix) || '@pix2pi.local',
    'CCR ACCOUNTANT TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_7_accountant_entity')
  );

  INSERT INTO org.visibility_rules (
    id,
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
    v_visibility_rule_id,
    v_tenant_id,
    v_company_entity_id,
    'CCR_VIS_RULE_' || v_suffix,
    'CCR-VIS-' || v_suffix,
    'ROLE',
    'TENANT_ADMIN',
    'ENTITY',
    'NO_BRANCH',
    v_partner_entity_id,
    'READ_ONLY',
    'READ',
    true,
    false,
    false,
    false,
    true,
    current_date,
    'ACTIVE',
    'CCR_VIS_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_7_visibility_rule')
  );

  INSERT INTO org.cross_company_relations (
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
    credit_limit,
    payment_term_days,
    currency_code,
    effective_from,
    status,
    approval_ref,
    relation_audit_ref,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_company_entity_id,
    'CCR_PARTNER_REL_' || v_suffix,
    'CCR-PARTNER-' || v_suffix,
    'PARTNER',
    'BIDIRECTIONAL',
    'DIRECT',
    v_partner_entity_id,
    'PIX2PI CCR PARTNER TEST A.S.',
    v_visibility_rule_id,
    'CROSS_COMPANY_VISIBLE',
    true,
    true,
    false,
    false,
    100000.00,
    30,
    'TRY',
    current_date,
    'ACTIVE',
    'APPROVAL_CCR_PARTNER_' || v_suffix,
    'CCR_AUDIT_PARTNER_' || v_suffix,
    jsonb_build_object('test','partner_relation')
  );

  INSERT INTO org.cross_company_relations (
    tenant_id,
    legal_entity_id,
    business_code,
    relation_code,
    relation_type,
    relation_direction,
    relation_channel,
    counterparty_external_ref,
    counterparty_name,
    visibility_effect,
    cross_company_visibility_allowed,
    is_partner,
    is_customer,
    is_vendor,
    credit_limit,
    payment_term_days,
    currency_code,
    effective_from,
    status,
    relation_audit_ref,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_company_entity_id,
    'CCR_CUSTOMER_REL_' || v_suffix,
    'CCR-CUSTOMER-' || v_suffix,
    'CUSTOMER',
    'OUTBOUND',
    'DIRECT',
    'EXT-CUSTOMER-' || v_suffix,
    'EXTERNAL CUSTOMER ' || v_suffix,
    'INTERNAL_ONLY',
    false,
    false,
    true,
    false,
    50000.00,
    15,
    'TRY',
    current_date,
    'ACTIVE',
    'CCR_AUDIT_CUSTOMER_' || v_suffix,
    jsonb_build_object('test','customer_relation')
  );

  INSERT INTO org.cross_company_relations (
    tenant_id,
    legal_entity_id,
    business_code,
    relation_code,
    relation_type,
    relation_direction,
    relation_channel,
    counterparty_external_ref,
    counterparty_name,
    visibility_effect,
    cross_company_visibility_allowed,
    is_partner,
    is_customer,
    is_vendor,
    payment_term_days,
    currency_code,
    effective_from,
    status,
    relation_audit_ref,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_company_entity_id,
    'CCR_VENDOR_REL_' || v_suffix,
    'CCR-VENDOR-' || v_suffix,
    'VENDOR',
    'INBOUND',
    'INTEGRATION',
    'EXT-VENDOR-' || v_suffix,
    'EXTERNAL VENDOR ' || v_suffix,
    'INTERNAL_ONLY',
    false,
    false,
    false,
    true,
    45,
    'TRY',
    current_date,
    'ACTIVE',
    'CCR_AUDIT_VENDOR_' || v_suffix,
    jsonb_build_object('test','vendor_relation')
  );

  INSERT INTO org.cross_company_relations (
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
    v_tenant_id,
    v_company_entity_id,
    'CCR_ACCOUNTANT_REL_' || v_suffix,
    'CCR-ACCOUNTANT-' || v_suffix,
    'ACCOUNTANT_CLIENT',
    'BIDIRECTIONAL',
    'ACCOUNTANT_PORTAL',
    v_accountant_entity_id,
    'PIX2PI CCR ACCOUNTANT TEST A.S.',
    v_visibility_rule_id,
    'ACCOUNTANT_VISIBLE',
    true,
    false,
    false,
    false,
    'TRY',
    current_date,
    'ACTIVE',
    'APPROVAL_CCR_ACCOUNTANT_' || v_suffix,
    'CCR_AUDIT_ACCOUNTANT_' || v_suffix,
    jsonb_build_object('test','accountant_client_relation')
  );

  SELECT count(*)
  INTO v_count
  FROM org.cross_company_relations
  WHERE tenant_id=v_tenant_id
    AND legal_entity_id=v_company_entity_id
    AND status='ACTIVE';

  IF v_count <> 4 THEN
    RAISE EXCEPTION 'cross-company relation valid insert/read failed, count %', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.cross_company_relations
  WHERE tenant_id=v_tenant_id
    AND relation_type='PARTNER'
    AND is_partner=true
    AND visibility_effect='CROSS_COMPANY_VISIBLE'
    AND cross_company_visibility_allowed=true
    AND visibility_rule_id=v_visibility_rule_id;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'partner cross-company visibility relation was not persisted correctly';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.cross_company_relations
  WHERE tenant_id=v_tenant_id
    AND relation_type='CUSTOMER'
    AND is_customer=true
    AND is_vendor=false;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'customer relation was not persisted correctly';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.cross_company_relations
  WHERE tenant_id=v_tenant_id
    AND relation_type='VENDOR'
    AND is_vendor=true
    AND is_customer=false;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'vendor relation was not persisted correctly';
  END IF;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_entity_id, counterparty_name,
      visibility_effect, is_partner, is_customer, is_vendor,
      currency_code, effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_BAD_SELF_' || v_suffix,
      'CCR-BAD-SELF-' || v_suffix,
      'PARTNER', 'BIDIRECTIONAL', 'DIRECT',
      v_company_entity_id, 'SELF RELATION',
      'INTERNAL_ONLY', true, false, false,
      'TRY', current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'self relation was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_name,
      visibility_effect, is_partner, is_customer, is_vendor,
      currency_code, effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_BAD_NO_COUNTERPARTY_' || v_suffix,
      'CCR-BAD-NO-COUNTERPARTY-' || v_suffix,
      'CUSTOMER', 'OUTBOUND', 'DIRECT',
      'NO COUNTERPARTY',
      'INTERNAL_ONLY', false, true, false,
      'TRY', current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'missing counterparty was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_external_ref, counterparty_name,
      visibility_effect, is_partner, is_customer, is_vendor,
      currency_code, effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_BAD_CUSTOMER_FLAG_' || v_suffix,
      'CCR-BAD-CUSTOMER-FLAG-' || v_suffix,
      'CUSTOMER', 'OUTBOUND', 'DIRECT',
      'EXT-BAD-CUSTOMER-' || v_suffix, 'BAD CUSTOMER FLAG',
      'INTERNAL_ONLY', false, false, false,
      'TRY', current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'CUSTOMER relation without is_customer=true was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_external_ref, counterparty_name,
      visibility_effect, cross_company_visibility_allowed,
      is_partner, is_customer, is_vendor,
      currency_code, effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_BAD_VISIBILITY_' || v_suffix,
      'CCR-BAD-VISIBILITY-' || v_suffix,
      'PARTNER', 'BIDIRECTIONAL', 'DIRECT',
      'EXT-BAD-VIS-' || v_suffix, 'BAD VISIBILITY',
      'CROSS_COMPANY_VISIBLE', false,
      true, false, false,
      'TRY', current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'cross-company visibility without allowed/rule/approval was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_external_ref, counterparty_name,
      visibility_effect,
      is_partner, is_customer, is_vendor,
      currency_code, effective_from, effective_to, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_BAD_DATE_' || v_suffix,
      'CCR-BAD-DATE-' || v_suffix,
      'VENDOR', 'INBOUND', 'DIRECT',
      'EXT-BAD-DATE-' || v_suffix, 'BAD DATE',
      'INTERNAL_ONLY',
      false, false, true,
      'TRY', current_date + 10, current_date + 9, 'ACTIVE'
    );

    RAISE EXCEPTION 'bad effective date range was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_external_ref, counterparty_name,
      visibility_effect,
      is_partner, is_customer, is_vendor,
      credit_limit, currency_code, effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_BAD_MONEY_' || v_suffix,
      'CCR-BAD-MONEY-' || v_suffix,
      'CUSTOMER', 'OUTBOUND', 'DIRECT',
      'EXT-BAD-MONEY-' || v_suffix, 'BAD MONEY',
      'INTERNAL_ONLY',
      false, true, false,
      -1, 'TRY', current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'negative credit limit was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.cross_company_relations (
      tenant_id, legal_entity_id, business_code, relation_code,
      relation_type, relation_direction, relation_channel,
      counterparty_external_ref, counterparty_name,
      visibility_effect,
      is_partner, is_customer, is_vendor,
      currency_code, effective_from, status
    )
    VALUES (
      v_tenant_id, v_company_entity_id,
      'CCR_DUP_CUSTOMER_' || v_suffix,
      'CCR-DUP-CUSTOMER-' || v_suffix,
      'CUSTOMER', 'OUTBOUND', 'DIRECT',
      'EXT-CUSTOMER-' || v_suffix,
      'EXTERNAL CUSTOMER DUP ' || v_suffix,
      'INTERNAL_ONLY',
      false, true, false,
      'TRY', current_date, 'ACTIVE'
    );

    RAISE EXCEPTION 'duplicate customer relation was not blocked';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "10.1 relation SQL suite dosyası yazıldı: $RELATION_TEST_SQL / OK ✅"

echo "11. cross-company relation lifecycle / abuse SQL suite çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$RELATION_TEST_SQL" > "$RELATION_TEST_OUT" 2>&1; then
  pass "11.1 cross-company relation lifecycle / abuse SQL suite geçti"
else
  fail "11.1 cross-company relation lifecycle / abuse SQL suite başarısız"
  cat "$RELATION_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$RELATION_TEST_OUT"; then
  pass "11.2 cross-company relation test rollback ile temizlendi"
  RELATION_TEST_STATUS="PASS"
else
  fail "11.2 cross-company relation rollback kanıtı yok"
  RELATION_TEST_STATUS="FAIL"
fi

echo "12. cross-company relation model sayaçları alınıyor..."

RELATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='cross_company_relations';")"

RELATION_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='cross_company_relations'
    and column_name in (
      'id','tenant_id','legal_entity_id',
      'business_code','relation_code',
      'relation_type','relation_direction','relation_channel',
      'counterparty_entity_id','counterparty_external_ref','counterparty_name',
      'visibility_rule_id','visibility_effect','cross_company_visibility_allowed',
      'is_partner','is_customer','is_vendor',
      'credit_limit','payment_term_days','currency_code',
      'effective_from','effective_to','status',
      'approval_ref','lifecycle_reason','relation_audit_ref',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

RELATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and contype='f';")"
RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and contype='c';")"
RELATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='cross_company_relations';")"
RELATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='cross_company_relations' and c.relrowsecurity=true;")"
RELATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='cross_company_relations' and c.relforcerowsecurity=true;")"
RELATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='cross_company_relations';")"
RELATION_UPDATED_AT_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_cross_company_relations_set_updated_at' and tgrelid='org.cross_company_relations'::regclass and not tgisinternal;")"
RELATION_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='cross_company_relations' and column_name in ('approval_ref','lifecycle_reason','relation_audit_ref','audit_metadata');")"
RELATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='cross_company_relations';")"

PARTNER_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_flags_match_type';")"
CUSTOMER_VENDOR_RULE_CHECK_COUNT="$PARTNER_RULE_CHECK_COUNT"
CROSS_COMPANY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_cross_company_visibility';")"
RELATION_AUDIT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_termination_audit';")"
COUNTERPARTY_REQUIRED_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_counterparty_required';")"
NO_SELF_RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_no_self_relation';")"
VISIBILITY_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"

echo "RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
echo "RELATION_COLUMN_COUNT=$RELATION_COLUMN_COUNT"
echo "RELATION_FK_COUNT=$RELATION_FK_COUNT"
echo "RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
echo "RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
echo "RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
echo "RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
echo "RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
echo "RELATION_UPDATED_AT_TRIGGER_COUNT=$RELATION_UPDATED_AT_TRIGGER_COUNT"
echo "RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
echo "RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
echo "PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
echo "CUSTOMER_VENDOR_RULE_CHECK_COUNT=$CUSTOMER_VENDOR_RULE_CHECK_COUNT"
echo "CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
echo "COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
echo "NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
echo "VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"
echo "RELATION_TEST_STATUS=$RELATION_TEST_STATUS"

[ "$RELATION_TABLE_COUNT" -eq 1 ] && pass "12.1 cross_company_relations tablosu hazır" || fail "12.1 cross_company_relations tablosu eksik"
[ "$RELATION_COLUMN_COUNT" -ge 33 ] && pass "12.2 cross_company_relations kolon kapsamı tam" || fail "12.2 cross_company_relations kolon kapsamı eksik"
[ "$RELATION_FK_COUNT" -ge 3 ] && pass "12.3 cross_company_relations FK seti hazır" || fail "12.3 cross_company_relations FK seti eksik"
[ "$RELATION_CHECK_COUNT" -ge 12 ] && pass "12.4 cross_company_relations check constraint seti hazır" || fail "12.4 cross_company_relations check seti eksik"
[ "$RELATION_INDEX_COUNT" -ge 14 ] && pass "12.5 cross_company_relations index seti hazır" || fail "12.5 cross_company_relations index seti eksik"
[ "$RELATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.6 cross_company_relations RLS enabled" || fail "12.6 cross_company_relations RLS enabled eksik"
[ "$RELATION_RLS_FORCED_COUNT" -eq 1 ] && pass "12.7 cross_company_relations RLS forced" || fail "12.7 cross_company_relations RLS forced eksik"
[ "$RELATION_POLICY_COUNT" -ge 1 ] && pass "12.8 cross_company_relations tenant policy hazır" || fail "12.8 cross_company_relations tenant policy eksik"
[ "$RELATION_UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "12.9 cross_company_relations updated_at trigger hazır" || fail "12.9 cross_company_relations updated_at trigger eksik"
[ "$RELATION_AUDIT_COLUMN_COUNT" -eq 4 ] && pass "12.10 relation audit kolonları hazır" || fail "12.10 relation audit kolonları eksik"
[ "$RELATION_DICTIONARY_COUNT" -ge 1 ] && pass "12.11 relation data dictionary kaydı mevcut" || warn "12.11 relation data dictionary kaydı eksik"
[ "$PARTNER_RULE_CHECK_COUNT" -eq 1 ] && pass "12.12 partner/customer/vendor flag rule hazır" || fail "12.12 partner/customer/vendor flag rule eksik"
[ "$CUSTOMER_VENDOR_RULE_CHECK_COUNT" -eq 1 ] && pass "12.13 customer/vendor relation rule hazır" || fail "12.13 customer/vendor relation rule eksik"
[ "$CROSS_COMPANY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "12.14 cross-company visibility rule hazır" || fail "12.14 cross-company visibility rule eksik"
[ "$RELATION_AUDIT_CHECK_COUNT" -eq 1 ] && pass "12.15 relation audit termination rule hazır" || fail "12.15 relation audit termination rule eksik"
[ "$COUNTERPARTY_REQUIRED_CHECK_COUNT" -eq 1 ] && pass "12.16 counterparty required rule hazır" || fail "12.16 counterparty required rule eksik"
[ "$NO_SELF_RELATION_CHECK_COUNT" -eq 1 ] && pass "12.17 self-relation prevention hazır" || fail "12.17 self-relation prevention eksik"
[ "$VISIBILITY_DEPENDENCY_COUNT" -eq 1 ] && pass "12.18 visibility rule dependency hazır" || fail "12.18 visibility rule dependency eksik"
[ "$RELATION_TEST_STATUS" = "PASS" ] && pass "12.19 cross-company relation lifecycle / abuse suite PASS" || fail "12.19 cross-company relation lifecycle / abuse suite FAIL"

echo "13. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_7_partner_customer_vendor_cross_company_relations_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_7_PARTNER_CUSTOMER_VENDOR_CROSS_COMPANY_RELATIONS_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS STRICT SUITE START ====="

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

RELATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='cross_company_relations';")"
RELATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and contype='f';")"
RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and contype='c';")"
RELATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='cross_company_relations';")"
RELATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='cross_company_relations' and c.relrowsecurity=true;")"
RELATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='cross_company_relations' and c.relforcerowsecurity=true;")"
RELATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='cross_company_relations';")"
RELATION_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='cross_company_relations' and column_name in ('approval_ref','lifecycle_reason','relation_audit_ref','audit_metadata');")"
RELATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='cross_company_relations';")"

PARTNER_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_flags_match_type';")"
CROSS_COMPANY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_cross_company_visibility';")"
RELATION_AUDIT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_termination_audit';")"
COUNTERPARTY_REQUIRED_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_counterparty_required';")"
NO_SELF_RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_no_self_relation';")"
VISIBILITY_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"

echo "RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
echo "RELATION_FK_COUNT=$RELATION_FK_COUNT"
echo "RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
echo "RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
echo "RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
echo "RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
echo "RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
echo "RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
echo "RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
echo "PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
echo "CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
echo "COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
echo "NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
echo "VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"

[ "$RELATION_TABLE_COUNT" -eq 1 ] && pass "5.1 cross_company_relations tablosu hazır" || fail "5.1 cross_company_relations tablosu eksik"
[ "$RELATION_FK_COUNT" -ge 3 ] && pass "5.2 relation FK seti hazır" || fail "5.2 relation FK seti eksik"
[ "$RELATION_CHECK_COUNT" -ge 12 ] && pass "5.3 relation check seti hazır" || fail "5.3 relation check seti eksik"
[ "$RELATION_INDEX_COUNT" -ge 14 ] && pass "5.4 relation index seti hazır" || fail "5.4 relation index seti eksik"
[ "$RELATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 relation RLS enabled" || fail "5.5 relation RLS enabled eksik"
[ "$RELATION_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 relation RLS forced" || fail "5.6 relation RLS forced eksik"
[ "$RELATION_POLICY_COUNT" -ge 1 ] && pass "5.7 relation tenant policy hazır" || fail "5.7 relation tenant policy eksik"
[ "$RELATION_AUDIT_COLUMN_COUNT" -eq 4 ] && pass "5.8 relation audit kolonları hazır" || fail "5.8 relation audit kolonları eksik"
[ "$RELATION_DICTIONARY_COUNT" -ge 1 ] && pass "5.9 relation data dictionary mevcut" || warn "5.9 relation data dictionary eksik"
[ "$PARTNER_RULE_CHECK_COUNT" -eq 1 ] && pass "5.10 partner/customer/vendor rule hazır" || fail "5.10 partner/customer/vendor rule eksik"
[ "$CROSS_COMPANY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.11 cross-company visibility rule hazır" || fail "5.11 cross-company visibility rule eksik"
[ "$RELATION_AUDIT_CHECK_COUNT" -eq 1 ] && pass "5.12 relation audit rule hazır" || fail "5.12 relation audit rule eksik"
[ "$COUNTERPARTY_REQUIRED_CHECK_COUNT" -eq 1 ] && pass "5.13 counterparty required rule hazır" || fail "5.13 counterparty required rule eksik"
[ "$NO_SELF_RELATION_CHECK_COUNT" -eq 1 ] && pass "5.14 self-relation prevention hazır" || fail "5.14 self-relation prevention eksik"
[ "$VISIBILITY_DEPENDENCY_COUNT" -eq 1 ] && pass "5.15 visibility dependency hazır" || fail "5.15 visibility dependency eksik"

{
  echo "# FAZ 1-3.7 Partner / Customer / Vendor Cross-company Relations Strict Suite Result"
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

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
echo "RELATION_FK_COUNT=$RELATION_FK_COUNT"
echo "RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
echo "RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
echo "RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
echo "RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
echo "RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
echo "RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
echo "RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
echo "PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
echo "CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
echo "COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
echo "NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
echo "VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_7_PARTNER_RELATION_STATUS=PASS"
  echo "FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS=PASS"
  echo "FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_TEST_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_7_RELATION_TEST_STATUS=FAIL"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_7_RELATION_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_7_RELATION_SEAL_STATUS")"

PARTNER_RELATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_7_PARTNER_RELATION_STATUS")"
CUSTOMER_VENDOR_RELATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS")"
CROSS_COMPANY_VISIBILITY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS")"
RELATION_AUDIT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_7_RELATION_AUDIT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "15. strict suite FAIL_COUNT=0 doğrulandı" || fail "15. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "16. strict suite status PASS doğrulandı" || fail "16. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "17. strict suite seal SEALED doğrulandı" || fail "17. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "18. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.7 — Partner / Customer / Vendor Cross-company Relation Modeli

## Kapsam

- Partner relation
- Customer/vendor relation
- Cross-company visibility
- Relation audit
- Tests

## Uygulama

Bu adım org.cross_company_relations tablosunu kurar.

Desteklenen relation_type:
- PARTNER
- CUSTOMER
- VENDOR
- CUSTOMER_VENDOR
- STRATEGIC_PARTNER
- ACCOUNTANT_CLIENT
- OTHER

Ana guard'lar:
- counterparty_entity_id veya counterparty_external_ref zorunlu
- self-relation engellenir
- CUSTOMER için is_customer=true zorunlu
- VENDOR için is_vendor=true zorunlu
- PARTNER/STRATEGIC_PARTNER için is_partner=true zorunlu
- CUSTOMER_VENDOR için is_customer=true ve is_vendor=true zorunlu
- CROSS_COMPANY_VISIBLE için cross_company_visibility_allowed=true ve visibility_rule_id veya approval_ref zorunlu
- TERMINATED/ARCHIVED için lifecycle_reason ve relation_audit_ref zorunlu

## Final Status

- FAZ_1_3_7_PARTNER_RELATION_STATUS=${PARTNER_RELATION_STATUS:-N/A}
- FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS=${CUSTOMER_VENDOR_RELATION_STATUS:-N/A}
- FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS=${CROSS_COMPANY_VISIBILITY_STATUS:-N/A}
- FAZ_1_3_7_RELATION_AUDIT_STATUS=${RELATION_AUDIT_STATUS:-N/A}
- FAZ_1_3_7_RELATION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_7_RELATION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.7 Partner / Customer / Vendor Cross-company Relations Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Relation SQL: $RELATION_TEST_SQL"
  echo "- Relation output: $RELATION_TEST_OUT"
  echo
  echo "## Counts"
  echo "- RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
  echo "- RELATION_COLUMN_COUNT=$RELATION_COLUMN_COUNT"
  echo "- RELATION_FK_COUNT=$RELATION_FK_COUNT"
  echo "- RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
  echo "- RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
  echo "- RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
  echo "- RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
  echo "- RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
  echo "- RELATION_UPDATED_AT_TRIGGER_COUNT=$RELATION_UPDATED_AT_TRIGGER_COUNT"
  echo "- RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
  echo "- RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
  echo "- PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
  echo "- CUSTOMER_VENDOR_RULE_CHECK_COUNT=$CUSTOMER_VENDOR_RULE_CHECK_COUNT"
  echo "- CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
  echo "- RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
  echo "- COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
  echo "- NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
  echo "- VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"
  echo
  echo "## Tests"
  echo "- RELATION_TEST_STATUS=$RELATION_TEST_STATUS"
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
  echo "# FAZ 1-3.7 Partner / Customer / Vendor Cross-company Relations Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_7_PARTNER_RELATION_STATUS=${PARTNER_RELATION_STATUS:-N/A}"
  echo "FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS=${CUSTOMER_VENDOR_RELATION_STATUS:-N/A}"
  echo "FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS=${CROSS_COMPANY_VISIBILITY_STATUS:-N/A}"
  echo "FAZ_1_3_7_RELATION_AUDIT_STATUS=${RELATION_AUDIT_STATUS:-N/A}"
  echo "FAZ_1_3_7_RELATION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_8_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "18.1 dokümantasyon yazıldı: $DOC_FILE"
pass "18.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "18.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "18.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RELATION_TEST_STATUS=$RELATION_TEST_STATUS"
echo "RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
echo "RELATION_COLUMN_COUNT=$RELATION_COLUMN_COUNT"
echo "RELATION_FK_COUNT=$RELATION_FK_COUNT"
echo "RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
echo "RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
echo "RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
echo "RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
echo "RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
echo "RELATION_UPDATED_AT_TRIGGER_COUNT=$RELATION_UPDATED_AT_TRIGGER_COUNT"
echo "RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
echo "RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
echo "PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
echo "CUSTOMER_VENDOR_RULE_CHECK_COUNT=$CUSTOMER_VENDOR_RULE_CHECK_COUNT"
echo "CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
echo "COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
echo "NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
echo "VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "PARTNER_RELATION_STATUS=${PARTNER_RELATION_STATUS:-N/A}"
echo "CUSTOMER_VENDOR_RELATION_STATUS=${CUSTOMER_VENDOR_RELATION_STATUS:-N/A}"
echo "CROSS_COMPANY_VISIBILITY_STATUS=${CROSS_COMPANY_VISIBILITY_STATUS:-N/A}"
echo "RELATION_AUDIT_STATUS=${RELATION_AUDIT_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$RELATION_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_7_PARTNER_RELATION_STATUS=PASS"
  echo "FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS=PASS"
  echo "FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_FINAL_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_8_READY=YES"
else
  echo "FAZ_1_3_7_RELATION_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_8_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS END ====="
