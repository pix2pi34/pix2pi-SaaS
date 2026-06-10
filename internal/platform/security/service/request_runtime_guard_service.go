package service

import (
	"errors"
	"strings"
)

var (
	ErrRuntimeGuardProfileNameRequired = errors.New("security: runtime guard profile name required")
	ErrRuntimeGuardInputNilMaps        = errors.New("security: runtime guard input maps cannot both be nil")
)

type RuntimeRequestGuardProfile struct {
	Name                 string
	AllowedQueryKeys     []string
	AllowedHeaderKeys    []string
	QueryValueMaxLength  int
	HeaderValueMaxLength int
}

func (p RuntimeRequestGuardProfile) Validate() error {
	if strings.TrimSpace(p.Name) == "" {
		return ErrRuntimeGuardProfileNameRequired
	}
	if p.QueryValueMaxLength <= 0 {
		return ErrInputMaxLengthInvalid
	}
	if p.HeaderValueMaxLength <= 0 {
		return ErrInputMaxLengthInvalid
	}
	return nil
}

type RuntimeRequestInput struct {
	QueryParams map[string]string
	Headers     map[string]string
}

func GuardRuntimeRequestInput(
	profile RuntimeRequestGuardProfile,
	input RuntimeRequestInput,
) error {
	if err := profile.Validate(); err != nil {
		return err
	}

	if input.QueryParams == nil && input.Headers == nil {
		return ErrRuntimeGuardInputNilMaps
	}

	if len(input.QueryParams) > 0 {
		if len(profile.AllowedQueryKeys) == 0 {
			return ErrInputKeyNotAllowed
		}
		if err := ValidateAllowedQueryParams(
			input.QueryParams,
			profile.AllowedQueryKeys,
			profile.QueryValueMaxLength,
		); err != nil {
			return err
		}
	}

	if len(input.Headers) > 0 {
		if len(profile.AllowedHeaderKeys) == 0 {
			return ErrHeaderKeyNotAllowed
		}
		if err := ValidateAllowedHeaderInputs(
			input.Headers,
			profile.AllowedHeaderKeys,
			profile.HeaderValueMaxLength,
		); err != nil {
			return err
		}
	}

	return nil
}

func DefaultAPIRuntimeRequestGuardProfile() RuntimeRequestGuardProfile {
	return RuntimeRequestGuardProfile{
		Name:                 "default_api_runtime_guard",
		AllowedQueryKeys:     []string{"tenant_id", "branch_id", "period_key", "cursor", "limit"},
		AllowedHeaderKeys:    []string{"X-Tenant-ID", "X-Request-ID", "Authorization"},
		QueryValueMaxLength:  128,
		HeaderValueMaxLength: 512,
	}
}
