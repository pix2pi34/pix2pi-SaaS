package service

import (
	"errors"
	"strings"
)

var (
	ErrSecretEnvKeyRequired = errors.New("security: secret env key required")
)

type RequiredSecretSpec struct {
	EnvKey      string
	DisplayName string
}

func (s RequiredSecretSpec) Validate() error {
	if strings.TrimSpace(s.EnvKey) == "" {
		return ErrSecretEnvKeyRequired
	}
	return nil
}

func DefaultCriticalSecretSpecs() []RequiredSecretSpec {
	return []RequiredSecretSpec{
		{
			EnvKey:      "JWT_SECRET",
			DisplayName: "JWT secret",
		},
		{
			EnvKey:      "DB_PASSWORD",
			DisplayName: "Database password",
		},
	}
}

func ValidateRequiredSecretsFromEnv(
	specs []RequiredSecretSpec,
	policy SecretPolicy,
	lookup func(string) string,
) error {
	if lookup == nil {
		return ErrSecretValueRequired
	}

	for _, spec := range specs {
		if err := spec.Validate(); err != nil {
			return err
		}

		value := strings.TrimSpace(lookup(spec.EnvKey))

		err := ValidateSecretContract(
			SecretContractInput{
				Name:  spec.EnvKey,
				Value: value,
			},
			policy,
		)
		if err != nil {
			return err
		}
	}

	return nil
}

func ValidateDefaultCriticalSecretsFromEnv(
	lookup func(string) string,
) error {
	return ValidateRequiredSecretsFromEnv(
		DefaultCriticalSecretSpecs(),
		DefaultSecretPolicy(),
		lookup,
	)
}
