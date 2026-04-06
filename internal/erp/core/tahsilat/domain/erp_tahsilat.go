package domain

import "time"

type Tahsilat struct {
	TahsilatID string
	CariID     string
	Tutar      float64
	ParaBirimi string
	KasaID     string
	BankaID    string
	Aciklama   string
	Tarih      time.Time
}
