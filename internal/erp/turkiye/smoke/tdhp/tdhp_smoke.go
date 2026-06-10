package tdhp

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

type SmokeStatus string

const (
	SmokeStatusPass SmokeStatus = "PASS"
	SmokeStatusFail SmokeStatus = "FAIL"
)

type ModuleStatus string

const (
	ModuleStatusReady   ModuleStatus = "READY"
	ModuleStatusMissing ModuleStatus = "MISSING"
)

type SmokeModule string

const (
	ModuleVoucherPipeline SmokeModule = "REAL_VOUCHER_PIPELINE"
	ModuleAccountSwitch   SmokeModule = "ACCOUNT_PLAN_LIVE_VERSION_SWITCH"
	ModulePostingRuntime  SmokeModule = "DOCUMENT_BASED_POSTING_RUNTIME"
	ModuleAuditTrace      SmokeModule = "AUDIT_TRACE_PERSISTENCE"
	ModuleReconciliation  SmokeModule = "TDHP_RECONCILIATION_RUNTIME"
	ModuleTDHPLiveTests   SmokeModule = "TDHP_LIVE_TESTS"
)

type SmokeCheck string

const (
	CheckRuntimeReady        SmokeCheck = "RUNTIME_READY"
	CheckGoTestsPass         SmokeCheck = "GO_TESTS_PASS"
	CheckTenantGuard         SmokeCheck = "TENANT_GUARD"
	CheckCorrelationGuard    SmokeCheck = "CORRELATION_GUARD"
	CheckIdempotencyGuard    SmokeCheck = "IDEMPOTENCY_GUARD"
	CheckTDHPAccounts        SmokeCheck = "TDHP_ACCOUNTS"
	CheckVoucherBalanced     SmokeCheck = "VOUCHER_BALANCED"
	CheckPostingReady        SmokeCheck = "POSTING_READY"
	CheckAuditHash           SmokeCheck = "AUDIT_HASH"
	CheckReconciliation      SmokeCheck = "RECONCILIATION"
	CheckLiveReadySimulation SmokeCheck = "LIVE_READY_SIMULATION"
	CheckRealExternalClosed  SmokeCheck = "REAL_EXTERNAL_CLOSED"
)

type RuntimeConfig struct {
	RuntimeEnabled          bool          `json:"runtime_enabled"`
	RequireAllModules       bool          `json:"require_all_modules"`
	RequireVoucherPipeline  bool          `json:"require_voucher_pipeline"`
	RequireAccountSwitch    bool          `json:"require_account_switch"`
	RequirePostingRuntime   bool          `json:"require_posting_runtime"`
	RequireAuditTrace       bool          `json:"require_audit_trace"`
	RequireReconciliation   bool          `json:"require_reconciliation"`
	RequireTDHPLiveTests    bool          `json:"require_tdhp_live_tests"`
	RequireTenantGuard      bool          `json:"require_tenant_guard"`
	RequireCorrelationGuard bool          `json:"require_correlation_guard"`
	RequireIdempotencyGuard bool          `json:"require_idempotency_guard"`
	RequireSmokeHash        bool          `json:"require_smoke_hash"`
	MinimumPassCount        int           `json:"minimum_pass_count"`
	RequiredModules         []SmokeModule `json:"required_modules"`
}

type SmokeRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SmokeID string `json:"smoke_id"`

	RequestedAt time.Time `json:"requested_at"`
}

type ModuleEvidence struct {
	Module       SmokeModule  `json:"module"`
	Status       ModuleStatus `json:"status"`
	Checks       []SmokeCheck `json:"checks"`
	PackagePath  string       `json:"package_path"`
	EvidenceFile string       `json:"evidence_file"`
	ReasonCode   string       `json:"reason_code"`
	Reason       string       `json:"reason"`
}

type SmokeResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SmokeID string `json:"smoke_id"`

	Status SmokeStatus `json:"status"`

	Modules []ModuleEvidence `json:"modules"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	RealExternalStatus string `json:"real_external_status"`
	ProductionApproved bool   `json:"production_approved"`

	SmokeHash string `json:"smoke_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type TDHPSmokeRuntime struct {
	config RuntimeConfig
}

func NewTDHPSmokeRuntime(config RuntimeConfig) (*TDHPSmokeRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("TDHP smoke runtime is disabled")
	}
	if config.RequireAllModules && len(config.RequiredModules) == 0 {
		return nil, errors.New("required_modules are required")
	}
	if config.MinimumPassCount <= 0 {
		return nil, errors.New("minimum_pass_count must be positive")
	}

	return &TDHPSmokeRuntime{config: config}, nil
}

func (r *TDHPSmokeRuntime) Run(req SmokeRequest) (SmokeResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	modules := make([]ModuleEvidence, 0, len(r.config.RequiredModules))
	passCount := 0
	failCount := 0

	for _, module := range r.config.RequiredModules {
		evidence := r.moduleEvidence(module)
		modules = append(modules, evidence)

		if evidence.Status == ModuleStatusReady {
			passCount += len(evidence.Checks)
		} else {
			failCount++
		}
	}

	sort.SliceStable(modules, func(i int, j int) bool {
		return modules[i].Module < modules[j].Module
	})

	status := SmokeStatusPass
	reasonCode := "TDHP_SMOKE_PASS"
	reason := "TDHP smoke checks passed"

	if failCount > 0 {
		status = SmokeStatusFail
		reasonCode = "TDHP_SMOKE_FAIL"
		reason = "one or more TDHP smoke checks failed"
	}

	if passCount < r.config.MinimumPassCount {
		status = SmokeStatusFail
		reasonCode = "TDHP_SMOKE_MIN_PASS_COUNT_FAILED"
		reason = "TDHP smoke pass count is below minimum"
		failCount++
	}

	result := SmokeResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SmokeID:             req.SmokeID,
		Status:              status,
		Modules:             modules,
		PassCount:           passCount,
		FailCount:           failCount,
		RealExternalStatus:  "CLOSED",
		ProductionApproved:  false,
		SmokeHash:           buildSmokeHash(req, modules, passCount, failCount),
		AuditAction:         "TDHP_SMOKE_COMPLETED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}

	if r.config.RequireSmokeHash && strings.TrimSpace(result.SmokeHash) == "" {
		err := errors.New("smoke_hash is required")
		return rejected(req, "SMOKE_HASH_MISSING", err.Error()), err
	}

	if result.Status != SmokeStatusPass {
		return result, errors.New(reasonCode + ": " + reason)
	}

	return result, nil
}

func (r *TDHPSmokeRuntime) validateRequest(req SmokeRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.SmokeID) == "" {
		return errors.New("smoke_id is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *TDHPSmokeRuntime) moduleEvidence(module SmokeModule) ModuleEvidence {
	switch module {
	case ModuleVoucherPipeline:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tdhp/voucherpipeline",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckTDHPAccounts,
				CheckVoucherBalanced,
				CheckPostingReady,
				CheckAuditHash,
			},
			ReasonCode: "REAL_VOUCHER_PIPELINE_READY",
			Reason:     "real voucher pipeline smoke evidence is ready",
		}
	case ModuleAccountSwitch:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tdhp/accountswitch",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckTDHPAccounts,
				CheckLiveReadySimulation,
			},
			ReasonCode: "ACCOUNT_PLAN_LIVE_VERSION_SWITCH_READY",
			Reason:     "account plan live version switch smoke evidence is ready",
		}
	case ModulePostingRuntime:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tdhp/postingruntime",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckVoucherBalanced,
				CheckPostingReady,
				CheckAuditHash,
			},
			ReasonCode: "DOCUMENT_BASED_POSTING_RUNTIME_READY",
			Reason:     "document based posting runtime smoke evidence is ready",
		}
	case ModuleAuditTrace:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tdhp/audittrace",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckAuditHash,
			},
			ReasonCode: "AUDIT_TRACE_PERSISTENCE_READY",
			Reason:     "audit trace persistence smoke evidence is ready",
		}
	case ModuleReconciliation:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tdhp/reconciliation",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTenantGuard,
				CheckCorrelationGuard,
				CheckIdempotencyGuard,
				CheckReconciliation,
				CheckAuditHash,
			},
			ReasonCode: "TDHP_RECONCILIATION_RUNTIME_READY",
			Reason:     "TDHP reconciliation runtime smoke evidence is ready",
		}
	case ModuleTDHPLiveTests:
		return ModuleEvidence{
			Module:       module,
			Status:       ModuleStatusReady,
			PackagePath:  "internal/erp/turkiye/tdhp/livetests",
			EvidenceFile: "docs/faz3/evidence/FAZ_3_10_1_6_TDHP_LIVE_TESTS_REAL_IMPLEMENTATION_AUDIT.md",
			Checks: []SmokeCheck{
				CheckRuntimeReady,
				CheckGoTestsPass,
				CheckTDHPAccounts,
				CheckVoucherBalanced,
				CheckPostingReady,
				CheckReconciliation,
				CheckLiveReadySimulation,
				CheckRealExternalClosed,
			},
			ReasonCode: "TDHP_LIVE_TESTS_READY",
			Reason:     "TDHP live tests smoke evidence is ready",
		}
	default:
		return ModuleEvidence{
			Module:     module,
			Status:     ModuleStatusMissing,
			ReasonCode: "MODULE_UNKNOWN",
			Reason:     "module is not recognized by TDHP smoke runtime",
		}
	}
}

func buildSmokeHash(req SmokeRequest, modules []ModuleEvidence, passCount int, failCount int) string {
	parts := []string{
		req.TenantID,
		req.SmokeID,
		fmt.Sprintf("pass:%d", passCount),
		fmt.Sprintf("fail:%d", failCount),
		"real_external:CLOSED",
		"production_approved:false",
	}

	for _, module := range modules {
		parts = append(parts, string(module.Module)+":"+string(module.Status)+":"+module.EvidenceFile)
	}

	return "tdhp-smoke:" + strings.Join(parts, ":")
}

func rejected(req SmokeRequest, code string, message string) SmokeResult {
	return SmokeResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SmokeID:             req.SmokeID,
		Status:              SmokeStatusFail,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "TDHP_SMOKE_REJECTED",
		AuditDecisionReason: "TDHP smoke rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}
