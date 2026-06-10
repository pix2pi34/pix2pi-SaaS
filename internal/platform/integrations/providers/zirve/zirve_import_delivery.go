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
	ZirveImportDeliveryModuleCode     = "FAZ_7_8Z_3"
	ZirveImportDeliveryContractMode   = "IMPORT_PACKAGE_DELIVERY_CONTRACT_DRY_RUN_ONLY"
	ZirveImportDeliveryContractStatus = "READY_DRY_RUN_ONLY"
	ZirveDeliveryChannelStatus        = "PLACEHOLDER_ONLY"
	ZirveImportDeliveryTargetSystem   = "ZIRVE_ACCOUNTING_IMPORT_DRY_RUN"
	ZirveImportDeliveryPolicy         = "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE"

	ZirveDeliveryArtifactManifest      = "delivery_manifest.json"
	ZirveDeliveryArtifactHandoff       = "delivery_handoff.json"
	ZirveDeliveryArtifactAuditDecision = "delivery_audit_decision.json"
)

type ZirveDeliveryChannel string

const (
	ZirveDeliveryChannelNoneDryRun         ZirveDeliveryChannel = "NONE_DRY_RUN"
	ZirveDeliveryChannelLocalPackage       ZirveDeliveryChannel = "LOCAL_PACKAGE_PLACEHOLDER"
	ZirveDeliveryChannelProviderLiveModule ZirveDeliveryChannel = "PROVIDER_LIVE_MODULE_ONLY"
)

type ZirveImportDeliveryRequest struct {
	TenantID      string
	ExportRunID   string
	DeliveryRunID string
	CorrelationID string
	RequestedBy   string
	Package       ZirveExportPackage
	Channel       ZirveDeliveryChannel
	DryRun        bool
	RequestedAt   time.Time
}

type ZirveImportDeliveryContract struct {
	ProviderID                        string
	ModuleCode                        string
	ContractMode                      string
	ContractStatus                    string
	TargetSystem                      string
	DryRunDeliveryPolicy              string
	DeliveryChannel                   ZirveDeliveryChannel
	DeliveryChannelStatus             string
	TenantID                          string
	ExportRunID                       string
	DeliveryRunID                     string
	CorrelationID                     string
	DryRun                            bool
	PackageArtifactCount              int
	PackageArtifactPaths              []string
	PackageFingerprintSHA256          string
	RealProviderAPIAllowed            bool
	RealFileDeliveryAllowed           bool
	RealDeliveryChannelAllowed        bool
	RealERPWriteAllowed               bool
	RealOperatorProviderActionAllowed bool
	Artifacts                         []ZirveExportPackageArtifact
	AuditDecision                     OperationDecision
	CreatedAtUTC                      time.Time
}

type ZirveImportDeliveryContractBuilder struct {
	Identity ZirveProviderIdentity
}

func NewZirveImportDeliveryContractBuilder(identity ZirveProviderIdentity) ZirveImportDeliveryContractBuilder {
	if strings.TrimSpace(identity.ProviderID) == "" {
		identity = NewZirveProviderIdentity(time.Now().UTC())
	}

	return ZirveImportDeliveryContractBuilder{
		Identity: identity,
	}
}

func (b ZirveImportDeliveryContractBuilder) BuildDryRunImportDeliveryContract(request ZirveImportDeliveryRequest) (ZirveImportDeliveryContract, error) {
	if err := b.Identity.Validate(); err != nil {
		return ZirveImportDeliveryContract{}, fmt.Errorf("zirve identity validation failed: %w", err)
	}

	normalized, err := normalizeZirveImportDeliveryRequest(request)
	if err != nil {
		return ZirveImportDeliveryContract{}, err
	}

	if err := validateZirveDryRunExportPackageForDelivery(normalized); err != nil {
		return ZirveImportDeliveryContract{}, err
	}

	decision := decideZirveImportDeliveryOperation("DRY_RUN_IMPORT_DELIVERY_CONTRACT")
	if !decision.Allowed {
		return ZirveImportDeliveryContract{}, fmt.Errorf("zirve import delivery contract operation denied: %s", decision.Reason)
	}

	if b.Identity.CanUseRealProviderAPI() {
		return ZirveImportDeliveryContract{}, errors.New("real Zirve provider API must remain closed in FAZ 7-8Z.3")
	}

	if b.Identity.CanDeliverRealFile() {
		return ZirveImportDeliveryContract{}, errors.New("real Zirve file delivery must remain closed in FAZ 7-8Z.3")
	}

	if b.Identity.CanWriteERP() {
		return ZirveImportDeliveryContract{}, errors.New("real ERP write must remain closed in FAZ 7-8Z.3")
	}

	artifactPaths := sortedZirvePackageArtifactPaths(normalized.Package.Artifacts)
	fingerprint := fingerprintZirvePackageArtifacts(normalized.Package.Artifacts)
	artifacts := buildZirveImportDeliveryArtifacts(normalized, decision, artifactPaths, fingerprint)

	return ZirveImportDeliveryContract{
		ProviderID:                        ProviderID,
		ModuleCode:                        ZirveImportDeliveryModuleCode,
		ContractMode:                      ZirveImportDeliveryContractMode,
		ContractStatus:                    ZirveImportDeliveryContractStatus,
		TargetSystem:                      ZirveImportDeliveryTargetSystem,
		DryRunDeliveryPolicy:              ZirveImportDeliveryPolicy,
		DeliveryChannel:                   normalized.Channel,
		DeliveryChannelStatus:             ZirveDeliveryChannelStatus,
		TenantID:                          normalized.TenantID,
		ExportRunID:                       normalized.ExportRunID,
		DeliveryRunID:                     normalized.DeliveryRunID,
		CorrelationID:                     normalized.CorrelationID,
		DryRun:                            true,
		PackageArtifactCount:              len(normalized.Package.Artifacts),
		PackageArtifactPaths:              artifactPaths,
		PackageFingerprintSHA256:          fingerprint,
		RealProviderAPIAllowed:            false,
		RealFileDeliveryAllowed:           false,
		RealDeliveryChannelAllowed:        false,
		RealERPWriteAllowed:               false,
		RealOperatorProviderActionAllowed: false,
		Artifacts:                         artifacts,
		AuditDecision:                     decision,
		CreatedAtUTC:                      normalized.RequestedAt.UTC(),
	}, nil
}

func normalizeZirveImportDeliveryRequest(request ZirveImportDeliveryRequest) (ZirveImportDeliveryRequest, error) {
	request.TenantID = strings.TrimSpace(request.TenantID)
	request.ExportRunID = strings.TrimSpace(request.ExportRunID)
	request.DeliveryRunID = strings.TrimSpace(request.DeliveryRunID)
	request.CorrelationID = strings.TrimSpace(request.CorrelationID)
	request.RequestedBy = strings.TrimSpace(request.RequestedBy)

	if request.TenantID == "" {
		return request, errors.New("tenant id is required for Zirve import delivery contract")
	}
	if request.ExportRunID == "" {
		return request, errors.New("export run id is required for Zirve import delivery contract")
	}
	if request.DeliveryRunID == "" {
		return request, errors.New("delivery run id is required for Zirve import delivery contract")
	}
	if request.CorrelationID == "" {
		return request, errors.New("correlation id is required for Zirve import delivery contract")
	}
	if request.RequestedBy == "" {
		return request, errors.New("requested by is required for Zirve import delivery contract")
	}
	if !request.DryRun {
		return request, errors.New("Zirve import delivery contract is dry-run only in FAZ 7-8Z.3")
	}

	if request.Channel == "" {
		request.Channel = ZirveDeliveryChannelLocalPackage
	}

	if request.Channel != ZirveDeliveryChannelLocalPackage {
		return request, fmt.Errorf("Zirve import delivery channel must be %s in this phase", ZirveDeliveryChannelLocalPackage)
	}

	if request.RequestedAt.IsZero() {
		request.RequestedAt = time.Now().UTC()
	}

	return request, nil
}

func validateZirveDryRunExportPackageForDelivery(request ZirveImportDeliveryRequest) error {
	pkg := request.Package

	if strings.TrimSpace(pkg.ProviderID) != ProviderID {
		return fmt.Errorf("package provider id must be %s", ProviderID)
	}
	if strings.TrimSpace(pkg.ModuleCode) != ZirveFileGenerationModuleCode {
		return fmt.Errorf("package module code must be %s", ZirveFileGenerationModuleCode)
	}
	if strings.TrimSpace(pkg.FileGenerationMode) != ZirveFileGenerationMode {
		return fmt.Errorf("package file generation mode must be %s", ZirveFileGenerationMode)
	}
	if strings.TrimSpace(pkg.TargetSystem) != ZirveFileGenerationTarget {
		return fmt.Errorf("package target system must be %s", ZirveFileGenerationTarget)
	}
	if strings.TrimSpace(pkg.TenantID) != request.TenantID {
		return errors.New("delivery contract tenant id must match export package tenant id")
	}
	if strings.TrimSpace(pkg.ExportRunID) != request.ExportRunID {
		return errors.New("delivery contract export run id must match export package export run id")
	}
	if !pkg.DryRun {
		return errors.New("only dry-run export packages can be used in FAZ 7-8Z.3")
	}
	if pkg.RealFileDeliveryAllowed {
		return errors.New("export package real file delivery must be closed")
	}
	if pkg.RealDeliveryChannelAllowed {
		return errors.New("export package real delivery channel must be closed")
	}
	if pkg.RealERPWriteAllowed {
		return errors.New("export package real ERP write must be closed")
	}
	if pkg.RealOperatorProviderActionAllowed {
		return errors.New("export package real operator provider action must be closed")
	}
	if len(pkg.Artifacts) == 0 {
		return errors.New("export package artifacts are required for delivery contract")
	}

	required := map[string]bool{
		ZirveArtifactManifest:       false,
		ZirveArtifactObjectsNDJSON:  false,
		ZirveArtifactValidationJSON: false,
		ZirveArtifactAuditJSON:      false,
	}

	for _, artifact := range pkg.Artifacts {
		if artifact.RelativePath == "" {
			return errors.New("package artifact relative path is required")
		}
		if artifact.SHA256 == "" {
			return errors.New("package artifact sha256 is required")
		}
		if _, ok := required[artifact.RelativePath]; ok {
			required[artifact.RelativePath] = true
		}
	}

	for artifact, present := range required {
		if !present {
			return fmt.Errorf("required package artifact missing: %s", artifact)
		}
	}

	return nil
}

func decideZirveImportDeliveryOperation(operationCode string) OperationDecision {
	operationCode = strings.TrimSpace(operationCode)

	if operationCode == "DRY_RUN_IMPORT_DELIVERY_CONTRACT" {
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       true,
			Reason:        "dry-run import delivery contract is allowed without external delivery",
			RequiredGate:  "IMPORT_DELIVERY_CONTRACT_ONLY",
		}
	}

	return OperationDecision{
		OperationCode: operationCode,
		Allowed:       false,
		Reason:        "real import delivery is closed until provider live/import delivery live module",
		RequiredGate:  HandoffGateStatus,
	}
}

func sortedZirvePackageArtifactPaths(artifacts []ZirveExportPackageArtifact) []string {
	paths := make([]string, 0, len(artifacts))
	for _, artifact := range artifacts {
		paths = append(paths, artifact.RelativePath)
	}
	sort.Strings(paths)
	return paths
}

func fingerprintZirvePackageArtifacts(artifacts []ZirveExportPackageArtifact) string {
	paths := sortedZirvePackageArtifactPaths(artifacts)

	var builder strings.Builder
	for _, path := range paths {
		for _, artifact := range artifacts {
			if artifact.RelativePath == path {
				builder.WriteString(artifact.RelativePath)
				builder.WriteString(":")
				builder.WriteString(artifact.SHA256)
				builder.WriteString("\n")
			}
		}
	}

	sum := sha256.Sum256([]byte(builder.String()))
	return hex.EncodeToString(sum[:])
}

func buildZirveImportDeliveryArtifacts(request ZirveImportDeliveryRequest, decision OperationDecision, packagePaths []string, packageFingerprint string) []ZirveExportPackageArtifact {
	manifest := buildZirveDeliveryManifestContent(request, packagePaths, packageFingerprint)
	handoff := buildZirveDeliveryHandoffContent(request)
	audit := buildZirveDeliveryAuditDecisionContent(request, decision)

	return []ZirveExportPackageArtifact{
		newZirveArtifact(ZirveDeliveryArtifactManifest, "application/json", manifest),
		newZirveArtifact(ZirveDeliveryArtifactHandoff, "application/json", handoff),
		newZirveArtifact(ZirveDeliveryArtifactAuditDecision, "application/json", audit),
	}
}

func buildZirveDeliveryManifestContent(request ZirveImportDeliveryRequest, packagePaths []string, packageFingerprint string) string {
	return fmt.Sprintf(`{
  "module_code": "%s",
  "provider_id": "%s",
  "contract_mode": "%s",
  "contract_status": "%s",
  "target_system": "%s",
  "dry_run_delivery_policy": "%s",
  "tenant_id": "%s",
  "export_run_id": "%s",
  "delivery_run_id": "%s",
  "correlation_id": "%s",
  "requested_by": "%s",
  "delivery_channel": "%s",
  "delivery_channel_status": "%s",
  "package_artifact_count": %d,
  "package_artifact_paths": "%s",
  "package_fingerprint_sha256": "%s",
  "dry_run": true,
  "real_provider_api": false,
  "real_file_delivery": false,
  "real_delivery_channel": false,
  "real_erp_write": false,
  "real_operator_provider_action": false
}`,
		ZirveImportDeliveryModuleCode,
		ProviderID,
		ZirveImportDeliveryContractMode,
		ZirveImportDeliveryContractStatus,
		ZirveImportDeliveryTargetSystem,
		ZirveImportDeliveryPolicy,
		request.TenantID,
		request.ExportRunID,
		request.DeliveryRunID,
		request.CorrelationID,
		request.RequestedBy,
		request.Channel,
		ZirveDeliveryChannelStatus,
		len(request.Package.Artifacts),
		strings.Join(packagePaths, ","),
		packageFingerprint,
	)
}

func buildZirveDeliveryHandoffContent(request ZirveImportDeliveryRequest) string {
	return fmt.Sprintf(`{
  "provider_id": "%s",
  "module_code": "%s",
  "tenant_id": "%s",
  "export_run_id": "%s",
  "delivery_run_id": "%s",
  "handoff_gate": "%s",
  "provider_live_module_status": "%s",
  "import_delivery_contract_status": "%s",
  "real_external_delivery_attempted": false,
  "real_erp_write_attempted": false
}`,
		ProviderID,
		ZirveImportDeliveryModuleCode,
		request.TenantID,
		request.ExportRunID,
		request.DeliveryRunID,
		HandoffGateStatus,
		ProviderLiveModuleStatus,
		ZirveImportDeliveryContractStatus,
	)
}

func buildZirveDeliveryAuditDecisionContent(request ZirveImportDeliveryRequest, decision OperationDecision) string {
	return fmt.Sprintf(`{
  "provider_id": "%s",
  "module_code": "%s",
  "tenant_id": "%s",
  "export_run_id": "%s",
  "delivery_run_id": "%s",
  "correlation_id": "%s",
  "operation_code": "%s",
  "allowed": %t,
  "reason": "%s",
  "required_gate": "%s",
  "dry_run_only": true,
  "external_delivery_attempted": false,
  "real_file_delivery_allowed": false,
  "real_delivery_channel_allowed": false,
  "real_erp_write_allowed": false
}`,
		ProviderID,
		ZirveImportDeliveryModuleCode,
		request.TenantID,
		request.ExportRunID,
		request.DeliveryRunID,
		request.CorrelationID,
		decision.OperationCode,
		decision.Allowed,
		decision.Reason,
		decision.RequiredGate,
	)
}
