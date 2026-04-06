package middleware

import (
	"errors"
	"net/http"
)

func TenantKontrol(r *http.Request) (string, error) {

	tenantID := r.Header.Get("X-Tenant-ID")

	if tenantID == "" {
		return "", errors.New("tenant id zorunlu")
	}

	return tenantID, nil
}
