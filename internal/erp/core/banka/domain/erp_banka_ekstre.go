package domain

import "time"

type BankaEkstreSatir struct {
	Tarih    time.Time
	BelgeNo  string
	Aciklama string
	Giris    float64
	Cikis    float64
	Bakiye   float64
}
