package masterparty

import "errors"

var (
	ErrPartyNotFound           = errors.New("party bulunamadi")
	ErrCustomerNotFound        = errors.New("customer bulunamadi")
	ErrVendorNotFound          = errors.New("vendor bulunamadi")
	ErrContactNotFound         = errors.New("contact bulunamadi")
	ErrAddressNotFound         = errors.New("address bulunamadi")
	ErrPartyIDRequired         = errors.New("party_id zorunlu")
	ErrContactFullNameRequired = errors.New("contact full_name zorunlu")
	ErrAddressCityRequired     = errors.New("address city zorunlu")
	ErrAddressLine1Required    = errors.New("address_line1 zorunlu")
	ErrAddressTypeInvalid      = errors.New("address_type gecersiz")
)
