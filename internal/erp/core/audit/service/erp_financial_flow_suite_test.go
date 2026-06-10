package service_test

import (
	"context"
	"testing"

	auditservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/audit/service"
	eventservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/service"
	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
	ledgerservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/service"
	journalservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/service"
	reconciliationservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/reconciliation/service"
	ruledomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain"
	rulesservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/service"
)

type suitePostingExecutionTracker struct {
	existingKeys map[string]bool
	markCalls    int
	lastKey      string
	lastState    ledgerservice.PostingState
	lastDetail   string
}

func newSuitePostingExecutionTracker() *suitePostingExecutionTracker {
	return &suitePostingExecutionTracker{
		existingKeys: make(map[string]bool),
	}
}

func (f *suitePostingExecutionTracker) Exists(_ context.Context, executionKey string) (bool, error) {
	return f.existingKeys[executionKey], nil
}

func (f *suitePostingExecutionTracker) Mark(_ context.Context, executionKey string, state ledgerservice.PostingState, detail string) error {
	f.markCalls++
	f.lastKey = executionKey
	f.lastState = state
	f.lastDetail = detail
	f.existingKeys[executionKey] = true
	return nil
}

func buildExternalMovementsFromPostings(postings []ledgerdomain.LedgerPosting) []reconciliationservice.ExternalMovement {
	result := make([]reconciliationservice.ExternalMovement, 0, len(postings))

	for _, posting := range postings {
		amount := posting.Debit
		if amount == 0 {
			amount = posting.Credit
		}

		result = append(result, reconciliationservice.ExternalMovement{
			Source:      "suite",
			AccountCode: posting.AccountCode,
			Amount:      amount,
			ReferenceID: posting.ReferenceID,
		})
	}

	return result
}

func TestERPFinancialFlowSuite_Success(t *testing.T) {
	intakeService := eventservice.NewEventIntakeService()
	financialService := eventservice.NewFinancialEventService()
	ruleService := rulesservice.NewAccountingRuleService()
	journalBuilder := journalservice.NewJournalBuilderService()
	ledgerBuilder := ledgerservice.NewLedgerPostingService()
	reconciliationSvc := reconciliationservice.NewReconciliationService()
	consistencySvc := auditservice.NewFinancialConsistencyService()
	tracker := newSuitePostingExecutionTracker()
	safetySvc, err := ledgerservice.NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	intake, err := intakeService.Normalize(eventservice.EventIntake{
		TenantID:      "tenant_42",
		EventID:       "sale_2001",
		EventType:     "sale.created",
		SourceModule:  "pos",
		DocumentNo:    "DOC-2001",
		ReferenceID:   "REF-2001",
		PaymentMethod: "cash",
		TaxRate:       20,
		GrossAmount:   120,
		Currency:      "TRY",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if intake.EventType != "sale.completed" {
		t.Fatalf("expected sale.completed, got %s", intake.EventType)
	}

	financialEvent, err := financialService.Build(intake.ToFinancialEventInput())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	rule, err := ruleService.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     intake.EventType,
		PaymentMethod: intake.PaymentMethod,
		TaxRate:       intake.TaxRate,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	journalEntry, err := journalBuilder.Build(financialEvent, rule)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	postings, err := ledgerBuilder.BuildFromJournal(journalEntry)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	decision, err := safetySvc.Evaluate(context.Background(), ledgerservice.PostingSafetyRequest{
		TenantID:  intake.TenantID,
		EventID:   financialEvent.EventID,
		JournalID: journalEntry.JournalID,
		Replay:    false,
		Postings:  postings,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !decision.Allowed {
		t.Fatal("expected posting allowed")
	}

	if err := safetySvc.MarkRunning(context.Background(), decision); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if err := safetySvc.MarkCompleted(context.Background(), decision); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	consistency, err := consistencySvc.Check(financialEvent, journalEntry, postings)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !consistency.IsConsistent {
		t.Fatal("expected consistent flow")
	}

	reconciliation, err := reconciliationSvc.Reconcile(postings, buildExternalMovementsFromPostings(postings))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if reconciliation.MatchedCount != len(postings) {
		t.Fatalf("expected %d matches, got %d", len(postings), reconciliation.MatchedCount)
	}
}

func TestERPFinancialFlowSuite_DuplicateBlocked(t *testing.T) {
	intakeService := eventservice.NewEventIntakeService()
	financialService := eventservice.NewFinancialEventService()
	ruleService := rulesservice.NewAccountingRuleService()
	journalBuilder := journalservice.NewJournalBuilderService()
	ledgerBuilder := ledgerservice.NewLedgerPostingService()
	tracker := newSuitePostingExecutionTracker()
	safetySvc, err := ledgerservice.NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	intake, err := intakeService.Normalize(eventservice.EventIntake{
		TenantID:      "tenant_42",
		EventID:       "sale_2002",
		EventType:     "sale.completed",
		SourceModule:  "pos",
		DocumentNo:    "DOC-2002",
		ReferenceID:   "REF-2002",
		PaymentMethod: "cash",
		TaxRate:       20,
		GrossAmount:   240,
		Currency:      "TRY",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	financialEvent, err := financialService.Build(intake.ToFinancialEventInput())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	rule, err := ruleService.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     intake.EventType,
		PaymentMethod: intake.PaymentMethod,
		TaxRate:       intake.TaxRate,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	journalEntry, err := journalBuilder.Build(financialEvent, rule)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	postings, err := ledgerBuilder.BuildFromJournal(journalEntry)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	executionKey := intake.TenantID + "::" + financialEvent.EventID + "::" + journalEntry.JournalID
	tracker.existingKeys[executionKey] = true

	decision, err := safetySvc.Evaluate(context.Background(), ledgerservice.PostingSafetyRequest{
		TenantID:  intake.TenantID,
		EventID:   financialEvent.EventID,
		JournalID: journalEntry.JournalID,
		Replay:    false,
		Postings:  postings,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if decision.Allowed {
		t.Fatal("expected duplicate blocked")
	}
	if !decision.IsDuplicate {
		t.Fatal("expected duplicate true")
	}
	if decision.State != ledgerservice.PostingStateSkippedDuplicate {
		t.Fatalf("expected skipped_duplicate, got %s", decision.State)
	}
}

func TestERPFinancialFlowSuite_ReplayAccepted(t *testing.T) {
	intakeService := eventservice.NewEventIntakeService()
	financialService := eventservice.NewFinancialEventService()
	ruleService := rulesservice.NewAccountingRuleService()
	journalBuilder := journalservice.NewJournalBuilderService()
	ledgerBuilder := ledgerservice.NewLedgerPostingService()
	tracker := newSuitePostingExecutionTracker()
	safetySvc, err := ledgerservice.NewPostingSafetyService(tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	intake, err := intakeService.Normalize(eventservice.EventIntake{
		TenantID:      "tenant_42",
		EventID:       "sale_2003",
		EventType:     "sale.completed",
		SourceModule:  "pos",
		DocumentNo:    "DOC-2003",
		ReferenceID:   "REF-2003",
		PaymentMethod: "bank",
		TaxRate:       20,
		GrossAmount:   360,
		Currency:      "TRY",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	financialEvent, err := financialService.Build(intake.ToFinancialEventInput())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	rule, err := ruleService.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     intake.EventType,
		PaymentMethod: intake.PaymentMethod,
		TaxRate:       intake.TaxRate,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	journalEntry, err := journalBuilder.Build(financialEvent, rule)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	postings, err := ledgerBuilder.BuildFromJournal(journalEntry)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	executionKey := intake.TenantID + "::" + financialEvent.EventID + "::" + journalEntry.JournalID
	tracker.existingKeys[executionKey] = true

	decision, err := safetySvc.Evaluate(context.Background(), ledgerservice.PostingSafetyRequest{
		TenantID:  intake.TenantID,
		EventID:   financialEvent.EventID,
		JournalID: journalEntry.JournalID,
		Replay:    true,
		Postings:  postings,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !decision.Allowed {
		t.Fatal("expected replay allowed")
	}
	if !decision.IsDuplicate {
		t.Fatal("expected duplicate true")
	}
	if decision.State != ledgerservice.PostingStateReplayAccepted {
		t.Fatalf("expected replay_accepted, got %s", decision.State)
	}
}

func TestERPFinancialFlowSuite_RuleNotFound(t *testing.T) {
	intakeService := eventservice.NewEventIntakeService()
	ruleService := rulesservice.NewAccountingRuleService()

	intake, err := intakeService.Normalize(eventservice.EventIntake{
		TenantID:      "tenant_42",
		EventID:       "sale_2004",
		EventType:     "sale.completed",
		SourceModule:  "pos",
		DocumentNo:    "DOC-2004",
		ReferenceID:   "REF-2004",
		PaymentMethod: "crypto",
		TaxRate:       20,
		GrossAmount:   100,
		Currency:      "TRY",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = ruleService.FindRule(ruledomain.AccountingRuleQuery{
		EventType:     intake.EventType,
		PaymentMethod: intake.PaymentMethod,
		TaxRate:       intake.TaxRate,
	})
	if err == nil {
		t.Fatal("expected rule not found error")
	}
}
