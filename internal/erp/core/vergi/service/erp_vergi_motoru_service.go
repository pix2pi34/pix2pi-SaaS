package service

import (
	"fmt"

	vergidomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/domain"
)

type VergiMotoruService struct {
	kurallar []vergidomain.VergiKural
}

func NewVergiMotoruService() *VergiMotoruService {
	return &VergiMotoruService{
		kurallar: make([]vergidomain.VergiKural, 0),
	}
}

func (s *VergiMotoruService) KuralEkle(
	k vergidomain.VergiKural,
) {
	s.kurallar = append(s.kurallar, k)
}

func (s *VergiMotoruService) KuralBul(
	islemTipi string,
	kdvOrani float64,
) (*vergidomain.VergiKural, error) {
	for _, k := range s.kurallar {
		if k.IslemTipi == islemTipi && k.KdvOrani == kdvOrani {
			return &k, nil
		}
	}

	return nil, fmt.Errorf("vergi kurali bulunamadi: islemTipi=%s kdvOrani=%.2f", islemTipi, kdvOrani)
}
