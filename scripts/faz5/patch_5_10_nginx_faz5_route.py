from pathlib import Path
import sys

conf_path = Path("/etc/nginx/conf.d/pix2pi_faz4d_static.conf")

if not conf_path.exists():
    print("HATA ❌ nginx conf bulunamadi:", conf_path)
    sys.exit(1)

text = conf_path.read_text(encoding="utf-8")

if "location /faz5/" in text:
    print("OK ✅ location /faz5/ zaten mevcut")
    sys.exit(0)

marker = "location /faz4d/pilot-go-live/"
insert_block = """    location /faz5/ {
        root /var/www/pix2pi;
        index index.html;
        try_files $uri $uri/ /faz5/index.html;
    }

"""

if marker not in text:
    print("HATA ❌ faz4d location marker bulunamadi, otomatik patch uygulanmadi")
    print("ARANAN_MARKER:", marker)
    sys.exit(1)

patched = text.replace("    " + marker, insert_block + "    " + marker, 1)

conf_path.write_text(patched, encoding="utf-8")

print("OK ✅ /faz5/ location eklendi:", conf_path)
