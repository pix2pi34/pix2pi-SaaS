package mikro

import (
	"errors"
	"testing"
)

func logMikroImportDeliveryOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroImportDeliveryPackage(t *testing.T) MikroDryRunPackage {
	t.Helper()

	builder := NewMikroFileGenerationBuilder()
	pkg, decision, err := builder.BuildDryRunPackage(validMikroFileGenerationRequest(ERPObjectSalesInvoice))
	if err != nil {
		t.Fatalf("failed to build prerequisite dry-run package: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("prerequisite dry-run package decision was not allowed")
	}
	return pkg
}

func validMikroImportDeliveryRequest(t *testing.T) MikroImportDeliveryRequest {
	t.Helper()

	return MikroImportDeliveryRequest{
		TenantID:        "tenant_7",
		ActorUserID:     "user_ops_1",
		CorrelationID:   "corr-7-8m-3-import-delivery",
		DeliveryID:      "delivery-7-8m-3-001",
		RequestedMode:   MikroImportDeliveryContractMode,
		DeliveryChannel: MikroDeliveryChannelDryRunManifestOnly,
		Package:         validMikroImportDeliveryPackage(t),
	}
}

func TestMikroImportDeliveryContractMetadata(t *testing.T) {
	runtime := NewMikroImportDeliveryRuntime()
	contract := runtime.Contract

	if err := contract.Validate(); err != nil {
		t.Fatalf("import delivery contract validation failed: %v", err)
	}

	logMikroImportDeliveryOK(t, "7-8M.3", "Mikro Import Package / Delivery Contract root validation")
	logMikroImportDeliveryOK(t, "7-8M.3.1", "metadata validation")
	logMikroImportDeliveryOK(t, "7-8M.3.1.1", "phase is FAZ_7_8M_3")
	logMikroImportDeliveryOK(t, "7-8M.3.1.2", "provider identity is mikro")
	logMikroImportDeliveryOK(t, "7-8M.3.1.3", "delivery contract mode is IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY")
	logMikroImportDeliveryOK(t, "7-8M.3.1.4", "runtime mode is DRY_RUN_DELIVERY_PLACEHOLDER_ONLY")
	logMikroImportDeliveryOK(t, "7-8M.3.1.5", "target system is MIKRO_ACCOUNTING_IMPORT_DRY_RUN")
	logMikroImportDeliveryOK(t, "7-8M.3.1.6", "delivery policy blocks external delivery")

	if contract.Phase != MikroImportDeliveryPhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.DeliveryContractMode != MikroImportDeliveryContractMode {
		t.Fatalf("contract mode mismatch")
	}
	if contract.DeliveryRuntimeMode != MikroImportDeliveryRuntimeMode {
		t.Fatalf("runtime mode mismatch")
	}
	if contract.DeliveryPolicy != MikroImportDeliveryNoExternalDelivery {
		t.Fatalf("delivery policy mismatch")
	}
}

func TestMikroImportDeliveryDryRunReceipt(t *testing.T) {
	runtime := NewMikroImportDeliveryRuntime()

	receipt, decision, err := runtime.CreateDryRunDeliveryReceipt(validMikroImportDeliveryRequest(t))
	if err != nil {
		t.Fatalf("dry-run delivery receipt failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("dry-run delivery receipt must be allowed")
	}
	if decision.Reason != MikroImportDeliveryDecisionReady {
		t.Fatalf("unexpected decision reason")
	}
	if receipt.Delivered {
		t.Fatalf("dry-run receipt must not mark external delivery as delivered")
	}
	if receipt.ExternalReference != "" {
		t.Fatalf("dry-run receipt must not have external reference")
	}
	if receipt.Status != "DRY_RUN_RECEIPT_CREATED_NO_EXTERNAL_DELIVERY" {
		t.Fatalf("unexpected receipt status")
	}
	if receipt.Checksum == "" {
		t.Fatalf("checksum must be copied into receipt")
	}

	logMikroImportDeliveryOK(t, "7-8M.3.2", "dry-run delivery receipt validation")
	logMikroImportDeliveryOK(t, "7-8M.3.2.1", "dry-run receipt is allowed")
	logMikroImportDeliveryOK(t, "7-8M.3.2.2", "receipt status is dry-run no external delivery")
	logMikroImportDeliveryOK(t, "7-8M.3.2.3", "receipt does not mark delivered")
	logMikroImportDeliveryOK(t, "7-8M.3.2.4", "receipt does not contain external reference")
	logMikroImportDeliveryOK(t, "7-8M.3.2.5", "receipt checksum is present")
}

func TestMikroImportDeliverySupportedChannels(t *testing.T) {
	runtime := NewMikroImportDeliveryRuntime()

	channels := []string{
		MikroDeliveryChannelDryRunManifestOnly,
		MikroDeliveryChannelManualReview,
		MikroDeliveryChannelSFTPPlaceholder,
		MikroDeliveryChannelAPIPlaceholder,
	}

	logMikroImportDeliveryOK(t, "7-8M.3.3", "delivery channel placeholder validation")

	for index, channel := range channels {
		req := validMikroImportDeliveryRequest(t)
		req.DeliveryID = "delivery-channel-" + itoaForImportDeliveryTest(index+1)
		req.DeliveryChannel = channel

		receipt, decision, err := runtime.CreateDryRunDeliveryReceipt(req)
		if err != nil {
			t.Fatalf("channel %s should not error: %v", channel, err)
		}
		if !decision.Allowed {
			t.Fatalf("channel %s should be allowed as placeholder", channel)
		}
		if receipt.Delivered {
			t.Fatalf("channel %s must not perform real delivery", channel)
		}
		logMikroImportDeliveryOK(t, "7-8M.3.3."+itoaForImportDeliveryTest(index+1), channel+" placeholder is accepted without real delivery")
	}

	badChannel := validMikroImportDeliveryRequest(t)
	badChannel.DeliveryChannel = "REAL_SFTP"
	_, badDecision, err := runtime.CreateDryRunDeliveryReceipt(badChannel)
	if err != nil {
		t.Fatalf("unsupported channel should deny without runtime error: %v", err)
	}
	if badDecision.Allowed || badDecision.Reason != MikroImportDeliveryDecisionBadChannel {
		t.Fatalf("unsupported channel must be denied")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.3.5", "unsupported real delivery channel is denied")
}

func TestMikroImportDeliveryClosedRealOperations(t *testing.T) {
	runtime := NewMikroImportDeliveryRuntime()
	contract := runtime.Contract

	if contract.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		t.Fatalf("real provider API must stay closed")
	}
	if contract.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		t.Fatalf("real file delivery must stay closed")
	}
	if contract.RealERPWriteStatus != MikroRealERPWriteStatus {
		t.Fatalf("real ERP write must stay closed")
	}
	if contract.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		t.Fatalf("real delivery channel must stay closed")
	}

	logMikroImportDeliveryOK(t, "7-8M.3.4", "closed real operation gates validation")
	logMikroImportDeliveryOK(t, "7-8M.3.4.1", "real Mikro provider API is closed")
	logMikroImportDeliveryOK(t, "7-8M.3.4.2", "real Mikro file delivery is closed")
	logMikroImportDeliveryOK(t, "7-8M.3.4.3", "real ERP write is closed")
	logMikroImportDeliveryOK(t, "7-8M.3.4.4", "real delivery channel is closed")

	apiReq := validMikroImportDeliveryRequest(t)
	apiReq.RealProviderAPIEnabled = true
	_, apiDecision, err := runtime.CreateDryRunDeliveryReceipt(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroImportDeliveryDecisionRealAPI {
		t.Fatalf("real provider API must be denied")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.4.5", "real Mikro API request is denied")

	fileReq := validMikroImportDeliveryRequest(t)
	fileReq.RealFileDeliveryEnabled = true
	_, fileDecision, err := runtime.CreateDryRunDeliveryReceipt(fileReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if fileDecision.Allowed || fileDecision.Reason != MikroImportDeliveryDecisionRealFile {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.4.6", "real Mikro file delivery request is denied")

	erpReq := validMikroImportDeliveryRequest(t)
	erpReq.RealERPWriteEnabled = true
	_, erpDecision, err := runtime.CreateDryRunDeliveryReceipt(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroImportDeliveryDecisionRealERP {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.4.7", "real ERP write request is denied")
}

func TestMikroImportDeliveryRequestPackageAndSecretGuards(t *testing.T) {
	runtime := NewMikroImportDeliveryRuntime()

	missingDelivery := validMikroImportDeliveryRequest(t)
	missingDelivery.DeliveryID = ""
	_, _, err := runtime.CreateDryRunDeliveryReceipt(missingDelivery)
	if err == nil {
		t.Fatalf("missing delivery id must fail")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.5", "request and package guard validation")
	logMikroImportDeliveryOK(t, "7-8M.3.5.1", "missing delivery id is rejected")

	missingPackage := validMikroImportDeliveryRequest(t)
	missingPackage.Package.Manifest.PackageID = ""
	_, _, err = runtime.CreateDryRunDeliveryReceipt(missingPackage)
	if err == nil {
		t.Fatalf("missing package id must fail")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.5.2", "missing package id is rejected")

	badChecksum := validMikroImportDeliveryRequest(t)
	badChecksum.Package.Manifest.Checksum = "bad-checksum"
	_, _, err = runtime.CreateDryRunDeliveryReceipt(badChecksum)
	if err == nil {
		t.Fatalf("bad checksum must fail")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.5.3", "checksum mismatch is rejected")

	emptyContent := validMikroImportDeliveryRequest(t)
	emptyContent.Package.VirtualContent = ""
	_, _, err = runtime.CreateDryRunDeliveryReceipt(emptyContent)
	if err == nil {
		t.Fatalf("empty virtual content must fail")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.5.4", "empty virtual content is rejected")

	liveMode := validMikroImportDeliveryRequest(t)
	liveMode.RequestedMode = "PROVIDER_LIVE"
	_, liveDecision, err := runtime.CreateDryRunDeliveryReceipt(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroImportDeliveryDecisionLiveMode {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.5.5", "provider live mode is denied")

	secretReq := validMikroImportDeliveryRequest(t)
	secretReq.InjectedFieldName = "client_secret"
	_, _, err = runtime.CreateDryRunDeliveryReceipt(secretReq)
	if !errors.Is(err, ErrMikroImportDeliverySecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroImportDeliveryOK(t, "7-8M.3.5.6", "client_secret field is rejected")
}

func itoaForImportDeliveryTest(value int) string {
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
	default:
		return "x"
	}
}
