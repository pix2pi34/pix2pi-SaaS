package compliance

type ComplianceEngine struct{}

func (c *ComplianceEngine) Check(rule string) bool { return true }
