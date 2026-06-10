# uzmanparcaci — Improvement Carry-forward Register

## Kaynak

SOURCE_BLOCK=4C-7C
PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_SECTOR=OTO_YEDEK_PARCA

---

## Register özeti

IMPROVEMENT_CARRY_FORWARD_STATUS=PASS
SOURCE_IMPROVEMENT_COUNT=3
CARRIED_FORWARD_COUNT=3
OPEN_IMPROVEMENT_COUNT_FOR_4C=0

---

## Carry-forward kayıtları

| Kod | Açıklama | Hedef faz | Durum |
|-----|----------|-----------|-------|
| IMP-01 | Barkod alanını opsiyonel UI bilgisiyle göstermek | FAZ 4D / FAZ 5 | CARRIED_FORWARD |
| IMP-02 | Oto yedek parça UI: OEM, eşdeğer, araç uyum | FAZ 4D | CARRIED_FORWARD |
| IMP-03 | Pazaryeri ve Paraşüt discovery notlarını FAZ 4D'ye taşımak | FAZ 4D | CARRIED_FORWARD |

---

## Machine status

IMP_01_STATUS=CARRIED_FORWARD
IMP_02_STATUS=CARRIED_FORWARD
IMP_03_STATUS=CARRIED_FORWARD
OPEN_IMPROVEMENT_COUNT_FOR_4C=0
4C_7D_READY=YES
