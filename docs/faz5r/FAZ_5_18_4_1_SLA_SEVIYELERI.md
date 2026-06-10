# FAZ 5-R / 247 — FAZ 5-18.4.1 SLA Seviyeleri

## Amaç

Bu adım, Commercial / Public Launch öncesinde support operasyonunun SLA seviyelerini tanımlar.

Bu çalışma production SLA yayını değildir. Amaç; P0/P1/P2/P3 önceliklerini, response SLA, resolution SLA, escalation SLA, müşteri güncelleme aralığı ve breach policy gereksinimlerini teknik olarak audit edilebilir hale getirmektir.

## SLA matrisi

| Öncelik | Response SLA | Resolution SLA | Escalation SLA | Update interval |
|---|---:|---:|---:|---:|
| P0_CRITICAL | 1 saat | 4 saat | 1 saat | 1 saat |
| P1_HIGH | 4 saat | 24 saat | 4 saat | 4 saat |
| P2_NORMAL | 24 saat | 72 saat | 24 saat | 24 saat |
| P3_LOW | 48 saat | 168 saat | 48 saat | 48 saat |

## Kritik kurallar

- Tüm SLA seviyeleri READY olmalıdır.
- P0, P1, P2, P3 priority eksiksiz olmalıdır.
- P0 SLA süreleri P1/P2/P3'ten daha sıkı olmalıdır.
- Her SLA tenant scoped olmalıdır.
- Her SLA için ops owner bulunmalıdır.
- Her SLA için business owner bulunmalıdır.
- Her SLA için escalation rule bulunmalıdır.
- Her SLA için breach policy bulunmalıdır.
- Production SLA public yayını bu fazda kapalı kalır.
- Public SLA page bu fazda kapalı kalır.

## Çıkış kararı

Bu adım PASS olduğunda:

- SLA matrisi hazırdır.
- Destek kanal yapısına bağlanmaya hazırdır.
- Escalation matrisi için temel oluşmuştur.
- Support ops testleri için SLA contract hazırdır.

## Final policy

INTERNAL_SLA_READY=true  
PRODUCTION_SLA_PUBLISHED=false  
PUBLIC_SLA_PAGE_ENABLED=false  
SUPPORT_CHANNEL_STRUCTURE_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_4_2_DESTEK_KANAL_YAPISI
