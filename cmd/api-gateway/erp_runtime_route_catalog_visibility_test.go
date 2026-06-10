package main

import (
	"os"
	"strings"
	"testing"
)

func TestGatewayRoutesCatalogIncludesERPRuntimeVisibilitySource(t *testing.T) {
	content, err := os.ReadFile("gateway_routes.go")
	if err != nil {
		t.Fatalf("gateway_routes.go okunamadi: %v", err)
	}

	required := []string{
		`"/api/v1/erp/runtime/flows"`,
		`routeScopeProtected`,
		`"jwt+tenant"`,
		`"erp runtime flow create"`,
	}

	for _, token := range required {
		if !strings.Contains(string(content), token) {
			t.Fatalf("gateway_routes.go icinde %q bulunamadi", token)
		}
	}
}
