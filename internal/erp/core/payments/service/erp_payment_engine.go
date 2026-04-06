package service

import "fmt"

const (
PaymentTypeCash = "cash"
PaymentTypePOS  = "pos"
PaymentTypeBank = "bank"
)

type PaymentEngine struct{}

func NewPaymentEngine() *PaymentEngine {
return &PaymentEngine{}
}

func (e *PaymentEngine) ResolveDebitAccount(
paymentType string,
bank string,
) (string, error) {

switch paymentType {

case PaymentTypeCash:
return "100.01", nil

case PaymentTypePOS:

switch bank {

case "ziraat":
return "108.01", nil

case "isbank":
return "108.02", nil

default:
return "108.00", nil

}

case PaymentTypeBank:

switch bank {

case "ziraat":
return "102.01", nil

case "isbank":
return "102.02", nil

default:
return "102.00", nil

}

default:
return "", fmt.Errorf("unknown payment type: %s", paymentType)

}

}
