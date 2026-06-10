# Panel Named HTML Routes Fix Audit

## Amaç

Panel login/register sayfalarını dizin route yerine named html route olarak servis etmek.

## Yeni route'lar

- https://panel.pix2pi.com.tr/customer-login_react.html
- https://panel.pix2pi.com.tr/customer-login_vue3.html
- https://panel.pix2pi.com.tr/customer-register_react.html
- https://panel.pix2pi.com.tr/customer-register_vue3.html

## Kapanan eski route'lar

- /customer-login/react/
- /customer-login/vue3/
- /customer-register/react/
- /customer-register/vue3/

## Web root

/root/pix2pi/pix2pi-SaaS/pix2pi_www/panel

## Nginx conf

/etc/nginx/conf.d/00_pix2pi_clean_canonical.conf

## Backup

/root/pix2pi/pix2pi-SaaS/backups/panel-named-html-routes-fix/20260518_073513

## Regression

pix2pi.com.tr root: 200

## Counts

PASS_COUNT=13
FAIL_COUNT=0
WARN_COUNT=0
