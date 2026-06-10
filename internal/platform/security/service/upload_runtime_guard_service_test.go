package service

import "testing"

func TestRuntimeUploadGuardProfile_Validate_Success(t *testing.T) {
	profile := DefaultDocumentUploadRuntimeProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeUploadGuardProfile_Validate_EmptyName(t *testing.T) {
	profile := DefaultDocumentUploadRuntimeProfile()
	profile.Name = ""

	err := profile.Validate()
	if err == nil {
		t.Fatal("expected empty profile name error")
	}
	if err != ErrUploadRuntimeProfileNameRequired {
		t.Fatalf("expected ErrUploadRuntimeProfileNameRequired, got %v", err)
	}
}

func TestGuardRuntimeUpload_Success(t *testing.T) {
	name, err := GuardRuntimeUpload(
		DefaultDocumentUploadRuntimeProfile(),
		RuntimeUploadInput{
			Filename:  "Invoice Final.PDF",
			MimeType:  "application/pdf",
			SizeBytes: 1024,
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if name != "invoice_final.pdf" {
		t.Fatalf("expected invoice_final.pdf, got %s", name)
	}
}

func TestGuardRuntimeUpload_TooLarge(t *testing.T) {
	profile := DefaultDocumentUploadRuntimeProfile()

	_, err := GuardRuntimeUpload(
		profile,
		RuntimeUploadInput{
			Filename:  "bigfile.pdf",
			MimeType:  "application/pdf",
			SizeBytes: profile.Policy.MaxBytes + 1,
		},
	)
	if err == nil {
		t.Fatal("expected too large error")
	}
	if err != ErrUploadTooLarge {
		t.Fatalf("expected ErrUploadTooLarge, got %v", err)
	}
}

func TestGuardRuntimeUpload_ForbiddenExtension(t *testing.T) {
	_, err := GuardRuntimeUpload(
		DefaultDocumentUploadRuntimeProfile(),
		RuntimeUploadInput{
			Filename:  "payload.php",
			MimeType:  "application/pdf",
			SizeBytes: 100,
		},
	)
	if err == nil {
		t.Fatal("expected forbidden extension error")
	}
	if err != ErrUploadExtensionForbidden {
		t.Fatalf("expected ErrUploadExtensionForbidden, got %v", err)
	}
}

func TestGuardRuntimeUpload_MimeTypeNotAllowed(t *testing.T) {
	_, err := GuardRuntimeUpload(
		DefaultDocumentUploadRuntimeProfile(),
		RuntimeUploadInput{
			Filename:  "image.png",
			MimeType:  "application/x-msdownload",
			SizeBytes: 100,
		},
	)
	if err == nil {
		t.Fatal("expected mime type not allowed error")
	}
	if err != ErrUploadMimeTypeNotAllowed {
		t.Fatalf("expected ErrUploadMimeTypeNotAllowed, got %v", err)
	}
}

func TestGuardRuntimeUpload_InvalidProfilePolicy(t *testing.T) {
	profile := DefaultDocumentUploadRuntimeProfile()
	profile.Policy.MaxBytes = 0

	_, err := GuardRuntimeUpload(
		profile,
		RuntimeUploadInput{
			Filename:  "invoice.pdf",
			MimeType:  "application/pdf",
			SizeBytes: 100,
		},
	)
	if err == nil {
		t.Fatal("expected invalid policy error")
	}
	if err != ErrUploadPolicyInvalid {
		t.Fatalf("expected ErrUploadPolicyInvalid, got %v", err)
	}
}
