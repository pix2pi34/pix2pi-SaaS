package domain

type MultiLedgerAccount struct {
	AccountID   string
	AccountType string
	OwnerID     string
	Currency    string
	Balance     float64
}
