package rule

type RuleEngine struct{}

func NewRuleEngine() *RuleEngine {
	return &RuleEngine{}
}

func (r *RuleEngine) Apply(rules map[string]any) error {
	// Kurallar burada çalıştırılacak
	return nil
}
