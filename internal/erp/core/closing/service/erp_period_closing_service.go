package service

type PeriodClosingResult struct {
	PeriodProfit float64
	IsClosed     bool
}

type PeriodClosingService struct {
}

func NewPeriodClosingService() *PeriodClosingService {
	return &PeriodClosingService{}
}

func (s *PeriodClosingService) ClosePeriod(profit float64) PeriodClosingResult {

	return PeriodClosingResult{
		PeriodProfit: profit,
		IsClosed:     true,
	}
}
