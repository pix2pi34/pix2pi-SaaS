package runtimetests

import (
	"time"

	audit "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/auditpersistence"
	exemption "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/exemption"
	kdv "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/kdv"
	rollout "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/rulerollout"
	withholding "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tax/withholding"
)

type TaxRuntimeTestSuite struct {
	KDVRuntime       *kdv.KDVRuntime
	StopajRuntime    *withholding.StopajRuntime
	ExemptionRuntime *exemption.TaxExemptionRuntime
	RolloutRuntime   *rollout.TaxRuleVersionRolloutRuntime
	AuditRuntime     *audit.TaxAuditPersistenceRuntime
	AuditRepository  *audit.InMemoryTaxAuditRepository
}

func NewTaxRuntimeTestSuite() (*TaxRuntimeTestSuite, error) {
	kdvRuntime, err := kdv.NewKDVRuntime(kdvConfig(), kdvRules())
	if err != nil {
		return nil, err
	}

	stopajRuntime, err := withholding.NewStopajRuntime(stopajConfig(), stopajRules())
	if err != nil {
		return nil, err
	}

	exemptionRuntime, err := exemption.NewTaxExemptionRuntime(exemptionConfig(), exemptionRules())
	if err != nil {
		return nil, err
	}

	rolloutRuntime, err := rollout.NewTaxRuleVersionRolloutRuntime(rolloutConfig())
	if err != nil {
		return nil, err
	}

	repository := audit.NewInMemoryTaxAuditRepository()
	auditRuntime, err := audit.NewTaxAuditPersistenceRuntime(auditConfig(), repository)
	if err != nil {
		return nil, err
	}

	return &TaxRuntimeTestSuite{
		KDVRuntime:       kdvRuntime,
		StopajRuntime:    stopajRuntime,
		ExemptionRuntime: exemptionRuntime,
		RolloutRuntime:   rolloutRuntime,
		AuditRuntime:     auditRuntime,
		AuditRepository:  repository,
	}, nil
}

func suiteTime() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func kdvConfig() kdv.RuntimeConfig {
	return kdv.RuntimeConfig{
		RuntimeEnabled:      true,
		ActiveRuleVersion:   "TR_KDV_2026_V1",
		DefaultCurrencyCode: "TRY",
		AuditRequired:       true,
		IdempotencyRequired: true,
		MinRateBps:          0,
		MaxRateBps:          2000,
		AllowedDocumentTypes: []kdv.DocumentType{
			kdv.DocumentTypeSalesInvoice,
			kdv.DocumentTypePurchaseInvoice,
			kdv.DocumentTypeSalesReturn,
			kdv.DocumentTypePurchaseReturn,
			kdv.DocumentTypeEBelgeDocument,
			kdv.DocumentTypeCustom,
		},
		AllowedDirections: []kdv.TaxDirection{
			kdv.DirectionOutput,
			kdv.DirectionInput,
			kdv.DirectionReturn,
		},
		AllowedRateCodes: []kdv.KDVRateCode{
			kdv.RateCodeKDV0,
			kdv.RateCodeKDV1,
			kdv.RateCodeKDV10,
			kdv.RateCodeKDV20,
			kdv.RateCodeCustom,
		},
	}
}

func kdvRules() []kdv.KDVRule {
	effectiveFrom := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	return []kdv.KDVRule{
		{
			RuleID:               "KDV-OUTPUT-20-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             kdv.RateCodeKDV20,
			RateBps:              2000,
			Direction:            kdv.DirectionOutput,
			EffectiveFrom:        effectiveFrom,
			OutputAccountCode:    "391.01.20",
			DeclarationCode:      "KDV_OUTPUT_20",
			ExemptionAllowed:     true,
			ReverseChargeAllowed: false,
			Active:               true,
		},
		{
			RuleID:               "KDV-INPUT-20-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             kdv.RateCodeKDV20,
			RateBps:              2000,
			Direction:            kdv.DirectionInput,
			EffectiveFrom:        effectiveFrom,
			InputAccountCode:     "191.01.20",
			DeclarationCode:      "KDV_INPUT_20",
			ExemptionAllowed:     false,
			ReverseChargeAllowed: true,
			Active:               true,
		},
		{
			RuleID:               "KDV-OUTPUT-10-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             kdv.RateCodeKDV10,
			RateBps:              1000,
			Direction:            kdv.DirectionOutput,
			EffectiveFrom:        effectiveFrom,
			OutputAccountCode:    "391.01.10",
			DeclarationCode:      "KDV_OUTPUT_10",
			ExemptionAllowed:     true,
			ReverseChargeAllowed: false,
			Active:               true,
		},
		{
			RuleID:               "KDV-OUTPUT-0-2026",
			RuleVersion:          "TR_KDV_2026_V1",
			RateCode:             kdv.RateCodeKDV0,
			RateBps:              0,
			Direction:            kdv.DirectionOutput,
			EffectiveFrom:        effectiveFrom,
			OutputAccountCode:    "391.00",
			DeclarationCode:      "KDV_ZERO_RATE",
			ExemptionAllowed:     true,
			ReverseChargeAllowed: false,
			Active:               true,
		},
	}
}

func stopajConfig() withholding.RuntimeConfig {
	return withholding.RuntimeConfig{
		RuntimeEnabled:      true,
		ActiveRuleVersion:   "TR_STOPAJ_2026_V1",
		DefaultCurrencyCode: "TRY",
		MaxRateBps:          4000,
		MinRateBps:          0,
		AuditRequired:       true,
		IdempotencyRequired: true,
		AllowedDocumentTypes: []withholding.DocumentType{
			withholding.DocumentTypePurchaseInvoice,
			withholding.DocumentTypeExpenseVoucher,
			withholding.DocumentTypeSelfEmployment,
			withholding.DocumentTypeRentAccrual,
			withholding.DocumentTypeCustom,
		},
		AllowedSubjects: []withholding.WithholdingSubject{
			withholding.SubjectRent,
			withholding.SubjectProfessionalService,
			withholding.SubjectSelfEmployment,
			withholding.SubjectFreelance,
			withholding.SubjectConstruction,
			withholding.SubjectDividend,
			withholding.SubjectCustom,
		},
	}
}

func stopajRules() []withholding.WithholdingRule {
	effectiveFrom := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	return []withholding.WithholdingRule{
		{
			RuleID:             "STOPAJ-RENT-2026",
			RuleVersion:        "TR_STOPAJ_2026_V1",
			Subject:            withholding.SubjectRent,
			RateBps:            2000,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			AccountCode:        "360.01",
			DeclarationCode:    "STOPAJ_RENT",
			Active:             true,
			ExemptionAllowed:   true,
		},
		{
			RuleID:             "STOPAJ-PROF-2026",
			RuleVersion:        "TR_STOPAJ_2026_V1",
			Subject:            withholding.SubjectProfessionalService,
			RateBps:            2000,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 50000,
			AccountCode:        "360.02",
			DeclarationCode:    "STOPAJ_PROFESSIONAL_SERVICE",
			Active:             true,
			ExemptionAllowed:   false,
		},
	}
}

func exemptionConfig() exemption.RuntimeConfig {
	return exemption.RuntimeConfig{
		RuntimeEnabled:      true,
		ActiveRuleVersion:   "TR_TAX_EXEMPTION_2026_V1",
		DefaultCurrencyCode: "TRY",
		AuditRequired:       true,
		IdempotencyRequired: true,
		MinOverrideRateBps:  0,
		MaxOverrideRateBps:  2000,
		AllowedDocumentTypes: []exemption.DocumentType{
			exemption.DocumentTypeSalesInvoice,
			exemption.DocumentTypePurchaseInvoice,
			exemption.DocumentTypeEBelgeDocument,
			exemption.DocumentTypeExpenseVoucher,
			exemption.DocumentTypeJournalDocument,
			exemption.DocumentTypeCustom,
		},
		AllowedTaxTypes: []exemption.TaxType{
			exemption.TaxTypeKDV,
			exemption.TaxTypeStopaj,
			exemption.TaxTypeOTV,
			exemption.TaxTypeDamga,
			exemption.TaxTypeCustom,
		},
	}
}

func exemptionRules() []exemption.ExemptionRule {
	effectiveFrom := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	return []exemption.ExemptionRule{
		{
			RuleID:             "KDV-FULL-EXPORT-2026",
			RuleVersion:        "TR_TAX_EXEMPTION_2026_V1",
			TaxType:            exemption.TaxTypeKDV,
			ExemptionCode:      "KDV_EXPORT_FULL",
			ExemptionScope:     exemption.ScopeFullExemption,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			AccountCode:        "391.00",
			DeclarationCode:    "KDV_EXPORT_EXEMPTION",
			LegalReference:     "KDV istisna test referansi",
			ReasonRequired:     true,
			Active:             true,
		},
		{
			RuleID:             "KDV-PARTIAL-2026",
			RuleVersion:        "TR_TAX_EXEMPTION_2026_V1",
			TaxType:            exemption.TaxTypeKDV,
			ExemptionCode:      "KDV_PARTIAL_50",
			ExemptionScope:     exemption.ScopePartialExemption,
			EffectiveFrom:      effectiveFrom,
			MinBaseAmountKurus: 1,
			ExemptRateBps:      5000,
			AccountCode:        "391.01",
			DeclarationCode:    "KDV_PARTIAL_EXEMPTION",
			LegalReference:     "KDV kismi istisna test referansi",
			ReasonRequired:     false,
			Active:             true,
		},
	}
}

func rolloutConfig() rollout.RuntimeConfig {
	return rollout.RuntimeConfig{
		RuntimeEnabled:             true,
		DefaultCountryCode:         "TR",
		ApprovalRequired:           true,
		LegalReferenceRequired:     true,
		AuditRequired:              true,
		IdempotencyRequired:        true,
		CanaryAllowed:              true,
		RollbackAllowed:            true,
		MinCanaryPercent:           1,
		MaxCanaryPercent:           25,
		RequiredEvidenceFileSuffix: ".md",
		AllowedTaxFamilies: []rollout.TaxFamily{
			rollout.TaxFamilyKDV,
			rollout.TaxFamilyStopaj,
			rollout.TaxFamilyTaxExemption,
			rollout.TaxFamilyOTV,
			rollout.TaxFamilyDamga,
			rollout.TaxFamilyCustom,
		},
		AllowedRolloutStrategies: []rollout.RolloutStrategy{
			rollout.StrategyFull,
			rollout.StrategyCanary,
			rollout.StrategyBlueGreen,
			rollout.StrategyRollback,
		},
	}
}

func auditConfig() audit.RuntimeConfig {
	return audit.RuntimeConfig{
		PersistenceEnabled:   true,
		AppendOnly:           true,
		IdempotencyRequired:  true,
		EvidenceHashRequired: true,
		RuleVersionRequired:  true,
		ActorRequired:        true,
		RetentionDays:        3650,
		AllowedTaxFamilies: []audit.TaxFamily{
			audit.TaxFamilyKDV,
			audit.TaxFamilyStopaj,
			audit.TaxFamilyTaxExemption,
			audit.TaxFamilyOTV,
			audit.TaxFamilyDamga,
			audit.TaxFamilyCustom,
		},
		AllowedAuditActions: []audit.AuditAction{
			audit.ActionKDVCalculated,
			audit.ActionStopajCalculated,
			audit.ActionExemptionApplied,
			audit.ActionRuleVersionRolled,
			audit.ActionRuleVersionActivated,
			audit.ActionRuleVersionRollback,
			audit.ActionValidationRejected,
			audit.ActionManualReview,
		},
		AllowedSourceRuntimes: []audit.SourceRuntime{
			audit.SourceKDVRuntime,
			audit.SourceStopajRuntime,
			audit.SourceTaxExemptionRuntime,
			audit.SourceRuleRolloutRuntime,
			audit.SourceTaxRuntimeTestSuite,
		},
	}
}

func KDVOutputRequest() kdv.KDVRequest {
	now := suiteTime()

	return kdv.KDVRequest{
		TenantID:           "tenant-001",
		CorrelationID:      "corr-tax-suite-kdv",
		RequestID:          "req-tax-suite-kdv",
		IdempotencyKey:     "idem-tax-suite-kdv",
		DocumentType:       kdv.DocumentTypeSalesInvoice,
		DocumentID:         "invoice-kdv-suite-001",
		DocumentNo:         "INV-KDV-SUITE-001",
		PartyID:            "party-001",
		PartyTitle:         "Test Musteri A.S.",
		PartyTaxNo:         "1234567890",
		Direction:          kdv.DirectionOutput,
		RateCode:           kdv.RateCodeKDV20,
		GrossAmountKurus:   1200000,
		NetAmountKurus:     1000000,
		TaxBaseAmountKurus: 1000000,
		CurrencyCode:       "TRY",
		DocumentDate:       now,
		RequestedAt:        now,
	}
}

func StopajRentRequest() withholding.WithholdingRequest {
	now := suiteTime()

	return withholding.WithholdingRequest{
		TenantID:           "tenant-001",
		CorrelationID:      "corr-tax-suite-stopaj",
		RequestID:          "req-tax-suite-stopaj",
		IdempotencyKey:     "idem-tax-suite-stopaj",
		DocumentType:       withholding.DocumentTypeRentAccrual,
		DocumentID:         "rent-suite-001",
		DocumentNo:         "RENT-SUITE-001",
		PartyID:            "party-landlord-001",
		PartyTitle:         "Test Mal Sahibi",
		PartyTaxNo:         "1234567890",
		Subject:            withholding.SubjectRent,
		GrossAmountKurus:   1000000,
		TaxBaseAmountKurus: 1000000,
		CurrencyCode:       "TRY",
		DocumentDate:       now,
		RequestedAt:        now,
	}
}

func KDVFullExemptionRequest() exemption.ExemptionRequest {
	now := suiteTime()

	return exemption.ExemptionRequest{
		TenantID:               "tenant-001",
		CorrelationID:          "corr-tax-suite-exemption",
		RequestID:              "req-tax-suite-exemption",
		IdempotencyKey:         "idem-tax-suite-exemption",
		DocumentType:           exemption.DocumentTypeSalesInvoice,
		DocumentID:             "invoice-exemption-suite-001",
		DocumentNo:             "INV-EXEMPTION-SUITE-001",
		PartyID:                "party-001",
		PartyTitle:             "Test Musteri A.S.",
		PartyTaxNo:             "1234567890",
		TaxType:                exemption.TaxTypeKDV,
		ExemptionCode:          "KDV_EXPORT_FULL",
		ExemptionReason:        "Ihracat istisnasi",
		GrossAmountKurus:       1000000,
		TaxBaseAmountKurus:     1000000,
		OriginalTaxRateBps:     2000,
		OriginalTaxAmountKurus: 200000,
		CurrencyCode:           "TRY",
		DocumentDate:           now,
		RequestedAt:            now,
	}
}

func TaxRolloutRequest() rollout.RolloutRequest {
	now := suiteTime()

	current := TaxVersion("TR_KDV_2026_V1", rollout.TaxFamilyKDV, rollout.VersionStatusActive)
	target := TaxVersion("TR_KDV_2026_V2", rollout.TaxFamilyKDV, rollout.VersionStatusReady)

	return rollout.RolloutRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-tax-suite-rollout",
		RequestID:      "req-tax-suite-rollout",
		IdempotencyKey: "idem-tax-suite-rollout",
		RolloutID:      "rollout-tax-suite-001",
		Strategy:       rollout.StrategyFull,
		CurrentVersion: current,
		TargetVersion:  target,
		RequestedBy:    "tax-admin",
		RequestedAt:    now,
	}
}

func TaxVersion(code string, family rollout.TaxFamily, status rollout.VersionStatus) rollout.TaxRuleVersion {
	now := suiteTime()

	return rollout.TaxRuleVersion{
		VersionID:           "ver-" + code,
		TaxFamily:           family,
		VersionCode:         code,
		PreviousVersionCode: "PREV-" + code,
		Status:              status,
		CountryCode:         "TR",
		LegalReference:      "TR tax legal reference",
		RuleArtifactPath:    "internal/erp/turkiye/tax/" + code,
		ConfigArtifactPath:  "configs/faz3/tax/" + code + ".json",
		EvidenceFilePath:    "docs/faz3/evidence/" + code + ".md",
		EvidenceHash:        "sha256:" + code,
		EffectiveFrom:       now,
		ApprovedBy:          "tax-admin",
		ApprovedAt:          now,
		CreatedAt:           now,
	}
}

func AuditRecordFromKDV(result kdv.KDVResult) audit.TaxAuditRecord {
	now := suiteTime()

	return audit.TaxAuditRecord{
		TenantID:            result.TenantID,
		CorrelationID:       result.CorrelationID,
		RequestID:           result.RequestID,
		IdempotencyKey:      "audit-" + result.IdempotencyKey,
		AuditID:             "audit-kdv-suite-001",
		TaxFamily:           audit.TaxFamilyKDV,
		SourceRuntime:       audit.SourceKDVRuntime,
		Action:              audit.ActionKDVCalculated,
		DecisionStatus:      audit.DecisionApplied,
		RuleVersion:         result.RuleVersion,
		DocumentType:        string(result.DocumentType),
		DocumentID:          result.DocumentID,
		DocumentNo:          result.DocumentNo,
		PartyID:             "party-001",
		PartyTaxNo:          "1234567890",
		TaxBaseAmountKurus:  result.TaxBaseAmountKurus,
		TaxAmountKurus:      result.KDVAmountKurus,
		CurrencyCode:        "TRY",
		EvidenceFilePath:    "docs/faz3/evidence/kdv-suite.md",
		EvidenceHash:        "sha256:kdv-suite-evidence",
		RequestHash:         "sha256:kdv-suite-request",
		ResultHash:          "sha256:kdv-suite-result",
		BeforeSnapshotHash:  "sha256:kdv-before",
		AfterSnapshotHash:   "sha256:kdv-after",
		AuditDecisionReason: result.AuditDecisionReason,
		ActorID:             "tax-runtime-suite",
		ActorRole:           "SYSTEM",
		CreatedAt:           now,
	}
}

func AuditRecordFromStopaj(result withholding.WithholdingResult) audit.TaxAuditRecord {
	now := suiteTime()

	return audit.TaxAuditRecord{
		TenantID:               result.TenantID,
		CorrelationID:          result.CorrelationID,
		RequestID:              result.RequestID,
		IdempotencyKey:         "audit-" + result.IdempotencyKey,
		AuditID:                "audit-stopaj-suite-001",
		TaxFamily:              audit.TaxFamilyStopaj,
		SourceRuntime:          audit.SourceStopajRuntime,
		Action:                 audit.ActionStopajCalculated,
		DecisionStatus:         audit.DecisionApplied,
		RuleVersion:            result.RuleVersion,
		DocumentType:           string(result.DocumentType),
		DocumentID:             result.DocumentID,
		DocumentNo:             result.DocumentNo,
		PartyID:                "party-landlord-001",
		PartyTaxNo:             "1234567890",
		TaxBaseAmountKurus:     result.TaxBaseAmountKurus,
		WithholdingAmountKurus: result.WithholdingAmountKurus,
		CurrencyCode:           "TRY",
		EvidenceFilePath:       "docs/faz3/evidence/stopaj-suite.md",
		EvidenceHash:           "sha256:stopaj-suite-evidence",
		RequestHash:            "sha256:stopaj-suite-request",
		ResultHash:             "sha256:stopaj-suite-result",
		BeforeSnapshotHash:     "sha256:stopaj-before",
		AfterSnapshotHash:      "sha256:stopaj-after",
		AuditDecisionReason:    result.AuditDecisionReason,
		ActorID:                "tax-runtime-suite",
		ActorRole:              "SYSTEM",
		CreatedAt:              now,
	}
}

func AuditRecordFromExemption(result exemption.ExemptionResult) audit.TaxAuditRecord {
	now := suiteTime()

	return audit.TaxAuditRecord{
		TenantID:            result.TenantID,
		CorrelationID:       result.CorrelationID,
		RequestID:           result.RequestID,
		IdempotencyKey:      "audit-" + result.IdempotencyKey,
		AuditID:             "audit-exemption-suite-001",
		TaxFamily:           audit.TaxFamilyTaxExemption,
		SourceRuntime:       audit.SourceTaxExemptionRuntime,
		Action:              audit.ActionExemptionApplied,
		DecisionStatus:      audit.DecisionApplied,
		RuleVersion:         result.RuleVersion,
		DocumentType:        string(result.DocumentType),
		DocumentID:          result.DocumentID,
		DocumentNo:          result.DocumentNo,
		PartyID:             "party-001",
		PartyTaxNo:          "1234567890",
		TaxBaseAmountKurus:  result.TaxBaseAmountKurus,
		TaxAmountKurus:      result.EffectiveTaxAmountKurus,
		ExemptedAmountKurus: result.ExemptedTaxAmountKurus,
		CurrencyCode:        "TRY",
		EvidenceFilePath:    "docs/faz3/evidence/exemption-suite.md",
		EvidenceHash:        "sha256:exemption-suite-evidence",
		RequestHash:         "sha256:exemption-suite-request",
		ResultHash:          "sha256:exemption-suite-result",
		BeforeSnapshotHash:  "sha256:exemption-before",
		AfterSnapshotHash:   "sha256:exemption-after",
		AuditDecisionReason: result.AuditDecisionReason,
		ActorID:             "tax-runtime-suite",
		ActorRole:           "SYSTEM",
		CreatedAt:           now,
	}
}

func AuditRecordFromRollout(result rollout.RolloutResult) audit.TaxAuditRecord {
	now := suiteTime()

	return audit.TaxAuditRecord{
		TenantID:            result.TenantID,
		CorrelationID:       result.CorrelationID,
		RequestID:           result.RequestID,
		IdempotencyKey:      "audit-" + result.IdempotencyKey,
		AuditID:             "audit-rollout-suite-001",
		TaxFamily:           audit.TaxFamilyKDV,
		SourceRuntime:       audit.SourceRuleRolloutRuntime,
		Action:              audit.ActionRuleVersionActivated,
		DecisionStatus:      audit.DecisionActivated,
		RuleVersion:         result.TargetVersionCode,
		PreviousRuleVersion: result.PreviousVersionCode,
		TargetRuleVersion:   result.TargetVersionCode,
		CurrencyCode:        "TRY",
		EvidenceFilePath:    "docs/faz3/evidence/rollout-suite.md",
		EvidenceHash:        "sha256:rollout-suite-evidence",
		RequestHash:         "sha256:rollout-suite-request",
		ResultHash:          "sha256:rollout-suite-result",
		BeforeSnapshotHash:  "sha256:rollout-before",
		AfterSnapshotHash:   "sha256:rollout-after",
		AuditDecisionReason: result.AuditDecisionReason,
		ActorID:             "tax-runtime-suite",
		ActorRole:           "SYSTEM",
		CreatedAt:           now,
	}
}
