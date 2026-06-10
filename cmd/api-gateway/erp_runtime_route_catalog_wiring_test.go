package main

import (
	"net/http"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
)

func TestGatewayRouteRulesIncludesERPRuntimeRoute(t *testing.T) {
	rules := gatewayRouteRules()

	found := false

	for _, rule := range rules {
		if rule.Path != apisurface.RuntimeFlowAPIPath {
			continue
		}

		found = true

		if rule.Name != apisurface.RuntimeFlowAPIRouteName {
			t.Fatalf("expected route name %s, got %s", apisurface.RuntimeFlowAPIRouteName, rule.Name)
		}

		if rule.Scope != routeScopeProtected {
			t.Fatalf("expected protected scope, got %s", rule.Scope)
		}

		if !rule.AuthRequired {
			t.Fatal("expected auth required")
		}

		if !rule.TenantRequired {
			t.Fatal("expected tenant required")
		}

		if rule.Prefix {
			t.Fatal("expected exact route, prefix=false")
		}

		if len(rule.Methods) != 1 || rule.Methods[0] != http.MethodPost {
			t.Fatalf("expected POST method, got %#v", rule.Methods)
		}
	}

	if !found {
		t.Fatalf("ERP runtime route not found in gatewayRouteRules: %s", apisurface.RuntimeFlowAPIPath)
	}
}

func TestMatchRouteRuleFindsERPRuntimeRoute(t *testing.T) {
	rule, ok := matchRouteRule(apisurface.RuntimeFlowAPIPath)
	if !ok {
		t.Fatalf("expected matchRouteRule to find ERP runtime route: %s", apisurface.RuntimeFlowAPIPath)
	}

	if rule.Name != apisurface.RuntimeFlowAPIRouteName {
		t.Fatalf("expected route name %s, got %s", apisurface.RuntimeFlowAPIRouteName, rule.Name)
	}

	if rule.Scope != routeScopeProtected {
		t.Fatalf("expected protected scope, got %s", rule.Scope)
	}

	if !methodAllowed(rule, http.MethodPost) {
		t.Fatal("expected POST to be allowed")
	}

	if methodAllowed(rule, http.MethodGet) {
		t.Fatal("expected GET to be rejected")
	}
}
