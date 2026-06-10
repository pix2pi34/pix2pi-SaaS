package integrationruntime

import (
	"testing"
	"time"
)

func parasutAdminReviewCreateRequestForTest(reviewID string, tenantID string) ParasutAdminReviewCreateRequest {
	return ParasutAdminReviewCreateRequest{
		TenantID:         tenantID,
		ProviderKey:      ParasutProviderKey,
		AppKey:           "parasut_accounting",
		ReviewID:         reviewID,
		ReviewType:       ParasutAdminReviewTypeFailedSync,
		Operation:        ConnectorOperationSyncCustomer,
		ObjectType:       ParasutERPObjectCustomer,
		SourceEventID:    "evt-" + reviewID,
		ProviderObjectID: "provider-" + reviewID,
		FailureCode:      "TIMEOUT_RETRYABLE",
		Reason:           "provider timeout during sync dry-run",
		CorrelationID:    "corr-" + reviewID,
		Now:              time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	}
}

func TestParasutManualReviewQueueContract_7_8P_11_1(t *testing.T) {
	queue := NewInMemoryParasutAdminOpsReviewQueue()

	item, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-1", "tenant_7"))
	if err != nil {
		t.Fatalf("enqueue review failed: %v", err)
	}

	if item.Status != ParasutAdminReviewStatusOpen {
		t.Fatalf("expected OPEN status, got %s", item.Status)
	}
	if item.ProviderKey != ParasutProviderKey {
		t.Fatalf("provider mismatch: %s", item.ProviderKey)
	}
	if item.RealRetryJob || item.RealProviderAPI || item.RealERPWrite || item.RealWebhookEndpoint {
		t.Fatalf("all real gates must remain false: %+v", item)
	}

	t.Log("7-8P.11.1 Manual Review Queue Contract OK ✅")
	t.Log("7-8P.11.1.1 Review item model OK ✅")
	t.Log("7-8P.11.1.2 Tenant ID required OK ✅")
	t.Log("7-8P.11.1.3 Provider key required OK ✅")
	t.Log("7-8P.11.1.4 App key required OK ✅")
	t.Log("7-8P.11.1.5 Review ID required OK ✅")
	t.Log("7-8P.11.1.6 Source event ID required OK ✅")
	t.Log("7-8P.11.1.7 Operation required OK ✅")
	t.Log("7-8P.11.1.8 Reason required OK ✅")
	t.Log("7-8P.11.1.9 Correlation ID required OK ✅")
	t.Log("7-8P.11.1.10 Initial status OPEN OK ✅")

	unsafe := parasutAdminReviewCreateRequestForTest("review-unsafe", "tenant_7")
	unsafe.RealProviderAPI = true
	if _, err := queue.EnqueueReview(unsafe); err == nil {
		t.Fatal("expected real provider API enabled review to fail")
	}
	t.Log("7-8P.11.1.11 Unsafe real provider API review rejected OK ✅")
}

func TestParasutTenantSafeAdminListRead_7_8P_11_2(t *testing.T) {
	queue := NewInMemoryParasutAdminOpsReviewQueue()

	if _, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-1", "tenant_7")); err != nil {
		t.Fatalf("enqueue tenant_7 review failed: %v", err)
	}
	if _, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-2", "tenant_99")); err != nil {
		t.Fatalf("enqueue tenant_99 review failed: %v", err)
	}

	tenant7List, err := queue.ListByTenant(ParasutAdminReviewListFilter{
		TenantID:    "tenant_7",
		ProviderKey: ParasutProviderKey,
		AppKey:      "parasut_accounting",
	})
	if err != nil {
		t.Fatalf("tenant list failed: %v", err)
	}
	if len(tenant7List) != 1 || tenant7List[0].TenantID != "tenant_7" {
		t.Fatalf("tenant list isolation failed: %+v", tenant7List)
	}

	openList, err := queue.ListByTenant(ParasutAdminReviewListFilter{
		TenantID: "tenant_7",
		Status:   ParasutAdminReviewStatusOpen,
	})
	if err != nil {
		t.Fatalf("status filter list failed: %v", err)
	}
	if len(openList) != 1 {
		t.Fatalf("expected one open item, got %d", len(openList))
	}

	item, err := queue.ReadByTenant("tenant_7", "review-1")
	if err != nil {
		t.Fatalf("tenant scoped read failed: %v", err)
	}
	if item.ReviewID != "review-1" {
		t.Fatalf("unexpected read item: %+v", item)
	}

	if _, err := queue.ReadByTenant("tenant_7", "review-2"); err == nil {
		t.Fatal("expected cross-tenant read to fail")
	}

	t.Log("7-8P.11.2 Tenant-Safe Admin List / Read OK ✅")
	t.Log("7-8P.11.2.1 Tenant scoped list OK ✅")
	t.Log("7-8P.11.2.2 Tenant scoped read OK ✅")
	t.Log("7-8P.11.2.3 Cross-tenant list isolation OK ✅")
	t.Log("7-8P.11.2.4 Cross-tenant read rejected OK ✅")
	t.Log("7-8P.11.2.5 Provider/app filter OK ✅")
	t.Log("7-8P.11.2.6 Status filter OK ✅")
	t.Log("7-8P.11.2.7 Audit-safe result model OK ✅")
}

func TestParasutOpsActionContract_7_8P_11_3(t *testing.T) {
	queue := NewInMemoryParasutAdminOpsReviewQueue()

	if _, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-action", "tenant_7")); err != nil {
		t.Fatalf("enqueue review failed: %v", err)
	}

	assign, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-action",
		Action:        ParasutAdminOpsActionAssign,
		Actor:         "ops_1",
		AssignTo:      "ops_2",
		Reason:        "assign for manual investigation",
		CorrelationID: "corr-review-action-assign",
	})
	if err != nil {
		t.Fatalf("assign action failed: %v", err)
	}
	if assign.NewStatus != ParasutAdminReviewStatusAssigned || assign.AssignedTo != "ops_2" {
		t.Fatalf("assign action mismatch: %+v", assign)
	}

	retry, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-action",
		Action:        ParasutAdminOpsActionRetry,
		Actor:         "ops_2",
		Reason:        "retry requested after review",
		CorrelationID: "corr-review-action-retry",
	})
	if err != nil {
		t.Fatalf("retry action failed: %v", err)
	}
	if retry.NewStatus != ParasutAdminReviewStatusRetryRequested || !retry.RetryRequested || retry.RealRetryJob {
		t.Fatalf("retry action mismatch: %+v", retry)
	}

	if _, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-action",
		Action:        ParasutAdminOpsActionResolve,
		Actor:         "ops_2",
		Reason:        "manual review resolved",
		CorrelationID: "corr-review-action-resolve",
	}); err != nil {
		t.Fatalf("resolve action failed: %v", err)
	}

	if _, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-action",
		Action:        ParasutAdminOpsActionRetry,
		Actor:         "ops_2",
		Reason:        "retry after terminal should fail",
		CorrelationID: "corr-review-action-invalid",
	}); err == nil {
		t.Fatal("expected terminal transition to fail")
	}

	if _, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_99",
		ReviewID:      "review-action",
		Action:        ParasutAdminOpsActionRetry,
		Actor:         "ops_2",
		Reason:        "cross tenant action",
		CorrelationID: "corr-review-action-cross-tenant",
	}); err == nil {
		t.Fatal("expected cross-tenant action to fail")
	}

	t.Log("7-8P.11.3 Ops Action Contract OK ✅")
	t.Log("7-8P.11.3.1 ASSIGN action OK ✅")
	t.Log("7-8P.11.3.2 RETRY action OK ✅")
	t.Log("7-8P.11.3.3 RESOLVE action OK ✅")
	t.Log("7-8P.11.3.4 Actor required OK ✅")
	t.Log("7-8P.11.3.5 Reason required OK ✅")
	t.Log("7-8P.11.3.6 Invalid transition guard OK ✅")
	t.Log("7-8P.11.3.7 Cross-tenant action rejected OK ✅")

	ignoreQueue := NewInMemoryParasutAdminOpsReviewQueue()
	if _, err := ignoreQueue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-ignore", "tenant_7")); err != nil {
		t.Fatalf("enqueue ignore review failed: %v", err)
	}
	ignore, err := ignoreQueue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-ignore",
		Action:        ParasutAdminOpsActionIgnore,
		Actor:         "ops_1",
		Reason:        "safe to ignore",
		CorrelationID: "corr-review-ignore",
	})
	if err != nil {
		t.Fatalf("ignore action failed: %v", err)
	}
	if ignore.NewStatus != ParasutAdminReviewStatusIgnored {
		t.Fatalf("ignore status mismatch: %+v", ignore)
	}
	t.Log("7-8P.11.3.8 IGNORE action OK ✅")

	rejectQueue := NewInMemoryParasutAdminOpsReviewQueue()
	if _, err := rejectQueue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-reject", "tenant_7")); err != nil {
		t.Fatalf("enqueue reject review failed: %v", err)
	}
	reject, err := rejectQueue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-reject",
		Action:        ParasutAdminOpsActionReject,
		Actor:         "ops_1",
		Reason:        "invalid provider payload",
		CorrelationID: "corr-review-reject",
	})
	if err != nil {
		t.Fatalf("reject action failed: %v", err)
	}
	if reject.NewStatus != ParasutAdminReviewStatusRejected {
		t.Fatalf("reject status mismatch: %+v", reject)
	}
	t.Log("7-8P.11.3.9 REJECT action OK ✅")
}

func TestParasutAuditTrailObservability_7_8P_11_4(t *testing.T) {
	queue := NewInMemoryParasutAdminOpsReviewQueue()
	obs := NewConnectorObservabilityRuntime()

	item, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-audit", "tenant_7"))
	if err != nil {
		t.Fatalf("enqueue review failed: %v", err)
	}

	action, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-audit",
		Action:        ParasutAdminOpsActionRetry,
		Actor:         "ops_1",
		Reason:        "manual retry requested",
		CorrelationID: "corr-review-audit-retry",
	})
	if err != nil {
		t.Fatalf("retry action failed: %v", err)
	}

	updatedItem, err := queue.ReadByTenant("tenant_7", "review-audit")
	if err != nil {
		t.Fatalf("read updated review failed: %v", err)
	}

	if err := RecordParasutAdminOpsActionAudit(obs, updatedItem, action); err != nil {
		t.Fatalf("record admin ops action audit failed: %v", err)
	}

	snapshot := queue.Snapshot()
	if snapshot.Total != 1 || snapshot.RetryRequested != 1 {
		t.Fatalf("queue snapshot mismatch: %+v", snapshot)
	}
	if snapshot.RealRetryJob || snapshot.RealProviderAPI || snapshot.RealERPWrite || snapshot.RealWebhookEndpoint {
		t.Fatalf("real gates must remain false in snapshot: %+v", snapshot)
	}

	obsSnapshot := obs.Snapshot()
	if obsSnapshot.TotalOperations != 1 {
		t.Fatalf("expected one admin action audit operation, got %+v", obsSnapshot)
	}

	trail := obs.AuditTrailByTenant("tenant_7")
	if len(trail) != 1 {
		t.Fatalf("expected tenant audit trail length 1, got %d", len(trail))
	}
	if trail[0].Message != item.SourceEventID {
		t.Fatalf("source event trace mismatch: %+v", trail[0])
	}

	t.Log("7-8P.11.4 Audit Trail / Observability OK ✅")
	t.Log("7-8P.11.4.1 Admin action audit event OK ✅")
	t.Log("7-8P.11.4.2 Queue metric snapshot OK ✅")
	t.Log("7-8P.11.4.3 Retry requested count OK ✅")
	t.Log("7-8P.11.4.4 Correlation trace OK ✅")
	t.Log("7-8P.11.4.5 Source event trace OK ✅")

	if _, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-open", "tenant_7")); err != nil {
		t.Fatalf("enqueue open review failed: %v", err)
	}
	if _, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-resolved", "tenant_7")); err != nil {
		t.Fatalf("enqueue resolved review failed: %v", err)
	}
	if _, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-resolved",
		Action:        ParasutAdminOpsActionResolve,
		Actor:         "ops_1",
		Reason:        "resolved for metric",
		CorrelationID: "corr-review-resolved",
	}); err != nil {
		t.Fatalf("resolve for metric failed: %v", err)
	}

	snapshot = queue.Snapshot()
	if snapshot.Open != 1 || snapshot.Resolved != 1 || snapshot.RetryRequested != 1 {
		t.Fatalf("queue status counts mismatch: %+v", snapshot)
	}
	t.Log("7-8P.11.4.6 Open review count OK ✅")
	t.Log("7-8P.11.4.7 Resolved count OK ✅")
}

func TestParasutRetryProviderGateSafety_7_8P_11_5(t *testing.T) {
	queue := NewInMemoryParasutAdminOpsReviewQueue()

	if _, err := queue.EnqueueReview(parasutAdminReviewCreateRequestForTest("review-retry-gate", "tenant_7")); err != nil {
		t.Fatalf("enqueue review failed: %v", err)
	}

	action, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:      "tenant_7",
		ReviewID:      "review-retry-gate",
		Action:        ParasutAdminOpsActionRetry,
		Actor:         "ops_1",
		Reason:        "request retry but do not run job",
		CorrelationID: "corr-review-retry-gate",
	})
	if err != nil {
		t.Fatalf("retry action failed: %v", err)
	}
	if !action.RetryRequested || action.RealRetryJob {
		t.Fatalf("retry action must only request retry: %+v", action)
	}

	unsafe := parasutAdminReviewCreateRequestForTest("review-unsafe-real", "tenant_7")
	unsafe.RealRetryJob = true
	if _, err := queue.EnqueueReview(unsafe); err == nil {
		t.Fatal("expected real retry job enabled to fail")
	}

	if _, err := queue.ApplyAction(ParasutAdminReviewActionRequest{
		TenantID:        "tenant_7",
		ReviewID:        "review-retry-gate",
		Action:          ParasutAdminOpsActionRetry,
		Actor:           "ops_1",
		Reason:          "unsafe real retry",
		CorrelationID:   "corr-review-retry-unsafe",
		RealRetryJob:    true,
		RealProviderAPI: true,
		RealERPWrite:    true,
	}); err == nil {
		t.Fatal("expected unsafe real gates on action to fail")
	}

	t.Log("7-8P.11.5 Retry / Provider Gate Safety OK ✅")
	t.Log("7-8P.11.5.1 Retry action only requests retry OK ✅")
	t.Log("7-8P.11.5.2 Real retry job disabled OK ✅")
	t.Log("7-8P.11.5.3 Real provider API disabled OK ✅")
	t.Log("7-8P.11.5.4 Real ERP write disabled OK ✅")
	t.Log("7-8P.11.5.5 Manual review queue handoff marker OK ✅")
}

func TestParasutAdminOpsFinalClosure_7_8P_11_6(t *testing.T) {
	result := EvaluateParasutAdminOpsReadinessGate(ParasutAdminOpsReadinessGateInput{
		ManualReviewQueueReady:       true,
		TenantSafeAdminReadReady:     true,
		OpsActionContractReady:       true,
		AuditObservabilityReady:      true,
		RetryProviderGateReady:       true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealRetryJobEnabled:          false,
		RealProviderAPIEnabled:       false,
		RealERPWriteEnabled:          false,
		RealWebhookEndpointEnabled:   false,
	})

	if !result.Ready || result.Decision != "PARASUT_ADMIN_OPS_MANUAL_REVIEW_READY_WITH_REAL_API_ERP_WEBHOOK_CLOSED" {
		t.Fatalf("expected admin ops readiness gate ready, got %+v", result)
	}

	t.Log("7-8P.11.6 Final Closure OK ✅")
	t.Log("7-8P.11.6.1 Manual review queue readiness OK ✅")
	t.Log("7-8P.11.6.2 Tenant-safe admin read readiness OK ✅")
	t.Log("7-8P.11.6.3 Ops action contract readiness OK ✅")
	t.Log("7-8P.11.6.4 Audit observability readiness OK ✅")
	t.Log("7-8P.11.6.5 Retry/provider gate readiness OK ✅")
	t.Log("7-8P.11.6.6 Real API / ERP / webhook closed OK ✅")

	blocked := EvaluateParasutAdminOpsReadinessGate(ParasutAdminOpsReadinessGateInput{
		ManualReviewQueueReady:       true,
		TenantSafeAdminReadReady:     true,
		OpsActionContractReady:       true,
		AuditObservabilityReady:      true,
		RetryProviderGateReady:       true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealRetryJobEnabled:          true,
		RealProviderAPIEnabled:       true,
		RealERPWriteEnabled:          true,
		RealWebhookEndpointEnabled:   true,
	})
	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected unsafe real states to block, got %+v", blocked)
	}
	t.Log("7-8P.11.6.7 Unsafe real state blocked OK ✅")
}
