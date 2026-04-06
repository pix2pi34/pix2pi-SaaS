package domain

import "time"

type KasaEkstreSatir struct {
	Tarih    time.Time
	BelgeNo  string
	Aciklama string
	Giris    float64
	Cikis    float64
	Bakiye   float64
}
