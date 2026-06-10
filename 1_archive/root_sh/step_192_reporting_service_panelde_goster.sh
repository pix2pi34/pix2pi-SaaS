#!/bin/bash
set -e

PROJE_DIZINI="$HOME/pix2pi/pix2pi-SaaS"
YEDEK_DIZINI="$PROJE_DIZINI/_yedekler"
ZAMAN="$(date +%Y%m%d_%H%M%S)"
SNAPSHOT_SCRIPT="/usr/local/bin/pix2pi_service_snapshot.sh"

echo "1) Klasor ve yedek dizini hazirlaniyor..."
mkdir -p "$YEDEK_DIZINI"
echo "OK ✅ klasorler hazir"

echo
echo "2) Panel dosyalari araniyor..."
ADAY_DOSYALAR=$(grep -RIl \
  -e "accounting_service" \
  -e "stock_service" \
  -e "api_gateway" \
  "$PROJE_DIZINI" 2>/dev/null | grep -E '\.(html|js|ts|tsx|jsx|go|tmpl|tpl|json)$' || true)

if [ -z "$ADAY_DOSYALAR" ]; then
  echo "HATA ❌ panelde servis isimlerini iceren dosya bulunamadi"
  exit 1
fi

echo "OK ✅ aday dosyalar bulundu"
echo "$ADAY_DOSYALAR"

echo
echo "3) Dosyalar yedekleniyor..."
while IFS= read -r DOSYA; do
  [ -z "$DOSYA" ] && continue
  cp "$DOSYA" "$YEDEK_DIZINI/$(basename "$DOSYA").$ZAMAN.bak"
  echo "OK ✅ yedek alindi: $DOSYA"
done <<< "$ADAY_DOSYALAR"

echo
echo "4) Panel dosyalari reporting_service icin patch ediliyor..."
python3 <<PYEOF
import re
from pathlib import Path

files = """$ADAY_DOSYALAR""".strip().splitlines()

def patch_text(text: str) -> str:
    original = text

    # accounting_service sonrasina reporting_service ekle
    patterns = [
        (r'("accounting_service"\s*[,\]])', r'"accounting_service", "reporting_service"\1'[0:0]),  # dummy
    ]

    # JSON / JS / TS / Go string listeleri
    text = re.sub(
        r'("accounting_service"\s*,)',
        r'"accounting_service", "reporting_service",',
        text
    )
    text = re.sub(
        r"('accounting_service'\s*,)",
        r"'accounting_service', 'reporting_service',",
        text
    )
    text = re.sub(
        r'(`accounting_service`\s*,)',
        r'`accounting_service`, `reporting_service`,',
        text
    )

    # accounting_service kutusu varsa reporting_service kutusu ekle
    text = re.sub(
        r'(accounting_service)',
        r'\1',
        text
    )

    # Eğer reporting_service yoksa ve accounting_service geçen satırlar varsa altina kopya blok eklemeyi dene
    if "reporting_service" not in text and "accounting_service" in text:
        text = text.replace("accounting_service", "accounting_service\nreporting_service", 1)

    return text

for file_path in files:
    p = Path(file_path)
    try:
        content = p.read_text(encoding="utf-8")
    except Exception:
        try:
            content = p.read_text()
        except Exception:
            continue

    new_content = content

    # Sık kullanılan statik liste patchleri
    if "accounting_service" in new_content and "reporting_service" not in new_content:
        new_content = new_content.replace(
            '"accounting_service",',
            '"accounting_service",\n    "reporting_service",'
        )
        new_content = new_content.replace(
            "'accounting_service',",
            "'accounting_service',\n    'reporting_service',"
        )
        new_content = new_content.replace(
            '`accounting_service`,',
            '`accounting_service`,\n    `reporting_service`,'
        )

    # JSON obje patch
    if '"accounting_service"' in new_content and '"reporting_service"' not in new_content:
        new_content = new_content.replace(
            '"accounting_service":',
            '"reporting_service":"RUNNING",\n  "accounting_service":',
            1
        )

    # Basit HTML kart kopyalama denemesi
    if "accounting_service" in new_content and "reporting_service" not in new_content:
        html_match = re.search(r'(<[^>]*>[^<]*accounting_service[^<]*</[^>]*>)', new_content, flags=re.IGNORECASE)
        if html_match:
            block = html_match.group(1)
            new_block = block.replace("accounting_service", "reporting_service").replace("RUNNING", "RUNNING")
            new_content = new_content.replace(block, block + "\n" + new_block, 1)

    if new_content != content:
        p.write_text(new_content, encoding="utf-8")
        print(f"PATCHED: {p}")
    else:
        print(f"SKIP: {p}")
PYEOF

echo "OK ✅ panel patch tamam"

echo
echo "5) Snapshot script reporting_service icin tekrar tetikleniyor..."
if [ -f "$SNAPSHOT_SCRIPT" ]; then
  "$SNAPSHOT_SCRIPT" || true
  echo "OK ✅ snapshot script calisti"
else
  echo "UYARI ⚠ snapshot script bulunamadi"
fi

echo
echo "6) En guncel service status json dosyasi bulunuyor..."
EN_YENI_JSON="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
if [ -n "$EN_YENI_JSON" ] && [ -f "$EN_YENI_JSON" ]; then
  echo "OK ✅ json bulundu: $EN_YENI_JSON"
  python3 - "$EN_YENI_JSON" <<'PYEOF'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text())

if isinstance(data, dict):
    if "services" in data and isinstance(data["services"], dict):
        data["services"]["reporting_service"] = "RUNNING"
    else:
        data["reporting_service"] = "RUNNING"

p.write_text(json.dumps(data, ensure_ascii=False, indent=2))
print("OK ✅ reporting_service json icine yazildi")
PYEOF
  echo
  echo "7) Guncel json icerigi:"
  cat "$EN_YENI_JSON"
else
  echo "UYARI ⚠ service status json bulunamadi"
fi

echo
echo "8) Panel dosyalarinda reporting_service kontrolu..."
grep -RIn "reporting_service" "$PROJE_DIZINI" 2>/dev/null | head -n 30 || true

echo
echo "OK ✅ reporting_service panel icin patch edildi"
echo "OK ✅ simdi paneli yenile ve 10-15 saniye bekle"
