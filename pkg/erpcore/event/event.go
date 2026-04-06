package event

type Event struct {
	ID      string
	Type    string
	Payload any
}

type EventBus struct{}

func NewEventBus() *EventBus {
	return &EventBus{}
}

func (e *EventBus) Publish(ev Event) {
	// Event publishing logic
}
