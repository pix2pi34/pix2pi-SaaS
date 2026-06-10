#!/usr/bin/env bash
set -euo pipefail

WEB_ROOT="${WEB_ROOT:-/var/www/pix2pi/live}"
DEST="${WEB_ROOT}/faz4r"
MANIFEST_FILE="configs/faz4r/faz4r_live_html_publish_manifest.json"

echo "===== FAZ 4-R HTML LIVE PUBLISH RUNTIME START ====="

mkdir -p "$DEST"

export DEST
export MANIFEST_FILE

python3 - <<'PY_EOF'
import json
import os
import shutil
from datetime import datetime, timezone
from pathlib import Path
from html import escape

repo = Path.cwd()
dest = Path(os.environ["DEST"])
manifest_file = Path(os.environ["MANIFEST_FILE"])

dest.mkdir(parents=True, exist_ok=True)
published = []

def title_from_path(path: Path) -> str:
    parts = list(path.parts)
    name = path.stem if path.name != "index.html" else path.parent.name
    title = name.replace("_", " ").replace("-", " ").strip().title()
    if "approval" in str(path):
        return "Approval Inbox"
    if "workflow-monitor" in str(path):
        return "Workflow Monitor"
    if "realtime-health" in str(path):
        return "WebSocket / SSE Bağlantı Sağlığı"
    if "realtime-event-feed" in str(path):
        return "Realtime Event Feed"
    if "notification-center" in str(path):
        return "Canlı Bildirim Merkezi"
    if "pilot" in str(path).lower() and "health" in str(path).lower():
        return "Pilot Health Dashboard"
    return title

def public_href(rel_to_dest: Path) -> str:
    rel = rel_to_dest.as_posix()
    if rel.endswith("/index.html"):
        return "/faz4r/" + rel[:-10]
    if rel == "index.html":
        return "/faz4r/"
    return "/faz4r/" + rel

def copy_html_tree(base: Path, mode: str):
    if not base.exists():
        return
    for src in sorted(base.rglob("*.html")):
        if any(skip in src.parts for skip in {"node_modules", ".git"}):
            continue

        if mode == "web":
            rel = src.relative_to(base)
            out = dest / rel
        else:
            rel = src.relative_to(base)
            out = dest / "docs" / rel

        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, out)

        rel_to_dest = out.relative_to(dest)
        published.append({
            "title": title_from_path(out),
            "source": str(src),
            "published_file": str(out),
            "url_path": public_href(rel_to_dest)
        })

copy_html_tree(repo / "web" / "faz4r", "web")
copy_html_tree(repo / "docs" / "faz4r", "docs")

required = [
    "approval-inbox/index.html",
    "workflow-monitor/index.html",
    "realtime-health/index.html",
    "realtime-event-feed/index.html",
    "notification-center/index.html"
]

missing = [item for item in required if not (dest / item).exists()]
if missing:
    print("FAZ4R_HTML_PUBLISH_STATUS=FAIL")
    print("MISSING_REQUIRED_HTML=" + ",".join(missing))
    raise SystemExit(1)

now = datetime.now(timezone.utc).isoformat()

cards = []
for item in published:
    href = item["url_path"]
    cards.append(f"""
      <a class="card" href="{escape(href)}">
        <strong>{escape(item['title'])}</strong>
        <span>{escape(href)}</span>
      </a>
    """)

index_html = f"""<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Pix2pi FAZ 4-R HTML Checkpoints</title>
  <style>
    :root {{
      --bg: #0f172a;
      --panel: #111827;
      --card: #1f2937;
      --line: #334155;
      --text: #e5e7eb;
      --muted: #94a3b8;
      --ok: #22c55e;
      --blue: #38bdf8;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      background: linear-gradient(145deg, var(--bg), #020617);
      color: var(--text);
      min-height: 100vh;
    }}
    .shell {{ max-width: 1180px; margin: 0 auto; padding: 34px 18px; }}
    .top {{
      display: flex;
      justify-content: space-between;
      gap: 16px;
      align-items: flex-start;
      margin-bottom: 24px;
    }}
    h1 {{ margin: 0 0 8px; font-size: 32px; }}
    p {{ margin: 0; color: var(--muted); line-height: 1.5; }}
    .badge {{
      border: 1px solid var(--line);
      background: rgba(31, 41, 55, .75);
      padding: 10px 14px;
      border-radius: 999px;
      color: var(--ok);
      font-weight: 700;
      white-space: nowrap;
    }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 14px;
    }}
    .card {{
      display: block;
      text-decoration: none;
      color: var(--text);
      background: rgba(17, 24, 39, .88);
      border: 1px solid var(--line);
      border-radius: 18px;
      padding: 18px;
      box-shadow: 0 18px 50px rgba(0,0,0,.25);
    }}
    .card strong {{ display: block; font-size: 17px; margin-bottom: 8px; }}
    .card span {{ color: var(--blue); font-size: 13px; word-break: break-all; }}
    .footer {{ margin-top: 24px; color: var(--muted); font-size: 13px; }}
  </style>
</head>
<body>
  <!-- FAZ_4_R_LIVE_HTML_INDEX -->
  <!-- CLOSED_POLICY_GATE_REFERENCE_ONLY -->
  <main class="shell">
    <section class="top">
      <div>
        <h1>Pix2pi FAZ 4-R HTML Checkpoints</h1>
        <p>Pilot / Import / UAT Final Closure içinde üretilen HTML kontrol yüzeyleri.</p>
      </div>
      <div class="badge">LIVE HTML READY</div>
    </section>
    <section class="grid">
      {''.join(cards)}
    </section>
    <section class="footer">
      Generated at: {escape(now)} · Static checkpoint pages only. No live provider, no workflow mutation, no event publish.
    </section>
  </main>
</body>
</html>
"""

(dest / "index.html").write_text(index_html, encoding="utf-8")

manifest = {
    "phase": "FAZ_4_R",
    "artifact": "LIVE_HTML_PUBLISH_MANIFEST",
    "status": "READY",
    "generated_at": now,
    "web_root": str(dest.parent),
    "publish_root": str(dest),
    "published_count": len(published),
    "required_html": required,
    "missing_required_html": missing,
    "published": published,
    "public_base_urls": [
        "https://www.pix2pi.com.tr/faz4r/",
        "https://pix2pi.com.tr/faz4r/"
    ],
    "closed_policy_reference": "CLOSED_POLICY_GATE_REFERENCE_ONLY"
}

manifest_file.parent.mkdir(parents=True, exist_ok=True)
manifest_file.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print("FAZ4R_HTML_PUBLISH_STATUS=PASS")
print(f"FAZ4R_HTML_PUBLISHED_COUNT={len(published)}")
print(f"FAZ4R_HTML_DEST={dest}")
print(f"FAZ4R_HTML_MANIFEST={manifest_file}")
PY_EOF

find "$DEST" -type d -exec chmod 755 {} \;
find "$DEST" -type f -exec chmod 644 {} \;

echo "===== FAZ 4-R HTML LIVE PUBLISH RUNTIME COMPLETE ====="
