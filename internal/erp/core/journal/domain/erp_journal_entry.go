package domain

import "time"

type JournalLine struct {
	AccountCode string
	Debit       float64
	Credit      float64
}

type JournalEntry struct {
	JournalID    string
	EventID      string
	DocumentNo   string
	ReferenceID  string
	SourceModule string
	CreatedAt    time.Time
	Lines        []JournalLine
}
