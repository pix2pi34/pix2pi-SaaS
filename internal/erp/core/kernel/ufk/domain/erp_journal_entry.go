package domain

import "time"

type JournalEntry struct {
	ID          string
	Description string
	CreatedAt   time.Time
	Lines       []JournalLine
}
