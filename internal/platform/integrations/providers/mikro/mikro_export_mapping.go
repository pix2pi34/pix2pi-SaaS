package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	MikroExportMappingPhase        = "FAZ_7_8M_1"
	MikroExportMappingModule       = "MIKRO_EXPORT_MAPPING_ERP_OBJECT_CONTRACT"
	MikroExportMappingModuleName   = "Mikro Export Mapping / ERP Object Contract Readiness"
	MikroExportMappingMode         = "ERP_OBJECT_EXPORT_MAPPING_CONTRACT_ONLY"
	MikroExportMappingDirection    = "PIX2PI_TO_MIKRO"
	MikroExportMappingSourceSystem = "PIX2PI_ERP"
	MikroExportMappingTargetSystem = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroExportMappingGate         = "READY_AFTER_TEST_AND_AUDIT_PASS"

	MikroObjectCariHesapKarti = "CARI_HESAP_KARTI"
	MikroObjectStokKarti      = "STOK_KARTI"
	MikroObjectHizmetKarti    = "HIZMET_KARTI"
	MikroObjectSatisFaturasi  = "SATIS_FATURASI"
	MikroObjectAlisFaturasi   = "ALIS_FATURASI"
	MikroObjectStokHareketi   = "STOK_HAREKETI"
	MikroObjectMuhasebeFisi   = "MUHASEBE_FISI"
	MikroObjectKDVSatiri      = "KDV_SATIRI"

	ERPObjectCustomer          = "CUSTOMER"
	ERPObjectVendor            = "VENDOR"
	ERPObjectProduct           = "PRODUCT"
	ERPObjectServiceItem       = "SERVICE_ITEM"
	ERPObjectSalesInvoice      = "SALES_INVOICE"
	ERPObjectPurchaseInvoice   = "PURCHASE_INVOICE"
	ERPObjectStockMovement     = "STOCK_MOVEMENT"
	ERPObjectAccountingVoucher = "ACCOUNTING_VOUCHER"
	ERPObjectTaxLine           = "TAX_LINE"

	MikroExportMappingDecisionReady            = "MIKRO_EXPORT_MAPPING_CONTRACT_READY"
	MikroExportMappingDecisionUnsupported      = "MIKRO_ERP_OBJECT_UNSUPPORTED"
	MikroExportMappingDecisionSecretForbidden  = "MIKRO_EXPORT_MAPPING_SECRET_FIELD_FORBIDDEN"
	MikroExportMappingDecisionRealAPIClosed    = "MIKRO_EXPORT_MAPPING_REAL_PROVIDER_API_CLOSED"
	MikroExportMappingDecisionFileDeliveryStop = "MIKRO_EXPORT_MAPPING_REAL_FILE_DELIVERY_CLOSED"
	MikroExportMappingDecisionERPWriteClosed   = "MIKRO_EXPORT_MAPPING_REAL_ERP_WRITE_CLOSED"
	MikroExportMappingDecisionLiveModeClosed   = "MIKRO_EXPORT_MAPPING_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroExportMappingContract = errors.New("invalid mikro export mapping contract")
	ErrInvalidMikroExportMappingRequest  = errors.New("invalid mikro export mapping request")
	ErrMikroExportMappingSecretForbidden = errors.New("mikro export mapping secret field is forbidden")
)

type MikroFieldMapping struct {
	SourceField   string
	TargetField   string
	Required      bool
	TransformRule string
	Sensitive     bool
}

type MikroObjectMapping struct {
	ERPObjectType   string
	MikroObjectType string
	Direction       string
	Required        bool
	Fields          []MikroFieldMapping
}

type MikroExportMappingContract struct {
	Phase                  string
	Module                 string
	ModuleName             string
	ProviderID             string
	ProviderName           string
	ProviderCategory       string
	MappingMode            string
	Direction              string
	SourceSystem           string
	TargetSystem           string
	MappingGate            string
	RealProviderAPIStatus  string
	RealFileDeliveryStatus string
	RealERPWriteStatus     string
	RequiredContextFields  []string
	ForbiddenFieldLabels   []string
	ObjectMappings         []MikroObjectMapping
}

type MikroExportMappingRequest struct {
	TenantID                string
	ActorUserID             string
	CorrelationID           string
	ERPObjectType           string
	RequestedMode           string
	RealProviderAPIEnabled  bool
	RealFileDeliveryEnabled bool
	RealERPWriteEnabled     bool
	InjectedFieldName       string
}

type MikroExportMappingDecision struct {
	Allowed                bool
	Phase                  string
	Module                 string
	ProviderID             string
	ProviderName           string
	ERPObjectType          string
	MikroObjectType        string
	Direction              string
	MappingMode            string
	Reason                 string
	RealProviderAPIStatus  string
	RealFileDeliveryStatus string
	RealERPWriteStatus     string
	MappingGate            string
	FieldCount             int
	RequiredFieldCount     int
	AuditFields            map[string]string
}

func NewMikroExportMappingContract() MikroExportMappingContract {
	return MikroExportMappingContract{
		Phase:                  MikroExportMappingPhase,
		Module:                 MikroExportMappingModule,
		ModuleName:             MikroExportMappingModuleName,
		ProviderID:             ProviderID,
		ProviderName:           ProviderName,
		ProviderCategory:       ProviderCategory,
		MappingMode:            MikroExportMappingMode,
		Direction:              MikroExportMappingDirection,
		SourceSystem:           MikroExportMappingSourceSystem,
		TargetSystem:           MikroExportMappingTargetSystem,
		MappingGate:            MikroExportMappingGate,
		RealProviderAPIStatus:  MikroRealProviderAPIStatus,
		RealFileDeliveryStatus: MikroRealFileDeliveryStatus,
		RealERPWriteStatus:     MikroRealERPWriteStatus,
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"erp_object_type",
		},
		ForbiddenFieldLabels: []string{
			"client_secret",
			"access_token",
			"refresh_token",
			"password",
			"real_provider_endpoint",
			"real_delivery_endpoint",
		},
		ObjectMappings: []MikroObjectMapping{
			{
				ERPObjectType:   ERPObjectCustomer,
				MikroObjectType: MikroObjectCariHesapKarti,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "customer_id", TargetField: "cari_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "legal_name", TargetField: "cari_unvan", Required: true, TransformRule: "trim_upper", Sensitive: false},
					{SourceField: "tax_number", TargetField: "vergi_no", Required: false, TransformRule: "digits_only", Sensitive: false},
					{SourceField: "tax_office", TargetField: "vergi_dairesi", Required: false, TransformRule: "trim", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectVendor,
				MikroObjectType: MikroObjectCariHesapKarti,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "vendor_id", TargetField: "cari_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "legal_name", TargetField: "cari_unvan", Required: true, TransformRule: "trim_upper", Sensitive: false},
					{SourceField: "tax_number", TargetField: "vergi_no", Required: false, TransformRule: "digits_only", Sensitive: false},
					{SourceField: "tax_office", TargetField: "vergi_dairesi", Required: false, TransformRule: "trim", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectProduct,
				MikroObjectType: MikroObjectStokKarti,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "product_id", TargetField: "stok_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "product_name", TargetField: "stok_adi", Required: true, TransformRule: "trim", Sensitive: false},
					{SourceField: "barcode", TargetField: "barkod", Required: false, TransformRule: "trim", Sensitive: false},
					{SourceField: "unit_code", TargetField: "birim", Required: true, TransformRule: "normalize_unit", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectServiceItem,
				MikroObjectType: MikroObjectHizmetKarti,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "service_id", TargetField: "hizmet_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "service_name", TargetField: "hizmet_adi", Required: true, TransformRule: "trim", Sensitive: false},
					{SourceField: "vat_rate", TargetField: "kdv_orani", Required: true, TransformRule: "percent_to_rate", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectSalesInvoice,
				MikroObjectType: MikroObjectSatisFaturasi,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "invoice_id", TargetField: "belge_no", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "customer_id", TargetField: "cari_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "issue_date", TargetField: "belge_tarihi", Required: true, TransformRule: "date_yyyy_mm_dd", Sensitive: false},
					{SourceField: "currency_code", TargetField: "doviz_kodu", Required: false, TransformRule: "currency_upper", Sensitive: false},
					{SourceField: "net_total", TargetField: "net_tutar", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
					{SourceField: "tax_total", TargetField: "kdv_tutari", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
					{SourceField: "gross_total", TargetField: "genel_toplam", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectPurchaseInvoice,
				MikroObjectType: MikroObjectAlisFaturasi,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "invoice_id", TargetField: "belge_no", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "vendor_id", TargetField: "cari_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "issue_date", TargetField: "belge_tarihi", Required: true, TransformRule: "date_yyyy_mm_dd", Sensitive: false},
					{SourceField: "net_total", TargetField: "net_tutar", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
					{SourceField: "tax_total", TargetField: "kdv_tutari", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
					{SourceField: "gross_total", TargetField: "genel_toplam", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectStockMovement,
				MikroObjectType: MikroObjectStokHareketi,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "movement_id", TargetField: "hareket_no", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "product_id", TargetField: "stok_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "warehouse_id", TargetField: "depo_kodu", Required: true, TransformRule: "pix2pi_id_to_mikro_code", Sensitive: false},
					{SourceField: "quantity", TargetField: "miktar", Required: true, TransformRule: "decimal", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectAccountingVoucher,
				MikroObjectType: MikroObjectMuhasebeFisi,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "journal_id", TargetField: "fis_no", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "posting_date", TargetField: "fis_tarihi", Required: true, TransformRule: "date_yyyy_mm_dd", Sensitive: false},
					{SourceField: "account_code", TargetField: "hesap_kodu", Required: true, TransformRule: "tdhp_account_code", Sensitive: false},
					{SourceField: "debit_amount", TargetField: "borc", Required: false, TransformRule: "money_minor_to_decimal", Sensitive: false},
					{SourceField: "credit_amount", TargetField: "alacak", Required: false, TransformRule: "money_minor_to_decimal", Sensitive: false},
				},
			},
			{
				ERPObjectType:   ERPObjectTaxLine,
				MikroObjectType: MikroObjectKDVSatiri,
				Direction:       MikroExportMappingDirection,
				Required:        true,
				Fields: []MikroFieldMapping{
					{SourceField: "tenant_id", TargetField: "tenant_ref", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "tax_line_id", TargetField: "kdv_satir_no", Required: true, TransformRule: "copy", Sensitive: false},
					{SourceField: "tax_rate", TargetField: "kdv_orani", Required: true, TransformRule: "percent_to_rate", Sensitive: false},
					{SourceField: "tax_base", TargetField: "matrah", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
					{SourceField: "tax_amount", TargetField: "kdv_tutari", Required: true, TransformRule: "money_minor_to_decimal", Sensitive: false},
				},
			},
		},
	}
}

func (c MikroExportMappingContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroExportMappingPhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroExportMappingContract, MikroExportMappingPhase)
	}
	if strings.TrimSpace(c.Module) != MikroExportMappingModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroExportMappingContract, MikroExportMappingModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroExportMappingContract, ProviderID)
	}
	if strings.TrimSpace(c.MappingMode) != MikroExportMappingMode {
		return fmt.Errorf("%w: mapping mode must be contract only", ErrInvalidMikroExportMappingContract)
	}
	if strings.TrimSpace(c.Direction) != MikroExportMappingDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroExportMappingContract)
	}
	if strings.TrimSpace(c.SourceSystem) != MikroExportMappingSourceSystem {
		return fmt.Errorf("%w: source system must be PIX2PI_ERP", ErrInvalidMikroExportMappingContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroExportMappingTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroExportMappingContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroExportMappingContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroExportMappingContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroExportMappingContract)
	}
	if len(c.RequiredContextFields) < 4 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroExportMappingContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden field labels are required", ErrInvalidMikroExportMappingContract)
	}
	if len(c.ObjectMappings) < 9 {
		return fmt.Errorf("%w: object mapping coverage is incomplete", ErrInvalidMikroExportMappingContract)
	}
	for _, mapping := range c.ObjectMappings {
		if err := validateObjectMapping(mapping); err != nil {
			return err
		}
	}
	return nil
}

func (c MikroExportMappingContract) SupportsERPObject(erpObjectType string) bool {
	_, ok := c.MappingFor(erpObjectType)
	return ok
}

func (c MikroExportMappingContract) MappingFor(erpObjectType string) (MikroObjectMapping, bool) {
	normalized := normalizeExportMappingValue(erpObjectType)
	for _, mapping := range c.ObjectMappings {
		if mapping.ERPObjectType == normalized {
			return mapping, true
		}
	}
	return MikroObjectMapping{}, false
}

func (c MikroExportMappingContract) Evaluate(req MikroExportMappingRequest) (MikroExportMappingDecision, error) {
	decision := MikroExportMappingDecision{
		Allowed:                false,
		Phase:                  c.Phase,
		Module:                 c.Module,
		ProviderID:             c.ProviderID,
		ProviderName:           c.ProviderName,
		ERPObjectType:          normalizeExportMappingValue(req.ERPObjectType),
		Direction:              c.Direction,
		MappingMode:            c.MappingMode,
		RealProviderAPIStatus:  c.RealProviderAPIStatus,
		RealFileDeliveryStatus: c.RealFileDeliveryStatus,
		RealERPWriteStatus:     c.RealERPWriteStatus,
		MappingGate:            c.MappingGate,
		AuditFields: map[string]string{
			"tenant_id":       strings.TrimSpace(req.TenantID),
			"actor_user_id":   strings.TrimSpace(req.ActorUserID),
			"correlation_id":  strings.TrimSpace(req.CorrelationID),
			"provider_id":     c.ProviderID,
			"phase":           c.Phase,
			"erp_object_type": normalizeExportMappingValue(req.ERPObjectType),
			"mapping_mode":    c.MappingMode,
			"mapping_gate":    c.MappingGate,
			"source_system":   c.SourceSystem,
			"target_system":   c.TargetSystem,
			"mapping_runtime": "dry_run_contract_only",
		},
	}

	if err := c.Validate(); err != nil {
		return decision, err
	}
	if err := validateMikroExportMappingRequest(req); err != nil {
		return decision, err
	}
	if containsForbiddenMappingField(req.InjectedFieldName) {
		decision.Reason = MikroExportMappingDecisionSecretForbidden
		return decision, ErrMikroExportMappingSecretForbidden
	}
	if normalizeExportMappingValue(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroExportMappingDecisionLiveModeClosed
		return decision, nil
	}
	if req.RealProviderAPIEnabled {
		decision.Reason = MikroExportMappingDecisionRealAPIClosed
		return decision, nil
	}
	if req.RealFileDeliveryEnabled {
		decision.Reason = MikroExportMappingDecisionFileDeliveryStop
		return decision, nil
	}
	if req.RealERPWriteEnabled {
		decision.Reason = MikroExportMappingDecisionERPWriteClosed
		return decision, nil
	}

	mapping, ok := c.MappingFor(req.ERPObjectType)
	if !ok {
		decision.Reason = MikroExportMappingDecisionUnsupported
		return decision, nil
	}

	decision.Allowed = true
	decision.Reason = MikroExportMappingDecisionReady
	decision.MikroObjectType = mapping.MikroObjectType
	decision.FieldCount = len(mapping.Fields)
	decision.RequiredFieldCount = countRequiredFields(mapping.Fields)
	return decision, nil
}

func validateObjectMapping(mapping MikroObjectMapping) error {
	if strings.TrimSpace(mapping.ERPObjectType) == "" {
		return fmt.Errorf("%w: erp object type is required", ErrInvalidMikroExportMappingContract)
	}
	if strings.TrimSpace(mapping.MikroObjectType) == "" {
		return fmt.Errorf("%w: mikro object type is required", ErrInvalidMikroExportMappingContract)
	}
	if strings.TrimSpace(mapping.Direction) != MikroExportMappingDirection {
		return fmt.Errorf("%w: mapping direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroExportMappingContract)
	}
	if len(mapping.Fields) == 0 {
		return fmt.Errorf("%w: mapping fields are required for %s", ErrInvalidMikroExportMappingContract, mapping.ERPObjectType)
	}
	for _, field := range mapping.Fields {
		if strings.TrimSpace(field.SourceField) == "" || strings.TrimSpace(field.TargetField) == "" {
			return fmt.Errorf("%w: source and target fields are required", ErrInvalidMikroExportMappingContract)
		}
		if field.Sensitive {
			return fmt.Errorf("%w: sensitive mapping fields are forbidden", ErrInvalidMikroExportMappingContract)
		}
		if containsForbiddenMappingField(field.SourceField) || containsForbiddenMappingField(field.TargetField) {
			return fmt.Errorf("%w: forbidden mapping field detected", ErrInvalidMikroExportMappingContract)
		}
	}
	return nil
}

func validateMikroExportMappingRequest(req MikroExportMappingRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroExportMappingRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroExportMappingRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroExportMappingRequest)
	}
	if strings.TrimSpace(req.ERPObjectType) == "" {
		return fmt.Errorf("%w: erp_object_type is required", ErrInvalidMikroExportMappingRequest)
	}
	return nil
}

func countRequiredFields(fields []MikroFieldMapping) int {
	count := 0
	for _, field := range fields {
		if field.Required {
			count++
		}
	}
	return count
}

func containsForbiddenMappingField(fieldName string) bool {
	normalized := strings.ToLower(strings.TrimSpace(fieldName))
	if normalized == "" {
		return false
	}
	forbiddenFragments := []string{
		"client_secret",
		"access_token",
		"refresh_token",
		"password",
		"real_provider_endpoint",
		"real_delivery_endpoint",
		"secret",
		"token",
	}
	for _, fragment := range forbiddenFragments {
		if strings.Contains(normalized, fragment) {
			return true
		}
	}
	return false
}

func normalizeExportMappingValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}
