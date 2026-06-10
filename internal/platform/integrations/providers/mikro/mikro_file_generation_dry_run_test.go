package mikro

import (
	"errors"
	"strings"
	"testing"
)

func logMikroFileGenerationOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroFileGenerationRequest(objectType string) MikroFileGenerationRequest {
	return MikroFileGenerationRequest{
		TenantID:      "tenant_7",
		ActorUserID:   "user_ops_1",
		CorrelationID: "corr-7-8m-2-file-generation",
		PackageID:     "pkg-7-8m-2-001",
		ERPObjectType: objectType,
		RequestedMode: MikroFileGenerationBuilderMode,
		Records: []MikroDryRunPackageRecord{
			{
				RecordID:      "record-001",
				ERPObjectType: objectType,
				Fields: map[string]string{
					"invoice_id":    "INV-001",
					"customer_id":   "CUST-001",
					"issue_date":    "2026-05-02",
					"net_total":     "10000",
					"tax_total":     "2000",
					"gross_total":   "12000",
					"currency_code": "TRY",
				},
			},
		},
	}
}

func TestMikroFileGenerationContractMetadata(t *testing.T) {
	builder := NewMikroFileGenerationBuilder()
	contract := builder.Contract

	if err := contract.Validate(); err != nil {
		t.Fatalf("file generation contract validation failed: %v", err)
	}
	if err := builder.MappingContract.Validate(); err != nil {
		t.Fatalf("mapping bridge validation failed: %v", err)
	}

	logMikroFileGenerationOK(t, "7-8M.2", "Mikro File Generation Dry-Run Contract root validation")
	logMikroFileGenerationOK(t, "7-8M.2.1", "metadata validation")
	logMikroFileGenerationOK(t, "7-8M.2.1.1", "phase is FAZ_7_8M_2")
	logMikroFileGenerationOK(t, "7-8M.2.1.2", "provider identity is mikro")
	logMikroFileGenerationOK(t, "7-8M.2.1.3", "builder mode is EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY")
	logMikroFileGenerationOK(t, "7-8M.2.1.4", "direction is PIX2PI_TO_MIKRO")
	logMikroFileGenerationOK(t, "7-8M.2.1.5", "target system is MIKRO_ACCOUNTING_IMPORT_DRY_RUN")
	logMikroFileGenerationOK(t, "7-8M.2.1.6", "mapping contract bridge is valid")

	if contract.Phase != MikroFileGenerationPhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.BuilderMode != MikroFileGenerationBuilderMode {
		t.Fatalf("builder mode mismatch")
	}
	if contract.Direction != MikroFileGenerationDirection {
		t.Fatalf("direction mismatch")
	}
	if contract.TargetSystem != MikroFileGenerationTargetSystem {
		t.Fatalf("target system mismatch")
	}
}

func TestMikroFileGenerationDryRunPackageBuild(t *testing.T) {
	builder := NewMikroFileGenerationBuilder()

	pkg, decision, err := builder.BuildDryRunPackage(validMikroFileGenerationRequest(ERPObjectSalesInvoice))
	if err != nil {
		t.Fatalf("dry-run package build failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("dry-run package build must be allowed")
	}
	if decision.Reason != MikroFileGenerationDecisionReady {
		t.Fatalf("unexpected decision reason")
	}
	if decision.MikroObjectType != MikroObjectSatisFaturasi {
		t.Fatalf("sales invoice must map to satis faturasi")
	}
	if pkg.Manifest.RecordCount != 1 {
		t.Fatalf("record count mismatch")
	}
	if pkg.Manifest.Checksum == "" || len(pkg.Manifest.Checksum) != 64 {
		t.Fatalf("sha256 checksum must be populated")
	}
	if pkg.Manifest.VirtualFileName == "" || !strings.HasSuffix(pkg.Manifest.VirtualFileName, MikroDryRunVirtualExtension) {
		t.Fatalf("virtual file name must use dry-run extension")
	}
	if !strings.Contains(pkg.VirtualContent, "DELIVERY_POLICY="+MikroDryRunNoDeliveryPolicy) {
		t.Fatalf("virtual content must declare no delivery policy")
	}

	logMikroFileGenerationOK(t, "7-8M.2.2", "dry-run package builder validation")
	logMikroFileGenerationOK(t, "7-8M.2.2.1", "SALES_INVOICE dry-run package is allowed")
	logMikroFileGenerationOK(t, "7-8M.2.2.2", "SALES_INVOICE maps to SATIS_FATURASI")
	logMikroFileGenerationOK(t, "7-8M.2.2.3", "virtual filename is generated")
	logMikroFileGenerationOK(t, "7-8M.2.2.4", "SHA256 checksum is generated")
	logMikroFileGenerationOK(t, "7-8M.2.2.5", "manifest record count is populated")
	logMikroFileGenerationOK(t, "7-8M.2.2.6", "virtual content declares no delivery policy")
}

func TestMikroFileGenerationSupportedObjects(t *testing.T) {
	builder := NewMikroFileGenerationBuilder()

	objects := []string{
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

	logMikroFileGenerationOK(t, "7-8M.2.3", "supported package object coverage validation")

	for index, objectType := range objects {
		req := validMikroFileGenerationRequest(objectType)
		req.Records = []MikroDryRunPackageRecord{
			{
				RecordID:      "record-" + itoaForFileGenerationTest(index+1),
				ERPObjectType: objectType,
				Fields: map[string]string{
					"tenant_id": "tenant_7",
					"object_id": objectType + "-001",
				},
			},
		}

		pkg, decision, err := builder.BuildDryRunPackage(req)
		if err != nil {
			t.Fatalf("package build failed for %s: %v", objectType, err)
		}
		if !decision.Allowed {
			t.Fatalf("package build should be allowed for %s", objectType)
		}
		if pkg.Manifest.ERPObjectType != objectType {
			t.Fatalf("manifest object mismatch for %s", objectType)
		}
		logMikroFileGenerationOK(t, "7-8M.2.3."+itoaForFileGenerationTest(index+1), objectType+" package dry-run build exists")
	}
}

func TestMikroFileGenerationClosedRealOperations(t *testing.T) {
	builder := NewMikroFileGenerationBuilder()
	contract := builder.Contract

	if contract.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		t.Fatalf("real provider API must stay closed")
	}
	if contract.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		t.Fatalf("real file delivery must stay closed")
	}
	if contract.RealERPWriteStatus != MikroRealERPWriteStatus {
		t.Fatalf("real ERP write must stay closed")
	}

	logMikroFileGenerationOK(t, "7-8M.2.4", "closed real operation gates validation")
	logMikroFileGenerationOK(t, "7-8M.2.4.1", "real Mikro provider API is closed")
	logMikroFileGenerationOK(t, "7-8M.2.4.2", "real Mikro file delivery is closed")
	logMikroFileGenerationOK(t, "7-8M.2.4.3", "real ERP write is closed")

	apiReq := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	apiReq.RealProviderAPIEnabled = true
	_, apiDecision, err := builder.BuildDryRunPackage(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroFileGenerationDecisionRealAPIClosed {
		t.Fatalf("real provider API must be denied")
	}
	logMikroFileGenerationOK(t, "7-8M.2.4.4", "real Mikro API request is denied")

	deliveryReq := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	deliveryReq.RealFileDeliveryEnabled = true
	_, deliveryDecision, err := builder.BuildDryRunPackage(deliveryReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if deliveryDecision.Allowed || deliveryDecision.Reason != MikroFileGenerationDecisionFileDeliveryStop {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroFileGenerationOK(t, "7-8M.2.4.5", "real Mikro file delivery request is denied")

	erpReq := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	erpReq.RealERPWriteEnabled = true
	_, erpDecision, err := builder.BuildDryRunPackage(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroFileGenerationDecisionERPWriteClosed {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroFileGenerationOK(t, "7-8M.2.4.6", "real ERP write request is denied")
}

func TestMikroFileGenerationRequestAndSecretGuards(t *testing.T) {
	builder := NewMikroFileGenerationBuilder()

	missingPackage := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	missingPackage.PackageID = ""
	_, _, err := builder.BuildDryRunPackage(missingPackage)
	if err == nil {
		t.Fatalf("missing package id must fail")
	}
	logMikroFileGenerationOK(t, "7-8M.2.5", "request guard validation")
	logMikroFileGenerationOK(t, "7-8M.2.5.1", "missing package id is rejected")

	emptyRecords := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	emptyRecords.Records = nil
	_, _, err = builder.BuildDryRunPackage(emptyRecords)
	if err == nil {
		t.Fatalf("empty records must fail")
	}
	logMikroFileGenerationOK(t, "7-8M.2.5.2", "empty package records are rejected")

	unsupported := validMikroFileGenerationRequest("UNKNOWN_OBJECT")
	_, unsupportedDecision, err := builder.BuildDryRunPackage(unsupported)
	if err != nil {
		t.Fatalf("unsupported object should deny without runtime error: %v", err)
	}
	if unsupportedDecision.Allowed || unsupportedDecision.Reason != MikroFileGenerationDecisionUnsupported {
		t.Fatalf("unsupported object must be denied")
	}
	logMikroFileGenerationOK(t, "7-8M.2.5.3", "unsupported ERP object is denied")

	liveMode := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	liveMode.RequestedMode = "PROVIDER_LIVE"
	_, liveDecision, err := builder.BuildDryRunPackage(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroFileGenerationDecisionLiveModeClosed {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroFileGenerationOK(t, "7-8M.2.5.4", "provider live mode is denied")

	secretReq := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	secretReq.InjectedFieldName = "client_secret"
	_, _, err = builder.BuildDryRunPackage(secretReq)
	if !errors.Is(err, ErrMikroFileGenerationSecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroFileGenerationOK(t, "7-8M.2.5.5", "client_secret field is rejected")

	tokenRecord := validMikroFileGenerationRequest(ERPObjectSalesInvoice)
	tokenRecord.Records[0].Fields["access_token"] = "forbidden"
	_, _, err = builder.BuildDryRunPackage(tokenRecord)
	if !errors.Is(err, ErrMikroFileGenerationSecretForbidden) {
		t.Fatalf("access_token record field must be forbidden")
	}
	logMikroFileGenerationOK(t, "7-8M.2.5.6", "access_token record field is rejected")
}

func itoaForFileGenerationTest(value int) string {
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
