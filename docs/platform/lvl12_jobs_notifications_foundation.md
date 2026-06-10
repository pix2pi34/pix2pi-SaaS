# LVL12 Jobs + Notifications Foundation

## Kapsam
Bu paket su maddeleri acar:
- 12.3.1 background job engine
- 12.3.2 retryable jobs
- 12.3.3 idempotent jobs
- 12.3.4 tenant-aware jobs
- 12.3.5 job audit trail
- 12.3.6 job test suite
- 12.4.1 notification service
- 12.4.2 mail channel
- 12.4.3 sms / push channel
- 12.4.4 webhook delivery
- 12.4.5 webhook retry / DLQ
- 12.4.6 notification testleri

## Bu pakette ne var
- jobs / notifications env example
- jobs catalog
- notifications catalog
- rules template
- render script
- smoke script
- generated rules
- generated jobs summary
- generated notifications summary

## Mantik
Ilk asamada:
- background job standartlarini katalogluyoruz
- notification / webhook delivery modelini sabitliyoruz
- retry / idempotency / tenant-aware / audit mantigini env tabanli rule output ile uretiyoruz
- smoke ile generated ciktinin dogrulugunu kontrol ediyoruz

## Sonraki paket
- 12.5 realtime engine
- 12.6 workflow / orchestrator
