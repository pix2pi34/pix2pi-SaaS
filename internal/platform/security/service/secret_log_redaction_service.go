package service

import (
	"errors"
	"strings"
)

var (
	ErrSecretLogLeakDetected = errors.New("security: secret log leak detected")
)

const RedactedSecretValue = "[REDACTED]"

func IsSensitiveSecretKey(key string) bool {
	k := strings.ToLower(strings.TrimSpace(key))
	if k == "" {
		return false
	}

	sensitiveParts := []string{
		"secret",
		"password",
		"passwd",
		"pwd",
		"token",
		"api_key",
		"apikey",
		"private_key",
		"client_secret",
	}

	for _, part := range sensitiveParts {
		if strings.Contains(k, part) {
			return true
		}
	}

	return false
}

func RedactSecretValue(value string) string {
	if strings.TrimSpace(value) == "" {
		return ""
	}
	return RedactedSecretValue
}

func SanitizeLogFields(fields map[string]string) map[string]string {
	out := make(map[string]string, len(fields))

	for key, value := range fields {
		if IsSensitiveSecretKey(key) {
			out[key] = RedactSecretValue(value)
			continue
		}
		out[key] = value
	}

	return out
}

func SecretAppearsInLogLine(secret string, logLine string) bool {
	secret = strings.TrimSpace(secret)
	if secret == "" {
		return false
	}

	return strings.Contains(logLine, secret)
}

func ValidateNoSecretLeak(
	logLine string,
	secrets []SecretContractInput,
) error {
	for _, secret := range secrets {
		value := strings.TrimSpace(secret.Value)
		if value == "" {
			continue
		}

		if SecretAppearsInLogLine(value, logLine) {
			return ErrSecretLogLeakDetected
		}
	}

	return nil
}
