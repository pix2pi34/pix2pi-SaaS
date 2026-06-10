package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	MikroImportDeliveryPhase          = "FAZ_7_8M_3"
	MikroImportDeliveryModule         = "MIKRO_IMPORT_PACKAGE_DELIVERY_CONTRACT"
	MikroImportDeliveryModuleName     = "Mikro Import Package / Delivery Contract Readiness"
	MikroImportDeliveryContractMode   = "IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY"
	MikroImportDeliveryRuntimeMode    = "DRY_RUN_DELIVERY_PLACEHOLDER_ONLY"
	MikroImportDeliveryDirection      = "PIX2PI_TO_MIKRO"
	MikroImportDeliverySourceSystem   = "PIX2PI_ERP"
	MikroImportDeliveryTargetSystem   = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroImportDeliveryGate           = "READY_AFTER_TEST_AND_AUDIT_PASS"
	MikroImportDeliveryReceiptPolicy  = "DRY_RUN_RECEIPT_ONLY"
	MikroImportDeliveryChecksumPolicy = "REQUIRED"

	MikroDeliveryChannelDryRunManifestOnly  = "DRY_RUN_MANIFEST_ONLY"
	MikroDeliveryChannelManualReview        = "MANUAL_REVIEW_PLACEHOLDER"
	MikroDeliveryChannelSFTPPlaceholder     = "SFTP_PLACEHOLDER"
	MikroDeliveryChannelAPIPlaceholder      = "API_PLACEHOLDER"
	MikroRealDeliveryChannelStatus          = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	MikroImportDeliveryNoExternalDelivery   = "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE"
	MikroImportDeliveryDecisionReady        = "MIKRO_IMPORT_DELIVERY_DRY_RUN_RECEIPT_READY"
	MikroImportDeliveryDecisionBadChannel   = "MIKRO_IMPORT_DELIVERY_CHANNEL_UNSUPPORTED"
	MikroImportDeliveryDecisionBadPackage   = "MIKRO_IMPORT_DELIVERY_PACKAGE_INVALID"
	MikroImportDeliveryDecisionSecretDenied = "MIKRO_IMPORT_DELIVERY_SECRET_FIELD_FORBIDDEN"
	MikroImportDeliveryDecisionRealAPI      = "MIKRO_IMPORT_DELIVERY_REAL_PROVIDER_API_CLOSED"
	MikroImportDeliveryDecisionRealFile     = "MIKRO_IMPORT_DELIVERY_REAL_FILE_DELIVERY_CLOSED"
	MikroImportDeliveryDecisionRealERP      = "MIKRO_IMPORT_DELIVERY_REAL_ERP_WRITE_CLOSED"
	MikroImportDeliveryDecisionLiveMode     = "MIKRO_IMPORT_DELIVERY_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroImportDeliveryContract = errors.New("invalid mikro import delivery contract")
	ErrInvalidMikroImportDeliveryRequest  = errors.New("invalid mikro import delivery request")
	ErrMikroImportDeliverySecretForbidden = errors.New("mikro import delivery secret field is forbidden")
)

type MikroImportDeliveryContract struct {
	Phase                     string
	Module                    string
	ModuleName                string
	ProviderID                string
	ProviderName              string
	ProviderCategory          string
	DeliveryContractMode      string
	DeliveryRuntimeMode       string
	Direction                 string
	SourceSystem              string
	TargetSystem              string
	DeliveryGate              string
	DeliveryPolicy            string
	ReceiptPolicy             string
	ChecksumVerification      string
	RealProviderAPIStatus     string
	RealFileDeliveryStatus    string
	RealERPWriteStatus        string
	RealDeliveryChannelStatus string
	SupportedChannels         []string
	RequiredContextFields     []string
	ForbiddenFieldLabels      []string
}

type MikroImportDeliveryRequest struct {
	TenantID                string
	ActorUserID             string
	CorrelationID           string
	DeliveryID              string
	RequestedMode           string
	DeliveryChannel         string
	InjectedFieldName       string
	Package                 MikroDryRunPackage
	RealProviderAPIEnabled  bool
	RealFileDeliveryEnabled bool
	RealERPWriteEnabled     bool
	RealDeliveryEnabled     bool
}

type MikroImportDeliveryReceipt struct {
	Phase             string
	Module            string
	ProviderID        string
	ProviderName      string
	TenantID          string
	CorrelationID     string
	DeliveryID        string
	PackageID         string
	ERPObjectType     string
	MikroObjectType   string
	DeliveryChannel   string
	DeliveryPolicy    string
	ReceiptPolicy     string
	VirtualFileName   string
	ChecksumAlgorithm string
	Checksum          string
	RecordCount       int
	Delivered         bool
	ExternalReference string
	Status            string
}

type MikroImportDeliveryDecision struct {
	Allowed                   bool
	Phase                     string
	Module                    string
	ProviderID                string
	ProviderName              string
	DeliveryID                string
	PackageID                 string
	ERPObjectType             string
	MikroObjectType           string
	DeliveryChannel           string
	DeliveryContractMode      string
	DeliveryRuntimeMode       string
	Direction                 string
	TargetSystem              string
	Reason                    string
	RealProviderAPIStatus     string
	RealFileDeliveryStatus    string
	RealERPWriteStatus        string
	RealDeliveryChannelStatus string
	DeliveryGate              string
	ReceiptStatus             string
	AuditFields               map[string]string
}

type MikroImportDeliveryRuntime struct {
	Contract MikroImportDeliveryContract
}

func NewMikroImportDeliveryContract() MikroImportDeliveryContract {
	return MikroImportDeliveryContract{
		Phase:                     MikroImportDeliveryPhase,
		Module:                    MikroImportDeliveryModule,
		ModuleName:                MikroImportDeliveryModuleName,
		ProviderID:                ProviderID,
		ProviderName:              ProviderName,
		ProviderCategory:          ProviderCategory,
		DeliveryContractMode:      MikroImportDeliveryContractMode,
		DeliveryRuntimeMode:       MikroImportDeliveryRuntimeMode,
		Direction:                 MikroImportDeliveryDirection,
		SourceSystem:              MikroImportDeliverySourceSystem,
		TargetSystem:              MikroImportDeliveryTargetSystem,
		DeliveryGate:              MikroImportDeliveryGate,
		DeliveryPolicy:            MikroImportDeliveryNoExternalDelivery,
		ReceiptPolicy:             MikroImportDeliveryReceiptPolicy,
		ChecksumVerification:      MikroImportDeliveryChecksumPolicy,
		RealProviderAPIStatus:     MikroRealProviderAPIStatus,
		RealFileDeliveryStatus:    MikroRealFileDeliveryStatus,
		RealERPWriteStatus:        MikroRealERPWriteStatus,
		RealDeliveryChannelStatus: MikroRealDeliveryChannelStatus,
		SupportedChannels: []string{
			MikroDeliveryChannelDryRunManifestOnly,
			MikroDeliveryChannelManualReview,
			MikroDeliveryChannelSFTPPlaceholder,
			MikroDeliveryChannelAPIPlaceholder,
		},
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"delivery_id",
			"package_id",
		},
		ForbiddenFieldLabels: []string{
			"client_secret",
			"access_token",
			"refresh_token",
			"password",
			"real_provider_endpoint",
			"real_delivery_endpoint",
			"secret",
			"token",
		},
	}
}

func NewMikroImportDeliveryRuntime() MikroImportDeliveryRuntime {
	return MikroImportDeliveryRuntime{
		Contract: NewMikroImportDeliveryContract(),
	}
}

func (c MikroImportDeliveryContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroImportDeliveryPhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroImportDeliveryContract, MikroImportDeliveryPhase)
	}
	if strings.TrimSpace(c.Module) != MikroImportDeliveryModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroImportDeliveryContract, MikroImportDeliveryModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroImportDeliveryContract, ProviderID)
	}
	if strings.TrimSpace(c.DeliveryContractMode) != MikroImportDeliveryContractMode {
		return fmt.Errorf("%w: delivery contract mode mismatch", ErrInvalidMikroImportDeliveryContract)
	}
	if strings.TrimSpace(c.DeliveryRuntimeMode) != MikroImportDeliveryRuntimeMode {
		return fmt.Errorf("%w: delivery runtime mode mismatch", ErrInvalidMikroImportDeliveryContract)
	}
	if strings.TrimSpace(c.Direction) != MikroImportDeliveryDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroImportDeliveryContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroImportDeliveryTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroImportDeliveryContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroImportDeliveryContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroImportDeliveryContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroImportDeliveryContract)
	}
	if c.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		return fmt.Errorf("%w: real delivery channel must stay closed", ErrInvalidMikroImportDeliveryContract)
	}
	if c.DeliveryPolicy != MikroImportDeliveryNoExternalDelivery {
		return fmt.Errorf("%w: delivery policy must block external delivery", ErrInvalidMikroImportDeliveryContract)
	}
	if len(c.SupportedChannels) < 4 {
		return fmt.Errorf("%w: supported dry-run channels are incomplete", ErrInvalidMikroImportDeliveryContract)
	}
	if len(c.RequiredContextFields) < 5 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroImportDeliveryContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden fields are required", ErrInvalidMikroImportDeliveryContract)
	}
	return nil
}

func (c MikroImportDeliveryContract) SupportsChannel(channel string) bool {
	normalized := normalizeExportMappingValue(channel)
	for _, supported := range c.SupportedChannels {
		if supported == normalized {
			return true
		}
	}
	return false
}

func (r MikroImportDeliveryRuntime) CreateDryRunDeliveryReceipt(req MikroImportDeliveryRequest) (MikroImportDeliveryReceipt, MikroImportDeliveryDecision, error) {
	receipt := MikroImportDeliveryReceipt{}
	packageID := strings.TrimSpace(req.Package.Manifest.PackageID)

	decision := MikroImportDeliveryDecision{
		Allowed:                   false,
		Phase:                     r.Contract.Phase,
		Module:                    r.Contract.Module,
		ProviderID:                r.Contract.ProviderID,
		ProviderName:              r.Contract.ProviderName,
		DeliveryID:                strings.TrimSpace(req.DeliveryID),
		PackageID:                 packageID,
		ERPObjectType:             normalizeExportMappingValue(req.Package.Manifest.ERPObjectType),
		MikroObjectType:           req.Package.Manifest.MikroObjectType,
		DeliveryChannel:           normalizeExportMappingValue(req.DeliveryChannel),
		DeliveryContractMode:      r.Contract.DeliveryContractMode,
		DeliveryRuntimeMode:       r.Contract.DeliveryRuntimeMode,
		Direction:                 r.Contract.Direction,
		TargetSystem:              r.Contract.TargetSystem,
		RealProviderAPIStatus:     r.Contract.RealProviderAPIStatus,
		RealFileDeliveryStatus:    r.Contract.RealFileDeliveryStatus,
		RealERPWriteStatus:        r.Contract.RealERPWriteStatus,
		RealDeliveryChannelStatus: r.Contract.RealDeliveryChannelStatus,
		DeliveryGate:              r.Contract.DeliveryGate,
		AuditFields: map[string]string{
			"tenant_id":             strings.TrimSpace(req.TenantID),
			"actor_user_id":         strings.TrimSpace(req.ActorUserID),
			"correlation_id":        strings.TrimSpace(req.CorrelationID),
			"delivery_id":           strings.TrimSpace(req.DeliveryID),
			"package_id":            packageID,
			"provider_id":           r.Contract.ProviderID,
			"phase":                 r.Contract.Phase,
			"delivery_policy":       r.Contract.DeliveryPolicy,
			"delivery_runtime_mode": r.Contract.DeliveryRuntimeMode,
			"target_system":         r.Contract.TargetSystem,
		},
	}

	if err := r.Contract.Validate(); err != nil {
		return receipt, decision, err
	}
	if err := validateMikroImportDeliveryRequest(req); err != nil {
		decision.Reason = MikroImportDeliveryDecisionBadPackage
		return receipt, decision, err
	}
	if containsForbiddenMappingField(req.InjectedFieldName) {
		decision.Reason = MikroImportDeliveryDecisionSecretDenied
		return receipt, decision, ErrMikroImportDeliverySecretForbidden
	}
	if normalizeExportMappingValue(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroImportDeliveryDecisionLiveMode
		return receipt, decision, nil
	}
	if req.RealProviderAPIEnabled {
		decision.Reason = MikroImportDeliveryDecisionRealAPI
		return receipt, decision, nil
	}
	if req.RealFileDeliveryEnabled || req.RealDeliveryEnabled {
		decision.Reason = MikroImportDeliveryDecisionRealFile
		return receipt, decision, nil
	}
	if req.RealERPWriteEnabled {
		decision.Reason = MikroImportDeliveryDecisionRealERP
		return receipt, decision, nil
	}
	if !r.Contract.SupportsChannel(req.DeliveryChannel) {
		decision.Reason = MikroImportDeliveryDecisionBadChannel
		return receipt, decision, nil
	}
	if err := verifyMikroDryRunPackage(req.Package); err != nil {
		decision.Reason = MikroImportDeliveryDecisionBadPackage
		return receipt, decision, err
	}

	receipt = MikroImportDeliveryReceipt{
		Phase:             r.Contract.Phase,
		Module:            r.Contract.Module,
		ProviderID:        r.Contract.ProviderID,
		ProviderName:      r.Contract.ProviderName,
		TenantID:          strings.TrimSpace(req.TenantID),
		CorrelationID:     strings.TrimSpace(req.CorrelationID),
		DeliveryID:        strings.TrimSpace(req.DeliveryID),
		PackageID:         req.Package.Manifest.PackageID,
		ERPObjectType:     req.Package.Manifest.ERPObjectType,
		MikroObjectType:   req.Package.Manifest.MikroObjectType,
		DeliveryChannel:   normalizeExportMappingValue(req.DeliveryChannel),
		DeliveryPolicy:    r.Contract.DeliveryPolicy,
		ReceiptPolicy:     r.Contract.ReceiptPolicy,
		VirtualFileName:   req.Package.Manifest.VirtualFileName,
		ChecksumAlgorithm: req.Package.Manifest.ChecksumAlgorithm,
		Checksum:          req.Package.Manifest.Checksum,
		RecordCount:       req.Package.Manifest.RecordCount,
		Delivered:         false,
		ExternalReference: "",
		Status:            "DRY_RUN_RECEIPT_CREATED_NO_EXTERNAL_DELIVERY",
	}

	decision.Allowed = true
	decision.Reason = MikroImportDeliveryDecisionReady
	decision.ReceiptStatus = receipt.Status
	return receipt, decision, nil
}

func validateMikroImportDeliveryRequest(req MikroImportDeliveryRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(req.DeliveryID) == "" {
		return fmt.Errorf("%w: delivery_id is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(req.Package.Manifest.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(req.DeliveryChannel) == "" {
		return fmt.Errorf("%w: delivery_channel is required", ErrInvalidMikroImportDeliveryRequest)
	}
	return nil
}

func verifyMikroDryRunPackage(pkg MikroDryRunPackage) error {
	if strings.TrimSpace(pkg.VirtualContent) == "" {
		return fmt.Errorf("%w: virtual content is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(pkg.Manifest.PackageID) == "" {
		return fmt.Errorf("%w: manifest package_id is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(pkg.Manifest.VirtualFileName) == "" {
		return fmt.Errorf("%w: manifest virtual file name is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if strings.TrimSpace(pkg.Manifest.Checksum) == "" {
		return fmt.Errorf("%w: manifest checksum is required", ErrInvalidMikroImportDeliveryRequest)
	}
	if pkg.Manifest.ChecksumAlgorithm != MikroDryRunChecksumSHA256 {
		return fmt.Errorf("%w: checksum algorithm must be SHA256", ErrInvalidMikroImportDeliveryRequest)
	}
	if calculateMikroDryRunChecksum(pkg.VirtualContent) != pkg.Manifest.Checksum {
		return fmt.Errorf("%w: package checksum mismatch", ErrInvalidMikroImportDeliveryRequest)
	}
	if pkg.Manifest.DeliveryPolicy != MikroDryRunNoDeliveryPolicy {
		return fmt.Errorf("%w: package delivery policy must block external delivery", ErrInvalidMikroImportDeliveryRequest)
	}
	if !strings.HasSuffix(pkg.Manifest.VirtualFileName, MikroDryRunVirtualExtension) {
		return fmt.Errorf("%w: virtual file extension mismatch", ErrInvalidMikroImportDeliveryRequest)
	}
	if pkg.Manifest.RecordCount <= 0 {
		return fmt.Errorf("%w: manifest record count must be positive", ErrInvalidMikroImportDeliveryRequest)
	}
	return nil
}
