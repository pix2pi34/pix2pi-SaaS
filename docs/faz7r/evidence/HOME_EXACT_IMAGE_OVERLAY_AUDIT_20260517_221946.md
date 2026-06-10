# Pix2pi Home Exact Image Overlay Audit

## Decision

User requested exact same visual output, not CSS recreation.

Implementation:
- Full-page design images are used as the visible page.
- Active HTML overlay links are positioned above the image.
- Theme selector switches image themes.
- SEO/accessibility text is hidden off-screen but present in HTML.

## Assets

- /var/www/pix2pi/live/assets/images/home/pix2pi-home-blue.png
- /var/www/pix2pi/live/assets/images/home/pix2pi-home-gold.png
- /var/www/pix2pi/live/assets/images/home/pix2pi-home-redwhite.png

## Active overlay links

- Logo -> /customer-login_react.html
- Top Giriş Yap -> /customer-login_react.html
- Top Kayıt Ol -> /customer-register_react.html
- Müşteri Girişi -> /customer-login_react.html
- İşletme Kaydı -> /customer-register_react.html

## Themes

- Blue
- Gold
- Redwhite

## Tests

- HTML marker: PASS
- Theme images in HTML: PASS
- Overlay links in HTML: PASS
- localStorage theme persistence: PASS
- nginx -t: PASS
- nginx reload: PASS
- local assets exist: PASS
- external page: PASS
- external images: WARN
- semantic text: PASS

## Counts

- PASS_COUNT=8
- FAIL_COUNT=0
- WARN_COUNT=1
