# FAZ 4 / 14.2.4 - Restore Drill Test / Sandbox Execution

Amac:
14.2.2 logical backup dosyasinin izole sandbox PostgreSQL uzerinde restore edilebildigini kanitlamak.

Bu adim:
- Canli primary DB'ye dokunmaz.
- Canli DB mutate etmez.
- PITR ayari degistirmez.
- Sadece sandbox PostgreSQL container uzerinde restore yapar.
- Restore kanitlarini toplar.
- Test sonunda sandbox container ve volume temizler.

Guvenlik kurallari:
1. Restore sadece pix2pi_pg_restore_drill_14_2_4 sandbox container uzerinde yapilir.
2. Sandbox portu canli DB portundan farkli olur.
3. Restore drill password rapora yazilmaz.
4. Dump checksum tekrar dogrulanir.
5. Restore sonrasi tablo/schema/index sayilari raporlanir.
6. Cleanup sonucu raporlanir.
7. Canli DB mutasyonu NO olarak kalir.

Kapanis hedefi:
RESTORE_DRILL_TEST=PASS
SANDBOX_RESTORE_STATUS=PASS
LIVE_DB_MUTATION=NO
SANDBOX_CLEANUP_STATUS=PASS
FAZ4_14_2_4_FINAL_STATUS=PASS
