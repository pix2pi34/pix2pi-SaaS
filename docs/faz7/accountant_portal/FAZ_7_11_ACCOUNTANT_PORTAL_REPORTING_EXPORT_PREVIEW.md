# FAZ 7-11 — Accountant Portal Reporting / Export Preview Surface

## Amaç

Bu modül, muhasebeci portalında rapor ve export preview yüzeyini kurar.

FAZ 7-9 ticari yüzeyinden sonra, FAZ 7-10 çok firmalı erişim runtime üzerine çalışır.

## Kapsam

- Muhasebeci firma context üzerinden rapor preview
- Permission bazlı rapor erişimi
- Permission bazlı export preview erişimi
- Paraşüt / Logo / Mikro / Zirve export package preview yüzeyi
- Synthetic preview row / manifest üretimi
- No-real-customer-data garantisi
- Live export / provider API / file delivery / ERP write blocker
- Reporting audit trail

## Runtime kuralları

Rapor preview için:
1. Aktif firma access grant olmalı
2. Doğru accountant tenant + firm tenant + user + period eşleşmeli
3. `report.view` permission olmalı
4. Preview yalnızca synthetic veri üretmeli
5. Gerçek müşteri verisi taşınmamalı

Export package preview için:
1. Aktif firma access grant olmalı
2. `export.preview` permission olmalı
3. Provider sadece dry-run sealed aileden olmalı: PARASUT, LOGO, MIKRO, ZIRVE
4. Manifest synthetic olmalı
5. Gerçek provider API çağrısı yapılmamalı
6. Gerçek dosya teslimi yapılmamalı
7. Gerçek ERP write yapılmamalı
8. Gerçek müşteri verisi export edilmemeli

## Kapalı kalan live işlemler

Bu fazda kapalı kalan işlemler:

- Gerçek muhasebeci billing
- Gerçek ödeme capture
- Gerçek provider API operasyonu
- Gerçek file delivery
- Gerçek ERP write
- Gerçek müşteri verisi export
- Gerçek operator provider action

## Acceptance criteria

- Runtime kodu var
- Test kodu var
- Config var
- Dokümantasyon var
- Audit script var
- Report preview runtime var
- Export package preview runtime var
- Permission enforcement var
- Access runtime entegrasyonu var
- Synthetic report rows var
- Synthetic export manifest var
- No-real-customer-data guard var
- Live export blocker var
- Real provider export blocker var
- Real file delivery blocker var
- Real ERP write blocker var
- Audit trail var
- Go test PASS
- Real implementation audit PASS
