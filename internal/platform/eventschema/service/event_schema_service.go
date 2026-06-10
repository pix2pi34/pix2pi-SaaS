package service

import (
	"encoding/json"
	"fmt"
	"strings"
	"sync"

	schemadomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/domain"
)

type EventSchemaService struct {
	mu          sync.RWMutex
	sozlesmeler map[string]schemadomain.EventSozlesme
}

func NewEventSchemaService() *EventSchemaService {
	return &EventSchemaService{
		sozlesmeler: make(map[string]schemadomain.EventSozlesme),
	}
}

func temizZorunluAlanlar(alanlar []string) []string {
	sonuc := make([]string, 0)

	for _, alan := range alanlar {
		temiz := strings.TrimSpace(alan)
		if temiz == "" {
			continue
		}
		sonuc = append(sonuc, temiz)
	}

	return sonuc
}

func (s *EventSchemaService) SozlesmeKaydet(
	sozlesme schemadomain.EventSozlesme,
) error {
	if sozlesme.Topic == "" {
		return fmt.Errorf("topic zorunlu")
	}
	if sozlesme.SozlesmeAdi == "" {
		return fmt.Errorf("sozlesme adi zorunlu")
	}
	if sozlesme.SozlesmeVersiyonu == 0 {
		return fmt.Errorf("sozlesme versiyonu zorunlu")
	}

	sozlesme.ZorunluAlanlar = temizZorunluAlanlar(sozlesme.ZorunluAlanlar)

	s.mu.Lock()
	defer s.mu.Unlock()

	s.sozlesmeler[sozlesme.Topic] = sozlesme
	return nil
}

func (s *EventSchemaService) SozlesmeGetir(
	topic string,
) (schemadomain.EventSozlesme, error) {
	if topic == "" {
		return schemadomain.EventSozlesme{}, fmt.Errorf("topic zorunlu")
	}

	s.mu.RLock()
	sozlesme, varMi := s.sozlesmeler[topic]
	s.mu.RUnlock()

	if !varMi {
		return schemadomain.EventSozlesme{}, fmt.Errorf("event sozlesmesi bulunamadi")
	}

	return sozlesme, nil
}

func zorunluAlanVarMi(veri map[string]any, alan string) bool {
	deger, varMi := veri[alan]
	if !varMi {
		return false
	}
	if deger == nil {
		return false
	}

	if yazi, ok := deger.(string); ok {
		return strings.TrimSpace(yazi) != ""
	}

	return true
}

func (s *EventSchemaService) Dogrula(
	topic string,
	payload string,
) (schemadomain.EventSozlesme, error) {
	sozlesme, err := s.SozlesmeGetir(topic)
	if err != nil {
		return schemadomain.EventSozlesme{}, err
	}

	if strings.TrimSpace(payload) == "" {
		return schemadomain.EventSozlesme{}, fmt.Errorf("payload zorunlu")
	}

	var veri map[string]any
	if err := json.Unmarshal([]byte(payload), &veri); err != nil {
		return schemadomain.EventSozlesme{}, fmt.Errorf("payload json object olmali")
	}

	for _, alan := range sozlesme.ZorunluAlanlar {
		if !zorunluAlanVarMi(veri, alan) {
			return schemadomain.EventSozlesme{}, fmt.Errorf("zorunlu alan eksik: %s", alan)
		}
	}

	return sozlesme, nil
}
