package service

import (
	"encoding/json"
	"fmt"

	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/ufk/domain"
)

type SatisEvent struct {
	FaturaNo string  `json:"fatura_no"`
	Tutar    float64 `json:"tutar"`
	KDV      float64 `json:"kdv"`
}

type JournalBuilderService struct{}

func NewJournalBuilderService() *JournalBuilderService {
	return &JournalBuilderService{}
}

func (s *JournalBuilderService) SatisEventindenFisOlustur(
	payload string,
) ([]journaldomain.JournalLine, error) {

	var event SatisEvent

	err := json.Unmarshal([]byte(payload), &event)
	if err != nil {
		return nil, fmt.Errorf("event parse hatasi")
	}

	netTutar := event.Tutar
	kdv := event.KDV

	satirlar := []journaldomain.JournalLine{

		{
			HesapKodu: "120",
			Borc:      netTutar + kdv,
			Alacak:    0,
			Aciklama:  "Alıcılar",
		},

		{
			HesapKodu: "600",
			Borc:      0,
			Alacak:    netTutar,
			Aciklama:  "Yurtiçi satışlar",
		},

		{
			HesapKodu: "391",
			Borc:      0,
			Alacak:    kdv,
			Aciklama:  "Hesaplanan KDV",
		},
	}

	return satirlar, nil
}
