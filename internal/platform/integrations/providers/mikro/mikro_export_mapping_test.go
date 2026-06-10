package mikro

import (
	"errors"
	"testing"
)

func logMikroExportMappingOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroExportMappingRequest(objectType string) MikroExportMappingRequest {
	return MikroExportMappingRequest{
		TenantID:      "tenant_7",
		ActorUserID:   "user_ops_1",
		CorrelationID: "corr-7-8m-1-export-mapping",
		ERPObjectType: objectType,
		RequestedMode: MikroExportMappingMode,
	}
}

func TestMikroExportMappingContractMetadata(t *testing.T) {
	contract := NewMikroExportMappingContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("mapping contract validation failed: %v", err)
	}

	logMikroExportMappingOK(t, "7-8M.1", "Mikro Export Mapping / ERP Object Contract root validation")
	logMikroExportMappingOK(t, "7-8M.1.1", "metadata validation")
	logMikroExportMappingOK(t, "7-8M.1.1.1", "phase is FAZ_7_8M_1")
	logMikroExportMappingOK(t, "7-8M.1.1.2", "provider identity is mikro")
	logMikroExportMappingOK(t, "7-8M.1.1.3", "mapping mode is ERP_OBJECT_EXPORT_MAPPING_CONTRACT_ONLY")
	logMikroExportMappingOK(t, "7-8M.1.1.4", "direction is PIX2PI_TO_MIKRO")
	logMikroExportMappingOK(t, "7-8M.1.1.5", "target system is MIKRO_ACCOUNTING_IMPORT_DRY_RUN")

	if contract.Phase != MikroExportMappingPhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.MappingMode != MikroExportMappingMode {
		t.Fatalf("mapping mode mismatch")
	}
	if contract.Direction != MikroExportMappingDirection {
		t.Fatalf("direction mismatch")
	}
	if contract.TargetSystem != MikroExportMappingTargetSystem {
		t.Fatalf("target system mismatch")
	}
}

func TestMikroExportMappingObjectCoverage(t *testing.T) {
	contract := NewMikroExportMappingContract()

	requiredObjects := []string{
		ERPObjectCustomer,
		ERPObjectVendor,
		ERPObjectProduct,
		ERPObjectServiceItem,
		ERPObjectSalesInvoice,
		ERPObjectPurchaseInvoice,
		ERPObjectStockMovement,
		ERPObjectAccountingVoucher,
		ERPObjectTaxLine,
	}

	logMikroExportMappingOK(t, "7-8M.1.2", "ERP object coverage validation")

	for index, objectType := range requiredObjects {
		if !contract.SupportsERPObject(objectType) {
			t.Fatalf("expected object mapping missing: %s", objectType)
		}
		mapping, ok := contract.MappingFor(objectType)
		if !ok {
			t.Fatalf("mapping not found: %s", objectType)
		}
		if mapping.Direction != MikroExportMappingDirection {
			t.Fatalf("mapping direction mismatch for %s", objectType)
		}
		if len(mapping.Fields) == 0 {
			t.Fatalf("mapping fields missing for %s", objectType)
		}
		logMikroExportMappingOK(t, "7-8M.1.2."+itoaForTest(index+1), objectType+" mapping exists")
	}
}

func TestMikroExportMappingDecisionRuntimeAndGuards(t *testing.T) {
	contract := NewMikroExportMappingContract()

	decision, err := contract.Evaluate(validMikroExportMappingRequest(ERPObjectSalesInvoice))
	if err != nil {
		t.Fatalf("mapping decision failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("sales invoice mapping must be allowed in dry-run contract mode")
	}
	if decision.Reason != MikroExportMappingDecisionReady {
		t.Fatalf("unexpected decision reason")
	}
	if decision.MikroObjectType != MikroObjectSatisFaturasi {
		t.Fatalf("sales invoice must map to Mikro satis faturasi")
	}
	if decision.FieldCount == 0 || decision.RequiredFieldCount == 0 {
		t.Fatalf("field counts must be populated")
	}

	logMikroExportMappingOK(t, "7-8M.1.3", "mapping decision runtime validation")
	logMikroExportMappingOK(t, "7-8M.1.3.1", "SALES_INVOICE dry-run mapping is allowed")
	logMikroExportMappingOK(t, "7-8M.1.3.2", "SALES_INVOICE maps to SATIS_FATURASI")
	logMikroExportMappingOK(t, "7-8M.1.3.3", "field count is populated")
	logMikroExportMappingOK(t, "7-8M.1.3.4", "required field count is populated")

	missingTenant := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	missingTenant.TenantID = ""
	_, err = contract.Evaluate(missingTenant)
	if err == nil {
		t.Fatalf("missing tenant must fail")
	}
	logMikroExportMappingOK(t, "7-8M.1.3.5", "missing tenant is rejected")

	unsupported := validMikroExportMappingRequest("UNKNOWN_OBJECT")
	unsupportedDecision, err := contract.Evaluate(unsupported)
	if err != nil {
		t.Fatalf("unsupported object should deny without runtime error: %v", err)
	}
	if unsupportedDecision.Allowed || unsupportedDecision.Reason != MikroExportMappingDecisionUnsupported {
		t.Fatalf("unsupported object must be denied")
	}
	logMikroExportMappingOK(t, "7-8M.1.3.6", "unsupported ERP object is denied")

	liveMode := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	liveMode.RequestedMode = "PROVIDER_LIVE"
	liveDecision, err := contract.Evaluate(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroExportMappingDecisionLiveModeClosed {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroExportMappingOK(t, "7-8M.1.3.7", "provider live mode is denied")
}

func TestMikroExportMappingClosedRealOperations(t *testing.T) {
	contract := NewMikroExportMappingContract()

	if contract.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		t.Fatalf("real provider API must stay closed")
	}
	if contract.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		t.Fatalf("real file delivery must stay closed")
	}
	if contract.RealERPWriteStatus != MikroRealERPWriteStatus {
		t.Fatalf("real ERP write must stay closed")
	}

	logMikroExportMappingOK(t, "7-8M.1.4", "closed real operation gates validation")
	logMikroExportMappingOK(t, "7-8M.1.4.1", "real Mikro provider API is closed")
	logMikroExportMappingOK(t, "7-8M.1.4.2", "real Mikro file delivery is closed")
	logMikroExportMappingOK(t, "7-8M.1.4.3", "real ERP write is closed")

	apiReq := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	apiReq.RealProviderAPIEnabled = true
	apiDecision, err := contract.Evaluate(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroExportMappingDecisionRealAPIClosed {
		t.Fatalf("real provider API must be denied")
	}
	logMikroExportMappingOK(t, "7-8M.1.4.4", "real Mikro API request is denied")

	deliveryReq := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	deliveryReq.RealFileDeliveryEnabled = true
	deliveryDecision, err := contract.Evaluate(deliveryReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if deliveryDecision.Allowed || deliveryDecision.Reason != MikroExportMappingDecisionFileDeliveryStop {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroExportMappingOK(t, "7-8M.1.4.5", "real Mikro file delivery request is denied")

	erpReq := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	erpReq.RealERPWriteEnabled = true
	erpDecision, err := contract.Evaluate(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroExportMappingDecisionERPWriteClosed {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroExportMappingOK(t, "7-8M.1.4.6", "real ERP write request is denied")
}

func TestMikroExportMappingFieldAndSecretGuards(t *testing.T) {
	contract := NewMikroExportMappingContract()

	invoiceMapping, ok := contract.MappingFor(ERPObjectSalesInvoice)
	if !ok {
		t.Fatalf("sales invoice mapping missing")
	}
	if !fieldMappingExists(invoiceMapping, "invoice_id", "belge_no") {
		t.Fatalf("invoice_id -> belge_no mapping missing")
	}
	if !fieldMappingExists(invoiceMapping, "customer_id", "cari_kodu") {
		t.Fatalf("customer_id -> cari_kodu mapping missing")
	}
	if !fieldMappingExists(invoiceMapping, "tax_total", "kdv_tutari") {
		t.Fatalf("tax_total -> kdv_tutari mapping missing")
	}
	if !fieldMappingExists(invoiceMapping, "gross_total", "genel_toplam") {
		t.Fatalf("gross_total -> genel_toplam mapping missing")
	}

	logMikroExportMappingOK(t, "7-8M.1.5", "field mapping validation")
	logMikroExportMappingOK(t, "7-8M.1.5.1", "invoice_id maps to belge_no")
	logMikroExportMappingOK(t, "7-8M.1.5.2", "customer_id maps to cari_kodu")
	logMikroExportMappingOK(t, "7-8M.1.5.3", "tax_total maps to kdv_tutari")
	logMikroExportMappingOK(t, "7-8M.1.5.4", "gross_total maps to genel_toplam")

	secretReq := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	secretReq.InjectedFieldName = "client_secret"
	_, err := contract.Evaluate(secretReq)
	if !errors.Is(err, ErrMikroExportMappingSecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroExportMappingOK(t, "7-8M.1.5.5", "client_secret mapping field is rejected")

	tokenReq := validMikroExportMappingRequest(ERPObjectSalesInvoice)
	tokenReq.InjectedFieldName = "access_token"
	_, err = contract.Evaluate(tokenReq)
	if !errors.Is(err, ErrMikroExportMappingSecretForbidden) {
		t.Fatalf("access_token field must be forbidden")
	}
	logMikroExportMappingOK(t, "7-8M.1.5.6", "access_token mapping field is rejected")
}

func fieldMappingExists(mapping MikroObjectMapping, source string, target string) bool {
	for _, field := range mapping.Fields {
		if field.SourceField == source && field.TargetField == target {
			return true
		}
	}
	return false
}

func itoaForTest(value int) string {
	switch value {
	case 1:
		return "1"
	case 2:
		return "2"
	case 3:
		return "3"
	case 4:
		return "4"
	case 5:
		return "5"
	case 6:
		return "6"
	case 7:
		return "7"
	case 8:
		return "8"
	case 9:
		return "9"
	default:
		return "x"
	}
}
