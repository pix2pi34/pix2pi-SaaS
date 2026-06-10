# FAZ 7-12 — Accountant Portal Final Closure / Commercial Handoff Gate

## Amaç

Bu modül, FAZ 7 muhasebeci portal ailesini final closure gate altında kapatır.

Kapanan aile:
- FAZ 7-9 Accountant Portal Commercial Surface
- FAZ 7-10 Accountant Portal Access / Multi-Firm Runtime Surface
- FAZ 7-11 Accountant Portal Reporting / Export Preview Surface

## Kapsam

- 7-9 / 7-10 / 7-11 final status doğrulama
- 7-9 / 7-10 / 7-11 seal status doğrulama
- Paraşüt / Logo / Mikro / Zirve dry-run provider set doğrulama
- Commercial handoff gate üretimi
- Live module statuslarının NOT_STARTED kalması
- Gerçek billing/payment/provider/export/ERP write kapılarının kapalı kalması
- Final closure audit trail

## Bu faz live açılış değildir

Bu fazda aşağıdaki işlemler açılmaz:

- Gerçek muhasebeci billing
- Gerçek ödeme capture
- Gerçek provider API çağrısı
- Gerçek file delivery
- Gerçek ERP write
- Gerçek müşteri verisi export
- Gerçek operator provider action

## Handoff kararı

Bu faz başarılı olursa muhasebeci portal modülü mühürlenir.

Handoff gate:
- ACCOUNTANT_PORTAL_MODULE_FINAL_SEAL_STATUS=SEALED
- ACCOUNTANT_PORTAL_COMMERCIAL_HANDOFF_GATE=READY_FOR_COMMERCIAL_LIVE_MODULE
- ACCOUNTANT_PORTAL_COMMERCIAL_LIVE_MODULE_STATUS=NOT_STARTED

## Acceptance criteria

- Runtime kodu var
- Test kodu var
- Config var
- Dokümantasyon var
- Audit script var
- Dependency seal doğrulama var
- Provider dry-run set doğrulama var
- Live operation close assertion var
- Real billing blocker var
- Real payment blocker var
- Real provider API blocker var
- Real file delivery blocker var
- Real ERP write blocker var
- Real customer export blocker var
- Commercial handoff gate var
- Audit trail var
- Go test PASS
- Real implementation audit PASS
