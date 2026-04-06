package erpcore

import (
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/rule"
	"github.com/divrigili/pix2pi-SaaS/pkg/erpcore/tax"
)

type UFKKernel struct {
	Rule *rule.RuleEngine
	Tax  *tax.TaxEngine
}

func NewUFK() *UFKKernel {
	return &UFKKernel{
		Rule: rule.NewRuleEngine(),
		Tax:  tax.NewTaxEngine(),
	}
}
