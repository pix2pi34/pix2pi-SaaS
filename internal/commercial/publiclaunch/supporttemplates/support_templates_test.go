package supporttemplates

import "testing"

func TestCustomerCommunicationTemplatesPassInternalReadiness(t *testing.T) {
	input := validTemplateInput()

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

	if !report.InternalTemplatesReady {
		t.Fatal("internal templates readiness must be true")
	}

	if report.PublicTemplatesPublished {
		t.Fatal("public template publication must remain blocked")
	}

	if report.RealCustomerSendingEnabled {
		t.Fatal("real customer sending must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestCustomerCommunicationTemplatesBlockRealCustomerSending(t *testing.T) {
	input := validTemplateInput()
	input.RealCustomerSendingEnabled = true

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

	if report.RealCustomerSendingEnabled {
		t.Fatal("real customer sending must be blocked")
	}
}

func TestCustomerCommunicationTemplatesRequireKVKKPrivacyNotice(t *testing.T) {
	input := validTemplateInput()

	for idx := range input.Templates {
		if input.Templates[idx].Category == CategoryKVKKRequest {
			input.Templates[idx].HasPrivacyNoticeLink = false
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

func TestCustomerCommunicationTemplatesRequireBreachSLAContext(t *testing.T) {
	input := validTemplateInput()

	for idx := range input.Templates {
		if input.Templates[idx].Category == CategorySLABreach {
			input.Templates[idx].HasSLAContext = false
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

func TestRequiredTemplateKeysSorted(t *testing.T) {
	input := TemplateInput{RequiredTemplateKeys: []string{"template_security_report_ack", "template_ticket_ack"}}
	keys := RequiredTemplateKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "template_security_report_ack" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validTemplateInput() TemplateInput {
	return TemplateInput{
		Phase:                      "FAZ_5_18_4_5",
		Target:                     "FAZ_5_R_CUSTOMER_COMMUNICATION_TEMPLATES",
		InternalTemplatesReady:     true,
		PublicTemplatesPublished:   false,
		RealCustomerSendingEnabled: false,
		RequiredTemplateKeys: []string{
			"template_ticket_ack",
			"template_incident_update",
			"template_sla_breach_notice",
			"template_kvkk_request_ack",
			"template_billing_issue_ack",
			"template_security_report_ack",
		},
		RequiredCategories: []TemplateCategory{
			CategoryTicketAck,
			CategoryIncidentUpdate,
			CategorySLABreach,
			CategoryKVKKRequest,
			CategoryBillingIssue,
			CategorySecurityReport,
		},
		RequireTenantContext:            true,
		RequireTicketContext:            true,
		RequireAuditTrail:               true,
		RequireToneGuard:                true,
		RequireKVKKFooter:               true,
		RequirePrivacyNoticeForKVKK:     true,
		RequireSLAContextForBreach:      true,
		RequireEscalationHintForBreach:  true,
		RequireTurkishLanguageTemplates: true,
		Templates: []CustomerTemplate{
			template("template_ticket_ack", CategoryTicketAck, ChannelEmail, "Talebiniz Alındı", true, false),
			template("template_incident_update", CategoryIncidentUpdate, ChannelEmail, "Talebiniz İçin Güncelleme", true, false),
			template("template_sla_breach_notice", CategorySLABreach, ChannelEmail, "SLA Bilgilendirmesi", true, true),
			template("template_kvkk_request_ack", CategoryKVKKRequest, ChannelEmail, "KVKK Talebiniz Alındı", true, false),
			template("template_billing_issue_ack", CategoryBillingIssue, ChannelEmail, "Faturalama Talebiniz Alındı", true, false),
			template("template_security_report_ack", CategorySecurityReport, ChannelEmail, "Güvenlik Bildiriminiz Alındı", true, false),
		},
	}
}

func template(key string, category TemplateCategory, channel DeliveryChannel, subject string, privacy bool, breach bool) CustomerTemplate {
	return CustomerTemplate{
		Key:                  key,
		Category:             category,
		Channel:              channel,
		Title:                subject,
		Owner:                "support_ops",
		Language:             "tr-TR",
		Status:               StatusReady,
		Required:             true,
		InternalOnly:         true,
		PublicPublished:      false,
		RealCustomerSending:  false,
		Subject:              subject,
		BodyPreview:          "Merhaba, talebiniz güvenli şekilde kayıt altına alınmıştır.",
		RequiredVariables:    []string{"tenant_id", "ticket_id", "requester_email", "correlation_id", "sla_key"},
		HasTenantContext:     true,
		HasTicketContext:     true,
		HasSLAContext:        true,
		HasKVKKFooter:        true,
		HasPrivacyNoticeLink: privacy,
		HasAuditTrail:        true,
		HasToneGuard:         true,
		HasEscalationHint:    breach,
	}
}
