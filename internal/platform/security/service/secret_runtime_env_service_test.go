package service

import "testing"

func testLookup(values map[string]string) func(string) string {
	return func(key string) string {
		return values[key]
	}
}

func TestRequiredSecretSpec_Validate_Success(t *testing.T) {
	spec := RequiredSecretSpec{
		EnvKey:      "JWT_SECRET",
		DisplayName: "JWT secret",
	}

	if err := spec.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRequiredSecretSpec_Validate_EmptyEnvKey(t *testing.T) {
	spec := RequiredSecretSpec{
		EnvKey:      "",
		DisplayName: "JWT secret",
	}

	err := spec.Validate()
	if err == nil {
		t.Fatal("expected env key required error")
	}
	if err != ErrSecretEnvKeyRequired {
		t.Fatalf("expected ErrSecretEnvKeyRequired, got %v", err)
	}
}

func TestDefaultCriticalSecretSpecs(t *testing.T) {
	specs := DefaultCriticalSecretSpecs()

	if len(specs) != 2 {
		t.Fatalf("expected 2 specs, got %d", len(specs))
	}

	if specs[0].EnvKey != "JWT_SECRET" {
		t.Fatalf("expected JWT_SECRET, got %s", specs[0].EnvKey)
	}
	if specs[1].EnvKey != "DB_PASSWORD" {
		t.Fatalf("expected DB_PASSWORD, got %s", specs[1].EnvKey)
	}
}

func TestValidateRequiredSecretsFromEnv_Success(t *testing.T) {
	err := ValidateRequiredSecretsFromEnv(
		[]RequiredSecretSpec{
			{EnvKey: "JWT_SECRET", DisplayName: "JWT secret"},
			{EnvKey: "DB_PASSWORD", DisplayName: "DB password"},
		},
		DefaultSecretPolicy(),
		testLookup(map[string]string{
			"JWT_SECRET":  "Pix2piSuperSecret123",
			"DB_PASSWORD": "PostgresStrongPass123",
		}),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateRequiredSecretsFromEnv_MissingValue(t *testing.T) {
	err := ValidateRequiredSecretsFromEnv(
		[]RequiredSecretSpec{
			{EnvKey: "JWT_SECRET", DisplayName: "JWT secret"},
		},
		DefaultSecretPolicy(),
		testLookup(map[string]string{}),
	)
	if err == nil {
		t.Fatal("expected missing value error")
	}
	if err != ErrSecretValueRequired {
		t.Fatalf("expected ErrSecretValueRequired, got %v", err)
	}
}

func TestValidateRequiredSecretsFromEnv_WeakDefault(t *testing.T) {
	err := ValidateRequiredSecretsFromEnv(
		[]RequiredSecretSpec{
			{EnvKey: "JWT_SECRET", DisplayName: "JWT secret"},
		},
		DefaultSecretPolicy(),
		testLookup(map[string]string{
			"JWT_SECRET": "password",
		}),
	)
	if err == nil {
		t.Fatal("expected weak default error")
	}
	if err != ErrSecretWeakDefault {
		t.Fatalf("expected ErrSecretWeakDefault, got %v", err)
	}
}

func TestValidateRequiredSecretsFromEnv_FailsFast(t *testing.T) {
	err := ValidateRequiredSecretsFromEnv(
		[]RequiredSecretSpec{
			{EnvKey: "JWT_SECRET", DisplayName: "JWT secret"},
			{EnvKey: "DB_PASSWORD", DisplayName: "DB password"},
		},
		DefaultSecretPolicy(),
		testLookup(map[string]string{
			"JWT_SECRET":  "Pix2piSuperSecret123",
			"DB_PASSWORD": "default",
		}),
	)
	if err == nil {
		t.Fatal("expected validation error")
	}
	if err != ErrSecretWeakDefault {
		t.Fatalf("expected ErrSecretWeakDefault, got %v", err)
	}
}

func TestValidateDefaultCriticalSecretsFromEnv_Success(t *testing.T) {
	err := ValidateDefaultCriticalSecretsFromEnv(
		testLookup(map[string]string{
			"JWT_SECRET":  "Pix2piSuperSecret123",
			"DB_PASSWORD": "PostgresStrongPass123",
		}),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}
