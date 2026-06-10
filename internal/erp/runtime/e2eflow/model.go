package e2eflow

import (
	"strings"
	"time"
)

type TransactionKind string

const (
	TransactionKindSalesInvoice    TransactionKind = "sales_invoice"
	TransactionKindPurchaseInvoice TransactionKind = "purchase_invoice"
	TransactionKindCashReceipt     TransactionKind = "cash_receipt"
	TransactionKindCashPayment     TransactionKind = "cash_payment"
)

type FlowStatus string

const (
	FlowStatusDraft     FlowStatus = "draft"
	FlowStatusRunning   FlowStatus = "running"
	FlowStatusCompleted FlowStatus = "completed"
	FlowStatusFailed    FlowStatus = "failed"
)

type FlowStepKind string

const (
	FlowStepValidateRequest FlowStepKind = "validate_request"
	FlowStepPersistDocument FlowStepKind = "persist_document"
	FlowStepCalculateTax    FlowStepKind = "calculate_tax"
	FlowStepCashBankPayment FlowStepKind = "cashbank_payment"
	FlowStepPostJournal     FlowStepKind = "post_journal"
	FlowStepPostLedger      FlowStepKind = "post_ledger"
	FlowStepPublishEvent    FlowStepKind = "publish_event"
)

type FlowStepStatus string

const (
	FlowStepStatusPending   FlowStepStatus = "pending"
	FlowStepStatusRunning   FlowStepStatus = "running"
	FlowStepStatusCompleted FlowStepStatus = "completed"
	FlowStepStatusFailed    FlowStepStatus = "failed"
	FlowStepStatusSkipped   FlowStepStatus = "skipped"
)

type TenantContext struct {
	TenantID  string
	RequestID string
	ActorID   string
	ActorType string
}

type SourceDocumentRef struct {
	SourceModule       string
	SourceDocumentType string
	SourceDocumentID   string
	SourceDocumentNo   string
}

type MoneySummary struct {
	TotalAmount  float64
	CurrencyCode string
	ExchangeRate float64
}

type RuntimeFlowRequest struct {
	Tenant TenantContext

	TransactionKind TransactionKind
	Source          SourceDocumentRef
	Money           MoneySummary

	IdempotencyKey string
	CorrelationID  string

	Description string
	Metadata    map[string]string
}

type RuntimeFlowStep struct {
	StepNo int

	Kind   FlowStepKind
	Status FlowStepStatus

	Message string

	StartedAt   time.Time
	CompletedAt time.Time
}

type RuntimeFlowPlan struct {
	TenantID  string
	RequestID string

	TransactionKind TransactionKind
	Source          SourceDocumentRef
	Money           MoneySummary

	IdempotencyKey string
	CorrelationID  string

	Status FlowStatus
	Steps  []RuntimeFlowStep
}

type RuntimeFlowResult struct {
	OK bool

	TenantID  string
	RequestID string

	TransactionKind TransactionKind
	Source          SourceDocumentRef

	Status FlowStatus

	StepCount int

	CompletedAt time.Time
	Message     string
}

func ValidateTenantContext(ctx TenantContext) error {
	if strings.TrimSpace(ctx.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(ctx.RequestID) == "" {
		return ErrRequestIDRequired
	}

	if strings.TrimSpace(ctx.ActorID) == "" {
		return ErrActorRequired
	}

	return nil
}

func ValidateSourceDocumentRef(ref SourceDocumentRef) error {
	if strings.TrimSpace(ref.SourceModule) == "" {
		return ErrSourceModuleRequired
	}

	if strings.TrimSpace(ref.SourceDocumentType) == "" {
		return ErrSourceDocumentRequired
	}

	if strings.TrimSpace(ref.SourceDocumentID) == "" && strings.TrimSpace(ref.SourceDocumentNo) == "" {
		return ErrSourceDocumentRequired
	}

	return nil
}

func ValidateMoneySummary(money MoneySummary) error {
	if money.TotalAmount <= 0 {
		return ErrTotalAmountInvalid
	}

	if strings.TrimSpace(money.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if money.ExchangeRate <= 0 {
		return ErrExchangeRateInvalid
	}

	return nil
}

func ValidateRuntimeFlowRequest(req RuntimeFlowRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if !isValidTransactionKind(req.TransactionKind) {
		return ErrTransactionKindInvalid
	}

	if err := ValidateSourceDocumentRef(req.Source); err != nil {
		return err
	}

	if err := ValidateMoneySummary(req.Money); err != nil {
		return err
	}

	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return ErrIdempotencyKeyRequired
	}

	return nil
}

func ValidateRuntimeFlowStep(step RuntimeFlowStep) error {
	if step.StepNo <= 0 {
		return ErrFlowStepCountInvalid
	}

	if !isValidFlowStepKind(step.Kind) {
		return ErrFlowStepKindInvalid
	}

	if !isValidFlowStepStatus(step.Status) {
		return ErrFlowStepStatusInvalid
	}

	return nil
}

func ValidateRuntimeFlowPlan(plan RuntimeFlowPlan) error {
	if strings.TrimSpace(plan.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(plan.RequestID) == "" {
		return ErrRequestIDRequired
	}

	if !isValidTransactionKind(plan.TransactionKind) {
		return ErrTransactionKindInvalid
	}

	if err := ValidateSourceDocumentRef(plan.Source); err != nil {
		return err
	}

	if err := ValidateMoneySummary(plan.Money); err != nil {
		return err
	}

	if strings.TrimSpace(plan.IdempotencyKey) == "" {
		return ErrIdempotencyKeyRequired
	}

	if !isValidFlowStatus(plan.Status) {
		return ErrFlowStatusInvalid
	}

	if len(plan.Steps) < 1 {
		return ErrFlowStepCountInvalid
	}

	for _, step := range plan.Steps {
		if err := ValidateRuntimeFlowStep(step); err != nil {
			return err
		}
	}

	return nil
}

func BuildRuntimeFlowPlan(req RuntimeFlowRequest) (RuntimeFlowPlan, error) {
	if err := ValidateRuntimeFlowRequest(req); err != nil {
		return RuntimeFlowPlan{}, err
	}

	steps := BuildDefaultFlowSteps(req.TransactionKind)

	return RuntimeFlowPlan{
		TenantID:        req.Tenant.TenantID,
		RequestID:       req.Tenant.RequestID,
		TransactionKind: req.TransactionKind,
		Source:          req.Source,
		Money:           normalizeMoney(req.Money),
		IdempotencyKey:  strings.TrimSpace(req.IdempotencyKey),
		CorrelationID:   strings.TrimSpace(req.CorrelationID),
		Status:          FlowStatusDraft,
		Steps:           steps,
	}, nil
}

func BuildDefaultFlowSteps(kind TransactionKind) []RuntimeFlowStep {
	stepKinds := []FlowStepKind{
		FlowStepValidateRequest,
	}

	switch kind {
	case TransactionKindSalesInvoice, TransactionKindPurchaseInvoice:
		stepKinds = append(stepKinds,
			FlowStepPersistDocument,
			FlowStepCalculateTax,
			FlowStepPostJournal,
			FlowStepPostLedger,
			FlowStepPublishEvent,
		)
	case TransactionKindCashReceipt, TransactionKindCashPayment:
		stepKinds = append(stepKinds,
			FlowStepCashBankPayment,
			FlowStepPostJournal,
			FlowStepPostLedger,
			FlowStepPublishEvent,
		)
	default:
		stepKinds = append(stepKinds, FlowStepPublishEvent)
	}

	steps := make([]RuntimeFlowStep, 0, len(stepKinds))

	for index, kind := range stepKinds {
		steps = append(steps, RuntimeFlowStep{
			StepNo: index + 1,
			Kind:   kind,
			Status: FlowStepStatusPending,
		})
	}

	return steps
}

func CompleteRuntimeFlowPlan(plan RuntimeFlowPlan, completedAt time.Time) (RuntimeFlowPlan, error) {
	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowPlan{}, err
	}

	if completedAt.IsZero() {
		completedAt = time.Now().UTC()
	}

	plan.Status = FlowStatusCompleted

	for index := range plan.Steps {
		if plan.Steps[index].StartedAt.IsZero() {
			plan.Steps[index].StartedAt = completedAt
		}

		plan.Steps[index].CompletedAt = completedAt
		plan.Steps[index].Status = FlowStepStatusCompleted

		if strings.TrimSpace(plan.Steps[index].Message) == "" {
			plan.Steps[index].Message = "completed"
		}
	}

	return plan, nil
}

func BuildRuntimeFlowResult(req RuntimeFlowRequest, plan RuntimeFlowPlan, message string) (RuntimeFlowResult, error) {
	if err := ValidateRuntimeFlowRequest(req); err != nil {
		return RuntimeFlowResult{}, err
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowResult{}, err
	}

	if plan.Status != FlowStatusCompleted {
		return RuntimeFlowResult{}, ErrFlowStatusInvalid
	}

	return RuntimeFlowResult{
		OK:              true,
		TenantID:        plan.TenantID,
		RequestID:       plan.RequestID,
		TransactionKind: plan.TransactionKind,
		Source:          plan.Source,
		Status:          FlowStatusCompleted,
		StepCount:       len(plan.Steps),
		CompletedAt:     latestStepCompletedAt(plan.Steps),
		Message:         message,
	}, nil
}

func latestStepCompletedAt(steps []RuntimeFlowStep) time.Time {
	var latest time.Time

	for _, step := range steps {
		if step.CompletedAt.After(latest) {
			latest = step.CompletedAt
		}
	}

	if latest.IsZero() {
		return time.Now().UTC()
	}

	return latest
}

func normalizeMoney(money MoneySummary) MoneySummary {
	return MoneySummary{
		TotalAmount:  money.TotalAmount,
		CurrencyCode: strings.ToUpper(strings.TrimSpace(money.CurrencyCode)),
		ExchangeRate: money.ExchangeRate,
	}
}

func isValidTransactionKind(kind TransactionKind) bool {
	switch kind {
	case TransactionKindSalesInvoice, TransactionKindPurchaseInvoice, TransactionKindCashReceipt, TransactionKindCashPayment:
		return true
	default:
		return false
	}
}

func isValidFlowStatus(status FlowStatus) bool {
	switch status {
	case FlowStatusDraft, FlowStatusRunning, FlowStatusCompleted, FlowStatusFailed:
		return true
	default:
		return false
	}
}

func isValidFlowStepKind(kind FlowStepKind) bool {
	switch kind {
	case FlowStepValidateRequest,
		FlowStepPersistDocument,
		FlowStepCalculateTax,
		FlowStepCashBankPayment,
		FlowStepPostJournal,
		FlowStepPostLedger,
		FlowStepPublishEvent:
		return true
	default:
		return false
	}
}

func isValidFlowStepStatus(status FlowStepStatus) bool {
	switch status {
	case FlowStepStatusPending, FlowStepStatusRunning, FlowStepStatusCompleted, FlowStepStatusFailed, FlowStepStatusSkipped:
		return true
	default:
		return false
	}
}
