package domain

import "time"

type CariEkstreSatir struct {
	Tarih    time.Time
	BelgeNo  string
	Aciklama string
	Borc     float64
	Alacak   float64
	Bakiye   float64
}
