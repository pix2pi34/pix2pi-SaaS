package runtimetests

import (
	"testing"

	audit "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/auditpersistence"
	exemption "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/exemption"
	kdv "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/kdv"
	rollout "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/rulerollout"
	withholding "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/withholding"
)

func TestTaxRuntimeSuiteKDVStopajExemptionRolloutAndAuditPersistence(t *testing.T) {
	suite, err := NewTaxRuntimeTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	kdvResult, err := suite.KDVRuntime.Execute(KDVOutputRequest())
	if err != nil {
		t.Fatalf("KDV execute failed: %v", err)
	}
	if kdvResult.DecisionStatus != kdv.DecisionApplied {
		t.Fatalf("expected KDV applied, got %s", kdvResult.DecisionStatus)
	}
	if kdvResult.KDVAmountKurus != 200000 {
		t.Fatalf("expected KDV 200000, got %d", kdvResult.KDVAmountKurus)
	}
	if kdvResult.AccountCode != "391.01.20" {
		t.Fatalf("expected output account 391.01.20, got %s", kdvResult.AccountCode)
	}

	stopajResult, err := suite.StopajRuntime.Execute(StopajRentRequest())
	if err != nil {
		t.Fatalf("Stopaj execute failed: %v", err)
	}
	if stopajResult.DecisionStatus != withholding.DecisionApplied {
		t.Fatalf("expected Stopaj applied, got %s", stopajResult.DecisionStatus)
	}
	if stopajResult.WithholdingAmountKurus != 200000 {
		t.Fatalf("expected withholding 200000, got %d", stopajResult.WithholdingAmountKurus)
	}

	exemptionResult, err := suite.ExemptionRuntime.Execute(KDVFullExemptionRequest())
	if err != nil {
		t.Fatalf("Exemption execute failed: %v", err)
	}
	if exemptionResult.DecisionStatus != exemption.DecisionApplied {
		t.Fatalf("expected exemption applied, got %s", exemptionResult.DecisionStatus)
	}
	if exemptionResult.ExemptedTaxAmountKurus != 200000 {
		t.Fatalf("expected exempted tax 200000, got %d", exemptionResult.ExemptedTaxAmountKurus)
	}

	rolloutResult, err := suite.RolloutRuntime.PrepareRollout(TaxRolloutRequest())
	if err != nil {
		t.Fatalf("tax rollout prepare failed: %v", err)
	}
	if rolloutResult.DecisionStatus != rollout.DecisionReady {
		t.Fatalf("expected rollout ready, got %s", rolloutResult.DecisionStatus)
	}
	if !rolloutResult.RuntimeSwitchReady || !rolloutResult.ConfigSwitchReady || !rolloutResult.AuditReady {
		t.Fatal("expected rollout runtime/config/audit ready")
	}

	if _, err := suite.AuditRuntime.Record(AuditRecordFromKDV(kdvResult)); err != nil {
		t.Fatalf("record KDV audit failed: %v", err)
	}
	if _, err := suite.AuditRuntime.Record(AuditRecordFromStopaj(stopajResult)); err != nil {
		t.Fatalf("record Stopaj audit failed: %v", err)
	}
	if _, err := suite.AuditRuntime.Record(AuditRecordFromExemption(exemptionResult)); err != nil {
		t.Fatalf("record Exemption audit failed: %v", err)
	}
	if _, err := suite.AuditRuntime.Record(AuditRecordFromRollout(rolloutResult)); err != nil {
		t.Fatalf("record Rollout audit failed: %v", err)
	}

	from := suiteTime().AddDate(0, 0, -1)
	to := suiteTime().AddDate(0, 0, 1)

	kdvExport, err := suite.AuditRuntime.ExportTenantAuditTrail("tenant-001", "corr-export-suite", "req-export-suite", "export-kdv-suite", audit.TaxFamilyKDV, from, to)
	if err != nil {
		t.Fatalf("export KDV audit trail failed: %v", err)
	}
	if kdvExport.RecordCount != 2 {
		t.Fatalf("expected 2 KDV-family audit records, got %d", kdvExport.RecordCount)
	}
	if kdvExport.TotalTaxAmountKurus != 200000 {
		t.Fatalf("expected exported KDV tax amount 200000, got %d", kdvExport.TotalTaxAmountKurus)
	}

	stopajExport, err := suite.AuditRuntime.ExportTenantAuditTrail("tenant-001", "corr-export-stopaj-suite", "req-export-stopaj-suite", "export-stopaj-suite", audit.TaxFamilyStopaj, from, to)
	if err != nil {
		t.Fatalf("export Stopaj audit trail failed: %v", err)
	}
	if stopajExport.RecordCount != 1 {
		t.Fatalf("expected 1 Stopaj audit record, got %d", stopajExport.RecordCount)
	}
	if stopajExport.TotalWithholdingAmountKurus != 200000 {
		t.Fatalf("expected exported withholding 200000, got %d", stopajExport.TotalWithholdingAmountKurus)
	}
}

func TestTaxRuntimeSuiteFailurePathsProtectTaxRuntime(t *testing.T) {
	suite, err := NewTaxRuntimeTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	badKDV := KDVOutputRequest()
	badKDV.CurrencyCode = "USD"

	kdvResult, err := suite.KDVRuntime.Execute(badKDV)
	if err == nil {
		t.Fatal("expected KDV currency mismatch error")
	}
	if kdvResult.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", kdvResult.ErrorCode)
	}

	badStopaj := StopajRentRequest()
	badStopaj.TenantID = ""

	stopajResult, err := suite.StopajRuntime.Execute(badStopaj)
	if err == nil {
		t.Fatal("expected Stopaj tenant validation error")
	}
	if stopajResult.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", stopajResult.ErrorCode)
	}

	badExemption := KDVFullExemptionRequest()
	badExemption.ExemptionReason = ""

	exemptionResult, err := suite.ExemptionRuntime.Execute(badExemption)
	if err == nil {
		t.Fatal("expected exemption reason error")
	}
	if exemptionResult.ErrorCode != "EXEMPTION_REASON_REQUIRED" {
		t.Fatalf("expected EXEMPTION_REASON_REQUIRED, got %s", exemptionResult.ErrorCode)
	}

	badRollout := TaxRolloutRequest()
	badRollout.Strategy = rollout.StrategyCanary
	badRollout.CanaryPercent = 10
	badRollout.TenantAllowlist = nil

	rolloutResult, err := suite.RolloutRuntime.PrepareRollout(badRollout)
	if err == nil {
		t.Fatal("expected canary allowlist error")
	}
	if rolloutResult.ErrorCode != "CANARY_TENANT_ALLOWLIST_REQUIRED" {
		t.Fatalf("expected CANARY_TENANT_ALLOWLIST_REQUIRED, got %s", rolloutResult.ErrorCode)
	}

	validAudit := AuditRecordFromKDV(kdv.KDVResult{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-dup-audit",
		RequestID:           "req-dup-audit",
		IdempotencyKey:      "idem-dup-audit",
		DocumentType:        kdv.DocumentTypeSalesInvoice,
		DocumentID:          "invoice-dup-audit",
		DocumentNo:          "INV-DUP-AUDIT",
		RuleVersion:         "TR_KDV_2026_V1",
		TaxBaseAmountKurus:  1000000,
		KDVAmountKurus:      200000,
		AuditDecisionReason: "duplicate audit test",
	})

	if _, err := suite.AuditRuntime.Record(validAudit); err != nil {
		t.Fatalf("record valid audit failed: %v", err)
	}

	duplicate := validAudit
	duplicate.AuditID = "audit-kdv-suite-duplicate"

	_, err = suite.AuditRuntime.Record(duplicate)
	if err == nil {
		t.Fatal("expected duplicate idempotency error")
	}
}
