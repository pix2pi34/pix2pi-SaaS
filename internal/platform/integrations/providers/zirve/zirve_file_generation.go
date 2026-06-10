package zirve

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	ZirveFileGenerationModuleCode = "FAZ_7_8Z_2"
	ZirveFileGenerationMode       = "EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY"
	ZirveFileGenerationTarget     = "ZIRVE_ACCOUNTING_IMPORT_DRY_RUN"
	ZirveDryRunDeliveryPolicy     = "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE"

	ZirveArtifactManifest       = "manifest.json"
	ZirveArtifactObjectsNDJSON  = "objects.ndjson"
	ZirveArtifactValidationJSON = "validation_report.json"
	ZirveArtifactAuditJSON      = "audit_decision.json"
)

type ZirveExportObjectType string

const (
	ZirveObjectCustomer      ZirveExportObjectType = "CUSTOMER"
	ZirveObjectVendor        ZirveExportObjectType = "VENDOR"
	ZirveObjectProduct       ZirveExportObjectType = "PRODUCT"
	ZirveObjectInvoice       ZirveExportObjectType = "INVOICE"
	ZirveObjectStockMovement ZirveExportObjectType = "STOCK_MOVEMENT"
	ZirveObjectJournalEntry  ZirveExportObjectType = "JOURNAL_ENTRY"
)

type ZirveExportOperation string

const (
	ZirveExportCreate ZirveExportOperation = "CREATE"
	ZirveExportUpdate ZirveExportOperation = "UPDATE"
	ZirveExportUpsert ZirveExportOperation = "UPSERT"
	ZirveExportDelete ZirveExportOperation = "DELETE"
)

type ZirveExportObject struct {
	ObjectKey   string
	ObjectType  ZirveExportObjectType
	Operation   ZirveExportOperation
	PayloadHash string
}

type ZirveExportPackageRequest struct {
	TenantID      string
	ExportRunID   string
	CorrelationID string
	RequestedBy   string
	Direction     SyncDirection
	DeliveryMode  DeliveryMode
	DryRun        bool
	RequestedAt   time.Time
	Objects       []ZirveExportObject
}

type ZirveExportPackageArtifact struct {
	RelativePath string
	MimeType     string
	SizeBytes    int
	SHA256       string
	Content      string
}

type ZirveExportPackage struct {
	ProviderID                        string
	ModuleCode                        string
	FileGenerationMode                string
	TargetSystem                      string
	DryRunDeliveryPolicy              string
	TenantID                          string
	ExportRunID                       string
	CorrelationID                     string
	Direction                         SyncDirection
	DeliveryMode                      DeliveryMode
	DryRun                            bool
	RealFileDeliveryAllowed           bool
	RealDeliveryChannelAllowed        bool
	RealERPWriteAllowed               bool
	RealOperatorProviderActionAllowed bool
	Artifacts                         []ZirveExportPackageArtifact
	AuditDecision                     OperationDecision
	CreatedAtUTC                      time.Time
}

type ZirveExportPackageBuilder struct {
	Identity ZirveProviderIdentity
}

func NewZirveExportPackageBuilder(identity ZirveProviderIdentity) ZirveExportPackageBuilder {
	if strings.TrimSpace(identity.ProviderID) == "" {
		identity = NewZirveProviderIdentity(time.Now().UTC())
	}

	return ZirveExportPackageBuilder{
		Identity: identity,
	}
}

func (b ZirveExportPackageBuilder) BuildDryRunExportPackage(request ZirveExportPackageRequest) (ZirveExportPackage, error) {
	if err := b.Identity.Validate(); err != nil {
		return ZirveExportPackage{}, fmt.Errorf("zirve identity validation failed: %w", err)
	}

	normalized, err := normalizeZirveExportPackageRequest(request)
	if err != nil {
		return ZirveExportPackage{}, err
	}

	decision := b.Identity.DecideOperation("DRY_RUN_EXPORT_PACKAGE_BUILD")
	if !decision.Allowed {
		return ZirveExportPackage{}, fmt.Errorf("zirve dry-run export package operation denied: %s", decision.Reason)
	}

	if b.Identity.CanDeliverRealFile() {
		return ZirveExportPackage{}, errors.New("real Zirve file delivery must remain closed in FAZ 7-8Z.2")
	}

	if b.Identity.CanWriteERP() {
		return ZirveExportPackage{}, errors.New("real ERP write must remain closed in FAZ 7-8Z.2")
	}

	artifacts := buildZirveDryRunArtifacts(normalized, decision)

	return ZirveExportPackage{
		ProviderID:                        ProviderID,
		ModuleCode:                        ZirveFileGenerationModuleCode,
		FileGenerationMode:                ZirveFileGenerationMode,
		TargetSystem:                      ZirveFileGenerationTarget,
		DryRunDeliveryPolicy:              ZirveDryRunDeliveryPolicy,
		TenantID:                          normalized.TenantID,
		ExportRunID:                       normalized.ExportRunID,
		CorrelationID:                     normalized.CorrelationID,
		Direction:                         normalized.Direction,
		DeliveryMode:                      normalized.DeliveryMode,
		DryRun:                            true,
		RealFileDeliveryAllowed:           false,
		RealDeliveryChannelAllowed:        false,
		RealERPWriteAllowed:               false,
		RealOperatorProviderActionAllowed: false,
		Artifacts:                         artifacts,
		AuditDecision:                     decision,
		CreatedAtUTC:                      normalized.RequestedAt.UTC(),
	}, nil
}

func normalizeZirveExportPackageRequest(request ZirveExportPackageRequest) (ZirveExportPackageRequest, error) {
	request.TenantID = strings.TrimSpace(request.TenantID)
	request.ExportRunID = strings.TrimSpace(request.ExportRunID)
	request.CorrelationID = strings.TrimSpace(request.CorrelationID)
	request.RequestedBy = strings.TrimSpace(request.RequestedBy)

	if request.TenantID == "" {
		return request, errors.New("tenant id is required for Zirve dry-run file generation")
	}
	if request.ExportRunID == "" {
		return request, errors.New("export run id is required for Zirve dry-run file generation")
	}
	if request.CorrelationID == "" {
		return request, errors.New("correlation id is required for Zirve dry-run file generation")
	}
	if request.RequestedBy == "" {
		return request, errors.New("requested by is required for Zirve dry-run file generation")
	}
	if !request.DryRun {
		return request, errors.New("Zirve file generation is dry-run only in FAZ 7-8Z.2")
	}

	if request.Direction == "" {
		request.Direction = DirectionPix2piToZirve
	}
	if request.Direction != DirectionPix2piToZirve {
		return request, fmt.Errorf("unsupported Zirve file generation direction in this phase: %s", request.Direction)
	}

	if request.DeliveryMode == "" {
		request.DeliveryMode = DeliveryModeFilePackageDryRun
	}
	if request.DeliveryMode != DeliveryModeFilePackageDryRun {
		return request, fmt.Errorf("Zirve file generation delivery mode must be %s", DeliveryModeFilePackageDryRun)
	}

	if request.RequestedAt.IsZero() {
		request.RequestedAt = time.Now().UTC()
	}

	if len(request.Objects) == 0 {
		return request, errors.New("at least one export object is required for Zirve dry-run file generation")
	}

	normalizedObjects := make([]ZirveExportObject, 0, len(request.Objects))
	for index, object := range request.Objects {
		object.ObjectKey = strings.TrimSpace(object.ObjectKey)
		object.PayloadHash = strings.TrimSpace(object.PayloadHash)

		if object.ObjectKey == "" {
			return request, fmt.Errorf("object key is required at index %d", index)
		}
		if !isSupportedZirveExportObjectType(object.ObjectType) {
			return request, fmt.Errorf("unsupported Zirve object type at index %d: %s", index, object.ObjectType)
		}
		if !isSupportedZirveExportOperation(object.Operation) {
			return request, fmt.Errorf("unsupported Zirve export operation at index %d: %s", index, object.Operation)
		}
		if object.PayloadHash == "" {
			return request, fmt.Errorf("payload hash is required at index %d", index)
		}

		normalizedObjects = append(normalizedObjects, object)
	}

	sort.Slice(normalizedObjects, func(i, j int) bool {
		if normalizedObjects[i].ObjectType == normalizedObjects[j].ObjectType {
			return normalizedObjects[i].ObjectKey < normalizedObjects[j].ObjectKey
		}
		return normalizedObjects[i].ObjectType < normalizedObjects[j].ObjectType
	})

	request.Objects = normalizedObjects
	return request, nil
}

func isSupportedZirveExportObjectType(objectType ZirveExportObjectType) bool {
	switch objectType {
	case ZirveObjectCustomer,
		ZirveObjectVendor,
		ZirveObjectProduct,
		ZirveObjectInvoice,
		ZirveObjectStockMovement,
		ZirveObjectJournalEntry:
		return true
	default:
		return false
	}
}

func isSupportedZirveExportOperation(operation ZirveExportOperation) bool {
	switch operation {
	case ZirveExportCreate,
		ZirveExportUpdate,
		ZirveExportUpsert,
		ZirveExportDelete:
		return true
	default:
		return false
	}
}

func buildZirveDryRunArtifacts(request ZirveExportPackageRequest, decision OperationDecision) []ZirveExportPackageArtifact {
	manifest := buildZirveManifestContent(request)
	objects := buildZirveObjectsNDJSONContent(request)
	validation := buildZirveValidationReportContent(request)
	audit := buildZirveAuditDecisionContent(request, decision)

	return []ZirveExportPackageArtifact{
		newZirveArtifact(ZirveArtifactManifest, "application/json", manifest),
		newZirveArtifact(ZirveArtifactObjectsNDJSON, "application/x-ndjson", objects),
		newZirveArtifact(ZirveArtifactValidationJSON, "application/json", validation),
		newZirveArtifact(ZirveArtifactAuditJSON, "application/json", audit),
	}
}

func buildZirveManifestContent(request ZirveExportPackageRequest) string {
	return fmt.Sprintf(`{
  "module_code": "%s",
  "provider_id": "%s",
  "target_system": "%s",
  "file_generation_mode": "%s",
  "dry_run_delivery_policy": "%s",
  "tenant_id": "%s",
  "export_run_id": "%s",
  "correlation_id": "%s",
  "requested_by": "%s",
  "direction": "%s",
  "delivery_mode": "%s",
  "dry_run": true,
  "object_count": %d,
  "real_file_delivery": false,
  "real_delivery_channel": false,
  "real_erp_write": false
}`,
		ZirveFileGenerationModuleCode,
		ProviderID,
		ZirveFileGenerationTarget,
		ZirveFileGenerationMode,
		ZirveDryRunDeliveryPolicy,
		request.TenantID,
		request.ExportRunID,
		request.CorrelationID,
		request.RequestedBy,
		request.Direction,
		request.DeliveryMode,
		len(request.Objects),
	)
}

func buildZirveObjectsNDJSONContent(request ZirveExportPackageRequest) string {
	var builder strings.Builder

	for _, object := range request.Objects {
		builder.WriteString(fmt.Sprintf(
			`{"tenant_id":"%s","export_run_id":"%s","object_type":"%s","object_key":"%s","operation":"%s","payload_hash":"%s","dry_run":true}`,
			request.TenantID,
			request.ExportRunID,
			object.ObjectType,
			object.ObjectKey,
			object.Operation,
			object.PayloadHash,
		))
		builder.WriteString("\n")
	}

	return builder.String()
}

func buildZirveValidationReportContent(request ZirveExportPackageRequest) string {
	return fmt.Sprintf(`{
  "provider_id": "%s",
  "module_code": "%s",
  "tenant_id": "%s",
  "export_run_id": "%s",
  "validation_status": "PASS",
  "required_fail": 0,
  "optional_warn": 0,
  "object_count": %d,
  "dry_run_only": true,
  "external_delivery_attempted": false
}`,
		ProviderID,
		ZirveFileGenerationModuleCode,
		request.TenantID,
		request.ExportRunID,
		len(request.Objects),
	)
}

func buildZirveAuditDecisionContent(request ZirveExportPackageRequest, decision OperationDecision) string {
	return fmt.Sprintf(`{
  "provider_id": "%s",
  "module_code": "%s",
  "tenant_id": "%s",
  "export_run_id": "%s",
  "correlation_id": "%s",
  "operation_code": "%s",
  "allowed": %t,
  "reason": "%s",
  "required_gate": "%s",
  "real_file_delivery_allowed": false,
  "real_erp_write_allowed": false
}`,
		ProviderID,
		ZirveFileGenerationModuleCode,
		request.TenantID,
		request.ExportRunID,
		request.CorrelationID,
		decision.OperationCode,
		decision.Allowed,
		decision.Reason,
		decision.RequiredGate,
	)
}

func newZirveArtifact(relativePath string, mimeType string, content string) ZirveExportPackageArtifact {
	sum := sha256.Sum256([]byte(content))

	return ZirveExportPackageArtifact{
		RelativePath: relativePath,
		MimeType:     mimeType,
		SizeBytes:    len([]byte(content)),
		SHA256:       hex.EncodeToString(sum[:]),
		Content:      content,
	}
}
