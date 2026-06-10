package paymentadapter

import (
	"os"
	"strings"
	"testing"
)

func TestPostgreSQLPaymentAttemptRepositoryImplementsContract(t *testing.T) {
	var _ PaymentAttemptRepository = (*PostgreSQLPaymentAttemptRepository)(nil)
}

func TestNewPostgreSQLPaymentAttemptRepositoryRejectsNilDB(t *testing.T) {
	repo, err := NewPostgreSQLPaymentAttemptRepository(nil)
	if err == nil {
		t.Fatal("nil db must be rejected")
	}
	if repo != nil {
		t.Fatal("repo must be nil when db is nil")
	}
}

func TestPaymentAttemptPostgreSQLRequiredColumns(t *testing.T) {
	columns := PaymentAttemptPostgreSQLRequiredColumns()

	assertContainsString(t, columns, "tenant_id")
	assertContainsString(t, columns, "attempt_id")
	assertContainsString(t, columns, "idempotency_key")
	assertContainsString(t, columns, "amount_minor")
	assertContainsString(t, columns, "currency")
	assertContainsString(t, columns, "status")
}

func TestPaymentAttemptPostgreSQLTables(t *testing.T) {
	tables := PaymentAttemptPostgreSQLTables()

	assertContainsString(t, tables, "payment_attempts")
	assertContainsString(t, tables, "payment_attempt_events")
}

func TestPostgreSQLPaymentAttemptSQLStatementsContainTenantSafeClauses(t *testing.T) {
	assertSQLContains(t, insertPaymentAttemptSQL, "INSERT INTO payment_attempts")
	assertSQLContains(t, updatePaymentAttemptSQL, "WHERE tenant_id = $1 AND attempt_id = $2")
	assertSQLContains(t, selectPaymentAttemptByIDSQL, "WHERE tenant_id = $1 AND attempt_id = $2")
	assertSQLContains(t, selectPaymentAttemptByIdempotencySQL, "WHERE tenant_id = $1 AND idempotency_key = $2")
	assertSQLContains(t, insertPaymentAttemptEventSQL, "INSERT INTO payment_attempt_events")
	assertSQLContains(t, selectPaymentAttemptEventsSQL, "WHERE tenant_id = $1 AND attempt_id = $2")
}

func TestPaymentDBMigrationFileContainsTablesConstraintsAndIndexes(t *testing.T) {
	raw, err := os.ReadFile("../../../../migrations/faz7/20260501_075p4_payment_attempts.sql")
	if err != nil {
		t.Fatalf("expected migration file to be readable: %v", err)
	}

	sql := string(raw)

	assertSQLContains(t, sql, "CREATE TABLE IF NOT EXISTS payment_attempts")
	assertSQLContains(t, sql, "CREATE TABLE IF NOT EXISTS payment_attempt_events")
	assertSQLContains(t, sql, "CONSTRAINT payment_attempts_pkey PRIMARY KEY (tenant_id, attempt_id)")
	assertSQLContains(t, sql, "CONSTRAINT payment_attempts_tenant_idempotency_unique UNIQUE (tenant_id, idempotency_key)")
	assertSQLContains(t, sql, "idx_payment_attempts_tenant_provider_transaction")
	assertSQLContains(t, sql, "idx_payment_attempts_tenant_status")
	assertSQLContains(t, sql, "CONSTRAINT payment_attempt_events_attempt_fk")
	assertSQLContains(t, sql, "idx_payment_attempt_events_tenant_attempt_event")
	assertSQLContains(t, sql, "CHECK (amount_minor > 0)")
}

func TestPaymentAttemptSQLArgsPreserveTenantAndIdempotency(t *testing.T) {
	attempt := repositoryPostgresTestAttempt(t)

	args := paymentAttemptSQLArgs(attempt)
	if len(args) != 14 {
		t.Fatalf("expected 14 attempt sql args, got %d", len(args))
	}
	if args[0] != "tenant_7" {
		t.Fatalf("expected tenant_id arg, got %v", args[0])
	}
	if args[1] != "attempt_pg_001" {
		t.Fatalf("expected attempt_id arg, got %v", args[1])
	}
	if args[7] != "idem_pg_001" {
		t.Fatalf("expected idempotency key arg, got %v", args[7])
	}
	if args[8] != int64(55000) {
		t.Fatalf("expected amount_minor arg, got %v", args[8])
	}
}

func TestPaymentAttemptEventSQLArgsPreserveAuditFields(t *testing.T) {
	attempt := repositoryPostgresTestAttempt(t)
	event := attempt.Events[0]

	args := paymentAttemptEventSQLArgs(attempt.TenantID, attempt.AttemptID, event)
	if len(args) != 14 {
		t.Fatalf("expected 14 event sql args, got %d", len(args))
	}
	if args[0] != "tenant_7" {
		t.Fatalf("expected tenant_id arg, got %v", args[0])
	}
	if args[1] != "attempt_pg_001" {
		t.Fatalf("expected attempt_id arg, got %v", args[1])
	}
	if args[10] != "idem_pg_001" {
		t.Fatalf("expected idempotency key arg, got %v", args[10])
	}
	if args[11] != true {
		t.Fatalf("expected audit_required true, got %v", args[11])
	}
	if args[12] != false {
		t.Fatalf("expected real_payment false, got %v", args[12])
	}
}

func TestMapPaymentPersistenceError(t *testing.T) {
	if got := mapPaymentPersistenceError(fakePersistenceError("duplicate key violates payment_attempts_pkey")); got != ErrPaymentAttemptAlreadyExists {
		t.Fatalf("expected attempt already exists, got %v", got)
	}

	if got := mapPaymentPersistenceError(fakePersistenceError("duplicate key violates payment_attempts_tenant_idempotency_unique")); got != ErrPaymentAttemptIdempotencyConflict {
		t.Fatalf("expected idempotency conflict, got %v", got)
	}
}

type fakePersistenceError string

func (e fakePersistenceError) Error() string {
	return string(e)
}

func repositoryPostgresTestAttempt(t *testing.T) PaymentAttempt {
	t.Helper()

	attempt, err := NewPaymentAttempt(PaymentAttemptCreateRequest{
		AttemptID:      "attempt_pg_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_pg_001",
		SubscriptionID: "sub_pg_001",
		ProviderCode:   "pix2pi_simulation",
		CorrelationID:  "corr_pg_001",
		RequestID:      "req_pg_001",
		IdempotencyKey: "idem_pg_001",
		Money:          Money{AmountMinor: 55000, Currency: "TRY"},
	})
	if err != nil {
		t.Fatalf("expected postgres test payment attempt, got error: %v", err)
	}

	return attempt
}

func assertContainsString(t *testing.T, values []string, expected string) {
	t.Helper()

	for _, value := range values {
		if value == expected {
			return
		}
	}

	t.Fatalf("expected %s in list %v", expected, values)
}

func assertSQLContains(t *testing.T, sql string, expected string) {
	t.Helper()

	normalizedSQL := strings.Join(strings.Fields(sql), " ")
	normalizedExpected := strings.Join(strings.Fields(expected), " ")

	if !strings.Contains(normalizedSQL, normalizedExpected) {
		t.Fatalf("expected SQL to contain %q\nSQL: %s", normalizedExpected, normalizedSQL)
	}
}
