package auditpersistence

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		PersistenceEnabled:   true,
		AppendOnly:           true,
		IdempotencyRequired:  true,
		EvidenceHashRequired: true,
		RuleVersionRequired:  true,
		ActorRequired:        true,
		RetentionDays:        3650,
		AllowedTaxFamilies: []TaxFamily{
			TaxFamilyKDV,
			TaxFamilyStopaj,
			TaxFamilyTaxExemption,
			TaxFamilyOTV,
			TaxFamilyDamga,
			TaxFamilyCustom,
		},
		AllowedAuditActions: []AuditAction{
			ActionKDVCalculated,
			ActionStopajCalculated,
			ActionExemptionApplied,
			ActionRuleVersionRolled,
			ActionRuleVersionActivated,
			ActionRuleVersionRollback,
			ActionValidationRejected,
			ActionManualReview,
		},
		AllowedSourceRuntimes: []SourceRuntime{
			SourceKDVRuntime,
			SourceStopajRuntime,
			SourceTaxExemptionRuntime,
			SourceRuleRolloutRuntime,
			SourceTaxRuntimeTestSuite,
		},
	}
}

func validKDVRecord() TaxAuditRecord {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return TaxAuditRecord{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-001",
		RequestID:           "req-001",
		IdempotencyKey:      "idem-kdv-001",
		AuditID:             "audit-kdv-001",
		TaxFamily:           TaxFamilyKDV,
		SourceRuntime:       SourceKDVRuntime,
		Action:              ActionKDVCalculated,
		DecisionStatus:      DecisionApplied,
		RuleVersion:         "TR_KDV_2026_V1",
		DocumentType:        "SALES_INVOICE",
		DocumentID:          "invoice-001",
		DocumentNo:          "INV-001",
		PartyID:             "party-001",
		PartyTaxNo:          "1234567890",
		TaxBaseAmountKurus:  1000000,
		TaxAmountKurus:      200000,
		CurrencyCode:        "TRY",
		EvidenceFilePath:    "docs/faz3/evidence/kdv-runtime.md",
		EvidenceHash:        "sha256:evidence-kdv",
		RequestHash:         "sha256:req-kdv",
		ResultHash:          "sha256:res-kdv",
		BeforeSnapshotHash:  "sha256:before-kdv",
		AfterSnapshotHash:   "sha256:after-kdv",
		AuditDecisionReason: "KDV calculated with active rule version",
		ActorID:             "tax-runtime",
		ActorRole:           "SYSTEM",
		CreatedAt:           now,
	}
}

func validStopajRecord() TaxAuditRecord {
	record := validKDVRecord()
	record.IdempotencyKey = "idem-stopaj-001"
	record.AuditID = "audit-stopaj-001"
	record.TaxFamily = TaxFamilyStopaj
	record.SourceRuntime = SourceStopajRuntime
	record.Action = ActionStopajCalculated
	record.RuleVersion = "TR_STOPAJ_2026_V1"
	record.TaxAmountKurus = 0
	record.WithholdingAmountKurus = 200000
	record.EvidenceHash = "sha256:evidence-stopaj"
	record.RequestHash = "sha256:req-stopaj"
	record.ResultHash = "sha256:res-stopaj"
	return record
}

func validRolloutRecord() TaxAuditRecord {
	record := validKDVRecord()
	record.IdempotencyKey = "idem-rollout-001"
	record.AuditID = "audit-rollout-001"
	record.TaxFamily = TaxFamilyKDV
	record.SourceRuntime = SourceRuleRolloutRuntime
	record.Action = ActionRuleVersionActivated
	record.DecisionStatus = DecisionActivated
	record.RuleVersion = "TR_KDV_2026_V2"
	record.PreviousRuleVersion = "TR_KDV_2026_V1"
	record.TargetRuleVersion = "TR_KDV_2026_V2"
	record.DocumentID = ""
	record.DocumentNo = ""
	record.TaxBaseAmountKurus = 0
	record.TaxAmountKurus = 0
	record.EvidenceHash = "sha256:evidence-rollout"
	record.RequestHash = "sha256:req-rollout"
	record.ResultHash = "sha256:res-rollout"
	return record
}

func newRuntime(t *testing.T) *TaxAuditPersistenceRuntime {
	t.Helper()

	runtime, err := NewTaxAuditPersistenceRuntime(validConfig(), NewInMemoryTaxAuditRepository())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	return runtime
}

func TestRecordPersistsAuditRecord(t *testing.T) {
	runtime := newRuntime(t)

	stored, err := runtime.Record(validKDVRecord())
	if err != nil {
		t.Fatalf("record failed: %v", err)
	}

	if stored.AuditID != "audit-kdv-001" {
		t.Fatalf("expected audit-kdv-001, got %s", stored.AuditID)
	}
	if stored.TenantID != "tenant-001" {
		t.Fatalf("expected tenant-001, got %s", stored.TenantID)
	}
}

func TestFindByAuditIDIsTenantScoped(t *testing.T) {
	runtime := newRuntime(t)

	_, err := runtime.Record(validKDVRecord())
	if err != nil {
		t.Fatalf("record failed: %v", err)
	}

	found, ok, err := runtime.FindByAuditID("tenant-001", "audit-kdv-001")
	if err != nil {
		t.Fatalf("find failed: %v", err)
	}
	if !ok {
		t.Fatal("expected audit record to be found")
	}
	if found.AuditID != "audit-kdv-001" {
		t.Fatalf("expected audit-kdv-001, got %s", found.AuditID)
	}

	_, ok, err = runtime.FindByAuditID("tenant-002", "audit-kdv-001")
	if err != nil {
		t.Fatalf("find cross tenant failed: %v", err)
	}
	if ok {
		t.Fatal("expected cross-tenant lookup to be isolated")
	}
}

func TestDuplicateIdempotencyKeyIsRejected(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.Record(validKDVRecord()); err != nil {
		t.Fatalf("record failed: %v", err)
	}

	duplicate := validKDVRecord()
	duplicate.AuditID = "audit-kdv-duplicate"

	_, err := runtime.Record(duplicate)
	if err == nil {
		t.Fatal("expected duplicate idempotency error")
	}
}

func TestAppendOnlyRejectsDuplicateAuditID(t *testing.T) {
	repo := NewInMemoryTaxAuditRepository()
	runtime, err := NewTaxAuditPersistenceRuntime(validConfig(), repo)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	if _, err := runtime.Record(validKDVRecord()); err != nil {
		t.Fatalf("record failed: %v", err)
	}

	duplicate := validKDVRecord()
	duplicate.IdempotencyKey = "idem-kdv-new"

	_, err = runtime.Record(duplicate)
	if err == nil {
		t.Fatal("expected duplicate audit_id error")
	}
}

func TestExportTenantAuditTrailAggregatesKDV(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.Record(validKDVRecord()); err != nil {
		t.Fatalf("record KDV failed: %v", err)
	}
	if _, err := runtime.Record(validStopajRecord()); err != nil {
		t.Fatalf("record Stopaj failed: %v", err)
	}
	if _, err := runtime.Record(validRolloutRecord()); err != nil {
		t.Fatalf("record rollout failed: %v", err)
	}

	from := time.Date(2026, 5, 7, 0, 0, 0, 0, time.UTC)
	to := time.Date(2026, 5, 8, 0, 0, 0, 0, time.UTC)

	export, err := runtime.ExportTenantAuditTrail("tenant-001", "corr-export", "req-export", "export-kdv-001", TaxFamilyKDV, from, to)
	if err != nil {
		t.Fatalf("export failed: %v", err)
	}

	if export.RecordCount != 2 {
		t.Fatalf("expected 2 KDV records, got %d", export.RecordCount)
	}
	if export.TotalTaxBaseAmountKurus != 1000000 {
		t.Fatalf("expected tax base total 1000000, got %d", export.TotalTaxBaseAmountKurus)
	}
	if export.TotalTaxAmountKurus != 200000 {
		t.Fatalf("expected tax amount total 200000, got %d", export.TotalTaxAmountKurus)
	}
	if export.ExportHash == "" {
		t.Fatal("expected export hash")
	}
}

func TestValidationRejectsMissingEvidenceHash(t *testing.T) {
	runtime := newRuntime(t)

	record := validKDVRecord()
	record.EvidenceHash = ""

	_, err := runtime.Record(record)
	if err == nil {
		t.Fatal("expected evidence hash error")
	}
}

func TestValidationRejectsNegativeTaxAmount(t *testing.T) {
	runtime := newRuntime(t)

	record := validKDVRecord()
	record.TaxAmountKurus = -1

	_, err := runtime.Record(record)
	if err == nil {
		t.Fatal("expected negative tax amount error")
	}
}

func TestValidationRejectsMissingActor(t *testing.T) {
	runtime := newRuntime(t)

	record := validKDVRecord()
	record.ActorID = ""

	_, err := runtime.Record(record)
	if err == nil {
		t.Fatal("expected actor error")
	}
}

func TestRuntimeRejectsNonAppendOnlyConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AppendOnly = false

	_, err := NewTaxAuditPersistenceRuntime(cfg, NewInMemoryTaxAuditRepository())
	if err == nil {
		t.Fatal("expected append-only config error")
	}
}

func TestRuntimeRejectsNilRepository(t *testing.T) {
	_, err := NewTaxAuditPersistenceRuntime(validConfig(), nil)
	if err == nil {
		t.Fatal("expected repository required error")
	}
}
