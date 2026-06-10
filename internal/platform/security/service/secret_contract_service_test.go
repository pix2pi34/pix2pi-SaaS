package service

import "testing"

func TestDefaultSecretPolicy(t *testing.T) {
	p := DefaultSecretPolicy()

	if p.MinLength != 16 {
		t.Fatalf("expected 16, got %d", p.MinLength)
	}
	if !p.RequireUppercase {
		t.Fatal("expected uppercase required")
	}
	if !p.RequireLowercase {
		t.Fatal("expected lowercase required")
	}
	if !p.RequireDigit {
		t.Fatal("expected digit required")
	}
	if len(p.ForbiddenValues) == 0 {
		t.Fatal("expected forbidden values")
	}
}

func TestSecretPolicy_Validate_InvalidMinLength(t *testing.T) {
	p := DefaultSecretPolicy()
	p.MinLength = 0

	err := p.Validate()
	if err == nil {
		t.Fatal("expected invalid min length error")
	}
	if err != ErrSecretPolicyMinInvalid {
		t.Fatalf("expected ErrSecretPolicyMinInvalid, got %v", err)
	}
}

func TestValidateSecretContract_Success(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "Pix2piSuperSecret123",
		},
		DefaultSecretPolicy(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateSecretContract_EmptyName(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "",
			Value: "Pix2piSuperSecret123",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected empty name error")
	}
	if err != ErrSecretNameRequired {
		t.Fatalf("expected ErrSecretNameRequired, got %v", err)
	}
}

func TestValidateSecretContract_EmptyValue(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected empty value error")
	}
	if err != ErrSecretValueRequired {
		t.Fatalf("expected ErrSecretValueRequired, got %v", err)
	}
}

func TestValidateSecretContract_TooShort(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "Short1Aa",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected too short error")
	}
	if err != ErrSecretTooShort {
		t.Fatalf("expected ErrSecretTooShort, got %v", err)
	}
}

func TestValidateSecretContract_WeakDefault(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "password",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected weak default error")
	}
	if err != ErrSecretWeakDefault {
		t.Fatalf("expected ErrSecretWeakDefault, got %v", err)
	}
}

func TestValidateSecretContract_MissingUpper(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "pix2pisupersecret123",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected missing upper error")
	}
	if err != ErrSecretRequireUpper {
		t.Fatalf("expected ErrSecretRequireUpper, got %v", err)
	}
}

func TestValidateSecretContract_MissingLower(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "PIX2PISUPERSECRET123",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected missing lower error")
	}
	if err != ErrSecretRequireLower {
		t.Fatalf("expected ErrSecretRequireLower, got %v", err)
	}
}

func TestValidateSecretContract_MissingDigit(t *testing.T) {
	err := ValidateSecretContract(
		SecretContractInput{
			Name:  "JWT_SECRET",
			Value: "PixTwoPiSuperSecret",
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected missing digit error")
	}
	if err != ErrSecretRequireDigit {
		t.Fatalf("expected ErrSecretRequireDigit, got %v", err)
	}
}

func TestValidateRequiredSecrets_Success(t *testing.T) {
	err := ValidateRequiredSecrets(
		[]SecretContractInput{
			{Name: "JWT_SECRET", Value: "Pix2piSuperSecret123"},
			{Name: "DB_PASSWORD", Value: "PostgresStrongPass123"},
		},
		DefaultSecretPolicy(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateRequiredSecrets_FailsFast(t *testing.T) {
	err := ValidateRequiredSecrets(
		[]SecretContractInput{
			{Name: "JWT_SECRET", Value: "Pix2piSuperSecret123"},
			{Name: "DB_PASSWORD", Value: "default"},
		},
		DefaultSecretPolicy(),
	)
	if err == nil {
		t.Fatal("expected required secret validation error")
	}
	if err != ErrSecretWeakDefault {
		t.Fatalf("expected ErrSecretWeakDefault, got %v", err)
	}
}
