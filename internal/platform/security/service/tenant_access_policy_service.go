package service

import "errors"

const (
	RoleTenantUser = "tenant_user"
	RoleSuperAdmin = "super_admin"
)

type TenantAccessPolicyService struct {
}

func NewTenantAccessPolicyService() *TenantAccessPolicyService {
	return &TenantAccessPolicyService{}
}

func (s *TenantAccessPolicyService) TenantErisimKontrol(
	role string,
	requestTenantID string,
	resourceTenantID string,
) error {
	if role == "" {
		return errors.New("role zorunlu")
	}
	if resourceTenantID == "" {
		return errors.New("resource tenant id zorunlu")
	}

	if role == RoleSuperAdmin {
		return nil
	}

	if requestTenantID == "" {
		return errors.New("request tenant id zorunlu")
	}

	if requestTenantID != resourceTenantID {
		return errors.New("tenant erisim reddedildi")
	}

	return nil
}
