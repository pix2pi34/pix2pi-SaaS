package compliancecontrol

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ApprovalStatus string

const (
	ApprovalApproved ApprovalStatus = "APPROVED"
	ApprovalPending  ApprovalStatus = "PENDING"
	ApprovalRejected ApprovalStatus = "REJECTED"
)

type DocumentStatus string

const (
	DocumentDraft           DocumentStatus = "DRAFT"
	DocumentReadyForReview  DocumentStatus = "READY_FOR_REVIEW"
	DocumentApprovedPrivate DocumentStatus = "APPROVED_PRIVATE"
	DocumentPublicApproved  DocumentStatus = "PUBLIC_APPROVED"
	DocumentMissing         DocumentStatus = "MISSING"
)

type ComplianceDocument struct {
	Key                    string
	Title                  string
	Owner                  string
	Version                string
	Status                 DocumentStatus
	Required               bool
	PublicPublishAllowed   bool
	RequiresLegalApproval  bool
	RequiresKVKKApproval   bool
	RequiresFounderGoNoGo  bool
	ContainsConsentScope   bool
	ContainsRetentionScope bool
	ContainsDataUseScope   bool
}

type ApprovalGate struct {
	Key    string
	Owner  string
	Status ApprovalStatus
}

type ControlInput struct {
	LaunchMode               string
	Target                   string
	PublicLaunchAllowed      bool
	RequiredDocumentKeys     []string
	Documents                []ComplianceDocument
	ApprovalGates            []ApprovalGate
	RequireVersionedDocs     bool
	RequireKVKKGate          bool
	RequireLegalGate         bool
	RequireFounderGate       bool
	RequireNoPublicDraftDocs bool
}

type ControlFinding struct {
	Severity string
	Code     string
	Message  string
}

type ControlReport struct {
	Status              string
	PublicLaunchAllowed bool
	RequiredFailCount   int
	OptionalWarnCount   int
	PassCount           int
	Findings            []ControlFinding
}

func Evaluate(input ControlInput) (ControlReport, error) {
	report := ControlReport{
		Status:              "PASS",
		PublicLaunchAllowed: false,
		Findings:            []ControlFinding{},
	}

	if strings.TrimSpace(input.LaunchMode) == "" {
		addFail(&report, "LAUNCH_MODE_MISSING", "launch mode boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&report, "TARGET_MISSING", "target boş olamaz")
	}

	docByKey := map[string]ComplianceDocument{}
	for _, doc := range input.Documents {
		key := strings.TrimSpace(doc.Key)
		if key == "" {
			addFail(&report, "DOCUMENT_KEY_MISSING", "doküman key boş olamaz")
			continue
		}
		if _, exists := docByKey[key]; exists {
			addFail(&report, "DOCUMENT_DUPLICATE", fmt.Sprintf("doküman duplicate: %s", key))
			continue
		}
		docByKey[key] = doc

		if doc.Required && doc.Status == DocumentMissing {
			addFail(&report, "REQUIRED_DOCUMENT_MISSING", fmt.Sprintf("zorunlu doküman missing: %s", key))
		} else {
			report.PassCount++
		}

		if input.RequireVersionedDocs && doc.Required && strings.TrimSpace(doc.Version) == "" {
			addFail(&report, "DOCUMENT_VERSION_MISSING", fmt.Sprintf("zorunlu doküman versiyonsuz: %s", key))
		} else if doc.Required {
			report.PassCount++
		}

		if input.RequireNoPublicDraftDocs && doc.PublicPublishAllowed && doc.Status != DocumentPublicApproved {
			addFail(&report, "PUBLIC_DRAFT_BLOCKED", fmt.Sprintf("public publish allowed ama PUBLIC_APPROVED değil: %s", key))
		} else {
			report.PassCount++
		}

		if doc.RequiresKVKKApproval && !doc.ContainsConsentScope && key == "consent_registry_policy" {
			addFail(&report, "CONSENT_SCOPE_MISSING", "consent registry policy consent scope içermeli")
		}

		if doc.RequiresKVKKApproval && key == "kvkk_privacy_notice" && !doc.ContainsDataUseScope {
			addFail(&report, "DATA_USE_SCOPE_MISSING", "KVKK/gizlilik metni veri kullanım kapsamını içermeli")
		}

		if key == "log_retention_destruction_policy" && !doc.ContainsRetentionScope {
			addFail(&report, "RETENTION_SCOPE_MISSING", "log retention / imha politikası retention scope içermeli")
		}
	}

	for _, requiredKey := range input.RequiredDocumentKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		doc, exists := docByKey[requiredKey]
		if !exists {
			addFail(&report, "REQUIRED_DOCUMENT_NOT_REGISTERED", fmt.Sprintf("required listesinde olup inventory'de yok: %s", requiredKey))
			continue
		}
		if !doc.Required {
			addFail(&report, "REQUIRED_DOCUMENT_FLAG_FALSE", fmt.Sprintf("required listesinde ama dokümanda required=false: %s", requiredKey))
			continue
		}
		report.PassCount++
	}

	gates := map[string]ApprovalGate{}
	for _, gate := range input.ApprovalGates {
		key := strings.TrimSpace(gate.Key)
		if key == "" {
			addFail(&report, "APPROVAL_GATE_KEY_MISSING", "approval gate key boş olamaz")
			continue
		}
		gates[key] = gate
	}

	if input.RequireLegalGate {
		assertGateApprovedOrPending(&report, gates, "legal_counsel_approval")
	}

	if input.RequireKVKKGate {
		assertGateApprovedOrPending(&report, gates, "kvkk_consultant_approval")
	}

	if input.RequireFounderGate {
		assertGateApprovedOrPending(&report, gates, "founder_go_no_go")
	}

	for _, doc := range input.Documents {
		if doc.PublicPublishAllowed {
			if doc.RequiresLegalApproval && !isGateApproved(gates, "legal_counsel_approval") {
				addFail(&report, "LEGAL_GATE_REQUIRED_FOR_PUBLIC", fmt.Sprintf("public doküman için hukukçu onayı APPROVED olmalı: %s", doc.Key))
			}
			if doc.RequiresKVKKApproval && !isGateApproved(gates, "kvkk_consultant_approval") {
				addFail(&report, "KVKK_GATE_REQUIRED_FOR_PUBLIC", fmt.Sprintf("public doküman için KVKK onayı APPROVED olmalı: %s", doc.Key))
			}
			if doc.RequiresFounderGoNoGo && !isGateApproved(gates, "founder_go_no_go") {
				addFail(&report, "FOUNDER_GATE_REQUIRED_FOR_PUBLIC", fmt.Sprintf("public doküman için founder go/no-go APPROVED olmalı: %s", doc.Key))
			}
		}
	}

	if input.PublicLaunchAllowed {
		if !allRequiredDocsPublicApproved(input) {
			addFail(&report, "PUBLIC_LAUNCH_BLOCKED_BY_DOCUMENT_STATUS", "public launch için tüm zorunlu dokümanlar PUBLIC_APPROVED olmalı")
		}
		if input.RequireLegalGate && !isGateApproved(gates, "legal_counsel_approval") {
			addFail(&report, "PUBLIC_LAUNCH_BLOCKED_BY_LEGAL_GATE", "public launch için legal_counsel_approval APPROVED olmalı")
		}
		if input.RequireKVKKGate && !isGateApproved(gates, "kvkk_consultant_approval") {
			addFail(&report, "PUBLIC_LAUNCH_BLOCKED_BY_KVKK_GATE", "public launch için kvkk_consultant_approval APPROVED olmalı")
		}
		if input.RequireFounderGate && !isGateApproved(gates, "founder_go_no_go") {
			addFail(&report, "PUBLIC_LAUNCH_BLOCKED_BY_FOUNDER_GATE", "public launch için founder_go_no_go APPROVED olmalı")
		}
	}

	if report.RequiredFailCount > 0 {
		report.Status = "FAIL"
		report.PublicLaunchAllowed = false
		return report, nil
	}

	report.Status = "PASS"
	report.PublicLaunchAllowed = input.PublicLaunchAllowed && allRequiredDocsPublicApproved(input)
	return report, nil
}

func RequiredDocumentKeys(input ControlInput) []string {
	keys := make([]string, 0, len(input.RequiredDocumentKeys))
	keys = append(keys, input.RequiredDocumentKeys...)
	sort.Strings(keys)
	return keys
}

func addFail(report *ControlReport, code, message string) {
	report.RequiredFailCount++
	report.Findings = append(report.Findings, ControlFinding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}

func assertGateApprovedOrPending(report *ControlReport, gates map[string]ApprovalGate, key string) {
	gate, exists := gates[key]
	if !exists {
		addFail(report, "APPROVAL_GATE_MISSING", fmt.Sprintf("approval gate missing: %s", key))
		return
	}
	if gate.Status != ApprovalApproved && gate.Status != ApprovalPending {
		addFail(report, "APPROVAL_GATE_INVALID", fmt.Sprintf("approval gate geçersiz: %s", key))
		return
	}
	report.PassCount++
}

func isGateApproved(gates map[string]ApprovalGate, key string) bool {
	gate, exists := gates[key]
	return exists && gate.Status == ApprovalApproved
}

func allRequiredDocsPublicApproved(input ControlInput) bool {
	required := map[string]bool{}
	for _, key := range input.RequiredDocumentKeys {
		required[key] = true
	}
	for _, doc := range input.Documents {
		if required[doc.Key] && doc.Status != DocumentPublicApproved {
			return false
		}
	}
	return true
}

func MustPass(report ControlReport) error {
	if report.RequiredFailCount > 0 || report.Status != "PASS" {
		return errors.New("compliance document control failed")
	}
	return nil
}
