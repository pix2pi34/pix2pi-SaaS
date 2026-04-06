package domain

import "time"

type LedgerPosting struct {
	PostingID     string
	JournalID     string
	EventID       string
	DocumentNo    string
	ReferenceID   string
	SourceModule  string
	AccountCode   string
	Debit         float64
	Credit        float64
	PostingDate   time.Time
}
