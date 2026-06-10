# FAZ 4 / 14.2.3 - Restore Drill Sandbox Plan

Amac:
14.2.2 ile uretilen logical backup dosyasinin canli DB'ye dokunmadan izole bir PostgreSQL sandbox uzerinde restore edilebilmesi icin plan uretmek.

Bu adim:
- DB mutate etmez.
- Restore yapmaz.
- Docker container olusturmaz.
- Docker volume olusturmaz.
- PITR ayari degistirmez.
- Sadece restore drill planini ve komut taslagini uretir.

Guvenlik kurallari:
1. Canli primary DB uzerinde restore denenmez.
2. Sandbox container farkli isimle calisir.
3. Sandbox portu canli DB portundan farkli olur.
4. Restore drill sifresi rapora yazilmaz.
5. Dump dosyasi ve checksum dogrulanir.
6. pg_restore list dosyasi mevcut olmalidir.
7. Plan dosyasi otomatik calismayacak sekilde guvenlik exit'i ile uretilir.

Kapanis hedefi:
RESTORE_DRILL_SANDBOX_PLAN=PASS
RESTORE_EXECUTED=NO
SANDBOX_CONTAINER_CREATE_EXECUTED=NO
DB_MUTATION=NO
FAZ4_14_2_3_FINAL_STATUS=PASS
