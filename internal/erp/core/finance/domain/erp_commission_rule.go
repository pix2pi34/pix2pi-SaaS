package domain

import "time"

type CommissionRule struct {
	RuleID        string
	Version       int
	MerchantType  string
	Channel       string
	CommissionRate float64
	ValidFrom     time.Time
	ValidTo       time.Time
	Active        bool
}

type CommissionRuleQuery struct {
	MerchantType string
	Channel      string
	At           time.Time
}
