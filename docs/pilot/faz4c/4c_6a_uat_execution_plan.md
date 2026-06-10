# FAZ 4C — 4C-6A UAT Execution Plan / Checklist Freeze

## Blok

4C-6A — UAT Execution Plan / Checklist Freeze

## Ana karar

uzmanparcaci için gerçek UAT kapsamı donduruldu.

Bu adımda DB write yapılmaz.

---

## 1. UAT hedefi

Gerçek pilot işletme için sistemin aşağıdaki alanlarda kabul edilebilir durumda olup olmadığını görmek:

- Tenant doğru mu?
- Kullanıcı doğru tenant ve role bağlı mı?
- Ürün/stok staging verisi doğru mu?
- Oto yedek parça özel alanları iş ihtiyacını karşılıyor mu?
- Pilot işletme ilk kullanım akışını anlayabiliyor mu?
- Kritik blocker var mı?
- Go / No-Go kapısına geçilebilir mi?

---

## 2. UAT test alanları

| Kod | Test alanı | Beklenen |
|-----|------------|----------|
| UAT-01 | Tenant erişimi | uzmanparcaci tenant doğrulanır |
| UAT-02 | Kullanıcı/rol | uzmanparcaci1@gmail.com / PILOT_ADMIN doğrulanır |
| UAT-03 | Staging ürün verisi | 5 sample ürün görünür |
| UAT-04 | Veri kalite | duplicate SKU yok, tenant mismatch yok |
| UAT-05 | Oto yedek parça alanları | OEM, eşdeğer kod, araç uyum notu görünür |
| UAT-06 | Barkod kararı | Barkod boşluğu blocker değildir |
| UAT-07 | Scope guard | Pazaryeri canlı entegrasyon beklenmez |
| UAT-08 | İşletme kabul | kullanıcı onayı alınır |
| UAT-09 | Bug kaydı | bug/blocker varsa sınıflandırılır |
| UAT-10 | UAT sonuç | PASS / CONDITIONAL_PASS / FAIL |

---

## 3. Kabul kriterleri

UAT PASS için:

- Critical blocker = 0
- Tenant erişimi PASS
- Kullanıcı/rol erişimi PASS
- Staging ürün verisi PASS
- Veri kalite PASS
- Oto yedek parça özel alanları PASS
- İşletme kullanıcı onayı PASS veya CONDITIONAL_PASS
- Scope dışı beklenti yok

---

## 4. Bilinçli uyarılar

Aşağıdakiler UAT blocker değildir:

- Barkod boşluğu
- ERP core product apply yapılmaması
- Pazaryeri canlı entegrasyon olmaması
- Paraşüt canlı senkron olmaması
- Parola reset/davet kapısının açık olması

---

## 5. Final status

4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS
4C_6A_UAT_SCOPE_STATUS=FROZEN
4C_6A_SELECTED_BUSINESS=uzmanparcaci
4C_6A_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_6A_UAT_MODE=REAL_PILOT_UAT
4C_6A_UAT_EXECUTION_TYPE=CHECKLIST_BASED
4C_6A_UAT_CHECKLIST_CREATED=YES
4C_6A_DB_WRITE_APPLIED=NO
4C_6A_CRITICAL_BLOCKER_COUNT=0
4C_6B_READY=YES
