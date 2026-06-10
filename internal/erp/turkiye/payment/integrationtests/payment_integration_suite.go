package integrationtests

import (
	"time"

	bank "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/bankcollection"
	payerr "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/errorretry"
	audit "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/integrationaudit"
	pos "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/pos"
	recon "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/reconciliation"
	refund "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/refundcancel"
	status "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/statussync"
)

type PaymentIntegrationSuite struct {
	POSProviderRuntime       *pos.POSProviderRuntime
	BankCollectionRuntime    *bank.BankCollectionRuntime
	ReconciliationRuntime    *recon.ReconciliationRuntime
	RefundCancelRuntime      *refund.RefundCancelRuntime
	PaymentStatusSyncRuntime *status.PaymentStatusSyncRuntime
	PaymentErrorRetryRuntime *payerr.PaymentErrorRetryReversalRuntime
	IntegrationAuditRuntime  *audit.IntegrationAuditRuntime
}

func NewPaymentIntegrationSuite() (*PaymentIntegrationSuite, error) {
	posRuntime, err := pos.NewPOSProviderRuntime(pos.POSProviderConfig{
		ProviderCode:        "SIM_BANK_POS",
		Mode:                pos.ProviderModeSimulation,
		RealPaymentGateOpen: false,
		ProductionApproved:  false,
		EndpointBaseURL:     "https://simulation.local/pos",
		CredentialRef:       "secret://simulation/pos",
		RequestTimeoutMS:    5000,
		MaxRetryCount:       3,
		ThreeDSEnabled:      true,
		CaptureRequired:     true,
		IdempotencyRequired: true,
	})
	if err != nil {
		return nil, err
	}

	bankRuntime, err := bank.NewBankCollectionRuntime(bank.RuntimeConfig{
		Mode:                         bank.RuntimeModeSimulation,
		ProviderBankCode:             "SIM_BANK",
		RealBankGateOpen:             false,
		ProductionApproved:           false,
		EndpointBaseURL:              "https://simulation.local/bank",
		CredentialRef:                "secret://simulation/bank",
		RequestTimeoutMS:             5000,
		MaxRetryCount:                3,
		IdempotencyRequired:          true,
		StatementHashRequired:        true,
		ReconciliationToleranceKurus: 100,
	})
	if err != nil {
		return nil, err
	}

	reconciliationRuntime, err := recon.NewReconciliationRuntime(recon.RuntimeConfig{
		RuntimeEnabled:               true,
		DefaultCurrencyCode:          "TRY",
		ReconciliationToleranceKurus: 100,
		IdempotencyRequired:          true,
		StatementHashRequired:        true,
		ProviderPayloadHashRequired:  true,
		ManualReviewEnabled:          true,
		AllowedChannels: []recon.ReconciliationChannel{
			recon.ChannelPOS,
			recon.ChannelVirtualPOS,
			recon.ChannelBankTransfer,
			recon.ChannelBankCollection,
			recon.ChannelMarketplaceSettlement,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
	})
	if err != nil {
		return nil, err
	}

	refundRuntime, err := refund.NewRefundCancelRuntime(refund.RuntimeConfig{
		Mode:                           refund.RuntimeModeSimulation,
		RealPaymentGateOpen:            false,
		ProductionApproved:             false,
		DefaultCurrencyCode:            "TRY",
		IdempotencyRequired:            true,
		ProviderPayloadHashRequired:    true,
		ReasonRequired:                 true,
		PartialRefundAllowed:           true,
		FullRefundAllowed:              true,
		VoidAllowedBeforeSettlement:    true,
		CancelAllowedBeforeCapture:     true,
		ReversalAllowedAfterSettlement: true,
		AllowedChannels: []refund.PaymentChannel{
			refund.ChannelPOS,
			refund.ChannelVirtualPOS,
			refund.ChannelBankTransfer,
			refund.ChannelBankCollection,
			refund.ChannelMarketplaceSettlement,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
	})
	if err != nil {
		return nil, err
	}

	statusRuntime, err := status.NewPaymentStatusSyncRuntime(status.RuntimeConfig{
		CallbackSignatureRequired: true,
		WebhookSignatureRequired:  true,
		PollEnabled:               true,
		ManualRecheckEnabled:      true,
		PollIntervalSeconds:       300,
		MaxPollBatchSize:          100,
		MaxRetryCount:             3,
		AllowedChannels: []status.PaymentChannel{
			status.PaymentChannelPOS,
			status.PaymentChannelVirtualPOS,
			status.PaymentChannelBankTransfer,
			status.PaymentChannelBankCollection,
			status.PaymentChannelMarketplaceSettlement,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
	})
	if err != nil {
		return nil, err
	}

	errorRetryRuntime, err := payerr.NewPaymentErrorRetryReversalRuntime(payerr.RuntimeConfig{
		Mode:                        payerr.RuntimeModeSimulation,
		RealPaymentGateOpen:         false,
		ProductionApproved:          false,
		MaxRetryCount:               3,
		BaseRetryDelaySec:           60,
		MaxRetryDelaySec:            600,
		DLQEnabled:                  true,
		ManualReviewEnabled:         true,
		ReversalReasonRequired:      true,
		IdempotencyRequired:         true,
		ProviderPayloadHashRequired: true,
		AllowedChannels: []payerr.PaymentChannel{
			payerr.PaymentChannelPOS,
			payerr.PaymentChannelVirtualPOS,
			payerr.PaymentChannelBankCollection,
			payerr.PaymentChannelBankTransfer,
			payerr.PaymentChannelMarketplace,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
		RetryableErrorCodes: []string{
			"PROVIDER_TIMEOUT",
			"PROVIDER_RATE_LIMITED",
			"BANK_TEMPORARY_UNAVAILABLE",
		},
		FatalErrorCodes: []string{
			"INVALID_CARD",
			"INSUFFICIENT_FUNDS",
			"INVALID_IBAN",
			"INVALID_AMOUNT",
		},
		ManualReviewCodes: []string{
			"CHARGEBACK_RISK",
			"BANK_RECONCILIATION_CONFLICT",
		},
	})
	if err != nil {
		return nil, err
	}

	auditRuntime, err := audit.NewIntegrationAuditRuntime(audit.RuntimeConfig{
		RuntimeEnabled:               true,
		Mode:                         audit.RuntimeModeSimulation,
		RealProviderGateOpen:         false,
		ProductionApproved:           false,
		IdempotencyRequired:          true,
		EvidenceHashRequired:         true,
		ArtifactPathRequired:         true,
		FailBlocksClosure:            true,
		WarnRequiresReview:           true,
		MinimumPassCountForReadiness: 20,
		RequiredScopes: []audit.AuditScope{
			audit.ScopePOSProviderRuntime,
			audit.ScopeBankCollectionRuntime,
			audit.ScopeReconciliationRuntime,
			audit.ScopeRefundCancelRuntime,
			audit.ScopePaymentStatusSync,
			audit.ScopePaymentErrorRetryRuntime,
			audit.ScopePaymentIntegrationE2E,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
			"INTERNAL_AUDIT",
		},
	})
	if err != nil {
		return nil, err
	}

	return &PaymentIntegrationSuite{
		POSProviderRuntime:       posRuntime,
		BankCollectionRuntime:    bankRuntime,
		ReconciliationRuntime:    reconciliationRuntime,
		RefundCancelRuntime:      refundRuntime,
		PaymentStatusSyncRuntime: statusRuntime,
		PaymentErrorRetryRuntime: errorRetryRuntime,
		IntegrationAuditRuntime:  auditRuntime,
	}, nil
}

func integrationTime() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func POSSaleRequest() pos.POSRequest {
	now := integrationTime()

	return pos.POSRequest{
		TenantID:             "tenant-001",
		CorrelationID:        "corr-pos-e2e",
		RequestID:            "req-pos-e2e",
		IdempotencyKey:       "idem-pos-e2e-sale",
		Operation:            pos.OperationSale,
		PaymentTransactionID: "pay-pos-e2e-001",
		SourceDocumentType:   "SALES_INVOICE",
		SourceDocumentID:     "invoice-pos-e2e-001",
		SourceDocumentNo:     "INV-POS-E2E-001",
		MerchantID:           "merchant-001",
		TerminalID:           "terminal-001",
		ProviderCode:         "SIM_BANK_POS",
		AmountKurus:          100000,
		CurrencyCode:         "TRY",
		InstallmentCount:     1,
		CardToken:            "card-token-e2e",
		MaskedCardPAN:        "4508********1234",
		CardHolderName:       "TEST USER",
		ThreeDSReturnURL:     "https://pix2pi.local/3ds/callback",
		RequestedAt:          now,
	}
}

func PaymentStatusWebhookFromPOS(providerTxnID string) status.PaymentStatusSyncRequest {
	now := integrationTime()

	return status.PaymentStatusSyncRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-pos-e2e",
		RequestID:             "req-status-pos-e2e",
		IdempotencyKey:        "idem-status-pos-e2e",
		Source:                status.SyncSourceWebhook,
		PaymentTransactionID:  "pay-pos-e2e-001",
		TransactionNo:         "PAY-POS-E2E-001",
		Channel:               status.PaymentChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: providerTxnID,
		ProviderStatus:        status.ProviderStatusSold,
		ProviderStatusText:    "sold",
		ProviderPayloadHash:   "sha256:pos-status-payload",
		AmountKurus:           100000,
		CurrencyCode:          "TRY",
		WebhookSignature:      "sha256:webhook-signature",
		ProviderEventTime:     now,
		ReceivedAt:            now.Add(time.Second),
	}
}

func RefundRequest(providerTxnID string) refund.RefundCancelRequest {
	now := integrationTime()

	return refund.RefundCancelRequest{
		TenantID:                   "tenant-001",
		CorrelationID:              "corr-refund-e2e",
		RequestID:                  "req-refund-e2e",
		IdempotencyKey:             "idem-refund-e2e",
		PaymentTransactionID:       "pay-pos-e2e-001",
		TransactionNo:              "PAY-POS-E2E-001",
		Channel:                    refund.ChannelPOS,
		ProviderCode:               "SIM_BANK_POS",
		ProviderTransactionID:      providerTxnID,
		ProviderPayloadHash:        "sha256:refund-provider-payload",
		SourceDocumentType:         "SALES_INVOICE",
		SourceDocumentID:           "invoice-pos-e2e-001",
		SourceDocumentNo:           "INV-POS-E2E-001",
		OriginalAmountKurus:        100000,
		RequestedAmountKurus:       25000,
		AlreadyRefundedAmountKurus: 0,
		CurrencyCode:               "TRY",
		Settled:                    false,
		Captured:                   true,
		Authorized:                 true,
		ReasonCode:                 "CUSTOMER_RETURN",
		ReasonText:                 "Musteri iadesi",
		RequestedBy:                "user-001",
		RequestedAt:                now,
	}
}

func RefundReconciliationRequest(providerTxnID string) recon.ReconciliationRequest {
	now := integrationTime()

	return recon.ReconciliationRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-refund-recon-e2e",
		RequestID:             "req-refund-recon-e2e",
		IdempotencyKey:        "idem-refund-recon-e2e",
		ReconciliationID:      "recon-refund-e2e-001",
		PaymentTransactionID:  "pay-pos-e2e-001",
		TransactionNo:         "PAY-POS-E2E-001",
		Channel:               recon.ChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: providerTxnID,
		ProviderPayloadHash:   "sha256:refund-reconciliation-provider",
		SourceDocumentType:    "SALES_INVOICE",
		SourceDocumentID:      "invoice-pos-e2e-001",
		SourceDocumentNo:      "INV-POS-E2E-001",
		LedgerMovementID:      "ledger-refund-e2e-001",
		JournalID:             "journal-refund-e2e-001",
		ExpectedAmountKurus:   25000,
		ActualAmountKurus:     25000,
		CurrencyCode:          "TRY",
		OccurredAt:            now,
		RequestedAt:           now.Add(time.Second),
	}
}

func BankCollectionRequest() bank.CollectionRequest {
	now := integrationTime()

	return bank.CollectionRequest{
		TenantID:             "tenant-001",
		CorrelationID:        "corr-bank-e2e",
		RequestID:            "req-bank-e2e",
		IdempotencyKey:       "idem-bank-e2e",
		Operation:            bank.OperationRegisterTransfer,
		PaymentTransactionID: "pay-bank-e2e-001",
		CollectionNo:         "COL-BANK-E2E-001",
		BankAccountID:        "bank-account-001",
		ProviderBankCode:     "SIM_BANK",
		IBAN:                 "TR000000000000000000000001",
		BankReferenceNo:      "BANK-REF-E2E-001",
		StatementLineID:      "STMT-E2E-001",
		StatementPayloadHash: "sha256:statement-e2e",
		PayerPartyID:         "party-001",
		PayerTitle:           "Test Musteri A.S.",
		PayerTaxNo:           "1234567890",
		Description:          "E2E banka tahsilati",
		SourceDocumentType:   "SALES_INVOICE",
		SourceDocumentID:     "invoice-bank-e2e-001",
		SourceDocumentNo:     "INV-BANK-E2E-001",
		AmountKurus:          150000,
		CurrencyCode:         "TRY",
		ExpectedAmountKurus:  150000,
		ActualAmountKurus:    150050,
		ValueDate:            now,
		ReceivedAt:           now.Add(time.Second),
		RequestedAt:          now.Add(2 * time.Second),
	}
}

func BankReconciliationRequest() recon.ReconciliationRequest {
	now := integrationTime()

	return recon.ReconciliationRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-bank-recon-e2e",
		RequestID:             "req-bank-recon-e2e",
		IdempotencyKey:        "idem-bank-recon-e2e",
		ReconciliationID:      "recon-bank-e2e-001",
		PaymentTransactionID:  "pay-bank-e2e-001",
		TransactionNo:         "PAY-BANK-E2E-001",
		Channel:               recon.ChannelBankCollection,
		ProviderCode:          "SIM_BANK",
		ProviderTransactionID: "BANK-REF-E2E-001",
		ProviderPayloadHash:   "sha256:bank-provider-e2e",
		BankAccountID:         "bank-account-001",
		BankReferenceNo:       "BANK-REF-E2E-001",
		StatementLineID:       "STMT-E2E-001",
		StatementPayloadHash:  "sha256:statement-e2e",
		SourceDocumentType:    "SALES_INVOICE",
		SourceDocumentID:      "invoice-bank-e2e-001",
		SourceDocumentNo:      "INV-BANK-E2E-001",
		LedgerMovementID:      "ledger-bank-e2e-001",
		JournalID:             "journal-bank-e2e-001",
		ExpectedAmountKurus:   150000,
		ActualAmountKurus:     150050,
		CurrencyCode:          "TRY",
		OccurredAt:            now,
		RequestedAt:           now.Add(time.Second),
	}
}

func BankManualStatusRecheck() status.PaymentStatusSyncRequest {
	now := integrationTime()

	return status.PaymentStatusSyncRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-bank-status-e2e",
		RequestID:             "req-bank-status-e2e",
		IdempotencyKey:        "idem-bank-status-e2e",
		Source:                status.SyncSourceManualRecheck,
		PaymentTransactionID:  "pay-bank-e2e-001",
		TransactionNo:         "PAY-BANK-E2E-001",
		Channel:               status.PaymentChannelBankCollection,
		ProviderCode:          "SIM_BANK",
		ProviderTransactionID: "BANK-REF-E2E-001",
		ProviderStatus:        status.ProviderStatusReconciled,
		ProviderStatusText:    "reconciled",
		ProviderPayloadHash:   "sha256:bank-status-e2e",
		BankReferenceNo:       "BANK-REF-E2E-001",
		StatementLineID:       "STMT-E2E-001",
		AmountKurus:           150000,
		CurrencyCode:          "TRY",
		ProviderEventTime:     now,
		ReceivedAt:            now.Add(time.Second),
	}
}

func RetryablePaymentErrorEvent() payerr.PaymentErrorEvent {
	now := integrationTime()

	return payerr.PaymentErrorEvent{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-error-e2e",
		RequestID:             "req-error-e2e",
		IdempotencyKey:        "idem-error-e2e",
		PaymentTransactionID:  "pay-pos-e2e-001",
		TransactionNo:         "PAY-POS-E2E-001",
		Channel:               payerr.PaymentChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: "provider-pay-e2e-001",
		Operation:             payerr.OperationAuthorize,
		ProviderErrorCode:     "PROVIDER_TIMEOUT",
		ProviderErrorText:     "timeout",
		ProviderPayloadHash:   "sha256:error-payload",
		AmountKurus:           100000,
		CurrencyCode:          "TRY",
		RetryCount:            0,
		OccurredAt:            now,
		ReceivedAt:            now.Add(time.Second),
	}
}

func ReadyAuditBundle() audit.EvidenceBundle {
	now := integrationTime()

	return audit.EvidenceBundle{
		TenantID:      "tenant-001",
		CorrelationID: "corr-audit-e2e",
		RequestID:     "req-audit-e2e",
		BundleID:      "bundle-payment-integration-e2e",
		Events: []audit.IntegrationAuditEvent{
			auditEvent(audit.ScopePOSProviderRuntime, 32),
			auditEvent(audit.ScopeBankCollectionRuntime, 32),
			auditEvent(audit.ScopeReconciliationRuntime, 42),
			auditEvent(audit.ScopeRefundCancelRuntime, 49),
			auditEvent(audit.ScopePaymentStatusSync, 38),
			auditEvent(audit.ScopePaymentErrorRetryRuntime, 39),
			auditEvent(audit.ScopePaymentIntegrationE2E, 25),
		},
		PreparedAt: now,
	}
}

func auditEvent(scope audit.AuditScope, passCount int) audit.IntegrationAuditEvent {
	now := integrationTime()

	return audit.IntegrationAuditEvent{
		TenantID:             "tenant-001",
		CorrelationID:        "corr-audit-e2e",
		RequestID:            "req-audit-e2e",
		IdempotencyKey:       "idem-audit-" + string(scope),
		AuditEventID:         "audit-event-" + string(scope),
		Scope:                scope,
		Source:               audit.SourceRealAudit,
		Status:               audit.EventStatusPass,
		ProviderCode:         "INTERNAL_AUDIT",
		PaymentTransactionID: "pay-e2e",
		TransactionNo:        "PAY-E2E",
		CheckName:            "payment integration e2e audit",
		ArtifactPath:         "internal/erp/turkiye/payment/" + string(scope),
		EvidenceFilePath:     "docs/faz3/evidence/" + string(scope) + ".md",
		EvidenceHash:         "sha256:" + string(scope),
		PassCount:            passCount,
		FailCount:            0,
		WarnCount:            0,
		OccurredAt:           now,
	}
}
