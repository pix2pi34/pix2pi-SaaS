package service

import "fmt"

type AccountMapping struct {
	TenantID          string
	SystemAccountCode string
	CompanyAccountCode string
}

type AccountMappingService struct {
	mappings map[string]AccountMapping
}

func NewAccountMappingService() *AccountMappingService {
	s := &AccountMappingService{
		mappings: make(map[string]AccountMapping),
	}

	s.seedDefaultMappings()

	return s
}

func (s *AccountMappingService) seedDefaultMappings() {
	defaultMappings := []AccountMapping{
		{
			TenantID:           "default",
			SystemAccountCode:  "120",
			CompanyAccountCode: "120.01.001",
		},
		{
			TenantID:           "default",
			SystemAccountCode:  "600",
			CompanyAccountCode: "600.01.001",
		},
		{
			TenantID:           "default",
			SystemAccountCode:  "391.01.20",
			CompanyAccountCode: "391.01.20",
		},
	}

	for _, mapping := range defaultMappings {
		key := s.buildKey(mapping.TenantID, mapping.SystemAccountCode)
		s.mappings[key] = mapping
	}
}

func (s *AccountMappingService) ResolveAccountCode(
	tenantID string,
	systemAccountCode string,
) (string, error) {
	if systemAccountCode == "" {
		return "", fmt.Errorf("system account code cannot be empty")
	}

	if tenantID == "" {
		tenantID = "default"
	}

	key := s.buildKey(tenantID, systemAccountCode)

	mapping, ok := s.mappings[key]
	if !ok {
		return systemAccountCode, nil
	}

	return mapping.CompanyAccountCode, nil
}

func (s *AccountMappingService) AddMapping(
	tenantID string,
	systemAccountCode string,
	companyAccountCode string,
) error {
	if tenantID == "" {
		tenantID = "default"
	}

	if systemAccountCode == "" {
		return fmt.Errorf("system account code cannot be empty")
	}

	if companyAccountCode == "" {
		return fmt.Errorf("company account code cannot be empty")
	}

	key := s.buildKey(tenantID, systemAccountCode)

	s.mappings[key] = AccountMapping{
		TenantID:           tenantID,
		SystemAccountCode:  systemAccountCode,
		CompanyAccountCode: companyAccountCode,
	}

	return nil
}

func (s *AccountMappingService) buildKey(
	tenantID string,
	systemAccountCode string,
) string {
	return tenantID + "::" + systemAccountCode
}
