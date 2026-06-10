package chartofaccounts

import "context"

type ChartAccountRepository interface {
	CreateChartAccount(ctx context.Context, input CreateChartAccountInput) (ChartAccount, error)
	GetChartAccountByID(ctx context.Context, tenantID string, chartAccountID string) (ChartAccount, error)
	GetChartAccountByCode(ctx context.Context, tenantID string, accountCode string) (ChartAccount, error)
	ListChartAccounts(ctx context.Context, tenantID string, filter ListChartAccountsFilter) ([]ChartAccount, error)
}

type ListChartAccountsFilter struct {
	AccountType       AccountType
	NormalBalance     NormalBalance
	ParentAccountCode string
	IsPostable        *bool
	IsActive          *bool
	Query             string
	Limit             int
	Offset            int
}

type AccountMappingRuleRepository interface {
	CreateAccountMappingRule(ctx context.Context, input CreateAccountMappingRuleInput) (AccountMappingRule, error)
	GetAccountMappingRuleByID(ctx context.Context, tenantID string, accountMappingRuleID string) (AccountMappingRule, error)
	GetAccountMappingRuleByKey(ctx context.Context, tenantID string, mappingKey string) (AccountMappingRule, error)
	ListAccountMappingRules(ctx context.Context, tenantID string, filter ListAccountMappingRulesFilter) ([]AccountMappingRule, error)
}

type ListAccountMappingRulesFilter struct {
	SourceModule       MappingSourceModule
	SourceDocumentType string
	EventType          string
	LineType           string
	AccountCode        string
	IsDefault          *bool
	IsActive           *bool
	Query              string
	Limit              int
	Offset             int
}
