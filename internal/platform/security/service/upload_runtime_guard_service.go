package service

import (
	"errors"
	"strings"
)

var (
	ErrUploadRuntimeProfileNameRequired = errors.New("security: upload runtime profile name required")
)

type RuntimeUploadGuardProfile struct {
	Name   string
	Policy UploadPayloadPolicy
}

func (p RuntimeUploadGuardProfile) Validate() error {
	if strings.TrimSpace(p.Name) == "" {
		return ErrUploadRuntimeProfileNameRequired
	}

	if err := p.Policy.Validate(); err != nil {
		return err
	}

	return nil
}

type RuntimeUploadInput struct {
	Filename  string
	MimeType  string
	SizeBytes int64
}

func GuardRuntimeUpload(
	profile RuntimeUploadGuardProfile,
	input RuntimeUploadInput,
) (string, error) {
	if err := profile.Validate(); err != nil {
		return "", err
	}

	return ValidateUploadPayload(
		UploadPayloadInput{
			Filename:  input.Filename,
			MimeType:  input.MimeType,
			SizeBytes: input.SizeBytes,
		},
		profile.Policy,
	)
}

func DefaultDocumentUploadRuntimeProfile() RuntimeUploadGuardProfile {
	return RuntimeUploadGuardProfile{
		Name:   "default_document_upload_runtime_guard",
		Policy: DefaultUploadPayloadPolicy(),
	}
}
