package livetests

import (
	"fmt"
	"time"

	accountswitch "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/accountswitch"
	audittrace "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/audittrace"
	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
	reconciliationruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/reconciliationruntime"
	voucherpipeline "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/voucherpipeline"
)

type TDHPLiveTestSuite struct {
	AccountSwitch *accountswitch.ChartAccountLiveSwitchRuntime
	Voucher       *voucherpipeline.VoucherPipelineRuntime
	Posting       *postingruntime.DocumentPostingRuntime
	AuditTrace    *audittrace.AuditTracePersistenceRuntime
	Reconcile     *reconciliationruntime.ReconciliationRuntime
}

type TDHPLiveResult struct {
	SwitchReady      bool
	AccountResolved  bool
	VoucherReady     bool
	PostingPosted    bool
	AuditTraceStored bool
	Reconciled       bool
	LedgerReady      bool

	AccountCode      string
	VoucherID        string
	PostingID        string
	TraceID          string
	ReconciliationID string
}

func NewTDHPLiveTestSuite() (*TDHPLiveTestSuite, error) {
	accountSwitch, err := accountswitch.NewChartAccountLiveSwitchRuntime(chartSwitchConfig())
	if err != nil {
		return nil, err
	}

	voucher, err := voucherpipeline.NewVoucherPipelineRuntime(voucherConfig(), voucherpipeline.DefaultTRAccountMapping())
	if err != nil {
		return nil, err
	}

	posting, err := postingruntime.NewDocumentPostingRuntime(postingConfig(), postingruntime.NewInMemoryPostingRepository())
	if err != nil {
		return nil, err
	}

	auditRuntime, err := audittrace.NewAuditTracePersistenceRuntime(auditConfig(), audittrace.NewInMemoryAuditTraceRepository())
	if err != nil {
		return nil, err
	}

	reconcile, err := reconciliationruntime.NewReconciliationRuntime(reconciliationConfig(), reconciliationruntime.NewInMemoryReconciliationRepository())
	if err != nil {
		return nil, err
	}

	return &TDHPLiveTestSuite{
		AccountSwitch: accountSwitch,
		Voucher:       voucher,
		Posting:       posting,
		AuditTrace:    auditRuntime,
		Reconcile:     reconcile,
	}, nil
}

func (s *TDHPLiveTestSuite) RunSalesInvoiceLiveE2E(suffix string) (TDHPLiveResult, error) {
	switchResult, err := s.AccountSwitch.PrepareSwitch(chartSwitchRequest(suffix, accountswitch.StrategyFull))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	activeVersion := chartVersion("TR_TDHP_2026_V2_"+suffix, accountswitch.ChartVersionActive)
	resolved, err := s.AccountSwitch.ResolveAccount(activeVersion, resolveRequest(suffix, accountswitch.PurposeOutputKDV, "SALES_INVOICE"))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	voucher, err := s.Voucher.BuildVoucher(sourceDocument(suffix, voucherpipeline.DocumentTypeSalesInvoice, 1000000, 200000, 1200000))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	posting, err := s.Posting.PostDocument(postingRequest(suffix, voucher, postingruntime.SourceVoucherPipeline))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	trace, err := s.AuditTrace.RecordFromPosting(posting, "trace-sales-"+suffix, "idem-trace-sales-"+suffix, audittrace.ActionPostingPosted, "tdhp-live-suite", "SYSTEM")
	if err != nil {
		return TDHPLiveResult{}, err
	}

	reconciliation, err := s.Reconcile.Reconcile(reconciliationRequest(suffix, posting, trace))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	return liveResultFromArtifacts(switchResult, resolved, voucher, posting, trace, reconciliation), nil
}

func (s *TDHPLiveTestSuite) RunPurchaseInvoiceLiveE2E(suffix string) (TDHPLiveResult, error) {
	switchResult, err := s.AccountSwitch.PrepareSwitch(chartSwitchRequest(suffix, accountswitch.StrategyFull))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	activeVersion := chartVersion("TR_TDHP_2026_V2_"+suffix, accountswitch.ChartVersionActive)
	resolved, err := s.AccountSwitch.ResolveAccount(activeVersion, resolveRequest(suffix, accountswitch.PurposeInputKDV, "PURCHASE_INVOICE"))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	voucher, err := s.Voucher.BuildVoucher(sourceDocument(suffix, voucherpipeline.DocumentTypePurchaseInvoice, 1000000, 200000, 1200000))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	posting, err := s.Posting.PostDocument(postingRequest(suffix, voucher, postingruntime.SourcePurchaseRuntime))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	trace, err := s.AuditTrace.RecordFromPosting(posting, "trace-purchase-"+suffix, "idem-trace-purchase-"+suffix, audittrace.ActionPostingPosted, "tdhp-live-suite", "SYSTEM")
	if err != nil {
		return TDHPLiveResult{}, err
	}

	reconciliation, err := s.Reconcile.Reconcile(reconciliationRequest(suffix, posting, trace))
	if err != nil {
		return TDHPLiveResult{}, err
	}

	return liveResultFromArtifacts(switchResult, resolved, voucher, posting, trace, reconciliation), nil
}

func (s *TDHPLiveTestSuite) RunDifferenceScenario(suffix string) (reconciliationruntime.ReconciliationResult, error) {
	voucher, err := s.Voucher.BuildVoucher(sourceDocument(suffix, voucherpipeline.DocumentTypeSalesInvoice, 1000000, 200000, 1200000))
	if err != nil {
		return reconciliationruntime.ReconciliationResult{}, err
	}

	posting, err := s.Posting.PostDocument(postingRequest(suffix, voucher, postingruntime.SourceVoucherPipeline))
	if err != nil {
		return reconciliationruntime.ReconciliationResult{}, err
	}

	trace, err := s.AuditTrace.RecordFromPosting(posting, "trace-diff-"+suffix, "idem-trace-diff-"+suffix, audittrace.ActionPostingPosted, "tdhp-live-suite", "SYSTEM")
	if err != nil {
		return reconciliationruntime.ReconciliationResult{}, err
	}

	req := reconciliationRequest(suffix, posting, trace)
	req.ReconciliationID = "recon-diff-" + suffix
	req.IdempotencyKey = "idem-recon-diff-" + suffix
	req.ExpectedDocument.ExpectedDebitKurus = posting.TotalDebitKurus - 1000

	return s.Reconcile.Reconcile(req)
}

func (s *TDHPLiveTestSuite) ExportPostingAuditTrace(suffix string) (audittrace.AuditTraceExport, error) {
	from := liveTime().AddDate(0, 0, -1)
	to := liveTime().AddDate(0, 0, 1)

	return s.AuditTrace.ExportTenantTrace(
		"tenant-001",
		"corr-export-"+suffix,
		"req-export-"+suffix,
		"export-tdhp-live-"+suffix,
		audittrace.SourceDocumentPostingRuntime,
		from,
		to,
	)
}

func liveResultFromArtifacts(
	switchResult accountswitch.SwitchResult,
	resolved accountswitch.ResolveResult,
	voucher voucherpipeline.Voucher,
	posting postingruntime.PostingEntry,
	trace audittrace.AuditTraceRecord,
	reconciliation reconciliationruntime.ReconciliationResult,
) TDHPLiveResult {
	return TDHPLiveResult{
		SwitchReady:      switchResult.RuntimeSwitchReady && switchResult.MappingReady && switchResult.AuditReady,
		AccountResolved:  resolved.Resolved,
		VoucherReady:     voucher.PostingReady && voucher.Balanced,
		PostingPosted:    posting.Status == postingruntime.PostingStatusPosted,
		AuditTraceStored: trace.Status == audittrace.TraceStatusRecorded,
		Reconciled:       reconciliation.Status == reconciliationruntime.ReconciliationStatusMatched,
		LedgerReady:      reconciliation.LedgerClosureReady,
		AccountCode:      resolved.AccountCode,
		VoucherID:        voucher.VoucherID,
		PostingID:        posting.PostingID,
		TraceID:          trace.TraceID,
		ReconciliationID: reconciliation.ReconciliationID,
	}
}

func chartSwitchConfig() accountswitch.RuntimeConfig {
	return accountswitch.RuntimeConfig{
		RuntimeEnabled:             true,
		DefaultCountryCode:         "TR",
		DefaultCurrencyCode:        "TRY",
		ApprovalRequired:           true,
		EvidenceRequired:           true,
		IdempotencyRequired:        true,
		CanaryAllowed:              true,
		RollbackAllowed:            true,
		MinCanaryPercent:           1,
		MaxCanaryPercent:           25,
		RequiredEvidenceFileSuffix: ".md",
		AllowedStrategies: []accountswitch.SwitchStrategy{
			accountswitch.StrategyFull,
			accountswitch.StrategyCanary,
			accountswitch.StrategyBlueGreen,
			accountswitch.StrategyRollback,
		},
		RequiredPurposes: []accountswitch.AccountPurpose{
			accountswitch.PurposeReceivable,
			accountswitch.PurposeSales,
			accountswitch.PurposeOutputKDV,
			accountswitch.PurposeInventory,
			accountswitch.PurposeInputKDV,
			accountswitch.PurposePayable,
			accountswitch.PurposeBank,
		},
	}
}

func voucherConfig() voucherpipeline.RuntimeConfig {
	return voucherpipeline.RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		IdempotencyRequired:   true,
		StrictBalanceRequired: true,
		RequireTaxTrace:       true,
		RequirePartyTrace:     true,
		AllowedDocumentTypes: []voucherpipeline.DocumentType{
			voucherpipeline.DocumentTypeSalesInvoice,
			voucherpipeline.DocumentTypePurchaseInvoice,
			voucherpipeline.DocumentTypePaymentCollection,
			voucherpipeline.DocumentTypeSalesRefund,
			voucherpipeline.DocumentTypePurchaseRefund,
			voucherpipeline.DocumentTypeOpeningBalance,
		},
		RequiredStages: []voucherpipeline.PipelineStage{
			voucherpipeline.StageInputValidated,
			voucherpipeline.StageAccountMapped,
			voucherpipeline.StageLinesBuilt,
			voucherpipeline.StageBalanced,
			voucherpipeline.StagePostingReady,
		},
	}
}

func postingConfig() postingruntime.RuntimeConfig {
	return postingruntime.RuntimeConfig{
		RuntimeEnabled:      true,
		DefaultCurrencyCode: "TRY",
		IdempotencyRequired: true,
		RequireVoucherReady: true,
		RequireBalanced:     true,
		RequireAuditTrace:   true,
		AppendOnlyLedger:    true,
		AllowReversal:       true,
		AllowedPostingSources: []postingruntime.PostingSource{
			postingruntime.SourceVoucherPipeline,
			postingruntime.SourceSalesRuntime,
			postingruntime.SourcePurchaseRuntime,
			postingruntime.SourcePaymentRuntime,
			postingruntime.SourceManualRuntime,
		},
	}
}

func auditConfig() audittrace.RuntimeConfig {
	return audittrace.RuntimeConfig{
		PersistenceEnabled:   true,
		AppendOnly:           true,
		IdempotencyRequired:  true,
		EvidenceHashRequired: true,
		SnapshotHashRequired: true,
		ActorRequired:        true,
		RetentionDays:        3650,
		AllowedSources: []audittrace.TraceSource{
			audittrace.SourceRealVoucherPipeline,
			audittrace.SourceDocumentPostingRuntime,
			audittrace.SourceChartAccountVersionSwitch,
			audittrace.SourceReconciliationRuntime,
			audittrace.SourceTDHPLiveTests,
			audittrace.SourceManualReview,
		},
		AllowedActions: []audittrace.TraceAction{
			audittrace.ActionVoucherBuilt,
			audittrace.ActionPostingPrepared,
			audittrace.ActionPostingPosted,
			audittrace.ActionPostingReversed,
			audittrace.ActionPostingRejected,
			audittrace.ActionAccountVersionSwitched,
			audittrace.ActionReconciliationMatched,
			audittrace.ActionReconciliationDifference,
			audittrace.ActionManualReviewQueued,
		},
	}
}

func reconciliationConfig() reconciliationruntime.RuntimeConfig {
	return reconciliationruntime.RuntimeConfig{
		RuntimeEnabled:         true,
		DefaultCurrencyCode:    "TRY",
		IdempotencyRequired:    true,
		AppendOnlyResult:       true,
		RequireBalancedPosting: true,
		RequireAuditTrace:      true,
		ManualReviewEnabled:    true,
		ToleranceKurus:         0,
		AllowedActions: []reconciliationruntime.ReconciliationAction{
			reconciliationruntime.ActionPostingVsDocument,
			reconciliationruntime.ActionPostingVsAuditTrace,
			reconciliationruntime.ActionReversalVsPosting,
			reconciliationruntime.ActionPeriodBalance,
			reconciliationruntime.ActionManualReviewRegister,
		},
	}
}

func chartSwitchRequest(suffix string, strategy accountswitch.SwitchStrategy) accountswitch.SwitchRequest {
	return accountswitch.SwitchRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-switch-" + suffix,
		RequestID:      "req-switch-" + suffix,
		IdempotencyKey: "idem-switch-" + suffix,
		SwitchID:       "switch-" + suffix,
		Strategy:       strategy,
		CurrentVersion: chartVersion("TR_TDHP_2026_V1_"+suffix, accountswitch.ChartVersionActive),
		TargetVersion:  chartVersion("TR_TDHP_2026_V2_"+suffix, accountswitch.ChartVersionReady),
		RequestedBy:    "tdhp-live-suite",
		RequestedAt:    liveTime(),
	}
}

func chartVersion(code string, status accountswitch.ChartVersionStatus) accountswitch.ChartVersion {
	now := liveTime()

	return accountswitch.ChartVersion{
		VersionID:           "chart-" + code,
		VersionCode:         code,
		PreviousVersion:     "PREV-" + code,
		Status:              status,
		CountryCode:         "TR",
		CurrencyCode:        "TRY",
		LegalReference:      "TR TDHP live test legal reference",
		ChartArtifactPath:   "configs/faz3/tdhp/" + code + ".json",
		MappingArtifactPath: "configs/faz3/tdhp/" + code + ".mapping.json",
		ConfigArtifactPath:  "configs/faz3/tdhp/" + code + ".config.json",
		EvidenceFilePath:    "docs/faz3/evidence/" + code + ".md",
		EvidenceHash:        "sha256:" + code,
		Rules: []accountswitch.ChartAccountRule{
			{Purpose: accountswitch.PurposeReceivable, AccountCode: "120.01", AccountName: "Alıcılar", RequiredPrefix: "120", Active: true},
			{Purpose: accountswitch.PurposeSales, AccountCode: "600.01", AccountName: "Yurt içi satışlar", RequiredPrefix: "600", Active: true},
			{Purpose: accountswitch.PurposeOutputKDV, AccountCode: "391.01.20", AccountName: "Hesaplanan KDV", RequiredPrefix: "391", Active: true},
			{Purpose: accountswitch.PurposeInventory, AccountCode: "153.01", AccountName: "Ticari mallar", RequiredPrefix: "153", Active: true},
			{Purpose: accountswitch.PurposeInputKDV, AccountCode: "191.01.20", AccountName: "İndirilecek KDV", RequiredPrefix: "191", Active: true},
			{Purpose: accountswitch.PurposePayable, AccountCode: "320.01", AccountName: "Satıcılar", RequiredPrefix: "320", Active: true},
			{Purpose: accountswitch.PurposeBank, AccountCode: "102.01", AccountName: "Bankalar", RequiredPrefix: "102", Active: true},
			{Purpose: accountswitch.PurposeSalesReturn, AccountCode: "610.01", AccountName: "Satıştan iadeler", RequiredPrefix: "610", Active: true},
			{Purpose: accountswitch.PurposeOpeningBalance, AccountCode: "500.01", AccountName: "Sermaye", RequiredPrefix: "500", Active: true},
		},
		EffectiveFrom: now,
		ApprovedBy:    "tdhp-admin",
		ApprovedAt:    now,
		CreatedAt:     now,
	}
}

func resolveRequest(suffix string, purpose accountswitch.AccountPurpose, documentContext string) accountswitch.ResolveRequest {
	return accountswitch.ResolveRequest{
		TenantID:        "tenant-001",
		VersionCode:     "TR_TDHP_2026_V2_" + suffix,
		Purpose:         purpose,
		DocumentContext: documentContext,
		RequestedAt:     liveTime(),
	}
}

func sourceDocument(suffix string, documentType voucherpipeline.DocumentType, net int64, tax int64, gross int64) voucherpipeline.SourceDocument {
	return voucherpipeline.SourceDocument{
		TenantID:         "tenant-001",
		CorrelationID:    "corr-doc-" + suffix,
		RequestID:        "req-doc-" + suffix,
		IdempotencyKey:   "idem-doc-" + suffix,
		DocumentType:     documentType,
		DocumentID:       "document-" + suffix,
		DocumentNo:       "DOC-" + suffix,
		DocumentDate:     liveTime(),
		PartyID:          "party-001",
		PartyTitle:       "Test Cari A.S.",
		PartyTaxNo:       "1234567890",
		NetAmountKurus:   net,
		TaxAmountKurus:   tax,
		GrossAmountKurus: gross,
		TaxRateBps:       2000,
		CurrencyCode:     "TRY",
		Description:      "TDHP live test document",
		SourceSystem:     "TDHP_LIVE_TESTS",
		RequestedBy:      "tdhp-live-suite",
		RequestedAt:      liveTime(),
	}
}

func postingRequest(suffix string, voucher voucherpipeline.Voucher, source postingruntime.PostingSource) postingruntime.PostingRequest {
	return postingruntime.PostingRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-posting-" + suffix,
		RequestID:      "req-posting-" + suffix,
		IdempotencyKey: "idem-posting-" + suffix,
		PostingID:      "posting-" + suffix,
		PostingSource:  source,
		Voucher:        voucher,
		RequestedBy:    "tdhp-live-suite",
		RequestedAt:    liveTime(),
	}
}

func reconciliationRequest(suffix string, posting postingruntime.PostingEntry, trace audittrace.AuditTraceRecord) reconciliationruntime.ReconciliationRequest {
	return reconciliationruntime.ReconciliationRequest{
		TenantID:         "tenant-001",
		CorrelationID:    "corr-recon-" + suffix,
		RequestID:        "req-recon-" + suffix,
		IdempotencyKey:   "idem-recon-" + suffix,
		ReconciliationID: "recon-" + suffix,
		Action:           reconciliationruntime.ActionPostingVsAuditTrace,
		ExpectedDocument: reconciliationruntime.ExpectedDocument{
			DocumentType:        posting.DocumentType,
			DocumentID:          posting.DocumentID,
			DocumentNo:          posting.DocumentNo,
			DocumentDate:        posting.DocumentDate,
			CurrencyCode:        posting.CurrencyCode,
			ExpectedDebitKurus:  posting.TotalDebitKurus,
			ExpectedCreditKurus: posting.TotalCreditKurus,
			ExpectedGrossKurus:  posting.TotalDebitKurus,
			ExpectedPostingID:   posting.PostingID,
			ExpectedVoucherID:   posting.VoucherID,
		},
		PostingEntry: posting,
		AuditTrace:   trace,
		RequestedBy:  "tdhp-live-suite",
		RequestedAt:  liveTime(),
	}
}

func liveTime() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func (r TDHPLiveResult) RequireReady() error {
	if !r.SwitchReady {
		return fmt.Errorf("switch not ready")
	}
	if !r.AccountResolved {
		return fmt.Errorf("account not resolved")
	}
	if !r.VoucherReady {
		return fmt.Errorf("voucher not ready")
	}
	if !r.PostingPosted {
		return fmt.Errorf("posting not posted")
	}
	if !r.AuditTraceStored {
		return fmt.Errorf("audit trace not stored")
	}
	if !r.Reconciled {
		return fmt.Errorf("not reconciled")
	}
	if !r.LedgerReady {
		return fmt.Errorf("ledger not ready")
	}
	return nil
}
