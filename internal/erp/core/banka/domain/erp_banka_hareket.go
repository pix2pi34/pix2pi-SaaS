package domain

import "time"

const (
	BankaHareketTipGiris = "giris"
	BankaHareketTipCikis = "cikis"
)

type BankaHareket struct {
	HareketID       string
	HesapID         string
	HareketTip      string
	Tutar           float64
	BelgeNo         string
	ReferansID      string
	Aciklama        string
	OlusturmaTarihi time.Time
}
