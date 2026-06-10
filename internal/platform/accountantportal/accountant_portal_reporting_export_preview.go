package accountantportal

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	AccountantReportingModuleCode = "FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW"

	AccountantReportingModePreviewDryRunOnly = "REPORTING_EXPORT_PREVIEW_DRY_RUN_ONLY"

	AccountantReportingStatusReadyDryRunOnly       = "READY_DRY_RUN_ONLY"
	AccountantReportingStatusPreviewBuilt          = "PREVIEW_BUILT_DRY_RUN_ONLY"
	AccountantReportingStatusExportPackagePreview  = "EXPORT_PACKAGE_PREVIEW_DRY_RUN_ONLY"
	AccountantReportingStatusDenied                = "DENIED"
	AccountantReportingNoRealCustomerDataPolicy    = "NO_REAL_CUSTOMER_DATA_IN_REPORT_PREVIEW"
	AccountantReportingNoRealExportPolicy          = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_THIS_PHASE"
	AccountantReportingNoProviderAPIPolicy         = "NO_REAL_PROVIDER_API_OPERATION_IN_THIS_PHASE"
	AccountantReportingNoFileDeliveryPolicy        = "NO_REAL_FILE_DELIVERY_IN_THIS_PHASE"
	AccountantReportingNoERPWritePolicy            = "NO_REAL_ERP_WRITE_IN_THIS_PHASE"
	AccountantReportingPermissionReportView        = "report.view"
	AccountantReportingPermissionExportPreview     = "export.preview"
	AccountantReportingReportTypeFirmSummary       = "FIRM_SUMMARY"
	AccountantReportingReportTypeTaxSummary        = "TAX_SUMMARY"
	AccountantReportingReportTypeIntegrationStatus = "INTEGRATION_STATUS"

	AccountantReportingClosedUntilBillingLiveModule    = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	AccountantReportingClosedUntilProviderLiveModule   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	AccountantReportingClosedUntilSyncWorkerLiveModule = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	AccountantReportingClosedUntilExportLiveModule     = "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
)

var ErrAccountantReportingLiveOperationClosed = errors.New("accountant portal reporting/export live operation is closed in FAZ 7-11")

type AccountantReportingGate struct {
	RealAccountantBillingStatus      string `json:"real_accountant_billing_status"`
	RealPaymentCaptureStatus         string `json:"real_payment_capture_status"`
	RealProviderAPIStatus            string `json:"real_provider_api_status"`
	RealERPWriteStatus               string `json:"real_erp_write_status"`
	RealCustomerDataExportLiveStatus string `json:"real_customer_data_export_live_status"`
	RealFileDeliveryStatus           string `json:"real_file_delivery_status"`
	RealOperatorProviderActionStatus string `json:"real_operator_provider_action_status"`
	ReportingPreviewRuntimeStatus    string `json:"reporting_preview_runtime_status"`
}

func DefaultAccountantReportingGate() AccountantReportingGate {
	return AccountantReportingGate{
		RealAccountantBillingStatus:      AccountantReportingClosedUntilBillingLiveModule,
		RealPaymentCaptureStatus:         AccountantReportingClosedUntilBillingLiveModule,
		RealProviderAPIStatus:            AccountantReportingClosedUntilProviderLiveModule,
		RealERPWriteStatus:               AccountantReportingClosedUntilSyncWorkerLiveModule,
		RealCustomerDataExportLiveStatus: AccountantReportingClosedUntilExportLiveModule,
		RealFileDeliveryStatus:           AccountantReportingClosedUntilProviderLiveModule,
		RealOperatorProviderActionStatus: AccountantReportingClosedUntilProviderLiveModule,
		ReportingPreviewRuntimeStatus:    AccountantReportingStatusReadyDryRunOnly,
	}
}

func (g AccountantReportingGate) AssertLiveOperationsClosed() error {
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

type AccountantReportPreviewRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	UserID             string
	PeriodYYYYMM       string
	ReportType         string
	RequiredPermission string
}

type AccountantReportPreviewRow struct {
	MetricCode        string `json:"metric_code"`
	Label             string `json:"label"`
	Value             string `json:"value"`
	SyntheticPreview  bool   `json:"synthetic_preview"`
	ContainsRealData  bool   `json:"contains_real_data"`
	SourceDescription string `json:"source_description"`
}

type AccountantReportPreview struct {
	PreviewID                     string                       `json:"preview_id"`
	ModuleCode                    string                       `json:"module_code"`
	Mode                          string                       `json:"mode"`
	AccountantTenantID            string                       `json:"accountant_tenant_id"`
	FirmTenantID                  string                       `json:"firm_tenant_id"`
	UserID                        string                       `json:"user_id"`
	PeriodYYYYMM                  string                       `json:"period_yyyy_mm"`
	ReportType                    string                       `json:"report_type"`
	Status                        string                       `json:"status"`
	Rows                          []AccountantReportPreviewRow `json:"rows"`
	ContainsRealCustomerData      bool                         `json:"contains_real_customer_data"`
	RealCustomerDataExportAllowed bool                         `json:"real_customer_data_export_allowed"`
	RealProviderAPIAllowed        bool                         `json:"real_provider_api_allowed"`
	RealERPWriteAllowed           bool                         `json:"real_erp_write_allowed"`
	RealFileDeliveryAllowed       bool                         `json:"real_file_delivery_allowed"`
	LiveOperationPolicy           string                       `json:"live_operation_policy"`
	CreatedAt                     time.Time                    `json:"created_at"`
}

type AccountantExportPackagePreviewRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	UserID             string
	PeriodYYYYMM       string
	ProviderCode       string
	Format             string
}

type AccountantExportManifestItem struct {
	FileName            string `json:"file_name"`
	FileKind            string `json:"file_kind"`
	SyntheticPreview    bool   `json:"synthetic_preview"`
	ContainsRealData    bool   `json:"contains_real_data"`
	DeliveryStatus      string `json:"delivery_status"`
	ProviderAPIStatus   string `json:"provider_api_status"`
	ERPWriteStatus      string `json:"erp_write_status"`
	CustomerDataPolicy  string `json:"customer_data_policy"`
	GeneratedPreviewRef string `json:"generated_preview_ref"`
}

type AccountantExportPackagePreview struct {
	PackageID                string                         `json:"package_id"`
	ModuleCode               string                         `json:"module_code"`
	Mode                     string                         `json:"mode"`
	AccountantTenantID       string                         `json:"accountant_tenant_id"`
	FirmTenantID             string                         `json:"firm_tenant_id"`
	UserID                   string                         `json:"user_id"`
	PeriodYYYYMM             string                         `json:"period_yyyy_mm"`
	ProviderCode             string                         `json:"provider_code"`
	Format                   string                         `json:"format"`
	Status                   string                         `json:"status"`
	Manifest                 []AccountantExportManifestItem `json:"manifest"`
	ContainsRealCustomerData bool                           `json:"contains_real_customer_data"`
	LiveDeliveryRequested    bool                           `json:"live_delivery_requested"`
	RealProviderAPIRequested bool                           `json:"real_provider_api_requested"`
	RealERPWriteRequested    bool                           `json:"real_erp_write_requested"`
	RealFileDeliveryAllowed  bool                           `json:"real_file_delivery_allowed"`
	LiveOperationPolicy      string                         `json:"live_operation_policy"`
	CreatedAt                time.Time                      `json:"created_at"`
}

type AccountantReportingAuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	UserID             string    `json:"user_id,omitempty"`
	PeriodYYYYMM       string    `json:"period_yyyy_mm,omitempty"`
	Status             string    `json:"status"`
	Reason             string    `json:"reason,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

type AccountantPortalReportingRuntime struct {
	accessRuntime *AccountantPortalAccessRuntime
	gate          AccountantReportingGate
	auditEvents   []AccountantReportingAuditEvent
	now           func() time.Time
}

func NewDefaultAccountantPortalReportingRuntime(accessRuntime *AccountantPortalAccessRuntime) *AccountantPortalReportingRuntime {
	if accessRuntime == nil {
		accessRuntime = NewDefaultAccountantPortalAccessRuntime()
	}
	return &AccountantPortalReportingRuntime{
		accessRuntime: accessRuntime,
		gate:          DefaultAccountantReportingGate(),
		auditEvents:   []AccountantReportingAuditEvent{},
		now:           time.Now,
	}
}

func (r *AccountantPortalReportingRuntime) BuildReportPreview(req AccountantReportPreviewRequest) (AccountantReportPreview, error) {
	if req.RequiredPermission == "" {
		req.RequiredPermission = AccountantReportingPermissionReportView
	}
	if req.ReportType == "" {
		req.ReportType = AccountantReportingReportTypeFirmSummary
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		r.appendAudit("ACCOUNTANT_REPORT_PREVIEW_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusDenied, err.Error())
		return AccountantReportPreview{}, err
	}
	decision := r.accessRuntime.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: req.AccountantTenantID,
		FirmTenantID:       req.FirmTenantID,
		UserID:             req.UserID,
		PeriodYYYYMM:       req.PeriodYYYYMM,
		Permission:         req.RequiredPermission,
	})
	if !decision.Allowed {
		r.appendAudit("ACCOUNTANT_REPORT_PREVIEW_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusDenied, decision.DenyReason)
		return AccountantReportPreview{}, errors.New("accountant report preview denied: " + decision.DenyReason)
	}

	reportType := strings.ToUpper(strings.TrimSpace(req.ReportType))
	preview := AccountantReportPreview{
		PreviewID:                     reportingStableID("ACCT-REPORT-PREVIEW", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, reportType),
		ModuleCode:                    AccountantReportingModuleCode,
		Mode:                          AccountantReportingModePreviewDryRunOnly,
		AccountantTenantID:            req.AccountantTenantID,
		FirmTenantID:                  req.FirmTenantID,
		UserID:                        req.UserID,
		PeriodYYYYMM:                  req.PeriodYYYYMM,
		ReportType:                    reportType,
		Status:                        AccountantReportingStatusPreviewBuilt,
		Rows:                          syntheticReportRows(reportType),
		ContainsRealCustomerData:      false,
		RealCustomerDataExportAllowed: false,
		RealProviderAPIAllowed:        false,
		RealERPWriteAllowed:           false,
		RealFileDeliveryAllowed:       false,
		LiveOperationPolicy:           AccountantReportingNoRealCustomerDataPolicy,
		CreatedAt:                     r.now().UTC(),
	}
	r.appendAudit("ACCOUNTANT_REPORT_PREVIEW_BUILT", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusPreviewBuilt, "")
	return preview, nil
}

func (r *AccountantPortalReportingRuntime) BuildExportPackagePreview(req AccountantExportPackagePreviewRequest) (AccountantExportPackagePreview, error) {
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		r.appendAudit("ACCOUNTANT_EXPORT_PACKAGE_PREVIEW_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusDenied, err.Error())
		return AccountantExportPackagePreview{}, err
	}
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	if !isSupportedProvider(provider) {
		reason := "unsupported provider"
		r.appendAudit("ACCOUNTANT_EXPORT_PACKAGE_PREVIEW_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusDenied, reason)
		return AccountantExportPackagePreview{}, errors.New(reason)
	}
	decision := r.accessRuntime.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: req.AccountantTenantID,
		FirmTenantID:       req.FirmTenantID,
		UserID:             req.UserID,
		PeriodYYYYMM:       req.PeriodYYYYMM,
		Permission:         AccountantReportingPermissionExportPreview,
	})
	if !decision.Allowed {
		r.appendAudit("ACCOUNTANT_EXPORT_PACKAGE_PREVIEW_DENIED", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusDenied, decision.DenyReason)
		return AccountantExportPackagePreview{}, errors.New("accountant export package preview denied: " + decision.DenyReason)
	}

	format := strings.ToUpper(strings.TrimSpace(req.Format))
	if format == "" {
		format = provider + "_DRY_RUN_PREVIEW"
	}
	preview := AccountantExportPackagePreview{
		PackageID:                reportingStableID("ACCT-EXPORT-PACKAGE-PREVIEW", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, provider, format),
		ModuleCode:               AccountantReportingModuleCode,
		Mode:                     AccountantReportingModePreviewDryRunOnly,
		AccountantTenantID:       req.AccountantTenantID,
		FirmTenantID:             req.FirmTenantID,
		UserID:                   req.UserID,
		PeriodYYYYMM:             req.PeriodYYYYMM,
		ProviderCode:             provider,
		Format:                   format,
		Status:                   AccountantReportingStatusExportPackagePreview,
		Manifest:                 syntheticExportManifest(provider, format),
		ContainsRealCustomerData: false,
		LiveDeliveryRequested:    false,
		RealProviderAPIRequested: false,
		RealERPWriteRequested:    false,
		RealFileDeliveryAllowed:  false,
		LiveOperationPolicy:      AccountantReportingNoRealExportPolicy,
		CreatedAt:                r.now().UTC(),
	}
	r.appendAudit("ACCOUNTANT_EXPORT_PACKAGE_PREVIEW_BUILT", req.AccountantTenantID, req.FirmTenantID, req.UserID, req.PeriodYYYYMM, AccountantReportingStatusExportPackagePreview, "")
	return preview, nil
}

func (r *AccountantPortalReportingRuntime) RequestLiveCustomerDataExport(accountantTenantID, firmTenantID, userID, period string) error {
	r.appendAudit("ACCOUNTANT_REPORTING_LIVE_CUSTOMER_DATA_EXPORT_BLOCKED", accountantTenantID, firmTenantID, userID, period, AccountantReportingStatusDenied, AccountantReportingNoRealExportPolicy)
	return ErrAccountantReportingLiveOperationClosed
}

func (r *AccountantPortalReportingRuntime) RequestRealProviderExport(accountantTenantID, firmTenantID, userID, providerCode string) error {
	_ = providerCode
	r.appendAudit("ACCOUNTANT_REPORTING_REAL_PROVIDER_EXPORT_BLOCKED", accountantTenantID, firmTenantID, userID, "", AccountantReportingStatusDenied, AccountantReportingNoProviderAPIPolicy)
	return ErrAccountantReportingLiveOperationClosed
}

func (r *AccountantPortalReportingRuntime) RequestRealFileDelivery(accountantTenantID, firmTenantID, userID, period string) error {
	r.appendAudit("ACCOUNTANT_REPORTING_REAL_FILE_DELIVERY_BLOCKED", accountantTenantID, firmTenantID, userID, period, AccountantReportingStatusDenied, AccountantReportingNoFileDeliveryPolicy)
	return ErrAccountantReportingLiveOperationClosed
}

func (r *AccountantPortalReportingRuntime) RequestRealERPWrite(accountantTenantID, firmTenantID, userID, period string) error {
	r.appendAudit("ACCOUNTANT_REPORTING_REAL_ERP_WRITE_BLOCKED", accountantTenantID, firmTenantID, userID, period, AccountantReportingStatusDenied, AccountantReportingNoERPWritePolicy)
	return ErrAccountantReportingLiveOperationClosed
}

func (r *AccountantPortalReportingRuntime) Gate() AccountantReportingGate {
	return r.gate
}

func (r *AccountantPortalReportingRuntime) AuditEvents() []AccountantReportingAuditEvent {
	out := make([]AccountantReportingAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *AccountantPortalReportingRuntime) appendAudit(code, accountantTenantID, firmTenantID, userID, period, status, reason string) {
	r.auditEvents = append(r.auditEvents, AccountantReportingAuditEvent{
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

func syntheticReportRows(reportType string) []AccountantReportPreviewRow {
	rows := []AccountantReportPreviewRow{
		{
			MetricCode:        "preview.period",
			Label:             "Preview Period",
			Value:             "DRY_RUN_ONLY",
			SyntheticPreview:  true,
			ContainsRealData:  false,
			SourceDescription: "synthetic preview row",
		},
		{
			MetricCode:        "preview.real_customer_data",
			Label:             "Real Customer Data",
			Value:             "CLOSED",
			SyntheticPreview:  true,
			ContainsRealData:  false,
			SourceDescription: AccountantReportingNoRealCustomerDataPolicy,
		},
	}
	switch reportType {
	case AccountantReportingReportTypeTaxSummary:
		rows = append(rows, AccountantReportPreviewRow{
			MetricCode:        "tax.summary.preview",
			Label:             "Tax Summary Preview",
			Value:             "SYNTHETIC",
			SyntheticPreview:  true,
			ContainsRealData:  false,
			SourceDescription: "dry-run tax summary placeholder",
		})
	case AccountantReportingReportTypeIntegrationStatus:
		rows = append(rows, AccountantReportPreviewRow{
			MetricCode:        "integration.status.preview",
			Label:             "Integration Status Preview",
			Value:             "PARASUT_LOGO_MIKRO_ZIRVE_DRY_RUN",
			SyntheticPreview:  true,
			ContainsRealData:  false,
			SourceDescription: "sealed dry-run connector family",
		})
	default:
		rows = append(rows, AccountantReportPreviewRow{
			MetricCode:        "firm.summary.preview",
			Label:             "Firm Summary Preview",
			Value:             "SYNTHETIC",
			SyntheticPreview:  true,
			ContainsRealData:  false,
			SourceDescription: "dry-run firm summary placeholder",
		})
	}
	return rows
}

func syntheticExportManifest(provider, format string) []AccountantExportManifestItem {
	provider = strings.ToUpper(strings.TrimSpace(provider))
	format = strings.ToUpper(strings.TrimSpace(format))
	items := []AccountantExportManifestItem{
		{
			FileName:            strings.ToLower(provider) + "_manifest_preview.json",
			FileKind:            "MANIFEST_PREVIEW",
			SyntheticPreview:    true,
			ContainsRealData:    false,
			DeliveryStatus:      AccountantReportingClosedUntilProviderLiveModule,
			ProviderAPIStatus:   AccountantReportingClosedUntilProviderLiveModule,
			ERPWriteStatus:      AccountantReportingClosedUntilSyncWorkerLiveModule,
			CustomerDataPolicy:  AccountantReportingNoRealExportPolicy,
			GeneratedPreviewRef: format,
		},
		{
			FileName:            strings.ToLower(provider) + "_export_preview.txt",
			FileKind:            "EXPORT_FILE_PREVIEW",
			SyntheticPreview:    true,
			ContainsRealData:    false,
			DeliveryStatus:      AccountantReportingClosedUntilProviderLiveModule,
			ProviderAPIStatus:   AccountantReportingClosedUntilProviderLiveModule,
			ERPWriteStatus:      AccountantReportingClosedUntilSyncWorkerLiveModule,
			CustomerDataPolicy:  AccountantReportingNoRealExportPolicy,
			GeneratedPreviewRef: format,
		},
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].FileName < items[j].FileName
	})
	return items
}

func reportingStableID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
