# Nginx conf.d Visual Cleanup Audit

## Amaç

/etc/nginx/conf.d altında kalan Pix2pi disabled/bak dosyalarını silmeden oldweb arşivine taşımak.

## Aktif bırakılan dosya

/etc/nginx/conf.d/00_pix2pi_clean_canonical.conf

## Arşiv dizini

/root/pix2pi/pix2pi-SaaS/oldweb/nginx-conf-d-archive/20260518_065301

## Backup

/root/pix2pi/pix2pi-SaaS/backups/nginx-conf-d-visual-cleanup/20260518_065301

## Sonuçlar

- moved_count: 17
- active_pix2pi_conf_count: 1
- clutter_count_after: 0
- nginx -t: PASS
- nginx reload: PASS

## Counts

PASS_COUNT=9
FAIL_COUNT=0
WARN_COUNT=0
