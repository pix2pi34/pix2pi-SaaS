package legalchecklist

import "testing"

func TestLegalChecklistPassesInternalReadiness(t *testing.T) {
	input := validChecklistInput()

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

	if !report.InternalLegalChecklistReady {
		t.Fatal("internal legal checklist readiness must be true")
	}

	if report.ProductionPublicLaunchAllowed {
		t.Fatal("production public launch must remain blocked")
	}

	if report.RealCustomerCollectionAllowed {
		t.Fatal("real customer collection must remain blocked")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestLegalChecklistBlocksProductionPublicLaunch(t *testing.T) {
	input := validChecklistInput()
	input.ProductionPublicLaunchAllowed = true

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
}

func TestLegalChecklistRequiresVersion(t *testing.T) {
	input := validChecklistInput()
	input.Items[0].HasVersion = false

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
}

func TestLegalChecklistAllowsDeferredFinalApprovalWithReason(t *testing.T) {
	input := validChecklistInput()

	found := false
	for _, item := range input.Items {
		if item.DeferredToFinalApproval && item.DeferredReason != "" {
			found = true
		}
	}

	if !found {
		t.Fatal("expected at least one deferred final approval item")
	}
}

func TestRequiredItemKeysSorted(t *testing.T) {
	input := ChecklistInput{RequiredItemKeys: []string{"support_legal_readiness", "contract_set"}}
	keys := RequiredItemKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "contract_set" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validChecklistInput() ChecklistInput {
	return ChecklistInput{
		Phase:                         "FAZ_5_18_8_2",
		Target:                        "FAZ_5_R_LEGAL_CHECKLIST",
		InternalLegalChecklistReady:   true,
		ProductionPublicLaunchAllowed: false,
		RealCustomerCollectionAllowed: false,
		RequiredItemKeys: []string{
			"contract_set",
			"kvkk_privacy_notice",
			"explicit_consent_text",
			"consent_registry_policy",
			"log_retention_destruction_policy",
			"support_legal_readiness",
			"legal_final_approval_marker",
			"kvkk_final_approval_marker",
			"founder_final_go_no_go_marker",
		},
		RequiredDomains: []LegalDomain{
			DomainContract,
			DomainKVKK,
			DomainConsent,
			DomainRetention,
			DomainSupportLegal,
			DomainLaunchApproval,
		},
		RequireLegalApprovalGate:   true,
		RequireKVKKApprovalGate:    true,
		RequireFounderApprovalGate: true,
		RequireVersionedDocuments:  true,
		RequireEvidence:            true,
		RequireCounterBasedAudit:   true,
		RequireNoRequiredFail:      true,
		RequireNoOptionalWarn:      true,
		AllowDeferredFinalApproval: true,
		Items: []LegalChecklistItem{
			ready("contract_set", DomainContract, "Sözleşme Seti", true, false, true),
			ready("kvkk_privacy_notice", DomainKVKK, "KVKK / Gizlilik Metni", false, true, true),
			ready("explicit_consent_text", DomainConsent, "Açık Rıza Metni", false, true, true),
			ready("consent_registry_policy", DomainConsent, "Consent Registry Policy", false, true, true),
			ready("log_retention_destruction_policy", DomainRetention, "Log Retention / İmha Politikası", true, true, true),
			ready("support_legal_readiness", DomainSupportLegal, "Support Legal Readiness", true, true, true),
			deferred("legal_final_approval_marker", DomainLaunchApproval, "Nihai Hukukçu Onayı", "Production public launch öncesi gerçek hukukçu onayı alınacak", true, false, true),
			deferred("kvkk_final_approval_marker", DomainLaunchApproval, "Nihai KVKK Danışmanı Onayı", "Production public launch öncesi gerçek KVKK danışmanı onayı alınacak", false, true, true),
			deferred("founder_final_go_no_go_marker", DomainLaunchApproval, "Founder Final Go / No-Go", "Production public launch öncesi founder final onayı alınacak", true, true, true),
		},
	}
}

func ready(key string, domain LegalDomain, title string, legal bool, kvkk bool, founder bool) LegalChecklistItem {
	return LegalChecklistItem{
		Key:                           key,
		Domain:                        domain,
		Title:                         title,
		Owner:                         "legal_compliance",
		Status:                        StatusReady,
		Required:                      true,
		BlocksPublicLaunch:            true,
		RequiresLegalApproval:         legal,
		LegalApprovalReady:            legal,
		RequiresKVKKApproval:          kvkk,
		KVKKApprovalReady:             kvkk,
		RequiresFounderApproval:       founder,
		FounderApprovalReady:          founder,
		RequiresVersion:               true,
		HasVersion:                    true,
		RequiresEvidence:              true,
		HasEvidence:                   true,
		RequiresCounterBasedAudit:     true,
		HasCounterBasedAudit:          true,
		RequiredFailCount:             0,
		OptionalWarnCount:             0,
		PublicPublishAllowed:          false,
		RealCustomerCollectionAllowed: false,
		DeferredToFinalApproval:       false,
	}
}

func deferred(key string, domain LegalDomain, title string, reason string, legal bool, kvkk bool, founder bool) LegalChecklistItem {
	return LegalChecklistItem{
		Key:                           key,
		Domain:                        domain,
		Title:                         title,
		Owner:                         "legal_compliance",
		Status:                        StatusPendingLegal,
		Required:                      true,
		BlocksPublicLaunch:            true,
		RequiresLegalApproval:         legal,
		LegalApprovalReady:            false,
		RequiresKVKKApproval:          kvkk,
		KVKKApprovalReady:             false,
		RequiresFounderApproval:       founder,
		FounderApprovalReady:          false,
		RequiresVersion:               true,
		HasVersion:                    true,
		RequiresEvidence:              true,
		HasEvidence:                   true,
		RequiresCounterBasedAudit:     true,
		HasCounterBasedAudit:          true,
		RequiredFailCount:             0,
		OptionalWarnCount:             0,
		PublicPublishAllowed:          false,
		RealCustomerCollectionAllowed: false,
		DeferredToFinalApproval:       true,
		DeferredReason:                reason,
	}
}
