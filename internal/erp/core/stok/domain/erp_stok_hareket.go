package domain

import "time"

const (
	StokHareketTipGiris = "giris"
	StokHareketTipCikis = "cikis"
)

type StokHareket struct {
	HareketID       string
	UrunID          string
	HareketTip      string
	Miktar          float64
	BirimMaliyet    float64
	BelgeNo         string
	ReferansID      string
	Aciklama        string
	OlusturmaTarihi time.Time
}
