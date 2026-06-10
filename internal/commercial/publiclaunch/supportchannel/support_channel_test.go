package supportchannel

import "testing"

func TestSupportChannelStructurePassesInternalReadiness(t *testing.T) {
	input := validChannelInput()

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

	if !report.InternalChannelStructureReady {
		t.Fatal("internal channel structure readiness must be true")
	}

	if report.PublicSupportEnabled {
		t.Fatal("public support must remain disabled")
	}

	if report.RealCustomerSupportOpen {
		t.Fatal("real customer support must remain closed")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestSupportChannelStructureBlocksPublicSupport(t *testing.T) {
	input := validChannelInput()
	input.PublicSupportEnabled = true

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

	if report.PublicSupportEnabled {
		t.Fatal("public support must be blocked")
	}
}

func TestSupportChannelStructureRequiresKVKKPrivacyNoticeLink(t *testing.T) {
	input := validChannelInput()

	for idx := range input.Channels {
		if input.Channels[idx].Type == ChannelKVKK {
			input.Channels[idx].HasPrivacyNoticeLink = false
		}
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
}

func TestRequiredChannelKeysSorted(t *testing.T) {
	input := ChannelInput{RequiredChannelKeys: []string{"support_security_report", "support_email_intake"}}
	keys := RequiredChannelKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "support_email_intake" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validChannelInput() ChannelInput {
	return ChannelInput{
		Phase:                         "FAZ_5_18_4_2",
		Target:                        "FAZ_5_R_SUPPORT_CHANNEL_STRUCTURE",
		InternalChannelStructureReady: true,
		PublicSupportEnabled:          false,
		RealCustomerSupportOpen:       false,
		RequiredChannelKeys: []string{
			"support_email_intake",
			"support_in_app_intake",
			"support_help_center_form",
			"support_kvkk_request",
			"support_security_report",
			"support_ops_escalation",
		},
		RequiredFamilies: []IssueFamily{
			IssuePilot,
			IssueBilling,
			IssueKVKK,
			IssueSecurity,
			IssueTechnical,
			IssueCommercial,
		},
		RequireTenantSafeIntake:     true,
		RequireRequesterEmail:       true,
		RequireCorrelationID:        true,
		RequireSLAKey:               true,
		RequireAuditTrail:           true,
		RequireIntakeTemplate:       true,
		RequireRoutingRule:          true,
		RequireOpsOwner:             true,
		RequirePrivacyNoticeForKVKK: true,
		Channels: []SupportChannel{
			{
				Key:                    "support_email_intake",
				Type:                   ChannelEmail,
				Title:                  "Support Email Intake",
				Status:                 StatusReady,
				Owner:                  "support_ops",
				Required:               true,
				PublicVisible:          false,
				InternalOnly:           true,
				AllowedFamilies:        []IssueFamily{IssuePilot, IssueBilling, IssueTechnical, IssueCommercial},
				RequiresTenantID:       true,
				RequiresRequesterEmail: true,
				RequiresCorrelationID:  true,
				RequiresConsentContext: false,
				RequiresAuditTrail:     true,
				RequiresSLAKey:         true,
				HasIntakeTemplate:      true,
				HasRoutingRule:         true,
				HasOpsOwner:            true,
				HasPrivacyNoticeLink:   false,
			},
			{
				Key:                    "support_in_app_intake",
				Type:                   ChannelInApp,
				Title:                  "In-App Support Intake",
				Status:                 StatusReady,
				Owner:                  "product_ops",
				Required:               true,
				PublicVisible:          false,
				InternalOnly:           true,
				AllowedFamilies:        []IssueFamily{IssuePilot, IssueTechnical, IssueCommercial},
				RequiresTenantID:       true,
				RequiresRequesterEmail: true,
				RequiresCorrelationID:  true,
				RequiresConsentContext: false,
				RequiresAuditTrail:     true,
				RequiresSLAKey:         true,
				HasIntakeTemplate:      true,
				HasRoutingRule:         true,
				HasOpsOwner:            true,
				HasPrivacyNoticeLink:   false,
			},
			{
				Key:                    "support_help_center_form",
				Type:                   ChannelHelpCenter,
				Title:                  "Help Center Contact Form",
				Status:                 StatusReady,
				Owner:                  "customer_success",
				Required:               true,
				PublicVisible:          false,
				InternalOnly:           true,
				AllowedFamilies:        []IssueFamily{IssuePilot, IssueTechnical, IssueCommercial},
				RequiresTenantID:       true,
				RequiresRequesterEmail: true,
				RequiresCorrelationID:  true,
				RequiresConsentContext: false,
				RequiresAuditTrail:     true,
				RequiresSLAKey:         true,
				HasIntakeTemplate:      true,
				HasRoutingRule:         true,
				HasOpsOwner:            true,
				HasPrivacyNoticeLink:   false,
			},
			{
				Key:                    "support_kvkk_request",
				Type:                   ChannelKVKK,
				Title:                  "KVKK Request Channel",
				Status:                 StatusReady,
				Owner:                  "kvkk",
				Required:               true,
				PublicVisible:          false,
				InternalOnly:           true,
				AllowedFamilies:        []IssueFamily{IssueKVKK},
				RequiresTenantID:       true,
				RequiresRequesterEmail: true,
				RequiresCorrelationID:  true,
				RequiresConsentContext: true,
				RequiresAuditTrail:     true,
				RequiresSLAKey:         true,
				HasIntakeTemplate:      true,
				HasRoutingRule:         true,
				HasOpsOwner:            true,
				HasPrivacyNoticeLink:   true,
			},
			{
				Key:                    "support_security_report",
				Type:                   ChannelSecurity,
				Title:                  "Security Report Channel",
				Status:                 StatusReady,
				Owner:                  "security",
				Required:               true,
				PublicVisible:          false,
				InternalOnly:           true,
				AllowedFamilies:        []IssueFamily{IssueSecurity},
				RequiresTenantID:       true,
				RequiresRequesterEmail: true,
				RequiresCorrelationID:  true,
				RequiresConsentContext: false,
				RequiresAuditTrail:     true,
				RequiresSLAKey:         true,
				HasIntakeTemplate:      true,
				HasRoutingRule:         true,
				HasOpsOwner:            true,
				HasPrivacyNoticeLink:   false,
			},
			{
				Key:                    "support_ops_escalation",
				Type:                   ChannelOpsEscalation,
				Title:                  "Ops Escalation Channel",
				Status:                 StatusReady,
				Owner:                  "ops",
				Required:               true,
				PublicVisible:          false,
				InternalOnly:           true,
				AllowedFamilies:        []IssueFamily{IssuePilot, IssueBilling, IssueKVKK, IssueSecurity, IssueTechnical, IssueCommercial},
				RequiresTenantID:       true,
				RequiresRequesterEmail: true,
				RequiresCorrelationID:  true,
				RequiresConsentContext: false,
				RequiresAuditTrail:     true,
				RequiresSLAKey:         true,
				HasIntakeTemplate:      true,
				HasRoutingRule:         true,
				HasOpsOwner:            true,
				HasPrivacyNoticeLink:   false,
			},
		},
	}
}
