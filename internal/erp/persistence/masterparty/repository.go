package masterparty

import "context"

type PartyRepository interface {
	CreateParty(ctx context.Context, input CreatePartyInput) (Party, error)
	GetPartyByID(ctx context.Context, tenantID string, partyID string) (Party, error)
	ListParties(ctx context.Context, tenantID string, filter ListPartiesFilter) ([]Party, error)
}

type ListPartiesFilter struct {
	Query       string
	Status      PartyStatus
	Limit       int
	Offset      int
	WithDeleted bool
}

type CustomerRepository interface {
	CreateCustomer(ctx context.Context, tenantID string, partyID string, customerCode string) (Customer, error)
	GetCustomerByID(ctx context.Context, tenantID string, customerID string) (Customer, error)
	ListCustomers(ctx context.Context, tenantID string, filter ListCustomersFilter) ([]Customer, error)
}

type ListCustomersFilter struct {
	Query  string
	Status PartyStatus
	Limit  int
	Offset int
}

type VendorRepository interface {
	CreateVendor(ctx context.Context, tenantID string, partyID string, vendorCode string) (Vendor, error)
	GetVendorByID(ctx context.Context, tenantID string, vendorID string) (Vendor, error)
	ListVendors(ctx context.Context, tenantID string, filter ListVendorsFilter) ([]Vendor, error)
}

type ListVendorsFilter struct {
	Query  string
	Status PartyStatus
	Limit  int
	Offset int
}

type ContactRepository interface {
	CreateContact(ctx context.Context, input CreateContactInput) (Contact, error)
	GetContactByID(ctx context.Context, tenantID string, contactID string) (Contact, error)
	ListContacts(ctx context.Context, tenantID string, filter ListContactsFilter) ([]Contact, error)
}

type CreateContactInput struct {
	TenantID    string
	PartyID     string
	FullName    string
	Title       string
	Department  string
	Phone       string
	MobilePhone string
	Email       string
	IsPrimary   bool
	CreatedBy   string
}

type ListContactsFilter struct {
	PartyID string
	Query   string
	Status  PartyStatus
	Limit   int
	Offset  int
}

type AddressRepository interface {
	CreateAddress(ctx context.Context, input CreateAddressInput) (Address, error)
	GetAddressByID(ctx context.Context, tenantID string, addressID string) (Address, error)
	ListAddresses(ctx context.Context, tenantID string, filter ListAddressesFilter) ([]Address, error)
}

type CreateAddressInput struct {
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
	CreatedBy         string
}

type ListAddressesFilter struct {
	PartyID     string
	AddressType AddressType
	Query       string
	Status      PartyStatus
	Limit       int
	Offset      int
}
