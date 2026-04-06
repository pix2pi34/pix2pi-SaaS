package domain

type AccountingRule struct {
	RuleID         string
	EventType      string
	PaymentMethod  string
	TaxRate        int
	Version        int
	Active         bool
	SourceModule   string
	DebitAccount   string
	RevenueAccount string
	TaxAccount     string
}

type AccountingRuleQuery struct {
	EventType     string
	PaymentMethod string
	TaxRate       int
}
