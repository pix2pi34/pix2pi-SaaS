package mikro

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"
	"strings"
)

const (
	MikroFileGenerationPhase        = "FAZ_7_8M_2"
	MikroFileGenerationModule       = "MIKRO_FILE_GENERATION_DRY_RUN_CONTRACT"
	MikroFileGenerationModuleName   = "Mikro File Generation Dry-Run Contract / Export Package Builder Readiness"
	MikroFileGenerationBuilderMode  = "EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY"
	MikroFileGenerationDirection    = "PIX2PI_TO_MIKRO"
	MikroFileGenerationSourceSystem = "PIX2PI_ERP"
	MikroFileGenerationTargetSystem = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroFileGenerationGate         = "READY_AFTER_TEST_AND_AUDIT_PASS"

	MikroDryRunVirtualExtension = ".mikro.dryrun.txt"
	MikroDryRunEncoding         = "UTF-8"
	MikroDryRunLineEnding       = "LF"
	MikroDryRunChecksumSHA256   = "SHA256"
	MikroDryRunNoDeliveryPolicy = "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE"

	MikroFileGenerationDecisionReady            = "MIKRO_FILE_GENERATION_DRY_RUN_PACKAGE_READY"
	MikroFileGenerationDecisionUnsupported      = "MIKRO_FILE_GENERATION_ERP_OBJECT_UNSUPPORTED"
	MikroFileGenerationDecisionSecretForbidden  = "MIKRO_FILE_GENERATION_SECRET_FIELD_FORBIDDEN"
	MikroFileGenerationDecisionRealAPIClosed    = "MIKRO_FILE_GENERATION_REAL_PROVIDER_API_CLOSED"
	MikroFileGenerationDecisionFileDeliveryStop = "MIKRO_FILE_GENERATION_REAL_FILE_DELIVERY_CLOSED"
	MikroFileGenerationDecisionERPWriteClosed   = "MIKRO_FILE_GENERATION_REAL_ERP_WRITE_CLOSED"
	MikroFileGenerationDecisionLiveModeClosed   = "MIKRO_FILE_GENERATION_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroFileGenerationContract = errors.New("invalid mikro file generation dry-run contract")
	ErrInvalidMikroFileGenerationRequest  = errors.New("invalid mikro file generation request")
	ErrMikroFileGenerationSecretForbidden = errors.New("mikro file generation secret field is forbidden")
)

type MikroFileGenerationContract struct {
	Phase                  string
	Module                 string
	ModuleName             string
	ProviderID             string
	ProviderName           string
	ProviderCategory       string
	BuilderMode            string
	Direction              string
	SourceSystem           string
	TargetSystem           string
	PackageGate            string
	VirtualFileExtension   string
	Encoding               string
	LineEnding             string
	ChecksumAlgorithm      string
	RealFileWritePolicy    string
	RealProviderAPIStatus  string
	RealFileDeliveryStatus string
	RealERPWriteStatus     string
	RequiredContextFields  []string
	ForbiddenFieldLabels   []string
	SupportedERPObjects    []string
}

type MikroDryRunPackageRecord struct {
	RecordID      string
	ERPObjectType string
	Fields        map[string]string
}

type MikroFileGenerationRequest struct {
	TenantID                string
	ActorUserID             string
	CorrelationID           string
	PackageID               string
	ERPObjectType           string
	RequestedMode           string
	InjectedFieldName       string
	Records                 []MikroDryRunPackageRecord
	RealProviderAPIEnabled  bool
	RealFileDeliveryEnabled bool
	RealERPWriteEnabled     bool
}

type MikroDryRunPackageManifest struct {
	Phase             string
	Module            string
	ProviderID        string
	ProviderName      string
	TenantID          string
	CorrelationID     string
	PackageID         string
	ERPObjectType     string
	MikroObjectType   string
	Direction         string
	TargetSystem      string
	VirtualFileName   string
	Encoding          string
	LineEnding        string
	ChecksumAlgorithm string
	Checksum          string
	RecordCount       int
	FieldCount        int
	DeliveryPolicy    string
}

type MikroDryRunPackage struct {
	Manifest       MikroDryRunPackageManifest
	VirtualContent string
}

type MikroFileGenerationDecision struct {
	Allowed                bool
	Phase                  string
	Module                 string
	ProviderID             string
	ProviderName           string
	PackageID              string
	ERPObjectType          string
	MikroObjectType        string
	BuilderMode            string
	Direction              string
	TargetSystem           string
	Reason                 string
	RealProviderAPIStatus  string
	RealFileDeliveryStatus string
	RealERPWriteStatus     string
	PackageGate            string
	VirtualFileName        string
	Checksum               string
	RecordCount            int
	AuditFields            map[string]string
}

type MikroFileGenerationBuilder struct {
	Contract        MikroFileGenerationContract
	MappingContract MikroExportMappingContract
}

func NewMikroFileGenerationContract() MikroFileGenerationContract {
	return MikroFileGenerationContract{
		Phase:                  MikroFileGenerationPhase,
		Module:                 MikroFileGenerationModule,
		ModuleName:             MikroFileGenerationModuleName,
		ProviderID:             ProviderID,
		ProviderName:           ProviderName,
		ProviderCategory:       ProviderCategory,
		BuilderMode:            MikroFileGenerationBuilderMode,
		Direction:              MikroFileGenerationDirection,
		SourceSystem:           MikroFileGenerationSourceSystem,
		TargetSystem:           MikroFileGenerationTargetSystem,
		PackageGate:            MikroFileGenerationGate,
		VirtualFileExtension:   MikroDryRunVirtualExtension,
		Encoding:               MikroDryRunEncoding,
		LineEnding:             MikroDryRunLineEnding,
		ChecksumAlgorithm:      MikroDryRunChecksumSHA256,
		RealFileWritePolicy:    MikroDryRunNoDeliveryPolicy,
		RealProviderAPIStatus:  MikroRealProviderAPIStatus,
		RealFileDeliveryStatus: MikroRealFileDeliveryStatus,
		RealERPWriteStatus:     MikroRealERPWriteStatus,
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"package_id",
			"erp_object_type",
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
		SupportedERPObjects: []string{
			ERPObjectCustomer,
			ERPObjectVendor,
			ERPObjectProduct,
			ERPObjectServiceItem,
			ERPObjectSalesInvoice,
			ERPObjectPurchaseInvoice,
			ERPObjectStockMovement,
			ERPObjectAccountingVoucher,
			ERPObjectTaxLine,
		},
	}
}

func NewMikroFileGenerationBuilder() MikroFileGenerationBuilder {
	return MikroFileGenerationBuilder{
		Contract:        NewMikroFileGenerationContract(),
		MappingContract: NewMikroExportMappingContract(),
	}
}

func (c MikroFileGenerationContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroFileGenerationPhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroFileGenerationContract, MikroFileGenerationPhase)
	}
	if strings.TrimSpace(c.Module) != MikroFileGenerationModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroFileGenerationContract, MikroFileGenerationModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroFileGenerationContract, ProviderID)
	}
	if strings.TrimSpace(c.BuilderMode) != MikroFileGenerationBuilderMode {
		return fmt.Errorf("%w: builder mode must be dry-run only", ErrInvalidMikroFileGenerationContract)
	}
	if strings.TrimSpace(c.Direction) != MikroFileGenerationDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroFileGenerationContract)
	}
	if strings.TrimSpace(c.SourceSystem) != MikroFileGenerationSourceSystem {
		return fmt.Errorf("%w: source system must be PIX2PI_ERP", ErrInvalidMikroFileGenerationContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroFileGenerationTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroFileGenerationContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroFileGenerationContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroFileGenerationContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroFileGenerationContract)
	}
	if c.VirtualFileExtension != MikroDryRunVirtualExtension {
		return fmt.Errorf("%w: virtual file extension mismatch", ErrInvalidMikroFileGenerationContract)
	}
	if c.ChecksumAlgorithm != MikroDryRunChecksumSHA256 {
		return fmt.Errorf("%w: checksum algorithm must be SHA256", ErrInvalidMikroFileGenerationContract)
	}
	if len(c.RequiredContextFields) < 5 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroFileGenerationContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden field labels are required", ErrInvalidMikroFileGenerationContract)
	}
	if len(c.SupportedERPObjects) < 9 {
		return fmt.Errorf("%w: supported ERP object coverage is incomplete", ErrInvalidMikroFileGenerationContract)
	}
	return nil
}

func (b MikroFileGenerationBuilder) BuildDryRunPackage(req MikroFileGenerationRequest) (MikroDryRunPackage, MikroFileGenerationDecision, error) {
	pkg := MikroDryRunPackage{}
	decision := MikroFileGenerationDecision{
		Allowed:                false,
		Phase:                  b.Contract.Phase,
		Module:                 b.Contract.Module,
		ProviderID:             b.Contract.ProviderID,
		ProviderName:           b.Contract.ProviderName,
		PackageID:              strings.TrimSpace(req.PackageID),
		ERPObjectType:          normalizeExportMappingValue(req.ERPObjectType),
		BuilderMode:            b.Contract.BuilderMode,
		Direction:              b.Contract.Direction,
		TargetSystem:           b.Contract.TargetSystem,
		RealProviderAPIStatus:  b.Contract.RealProviderAPIStatus,
		RealFileDeliveryStatus: b.Contract.RealFileDeliveryStatus,
		RealERPWriteStatus:     b.Contract.RealERPWriteStatus,
		PackageGate:            b.Contract.PackageGate,
		RecordCount:            len(req.Records),
		AuditFields: map[string]string{
			"tenant_id":       strings.TrimSpace(req.TenantID),
			"actor_user_id":   strings.TrimSpace(req.ActorUserID),
			"correlation_id":  strings.TrimSpace(req.CorrelationID),
			"package_id":      strings.TrimSpace(req.PackageID),
			"provider_id":     b.Contract.ProviderID,
			"phase":           b.Contract.Phase,
			"erp_object_type": normalizeExportMappingValue(req.ERPObjectType),
			"builder_mode":    b.Contract.BuilderMode,
			"package_gate":    b.Contract.PackageGate,
			"source_system":   b.Contract.SourceSystem,
			"target_system":   b.Contract.TargetSystem,
			"delivery_policy": b.Contract.RealFileWritePolicy,
		},
	}

	if err := b.Contract.Validate(); err != nil {
		return pkg, decision, err
	}
	if err := b.MappingContract.Validate(); err != nil {
		return pkg, decision, err
	}
	if err := validateMikroFileGenerationRequest(req); err != nil {
		return pkg, decision, err
	}
	if containsForbiddenMappingField(req.InjectedFieldName) {
		decision.Reason = MikroFileGenerationDecisionSecretForbidden
		return pkg, decision, ErrMikroFileGenerationSecretForbidden
	}
	if normalizeExportMappingValue(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroFileGenerationDecisionLiveModeClosed
		return pkg, decision, nil
	}
	if req.RealProviderAPIEnabled {
		decision.Reason = MikroFileGenerationDecisionRealAPIClosed
		return pkg, decision, nil
	}
	if req.RealFileDeliveryEnabled {
		decision.Reason = MikroFileGenerationDecisionFileDeliveryStop
		return pkg, decision, nil
	}
	if req.RealERPWriteEnabled {
		decision.Reason = MikroFileGenerationDecisionERPWriteClosed
		return pkg, decision, nil
	}

	mapping, ok := b.MappingContract.MappingFor(req.ERPObjectType)
	if !ok {
		decision.Reason = MikroFileGenerationDecisionUnsupported
		return pkg, decision, nil
	}

	if err := validateMikroDryRunPackageRecords(req.ERPObjectType, req.Records); err != nil {
		return pkg, decision, err
	}

	virtualFileName := buildMikroDryRunVirtualFileName(req.TenantID, req.ERPObjectType, req.PackageID, b.Contract.VirtualFileExtension)
	content := buildMikroDryRunVirtualContent(req, mapping)
	checksum := calculateMikroDryRunChecksum(content)

	pkg = MikroDryRunPackage{
		Manifest: MikroDryRunPackageManifest{
			Phase:             b.Contract.Phase,
			Module:            b.Contract.Module,
			ProviderID:        b.Contract.ProviderID,
			ProviderName:      b.Contract.ProviderName,
			TenantID:          strings.TrimSpace(req.TenantID),
			CorrelationID:     strings.TrimSpace(req.CorrelationID),
			PackageID:         strings.TrimSpace(req.PackageID),
			ERPObjectType:     normalizeExportMappingValue(req.ERPObjectType),
			MikroObjectType:   mapping.MikroObjectType,
			Direction:         b.Contract.Direction,
			TargetSystem:      b.Contract.TargetSystem,
			VirtualFileName:   virtualFileName,
			Encoding:          b.Contract.Encoding,
			LineEnding:        b.Contract.LineEnding,
			ChecksumAlgorithm: b.Contract.ChecksumAlgorithm,
			Checksum:          checksum,
			RecordCount:       len(req.Records),
			FieldCount:        countPackageFields(req.Records),
			DeliveryPolicy:    b.Contract.RealFileWritePolicy,
		},
		VirtualContent: content,
	}

	decision.Allowed = true
	decision.Reason = MikroFileGenerationDecisionReady
	decision.MikroObjectType = mapping.MikroObjectType
	decision.VirtualFileName = virtualFileName
	decision.Checksum = checksum
	return pkg, decision, nil
}

func validateMikroFileGenerationRequest(req MikroFileGenerationRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroFileGenerationRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroFileGenerationRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroFileGenerationRequest)
	}
	if strings.TrimSpace(req.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroFileGenerationRequest)
	}
	if strings.TrimSpace(req.ERPObjectType) == "" {
		return fmt.Errorf("%w: erp_object_type is required", ErrInvalidMikroFileGenerationRequest)
	}
	if len(req.Records) == 0 {
		return fmt.Errorf("%w: at least one dry-run record is required", ErrInvalidMikroFileGenerationRequest)
	}
	return nil
}

func validateMikroDryRunPackageRecords(erpObjectType string, records []MikroDryRunPackageRecord) error {
	expectedObjectType := normalizeExportMappingValue(erpObjectType)
	for _, record := range records {
		if strings.TrimSpace(record.RecordID) == "" {
			return fmt.Errorf("%w: record_id is required", ErrInvalidMikroFileGenerationRequest)
		}
		if normalizeExportMappingValue(record.ERPObjectType) != expectedObjectType {
			return fmt.Errorf("%w: record ERP object type mismatch", ErrInvalidMikroFileGenerationRequest)
		}
		if len(record.Fields) == 0 {
			return fmt.Errorf("%w: record fields are required", ErrInvalidMikroFileGenerationRequest)
		}
		for key := range record.Fields {
			if containsForbiddenMappingField(key) {
				return ErrMikroFileGenerationSecretForbidden
			}
		}
	}
	return nil
}

func buildMikroDryRunVirtualFileName(tenantID string, erpObjectType string, packageID string, extension string) string {
	parts := []string{
		"pix2pi",
		sanitizeMikroFilePart(tenantID),
		"mikro",
		sanitizeMikroFilePart(erpObjectType),
		sanitizeMikroFilePart(packageID),
	}
	return strings.Join(parts, "_") + extension
}

func buildMikroDryRunVirtualContent(req MikroFileGenerationRequest, mapping MikroObjectMapping) string {
	var builder strings.Builder
	builder.WriteString("PHASE=" + MikroFileGenerationPhase + "\n")
	builder.WriteString("PROVIDER_ID=" + ProviderID + "\n")
	builder.WriteString("PACKAGE_ID=" + strings.TrimSpace(req.PackageID) + "\n")
	builder.WriteString("TENANT_ID=" + strings.TrimSpace(req.TenantID) + "\n")
	builder.WriteString("ERP_OBJECT_TYPE=" + normalizeExportMappingValue(req.ERPObjectType) + "\n")
	builder.WriteString("MIKRO_OBJECT_TYPE=" + mapping.MikroObjectType + "\n")
	builder.WriteString("DIRECTION=" + MikroFileGenerationDirection + "\n")
	builder.WriteString("TARGET_SYSTEM=" + MikroFileGenerationTargetSystem + "\n")
	builder.WriteString("DELIVERY_POLICY=" + MikroDryRunNoDeliveryPolicy + "\n")
	builder.WriteString("RECORD_COUNT=" + fmt.Sprintf("%d", len(req.Records)) + "\n")
	builder.WriteString("BEGIN_RECORDS\n")

	for _, record := range req.Records {
		builder.WriteString("RECORD_ID=" + strings.TrimSpace(record.RecordID) + "\n")
		keys := make([]string, 0, len(record.Fields))
		for key := range record.Fields {
			keys = append(keys, key)
		}
		sort.Strings(keys)
		for _, key := range keys {
			builder.WriteString(strings.TrimSpace(key) + "=" + strings.TrimSpace(record.Fields[key]) + "\n")
		}
		builder.WriteString("END_RECORD\n")
	}

	builder.WriteString("END_RECORDS\n")
	return builder.String()
}

func calculateMikroDryRunChecksum(content string) string {
	sum := sha256.Sum256([]byte(content))
	return hex.EncodeToString(sum[:])
}

func countPackageFields(records []MikroDryRunPackageRecord) int {
	count := 0
	for _, record := range records {
		count += len(record.Fields)
	}
	return count
}

func sanitizeMikroFilePart(value string) string {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if normalized == "" {
		return "unknown"
	}

	var builder strings.Builder
	for _, r := range normalized {
		switch {
		case r >= 'a' && r <= 'z':
			builder.WriteRune(r)
		case r >= '0' && r <= '9':
			builder.WriteRune(r)
		case r == '_' || r == '-':
			builder.WriteRune(r)
		default:
			builder.WriteRune('_')
		}
	}
	result := strings.Trim(builder.String(), "_")
	if result == "" {
		return "unknown"
	}
	return result
}
