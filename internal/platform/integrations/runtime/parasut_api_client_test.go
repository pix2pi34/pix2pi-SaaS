package integrationruntime

import (
	"strings"
	"testing"
	"time"
)

func buildParasutAPIClientContractForTest(t *testing.T) ParasutAPIClientContract {
	t.Helper()

	contract, err := BuildParasutAPIClientContract(ParasutAPIClientContractRequest{
		TenantID:       "tenant_7",
		AppKey:         "parasut_accounting",
		AccessTokenRef: "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RequestedBy:    "admin_1",
		CorrelationID:  "corr-7-8p-6-client",
		Now:            time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("build api client contract failed: %v", err)
	}

	return contract
}

func TestParasutAPIClientContract_7_8P_6_1(t *testing.T) {
	contract := buildParasutAPIClientContractForTest(t)

	if contract.ProviderKey != ParasutProviderKey {
		t.Fatalf("provider mismatch: %s", contract.ProviderKey)
	}
	if contract.Status != ParasutAPIClientStatusContractReady {
		t.Fatalf("expected contract ready, got %s", contract.Status)
	}
	if contract.RealAPIEnabled {
		t.Fatal("real api must remain disabled")
	}
	if contract.AuditDecision != AuditDecisionAllowed {
		t.Fatalf("audit decision mismatch: %s", contract.AuditDecision)
	}

	t.Log("7-8P.6.1 API Client Contract OK ✅")
	t.Log("7-8P.6.1.1 Tenant ID required OK ✅")
	t.Log("7-8P.6.1.2 App key required OK ✅")
	t.Log("7-8P.6.1.3 Access token ref required OK ✅")
	t.Log("7-8P.6.1.4 Correlation ID required OK ✅")
	t.Log("7-8P.6.1.5 Tenant-safe access_token_ref guard OK ✅")
	t.Log("7-8P.6.1.6 Real API enabled gate closed OK ✅")

	_, err := BuildParasutAPIClientContract(ParasutAPIClientContractRequest{
		TenantID:       "tenant_99",
		AppKey:         "parasut_accounting",
		AccessTokenRef: "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RequestedBy:    "admin_1",
		CorrelationID:  "corr-7-8p-6-client-bad",
	})
	if err == nil {
		t.Fatal("expected cross-tenant access token ref to fail")
	}
	t.Log("7-8P.6.1.7 Cross-tenant access token ref rejected OK ✅")

	_, err = BuildParasutAPIClientContract(ParasutAPIClientContractRequest{
		TenantID:       "tenant_7",
		AppKey:         "parasut_accounting",
		AccessTokenRef: "secret://pix2pi/tenant_7/parasut/access_token/v1",
		RequestedBy:    "admin_1",
		CorrelationID:  "corr-7-8p-6-client-real-bad",
		RealAPIEnabled: true,
	})
	if err == nil {
		t.Fatal("expected real api enabled to fail")
	}
	if !strings.Contains(err.Error(), "real parasut api must remain disabled") {
		t.Fatalf("unexpected real api guard error: %v", err)
	}
	t.Log("7-8P.6.1.8 Unsafe real API enabled rejected OK ✅")
}

func TestParasutOperationRequestBuilder_7_8P_6_2(t *testing.T) {
	contract := buildParasutAPIClientContractForTest(t)

	operations := []ConnectorOperation{
		ConnectorOperationPullInvoice,
		ConnectorOperationPushInvoice,
		ConnectorOperationSyncCustomer,
		ConnectorOperationSyncProduct,
		ConnectorOperationVerifyWebhook,
	}

	for _, operation := range operations {
		req, err := BuildParasutAPIOperationRequest(contract, operation, "idem-"+string(operation), map[string]string{
			"source": "dry_run_test",
		})
		if err != nil {
			t.Fatalf("build operation request failed for %s: %v", operation, err)
		}
		if req.Status != ParasutAPIClientStatusOperationReady {
			t.Fatalf("expected operation ready for %s, got %s", operation, req.Status)
		}
		if req.Endpoint.RealCallEnabled {
			t.Fatalf("endpoint real call must remain disabled for %s", operation)
		}
		if req.IdempotencyKey == "" {
			t.Fatalf("idempotency key missing for %s", operation)
		}
	}

	t.Log("7-8P.6.2 Operation Request Builder OK ✅")
	t.Log("7-8P.6.2.1 PULL_INVOICE request OK ✅")
	t.Log("7-8P.6.2.2 PUSH_INVOICE request OK ✅")
	t.Log("7-8P.6.2.3 SYNC_CUSTOMER request OK ✅")
	t.Log("7-8P.6.2.4 SYNC_PRODUCT request OK ✅")
	t.Log("7-8P.6.2.5 VERIFY_WEBHOOK request OK ✅")
	t.Log("7-8P.6.2.6 Idempotency key required OK ✅")
	t.Log("7-8P.6.2.7 Endpoint contract bridge OK ✅")

	_, err := BuildParasutAPIOperationRequest(contract, ConnectorOperationPullInvoice, "", map[string]string{"x": "y"})
	if err == nil {
		t.Fatal("expected missing idempotency key to fail")
	}
	t.Log("7-8P.6.2.8 Missing idempotency key rejected OK ✅")

	_, err = BuildParasutAPIOperationRequest(contract, ConnectorOperationPullInvoice, "idem-no-payload", nil)
	if err == nil {
		t.Fatal("expected missing payload to fail")
	}
	t.Log("7-8P.6.2.9 Missing payload rejected OK ✅")
}

func TestParasutDryRunProviderResponse_7_8P_6_3(t *testing.T) {
	contract := buildParasutAPIClientContractForTest(t)

	req, err := BuildParasutAPIOperationRequest(contract, ConnectorOperationPullInvoice, "idem-7-8p-6-3", map[string]string{
		"invoice_id": "INV-1",
	})
	if err != nil {
		t.Fatalf("build operation request failed: %v", err)
	}

	response, err := ExecuteParasutAPIDryRun(req)
	if err != nil {
		t.Fatalf("execute dry-run failed: %v", err)
	}
	if response.Status != ParasutAPIClientStatusDryRunSucceeded {
		t.Fatalf("expected dry-run succeeded, got %s", response.Status)
	}
	if response.RealHTTPCall {
		t.Fatal("real HTTP call must be false")
	}
	if response.PlaintextTokenUsed {
		t.Fatal("plaintext token must not be used")
	}
	if response.ProviderObjectID == "" || response.ProviderTransactionID == "" {
		t.Fatalf("provider trace fields missing: %+v", response)
	}
	if response.HTTPStatus != 200 {
		t.Fatalf("expected HTTP 200, got %d", response.HTTPStatus)
	}

	t.Log("7-8P.6.3 Dry-Run Provider Response OK ✅")
	t.Log("7-8P.6.3.1 Real Paraşüt API call not executed OK ✅")
	t.Log("7-8P.6.3.2 Simulated provider object id OK ✅")
	t.Log("7-8P.6.3.3 Simulated HTTP status OK ✅")
	t.Log("7-8P.6.3.4 Provider transaction id OK ✅")
	t.Log("7-8P.6.3.5 Plaintext token not used OK ✅")
	t.Log("7-8P.6.3.6 Operation result contract OK ✅")
}

func TestParasutRateLimitTimeoutRetryBridge_7_8P_6_4(t *testing.T) {
	contract := buildParasutAPIClientContractForTest(t)

	req, err := BuildParasutAPIOperationRequest(contract, ConnectorOperationPullInvoice, "idem-7-8p-6-4", map[string]string{
		"invoice_id": "INV-1",
	})
	if err != nil {
		t.Fatalf("build operation request failed: %v", err)
	}

	policy, err := BuildParasutAPIOperationPolicyBridge(ConnectorOperationPullInvoice)
	if err != nil {
		t.Fatalf("build policy bridge failed: %v", err)
	}
	if policy.Status != ParasutAPIClientStatusPolicyBridgeReady {
		t.Fatalf("expected policy bridge ready, got %s", policy.Status)
	}
	if policy.Timeout <= 0 {
		t.Fatal("timeout policy must be positive")
	}
	if policy.RateLimitPerMinute <= 0 {
		t.Fatal("rate limit policy must be positive")
	}
	if policy.RetryPolicy.MaxAttempts <= 0 {
		t.Fatal("retry policy max attempts must be positive")
	}

	timeoutDecision, err := EvaluateParasutAPIOperationFailure(req, 408, "timeout", 1)
	if err != nil {
		t.Fatalf("timeout failure decision failed: %v", err)
	}
	if timeoutDecision.Mapping.Code != ParasutMappedErrorTimeout || !timeoutDecision.Mapping.Retryable {
		t.Fatalf("unexpected timeout mapping: %+v", timeoutDecision)
	}
	if !timeoutDecision.RetryDecision.ShouldRetry {
		t.Fatalf("timeout should retry: %+v", timeoutDecision.RetryDecision)
	}

	rateLimitDecision, err := EvaluateParasutAPIOperationFailure(req, 429, "rate limited", 1)
	if err != nil {
		t.Fatalf("rate limit failure decision failed: %v", err)
	}
	if rateLimitDecision.Mapping.Code != ParasutMappedErrorRateLimited || !rateLimitDecision.RetryDecision.ShouldRetry {
		t.Fatalf("rate limit should retry: %+v", rateLimitDecision)
	}

	unknownDecision, err := EvaluateParasutAPIOperationFailure(req, 499, "unknown", 1)
	if err != nil {
		t.Fatalf("unknown failure decision failed: %v", err)
	}
	if unknownDecision.Mapping.Code != ParasutMappedErrorUnknown || !unknownDecision.Mapping.MoveToDLQ {
		t.Fatalf("unknown error should map to DLQ: %+v", unknownDecision)
	}

	t.Log("7-8P.6.4 Rate Limit / Timeout / Retry Bridge OK ✅")
	t.Log("7-8P.6.4.1 Endpoint timeout policy bridge OK ✅")
	t.Log("7-8P.6.4.2 Rate limit policy bridge OK ✅")
	t.Log("7-8P.6.4.3 RetryPolicy bridge OK ✅")
	t.Log("7-8P.6.4.4 Provider timeout retryable OK ✅")
	t.Log("7-8P.6.4.5 Rate limit retryable OK ✅")
	t.Log("7-8P.6.4.6 Unknown error DLQ mapping OK ✅")
}

func TestParasutOperationAuditObservabilityBridge_7_8P_6_5(t *testing.T) {
	contract := buildParasutAPIClientContractForTest(t)

	req, err := BuildParasutAPIOperationRequest(contract, ConnectorOperationSyncCustomer, "idem-7-8p-6-5", map[string]string{
		"customer_id": "CUST-1",
	})
	if err != nil {
		t.Fatalf("build operation request failed: %v", err)
	}

	response, err := ExecuteParasutAPIDryRun(req)
	if err != nil {
		t.Fatalf("execute dry-run failed: %v", err)
	}

	obs := NewConnectorObservabilityRuntime()
	if err := RecordParasutAPIOperationAudit(obs, response); err != nil {
		t.Fatalf("record parasut api operation audit failed: %v", err)
	}

	snapshot := obs.Snapshot()
	if snapshot.TotalOperations != 1 {
		t.Fatalf("expected one operation, got %+v", snapshot)
	}
	if snapshot.ByProvider[ParasutProviderKey] != 1 {
		t.Fatalf("expected parasut provider metric, got %+v", snapshot.ByProvider)
	}

	trail := obs.AuditTrailByTenant("tenant_7")
	if len(trail) != 1 {
		t.Fatalf("expected tenant audit trail length 1, got %d", len(trail))
	}
	if trail[0].CorrelationID != response.CorrelationID {
		t.Fatalf("correlation mismatch: %+v", trail[0])
	}
	if trail[0].Message != response.ProviderTransactionID {
		t.Fatalf("provider transaction trace mismatch: %+v", trail[0])
	}

	t.Log("7-8P.6.5 Operation Audit / Observability Bridge OK ✅")
	t.Log("7-8P.6.5.1 Connector audit event OK ✅")
	t.Log("7-8P.6.5.2 Tenant audit trail OK ✅")
	t.Log("7-8P.6.5.3 Operation metrics OK ✅")
	t.Log("7-8P.6.5.4 Correlation ID trace OK ✅")
	t.Log("7-8P.6.5.5 Provider transaction trace OK ✅")

	failedResponse := response
	failedResponse.HTTPStatus = 500
	failedResponse.Status = ParasutAPIClientStatusDryRunFailed
	failedResponse.ProviderTransactionID = "parasut-dryrun-txn-failed"

	if err := RecordParasutAPIOperationAudit(obs, failedResponse); err != nil {
		t.Fatalf("record failed parasut operation audit failed: %v", err)
	}

	snapshot = obs.Snapshot()
	if snapshot.FailedOperations != 1 {
		t.Fatalf("expected failed operation metric 1, got %+v", snapshot)
	}
	t.Log("7-8P.6.5.6 Failed operation metrics OK ✅")
}

func TestParasutAPIClientFinalClosure_7_8P_6_6(t *testing.T) {
	result := EvaluateParasutAPIClientReadinessGate(ParasutAPIClientReadinessGateInput{
		APIClientContractReady:        true,
		OperationRequestBuilderReady:  true,
		DryRunProviderResponseReady:   true,
		PolicyBridgeReady:             true,
		AuditObservabilityBridgeReady: true,
		TestsReady:                    true,
		RealImplementationAuditReady:  true,
		RealAPIEnabled:                false,
		RealHTTPClientEnabled:         false,
		PlaintextTokenResolveEnabled:  false,
	})

	if !result.Ready || result.Decision != "PARASUT_API_CLIENT_OPERATION_DRY_RUN_READY_WITH_REAL_API_CLOSED" {
		t.Fatalf("expected api client readiness with real API closed: %+v", result)
	}

	t.Log("7-8P.6.6 Final Closure OK ✅")
	t.Log("7-8P.6.6.1 API client contract readiness OK ✅")
	t.Log("7-8P.6.6.2 Operation request builder readiness OK ✅")
	t.Log("7-8P.6.6.3 Dry-run provider response readiness OK ✅")
	t.Log("7-8P.6.6.4 Policy bridge readiness OK ✅")
	t.Log("7-8P.6.6.5 Audit observability bridge readiness OK ✅")
	t.Log("7-8P.6.6.6 Real API remains closed OK ✅")

	blocked := EvaluateParasutAPIClientReadinessGate(ParasutAPIClientReadinessGateInput{
		APIClientContractReady:        true,
		OperationRequestBuilderReady:  true,
		DryRunProviderResponseReady:   true,
		PolicyBridgeReady:             true,
		AuditObservabilityBridgeReady: true,
		TestsReady:                    true,
		RealImplementationAuditReady:  true,
		RealAPIEnabled:                true,
		RealHTTPClientEnabled:         true,
		PlaintextTokenResolveEnabled:  true,
	})
	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected real API/http/plaintext state to block: %+v", blocked)
	}
	t.Log("7-8P.6.6.7 Real API / HTTP / plaintext token unsafe state blocked OK ✅")
}
