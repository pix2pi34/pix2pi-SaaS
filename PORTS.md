# Pix2pi Port Registry (Single Source of Truth)

> Bu dosya: Port çakışması yaşamamak için **tek kaynak**tır.
> Yeni servis eklerken önce buraya yaz, sonra compose/env’e uygula.

## App Ports
- 9001  identity-api (HTTP)
- 9011  dev-token (HTTP, only localhost)

## Observability
- 3000  grafana
- 3100  loki
- 9100  prometheus

## Data
- 5432  postgres
- 6379  redis

## Kurallar
1) Aynı port iki servise verilmez.  
2) dev-token **sadece 127.0.0.1** bind eder (dışarı açılmaz).  
3) Değişiklik olursa: PORTS.md + deploy/ports.env birlikte güncellenir.
