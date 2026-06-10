package accountantportal

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	AccountantAccessModuleCode = "FAZ_7_10_ACCOUNTANT_PORTAL_ACCESS_RUNTIME"

	AccountantAccessModeMultiFirmDryRunOnly = "MULTI_FIRM_ACCESS_RUNTIME_DRY_RUN_ONLY"

	AccountantAccessStatusActiveDryRunOnly       = "ACTIVE_DRY_RUN_ONLY"
	AccountantAccessStatusRevokedDryRunOnly      = "REVOKED_DRY_RUN_ONLY"
	AccountantAccessStatusDenied                 = "DENIED"
	AccountantAccessStatusAllowed                = "ALLOWED"
	AccountantAccessNoRealCustomerDataPolicy     = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_THIS_PHASE"
	AccountantAccessNoProviderOperationPolicy    = "NO_REAL_PROVIDER_API_OPERATION_IN_THIS_PHASE"
	AccountantAccessNoERPWritePolicy             = "NO_REAL_ERP_WRITE_IN_THIS_PHASE"
	AccountantAccessTenantIsolationPolicy        = "ACCOUNTANT_TENANT_AND_FIRM_TENANT_BOUNDARY_ENFORCED"
	AccountantAccessDefaultRoleViewer            = "accountant_viewer"
	AccountantAccessDefaultRoleOperator          = "accountant_operator"
	AccountantAccessDefaultPermissionFirmRead    = "firm.read"
	AccountantAccessDefaultPermissionReportView  = "report.view"
	AccountantAccessDefaultPermissionExportView  = "export.preview"
	AccountantAccessDefaultPermissionBillingView = "billing.draft.view"

	AccountantAccessClosedUntilBillingLiveModule    = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	AccountantAccessClosedUntilProviderLiveModule   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	AccountantAccessClosedUntilSyncWorkerLiveModule = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	AccountantAccessClosedUntilExportLiveModule     = "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
)

var ErrAccountantAccessLiveOperationClosed = errors.New("accountant portal live access/export/provider operation is closed in FAZ 7-10")

type AccountantAccessGate struct {
	RealAccountantBillingStatus      string `json:"real_accountant_billing_status"`
	RealPaymentCaptureStatus         string `json:"real_payment_capture_status"`
	RealProviderAPIStatus            string `json:"real_provider_api_status"`
	RealERPWriteStatus               string `json:"real_erp_write_status"`
	RealCustomerDataExportLiveStatus string `json:"real_customer_data_export_live_status"`
	RealFileDeliveryStatus           string `json:"real_file_delivery_status"`
	RealOperatorProviderActionStatus string `json:"real_operator_provider_action_status"`
	MultiFirmAccessRuntimeStatus     string `json:"multi_firm_access_runtime_status"`
}

func DefaultAccountantAccessGate() AccountantAccessGate {
	return AccountantAccessGate{
		RealAccountantBillingStatus:      AccountantAccessClosedUntilBillingLiveModule,
		RealPaymentCaptureStatus:         AccountantAccessClosedUntilBillingLiveModule,
		RealProviderAPIStatus:            AccountantAccessClosedUntilProviderLiveModule,
		RealERPWriteStatus:               AccountantAccessClosedUntilSyncWorkerLiveModule,
		RealCustomerDataExportLiveStatus: AccountantAccessClosedUntilExportLiveModule,
		RealFileDeliveryStatus:           AccountantAccessClosedUntilProviderLiveModule,
		RealOperatorProviderActionStatus: AccountantAccessClosedUntilProviderLiveModule,
		MultiFirmAccessRuntimeStatus:     AccountantAccessStatusActiveDryRunOnly,
	}
}

func (g AccountantAccessGate) AssertLiveOperationsClosed() error {
	checks := map[string]string{
		"real_accountant_billing_status":        g.RealAccountantBillingStatus,
		"real_payment_capture_status":           g.RealPaymentCaptureStatus,
		"real_provider_api_status":              g.RealProviderAPIStatus,
		"real_erp_write_status":                 g.RealERPWriteStatus,
		"real_customer_data_export_live_status": g.RealCustomerDataExportLiveStatus,
		"real_file_delivery_status":             g.RealFileDeliveryStatus,
		"real_operator_provider_action_status":  g.RealOperatorProviderActionStatus,
	}
	for name, value := range checks {
		if !strings.HasPrefix(value, "CLOSED_") {
			return fmt.Errorf("%s must remain closed, got %q", name, value)
		}
	}
	return nil
}

type FirmAccessGrant struct {
	GrantID            string    `json:"grant_id"`
	AccountantTenantID string    `json:"accountant_tenant_id"`
	FirmTenantID       string    `json:"firm_tenant_id"`
	UserID             string    `json:"user_id"`
	PeriodYYYYMM       string    `json:"period_yyyy_mm"`
	Role               string    `json:"role"`
	Permissions        []string  `json:"permissions"`
	Status             string    `json:"status"`
	CreatedAt          time.Time `json:"created_at"`
	RevokedAt          time.Time `json:"revoked_at,omitempty"`
}

type FirmContext struct {
	AccountantTenantID           string   `json:"accountant_tenant_id"`
	FirmTenantID                 string   `json:"firm_tenant_id"`
	UserID                       string   `json:"user_id"`
	PeriodYYYYMM                 string   `json:"period_yyyy_mm"`
	Role                         string   `json:"role"`
	Permissions                  []string `json:"permissions"`
	ContainsRealCustomerData     bool     `json:"contains_real_customer_data"`
	RealProviderAPIAllowed       bool     `json:"real_provider_api_allowed"`
	RealERPWriteAllowed          bool     `json:"real_erp_write_allowed"`
	RealCustomerDataExportStatus string   `json:"real_customer_data_export_status"`
}

type FirmAccessRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	UserID             string
	PeriodYYYYMM       string
	Role               string
	Permissions        []string
}

type FirmContextRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	UserID             string
	PeriodYYYYMM       string
	Permission         string
}

type FirmAccessDecision struct {
	DecisionID            string      `json:"decision_id"`
	Allowed               bool        `json:"allowed"`
	Status                string      `json:"status"`
	DenyReason            string      `json:"deny_reason,omitempty"`
	RequiredPermission    string      `json:"required_permission,omitempty"`
	SelectedFirmContext   FirmContext `json:"selected_firm_context"`
	LiveOperationPolicy   string      `json:"live_operation_policy"`
	TenantIsolationPolicy string      `json:"tenant_isolation_policy"`
	CreatedAt             time.Time   `json:"created_at"`
}

type AccountantAccessAuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	UserID             string    `json:"user_id,omitempty"`
	PeriodYYYYMM       string    `json:"period_yyyy_mm,omitempty"`
	Status             string    `json:"status"`
	Reason             string    `json:"reason,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

type AccountantPortalAccessRuntime struct {
	gate        AccountantAccessGate
	grants      map[string]FirmAccessGrant
	auditEvents []AccountantAccessAuditEvent
	now         func() time.Time
}

func NewDefaultAccountantPortalAccessRuntime() *AccountantPortalAccessRuntime {
	return &AccountantPortalAccessRuntime{
		gate:        DefaultAccountantAccessGate(),
		grants:      map[string]FirmAccessGrant{},
		auditEvents: []AccountantAccessAuditEvent{},
		now:         time.Now,
	}
}

func (r *AccountantPortalAccessRuntime) GrantFirmAccess(req FirmAccessRequest) (FirmAccessGrant, error) {
	if err := r.validateBase(req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM); err != nil {
		return FirmAccessGrant{}, err
	}
	if req.AccountantTenantID == req.FirmTenantID {
		return FirmAccessGrant{}, errors.New("accountant tenant and firm tenant must be different")
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		return FirmAccessGrant{}, err
	}
	role := strings.TrimSpace(req.Role)
	if role == "" {
		role = AccountantAccessDefaultRoleViewer
	}
	permissions := normalizeAccessPermissions(req.Permissions)
	grant := FirmAccessGrant{
		GrantID:            stableID("ACCT-ACCESS-GRANT", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM),
		AccountantTenantID: req.AccountantTenantID,
		FirmTenantID:       req.FirmTenantID,
		UserID:             req.UserID,
		PeriodYYYYMM:       req.PeriodYYYYMM,
		Role:               role,
		Permissions:        permissions,
		Status:             AccountantAccessStatusActiveDryRunOnly,
		CreatedAt:          r.now().UTC(),
	}
	r.grants[grantKey(req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM)] = grant
	r.appendAudit("ACCOUNTANT_FIRM_ACCESS_GRANTED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusActiveDryRunOnly, "")
	return grant, nil
}

func (r *AccountantPortalAccessRuntime) SelectFirmContext(req FirmContextRequest) FirmAccessDecision {
	decision := FirmAccessDecision{
		DecisionID:            stableID("ACCT-ACCESS-DECISION", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, req.Permission),
		Allowed:               false,
		Status:                AccountantAccessStatusDenied,
		RequiredPermission:    strings.ToLower(strings.TrimSpace(req.Permission)),
		LiveOperationPolicy:   AccountantAccessNoRealCustomerDataPolicy,
		TenantIsolationPolicy: AccountantAccessTenantIsolationPolicy,
		CreatedAt:             r.now().UTC(),
	}

	if err := r.validateBase(req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM); err != nil {
		decision.DenyReason = err.Error()
		r.appendAudit("ACCOUNTANT_FIRM_CONTEXT_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusDenied, decision.DenyReason)
		return decision
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		decision.DenyReason = err.Error()
		r.appendAudit("ACCOUNTANT_FIRM_CONTEXT_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusDenied, decision.DenyReason)
		return decision
	}

	grant, ok := r.grants[grantKey(req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM)]
	if !ok {
		decision.DenyReason = "active firm access grant not found"
		r.appendAudit("ACCOUNTANT_FIRM_CONTEXT_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusDenied, decision.DenyReason)
		return decision
	}
	if grant.Status != AccountantAccessStatusActiveDryRunOnly {
		decision.DenyReason = "firm access grant is not active"
		r.appendAudit("ACCOUNTANT_FIRM_CONTEXT_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusDenied, decision.DenyReason)
		return decision
	}
	if !hasPermission(grant.Permissions, decision.RequiredPermission) {
		decision.DenyReason = "required permission is missing"
		r.appendAudit("ACCOUNTANT_FIRM_CONTEXT_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusDenied, decision.DenyReason)
		return decision
	}

	decision.Allowed = true
	decision.Status = AccountantAccessStatusAllowed
	decision.DenyReason = ""
	decision.SelectedFirmContext = FirmContext{
		AccountantTenantID:           grant.AccountantTenantID,
		FirmTenantID:                 grant.FirmTenantID,
		UserID:                       grant.UserID,
		PeriodYYYYMM:                 grant.PeriodYYYYMM,
		Role:                         grant.Role,
		Permissions:                  cloneStrings(grant.Permissions),
		ContainsRealCustomerData:     false,
		RealProviderAPIAllowed:       false,
		RealERPWriteAllowed:          false,
		RealCustomerDataExportStatus: AccountantAccessClosedUntilExportLiveModule,
	}
	r.appendAudit("ACCOUNTANT_FIRM_CONTEXT_SELECTED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusAllowed, "")
	return decision
}

func (r *AccountantPortalAccessRuntime) ListVisibleFirms(accountantTenantID, userID, period string) []FirmContext {
	result := []FirmContext{}
	for _, grant := range r.grants {
		if grant.AccountantTenantID != accountantTenantID || grant.UserID != userID || grant.PeriodYYYYMM != period {
			continue
		}
		if grant.Status != AccountantAccessStatusActiveDryRunOnly {
			continue
		}
		result = append(result, FirmContext{
			AccountantTenantID:           grant.AccountantTenantID,
			FirmTenantID:                 grant.FirmTenantID,
			UserID:                       grant.UserID,
			PeriodYYYYMM:                 grant.PeriodYYYYMM,
			Role:                         grant.Role,
			Permissions:                  cloneStrings(grant.Permissions),
			ContainsRealCustomerData:     false,
			RealProviderAPIAllowed:       false,
			RealERPWriteAllowed:          false,
			RealCustomerDataExportStatus: AccountantAccessClosedUntilExportLiveModule,
		})
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].FirmTenantID < result[j].FirmTenantID
	})
	return result
}

func (r *AccountantPortalAccessRuntime) RevokeFirmAccess(req FirmContextRequest) (FirmAccessGrant, error) {
	if err := r.validateBase(req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM); err != nil {
		return FirmAccessGrant{}, err
	}
	key := grantKey(req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM)
	grant, ok := r.grants[key]
	if !ok {
		return FirmAccessGrant{}, errors.New("firm access grant not found")
	}
	grant.Status = AccountantAccessStatusRevokedDryRunOnly
	grant.RevokedAt = r.now().UTC()
	r.grants[key] = grant
	r.appendAudit("ACCOUNTANT_FIRM_ACCESS_REVOKED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantAccessStatusRevokedDryRunOnly, "")
	return grant, nil
}

func (r *AccountantPortalAccessRuntime) RequestLiveCustomerDataExport(accountantTenantID, firmTenantID, userID, period string) error {
	r.appendAudit("ACCOUNTANT_LIVE_CUSTOMER_DATA_EXPORT_BLOCKED", accountantTenantID, firmTenantID, userID, period, AccountantAccessStatusDenied, AccountantAccessNoRealCustomerDataPolicy)
	return ErrAccountantAccessLiveOperationClosed
}

func (r *AccountantPortalAccessRuntime) RequestRealProviderOperation(accountantTenantID, firmTenantID, userID, providerCode string) error {
	_ = providerCode
	r.appendAudit("ACCOUNTANT_REAL_PROVIDER_OPERATION_BLOCKED", accountantTenantID, firmTenantID, userID, "", AccountantAccessStatusDenied, AccountantAccessNoProviderOperationPolicy)
	return ErrAccountantAccessLiveOperationClosed
}

func (r *AccountantPortalAccessRuntime) RequestRealERPWrite(accountantTenantID, firmTenantID, userID, period string) error {
	r.appendAudit("ACCOUNTANT_REAL_ERP_WRITE_BLOCKED", accountantTenantID, firmTenantID, userID, period, AccountantAccessStatusDenied, AccountantAccessNoERPWritePolicy)
	return ErrAccountantAccessLiveOperationClosed
}

func (r *AccountantPortalAccessRuntime) AuditEvents() []AccountantAccessAuditEvent {
	out := make([]AccountantAccessAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *AccountantPortalAccessRuntime) Gate() AccountantAccessGate {
	return r.gate
}

func (r *AccountantPortalAccessRuntime) validateBase(accountantTenantID, firmTenantID, userID, period string) error {
	if strings.TrimSpace(accountantTenantID) == "" {
		return errors.New("accountant tenant id is required")
	}
	if strings.TrimSpace(firmTenantID) == "" {
		return errors.New("firm tenant id is required")
	}
	if strings.TrimSpace(userID) == "" {
		return errors.New("user id is required")
	}
	if len(period) != 7 || period[4] != '-' {
		return errors.New("period must use YYYY-MM format")
	}
	return nil
}

func (r *AccountantPortalAccessRuntime) appendAudit(code, accountantTenantID, firmTenantID, userID, period, status, reason string) {
	r.auditEvents = append(r.auditEvents, AccountantAccessAuditEvent{
		EventCode:          code,
		AccountantTenantID: accountantTenantID,
		FirmTenantID:       firmTenantID,
		UserID:             userID,
		PeriodYYYYMM:       period,
		Status:             status,
		Reason:             reason,
		CreatedAt:          r.now().UTC(),
	})
}

func normalizeAccessPermissions(in []string) []string {
	if len(in) == 0 {
		return []string{
			AccountantAccessDefaultPermissionFirmRead,
			AccountantAccessDefaultPermissionReportView,
			AccountantAccessDefaultPermissionExportView,
			AccountantAccessDefaultPermissionBillingView,
		}
	}
	seen := map[string]bool{}
	out := []string{}
	for _, permission := range in {
		permission = strings.ToLower(strings.TrimSpace(permission))
		if permission == "" || seen[permission] {
			continue
		}
		seen[permission] = true
		out = append(out, permission)
	}
	sort.Strings(out)
	return out
}

func hasPermission(permissions []string, required string) bool {
	required = strings.ToLower(strings.TrimSpace(required))
	if required == "" {
		required = AccountantAccessDefaultPermissionFirmRead
	}
	for _, permission := range permissions {
		if permission == required || permission == "*" {
			return true
		}
	}
	return false
}

func cloneStrings(in []string) []string {
	out := make([]string, len(in))
	copy(out, in)
	return out
}

func grantKey(accountantTenantID, firmTenantID, userID, period string) string {
	return accountantTenantID + "|" + firmTenantID + "|" + userID + "|" + period
}
