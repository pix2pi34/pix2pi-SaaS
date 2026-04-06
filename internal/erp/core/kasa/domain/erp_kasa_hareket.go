package domain

import "time"

const (
	KasaHareketTipGiris = "giris"
	KasaHareketTipCikis = "cikis"
)

type KasaHareket struct {
	HareketID       string
	KasaID          string
	HareketTip      string
	Tutar           float64
	ParaBirimi      string
	BelgeNo         string
	ReferansID      string
	Aciklama        string
	OlusturmaTarihi time.Time
}
