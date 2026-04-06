package engine

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/domain"
	vergiengine "github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/engine"
)

type EventProcessor struct {
	vergiEngine *vergiengine.VergiTaniEngine
}

func NewEventProcessor(
	vergiEngine *vergiengine.VergiTaniEngine,
) *EventProcessor {

	return &EventProcessor{
		vergiEngine: vergiEngine,
	}
}

func (p *EventProcessor) Process(
	event eventdomain.AccountingEvent,
) {

	if event.EventType == "satis" {

		err := p.vergiEngine.SatisFaturasiJournalYazdir(
			event.EventID,
			event.ReferenceID,
			event.Tutar,
			event.KdvOrani,
		)

		if err != nil {
			fmt.Println("event islenemedi:", err)
		}

	}

}
