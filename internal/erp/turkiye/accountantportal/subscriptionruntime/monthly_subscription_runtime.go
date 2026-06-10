package subscriptionruntime

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type SubscriptionStatus string

const (
	SubscriptionStatusDraft     SubscriptionStatus = "DRAFT"
	SubscriptionStatusTrialing  SubscriptionStatus = "TRIALING"
	SubscriptionStatusActive    SubscriptionStatus = "ACTIVE"
	SubscriptionStatusSuspended SubscriptionStatus = "SUSPENDED"
	SubscriptionStatusCanceled  SubscriptionStatus = "CANCELED"
	SubscriptionStatusExpired   SubscriptionStatus = "EXPIRED"
)

type BillingCycle string

const (
	BillingCycleMonthly BillingCycle = "MONTHLY"
)

type SubscriptionDecisionStatus string

const (
	DecisionAllowed SubscriptionDecisionStatus = "ALLOWED"
	DecisionDenied  SubscriptionDecisionStatus = "DENIED"
)

type SubscriptionAction string

const (
	ActionStartTrial      SubscriptionAction = "START_TRIAL"
	ActionActivateMonthly SubscriptionAction = "ACTIVATE_MONTHLY"
	ActionRenewMonthly    SubscriptionAction = "RENEW_MONTHLY"
	ActionChangePlan      SubscriptionAction = "CHANGE_PLAN"
	ActionSuspend         SubscriptionAction = "SUSPEND"
	ActionResume          SubscriptionAction = "RESUME"
	ActionCancel          SubscriptionAction = "CANCEL"
	ActionCheckAccess     SubscriptionAction = "CHECK_ACCESS"
)

type RuntimeConfig struct {
	RuntimeEnabled        bool                 `json:"runtime_enabled"`
	DefaultCurrencyCode   string               `json:"default_currency_code"`
	RequireTenantScope    bool                 `json:"require_tenant_scope"`
	RequireBillingProfile bool                 `json:"require_billing_profile"`
	RequireMonthlyCycle   bool                 `json:"require_monthly_cycle"`
	RequireFirmLimit      bool                 `json:"require_firm_limit"`
	RequireAuditActor     bool                 `json:"require_audit_actor"`
	AllowTrial            bool                 `json:"allow_trial"`
	AllowPlanChange       bool                 `json:"allow_plan_change"`
	AllowResumeSuspended  bool                 `json:"allow_resume_suspended"`
	DefaultTrialDays      int                  `json:"default_trial_days"`
	MaxAssignedFirmLimit  int                  `json:"max_assigned_firm_limit"`
	AllowedPlanCodes      []string             `json:"allowed_plan_codes"`
	AllowedStatuses       []SubscriptionStatus `json:"allowed_statuses"`
}

type SubscriptionPlan struct {
	PlanCode           string       `json:"plan_code"`
	PlanName           string       `json:"plan_name"`
	BillingCycle       BillingCycle `json:"billing_cycle"`
	CurrencyCode       string       `json:"currency_code"`
	MonthlyPriceKurus  int64        `json:"monthly_price_kurus"`
	IncludedFirmLimit  int          `json:"included_firm_limit"`
	IncludedUserLimit  int          `json:"included_user_limit"`
	ExportQuotaMonthly int          `json:"export_quota_monthly"`
	TrialDays          int          `json:"trial_days"`
}

type SubscriptionAccount struct {
	TenantID         string `json:"tenant_id"`
	SubscriptionID   string `json:"subscription_id"`
	AccountantFirmID string `json:"accountant_firm_id"`
	BillingProfileID string `json:"billing_profile_id"`

	PlanCode          string             `json:"plan_code"`
	PlanName          string             `json:"plan_name"`
	Status            SubscriptionStatus `json:"status"`
	BillingCycle      BillingCycle       `json:"billing_cycle"`
	CurrencyCode      string             `json:"currency_code"`
	MonthlyPriceKurus int64              `json:"monthly_price_kurus"`

	AssignedFirmLimit  int `json:"assigned_firm_limit"`
	AssignedFirmCount  int `json:"assigned_firm_count"`
	IncludedUserLimit  int `json:"included_user_limit"`
	ExportQuotaMonthly int `json:"export_quota_monthly"`

	PeriodStart time.Time `json:"period_start"`
	PeriodEnd   time.Time `json:"period_end"`

	TrialStart time.Time `json:"trial_start"`
	TrialEnd   time.Time `json:"trial_end"`

	LastRenewedAt time.Time `json:"last_renewed_at"`
	SuspendedAt   time.Time `json:"suspended_at"`
	CanceledAt    time.Time `json:"canceled_at"`

	AuditActorID string    `json:"audit_actor_id"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type SubscriptionCommandRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	CommandID        string             `json:"command_id"`
	Action           SubscriptionAction `json:"action"`
	SubscriptionID   string             `json:"subscription_id"`
	AccountantFirmID string             `json:"accountant_firm_id"`
	BillingProfileID string             `json:"billing_profile_id"`

	Plan    SubscriptionPlan    `json:"plan"`
	Current SubscriptionAccount `json:"current"`

	ActorID string `json:"actor_id"`
	Reason  string `json:"reason"`

	EffectiveAt time.Time `json:"effective_at"`
}

type SubscriptionDecision struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	CommandID        string             `json:"command_id"`
	Action           SubscriptionAction `json:"action"`
	SubscriptionID   string             `json:"subscription_id"`
	AccountantFirmID string             `json:"accountant_firm_id"`

	Status  SubscriptionDecisionStatus `json:"status"`
	Allowed bool                       `json:"allowed"`

	Account SubscriptionAccount `json:"account"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	DecisionHash string `json:"decision_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	CreatedAt           time.Time `json:"created_at"`
}

type AccessCheckRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	Subscription SubscriptionAccount `json:"subscription"`

	RequiredFirmCount int       `json:"required_firm_count"`
	RequestedAt       time.Time `json:"requested_at"`
}

type MonthlySubscriptionRuntime struct {
	config RuntimeConfig
}

func NewMonthlySubscriptionRuntime(config RuntimeConfig) (*MonthlySubscriptionRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("monthly subscription runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.DefaultTrialDays <= 0 {
		return nil, errors.New("default_trial_days must be positive")
	}
	if config.MaxAssignedFirmLimit <= 0 {
		return nil, errors.New("max_assigned_firm_limit must be positive")
	}
	if len(config.AllowedPlanCodes) == 0 {
		return nil, errors.New("allowed_plan_codes are required")
	}
	if len(config.AllowedStatuses) == 0 {
		return nil, errors.New("allowed_statuses are required")
	}

	return &MonthlySubscriptionRuntime{config: config}, nil
}

func (r *MonthlySubscriptionRuntime) StartTrial(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionStartTrial
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if !r.config.AllowTrial {
		err := errors.New("trial is not allowed by runtime config")
		return r.deny(req, SubscriptionAccount{}, "TRIAL_NOT_ALLOWED", err.Error()), err
	}
	if err := r.validatePlan(req.Plan); err != nil {
		return r.deny(req, SubscriptionAccount{}, "PLAN_INVALID", err.Error()), err
	}

	trialDays := req.Plan.TrialDays
	if trialDays <= 0 {
		trialDays = r.config.DefaultTrialDays
	}

	account := r.accountFromPlan(req, SubscriptionStatusTrialing)
	account.TrialStart = req.EffectiveAt
	account.TrialEnd = req.EffectiveAt.AddDate(0, 0, trialDays)
	account.PeriodStart = req.EffectiveAt
	account.PeriodEnd = monthEnd(req.EffectiveAt)

	return r.allow(req, account, "TRIAL_STARTED", "monthly trial subscription started"), nil
}

func (r *MonthlySubscriptionRuntime) ActivateMonthly(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionActivateMonthly
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validatePlan(req.Plan); err != nil {
		return r.deny(req, SubscriptionAccount{}, "PLAN_INVALID", err.Error()), err
	}

	account := r.accountFromPlan(req, SubscriptionStatusActive)
	account.PeriodStart = req.EffectiveAt
	account.PeriodEnd = monthEnd(req.EffectiveAt)
	account.LastRenewedAt = req.EffectiveAt

	return r.allow(req, account, "MONTHLY_SUBSCRIPTION_ACTIVATED", "monthly subscription activated"), nil
}

func (r *MonthlySubscriptionRuntime) RenewMonthly(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionRenewMonthly
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCurrent(req); err != nil {
		return r.deny(req, req.Current, "CURRENT_SUBSCRIPTION_INVALID", err.Error()), err
	}
	if req.Current.Status != SubscriptionStatusActive && req.Current.Status != SubscriptionStatusTrialing {
		err := errors.New("only ACTIVE or TRIALING subscriptions can be renewed")
		return r.deny(req, req.Current, "RENEW_STATUS_DENIED", err.Error()), err
	}

	account := req.Current
	account.Status = SubscriptionStatusActive
	account.PeriodStart = nextDay(req.Current.PeriodEnd)
	account.PeriodEnd = monthEnd(account.PeriodStart)
	account.LastRenewedAt = req.EffectiveAt
	account.AuditActorID = req.ActorID
	account.UpdatedAt = req.EffectiveAt

	return r.allow(req, account, "MONTHLY_SUBSCRIPTION_RENEWED", "monthly subscription renewed"), nil
}

func (r *MonthlySubscriptionRuntime) ChangePlan(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionChangePlan
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if !r.config.AllowPlanChange {
		err := errors.New("plan change is not allowed by runtime config")
		return r.deny(req, req.Current, "PLAN_CHANGE_NOT_ALLOWED", err.Error()), err
	}
	if err := r.validateCurrent(req); err != nil {
		return r.deny(req, req.Current, "CURRENT_SUBSCRIPTION_INVALID", err.Error()), err
	}
	if err := r.validatePlan(req.Plan); err != nil {
		return r.deny(req, req.Current, "PLAN_INVALID", err.Error()), err
	}
	if req.Current.Status != SubscriptionStatusActive && req.Current.Status != SubscriptionStatusTrialing {
		err := errors.New("only ACTIVE or TRIALING subscriptions can change plan")
		return r.deny(req, req.Current, "PLAN_CHANGE_STATUS_DENIED", err.Error()), err
	}
	if req.Current.AssignedFirmCount > req.Plan.IncludedFirmLimit {
		err := errors.New("assigned firm count exceeds new plan firm limit")
		return r.deny(req, req.Current, "PLAN_LIMIT_DENIED", err.Error()), err
	}

	account := req.Current
	account.PlanCode = req.Plan.PlanCode
	account.PlanName = req.Plan.PlanName
	account.BillingCycle = req.Plan.BillingCycle
	account.CurrencyCode = req.Plan.CurrencyCode
	account.MonthlyPriceKurus = req.Plan.MonthlyPriceKurus
	account.AssignedFirmLimit = req.Plan.IncludedFirmLimit
	account.IncludedUserLimit = req.Plan.IncludedUserLimit
	account.ExportQuotaMonthly = req.Plan.ExportQuotaMonthly
	account.AuditActorID = req.ActorID
	account.UpdatedAt = req.EffectiveAt

	return r.allow(req, account, "PLAN_CHANGED", "monthly subscription plan changed"), nil
}

func (r *MonthlySubscriptionRuntime) Suspend(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionSuspend
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCurrent(req); err != nil {
		return r.deny(req, req.Current, "CURRENT_SUBSCRIPTION_INVALID", err.Error()), err
	}
	if req.Current.Status != SubscriptionStatusActive && req.Current.Status != SubscriptionStatusTrialing {
		err := errors.New("only ACTIVE or TRIALING subscriptions can be suspended")
		return r.deny(req, req.Current, "SUSPEND_STATUS_DENIED", err.Error()), err
	}
	if strings.TrimSpace(req.Reason) == "" {
		err := errors.New("suspend reason is required")
		return r.deny(req, req.Current, "SUSPEND_REASON_REQUIRED", err.Error()), err
	}

	account := req.Current
	account.Status = SubscriptionStatusSuspended
	account.SuspendedAt = req.EffectiveAt
	account.AuditActorID = req.ActorID
	account.UpdatedAt = req.EffectiveAt

	return r.allow(req, account, "SUBSCRIPTION_SUSPENDED", "monthly subscription suspended"), nil
}

func (r *MonthlySubscriptionRuntime) Resume(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionResume
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if !r.config.AllowResumeSuspended {
		err := errors.New("resume is not allowed by runtime config")
		return r.deny(req, req.Current, "RESUME_NOT_ALLOWED", err.Error()), err
	}
	if err := r.validateCurrent(req); err != nil {
		return r.deny(req, req.Current, "CURRENT_SUBSCRIPTION_INVALID", err.Error()), err
	}
	if req.Current.Status != SubscriptionStatusSuspended {
		err := errors.New("only SUSPENDED subscriptions can be resumed")
		return r.deny(req, req.Current, "RESUME_STATUS_DENIED", err.Error()), err
	}
	if req.EffectiveAt.After(req.Current.PeriodEnd) {
		err := errors.New("cannot resume expired billing period")
		return r.deny(req, req.Current, "RESUME_PERIOD_EXPIRED", err.Error()), err
	}

	account := req.Current
	account.Status = SubscriptionStatusActive
	account.SuspendedAt = time.Time{}
	account.AuditActorID = req.ActorID
	account.UpdatedAt = req.EffectiveAt

	return r.allow(req, account, "SUBSCRIPTION_RESUMED", "monthly subscription resumed"), nil
}

func (r *MonthlySubscriptionRuntime) Cancel(req SubscriptionCommandRequest) (SubscriptionDecision, error) {
	req.Action = ActionCancel
	if err := r.validateCommandBase(req); err != nil {
		return r.deny(req, SubscriptionAccount{}, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCurrent(req); err != nil {
		return r.deny(req, req.Current, "CURRENT_SUBSCRIPTION_INVALID", err.Error()), err
	}
	if req.Current.Status == SubscriptionStatusCanceled {
		err := errors.New("subscription is already canceled")
		return r.deny(req, req.Current, "ALREADY_CANCELED", err.Error()), err
	}
	if strings.TrimSpace(req.Reason) == "" {
		err := errors.New("cancel reason is required")
		return r.deny(req, req.Current, "CANCEL_REASON_REQUIRED", err.Error()), err
	}

	account := req.Current
	account.Status = SubscriptionStatusCanceled
	account.CanceledAt = req.EffectiveAt
	account.AuditActorID = req.ActorID
	account.UpdatedAt = req.EffectiveAt

	return r.allow(req, account, "SUBSCRIPTION_CANCELED", "monthly subscription canceled"), nil
}

func (r *MonthlySubscriptionRuntime) CheckAccess(req AccessCheckRequest) (SubscriptionDecision, error) {
	commandReq := SubscriptionCommandRequest{
		TenantID:         req.TenantID,
		CorrelationID:    req.CorrelationID,
		RequestID:        req.RequestID,
		IdempotencyKey:   req.IdempotencyKey,
		CommandID:        "check-access:" + req.Subscription.SubscriptionID,
		Action:           ActionCheckAccess,
		SubscriptionID:   req.Subscription.SubscriptionID,
		AccountantFirmID: req.Subscription.AccountantFirmID,
		BillingProfileID: req.Subscription.BillingProfileID,
		Current:          req.Subscription,
		ActorID:          req.Subscription.AuditActorID,
		EffectiveAt:      req.RequestedAt,
	}

	if strings.TrimSpace(req.TenantID) == "" {
		err := errors.New("tenant_id is required")
		return r.deny(commandReq, req.Subscription, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		err := errors.New("correlation_id is required")
		return r.deny(commandReq, req.Subscription, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.RequestID) == "" {
		err := errors.New("request_id is required")
		return r.deny(commandReq, req.Subscription, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		err := errors.New("idempotency_key is required")
		return r.deny(commandReq, req.Subscription, "VALIDATION_FAILED", err.Error()), err
	}
	if req.RequestedAt.IsZero() {
		err := errors.New("requested_at is required")
		return r.deny(commandReq, req.Subscription, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCurrent(commandReq); err != nil {
		return r.deny(commandReq, req.Subscription, "CURRENT_SUBSCRIPTION_INVALID", err.Error()), err
	}
	if req.Subscription.Status != SubscriptionStatusActive && req.Subscription.Status != SubscriptionStatusTrialing {
		err := errors.New("subscription access requires ACTIVE or TRIALING status")
		return r.deny(commandReq, req.Subscription, "ACCESS_STATUS_DENIED", err.Error()), err
	}
	if req.RequestedAt.After(req.Subscription.PeriodEnd) {
		err := errors.New("subscription billing period is expired")
		return r.deny(commandReq, req.Subscription, "ACCESS_PERIOD_EXPIRED", err.Error()), err
	}
	if req.RequiredFirmCount > req.Subscription.AssignedFirmLimit {
		err := errors.New("required firm count exceeds assigned firm limit")
		return r.deny(commandReq, req.Subscription, "ACCESS_FIRM_LIMIT_DENIED", err.Error()), err
	}

	return r.allow(commandReq, req.Subscription, "SUBSCRIPTION_ACCESS_ALLOWED", "subscription access allowed"), nil
}

func (r *MonthlySubscriptionRuntime) validateCommandBase(req SubscriptionCommandRequest) error {
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
	if strings.TrimSpace(req.CommandID) == "" {
		return errors.New("command_id is required")
	}
	if strings.TrimSpace(req.SubscriptionID) == "" {
		return errors.New("subscription_id is required")
	}
	if strings.TrimSpace(req.AccountantFirmID) == "" {
		return errors.New("accountant_firm_id is required")
	}
	if r.config.RequireBillingProfile && strings.TrimSpace(req.BillingProfileID) == "" {
		return errors.New("billing_profile_id is required")
	}
	if r.config.RequireAuditActor && strings.TrimSpace(req.ActorID) == "" {
		return errors.New("actor_id is required")
	}
	if req.EffectiveAt.IsZero() {
		return errors.New("effective_at is required")
	}
	return nil
}

func (r *MonthlySubscriptionRuntime) validatePlan(plan SubscriptionPlan) error {
	if strings.TrimSpace(plan.PlanCode) == "" {
		return errors.New("plan_code is required")
	}
	if !hasPlanCode(r.config.AllowedPlanCodes, plan.PlanCode) {
		return errors.New("plan_code is not allowed")
	}
	if strings.TrimSpace(plan.PlanName) == "" {
		return errors.New("plan_name is required")
	}
	if r.config.RequireMonthlyCycle && plan.BillingCycle != BillingCycleMonthly {
		return errors.New("billing_cycle must be MONTHLY")
	}
	if plan.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("plan currency_code mismatch")
	}
	if plan.MonthlyPriceKurus < 0 {
		return errors.New("monthly_price_kurus cannot be negative")
	}
	if r.config.RequireFirmLimit && plan.IncludedFirmLimit <= 0 {
		return errors.New("included_firm_limit must be positive")
	}
	if plan.IncludedFirmLimit > r.config.MaxAssignedFirmLimit {
		return errors.New("included_firm_limit exceeds max_assigned_firm_limit")
	}
	if plan.IncludedUserLimit <= 0 {
		return errors.New("included_user_limit must be positive")
	}
	if plan.ExportQuotaMonthly <= 0 {
		return errors.New("export_quota_monthly must be positive")
	}
	return nil
}

func (r *MonthlySubscriptionRuntime) validateCurrent(req SubscriptionCommandRequest) error {
	current := req.Current

	if strings.TrimSpace(current.SubscriptionID) == "" {
		return errors.New("current subscription_id is required")
	}
	if current.SubscriptionID != req.SubscriptionID {
		return errors.New("current subscription_id mismatch")
	}
	if r.config.RequireTenantScope && current.TenantID != req.TenantID {
		return errors.New("current tenant_id mismatch")
	}
	if current.AccountantFirmID != req.AccountantFirmID {
		return errors.New("current accountant_firm_id mismatch")
	}
	if r.config.RequireBillingProfile && current.BillingProfileID != req.BillingProfileID {
		return errors.New("current billing_profile_id mismatch")
	}
	if !hasStatus(r.config.AllowedStatuses, current.Status) {
		return errors.New("current status is not allowed by runtime config")
	}
	if r.config.RequireMonthlyCycle && current.BillingCycle != BillingCycleMonthly {
		return errors.New("current billing_cycle must be MONTHLY")
	}
	if current.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("current currency_code mismatch")
	}
	if current.AssignedFirmLimit <= 0 {
		return errors.New("current assigned_firm_limit must be positive")
	}
	if current.AssignedFirmCount > current.AssignedFirmLimit {
		return errors.New("current assigned firm count exceeds limit")
	}
	if current.PeriodStart.IsZero() {
		return errors.New("current period_start is required")
	}
	if current.PeriodEnd.IsZero() {
		return errors.New("current period_end is required")
	}
	if current.PeriodEnd.Before(current.PeriodStart) {
		return errors.New("current period_end cannot be before period_start")
	}
	return nil
}

func (r *MonthlySubscriptionRuntime) accountFromPlan(req SubscriptionCommandRequest, status SubscriptionStatus) SubscriptionAccount {
	return SubscriptionAccount{
		TenantID:           req.TenantID,
		SubscriptionID:     req.SubscriptionID,
		AccountantFirmID:   req.AccountantFirmID,
		BillingProfileID:   req.BillingProfileID,
		PlanCode:           req.Plan.PlanCode,
		PlanName:           req.Plan.PlanName,
		Status:             status,
		BillingCycle:       req.Plan.BillingCycle,
		CurrencyCode:       req.Plan.CurrencyCode,
		MonthlyPriceKurus:  req.Plan.MonthlyPriceKurus,
		AssignedFirmLimit:  req.Plan.IncludedFirmLimit,
		AssignedFirmCount:  0,
		IncludedUserLimit:  req.Plan.IncludedUserLimit,
		ExportQuotaMonthly: req.Plan.ExportQuotaMonthly,
		AuditActorID:       req.ActorID,
		UpdatedAt:          req.EffectiveAt,
	}
}

func (r *MonthlySubscriptionRuntime) allow(req SubscriptionCommandRequest, account SubscriptionAccount, reasonCode string, reason string) SubscriptionDecision {
	return SubscriptionDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		CommandID:           req.CommandID,
		Action:              req.Action,
		SubscriptionID:      req.SubscriptionID,
		AccountantFirmID:    req.AccountantFirmID,
		Status:              DecisionAllowed,
		Allowed:             true,
		Account:             account,
		ReasonCode:          reasonCode,
		Reason:              reason,
		DecisionHash:        buildDecisionHash(req, account, DecisionAllowed, reasonCode),
		AuditAction:         "MONTHLY_SUBSCRIPTION_DECISION_ALLOWED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func (r *MonthlySubscriptionRuntime) deny(req SubscriptionCommandRequest, account SubscriptionAccount, reasonCode string, reason string) SubscriptionDecision {
	return SubscriptionDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		CommandID:           req.CommandID,
		Action:              req.Action,
		SubscriptionID:      req.SubscriptionID,
		AccountantFirmID:    req.AccountantFirmID,
		Status:              DecisionDenied,
		Allowed:             false,
		Account:             account,
		ReasonCode:          reasonCode,
		Reason:              reason,
		DecisionHash:        buildDecisionHash(req, account, DecisionDenied, reasonCode),
		AuditAction:         "MONTHLY_SUBSCRIPTION_DECISION_DENIED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func monthEnd(t time.Time) time.Time {
	year, month, _ := t.Date()
	location := t.Location()
	firstNextMonth := time.Date(year, month+1, 1, 23, 59, 59, 0, location)
	return firstNextMonth.AddDate(0, 0, -1)
}

func nextDay(t time.Time) time.Time {
	year, month, day := t.AddDate(0, 0, 1).Date()
	location := t.Location()
	return time.Date(year, month, day, 0, 0, 0, 0, location)
}

func hasPlanCode(items []string, value string) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func hasStatus(items []SubscriptionStatus, value SubscriptionStatus) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func buildDecisionHash(req SubscriptionCommandRequest, account SubscriptionAccount, status SubscriptionDecisionStatus, reasonCode string) string {
	parts := []string{
		req.TenantID,
		req.CommandID,
		req.SubscriptionID,
		req.AccountantFirmID,
		account.PlanCode,
		string(account.Status),
		string(status),
		reasonCode,
		fmt.Sprintf("%d", account.AssignedFirmLimit),
	}
	return "monthly-subscription:" + strings.Join(parts, ":")
}
