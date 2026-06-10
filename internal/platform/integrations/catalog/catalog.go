package catalog

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

type IntegrationCategory string

const (
	CategoryMarketplace      IntegrationCategory = "MARKETPLACE"
	CategoryAccountingExport IntegrationCategory = "ACCOUNTING_EXPORT"
	CategoryPayment          IntegrationCategory = "PAYMENT"
	CategoryEDocument        IntegrationCategory = "E_DOCUMENT"
	CategoryLogistics        IntegrationCategory = "LOGISTICS"
	CategoryCRM              IntegrationCategory = "CRM"
	CategoryWebhook          IntegrationCategory = "WEBHOOK"
	CategoryPublicAPI        IntegrationCategory = "PUBLIC_API"
)

type IntegrationStatus string

const (
	StatusPlanned            IntegrationStatus = "PLANNED"
	StatusCatalogOnly        IntegrationStatus = "CATALOG_ONLY"
	StatusSandboxReady       IntegrationStatus = "SANDBOX_READY"
	StatusHandoffReadyClosed IntegrationStatus = "HANDOFF_READY_CLOSED"
	StatusProductionReady    IntegrationStatus = "PRODUCTION_READY"
)

type IntegrationMode string

const (
	ModeCatalogOnly                    IntegrationMode = "CATALOG_ONLY"
	ModeProviderSpecificModuleRequired IntegrationMode = "PROVIDER_SPECIFIC_MODULE_REQUIRED"
	ModeSandboxOnly                    IntegrationMode = "SANDBOX_ONLY"
)

type IntegrationDirection string

const (
	DirectionInbound       IntegrationDirection = "INBOUND"
	DirectionOutbound      IntegrationDirection = "OUTBOUND"
	DirectionExportOnly    IntegrationDirection = "EXPORT_ONLY"
	DirectionBidirectional IntegrationDirection = "BIDIRECTIONAL"
)

type ProductionGate string

const (
	ProductionGateClosed ProductionGate = "CLOSED"
	ProductionGateOpen   ProductionGate = "OPEN"
)

type ProviderRiskLevel string

const (
	RiskLow      ProviderRiskLevel = "LOW"
	RiskMedium   ProviderRiskLevel = "MEDIUM"
	RiskHigh     ProviderRiskLevel = "HIGH"
	RiskCritical ProviderRiskLevel = "CRITICAL"
)

type Provider struct {
	Code                 string               `json:"code"`
	Name                 string               `json:"name"`
	Category             IntegrationCategory  `json:"category"`
	Status               IntegrationStatus    `json:"status"`
	Mode                 IntegrationMode      `json:"mode"`
	Direction            IntegrationDirection `json:"direction"`
	TenantScoped         bool                 `json:"tenant_scoped"`
	AuditRequired        bool                 `json:"audit_required"`
	SandboxEnabled       bool                 `json:"sandbox_enabled"`
	WebhookRequired      bool                 `json:"webhook_required"`
	ProductionGate       ProductionGate       `json:"production_gate"`
	RequiredEntitlements []string             `json:"required_entitlements"`
	ConfigKey            string               `json:"config_key"`
	DocumentationPath    string               `json:"documentation_path"`
	RiskLevel            ProviderRiskLevel    `json:"risk_level"`
}

type Catalog struct {
	Version                        string     `json:"version"`
	Phase                          string     `json:"phase"`
	RealProviderConnectionsEnabled bool       `json:"real_provider_connections_enabled"`
	RealPaymentLiveStatus          string     `json:"real_payment_live_status"`
	ProductionProviderHandoffGate  string     `json:"production_provider_handoff_gate"`
	ProviderSpecificModuleRequired bool       `json:"provider_specific_module_required"`
	Providers                      []Provider `json:"providers"`
}

func DefaultCatalog() Catalog {
	return Catalog{
		Version:                        "marketplace_integration_catalog.v1",
		Phase:                          "FAZ_7_8",
		RealProviderConnectionsEnabled: false,
		RealPaymentLiveStatus:          "CLOSED",
		ProductionProviderHandoffGate:  "READY_FOR_PROVIDER_SPECIFIC_MODULE",
		ProviderSpecificModuleRequired: true,
		Providers: []Provider{
			provider("TRENDYOL_MARKETPLACE", "Trendyol Marketplace", CategoryMarketplace, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskHigh, "integration.marketplace", "marketplace.trendyol"),
			provider("HEPSIBURADA_MARKETPLACE", "Hepsiburada Marketplace", CategoryMarketplace, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskHigh, "integration.marketplace", "marketplace.hepsiburada"),
			provider("N11_MARKETPLACE", "N11 Marketplace", CategoryMarketplace, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskHigh, "integration.marketplace", "marketplace.n11"),
			provider("PARASUT_ACCOUNTING", "Paraşüt Accounting", CategoryAccountingExport, ModeProviderSpecificModuleRequired, DirectionExportOnly, false, false, RiskMedium, "integration.accounting", "accounting.parasut"),
			provider("LOGO_EXPORT", "Logo Export", CategoryAccountingExport, ModeCatalogOnly, DirectionExportOnly, false, false, RiskMedium, "integration.accounting", "accounting.logo_export"),
			provider("MIKRO_EXPORT", "Mikro Export", CategoryAccountingExport, ModeCatalogOnly, DirectionExportOnly, false, false, RiskMedium, "integration.accounting", "accounting.mikro_export"),
			provider("ZIRVE_EXPORT", "Zirve Export", CategoryAccountingExport, ModeCatalogOnly, DirectionExportOnly, false, false, RiskMedium, "integration.accounting", "accounting.zirve_export"),
			provider("ETA_EXPORT", "ETA Export", CategoryAccountingExport, ModeCatalogOnly, DirectionExportOnly, false, false, RiskMedium, "integration.accounting", "accounting.eta_export"),
			provider("PAYMENT_PROVIDER_HANDOFF", "Payment Provider Production Handoff", CategoryPayment, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskCritical, "integration.payment", "payment.provider_adapter"),
			provider("E_FATURA_PROVIDER", "e-Fatura Provider", CategoryEDocument, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskHigh, "integration.edocument", "edocument.e_fatura"),
			provider("E_ARSIV_PROVIDER", "e-Arşiv Provider", CategoryEDocument, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskHigh, "integration.edocument", "edocument.e_arsiv"),
			provider("LOGISTICS_PROVIDER", "Logistics Provider", CategoryLogistics, ModeProviderSpecificModuleRequired, DirectionBidirectional, true, true, RiskMedium, "integration.logistics"),
			provider("CRM_WEBHOOK", "CRM Webhook", CategoryWebhook, ModeCatalogOnly, DirectionOutbound, false, true, RiskMedium, "integration.webhook", "crm.webhook"),
			provider("PUBLIC_API", "Public API Platform", CategoryPublicAPI, ModeCatalogOnly, DirectionBidirectional, false, false, RiskHigh, "integration.public_api"),
		},
	}
}

func provider(code string, name string, category IntegrationCategory, mode IntegrationMode, direction IntegrationDirection, sandbox bool, webhook bool, risk ProviderRiskLevel, entitlements ...string) Provider {
	return Provider{
		Code:                 code,
		Name:                 name,
		Category:             category,
		Status:               StatusPlanned,
		Mode:                 mode,
		Direction:            direction,
		TenantScoped:         true,
		AuditRequired:        true,
		SandboxEnabled:       sandbox,
		WebhookRequired:      webhook,
		ProductionGate:       ProductionGateClosed,
		RequiredEntitlements: append([]string{}, entitlements...),
		ConfigKey:            "integrations." + strings.ToLower(strings.ReplaceAll(code, "_", ".")),
		DocumentationPath:    "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md",
		RiskLevel:            risk,
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
	if c.RealProviderConnectionsEnabled {
		return errors.New("real provider connections must remain disabled in FAZ 7-8")
	}
	if c.RealPaymentLiveStatus != "CLOSED" {
		return errors.New("real payment live status must remain CLOSED in FAZ 7-8")
	}
	if !c.ProviderSpecificModuleRequired {
		return errors.New("provider specific module rule is required")
	}
	if len(c.Providers) == 0 {
		return errors.New("at least one provider is required")
	}

	seen := map[string]struct{}{}
	for i, p := range c.Providers {
		if err := validateProvider(p); err != nil {
			return fmt.Errorf("provider[%d] %s: %w", i, p.Code, err)
		}
		normalizedCode := strings.ToUpper(strings.TrimSpace(p.Code))
		if _, ok := seen[normalizedCode]; ok {
			return fmt.Errorf("duplicate provider code: %s", p.Code)
		}
		seen[normalizedCode] = struct{}{}
	}

	return nil
}

func validateProvider(p Provider) error {
	if strings.TrimSpace(p.Code) == "" {
		return errors.New("code is required")
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
	if !validMode(p.Mode) {
		return fmt.Errorf("unsupported mode: %s", p.Mode)
	}
	if !validDirection(p.Direction) {
		return fmt.Errorf("unsupported direction: %s", p.Direction)
	}
	if !p.TenantScoped {
		return errors.New("tenant scoped flag is required")
	}
	if !p.AuditRequired {
		return errors.New("audit required flag is required")
	}
	if p.ProductionGate != ProductionGateClosed && p.ProductionGate != ProductionGateOpen {
		return fmt.Errorf("unsupported production gate: %s", p.ProductionGate)
	}
	if p.Status != StatusProductionReady && p.ProductionGate == ProductionGateOpen {
		return errors.New("production gate cannot be OPEN unless provider is production ready")
	}
	if len(p.RequiredEntitlements) == 0 {
		return errors.New("required entitlements are required")
	}
	if strings.TrimSpace(p.ConfigKey) == "" {
		return errors.New("config key is required")
	}
	if strings.TrimSpace(p.DocumentationPath) == "" {
		return errors.New("documentation path is required")
	}
	if !validRiskLevel(p.RiskLevel) {
		return fmt.Errorf("unsupported risk level: %s", p.RiskLevel)
	}
	return nil
}

func (c Catalog) FindByCode(code string) (Provider, bool) {
	needle := strings.ToUpper(strings.TrimSpace(code))
	for _, p := range c.Providers {
		if strings.ToUpper(p.Code) == needle {
			return p, true
		}
	}
	return Provider{}, false
}

func (c Catalog) ListByCategory(category IntegrationCategory) []Provider {
	out := make([]Provider, 0)
	for _, p := range c.Providers {
		if p.Category == category {
			out = append(out, p)
		}
	}
	return out
}

func (c Catalog) ProductionCandidates() []Provider {
	out := make([]Provider, 0)
	for _, p := range c.Providers {
		if p.ProductionGate == ProductionGateOpen {
			out = append(out, p)
		}
	}
	return out
}

func (p Provider) RequiresProviderSpecificModule() bool {
	return p.Mode == ModeProviderSpecificModuleRequired
}

func validCategory(v IntegrationCategory) bool {
	switch v {
	case CategoryMarketplace, CategoryAccountingExport, CategoryPayment, CategoryEDocument, CategoryLogistics, CategoryCRM, CategoryWebhook, CategoryPublicAPI:
		return true
	default:
		return false
	}
}

func validStatus(v IntegrationStatus) bool {
	switch v {
	case StatusPlanned, StatusCatalogOnly, StatusSandboxReady, StatusHandoffReadyClosed, StatusProductionReady:
		return true
	default:
		return false
	}
}

func validMode(v IntegrationMode) bool {
	switch v {
	case ModeCatalogOnly, ModeProviderSpecificModuleRequired, ModeSandboxOnly:
		return true
	default:
		return false
	}
}

func validDirection(v IntegrationDirection) bool {
	switch v {
	case DirectionInbound, DirectionOutbound, DirectionExportOnly, DirectionBidirectional:
		return true
	default:
		return false
	}
}

func validRiskLevel(v ProviderRiskLevel) bool {
	switch v {
	case RiskLow, RiskMedium, RiskHigh, RiskCritical:
		return true
	default:
		return false
	}
}
