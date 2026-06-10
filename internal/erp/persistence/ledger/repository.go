package ledger

import "context"

type AccountMovementRepository interface {
	CreateAccountMovement(ctx context.Context, input CreateAccountMovementInput) (AccountMovement, error)
	GetAccountMovementByID(ctx context.Context, tenantID string, accountMovementID string) (AccountMovement, error)
	ListAccountMovements(ctx context.Context, tenantID string, filter ListAccountMovementsFilter) ([]AccountMovement, error)
}

type ListAccountMovementsFilter struct {
	AccountCode        string
	FiscalYear         int
	FiscalPeriod       string
	SourceModule       LedgerSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	Direction          MovementDirection
	Query              string
	Limit              int
	Offset             int
}

type LedgerBalanceRepository interface {
	CreateLedgerBalance(ctx context.Context, input CreateLedgerBalanceInput) (LedgerBalance, error)
	GetLedgerBalanceByID(ctx context.Context, tenantID string, ledgerBalanceID string) (LedgerBalance, error)
	ListLedgerBalances(ctx context.Context, tenantID string, filter ListLedgerBalancesFilter) ([]LedgerBalance, error)
}

type ListLedgerBalancesFilter struct {
	AccountCode    string
	FiscalYear     int
	FiscalPeriod   string
	BalanceSide    LedgerBalanceSide
	CostCenterCode string
	ProjectCode    string
	Query          string
	Limit          int
	Offset         int
}
