CREATE SCHEMA IF NOT EXISTS merchant_import_export;

CREATE TABLE IF NOT EXISTS merchant_import_export.import_jobs (
  import_job_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  import_type TEXT NOT NULL,
  source_file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  job_status TEXT NOT NULL DEFAULT 'pending',
  row_count INTEGER NOT NULL DEFAULT 0,
  success_count INTEGER NOT NULL DEFAULT 0,
  error_count INTEGER NOT NULL DEFAULT 0,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS merchant_import_export.import_job_rows (
  import_row_id TEXT PRIMARY KEY,
  import_job_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  import_type TEXT NOT NULL,
  row_no INTEGER NOT NULL,
  row_status TEXT NOT NULL,
  target_table TEXT NOT NULL DEFAULT '',
  target_id TEXT NOT NULL DEFAULT '',
  error_message TEXT NOT NULL DEFAULT '',
  raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_import_export.export_jobs (
  export_job_id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  export_type TEXT NOT NULL,
  export_status TEXT NOT NULL DEFAULT 'generated',
  row_count INTEGER NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  created_by_user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS merchant_import_export.export_artifacts (
  artifact_id TEXT PRIMARY KEY,
  export_job_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  artifact_type TEXT NOT NULL CHECK (artifact_type IN ('csv','xlsx')),
  artifact_status TEXT NOT NULL DEFAULT 'placeholder',
  artifact_path TEXT NOT NULL,
  checksum TEXT NOT NULL DEFAULT '',
  row_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_import_export.import_export_audit_events (
  event_id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  actor_user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  decision TEXT NOT NULL,
  correlation_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_import_jobs_tenant_type
  ON merchant_import_export.import_jobs(tenant_id, import_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_import_rows_job
  ON merchant_import_export.import_job_rows(import_job_id, row_status);

CREATE INDEX IF NOT EXISTS idx_export_jobs_tenant_type
  ON merchant_import_export.export_jobs(tenant_id, export_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_export_artifacts_job
  ON merchant_import_export.export_artifacts(export_job_id, artifact_type);

CREATE INDEX IF NOT EXISTS idx_import_export_audit_tenant
  ON merchant_import_export.import_export_audit_events(tenant_id, event_type, decision, created_at DESC);
