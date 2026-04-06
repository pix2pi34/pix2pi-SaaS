package domain

import "time"

type LedgerSnapshot struct {
	SnapshotID      string
	Aciklama        string
	Hesaplar        []LedgerAccount
	OlusturmaTarihi time.Time
}
