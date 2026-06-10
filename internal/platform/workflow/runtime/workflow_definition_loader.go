package workflowruntime

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	WorkflowStepTypeTask         = "TASK"
	WorkflowStepTypeApproval     = "APPROVAL"
	WorkflowStepTypeDecision     = "DECISION"
	WorkflowStepTypeCompensation = "COMPENSATION"
	WorkflowStepTypeNotify       = "NOTIFY"

	WorkflowDefinitionStatusDraft    = "DRAFT"
	WorkflowDefinitionStatusActive   = "ACTIVE"
	WorkflowDefinitionStatusArchived = "ARCHIVED"

	WorkflowDefinitionDecisionAllow = "ALLOW"
	WorkflowDefinitionDecisionDeny  = "DENY"

	WorkflowDefinitionReasonAllowed                 = "WORKFLOW_DEFINITION_ALLOWED"
	WorkflowDefinitionReasonMissingTenant           = "WORKFLOW_DEFINITION_MISSING_TENANT"
	WorkflowDefinitionReasonCrossTenant             = "WORKFLOW_DEFINITION_CROSS_TENANT_DENIED"
	WorkflowDefinitionReasonInvalidJSON             = "WORKFLOW_DEFINITION_INVALID_JSON"
	WorkflowDefinitionReasonMissingDefinitionKey    = "WORKFLOW_DEFINITION_MISSING_DEFINITION_KEY"
	WorkflowDefinitionReasonMissingVersion          = "WORKFLOW_DEFINITION_MISSING_VERSION"
	WorkflowDefinitionReasonMissingName             = "WORKFLOW_DEFINITION_MISSING_NAME"
	WorkflowDefinitionReasonMissingStep             = "WORKFLOW_DEFINITION_MISSING_STEP"
	WorkflowDefinitionReasonDuplicateStep           = "WORKFLOW_DEFINITION_DUPLICATE_STEP"
	WorkflowDefinitionReasonInvalidStepType         = "WORKFLOW_DEFINITION_INVALID_STEP_TYPE"
	WorkflowDefinitionReasonMissingApprovalPolicy   = "WORKFLOW_DEFINITION_MISSING_APPROVAL_POLICY"
	WorkflowDefinitionReasonMissingRetryPolicy      = "WORKFLOW_DEFINITION_MISSING_RETRY_POLICY"
	WorkflowDefinitionReasonMissingCompensationStep = "WORKFLOW_DEFINITION_MISSING_COMPENSATION_STEP"
	WorkflowDefinitionReasonInvalidInitialStep      = "WORKFLOW_DEFINITION_INVALID_INITIAL_STEP"
)

var (
	ErrWorkflowDefinitionMissingTenant           = errors.New("missing workflow definition tenant id")
	ErrWorkflowDefinitionCrossTenant             = errors.New("cross-tenant workflow definition access denied")
	ErrWorkflowDefinitionInvalidJSON             = errors.New("invalid workflow definition json")
	ErrWorkflowDefinitionMissingDefinitionKey    = errors.New("missing workflow definition key")
	ErrWorkflowDefinitionMissingVersion          = errors.New("missing workflow definition version")
	ErrWorkflowDefinitionMissingName             = errors.New("missing workflow definition name")
	ErrWorkflowDefinitionMissingStep             = errors.New("missing workflow definition step")
	ErrWorkflowDefinitionDuplicateStep           = errors.New("duplicate workflow definition step")
	ErrWorkflowDefinitionInvalidStepType         = errors.New("invalid workflow definition step type")
	ErrWorkflowDefinitionMissingApprovalPolicy   = errors.New("missing approval policy")
	ErrWorkflowDefinitionMissingRetryPolicy      = errors.New("missing retry policy")
	ErrWorkflowDefinitionMissingCompensationStep = errors.New("missing compensation step")
	ErrWorkflowDefinitionInvalidInitialStep      = errors.New("invalid initial workflow step")
)

type WorkflowDefinitionLoaderConfig struct {
	RequireTenant bool `json:"require_tenant"`
}

func DefaultWorkflowDefinitionLoaderConfig() WorkflowDefinitionLoaderConfig {
	return WorkflowDefinitionLoaderConfig{
		RequireTenant: true,
	}
}

type WorkflowDefinition struct {
	TenantID      string                   `json:"tenant_id"`
	DefinitionKey string                   `json:"definition_key"`
	Version       string                   `json:"version"`
	Name          string                   `json:"name"`
	Description   string                   `json:"description,omitempty"`
	Status        string                   `json:"status"`
	InitialStepID string                   `json:"initial_step_id"`
	Steps         []WorkflowStepDefinition `json:"steps"`
	Metadata      map[string]string        `json:"metadata,omitempty"`
	LoadedAt      string                   `json:"loaded_at,omitempty"`
}

type WorkflowStepDefinition struct {
	StepID           string                          `json:"step_id"`
	Name             string                          `json:"name"`
	Type             string                          `json:"type"`
	NextStepIDs      []string                        `json:"next_step_ids,omitempty"`
	ApprovalPolicy   *WorkflowApprovalStepDefinition `json:"approval_policy,omitempty"`
	RetryPolicy      *WorkflowRetryPolicyDefinition  `json:"retry_policy,omitempty"`
	CompensationStep *WorkflowCompensationDefinition `json:"compensation_step,omitempty"`
	Metadata         map[string]string               `json:"metadata,omitempty"`
}

type WorkflowApprovalStepDefinition struct {
	RequiredRole   string `json:"required_role"`
	RequiredCount  int    `json:"required_count"`
	TimeoutSeconds int    `json:"timeout_seconds,omitempty"`
}

type WorkflowRetryPolicyDefinition struct {
	MaxAttempts     int    `json:"max_attempts"`
	BackoffStrategy string `json:"backoff_strategy"`
	BackoffSeconds  int    `json:"backoff_seconds"`
}

type WorkflowCompensationDefinition struct {
	StepID string `json:"step_id"`
	Mode   string `json:"mode"`
}

type WorkflowDefinitionLoadRequest struct {
	TenantID      string `json:"tenant_id"`
	RawJSON       []byte `json:"-"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type WorkflowDefinitionLoadDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	DefinitionKey string `json:"definition_key,omitempty"`
	Version       string `json:"version,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type WorkflowDefinitionLoader struct {
	config WorkflowDefinitionLoaderConfig
}

func NewWorkflowDefinitionLoader(config WorkflowDefinitionLoaderConfig) *WorkflowDefinitionLoader {
	return &WorkflowDefinitionLoader{config: config}
}

func (l *WorkflowDefinitionLoader) LoadJSON(req WorkflowDefinitionLoadRequest) (WorkflowDefinition, WorkflowDefinitionLoadDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	decision := WorkflowDefinitionLoadDecision{
		Decision:  WorkflowDefinitionDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		CheckedAt: now,
	}

	if l.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowDefinitionReasonMissingTenant
		return WorkflowDefinition{}, decision, ErrWorkflowDefinitionMissingTenant
	}

	var definition WorkflowDefinition
	if err := json.Unmarshal(req.RawJSON, &definition); err != nil {
		decision.Reason = WorkflowDefinitionReasonInvalidJSON
		return WorkflowDefinition{}, decision, fmt.Errorf("%w: %v", ErrWorkflowDefinitionInvalidJSON, err)
	}

	definition.TenantID = strings.TrimSpace(definition.TenantID)
	definition.DefinitionKey = strings.TrimSpace(definition.DefinitionKey)
	definition.Version = strings.TrimSpace(definition.Version)
	definition.Name = strings.TrimSpace(definition.Name)
	definition.Status = normalizeDefinitionStatus(definition.Status)
	definition.InitialStepID = strings.TrimSpace(definition.InitialStepID)
	definition.LoadedAt = now

	decision.DefinitionKey = definition.DefinitionKey
	decision.Version = definition.Version

	if definition.TenantID == "" {
		definition.TenantID = tenantID
	}

	if definition.TenantID != tenantID {
		decision.Reason = WorkflowDefinitionReasonCrossTenant
		return WorkflowDefinition{}, decision, ErrWorkflowDefinitionCrossTenant
	}

	if err, reason := ValidateWorkflowDefinition(definition); err != nil {
		decision.Reason = reason
		return WorkflowDefinition{}, decision, err
	}

	decision.Decision = WorkflowDefinitionDecisionAllow
	decision.Allowed = true
	decision.Reason = WorkflowDefinitionReasonAllowed

	return definition, decision, nil
}

func ValidateWorkflowDefinition(definition WorkflowDefinition) (error, string) {
	if strings.TrimSpace(definition.TenantID) == "" {
		return ErrWorkflowDefinitionMissingTenant, WorkflowDefinitionReasonMissingTenant
	}

	if strings.TrimSpace(definition.DefinitionKey) == "" {
		return ErrWorkflowDefinitionMissingDefinitionKey, WorkflowDefinitionReasonMissingDefinitionKey
	}

	if strings.TrimSpace(definition.Version) == "" {
		return ErrWorkflowDefinitionMissingVersion, WorkflowDefinitionReasonMissingVersion
	}

	if strings.TrimSpace(definition.Name) == "" {
		return ErrWorkflowDefinitionMissingName, WorkflowDefinitionReasonMissingName
	}

	if len(definition.Steps) == 0 {
		return ErrWorkflowDefinitionMissingStep, WorkflowDefinitionReasonMissingStep
	}

	stepByID := make(map[string]WorkflowStepDefinition, len(definition.Steps))
	for _, step := range definition.Steps {
		step.StepID = strings.TrimSpace(step.StepID)
		step.Type = strings.TrimSpace(step.Type)

		if step.StepID == "" {
			return ErrWorkflowDefinitionMissingStep, WorkflowDefinitionReasonMissingStep
		}

		if _, exists := stepByID[step.StepID]; exists {
			return ErrWorkflowDefinitionDuplicateStep, WorkflowDefinitionReasonDuplicateStep
		}

		if !isAllowedWorkflowStepType(step.Type) {
			return ErrWorkflowDefinitionInvalidStepType, WorkflowDefinitionReasonInvalidStepType
		}

		if step.Type == WorkflowStepTypeApproval {
			if step.ApprovalPolicy == nil || strings.TrimSpace(step.ApprovalPolicy.RequiredRole) == "" || step.ApprovalPolicy.RequiredCount <= 0 {
				return ErrWorkflowDefinitionMissingApprovalPolicy, WorkflowDefinitionReasonMissingApprovalPolicy
			}
		}

		if step.RetryPolicy != nil {
			if step.RetryPolicy.MaxAttempts <= 0 || strings.TrimSpace(step.RetryPolicy.BackoffStrategy) == "" || step.RetryPolicy.BackoffSeconds < 0 {
				return ErrWorkflowDefinitionMissingRetryPolicy, WorkflowDefinitionReasonMissingRetryPolicy
			}
		}

		if step.Type == WorkflowStepTypeCompensation {
			if step.CompensationStep == nil || strings.TrimSpace(step.CompensationStep.StepID) == "" {
				return ErrWorkflowDefinitionMissingCompensationStep, WorkflowDefinitionReasonMissingCompensationStep
			}
		}

		stepByID[step.StepID] = step
	}

	if strings.TrimSpace(definition.InitialStepID) == "" {
		return ErrWorkflowDefinitionInvalidInitialStep, WorkflowDefinitionReasonInvalidInitialStep
	}

	if _, ok := stepByID[definition.InitialStepID]; !ok {
		return ErrWorkflowDefinitionInvalidInitialStep, WorkflowDefinitionReasonInvalidInitialStep
	}

	for _, step := range definition.Steps {
		for _, next := range step.NextStepIDs {
			if _, ok := stepByID[strings.TrimSpace(next)]; !ok {
				return ErrWorkflowDefinitionMissingStep, WorkflowDefinitionReasonMissingStep
			}
		}

		if step.CompensationStep != nil {
			if _, ok := stepByID[strings.TrimSpace(step.CompensationStep.StepID)]; !ok {
				return ErrWorkflowDefinitionMissingCompensationStep, WorkflowDefinitionReasonMissingCompensationStep
			}
		}
	}

	return nil, WorkflowDefinitionReasonAllowed
}

func (d WorkflowDefinition) StepByID(stepID string) (WorkflowStepDefinition, bool) {
	stepID = strings.TrimSpace(stepID)
	for _, step := range d.Steps {
		if step.StepID == stepID {
			return step, true
		}
	}
	return WorkflowStepDefinition{}, false
}

func isAllowedWorkflowStepType(stepType string) bool {
	switch strings.TrimSpace(stepType) {
	case WorkflowStepTypeTask,
		WorkflowStepTypeApproval,
		WorkflowStepTypeDecision,
		WorkflowStepTypeCompensation,
		WorkflowStepTypeNotify:
		return true
	default:
		return false
	}
}

func normalizeDefinitionStatus(status string) string {
	status = strings.TrimSpace(status)
	if status == "" {
		return WorkflowDefinitionStatusDraft
	}
	return status
}
