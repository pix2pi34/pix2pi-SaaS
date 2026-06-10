# Pix2pi Clean Canonical Nginx Continue Audit

## Durum

İlk script bağlantı kopması nedeniyle Step 7 civarında yarım kaldı.
Bu continue script kalan aktif Pix2pi conf dosyalarını disable etti, tek canonical config yazdı ve reload yaptı.

## Yeni web root

/root/pix2pi/pix2pi-SaaS/pix2pi_www

## Aktif canonical conf

/etc/nginx/conf.d/00_pix2pi_clean_canonical.conf

## Açık bırakılan route'lar

- pix2pi.com.tr /
- pix2pi.com.tr /pix2pi_home.html
- pix2pi.com.tr /assets/
- panel.pix2pi.com.tr /
- panel.pix2pi.com.tr /customer-login/react/
- panel.pix2pi.com.tr /customer-login/vue3/
- panel.pix2pi.com.tr /customer-register/react/
- panel.pix2pi.com.tr /customer-register/vue3/
- pos.pix2pi.com.tr /
- pos.pix2pi.com.tr /health.json
- api.pix2pi.com.tr /
- api.pix2pi.com.tr /health.json
- phoenix.pix2pi.com.tr /
- phoenix.pix2pi.com.tr /owner-panel/register-approvals/
- phoenix.pix2pi.com.tr /owner-panel/register-approvals/api/

## Test

- nginx -t: PASS
- nginx reload: PASS
- active pix2pi conf count: 1
- scheme: https
- port: 443

## Counts

PASS_COUNT=13
FAIL_COUNT=0
WARN_COUNT=1

## Partial backup

/root/pix2pi/pix2pi-SaaS/backups/pix2pi-clean-canonical-nginx-continue/20260518_064856

## Original interrupted backup

/root/pix2pi/pix2pi-SaaS/backups/pix2pi-clean-canonical-nginx/20260518_064638
