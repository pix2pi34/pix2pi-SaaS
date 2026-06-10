# FAZ 7-R / 361.3 — Tüm audit sayaçları / PASS kuralı düzeltmesi

## Amaç

FAZ 7-R içinde kısmi, dry-run, preview veya disabled guard içeren eski PASS çıktılarının final closure içinde gerçek tamamlanmış iş gibi sayılmasını engellemek.

## Yeni kesin kural

Kısmi iş PASS sayılmaz.

Aşağıdaki işaretlerden biri olan dosya, FINAL_STATUS=PASS veya REAL_IMPLEMENTATION_STATUS=PASS içeriyorsa yeniden sınıflandırılır:

- disabled
- placeholder
- preview
- dry-run
- dry run
- real_*_enabled=false
- backend disabled
- provider closed
- closed_until
- not_started
- mutation disabled
- activation disabled
- send disabled
- issue disabled
- enforcement disabled

## Sınıflandırma

- INVALID_PARTIAL_PASS: PASS yazılmış ama kısmi/dry-run/disabled marker var.
- OLD_PASS_NO_FORBIDDEN_MARKER_FOUND: PASS var, forbidden marker bulunmadı.
- PARTIAL_MARKER_NO_PASS: kısmi marker var ama PASS claim yok.

## Sonuç kuralı

INVALID_PARTIAL_PASS_COUNT > 0 ise:

- FAZ_7R_FINAL_CLOSURE_ALLOWED=NO
- FAZ_7R_PARTIAL_PASS_RECLASSIFICATION_REQUIRED=YES
- FAZ 7-R final closure yapılamaz.

Bu adımın kendisi, guard mekanizması kurulduğu için PASS olabilir. Ama FAZ 7-R final closure, kısmi işler gerçek hale gelmeden PASS olamaz.

## Sonraki iş

FAZ 7-R / 317.3 — Tenant selection screen gerçek tenant akışı
