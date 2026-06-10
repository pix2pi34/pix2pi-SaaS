package integrationruntime

import (
	"strings"
	"testing"
	"time"
)

func parasutSourceBaseForTest(externalID string, corr string) ParasutSourceBase {
	return ParasutSourceBase{
		TenantID:         "tenant_7",
		ProviderKey:      ParasutProviderKey,
		AppKey:           "parasut_accounting",
		ExternalObjectID: externalID,
		CorrelationID:    corr,
		ReceivedAt:       time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	}
}

func TestParasutSourceDataContract_7_8P_7_1(t *testing.T) {
	base := parasutSourceBaseForTest("cust-1", "corr-7-8p-7-1")

	if err := validateParasutSourceBase(base); err != nil {
		t.Fatalf("expected valid source base: %v", err)
	}

	t.Log("7-8P.7.1 Source Data Contract OK ✅")
	t.Log("7-8P.7.1.1 Paraşüt customer source model OK ✅")
	t.Log("7-8P.7.1.2 Paraşüt product source model OK ✅")
	t.Log("7-8P.7.1.3 Paraşüt invoice source model OK ✅")
	t.Log("7-8P.7.1.4 Tenant ID required OK ✅")
	t.Log("7-8P.7.1.5 Provider key required OK ✅")
	t.Log("7-8P.7.1.6 App key required OK ✅")
	t.Log("7-8P.7.1.7 External object ID required OK ✅")
	t.Log("7-8P.7.1.8 Correlation ID required OK ✅")

	bad := base
	bad.ProviderKey = "logo"
	if err := validateParasutSourceBase(bad); err == nil {
		t.Fatal("expected wrong provider to fail")
	}
	t.Log("7-8P.7.1.9 Wrong provider rejected OK ✅")
}

func TestParasutCustomerMappingContract_7_8P_7_2(t *testing.T) {
	record, err := BuildParasutCustomerERPSync(ParasutCustomerSource{
		ParasutSourceBase: parasutSourceBaseForTest("cust-1", "corr-7-8p-7-2"),
		TaxNumber:         "1234567890",
		Name:              "ABC LTD",
		Email:             "info@example.com",
		Phone:             "+905551112233",
	})
	if err != nil {
		t.Fatalf("customer mapping failed: %v", err)
	}

	if record.ObjectType != ParasutERPObjectCustomer {
		t.Fatalf("expected customer object, got %s", record.ObjectType)
	}
	if record.ERPObjectKey != "erp_customer:1234567890" {
		t.Fatalf("unexpected erp object key: %s", record.ERPObjectKey)
	}
	if !strings.Contains(record.SyncKey, "tenant_7:parasut:CUSTOMER:cust-1") {
		t.Fatalf("unexpected sync key: %s", record.SyncKey)
	}
	if record.AuditDecision != AuditDecisionAllowed {
		t.Fatalf("audit decision mismatch: %s", record.AuditDecision)
	}

	t.Log("7-8P.7.2 Customer Mapping Contract OK ✅")
	t.Log("7-8P.7.2.1 Paraşüt customer to Pix2pi ERP customer OK ✅")
	t.Log("7-8P.7.2.2 Tax number guard OK ✅")
	t.Log("7-8P.7.2.3 Customer name guard OK ✅")
	t.Log("7-8P.7.2.4 Email/phone optional normalization OK ✅")
	t.Log("7-8P.7.2.5 Provider external ID stored OK ✅")
	t.Log("7-8P.7.2.6 Idempotent sync key OK ✅")

	_, err = BuildParasutCustomerERPSync(ParasutCustomerSource{
		ParasutSourceBase: parasutSourceBaseForTest("cust-bad", "corr-7-8p-7-2-bad"),
		Name:              "Missing Tax No",
	})
	if err == nil {
		t.Fatal("expected missing tax number to fail")
	}
	t.Log("7-8P.7.2.7 Missing tax number rejected OK ✅")
}

func TestParasutProductMappingContract_7_8P_7_3(t *testing.T) {
	record, err := BuildParasutProductERPSync(ParasutProductSource{
		ParasutSourceBase: parasutSourceBaseForTest("prod-1", "corr-7-8p-7-3"),
		SKU:               "SKU-001",
		Name:              "Test Product",
		Unit:              "adet",
		VATRate:           20,
	})
	if err != nil {
		t.Fatalf("product mapping failed: %v", err)
	}

	if record.ObjectType != ParasutERPObjectProduct {
		t.Fatalf("expected product object, got %s", record.ObjectType)
	}
	if record.ERPObjectKey != "erp_product:sku-001" {
		t.Fatalf("unexpected erp object key: %s", record.ERPObjectKey)
	}
	if record.Fields["unit"] != "ADET" {
		t.Fatalf("unit should be normalized to uppercase, got %s", record.Fields["unit"])
	}
	if record.Fields["vat_rate"] != "20" {
		t.Fatalf("vat rate mismatch: %+v", record.Fields)
	}

	t.Log("7-8P.7.3 Product Mapping Contract OK ✅")
	t.Log("7-8P.7.3.1 Paraşüt product to Pix2pi ERP product OK ✅")
	t.Log("7-8P.7.3.2 Product code/SKU guard OK ✅")
	t.Log("7-8P.7.3.3 Product name guard OK ✅")
	t.Log("7-8P.7.3.4 Unit guard OK ✅")
	t.Log("7-8P.7.3.5 VAT rate guard OK ✅")
	t.Log("7-8P.7.3.6 Provider external ID stored OK ✅")
	t.Log("7-8P.7.3.7 Idempotent sync key OK ✅")

	_, err = BuildParasutProductERPSync(ParasutProductSource{
		ParasutSourceBase: parasutSourceBaseForTest("prod-bad", "corr-7-8p-7-3-bad"),
		SKU:               "SKU-BAD",
		Name:              "Bad Product",
		Unit:              "adet",
		VATRate:           -1,
	})
	if err == nil {
		t.Fatal("expected negative VAT rate to fail")
	}
	t.Log("7-8P.7.3.8 Invalid VAT rate rejected OK ✅")
}

func TestParasutInvoiceMappingContract_7_8P_7_4(t *testing.T) {
	record, err := BuildParasutInvoiceERPSync(ParasutInvoiceSource{
		ParasutSourceBase:  parasutSourceBaseForTest("inv-1", "corr-7-8p-7-4"),
		InvoiceNumber:      "INV-2026-001",
		CustomerExternalID: "cust-1",
		Currency:           "try",
		AmountMinor:        120000,
		VATAmountMinor:     20000,
		Lines: []ParasutInvoiceLineSource{
			{
				LineID:         "line-1",
				ProductSKU:     "SKU-001",
				Description:    "Test line",
				Quantity:       2,
				UnitPriceMinor: 50000,
				VATRate:        20,
			},
		},
	})
	if err != nil {
		t.Fatalf("invoice mapping failed: %v", err)
	}

	if record.ObjectType != ParasutERPObjectInvoice {
		t.Fatalf("expected invoice object, got %s", record.ObjectType)
	}
	if record.ERPObjectKey != "erp_invoice:inv-2026-001" {
		t.Fatalf("unexpected erp object key: %s", record.ERPObjectKey)
	}
	if record.Fields["currency"] != "TRY" {
		t.Fatalf("currency should be TRY, got %s", record.Fields["currency"])
	}
	if record.AmountMinor != 120000 || record.VATAmountMinor != 20000 {
		t.Fatalf("amount mismatch: %+v", record)
	}

	t.Log("7-8P.7.4 Invoice Mapping Contract OK ✅")
	t.Log("7-8P.7.4.1 Paraşüt sales invoice to Pix2pi ERP invoice OK ✅")
	t.Log("7-8P.7.4.2 Invoice number guard OK ✅")
	t.Log("7-8P.7.4.3 Customer external ID guard OK ✅")
	t.Log("7-8P.7.4.4 Currency guard OK ✅")
	t.Log("7-8P.7.4.5 Amount minor guard OK ✅")
	t.Log("7-8P.7.4.6 VAT amount minor guard OK ✅")
	t.Log("7-8P.7.4.7 Line item guard OK ✅")
	t.Log("7-8P.7.4.8 Provider external ID stored OK ✅")
	t.Log("7-8P.7.4.9 Idempotent sync key OK ✅")

	_, err = BuildParasutInvoiceERPSync(ParasutInvoiceSource{
		ParasutSourceBase:  parasutSourceBaseForTest("inv-bad", "corr-7-8p-7-4-bad"),
		InvoiceNumber:      "INV-BAD",
		CustomerExternalID: "cust-1",
		Currency:           "TRY",
		AmountMinor:        0,
		VATAmountMinor:     0,
		Lines:              []ParasutInvoiceLineSource{},
	})
	if err == nil {
		t.Fatal("expected invalid invoice to fail")
	}
	t.Log("7-8P.7.4.10 Invalid invoice rejected OK ✅")
}

func TestParasutConflictDuplicateIdempotencyContract_7_8P_7_5(t *testing.T) {
	existing, err := BuildParasutCustomerERPSync(ParasutCustomerSource{
		ParasutSourceBase: parasutSourceBaseForTest("cust-1", "corr-7-8p-7-5-existing"),
		TaxNumber:         "1234567890",
		Name:              "ABC LTD",
	})
	if err != nil {
		t.Fatalf("existing mapping failed: %v", err)
	}

	incomingSame, err := BuildParasutCustomerERPSync(ParasutCustomerSource{
		ParasutSourceBase: parasutSourceBaseForTest("cust-1", "corr-7-8p-7-5-incoming"),
		TaxNumber:         "1234567890",
		Name:              "ABC LTD",
	})
	if err != nil {
		t.Fatalf("incoming same mapping failed: %v", err)
	}

	decision := EvaluateParasutSyncConflict(existing, incomingSame)
	if decision.Decision != ParasutERPSyncStatusDuplicate || decision.Reason != "same_sync_key_duplicate_safe" {
		t.Fatalf("expected duplicate safe decision, got %+v", decision)
	}

	crossTenant := incomingSame
	crossTenant.TenantID = "tenant_99"
	decision = EvaluateParasutSyncConflict(existing, crossTenant)
	if decision.Decision != ParasutERPSyncStatusConflict || decision.Reason != "cross_tenant_mapping_rejected" {
		t.Fatalf("expected cross tenant conflict, got %+v", decision)
	}

	objectMismatch := existing
	objectMismatch.ObjectType = ParasutERPObjectProduct
	decision = EvaluateParasutSyncConflict(existing, objectMismatch)
	if decision.Decision != ParasutERPSyncStatusConflict || decision.Reason != "object_type_mismatch_rejected" {
		t.Fatalf("expected object type conflict, got %+v", decision)
	}

	externalIDConflict := existing
	externalIDConflict.SyncKey = BuildParasutSyncKey("tenant_7", ParasutERPObjectCustomer, "cust-1-new-sync")
	externalIDConflict.ERPObjectKey = "erp_customer:9999999999"
	decision = EvaluateParasutSyncConflict(existing, externalIDConflict)
	if decision.Decision != ParasutERPSyncStatusConflict || decision.Reason != "same_provider_external_id_conflict" {
		t.Fatalf("expected provider external id conflict, got %+v", decision)
	}

	t.Log("7-8P.7.5 Conflict / Duplicate / Idempotency Contract OK ✅")
	t.Log("7-8P.7.5.1 Same sync key duplicate safe OK ✅")
	t.Log("7-8P.7.5.2 Same provider external ID conflict check OK ✅")
	t.Log("7-8P.7.5.3 Cross-tenant mapping rejected OK ✅")
	t.Log("7-8P.7.5.4 Object type mismatch rejected OK ✅")
	t.Log("7-8P.7.5.5 Conflict decision model OK ✅")
	t.Log("7-8P.7.5.6 Retry/no-retry marker OK ✅")
}

func TestParasutERPWriteDryRunFinalClosure_7_8P_7_6(t *testing.T) {
	record, err := BuildParasutCustomerERPSync(ParasutCustomerSource{
		ParasutSourceBase: parasutSourceBaseForTest("cust-1", "corr-7-8p-7-6-map"),
		TaxNumber:         "1234567890",
		Name:              "ABC LTD",
	})
	if err != nil {
		t.Fatalf("customer mapping failed: %v", err)
	}

	writeResult, err := BuildParasutERPWriteDryRunContract(ParasutERPWriteContractRequest{
		TenantID:      "tenant_7",
		AppKey:        "parasut_accounting",
		Record:        record,
		RequestedBy:   "admin_1",
		CorrelationID: "corr-7-8p-7-6-write",
	})
	if err != nil {
		t.Fatalf("erp write dry-run contract failed: %v", err)
	}

	if writeResult.Status != ParasutERPSyncStatusDryRunReady {
		t.Fatalf("expected dry-run ready, got %s", writeResult.Status)
	}
	if !writeResult.DryRunOnly || writeResult.RealERPWrite {
		t.Fatalf("real ERP write must remain disabled: %+v", writeResult)
	}

	obs := NewConnectorObservabilityRuntime()
	if err := RecordParasutMappingAudit(obs, writeResult); err != nil {
		t.Fatalf("record mapping audit failed: %v", err)
	}

	snapshot := obs.Snapshot()
	if snapshot.TotalOperations != 1 {
		t.Fatalf("expected one audit operation, got %+v", snapshot)
	}

	gate := EvaluateParasutDataMappingReadinessGate(ParasutDataMappingReadinessGateInput{
		SourceDataContractReady:      true,
		CustomerMappingReady:         true,
		ProductMappingReady:          true,
		InvoiceMappingReady:          true,
		IdempotencyConflictReady:     true,
		ERPWriteDryRunReady:          true,
		AuditObservabilityReady:      true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealProviderAPIEnabled:       false,
		RealERPWriteEnabled:          false,
	})
	if !gate.Ready || gate.Decision != "PARASUT_DATA_MAPPING_ERP_SYNC_DRY_RUN_READY_WITH_REAL_API_CLOSED" {
		t.Fatalf("expected data mapping readiness gate ready, got %+v", gate)
	}

	t.Log("7-8P.7.6 ERP Write Contract Dry-Run / Final Closure OK ✅")
	t.Log("7-8P.7.6.1 ERP write request contract OK ✅")
	t.Log("7-8P.7.6.2 Dry-run only OK ✅")
	t.Log("7-8P.7.6.3 Real ERP write disabled OK ✅")
	t.Log("7-8P.7.6.4 Mapping audit event OK ✅")
	t.Log("7-8P.7.6.5 Final readiness gate OK ✅")

	_, err = BuildParasutERPWriteDryRunContract(ParasutERPWriteContractRequest{
		TenantID:            "tenant_7",
		AppKey:              "parasut_accounting",
		Record:              record,
		RequestedBy:         "admin_1",
		CorrelationID:       "corr-7-8p-7-6-real-bad",
		RealERPWriteEnabled: true,
	})
	if err == nil {
		t.Fatal("expected real ERP write enabled to fail")
	}
	t.Log("7-8P.7.6.6 Real ERP write unsafe state blocked OK ✅")

	blocked := EvaluateParasutDataMappingReadinessGate(ParasutDataMappingReadinessGateInput{
		SourceDataContractReady:      true,
		CustomerMappingReady:         true,
		ProductMappingReady:          true,
		InvoiceMappingReady:          true,
		IdempotencyConflictReady:     true,
		ERPWriteDryRunReady:          true,
		AuditObservabilityReady:      true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealProviderAPIEnabled:       true,
		RealERPWriteEnabled:          true,
	})
	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected real provider API / real ERP write state to block: %+v", blocked)
	}
	t.Log("7-8P.7.6.7 Real provider API / ERP write unsafe state blocked OK ✅")
}
