package integrationcatalog

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strings"
)

type IntegrationCategory string

const (
	CatalogCategoryMarketplace      IntegrationCategory = "MARKETPLACE"
	CatalogCategoryAccountingExport IntegrationCategory = "ACCOUNTING_EXPORT"
	CatalogCategoryPayment          IntegrationCategory = "PAYMENT"
	CatalogCategoryEDocument        IntegrationCategory = "E_DOCUMENT"
	CatalogCategoryLogistics        IntegrationCategory = "LOGISTICS"
	CatalogCategoryCRM              IntegrationCategory = "CRM"
	CatalogCategoryWebhook          IntegrationCategory = "WEBHOOK"
	CatalogCategoryPublicAPI        IntegrationCategory = "PUBLIC_API"
)

type Capability string

const (
	CatalogCapabilityReadProducts   Capability = "READ_PRODUCTS"
	CatalogCapabilityWriteProducts  Capability = "WRITE_PRODUCTS"
	CatalogCapabilityReadOrders     Capability = "READ_ORDERS"
	CatalogCapabilityWriteOrders    Capability = "WRITE_ORDERS"
	CatalogCapabilityReadCustomers  Capability = "READ_CUSTOMERS"
	CatalogCapabilityWriteCustomers Capability = "WRITE_CUSTOMERS"
	CatalogCapabilityWebhookIntake  Capability = "WEBHOOK_INTAKE"
	CatalogCapabilityFileExport     Capability = "FILE_EXPORT"
	CatalogCapabilityAPISync        Capability = "API_SYNC"
	CatalogCapabilityManualImport   Capability = "MANUAL_IMPORT"
)

type AuthMode string

const (
	CatalogAuthModeAPIKey        AuthMode = "API_KEY"
	CatalogAuthModeOAuth2        AuthMode = "OAUTH2"
	CatalogAuthModeBasicAuth     AuthMode = "BASIC_AUTH"
	CatalogAuthModeHMACSignature AuthMode = "HMAC_SIGNATURE"
	CatalogAuthModeFileUpload    AuthMode = "FILE_UPLOAD"
	CatalogAuthModeManual        AuthMode = "MANUAL"
)

type SyncDirection string

const (
	CatalogSyncDirectionInbound       SyncDirection = "INBOUND"
	CatalogSyncDirectionOutbound      SyncDirection = "OUTBOUND"
	CatalogSyncDirectionBidirectional SyncDirection = "BIDIRECTIONAL"
	CatalogSyncDirectionExportOnly    SyncDirection = "EXPORT_ONLY"
	CatalogSyncDirectionImportOnly    SyncDirection = "IMPORT_ONLY"
)

type IntegrationStatus string

const (
	CatalogStatusPlanned            IntegrationStatus = "PLANNED"
	CatalogStatusCatalogOnly        IntegrationStatus = "CATALOG_ONLY"
	CatalogStatusSandboxReady       IntegrationStatus = "SANDBOX_READY"
	CatalogStatusHandoffReadyClosed IntegrationStatus = "HANDOFF_READY_CLOSED"
	CatalogStatusProductionReady    IntegrationStatus = "PRODUCTION_READY"
)

type SetupMode string

const (
	CatalogSetupModeSelfService                    SetupMode = "SELF_SERVICE"
	CatalogSetupModeAdminAssisted                  SetupMode = "ADMIN_ASSISTED"
	CatalogSetupModeProviderSpecificModuleRequired SetupMode = "PROVIDER_SPECIFIC_MODULE_REQUIRED"
	CatalogSetupModeManualConfig                   SetupMode = "MANUAL_CONFIG"
)

type TenantIntegrationStatus string

const (
	CatalogTenantIntegrationInstalled     TenantIntegrationStatus = "INSTALLED"
	CatalogTenantIntegrationDisabled      TenantIntegrationStatus = "DISABLED"
	CatalogTenantIntegrationPendingConfig TenantIntegrationStatus = "PENDING_CONFIG"
	CatalogTenantIntegrationBlocked       TenantIntegrationStatus = "BLOCKED"
)

type ProductionGate string

const (
	CatalogProductionGateClosed ProductionGate = "CLOSED"
	CatalogProductionGateOpen   ProductionGate = "OPEN"
)

type PlanCode string

const (
	CatalogPlanStarter    PlanCode = "STARTER"
	CatalogPlanPro        PlanCode = "PRO"
	CatalogPlanEnterprise PlanCode = "ENTERPRISE"
)

type PricingPlanRequirement struct {
	RequiredPlan        PlanCode `json:"required_plan"`
	RequiredEntitlement string   `json:"required_entitlement"`
}

type IntegrationProvider struct {
	ProviderCode                   string              `json:"provider_code"`
	Name                           string              `json:"name"`
	Category                       IntegrationCategory `json:"category"`
	AuthModes                      []AuthMode          `json:"auth_modes"`
	SyncDirections                 []SyncDirection     `json:"sync_directions"`
	Capabilities                   []Capability        `json:"capabilities"`
	Status                         IntegrationStatus   `json:"status"`
	ModuleCode                     string              `json:"module_code"`
	ProviderSpecificModuleRequired bool                `json:"provider_specific_module_required"`
	TenantScoped                   bool                `json:"tenant_scoped"`
	AuditRequired                  bool                `json:"audit_required"`
	ProductionGate                 ProductionGate      `json:"production_gate"`
	RequiredPlan                   PlanCode            `json:"required_plan"`
	RequiredEntitlement            string              `json:"required_entitlement"`
	ConfigKey                      string              `json:"config_key"`
}

type IntegrationApp struct {
	AppCode             string              `json:"app_code"`
	Title               string              `json:"title"`
	Description         string              `json:"description"`
	Category            IntegrationCategory `json:"category"`
	ProviderCode        string              `json:"provider_code"`
	ModuleCode          string              `json:"module_code"`
	Status              IntegrationStatus   `json:"status"`
	RequiredPlan        PlanCode            `json:"required_plan"`
	RequiredEntitlement string              `json:"required_entitlement"`
	SetupMode           SetupMode           `json:"setup_mode"`
	Capabilities        []Capability        `json:"capabilities"`
}

type EntitlementRequirement struct {
	AppCode      string   `json:"app_code"`
	FeatureCode  string   `json:"feature_code"`
	RequiredPlan PlanCode `json:"required_plan"`
}

type TenantIntegrationInstall struct {
	TenantID     string                  `json:"tenant_id"`
	ProviderCode string                  `json:"provider_code"`
	AppCode      string                  `json:"app_code"`
	Status       TenantIntegrationStatus `json:"status"`
	InstallKey   string                  `json:"install_key"`
}

type Catalog struct {
	Version                        string                   `json:"version"`
	Phase                          string                   `json:"phase"`
	RealConnectorRuntimeEnabled    bool                     `json:"real_connector_runtime_enabled"`
	RealProviderConnectionsEnabled bool                     `json:"real_provider_connections_enabled"`
	RealPaymentLiveStatus          string                   `json:"real_payment_live_status"`
	ProductionProviderHandoffGate  string                   `json:"production_provider_handoff_gate"`
	ProviderSpecificModuleRequired bool                     `json:"provider_specific_module_required"`
	Categories                     []IntegrationCategory    `json:"categories"`
	Capabilities                   []Capability             `json:"capabilities"`
	AuthModes                      []AuthMode               `json:"auth_modes"`
	SyncDirections                 []SyncDirection          `json:"sync_directions"`
	Providers                      []IntegrationProvider    `json:"providers"`
	Apps                           []IntegrationApp         `json:"apps"`
	EntitlementRequirements        []EntitlementRequirement `json:"entitlement_requirements"`
}

func DefaultCatalog() Catalog {
	return Catalog{
		Version:                        "marketplace_integration_catalog.v1",
		Phase:                          "FAZ_7_8_FIX_V2",
		RealConnectorRuntimeEnabled:    false,
		RealProviderConnectionsEnabled: false,
		RealPaymentLiveStatus:          "CLOSED",
		ProductionProviderHandoffGate:  "READY_FOR_PROVIDER_SPECIFIC_MODULE",
		ProviderSpecificModuleRequired: true,
		Categories:                     SupportedCategories(),
		Capabilities:                   SupportedCapabilities(),
		AuthModes:                      SupportedAuthModes(),
		SyncDirections:                 SupportedSyncDirections(),
		Providers: []IntegrationProvider{
			provider("TRENDYOL", "Trendyol Marketplace", CatalogCategoryMarketplace, []AuthMode{CatalogAuthModeAPIKey, CatalogAuthModeHMACSignature}, []SyncDirection{CatalogSyncDirectionInbound, CatalogSyncDirectionOutbound, CatalogSyncDirectionBidirectional}, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityWriteProducts, CatalogCapabilityReadOrders, CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}, CatalogStatusPlanned, "marketplace_trendyol", true, CatalogPlanPro, "marketplace.trendyol"),
			provider("HEPSIBURADA", "Hepsiburada Marketplace", CatalogCategoryMarketplace, []AuthMode{CatalogAuthModeAPIKey, CatalogAuthModeHMACSignature}, []SyncDirection{CatalogSyncDirectionInbound, CatalogSyncDirectionOutbound, CatalogSyncDirectionBidirectional}, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityWriteProducts, CatalogCapabilityReadOrders, CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}, CatalogStatusPlanned, "marketplace_hepsiburada", true, CatalogPlanPro, "marketplace.hepsiburada"),
			provider("N11", "N11 Marketplace", CatalogCategoryMarketplace, []AuthMode{CatalogAuthModeAPIKey}, []SyncDirection{CatalogSyncDirectionInbound, CatalogSyncDirectionOutbound, CatalogSyncDirectionBidirectional}, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityWriteProducts, CatalogCapabilityReadOrders, CatalogCapabilityAPISync}, CatalogStatusPlanned, "marketplace_n11", true, CatalogPlanPro, "marketplace.n11"),
			provider("PARASUT", "Paraşüt Accounting", CatalogCategoryAccountingExport, []AuthMode{CatalogAuthModeOAuth2}, []SyncDirection{CatalogSyncDirectionExportOnly, CatalogSyncDirectionOutbound}, []Capability{CatalogCapabilityFileExport, CatalogCapabilityAPISync}, CatalogStatusPlanned, "accounting_parasut", true, CatalogPlanPro, "accounting.parasut"),
			provider("LOGO_EXPORT", "Logo Export", CatalogCategoryAccountingExport, []AuthMode{CatalogAuthModeFileUpload, CatalogAuthModeManual}, []SyncDirection{CatalogSyncDirectionExportOnly}, []Capability{CatalogCapabilityFileExport, CatalogCapabilityManualImport}, CatalogStatusCatalogOnly, "accounting_logo_export", false, CatalogPlanStarter, "accounting.logo_export"),
			provider("MIKRO_EXPORT", "Mikro Export", CatalogCategoryAccountingExport, []AuthMode{CatalogAuthModeFileUpload, CatalogAuthModeManual}, []SyncDirection{CatalogSyncDirectionExportOnly}, []Capability{CatalogCapabilityFileExport, CatalogCapabilityManualImport}, CatalogStatusCatalogOnly, "accounting_mikro_export", false, CatalogPlanStarter, "accounting.mikro_export"),
			provider("PAYMENT_PROVIDER_HANDOFF", "Payment Provider Production Handoff", CatalogCategoryPayment, []AuthMode{CatalogAuthModeHMACSignature, CatalogAuthModeAPIKey}, []SyncDirection{CatalogSyncDirectionBidirectional}, []Capability{CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}, CatalogStatusHandoffReadyClosed, "payment_provider_adapter", true, CatalogPlanPro, "payment.provider_adapter"),
			provider("E_FATURA_PROVIDER", "e-Fatura Provider", CatalogCategoryEDocument, []AuthMode{CatalogAuthModeAPIKey, CatalogAuthModeHMACSignature}, []SyncDirection{CatalogSyncDirectionBidirectional, CatalogSyncDirectionOutbound}, []Capability{CatalogCapabilityAPISync, CatalogCapabilityWebhookIntake, CatalogCapabilityFileExport}, CatalogStatusPlanned, "edocument_e_fatura", true, CatalogPlanPro, "edocument.e_fatura"),
			provider("LOGISTICS_PROVIDER", "Logistics Provider", CatalogCategoryLogistics, []AuthMode{CatalogAuthModeAPIKey}, []SyncDirection{CatalogSyncDirectionBidirectional}, []Capability{CatalogCapabilityReadOrders, CatalogCapabilityWriteOrders, CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}, CatalogStatusPlanned, "logistics_provider", true, CatalogPlanPro, "integration.logistics"),
			provider("PUBLIC_API", "Public API Platform", CatalogCategoryPublicAPI, []AuthMode{CatalogAuthModeAPIKey, CatalogAuthModeOAuth2, CatalogAuthModeHMACSignature}, []SyncDirection{CatalogSyncDirectionInbound, CatalogSyncDirectionOutbound, CatalogSyncDirectionBidirectional}, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityReadOrders, CatalogCapabilityReadCustomers, CatalogCapabilityAPISync, CatalogCapabilityWebhookIntake}, CatalogStatusPlanned, "public_api_platform", false, CatalogPlanEnterprise, "integration.public_api"),
		},
		Apps: []IntegrationApp{
			app("app_marketplace_trendyol", "Trendyol Marketplace", "Trendyol ürün, sipariş ve webhook katalog hazırlığı.", CatalogCategoryMarketplace, "TRENDYOL", "marketplace_trendyol", CatalogStatusPlanned, CatalogPlanPro, "marketplace.trendyol", CatalogSetupModeProviderSpecificModuleRequired, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityWriteProducts, CatalogCapabilityReadOrders, CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}),
			app("app_marketplace_hepsiburada", "Hepsiburada Marketplace", "Hepsiburada ürün, sipariş ve webhook katalog hazırlığı.", CatalogCategoryMarketplace, "HEPSIBURADA", "marketplace_hepsiburada", CatalogStatusPlanned, CatalogPlanPro, "marketplace.hepsiburada", CatalogSetupModeProviderSpecificModuleRequired, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityWriteProducts, CatalogCapabilityReadOrders, CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}),
			app("app_accounting_logo_export", "Logo Export", "Logo muhasebe export katalog hazırlığı.", CatalogCategoryAccountingExport, "LOGO_EXPORT", "accounting_logo_export", CatalogStatusCatalogOnly, CatalogPlanStarter, "accounting.logo_export", CatalogSetupModeManualConfig, []Capability{CatalogCapabilityFileExport, CatalogCapabilityManualImport}),
			app("app_payment_provider_handoff", "Payment Provider Production Handoff", "Ödeme sağlayıcı production handoff katalog hazırlığı. Gerçek ödeme kapalıdır.", CatalogCategoryPayment, "PAYMENT_PROVIDER_HANDOFF", "payment_provider_adapter", CatalogStatusHandoffReadyClosed, CatalogPlanPro, "payment.provider_adapter", CatalogSetupModeProviderSpecificModuleRequired, []Capability{CatalogCapabilityWebhookIntake, CatalogCapabilityAPISync}),
			app("app_public_api_platform", "Public API Platform", "Harici geliştirici ve kurumsal API erişimi için katalog hazırlığı.", CatalogCategoryPublicAPI, "PUBLIC_API", "public_api_platform", CatalogStatusPlanned, CatalogPlanEnterprise, "integration.public_api", CatalogSetupModeAdminAssisted, []Capability{CatalogCapabilityReadProducts, CatalogCapabilityReadOrders, CatalogCapabilityReadCustomers, CatalogCapabilityAPISync, CatalogCapabilityWebhookIntake}),
		},
		EntitlementRequirements: []EntitlementRequirement{
			{AppCode: "app_marketplace_trendyol", FeatureCode: "marketplace.trendyol", RequiredPlan: CatalogPlanPro},
			{AppCode: "app_marketplace_hepsiburada", FeatureCode: "marketplace.hepsiburada", RequiredPlan: CatalogPlanPro},
			{AppCode: "app_accounting_logo_export", FeatureCode: "accounting.logo_export", RequiredPlan: CatalogPlanStarter},
			{AppCode: "app_payment_provider_handoff", FeatureCode: "payment.provider_adapter", RequiredPlan: CatalogPlanPro},
			{AppCode: "app_public_api_platform", FeatureCode: "integration.public_api", RequiredPlan: CatalogPlanEnterprise},
		},
	}
}

func provider(code string, name string, category IntegrationCategory, authModes []AuthMode, syncDirections []SyncDirection, capabilities []Capability, status IntegrationStatus, moduleCode string, providerSpecificModuleRequired bool, requiredPlan PlanCode, requiredEntitlement string) IntegrationProvider {
	return IntegrationProvider{
		ProviderCode:                   code,
		Name:                           name,
		Category:                       category,
		AuthModes:                      append([]AuthMode{}, authModes...),
		SyncDirections:                 append([]SyncDirection{}, syncDirections...),
		Capabilities:                   append([]Capability{}, capabilities...),
		Status:                         status,
		ModuleCode:                     moduleCode,
		ProviderSpecificModuleRequired: providerSpecificModuleRequired,
		TenantScoped:                   true,
		AuditRequired:                  true,
		ProductionGate:                 CatalogProductionGateClosed,
		RequiredPlan:                   requiredPlan,
		RequiredEntitlement:            requiredEntitlement,
		ConfigKey:                      "integrations." + strings.ToLower(strings.ReplaceAll(code, "_", ".")),
	}
}

func app(code string, title string, description string, category IntegrationCategory, providerCode string, moduleCode string, status IntegrationStatus, requiredPlan PlanCode, requiredEntitlement string, setupMode SetupMode, capabilities []Capability) IntegrationApp {
	return IntegrationApp{
		AppCode:             code,
		Title:               title,
		Description:         description,
		Category:            category,
		ProviderCode:        providerCode,
		ModuleCode:          moduleCode,
		Status:              status,
		RequiredPlan:        requiredPlan,
		RequiredEntitlement: requiredEntitlement,
		SetupMode:           setupMode,
		Capabilities:        append([]Capability{}, capabilities...),
	}
}

func SupportedCategories() []IntegrationCategory {
	return []IntegrationCategory{
		CatalogCategoryMarketplace,
		CatalogCategoryAccountingExport,
		CatalogCategoryPayment,
		CatalogCategoryEDocument,
		CatalogCategoryLogistics,
		CatalogCategoryCRM,
		CatalogCategoryWebhook,
		CatalogCategoryPublicAPI,
	}
}

func SupportedCapabilities() []Capability {
	return []Capability{
		CatalogCapabilityReadProducts,
		CatalogCapabilityWriteProducts,
		CatalogCapabilityReadOrders,
		CatalogCapabilityWriteOrders,
		CatalogCapabilityReadCustomers,
		CatalogCapabilityWriteCustomers,
		CatalogCapabilityWebhookIntake,
		CatalogCapabilityFileExport,
		CatalogCapabilityAPISync,
		CatalogCapabilityManualImport,
	}
}

func SupportedAuthModes() []AuthMode {
	return []AuthMode{
		CatalogAuthModeAPIKey,
		CatalogAuthModeOAuth2,
		CatalogAuthModeBasicAuth,
		CatalogAuthModeHMACSignature,
		CatalogAuthModeFileUpload,
		CatalogAuthModeManual,
	}
}

func SupportedSyncDirections() []SyncDirection {
	return []SyncDirection{
		CatalogSyncDirectionInbound,
		CatalogSyncDirectionOutbound,
		CatalogSyncDirectionBidirectional,
		CatalogSyncDirectionExportOnly,
		CatalogSyncDirectionImportOnly,
	}
}

func LoadFromJSON(data []byte) (Catalog, error) {
	var c Catalog
	if err := json.Unmarshal(data, &c); err != nil {
		return Catalog{}, err
	}
	if err := ValidateCatalog(c); err != nil {
		return Catalog{}, err
	}
	return c, nil
}

func ValidateCatalog(c Catalog) error {
	if strings.TrimSpace(c.Version) == "" {
		return errors.New("catalog version is required")
	}
	if strings.TrimSpace(c.Phase) == "" {
		return errors.New("catalog phase is required")
	}
	if c.RealConnectorRuntimeEnabled {
		return errors.New("real connector runtime must remain disabled in FAZ 7-8")
	}
	if c.RealProviderConnectionsEnabled {
		return errors.New("real provider connections must remain disabled in FAZ 7-8")
	}
	if c.RealPaymentLiveStatus != "CLOSED" {
		return errors.New("real payment live status must remain CLOSED")
	}
	if !c.ProviderSpecificModuleRequired {
		return errors.New("provider specific module rule is required")
	}
	if len(c.Providers) == 0 {
		return errors.New("providers are required")
	}
	if len(c.Apps) == 0 {
		return errors.New("integration apps are required")
	}

	providerCodes := map[string]IntegrationProvider{}
	for i, p := range c.Providers {
		if err := validateProvider(p); err != nil {
			return fmt.Errorf("provider[%d] %s: %w", i, p.ProviderCode, err)
		}
		code := normalizeCode(p.ProviderCode)
		if _, exists := providerCodes[code]; exists {
			return fmt.Errorf("duplicate provider_code: %s", p.ProviderCode)
		}
		providerCodes[code] = p
	}

	appCodes := map[string]IntegrationApp{}
	for i, a := range c.Apps {
		if err := validateApp(a, providerCodes); err != nil {
			return fmt.Errorf("app[%d] %s: %w", i, a.AppCode, err)
		}
		code := normalizeCode(a.AppCode)
		if _, exists := appCodes[code]; exists {
			return fmt.Errorf("duplicate app_code: %s", a.AppCode)
		}
		appCodes[code] = a
	}

	for i, e := range c.EntitlementRequirements {
		if strings.TrimSpace(e.AppCode) == "" {
			return fmt.Errorf("entitlement_requirement[%d]: app_code is required", i)
		}
		if _, ok := appCodes[normalizeCode(e.AppCode)]; !ok {
			return fmt.Errorf("entitlement_requirement[%d]: unknown app_code %s", i, e.AppCode)
		}
		if strings.TrimSpace(e.FeatureCode) == "" {
			return fmt.Errorf("entitlement_requirement[%d]: feature_code is required", i)
		}
		if !validPlan(e.RequiredPlan) {
			return fmt.Errorf("entitlement_requirement[%d]: unsupported required_plan %s", i, e.RequiredPlan)
		}
	}

	return nil
}

func validateProvider(p IntegrationProvider) error {
	if strings.TrimSpace(p.ProviderCode) == "" {
		return errors.New("provider_code is required")
	}
	if strings.TrimSpace(p.Name) == "" {
		return errors.New("name is required")
	}
	if !validCategory(p.Category) {
		return fmt.Errorf("unsupported category: %s", p.Category)
	}
	if !validStatus(p.Status) {
		return fmt.Errorf("unsupported status: %s", p.Status)
	}
	if strings.TrimSpace(p.ModuleCode) == "" {
		return errors.New("module_code is required")
	}
	if !p.TenantScoped {
		return errors.New("tenant_scoped is required")
	}
	if !p.AuditRequired {
		return errors.New("audit_required is required")
	}
	if p.ProductionGate != CatalogProductionGateClosed && p.ProductionGate != CatalogProductionGateOpen {
		return fmt.Errorf("unsupported production_gate: %s", p.ProductionGate)
	}
	if p.Status != CatalogStatusProductionReady && p.ProductionGate == CatalogProductionGateOpen {
		return errors.New("production_gate cannot be OPEN before PRODUCTION_READY")
	}
	if !validPlan(p.RequiredPlan) {
		return fmt.Errorf("unsupported required_plan: %s", p.RequiredPlan)
	}
	if strings.TrimSpace(p.RequiredEntitlement) == "" {
		return errors.New("required_entitlement is required")
	}
	if strings.TrimSpace(p.ConfigKey) == "" {
		return errors.New("config_key is required")
	}
	if len(p.AuthModes) == 0 {
		return errors.New("auth_modes are required")
	}
	if len(p.SyncDirections) == 0 {
		return errors.New("sync_directions are required")
	}
	if len(p.Capabilities) == 0 {
		return errors.New("capabilities are required")
	}
	for _, m := range p.AuthModes {
		if !validAuthMode(m) {
			return fmt.Errorf("unsupported auth_mode: %s", m)
		}
	}
	for _, d := range p.SyncDirections {
		if !validSyncDirection(d) {
			return fmt.Errorf("unsupported sync_direction: %s", d)
		}
	}
	for _, c := range p.Capabilities {
		if !validCapability(c) {
			return fmt.Errorf("unsupported capability: %s", c)
		}
	}
	return nil
}

func validateApp(a IntegrationApp, providerCodes map[string]IntegrationProvider) error {
	if strings.TrimSpace(a.AppCode) == "" {
		return errors.New("app_code is required")
	}
	if strings.TrimSpace(a.Title) == "" {
		return errors.New("title is required")
	}
	if strings.TrimSpace(a.Description) == "" {
		return errors.New("description is required")
	}
	if !validCategory(a.Category) {
		return fmt.Errorf("unsupported category: %s", a.Category)
	}
	p, ok := providerCodes[normalizeCode(a.ProviderCode)]
	if !ok {
		return fmt.Errorf("unknown provider_code: %s", a.ProviderCode)
	}
	if p.Category != a.Category {
		return fmt.Errorf("provider category mismatch: provider=%s app=%s", p.Category, a.Category)
	}
	if strings.TrimSpace(a.ModuleCode) == "" {
		return errors.New("module_code is required")
	}
	if !validStatus(a.Status) {
		return fmt.Errorf("unsupported status: %s", a.Status)
	}
	if !validPlan(a.RequiredPlan) {
		return fmt.Errorf("unsupported required_plan: %s", a.RequiredPlan)
	}
	if strings.TrimSpace(a.RequiredEntitlement) == "" {
		return errors.New("required_entitlement is required")
	}
	if !validSetupMode(a.SetupMode) {
		return fmt.Errorf("unsupported setup_mode: %s", a.SetupMode)
	}
	if len(a.Capabilities) == 0 {
		return errors.New("capabilities are required")
	}
	for _, c := range a.Capabilities {
		if !validCapability(c) {
			return fmt.Errorf("unsupported capability: %s", c)
		}
		if !providerHasCapability(p, c) {
			return fmt.Errorf("app capability %s is not supported by provider %s", c, p.ProviderCode)
		}
	}
	return nil
}

func (c Catalog) FindProvider(providerCode string) (IntegrationProvider, bool) {
	needle := normalizeCode(providerCode)
	for _, p := range c.Providers {
		if normalizeCode(p.ProviderCode) == needle {
			return p, true
		}
	}
	return IntegrationProvider{}, false
}

func (c Catalog) FindApp(appCode string) (IntegrationApp, bool) {
	needle := normalizeCode(appCode)
	for _, a := range c.Apps {
		if normalizeCode(a.AppCode) == needle {
			return a, true
		}
	}
	return IntegrationApp{}, false
}

func (c Catalog) ListAppsByCategory(category IntegrationCategory) []IntegrationApp {
	out := make([]IntegrationApp, 0)
	for _, a := range c.Apps {
		if a.Category == category {
			out = append(out, a)
		}
	}
	return out
}

func (c Catalog) ProviderSupportsCapability(providerCode string, capability Capability) bool {
	p, ok := c.FindProvider(providerCode)
	if !ok {
		return false
	}
	return providerHasCapability(p, capability)
}

func (c Catalog) AppSupportsCapability(appCode string, capability Capability) bool {
	a, ok := c.FindApp(appCode)
	if !ok {
		return false
	}
	for _, c := range a.Capabilities {
		if c == capability {
			return true
		}
	}
	return false
}

func (c Catalog) EntitlementForApp(appCode string) (EntitlementRequirement, bool) {
	needle := normalizeCode(appCode)
	for _, e := range c.EntitlementRequirements {
		if normalizeCode(e.AppCode) == needle {
			return e, true
		}
	}
	return EntitlementRequirement{}, false
}

func (c Catalog) IsAppAllowedByPlanAndEntitlements(appCode string, currentPlan PlanCode, enabledFeatures []string) bool {
	app, ok := c.FindApp(appCode)
	if !ok {
		return false
	}
	if !PlanAllows(currentPlan, app.RequiredPlan) {
		return false
	}
	return hasFeature(enabledFeatures, app.RequiredEntitlement)
}

func (c Catalog) PrepareTenantInstall(tenantID string, appCode string, currentPlan PlanCode, enabledFeatures []string) (TenantIntegrationInstall, error) {
	if !safeIdentifier(tenantID) {
		return TenantIntegrationInstall{}, errors.New("tenant_id is not safe")
	}
	app, ok := c.FindApp(appCode)
	if !ok {
		return TenantIntegrationInstall{}, fmt.Errorf("unknown app_code: %s", appCode)
	}
	if !c.IsAppAllowedByPlanAndEntitlements(appCode, currentPlan, enabledFeatures) {
		return TenantIntegrationInstall{
			TenantID:     tenantID,
			ProviderCode: app.ProviderCode,
			AppCode:      app.AppCode,
			Status:       CatalogTenantIntegrationBlocked,
			InstallKey:   BuildTenantInstallKey(tenantID, app.ProviderCode, app.AppCode),
		}, nil
	}
	return TenantIntegrationInstall{
		TenantID:     tenantID,
		ProviderCode: app.ProviderCode,
		AppCode:      app.AppCode,
		Status:       CatalogTenantIntegrationPendingConfig,
		InstallKey:   BuildTenantInstallKey(tenantID, app.ProviderCode, app.AppCode),
	}, nil
}

func BuildTenantInstallKey(tenantID string, providerCode string, appCode string) string {
	return fmt.Sprintf("tenant:%s|provider:%s|app:%s", normalizeInstallPart(tenantID), normalizeInstallPart(providerCode), normalizeInstallPart(appCode))
}

func ValidateTenantInstall(install TenantIntegrationInstall) error {
	if !safeIdentifier(install.TenantID) {
		return errors.New("tenant_id is not safe")
	}
	if strings.TrimSpace(install.ProviderCode) == "" {
		return errors.New("provider_code is required")
	}
	if strings.TrimSpace(install.AppCode) == "" {
		return errors.New("app_code is required")
	}
	if !validTenantIntegrationStatus(install.Status) {
		return fmt.Errorf("unsupported tenant integration status: %s", install.Status)
	}
	expectedKey := BuildTenantInstallKey(install.TenantID, install.ProviderCode, install.AppCode)
	if install.InstallKey != expectedKey {
		return fmt.Errorf("install_key mismatch: expected %s got %s", expectedKey, install.InstallKey)
	}
	return nil
}

func PlanAllows(current PlanCode, required PlanCode) bool {
	return planRank(current) >= planRank(required)
}

func CapabilityMatrix() map[Capability]string {
	return map[Capability]string{
		CatalogCapabilityReadProducts:   "Read product catalog from provider",
		CatalogCapabilityWriteProducts:  "Write product catalog to provider",
		CatalogCapabilityReadOrders:     "Read orders from provider",
		CatalogCapabilityWriteOrders:    "Write order updates to provider",
		CatalogCapabilityReadCustomers:  "Read customer data from provider",
		CatalogCapabilityWriteCustomers: "Write customer data to provider",
		CatalogCapabilityWebhookIntake:  "Receive provider webhook events",
		CatalogCapabilityFileExport:     "Export provider-compatible files",
		CatalogCapabilityAPISync:        "Use API based sync",
		CatalogCapabilityManualImport:   "Support manual import/export operations",
	}
}

func SortedCapabilityCodes() []string {
	codes := make([]string, 0, len(SupportedCapabilities()))
	for _, c := range SupportedCapabilities() {
		codes = append(codes, string(c))
	}
	sort.Strings(codes)
	return codes
}

func providerHasCapability(p IntegrationProvider, capability Capability) bool {
	for _, c := range p.Capabilities {
		if c == capability {
			return true
		}
	}
	return false
}

func hasFeature(features []string, required string) bool {
	for _, f := range features {
		if strings.EqualFold(strings.TrimSpace(f), strings.TrimSpace(required)) {
			return true
		}
	}
	return false
}

func normalizeCode(v string) string {
	return strings.ToUpper(strings.TrimSpace(v))
}

func normalizeInstallPart(v string) string {
	return strings.ToLower(strings.TrimSpace(v))
}

var safeIDPattern = regexp.MustCompile(`^[a-zA-Z0-9_.:-]+$`)

func safeIdentifier(v string) bool {
	v = strings.TrimSpace(v)
	return v != "" && safeIDPattern.MatchString(v)
}

func planRank(plan PlanCode) int {
	switch plan {
	case CatalogPlanStarter:
		return 1
	case CatalogPlanPro:
		return 2
	case CatalogPlanEnterprise:
		return 3
	default:
		return 0
	}
}

func validCategory(v IntegrationCategory) bool {
	switch v {
	case CatalogCategoryMarketplace, CatalogCategoryAccountingExport, CatalogCategoryPayment, CatalogCategoryEDocument, CatalogCategoryLogistics, CatalogCategoryCRM, CatalogCategoryWebhook, CatalogCategoryPublicAPI:
		return true
	default:
		return false
	}
}

func validCapability(v Capability) bool {
	switch v {
	case CatalogCapabilityReadProducts, CatalogCapabilityWriteProducts, CatalogCapabilityReadOrders, CatalogCapabilityWriteOrders, CatalogCapabilityReadCustomers, CatalogCapabilityWriteCustomers, CatalogCapabilityWebhookIntake, CatalogCapabilityFileExport, CatalogCapabilityAPISync, CatalogCapabilityManualImport:
		return true
	default:
		return false
	}
}

func validAuthMode(v AuthMode) bool {
	switch v {
	case CatalogAuthModeAPIKey, CatalogAuthModeOAuth2, CatalogAuthModeBasicAuth, CatalogAuthModeHMACSignature, CatalogAuthModeFileUpload, CatalogAuthModeManual:
		return true
	default:
		return false
	}
}

func validSyncDirection(v SyncDirection) bool {
	switch v {
	case CatalogSyncDirectionInbound, CatalogSyncDirectionOutbound, CatalogSyncDirectionBidirectional, CatalogSyncDirectionExportOnly, CatalogSyncDirectionImportOnly:
		return true
	default:
		return false
	}
}

func validStatus(v IntegrationStatus) bool {
	switch v {
	case CatalogStatusPlanned, CatalogStatusCatalogOnly, CatalogStatusSandboxReady, CatalogStatusHandoffReadyClosed, CatalogStatusProductionReady:
		return true
	default:
		return false
	}
}

func validSetupMode(v SetupMode) bool {
	switch v {
	case CatalogSetupModeSelfService, CatalogSetupModeAdminAssisted, CatalogSetupModeProviderSpecificModuleRequired, CatalogSetupModeManualConfig:
		return true
	default:
		return false
	}
}

func validTenantIntegrationStatus(v TenantIntegrationStatus) bool {
	switch v {
	case CatalogTenantIntegrationInstalled, CatalogTenantIntegrationDisabled, CatalogTenantIntegrationPendingConfig, CatalogTenantIntegrationBlocked:
		return true
	default:
		return false
	}
}

func validPlan(v PlanCode) bool {
	switch v {
	case CatalogPlanStarter, CatalogPlanPro, CatalogPlanEnterprise:
		return true
	default:
		return false
	}
}
