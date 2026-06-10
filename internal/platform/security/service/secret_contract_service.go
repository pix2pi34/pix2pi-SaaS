package service

import (
	"errors"
	"strings"
	"unicode"
)

var (
	ErrSecretNameRequired     = errors.New("security: secret name required")
	ErrSecretValueRequired    = errors.New("security: secret value required")
	ErrSecretTooShort         = errors.New("security: secret too short")
	ErrSecretWeakDefault      = errors.New("security: weak default secret forbidden")
	ErrSecretRequireUpper     = errors.New("security: secret must contain uppercase")
	ErrSecretRequireLower     = errors.New("security: secret must contain lowercase")
	ErrSecretRequireDigit     = errors.New("security: secret must contain digit")
	ErrSecretPolicyMinInvalid = errors.New("security: invalid secret min length")
)

type SecretPolicy struct {
	MinLength        int
	RequireUppercase bool
	RequireLowercase bool
	RequireDigit     bool
	ForbiddenValues  []string
}

func DefaultSecretPolicy() SecretPolicy {
	return SecretPolicy{
		MinLength:        16,
		RequireUppercase: true,
		RequireLowercase: true,
		RequireDigit:     true,
		ForbiddenValues: []string{
			"changeme",
			"default",
			"secret",
			"password",
			"123456",
			"admin",
			"test",
		},
	}
}

func (p SecretPolicy) Validate() error {
	if p.MinLength <= 0 {
		return ErrSecretPolicyMinInvalid
	}
	return nil
}

type SecretContractInput struct {
	Name  string
	Value string
}

func ValidateSecretContract(
	input SecretContractInput,
	policy SecretPolicy,
) error {
	if err := policy.Validate(); err != nil {
		return err
	}

	name := strings.TrimSpace(input.Name)
	value := strings.TrimSpace(input.Value)

	if name == "" {
		return ErrSecretNameRequired
	}
	if value == "" {
		return ErrSecretValueRequired
	}

	for _, forbidden := range policy.ForbiddenValues {
		if strings.EqualFold(value, strings.TrimSpace(forbidden)) {
			return ErrSecretWeakDefault
		}
	}

	if len(value) < policy.MinLength {
		return ErrSecretTooShort
	}

	var hasUpper bool
	var hasLower bool
	var hasDigit bool

	for _, r := range value {
		if unicode.IsUpper(r) {
			hasUpper = true
		}
		if unicode.IsLower(r) {
			hasLower = true
		}
		if unicode.IsDigit(r) {
			hasDigit = true
		}
	}

	if policy.RequireUppercase && !hasUpper {
		return ErrSecretRequireUpper
	}
	if policy.RequireLowercase && !hasLower {
		return ErrSecretRequireLower
	}
	if policy.RequireDigit && !hasDigit {
		return ErrSecretRequireDigit
	}

	return nil
}

func ValidateRequiredSecrets(
	inputs []SecretContractInput,
	policy SecretPolicy,
) error {
	for _, input := range inputs {
		if err := ValidateSecretContract(input, policy); err != nil {
			return err
		}
	}
	return nil
}
