package logretention

import "testing"

func TestLogRetentionPolicyPassesInternalReadiness(t *testing.T) {
	input := PolicyInput{
		Phase:               "FAZ_5_18_3_3",
		Target:              "FAZ_5_R_PUBLIC_LAUNCH_COMPLIANCE",
		InternalPolicyReady: true,
		RequiredPolicyKeys: []string{
			"audit_event_log_retention",
			"consent_decision_log_retention",
			"contract_document_retention",
			"security_access_log_retention",
			"commercial_operation_log_retention",
		},
		RequireTenantScope:        true,
		RequireLegalHold:          true,
		RequireAuditEvidence:      true,
		RequireKVKKBasis:          true,
		RequireRestoreGuard:       true,
		ProductionDeletionAllowed: false,
		Policies: []RetentionPolicy{
			{
				Key:              "audit_event_log_retention",
				Scope:            ScopeAuditLog,
				Title:            "Audit Event Log Retention",
				Owner:            "security_compliance",
				Status:           StatusReady,
				Required:         true,
				RetentionDays:    365,
				DisposalAction:   ActionArchive,
				TenantScoped:     true,
				HasLegalHold:     true,
				HasAuditEvidence: true,
				HasKVKKBasis:     true,
				HasRestoreGuard:  true,
			},
			{
				Key:              "consent_decision_log_retention",
				Scope:            ScopeConsentLog,
				Title:            "Consent Decision Log Retention",
				Owner:            "kvkk",
				Status:           StatusReady,
				Required:         true,
				RetentionDays:    1825,
				DisposalAction:   ActionArchive,
				TenantScoped:     true,
				HasLegalHold:     true,
				HasAuditEvidence: true,
				HasKVKKBasis:     true,
				HasRestoreGuard:  true,
			},
			{
				Key:              "contract_document_retention",
				Scope:            ScopeContractDoc,
				Title:            "Contract Document Retention",
				Owner:            "commercial_legal",
				Status:           StatusReady,
				Required:         true,
				RetentionDays:    3650,
				DisposalAction:   ActionLegalHold,
				TenantScoped:     true,
				HasLegalHold:     true,
				HasAuditEvidence: true,
				HasKVKKBasis:     true,
				HasRestoreGuard:  true,
			},
			{
				Key:              "security_access_log_retention",
				Scope:            ScopeSecurityLog,
				Title:            "Security Access Log Retention",
				Owner:            "security",
				Status:           StatusReady,
				Required:         true,
				RetentionDays:    730,
				DisposalAction:   ActionArchive,
				TenantScoped:     true,
				HasLegalHold:     true,
				HasAuditEvidence: true,
				HasKVKKBasis:     true,
				HasRestoreGuard:  true,
			},
			{
				Key:              "commercial_operation_log_retention",
				Scope:            ScopeCommercialLog,
				Title:            "Commercial Operation Log Retention",
				Owner:            "commercial_ops",
				Status:           StatusReady,
				Required:         true,
				RetentionDays:    1095,
				DisposalAction:   ActionArchive,
				TenantScoped:     true,
				HasLegalHold:     true,
				HasAuditEvidence: true,
				HasKVKKBasis:     true,
				HasRestoreGuard:  true,
			},
		},
	}

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if report.Status != "PASS" {
		t.Fatalf("expected PASS got %s findings=%v", report.Status, report.Findings)
	}
	if report.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails got %d", report.RequiredFailCount)
	}
	if !report.InternalPolicyReady {
		t.Fatal("internal policy readiness must be true")
	}
	if report.ProductionDeletionAllowed {
		t.Fatal("production deletion must remain blocked")
	}
	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestLogRetentionPolicyBlocksProductionDeletion(t *testing.T) {
	input := PolicyInput{
		Phase:                     "FAZ_5_18_3_3",
		Target:                    "FAZ_5_R_PUBLIC_LAUNCH_COMPLIANCE",
		InternalPolicyReady:       true,
		RequireTenantScope:        true,
		RequireLegalHold:          true,
		RequireAuditEvidence:      true,
		RequireKVKKBasis:          true,
		RequireRestoreGuard:       true,
		ProductionDeletionAllowed: true,
		RequiredPolicyKeys:        []string{"audit_event_log_retention"},
		Policies: []RetentionPolicy{
			{
				Key:                     "audit_event_log_retention",
				Scope:                   ScopeAuditLog,
				Title:                   "Audit Event Log Retention",
				Owner:                   "security_compliance",
				Status:                  StatusReady,
				Required:                true,
				RetentionDays:           365,
				DisposalAction:          ActionDelete,
				TenantScoped:            true,
				HasLegalHold:            true,
				HasAuditEvidence:        true,
				HasKVKKBasis:            true,
				HasRestoreGuard:         true,
				ProductionDeleteEnabled: true,
			},
		},
	}

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}
	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
	if report.ProductionDeletionAllowed {
		t.Fatal("production deletion must be blocked")
	}
}

func TestRequiredPolicyKeysSorted(t *testing.T) {
	input := PolicyInput{RequiredPolicyKeys: []string{"security_access_log_retention", "audit_event_log_retention"}}
	keys := RequiredPolicyKeys(input)
	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "audit_event_log_retention" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}
