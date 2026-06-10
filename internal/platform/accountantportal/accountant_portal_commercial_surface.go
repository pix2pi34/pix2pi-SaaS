package accountantportal

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	ModuleCode = "FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE"

	ModeCommercialSurfaceDryRunOnly = "COMMERCIAL_SURFACE_DRY_RUN_ONLY"

	StatusReadyDryRunOnly                       = "READY_DRY_RUN_ONLY"
	StatusDraftOnlyNoRealInvoice                = "DRAFT_ONLY_NO_REAL_INVOICE"
	StatusPreviewOnlyNoRealCustomerData         = "PREVIEW_ONLY_NO_REAL_CUSTOMER_DATA"
	StatusClosedUntilBillingLiveModule          = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	StatusClosedUntilProviderLiveModule         = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	StatusClosedUntilSyncWorkerLiveModule       = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	StatusClosedUntilExportLiveModule           = "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
	StatusClosedUntilCommercialApproval         = "CLOSED_UNTIL_COMMERCIAL_APPROVAL"
	StatusClosedUntilOperatorProviderLiveModule = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
)

var ErrLiveOperationClosed = errors.New("accountant portal live commercial operation is closed in FAZ 7-9")

type CommercialGate struct {
	RealAccountantBillingStatus      string `json:"real_accountant_billing_status"`
	RealPaymentCaptureStatus         string `json:"real_payment_capture_status"`
	RealProviderAPIStatus            string `json:"real_provider_api_status"`
	RealERPWriteStatus               string `json:"real_erp_write_status"`
	RealCustomerDataExportLiveStatus string `json:"real_customer_data_export_live_status"`
	RealFileDeliveryStatus           string `json:"real_file_delivery_status"`
	RealOperatorProviderActionStatus string `json:"real_operator_provider_action_status"`
	CommercialApprovalStatus         string `json:"commercial_approval_status"`
	ProviderLiveModuleStatus         string `json:"provider_live_module_status"`
	SyncWorkerLiveModuleStatus       string `json:"sync_worker_live_module_status"`
}

func DefaultCommercialGate() CommercialGate {
	return CommercialGate{
		RealAccountantBillingStatus:      StatusClosedUntilBillingLiveModule,
		RealPaymentCaptureStatus:         StatusClosedUntilBillingLiveModule,
		RealProviderAPIStatus:            StatusClosedUntilProviderLiveModule,
		RealERPWriteStatus:               StatusClosedUntilSyncWorkerLiveModule,
		RealCustomerDataExportLiveStatus: StatusClosedUntilExportLiveModule,
		RealFileDeliveryStatus:           StatusClosedUntilProviderLiveModule,
		RealOperatorProviderActionStatus: StatusClosedUntilOperatorProviderLiveModule,
		CommercialApprovalStatus:         StatusClosedUntilCommercialApproval,
		ProviderLiveModuleStatus:         "NOT_STARTED",
		SyncWorkerLiveModuleStatus:       "NOT_STARTED",
	}
}

func (g CommercialGate) AssertLiveOperationsClosed() error {
	checks := map[string]string{
		"real_accountant_billing_status":        g.RealAccountantBillingStatus,
		"real_payment_capture_status":           g.RealPaymentCaptureStatus,
		"real_provider_api_status":              g.RealProviderAPIStatus,
		"real_erp_write_status":                 g.RealERPWriteStatus,
		"real_customer_data_export_live_status": g.RealCustomerDataExportLiveStatus,
		"real_file_delivery_status":             g.RealFileDeliveryStatus,
		"real_operator_provider_action_status":  g.RealOperatorProviderActionStatus,
		"commercial_approval_status":            g.CommercialApprovalStatus,
	}
	for name, value := range checks {
		if !strings.HasPrefix(value, "CLOSED_") {
			return fmt.Errorf("%s must remain closed, got %q", name, value)
		}
	}
	return nil
}

type ProviderDryRunEntitlement struct {
	ProviderCode          string `json:"provider_code"`
	ConnectorSealStatus   string `json:"connector_seal_status"`
	DryRunExportPreview   bool   `json:"dry_run_export_preview"`
	RealProviderAPIStatus string `json:"real_provider_api_status"`
	RealFileDelivery      string `json:"real_file_delivery_status"`
	RealERPWriteStatus    string `json:"real_erp_write_status"`
}

type AccountantPlan struct {
	Code                 string                      `json:"code"`
	Name                 string                      `json:"name"`
	MonthlyPriceTRY      int                         `json:"monthly_price_try"`
	Currency             string                      `json:"currency"`
	MaxFirmSlots         int                         `json:"max_firm_slots"`
	MaxPortalUsers       int                         `json:"max_portal_users"`
	ExportPreviewEnabled bool                        `json:"export_preview_enabled"`
	BillingMode          string                      `json:"billing_mode"`
	Status               string                      `json:"status"`
	ProviderDryRunSet    []ProviderDryRunEntitlement `json:"provider_dry_run_set"`
}

type FirmAssignment struct {
	AssignmentID       string    `json:"assignment_id"`
	AccountantTenantID string    `json:"accountant_tenant_id"`
	FirmTenantID       string    `json:"firm_tenant_id"`
	PlanCode           string    `json:"plan_code"`
	PeriodYYYYMM       string    `json:"period_yyyy_mm"`
	Role               string    `json:"role"`
	Permissions        []string  `json:"permissions"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
}

type AuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
}

type AssignFirmRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	PlanCode           string
	PeriodYYYYMM       string
	Role               string
	Permissions        []string
}

type BillingDraftRequest struct {
	AccountantTenantID string
	PlanCode           string
	PeriodYYYYMM       string
	FirmSlotCount      int
}

type BillingDraft struct {
	DraftID                   string `json:"draft_id"`
	AccountantTenantID        string `json:"accountant_tenant_id"`
	PlanCode                  string `json:"plan_code"`
	PeriodYYYYMM              string `json:"period_yyyy_mm"`
	AmountTRY                 int    `json:"amount_try"`
	Currency                  string `json:"currency"`
	Status                    string `json:"status"`
	RealInvoiceCreated        bool   `json:"real_invoice_created"`
	RealPaymentCaptureEnabled bool   `json:"real_payment_capture_enabled"`
	ProviderTransactionID     string `json:"provider_transaction_id"`
}

type ExportPreviewRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	ProviderCode       string
	PeriodYYYYMM       string
	Format             string
}

type ExportPreview struct {
	PreviewID                string `json:"preview_id"`
	ProviderCode             string `json:"provider_code"`
	Format                   string `json:"format"`
	Status                   string `json:"status"`
	ContainsRealCustomerData bool   `json:"contains_real_customer_data"`
	LiveDeliveryRequested    bool   `json:"live_delivery_requested"`
	RealProviderAPIRequested bool   `json:"real_provider_api_requested"`
	RealERPWriteRequested    bool   `json:"real_erp_write_requested"`
	PreviewRowCount          int    `json:"preview_row_count"`
}

type CommercialSurface struct {
	ModuleCode          string                      `json:"module_code"`
	Mode                string                      `json:"mode"`
	AccountantTenantID  string                      `json:"accountant_tenant_id"`
	PeriodYYYYMM        string                      `json:"period_yyyy_mm"`
	Plans               []AccountantPlan            `json:"plans"`
	Assignments         []FirmAssignment            `json:"assignments"`
	ProviderDryRunSet   []ProviderDryRunEntitlement `json:"provider_dry_run_set"`
	Gate                CommercialGate              `json:"gate"`
	LiveOperationPolicy string                      `json:"live_operation_policy"`
}

type AccountantPortalRuntime struct {
	gate        CommercialGate
	plans       map[string]AccountantPlan
	assignments map[string]FirmAssignment
	auditEvents []AuditEvent
	now         func() time.Time
}

func NewDefaultRuntime() *AccountantPortalRuntime {
	gate := DefaultCommercialGate()
	providers := []ProviderDryRunEntitlement{
		sealedDryRunProvider("PARASUT"),
		sealedDryRunProvider("LOGO"),
		sealedDryRunProvider("MIKRO"),
		sealedDryRunProvider("ZIRVE"),
	}
	plans := map[string]AccountantPlan{
		"ACCOUNTANT_STARTER": {
			Code:                 "ACCOUNTANT_STARTER",
			Name:                 "Muhasebeci Starter",
			MonthlyPriceTRY:      1490,
			Currency:             "TRY",
			MaxFirmSlots:         5,
			MaxPortalUsers:       2,
			ExportPreviewEnabled: true,
			BillingMode:          StatusDraftOnlyNoRealInvoice,
			Status:               StatusReadyDryRunOnly,
			ProviderDryRunSet:    providers,
		},
		"ACCOUNTANT_PRO": {
			Code:                 "ACCOUNTANT_PRO",
			Name:                 "Muhasebeci Pro",
			MonthlyPriceTRY:      3990,
			Currency:             "TRY",
			MaxFirmSlots:         25,
			MaxPortalUsers:       8,
			ExportPreviewEnabled: true,
			BillingMode:          StatusDraftOnlyNoRealInvoice,
			Status:               StatusReadyDryRunOnly,
			ProviderDryRunSet:    providers,
		},
		"ACCOUNTANT_ENTERPRISE": {
			Code:                 "ACCOUNTANT_ENTERPRISE",
			Name:                 "Muhasebeci Enterprise",
			MonthlyPriceTRY:      9990,
			Currency:             "TRY",
			MaxFirmSlots:         100,
			MaxPortalUsers:       25,
			ExportPreviewEnabled: true,
			BillingMode:          StatusDraftOnlyNoRealInvoice,
			Status:               StatusReadyDryRunOnly,
			ProviderDryRunSet:    providers,
		},
	}
	return &AccountantPortalRuntime{
		gate:        gate,
		plans:       plans,
		assignments: map[string]FirmAssignment{},
		auditEvents: []AuditEvent{},
		now:         time.Now,
	}
}

func sealedDryRunProvider(code string) ProviderDryRunEntitlement {
	return ProviderDryRunEntitlement{
		ProviderCode:          code,
		ConnectorSealStatus:   "SEALED",
		DryRunExportPreview:   true,
		RealProviderAPIStatus: StatusClosedUntilProviderLiveModule,
		RealFileDelivery:      StatusClosedUntilProviderLiveModule,
		RealERPWriteStatus:    StatusClosedUntilSyncWorkerLiveModule,
	}
}

func (r *AccountantPortalRuntime) BuildCommercialSurface(accountantTenantID, period string) (CommercialSurface, error) {
	if err := r.validateTenantAndPeriod(accountantTenantID, period); err != nil {
		return CommercialSurface{}, err
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		return CommercialSurface{}, err
	}
	plans := make([]AccountantPlan, 0, len(r.plans))
	for _, plan := range r.plans {
		plans = append(plans, plan)
	}
	assignments := r.ListAssignments(accountantTenantID, period)
	return CommercialSurface{
		ModuleCode:          ModuleCode,
		Mode:                ModeCommercialSurfaceDryRunOnly,
		AccountantTenantID:  accountantTenantID,
		PeriodYYYYMM:        period,
		Plans:               plans,
		Assignments:         assignments,
		ProviderDryRunSet:   sealedProviderSet(),
		Gate:                r.gate,
		LiveOperationPolicy: "REAL_BILLING_PROVIDER_API_ERP_WRITE_AND_CUSTOMER_EXPORT_CLOSED",
	}, nil
}

func (r *AccountantPortalRuntime) AssignFirm(req AssignFirmRequest) (FirmAssignment, error) {
	if err := r.validateTenantAndPeriod(req.AccountantTenantID, req.PeriodYYYYMM); err != nil {
		return FirmAssignment{}, err
	}
	if strings.TrimSpace(req.FirmTenantID) == "" {
		return FirmAssignment{}, errors.New("firm tenant id is required")
	}
	if req.AccountantTenantID == req.FirmTenantID {
		return FirmAssignment{}, errors.New("accountant tenant and firm tenant must be different")
	}
	plan, ok := r.plans[req.PlanCode]
	if !ok {
		return FirmAssignment{}, fmt.Errorf("unknown accountant plan %q", req.PlanCode)
	}
	if len(r.ListAssignments(req.AccountantTenantID, req.PeriodYYYYMM)) >= plan.MaxFirmSlots {
		return FirmAssignment{}, errors.New("accountant firm slot limit exceeded")
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		return FirmAssignment{}, err
	}
	role := strings.TrimSpace(req.Role)
	if role == "" {
		role = "accountant_operator"
	}
	permissions := normalizePermissions(req.Permissions)
	assignmentID := stableID("ACCT-ASG", req.AccountantTenantID, req.FirmTenantID, req.PeriodYYYYMM)
	assignment := FirmAssignment{
		AssignmentID:       assignmentID,
		AccountantTenantID: req.AccountantTenantID,
		FirmTenantID:       req.FirmTenantID,
		PlanCode:           req.PlanCode,
		PeriodYYYYMM:       req.PeriodYYYYMM,
		Role:               role,
		Permissions:        permissions,
		Status:             StatusReadyDryRunOnly,
		CreatedAt:          r.now().UTC(),
	}
	r.assignments[assignmentKey(req.AccountantTenantID, req.FirmTenantID, req.PeriodYYYYMM)] = assignment
	r.appendAudit("ACCOUNTANT_FIRM_SLOT_ASSIGNED", req.AccountantTenantID, req.FirmTenantID, StatusReadyDryRunOnly)
	return assignment, nil
}

func (r *AccountantPortalRuntime) ListAssignments(accountantTenantID, period string) []FirmAssignment {
	result := []FirmAssignment{}
	for _, assignment := range r.assignments {
		if assignment.AccountantTenantID == accountantTenantID && assignment.PeriodYYYYMM == period {
			result = append(result, assignment)
		}
	}
	return result
}

func (r *AccountantPortalRuntime) CreateBillingDraft(req BillingDraftRequest) (BillingDraft, error) {
	if err := r.validateTenantAndPeriod(req.AccountantTenantID, req.PeriodYYYYMM); err != nil {
		return BillingDraft{}, err
	}
	plan, ok := r.plans[req.PlanCode]
	if !ok {
		return BillingDraft{}, fmt.Errorf("unknown accountant plan %q", req.PlanCode)
	}
	if req.FirmSlotCount < 0 || req.FirmSlotCount > plan.MaxFirmSlots {
		return BillingDraft{}, errors.New("firm slot count is outside plan entitlement")
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		return BillingDraft{}, err
	}
	draft := BillingDraft{
		DraftID:                   stableID("ACCT-BILL-DRAFT", req.AccountantTenantID, req.PlanCode, req.PeriodYYYYMM),
		AccountantTenantID:        req.AccountantTenantID,
		PlanCode:                  req.PlanCode,
		PeriodYYYYMM:              req.PeriodYYYYMM,
		AmountTRY:                 plan.MonthlyPriceTRY,
		Currency:                  plan.Currency,
		Status:                    StatusDraftOnlyNoRealInvoice,
		RealInvoiceCreated:        false,
		RealPaymentCaptureEnabled: false,
		ProviderTransactionID:     "",
	}
	r.appendAudit("ACCOUNTANT_BILLING_DRAFT_CREATED", req.AccountantTenantID, "", StatusDraftOnlyNoRealInvoice)
	return draft, nil
}

func (r *AccountantPortalRuntime) BuildExportPreview(req ExportPreviewRequest) (ExportPreview, error) {
	if err := r.validateTenantAndPeriod(req.AccountantTenantID, req.PeriodYYYYMM); err != nil {
		return ExportPreview{}, err
	}
	if strings.TrimSpace(req.FirmTenantID) == "" {
		return ExportPreview{}, errors.New("firm tenant id is required")
	}
	if !r.assignmentExists(req.AccountantTenantID, req.FirmTenantID, req.PeriodYYYYMM) {
		return ExportPreview{}, errors.New("firm tenant is not assigned to accountant for period")
	}
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	if !isSupportedProvider(provider) {
		return ExportPreview{}, fmt.Errorf("unsupported provider %q", req.ProviderCode)
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		return ExportPreview{}, err
	}
	format := strings.ToUpper(strings.TrimSpace(req.Format))
	if format == "" {
		format = "DRY_RUN_PREVIEW"
	}
	preview := ExportPreview{
		PreviewID:                stableID("ACCT-EXP-PREVIEW", req.AccountantTenantID, req.FirmTenantID, provider, req.PeriodYYYYMM),
		ProviderCode:             provider,
		Format:                   format,
		Status:                   StatusPreviewOnlyNoRealCustomerData,
		ContainsRealCustomerData: false,
		LiveDeliveryRequested:    false,
		RealProviderAPIRequested: false,
		RealERPWriteRequested:    false,
		PreviewRowCount:          0,
	}
	r.appendAudit("ACCOUNTANT_EXPORT_PREVIEW_BUILT", req.AccountantTenantID, req.FirmTenantID, StatusPreviewOnlyNoRealCustomerData)
	return preview, nil
}

func (r *AccountantPortalRuntime) RequestLiveCommercialOperation(operation string) error {
	_ = operation
	return ErrLiveOperationClosed
}

func (r *AccountantPortalRuntime) AuditEvents() []AuditEvent {
	out := make([]AuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *AccountantPortalRuntime) assignmentExists(accountantTenantID, firmTenantID, period string) bool {
	_, ok := r.assignments[assignmentKey(accountantTenantID, firmTenantID, period)]
	return ok
}

func (r *AccountantPortalRuntime) validateTenantAndPeriod(accountantTenantID, period string) error {
	if strings.TrimSpace(accountantTenantID) == "" {
		return errors.New("accountant tenant id is required")
	}
	if len(period) != 7 || period[4] != '-' {
		return errors.New("period must use YYYY-MM format")
	}
	return nil
}

func (r *AccountantPortalRuntime) appendAudit(code, accountantTenantID, firmTenantID, status string) {
	r.auditEvents = append(r.auditEvents, AuditEvent{
		EventCode:          code,
		AccountantTenantID: accountantTenantID,
		FirmTenantID:       firmTenantID,
		Status:             status,
		CreatedAt:          r.now().UTC(),
	})
}

func sealedProviderSet() []ProviderDryRunEntitlement {
	return []ProviderDryRunEntitlement{
		sealedDryRunProvider("PARASUT"),
		sealedDryRunProvider("LOGO"),
		sealedDryRunProvider("MIKRO"),
		sealedDryRunProvider("ZIRVE"),
	}
}

func isSupportedProvider(provider string) bool {
	switch provider {
	case "PARASUT", "LOGO", "MIKRO", "ZIRVE":
		return true
	default:
		return false
	}
}

func normalizePermissions(in []string) []string {
	if len(in) == 0 {
		return []string{"firm.read", "report.preview", "export.preview"}
	}
	out := make([]string, 0, len(in))
	seen := map[string]bool{}
	for _, p := range in {
		p = strings.ToLower(strings.TrimSpace(p))
		if p == "" || seen[p] {
			continue
		}
		seen[p] = true
		out = append(out, p)
	}
	return out
}

func assignmentKey(accountantTenantID, firmTenantID, period string) string {
	return accountantTenantID + "|" + firmTenantID + "|" + period
}

func stableID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
