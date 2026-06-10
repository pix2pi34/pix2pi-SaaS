package service

import (
	"errors"
	"path/filepath"
	"strings"
	"unicode"
)

var (
	ErrUploadPolicyInvalid         = errors.New("security: upload policy invalid")
	ErrUploadFilenameRequired      = errors.New("security: upload filename required")
	ErrUploadFilenameUnsafe        = errors.New("security: upload filename unsafe")
	ErrUploadMimeTypeRequired      = errors.New("security: upload mime type required")
	ErrUploadSizeInvalid           = errors.New("security: upload size invalid")
	ErrUploadTooLarge              = errors.New("security: upload too large")
	ErrUploadExtensionNotAllowed   = errors.New("security: upload extension not allowed")
	ErrUploadExtensionForbidden    = errors.New("security: upload extension forbidden")
	ErrUploadMimeTypeNotAllowed    = errors.New("security: upload mime type not allowed")
)

type UploadPayloadPolicy struct {
	MaxBytes            int64
	AllowedExtensions   []string
	AllowedMimeTypes    []string
	ForbiddenExtensions []string
}

func DefaultUploadPayloadPolicy() UploadPayloadPolicy {
	return UploadPayloadPolicy{
		MaxBytes: 10 * 1024 * 1024,
		AllowedExtensions: []string{
			".jpg",
			".jpeg",
			".png",
			".pdf",
			".txt",
			".csv",
		},
		AllowedMimeTypes: []string{
			"image/jpeg",
			"image/png",
			"application/pdf",
			"text/plain",
			"text/csv",
		},
		ForbiddenExtensions: []string{
			".php",
			".exe",
			".sh",
			".js",
			".bat",
			".cmd",
		},
	}
}

func (p UploadPayloadPolicy) Validate() error {
	if p.MaxBytes <= 0 {
		return ErrUploadPolicyInvalid
	}
	if len(p.AllowedExtensions) == 0 {
		return ErrUploadPolicyInvalid
	}
	if len(p.AllowedMimeTypes) == 0 {
		return ErrUploadPolicyInvalid
	}
	return nil
}

type UploadPayloadInput struct {
	Filename string
	MimeType string
	SizeBytes int64
}

func NormalizeUploadFilename(filename string) (string, error) {
	name := strings.TrimSpace(filename)
	if name == "" {
		return "", ErrUploadFilenameRequired
	}

	if strings.Contains(name, "/") || strings.Contains(name, "\\") || strings.Contains(name, "..") {
		return "", ErrUploadFilenameUnsafe
	}

	name = strings.ToLower(name)
	name = strings.ReplaceAll(name, " ", "_")

	var b strings.Builder
	for _, r := range name {
		switch {
		case unicode.IsLetter(r), unicode.IsDigit(r):
			b.WriteRune(r)
		case r == '.', r == '_', r == '-':
			b.WriteRune(r)
		default:
			return "", ErrUploadFilenameUnsafe
		}
	}

	normalized := strings.TrimSpace(b.String())
	if normalized == "" || normalized == "." || normalized == ".." {
		return "", ErrUploadFilenameUnsafe
	}
	if strings.HasPrefix(normalized, ".") {
		return "", ErrUploadFilenameUnsafe
	}
	if filepath.Ext(normalized) == "" {
		return "", ErrUploadFilenameUnsafe
	}

	return normalized, nil
}

func ValidateUploadPayload(
	input UploadPayloadInput,
	policy UploadPayloadPolicy,
) (string, error) {
	if err := policy.Validate(); err != nil {
		return "", err
	}

	normalizedName, err := NormalizeUploadFilename(input.Filename)
	if err != nil {
		return "", err
	}

	mimeType := strings.ToLower(strings.TrimSpace(input.MimeType))
	if mimeType == "" {
		return "", ErrUploadMimeTypeRequired
	}
	if input.SizeBytes < 0 {
		return "", ErrUploadSizeInvalid
	}
	if input.SizeBytes > policy.MaxBytes {
		return "", ErrUploadTooLarge
	}

	ext := strings.ToLower(filepath.Ext(normalizedName))
	if ext == "" {
		return "", ErrUploadFilenameUnsafe
	}

	for _, forbidden := range policy.ForbiddenExtensions {
		if ext == strings.ToLower(strings.TrimSpace(forbidden)) {
			return "", ErrUploadExtensionForbidden
		}
	}

	allowedExt := false
	for _, allowed := range policy.AllowedExtensions {
		if ext == strings.ToLower(strings.TrimSpace(allowed)) {
			allowedExt = true
			break
		}
	}
	if !allowedExt {
		return "", ErrUploadExtensionNotAllowed
	}

	allowedMime := false
	for _, allowed := range policy.AllowedMimeTypes {
		if mimeType == strings.ToLower(strings.TrimSpace(allowed)) {
			allowedMime = true
			break
		}
	}
	if !allowedMime {
		return "", ErrUploadMimeTypeNotAllowed
	}

	return normalizedName, nil
}
