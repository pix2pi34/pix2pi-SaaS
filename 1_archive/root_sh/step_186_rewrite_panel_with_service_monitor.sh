#!/bin/bash
set -e

cat <<'HTML' > /opt/pix2pi/nginx/panel_index.html
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Pix2pi Admin Panel</title>
  <style>
    body{font-family:system-ui,Arial,sans-serif;max-width:980px;margin:40px auto;padding:0 16px;background:#f7f7f7;color:#111}
    .card{background:#fff;border:1px solid #ddd;border-radius:14px;padding:18px;margin:14px 0}
    h1,h2{margin-top:0}
    .ok{color:#0a7d32;font-weight:700}
    .warn{color:#b00020;font-weight:700}
    .muted{color:#666}
    a{color:#0a58ca;text-decoration:none}
    code{background:#f3f3f3;padding:2px 6px;border-radius:6px}
    ul{padding-left:20px}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}
    .service{border:1px solid #e5e5e5;border-radius:12px;padding:12px;background:#fafafa}
    .service-name{font-weight:700;margin-bottom:6px}
  </style>
</head>
<body>
  <h1>Pix2pi Admin Panel</h1>

  <div class="card">
    <h2>Durum</h2>
    <div id="genelDurum">Yukleniyor...</div>
  </div>

  <div class="card">
    <h2>Servis Monitörü</h2>
    <div class="muted">Otomatik yenileme: 10 saniye</div>
    <p class="muted">Son guncelleme: <span id="guncellemeSaati">-</span></p>
    <div id="serviceGrid" class="grid"></div>
  </div>

  <div class="card">
    <h2>Hizli Baglantilar</h2>
    <ul>
      <li><a href="/health">Panel Health</a></li>
      <li><a href="/api/health">API Health</a></li>
      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
    </ul>
  </div>

  <script>
    function durumClass(durum) {
      if (durum === "RUNNING" || durum === "HEALTHY") return "ok";
      return "warn";
    }

    async function yukle() {
      try {
        const res = await fetch("/service_status.json?_=" + Date.now());
        const data = await res.json();

        document.getElementById("guncellemeSaati").textContent = data.guncellendi || "-";

        const grid = document.getElementById("serviceGrid");
        grid.innerHTML = "";

        const anahtarlar = [
          "api_gateway",
          "identity",
          "auth",
          "stock_service",
          "accounting_service",
          "nats",
          "redis",
          "nginx"
        ];

        let saglikli = 0;

        anahtarlar.forEach(key => {
          const item = data[key] || { durum: "UNKNOWN" };
          if (item.durum === "RUNNING" || item.durum === "HEALTHY") {
            saglikli++;
          }

          const div = document.createElement("div");
          div.className = "service";
          div.innerHTML = `
            <div class="service-name">${key}</div>
            <div class="${durumClass(item.durum)}">${item.durum}</div>
          `;
          grid.appendChild(div);
        });

        const genel = document.getElementById("genelDurum");
        if (saglikli === anahtarlar.length) {
          genel.innerHTML = '<span class="ok">Tum kritik servisler ayakta</span>';
        } else {
          genel.innerHTML = '<span class="warn">Bazi servisler ayakta degil</span>';
        }
      } catch (err) {
        document.getElementById("genelDurum").innerHTML = '<span class="warn">Servis durumu okunamadi</span>';
      }
    }

    yukle();
    setInterval(yukle, 10000);
  </script>
</body>
</html>
HTML

nginx -t
systemctl reload nginx

echo "OK ✅ panel service monitor ile guncellendi"
