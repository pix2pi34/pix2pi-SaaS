from pathlib import Path
import sys

conf_path = Path("/etc/nginx/conf.d/pix2pi_faz4d_static.conf")

if not conf_path.exists():
    print("HATA ❌ nginx conf bulunamadi:", conf_path)
    sys.exit(1)

text = conf_path.read_text(encoding="utf-8")

def remove_location_blocks(src: str, starters):
    lines = src.splitlines(keepends=True)
    out = []
    i = 0

    while i < len(lines):
        stripped = lines[i].strip()
        should_remove = any(stripped.startswith(starter) for starter in starters)

        if not should_remove:
            out.append(lines[i])
            i += 1
            continue

        brace_balance = lines[i].count("{") - lines[i].count("}")
        i += 1

        while i < len(lines) and brace_balance > 0:
            brace_balance += lines[i].count("{") - lines[i].count("}")
            i += 1

    return "".join(out)

starters_to_remove = [
    "location /faz5/",
    "location = /faz5",
    "location = /faz5/",
    "location = /faz5/pricing",
    "location = /faz5/pricing/",
    "location ^~ /faz5/pricing/",
    "location = /faz5/developer",
    "location = /faz5/developer/",
    "location ^~ /faz5/developer/"
]

text = remove_location_blocks(text, starters_to_remove)

insert_block = """    location = /faz5 {
        return 301 /faz5/;
    }

    location = /faz5/ {
        root /var/www/pix2pi;
        index index.html;
        try_files /faz5/index.html =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
    }

    location = /faz5/pricing {
        return 301 /faz5/pricing/;
    }

    location = /faz5/pricing/ {
        root /var/www/pix2pi;
        index index.html;
        try_files /faz5/pricing/index.html =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
    }

    location ^~ /faz5/pricing/ {
        root /var/www/pix2pi;
        index index.html;
        try_files $uri /faz5/pricing/index.html =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
    }

    location = /faz5/developer {
        return 301 /faz5/developer/;
    }

    location = /faz5/developer/ {
        root /var/www/pix2pi;
        index index.html;
        try_files /faz5/developer/index.html =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
    }

    location ^~ /faz5/developer/ {
        root /var/www/pix2pi;
        index index.html;
        try_files $uri /faz5/developer/index.html =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
    }

"""

marker = "    location /faz4d/pilot-go-live/"

if marker not in text:
    print("HATA ❌ faz4d location marker bulunamadi, exact route patch uygulanmadi")
    print("ARANAN_MARKER:", marker)
    sys.exit(1)

patched = text.replace(marker, insert_block + marker, 1)

conf_path.write_text(patched, encoding="utf-8")

print("OK ✅ exact /faz5 route bloklari eklendi:", conf_path)
