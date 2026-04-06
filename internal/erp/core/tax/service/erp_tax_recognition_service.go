package service

import "fmt"

const (
	DocumentTypeSaleInvoice     = "sale_invoice"
	DocumentTypePurchaseInvoice = "purchase_invoice"
)

type TaxRecognitionInput struct {
	DocumentType string
	TaxRate      int
}

type TaxRecognitionService struct {
}

func NewTaxRecognitionService() *TaxRecognitionService {
	return &TaxRecognitionService{}
}

func (s *TaxRecognitionService) ResolveTaxAccountCode(
	input TaxRecognitionInput,
) (string, error) {
	switch input.DocumentType {

	case DocumentTypeSaleInvoice:
		return s.resolveSalesTaxAccount(input.TaxRate)

	case DocumentTypePurchaseInvoice:
		return s.resolvePurchaseTaxAccount(input.TaxRate)

	default:
		return "", fmt.Errorf("unsupported document type: %s", input.DocumentType)
	}
}

func (s *TaxRecognitionService) resolveSalesTaxAccount(
	taxRate int,
) (string, error) {
	switch taxRate {
	case 0:
		return "391.01.00", nil
	case 1:
		return "391.01.01", nil
	case 10:
		return "391.01.10", nil
	case 20:
		return "391.01.20", nil
	default:
		return "", fmt.Errorf("unsupported sales tax rate: %d", taxRate)
	}
}

func (s *TaxRecognitionService) resolvePurchaseTaxAccount(
	taxRate int,
) (string, error) {
	switch taxRate {
	case 0:
		return "191.01.00", nil
	case 1:
		return "191.01.01", nil
	case 10:
		return "191.01.10", nil
	case 20:
		return "191.01.20", nil
	default:
		return "", fmt.Errorf("unsupported purchase tax rate: %d", taxRate)
	}
}
