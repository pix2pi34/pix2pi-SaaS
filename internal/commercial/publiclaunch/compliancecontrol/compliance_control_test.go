package compliancecontrol

import "testing"

func TestComplianceDocumentControlPassesInDraftPrivateMode(t *testing.T) {
	input := ControlInput{
		LaunchMode:          "COMMERCIAL_PUBLIC_LAUNCH_LEGAL_READINESS",
		Target:              "FAZ_5_R_PUBLIC_LAUNCH",
		PublicLaunchAllowed: false,
		RequiredDocumentKeys: []string{
			"contract_set",
			"kvkk_privacy_notice",
			"explicit_consent_text",
			"commercial_use_terms",
			"consent_registry_policy",
			"log_retention_destruction_policy",
		},
		RequireVersionedDocs:     true,
		RequireKVKKGate:          true,
		RequireLegalGate:         true,
		RequireFounderGate:       true,
		RequireNoPublicDraftDocs: true,
		Documents: []ComplianceDocument{
			{
				Key:                   "contract_set",
				Title:                 "Sözleşme Seti",
				Owner:                 "commercial_legal",
				Version:               "v1.0-draft",
				Status:                DocumentApprovedPrivate,
				Required:              true,
				PublicPublishAllowed:  false,
				RequiresLegalApproval: true,
				RequiresFounderGoNoGo: true,
			},
			{
				Key:                  "kvkk_privacy_notice",
				Title:                "KVKK / Gizlilik Metinleri",
				Owner:                "kvkk",
				Version:              "v1.0-draft",
				Status:               DocumentApprovedPrivate,
				Required:             true,
				PublicPublishAllowed: false,
				RequiresKVKKApproval: true,
				ContainsDataUseScope: true,
			},
			{
				Key:                  "explicit_consent_text",
				Title:                "Açık Rıza Metni",
				Owner:                "kvkk",
				Version:              "v1.0-draft",
				Status:               DocumentApprovedPrivate,
				Required:             true,
				PublicPublishAllowed: false,
				RequiresKVKKApproval: true,
				ContainsConsentScope: true,
				ContainsDataUseScope: true,
			},
			{
				Key:                   "commercial_use_terms",
				Title:                 "Ticari Kullanım Şartları",
				Owner:                 "commercial_legal",
				Version:               "v1.0-draft",
				Status:                DocumentApprovedPrivate,
				Required:              true,
				PublicPublishAllowed:  false,
				RequiresLegalApproval: true,
				RequiresFounderGoNoGo: true,
			},
			{
				Key:                  "consent_registry_policy",
				Title:                "Consent Registry Policy",
				Owner:                "kvkk",
				Version:              "v1.0-draft",
				Status:               DocumentApprovedPrivate,
				Required:             true,
				PublicPublishAllowed: false,
				RequiresKVKKApproval: true,
				ContainsConsentScope: true,
			},
			{
				Key:                    "log_retention_destruction_policy",
				Title:                  "Log Retention / İmha Politikası",
				Owner:                  "security_compliance",
				Version:                "v1.0-draft",
				Status:                 DocumentApprovedPrivate,
				Required:               true,
				PublicPublishAllowed:   false,
				RequiresLegalApproval:  true,
				RequiresKVKKApproval:   true,
				ContainsRetentionScope: true,
			},
		},
		ApprovalGates: []ApprovalGate{
			{Key: "legal_counsel_approval", Owner: "legal", Status: ApprovalPending},
			{Key: "kvkk_consultant_approval", Owner: "kvkk", Status: ApprovalPending},
			{Key: "founder_go_no_go", Owner: "founder", Status: ApprovalPending},
		},
	}

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if report.Status != "PASS" {
		t.Fatalf("expected PASS, got %s findings=%v", report.Status, report.Findings)
	}
	if report.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails, got %d", report.RequiredFailCount)
	}
	if report.PublicLaunchAllowed {
		t.Fatal("public launch must remain blocked while approvals are pending")
	}
	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestComplianceDocumentControlBlocksPublicDraft(t *testing.T) {
	input := ControlInput{
		LaunchMode:          "COMMERCIAL_PUBLIC_LAUNCH_LEGAL_READINESS",
		Target:              "FAZ_5_R_PUBLIC_LAUNCH",
		PublicLaunchAllowed: true,
		RequiredDocumentKeys: []string{
			"contract_set",
		},
		RequireVersionedDocs:     true,
		RequireKVKKGate:          false,
		RequireLegalGate:         true,
		RequireFounderGate:       true,
		RequireNoPublicDraftDocs: true,
		Documents: []ComplianceDocument{
			{
				Key:                   "contract_set",
				Title:                 "Sözleşme Seti",
				Owner:                 "commercial_legal",
				Version:               "v1.0-draft",
				Status:                DocumentDraft,
				Required:              true,
				PublicPublishAllowed:  true,
				RequiresLegalApproval: true,
				RequiresFounderGoNoGo: true,
			},
		},
		ApprovalGates: []ApprovalGate{
			{Key: "legal_counsel_approval", Owner: "legal", Status: ApprovalPending},
			{Key: "founder_go_no_go", Owner: "founder", Status: ApprovalPending},
		},
	}

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL, got %s", report.Status)
	}
	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail count > 0")
	}
	if report.PublicLaunchAllowed {
		t.Fatal("public launch must be blocked")
	}
}

func TestRequiredDocumentKeysSorted(t *testing.T) {
	input := ControlInput{RequiredDocumentKeys: []string{"kvkk_privacy_notice", "contract_set"}}
	keys := RequiredDocumentKeys(input)
	if len(keys) != 2 {
		t.Fatalf("expected 2 keys, got %d", len(keys))
	}
	if keys[0] != "contract_set" {
		t.Fatalf("expected sorted keys, got %v", keys)
	}
}
