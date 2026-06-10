# Event Platform Final Suite Run 1

- Tarih: 2026-04-18 09:50:29 +0300
- Root: /root/pix2pi/pix2pi-SaaS
- Tum test dosyalari: 27
- Paket sayisi: 4
- Gecen paket: 4
- Kalan paket: 0

## Suite Matrix

- PKG: ././cmd/api-gateway
- TESTS:
- - TestS2SRoutesEndpointReturnsScopedAuthMetadata
- FILES:
- - ./cmd/api-gateway/gateway_s2s_policy_test.go
- 
- PKG: ././cmd/user-created-consumer
- TESTS:
- - TestParseUserCreated_MissingUserID
- - TestParseUserCreated_OK
- FILES:
- - ./cmd/user-created-consumer/user_created_consumer_main_test.go
- 
- PKG: ././internal/platform
- TESTS:
- - TestDLQ_Send
- - TestIdempotencyStore_AlreadyProcessed_BeforeMark
- - TestIdempotencyStore_KeyHasTTL
- - TestIdempotencyStore_MarkProcessed_ThenAlreadyProcessed
- - TestRetryPolicy_CanRetry
- - TestRetryPolicy_DelayFor_Backoff
- - TestRetryPolicy_DelayFor_FirstAttempt
- FILES:
- - ./internal/platform/dlq_test.go
- - ./internal/platform/idempotency_test.go
- - ./internal/platform/retry_test.go
- 
- PKG: ././test/internal/finance/test/ledger
- TESTS:
- - TestLedgerEvents
- FILES:
- - ./test/internal/finance/test/ledger/ledger_event_test.go
- 

## Run Summary

- PASS | ././cmd/api-gateway | TestS2SRoutesEndpointReturnsScopedAuthMetadata
- PASS | ././cmd/user-created-consumer | TestParseUserCreated_MissingUserID,TestParseUserCreated_OK
- PASS | ././internal/platform | TestDLQ_Send,TestIdempotencyStore_AlreadyProcessed_BeforeMark,TestIdempotencyStore_KeyHasTTL,TestIdempotencyStore_MarkProcessed_ThenAlreadyProcessed,TestRetryPolicy_CanRetry,TestRetryPolicy_DelayFor_Backoff,TestRetryPolicy_DelayFor_FirstAttempt
- PASS | ././test/internal/finance/test/ledger | TestLedgerEvents
