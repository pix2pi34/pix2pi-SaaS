package domain

import "time"

const (
	CariHareketTipBorc   = "borc"
	CariHareketTipAlacak = "alacak"
)

type CariHareket struct {
	HareketID    string
	HesapID      string
	HareketTip   string
	Tutar        float64
	ParaBirimi   string
	BelgeNo      string
	ReferansID   string
	Aciklama     string
	VadeTarihi   time.Time
	OlusturmaTarihi time.Time
}
