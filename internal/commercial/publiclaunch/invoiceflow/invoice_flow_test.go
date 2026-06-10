package invoiceflow

import "testing"

func TestInvoiceFlowPassesInternalReadiness(t *testing.T) {
	input := validFlowInput()

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

	if !report.InternalInvoiceFlowReady {
		t.Fatal("internal invoice flow readiness must be true")
	}

	if report.ProductionInvoiceEnabled {
		t.Fatal("production invoice must remain disabled")
	}

	if report.RealCustomerInvoiceEnabled {
		t.Fatal("real customer invoice must remain disabled")
	}

	if report.AutoInvoiceDeliveryEnabled {
		t.Fatal("auto invoice delivery must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestInvoiceFlowBlocksProductionInvoice(t *testing.T) {
	input := validFlowInput()
	input.ProductionInvoiceEnabled = true

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

func TestInvoiceFlowRequiresTaxCalculation(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresTaxCalculation = false

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

func TestInvoiceFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToEDocumentModule {
			input.Steps[idx].DeferredReason = ""
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

func TestRequiredStepKeysSorted(t *testing.T) {
	input := FlowInput{RequiredStepKeys: []string{"invoice_finalize", "invoice_draft_create"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "invoice_draft_create" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                      "FAZ_5_18_2_2",
		Target:                     "FAZ_5_R_INVOICE_FLOW",
		InternalInvoiceFlowReady:   true,
		ProductionInvoiceEnabled:   false,
		RealCustomerInvoiceEnabled: false,
		AutoInvoiceDeliveryEnabled: false,
		RequiredStepKeys: []string{
			"invoice_draft_create",
			"invoice_billing_profile_validate",
			"invoice_plan_snapshot_attach",
			"invoice_line_item_calculate",
			"invoice_tax_calculate",
			"invoice_finalize",
			"invoice_due_schedule",
			"invoice_delivery_block_policy",
			"accounting_export_handoff",
			"e_document_deferred_marker",
		},
		RequiredEvents: []InvoiceEvent{
			EventInvoiceDraftCreated,
			EventInvoiceCalculated,
			EventInvoiceFinalized,
			EventInvoiceDueScheduled,
			EventInvoiceDeliveryReady,
			EventAccountingExportReady,
			EventEDocumentDeferred,
		},
		RequireInternalReady:             true,
		RequireEvidence:                  true,
		RequireCounterBasedAudit:         true,
		RequireNoRequiredFail:            true,
		RequireNoOptionalWarn:            true,
		RequireTenantID:                  true,
		RequireInvoiceID:                 true,
		RequireBillingProfile:            true,
		RequirePlanSnapshot:              true,
		RequireLineItems:                 true,
		RequireTaxCalculation:            true,
		RequireDueDate:                   true,
		RequireCurrency:                  true,
		RequireAuditTrail:                true,
		RequireIdempotencyKey:            true,
		RequireAccountingExport:          true,
		RequireEDocumentHandoff:          true,
		RequireProductionInvoiceBlock:    true,
		RequireRealCustomerDeliveryBlock: true,
		AllowEDocumentDeferred:           true,
		Steps: []InvoiceStep{
			step("invoice_draft_create", EventInvoiceDraftCreated, "Invoice Draft Create"),
			step("invoice_billing_profile_validate", EventInvoiceDraftCreated, "Billing Profile Validate"),
			step("invoice_plan_snapshot_attach", EventInvoiceDraftCreated, "Plan Snapshot Attach"),
			step("invoice_line_item_calculate", EventInvoiceCalculated, "Line Item Calculate"),
			step("invoice_tax_calculate", EventInvoiceCalculated, "Tax Calculate"),
			step("invoice_finalize", EventInvoiceFinalized, "Invoice Finalize"),
			step("invoice_due_schedule", EventInvoiceDueScheduled, "Invoice Due Schedule"),
			step("invoice_delivery_block_policy", EventInvoiceDeliveryReady, "Invoice Delivery Block Policy"),
			step("accounting_export_handoff", EventAccountingExportReady, "Accounting Export Handoff"),
			deferred("e_document_deferred_marker", EventEDocumentDeferred, "E-Document Deferred Marker", "e-Belge production gönderimi e-document provider/live modülünde açılacak"),
		},
	}
}

func step(key string, event InvoiceEvent, title string) InvoiceStep {
	return InvoiceStep{
		Key:                        key,
		Event:                      event,
		Title:                      title,
		Owner:                      "billing_ops",
		Status:                     StatusReady,
		Required:                   true,
		InternalReady:              true,
		HasEvidence:                true,
		HasCounterBasedAudit:       true,
		RequiredFailCount:          0,
		OptionalWarnCount:          0,
		ProductionInvoiceEnabled:   false,
		RealCustomerInvoiceEnabled: false,
		AutoInvoiceDeliveryEnabled: false,
		RequiresTenantID:           true,
		RequiresInvoiceID:          true,
		RequiresBillingProfile:     true,
		RequiresPlanSnapshot:       true,
		RequiresLineItems:          true,
		RequiresTaxCalculation:     true,
		RequiresDueDate:            true,
		RequiresCurrency:           true,
		RequiresAuditTrail:         true,
		RequiresIdempotencyKey:     true,
		RequiresAccountingExport:   true,
		RequiresEDocumentHandoff:   true,
		BlocksProductionInvoice:    true,
		BlocksRealCustomerDelivery: true,
		DeferredToEDocumentModule:  false,
	}
}

func deferred(key string, event InvoiceEvent, title string, reason string) InvoiceStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToEDocumentModule = true
	s.DeferredReason = reason
	return s
}
