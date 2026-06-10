# uzmanparcaci — FAZ 4C Burn-down Register

## Pilot

PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_SECTOR=OTO_YEDEK_PARCA

---

## Register özeti

REGISTER_STATUS=IMPROVEMENTS_CARRIED_FORWARD
SOURCE_BLOCK=4C-6_REAL_UAT_EXECUTION

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=2
CLOSED_WARNING_COUNT=2
OPEN_WARNING_COUNT=0
BLOCKING_WARNING_COUNT=0

IMPROVEMENT_COUNT=3
CARRIED_FORWARD_IMPROVEMENT_COUNT=3
OPEN_IMPROVEMENT_COUNT_FOR_4C=0

---

## Critical blockers

| Kod | Açıklama | Durum | Aksiyon |
|-----|----------|-------|---------|
| NONE | Critical blocker yok | CLOSED | Aksiyon yok |

---

## Warnings

| Kod | Açıklama | Blocker | Durum | Burn-down kararı |
|-----|----------|---------|-------|------------------|
| WARN-01 | Barkod boşluğu | NO | CLOSED | Pilot barkod kullanmadığı için blocker değildir |
| WARN-02 | İşletme kabul kapısı sonradan PASS edildi | NO | CLOSED | Acceptance PASS alındığı için kapandı |

---

## Warning machine status

WARN_01_STATUS=CLOSED
WARN_02_STATUS=CLOSED
OPEN_WARNING_COUNT=0
CLOSED_WARNING_COUNT=2
BLOCKING_WARNING_COUNT=0

---

## Improvements

| Kod | Açıklama | Durum | Hedef |
|-----|----------|-------|-------|
| IMP-01 | Barkod alanını opsiyonel UI bilgisiyle göstermek | CARRIED_FORWARD | FAZ 4D / FAZ 5 |
| IMP-02 | Oto yedek parça UI: OEM, eşdeğer, araç uyum | CARRIED_FORWARD | FAZ 4D |
| IMP-03 | Pazaryeri ve Paraşüt discovery notlarını FAZ 4D'ye taşımak | CARRIED_FORWARD | FAZ 4D |

---

## Improvement machine status

IMP_01_STATUS=CARRIED_FORWARD
IMP_02_STATUS=CARRIED_FORWARD
IMP_03_STATUS=CARRIED_FORWARD
CARRIED_FORWARD_IMPROVEMENT_COUNT=3
OPEN_IMPROVEMENT_COUNT_FOR_4C=0

---

## Next

NEXT_STEP=4C_7D_BURNDOWN_CLOSURE_GATE
4C_7D_READY=YES
