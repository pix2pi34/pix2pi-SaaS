package service

import (
	"errors"
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

var (
	ErrInputKeyRequired            = errors.New("security: input key required")
	ErrInputValueRequired          = errors.New("security: input value required")
	ErrInputMaxLengthInvalid       = errors.New("security: input max length invalid")
	ErrInputKeyInvalid             = errors.New("security: input key invalid")
	ErrHeaderKeyInvalid            = errors.New("security: header key invalid")
	ErrInputKeyNotAllowed          = errors.New("security: input key not allowed")
	ErrHeaderKeyNotAllowed         = errors.New("security: header key not allowed")
	ErrInputTooLong                = errors.New("security: input too long")
	ErrInputControlCharDetected    = errors.New("security: input control char detected")
	ErrInputInjectionRiskDetected  = errors.New("security: input injection risk detected")
)

var (
	inputKeyPattern  = regexp.MustCompile(`^[A-Za-z0-9_-]+$`)
	headerKeyPattern = regexp.MustCompile(`^[A-Za-z0-9-]+$`)
)

func ValidateInputKey(key string) error {
	key = strings.TrimSpace(key)

	if key == "" {
		return ErrInputKeyRequired
	}
	if !inputKeyPattern.MatchString(key) {
		return ErrInputKeyInvalid
	}

	return nil
}

func ValidateHeaderKey(key string) error {
	key = strings.TrimSpace(key)

	if key == "" {
		return ErrInputKeyRequired
	}
	if !headerKeyPattern.MatchString(key) {
		return ErrHeaderKeyInvalid
	}

	return nil
}

func DetectInjectionRisk(value string) bool {
	v := strings.ToLower(strings.TrimSpace(value))
	if v == "" {
		return false
	}

	suspiciousParts := []string{
		"--",
		";",
		"/*",
		"*/",
		"\x00",
		"\n",
		"\r",
		" union select",
		" drop table",
		" delete from",
		" insert into",
		" update set",
		" or 1=1",
	}

	for _, part := range suspiciousParts {
		if strings.Contains(v, part) {
			return true
		}
	}

	return false
}

func ValidateSafeInputValue(value string, maxLength int) error {
	value = strings.TrimSpace(value)

	if maxLength <= 0 {
		return ErrInputMaxLengthInvalid
	}
	if value == "" {
		return ErrInputValueRequired
	}
	if utf8.RuneCountInString(value) > maxLength {
		return ErrInputTooLong
	}

	for _, r := range value {
		if unicode.IsControl(r) {
			return ErrInputControlCharDetected
		}
	}

	if DetectInjectionRisk(value) {
		return ErrInputInjectionRiskDetected
	}

	return nil
}

func ValidateAllowedQueryParams(
	params map[string]string,
	allowedKeys []string,
	maxLength int,
) error {
	if maxLength <= 0 {
		return ErrInputMaxLengthInvalid
	}

	allowed := make(map[string]struct{}, len(allowedKeys))
	for _, key := range allowedKeys {
		normalized := strings.ToLower(strings.TrimSpace(key))
		if normalized != "" {
			allowed[normalized] = struct{}{}
		}
	}

	for key, value := range params {
		if err := ValidateInputKey(key); err != nil {
			return err
		}

		if _, ok := allowed[strings.ToLower(key)]; !ok {
			return ErrInputKeyNotAllowed
		}

		if err := ValidateSafeInputValue(value, maxLength); err != nil {
			return err
		}
	}

	return nil
}

func ValidateAllowedHeaderInputs(
	headers map[string]string,
	allowedKeys []string,
	maxLength int,
) error {
	if maxLength <= 0 {
		return ErrInputMaxLengthInvalid
	}

	allowed := make(map[string]struct{}, len(allowedKeys))
	for _, key := range allowedKeys {
		normalized := strings.ToLower(strings.TrimSpace(key))
		if normalized != "" {
			allowed[normalized] = struct{}{}
		}
	}

	for key, value := range headers {
		if err := ValidateHeaderKey(key); err != nil {
			return err
		}

		if _, ok := allowed[strings.ToLower(key)]; !ok {
			return ErrHeaderKeyNotAllowed
		}

		if err := ValidateSafeInputValue(value, maxLength); err != nil {
			return err
		}
	}

	return nil
}
