package domain

type WalletTransfer struct {
	TransferID     string
	FromAccountID  string
	ToAccountID    string
	Amount         float64
	Currency       string
	Description    string
}
