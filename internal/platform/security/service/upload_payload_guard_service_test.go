package service

import "testing"

func TestDefaultUploadPayloadPolicy(t *testing.T) {
	policy := DefaultUploadPayloadPolicy()

	if policy.MaxBytes <= 0 {
		t.Fatal("expected positive max bytes")
	}
	if len(policy.AllowedExtensions) == 0 {
		t.Fatal("expected allowed extensions")
	}
	if len(policy.AllowedMimeTypes) == 0 {
		t.Fatal("expected allowed mime types")
	}
	if len(policy.ForbiddenExtensions) == 0 {
		t.Fatal("expected forbidden extensions")
	}
}

func TestUploadPayloadPolicy_Validate_Invalid(t *testing.T) {
	policy := DefaultUploadPayloadPolicy()
	policy.MaxBytes = 0

	err := policy.Validate()
	if err == nil {
		t.Fatal("expected invalid policy error")
	}
	if err != ErrUploadPolicyInvalid {
		t.Fatalf("expected ErrUploadPolicyInvalid, got %v", err)
	}
}

func TestNormalizeUploadFilename_Success(t *testing.T) {
	name, err := NormalizeUploadFilename("My Report 2026.PDF")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if name != "my_report_2026.pdf" {
		t.Fatalf("expected my_report_2026.pdf, got %s", name)
	}
}

func TestNormalizeUploadFilename_UnsafePath(t *testing.T) {
	_, err := NormalizeUploadFilename("../secret.pdf")
	if err == nil {
		t.Fatal("expected unsafe filename error")
	}
	if err != ErrUploadFilenameUnsafe {
		t.Fatalf("expected ErrUploadFilenameUnsafe, got %v", err)
	}
}

func TestValidateUploadPayload_Success(t *testing.T) {
	name, err := ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  "Invoice Final.PDF",
			MimeType:  "application/pdf",
			SizeBytes: 1024,
		},
		DefaultUploadPayloadPolicy(),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if name != "invoice_final.pdf" {
		t.Fatalf("expected invoice_final.pdf, got %s", name)
	}
}

func TestValidateUploadPayload_TooLarge(t *testing.T) {
	policy := DefaultUploadPayloadPolicy()

	_, err := ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  "bigfile.pdf",
			MimeType:  "application/pdf",
			SizeBytes: policy.MaxBytes + 1,
		},
		policy,
	)
	if err == nil {
		t.Fatal("expected too large error")
	}
	if err != ErrUploadTooLarge {
		t.Fatalf("expected ErrUploadTooLarge, got %v", err)
	}
}

func TestValidateUploadPayload_ForbiddenExtension(t *testing.T) {
	_, err := ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  "payload.php",
			MimeType:  "application/pdf",
			SizeBytes: 100,
		},
		DefaultUploadPayloadPolicy(),
	)
	if err == nil {
		t.Fatal("expected forbidden extension error")
	}
	if err != ErrUploadExtensionForbidden {
		t.Fatalf("expected ErrUploadExtensionForbidden, got %v", err)
	}
}

func TestValidateUploadPayload_MimeTypeNotAllowed(t *testing.T) {
	_, err := ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  "image.png",
			MimeType:  "application/x-msdownload",
			SizeBytes: 100,
		},
		DefaultUploadPayloadPolicy(),
	)
	if err == nil {
		t.Fatal("expected mime type not allowed error")
	}
	if err != ErrUploadMimeTypeNotAllowed {
		t.Fatalf("expected ErrUploadMimeTypeNotAllowed, got %v", err)
	}
}

func TestValidateUploadPayload_ExtensionNotAllowed(t *testing.T) {
	_, err := ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  "archive.zip",
			MimeType:  "application/pdf",
			SizeBytes: 100,
		},
		DefaultUploadPayloadPolicy(),
	)
	if err == nil {
		t.Fatal("expected extension not allowed error")
	}
	if err != ErrUploadExtensionNotAllowed {
		t.Fatalf("expected ErrUploadExtensionNotAllowed, got %v", err)
	}
}

func TestValidateUploadPayload_UnsafeFilename(t *testing.T) {
	_, err := ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  "../secret.pdf",
			MimeType:  "application/pdf",
			SizeBytes: 100,
		},
		DefaultUploadPayloadPolicy(),
	)
	if err == nil {
		t.Fatal("expected unsafe filename error")
	}
	if err != ErrUploadFilenameUnsafe {
		t.Fatalf("expected ErrUploadFilenameUnsafe, got %v", err)
	}
}
