# FAZ 4B / 16.4 - Pilot Data Readiness / Sample Dataset Contract

Amaç:
Pilot / UAT / Onboarding rollout için örnek ürün, stok, cari, satış, kasa, muhasebe ve rapor veri hazırlık sözleşmesini kurmak.

Bu adım:
- Gerçek veri eklemez.
- Gerçek ürün oluşturmaz.
- Gerçek stok hareketi oluşturmaz.
- Gerçek cari / müşteri / tedarikçi oluşturmaz.
- Gerçek satış / iade / kasa işlemi oluşturmaz.
- Gerçek muhasebe fişi / journal / ledger oluşturmaz.
- Data import çalıştırmaz.
- File export çalıştırmaz.
- DB tablo / migration oluşturmaz.
- DB apply yapmaz.
- DB mutate etmez.
- API route oluşturmaz.
- Backend implementation yapmaz.
- UI kodu yazmaz.
- Event Bus publish/consume yapmaz.
- Notification göndermez.
- Servis restart etmez.
- Container restart etmez.
- Docker compose up/down/restart çalıştırmaz.
- Nginx reload/restart yapmaz.
- Firewall değiştirmez.
- Port kapatmaz/açmaz.
- Config/env değiştirmez.
- Secret değeri, raw DSN, token, password veya müşteri hassas verisi rapora basmaz.
- Sadece sample dataset contract ve quality gate metadata üretir.

Ön koşul:
- 16.1 Pilot / UAT / Onboarding baseline PASS olmalı.
- 16.2 Pilot tenant readiness / role & onboarding contract PASS olmalı.
- 16.3 UAT scenario execution contract PASS olmalı.
- 17 Workflow / Realtime UI final closure PASS olmalı.
- 20 Infra Cleanup / Production Hardening PASS olmalı.
- 21 Security / RBAC / Audit PASS olmalı.
- 22 Observability / Ops Console final closure PASS olmalı.

Veri hazırlık hedefleri:
- Pilot product sample dataset
- Pilot stock sample dataset
- Pilot party/customer/vendor sample dataset
- Pilot sales/accounting sample dataset
- Pilot data quality gate matrix
- No-runtime-change / no-config-change / no-secret safety

Kapanış hedefi:
PILOT_DATA_READINESS_CONTRACT=PASS
PILOT_DATA_PREVIOUS_16_3=PASS
PILOT_PRODUCT_SAMPLE_DATASET=PASS
PILOT_STOCK_SAMPLE_DATASET=PASS
PILOT_PARTY_SAMPLE_DATASET=PASS
PILOT_SALES_ACCOUNTING_SAMPLE_DATASET=PASS
PILOT_DATA_QUALITY_GATE_MATRIX=PASS
PILOT_DATA_NO_RUNTIME_CHANGE=PASS
PILOT_DATA_NO_CONFIG_CHANGE=PASS
PILOT_DATA_SECRET_SAFE=PASS
FAZ4B_16_4_FINAL_STATUS=PASS
