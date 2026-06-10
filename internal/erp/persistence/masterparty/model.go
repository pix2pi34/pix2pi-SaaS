package masterparty

import (
	"errors"
	"strings"
	"time"
)

type PartyType string

const (
	PartyTypePerson       PartyType = "person"
	PartyTypeOrganization PartyType = "organization"
)

type PartyStatus string

const (
	PartyStatusActive  PartyStatus = "active"
	PartyStatusPassive PartyStatus = "passive"
	PartyStatusBlocked PartyStatus = "blocked"
	PartyStatusDeleted PartyStatus = "deleted"
)

type Party struct {
	PartyID     string
	TenantID    string
	PartyType   PartyType
	DisplayName string
	LegalName   string
	TradeName   string

	TaxNo     string
	TaxOffice string
	MersisNo  string

	Phone string
	Email string

	Status PartyStatus
	Source string

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time

	CreatedBy string
	UpdatedBy string
}

type Customer struct {
	CustomerID       string
	TenantID         string
	PartyID          string
	CustomerCode     string
	CustomerGroup    string
	CreditLimit      float64
	PaymentTermsDays int
	CurrencyCode     string
	IsCreditAllowed  bool
	Status           PartyStatus
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time
	CreatedBy        string
	UpdatedBy        string
}

type Vendor struct {
	VendorID          string
	TenantID          string
	PartyID           string
	VendorCode        string
	VendorGroup       string
	PaymentTermsDays  int
	CurrencyCode      string
	IsPurchaseAllowed bool
	Status            PartyStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type Contact struct {
	ContactID   string
	TenantID    string
	PartyID     string
	FullName    string
	Title       string
	Department  string
	Phone       string
	MobilePhone string
	Email       string
	IsPrimary   bool
	Status      PartyStatus
	CreatedAt   time.Time
	UpdatedAt   time.Time
	DeletedAt   *time.Time
	CreatedBy   string
	UpdatedBy   string
}

type AddressType string

const (
	AddressTypeGeneral   AddressType = "general"
	AddressTypeInvoice   AddressType = "invoice"
	AddressTypeDelivery  AddressType = "delivery"
	AddressTypeWarehouse AddressType = "warehouse"
	AddressTypeBranch    AddressType = "branch"
)

type Address struct {
	AddressID         string
	TenantID          string
	PartyID           string
	AddressType       AddressType
	CountryCode       string
	City              string
	District          string
	Neighborhood      string
	AddressLine1      string
	AddressLine2      string
	PostalCode        string
	IsPrimary         bool
	IsInvoiceAddress  bool
	IsDeliveryAddress bool
	Status            PartyStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type CreatePartyInput struct {
	TenantID    string
	PartyType   PartyType
	DisplayName string
	LegalName   string
	TradeName   string
	TaxNo       string
	TaxOffice   string
	MersisNo    string
	Phone       string
	Email       string
	Source      string
	CreatedBy   string
}

var (
	ErrTenantRequired      = errors.New("tenant_id zorunlu")
	ErrPartyTypeRequired   = errors.New("party_type zorunlu")
	ErrPartyTypeInvalid    = errors.New("party_type gecersiz")
	ErrDisplayNameRequired = errors.New("display_name zorunlu")
	ErrEmailInvalid        = errors.New("email gecersiz")
	ErrTaxOfficeRequired   = errors.New("vergi_dairesi zorunlu")
	ErrTaxNoRequired       = errors.New("vergi_no zorunlu")
)

func ValidateCreatePartyInput(input CreatePartyInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	switch input.PartyType {
	case PartyTypePerson, PartyTypeOrganization:
	default:
		if strings.TrimSpace(string(input.PartyType)) == "" {
			return ErrPartyTypeRequired
		}
		return ErrPartyTypeInvalid
	}

	if strings.TrimSpace(input.DisplayName) == "" {
		return ErrDisplayNameRequired
	}

	if strings.TrimSpace(input.Email) != "" && !strings.Contains(input.Email, "@") {
		return ErrEmailInvalid
	}

	if input.PartyType == PartyTypeOrganization {
		if strings.TrimSpace(input.TaxNo) == "" {
			return ErrTaxNoRequired
		}

		if strings.TrimSpace(input.TaxOffice) == "" {
			return ErrTaxOfficeRequired
		}
	}

	return nil
}
