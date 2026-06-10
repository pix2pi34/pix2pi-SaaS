import React, { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import "./style.css";

const MARKER = "PHOENIX_DELETE_ROUTES_BEFORE_404_UI_MARKER";
const API_BASE = "/owner-panel/register-approvals/api";

const STATUS_LABEL = {
  PENDING: "Bekleyen",
  APPROVED: "Onaylı",
  ACTIVE: "Aktif",
  REJECTED: "Reddedildi",
  UNKNOWN: "Bilinmiyor",
};

function text(value, fallback = "-") {
  if (value === undefined || value === null) return fallback;
  const s = String(value).trim();
  return s ? s : fallback;
}

function status(value) {
  return text(value, "UNKNOWN").toUpperCase();
}

function deepPick(obj, keys, fallback = "-") {
  if (!obj || typeof obj !== "object") return fallback;

  for (const key of keys) {
    if (obj[key] !== undefined && obj[key] !== null && String(obj[key]).trim() !== "") {
      return obj[key];
    }
  }

  for (const nestedKey of ["application", "company", "tenant", "owner", "contact", "data", "payload", "raw"]) {
    const nested = obj[nestedKey];
    if (nested && typeof nested === "object") {
      const found = deepPick(nested, keys, "");
      if (found !== "") return found;
    }
  }

  return fallback;
}

function extractArray(payload) {
  if (Array.isArray(payload)) return payload;

  const candidates = [
    payload?.companies,
    payload?.applications,
    payload?.items,
    payload?.data,
    payload?.results,
    payload?.records,
    payload?.rows,
  ];

  for (const item of candidates) {
    if (Array.isArray(item)) return item;
  }

  return [];
}

function normalize(raw, index) {
  const file = text(deepPick(raw, ["file", "filename", "name"], ""), "");
  const id = text(deepPick(raw, ["id", "application_id", "applicationId", "code"], ""), file || `APP-${index + 1}`);
  const email = text(deepPick(raw, ["email", "owner_email", "contact_email", "user_email"], "-"));
  const company = text(deepPick(raw, ["company", "company_name", "companyName", "business_name", "businessName", "tenant_name", "title"], "-"));
  const st = status(deepPick(raw, ["status", "application_status", "state"], "UNKNOWN"));
  const phone = text(deepPick(raw, ["phone", "gsm", "mobile", "telephone", "tel"], "-"));
  const owner = text(deepPick(raw, ["owner_name", "authorized_name", "authorizedName", "full_name", "fullName", "contact_name", "name"], "-"));
  const tenantId = text(deepPick(raw, ["tenant_id", "tenantId"], "-"));
  const createdAt = text(deepPick(raw, ["created_at", "createdAt", "created", "submitted_at", "submittedAt"], "-"));
  const updatedAt = text(deepPick(raw, ["updated_at", "updatedAt", "updated", "approved_at", "rejected_at"], "-"));

  return {
    raw,
    key: `${id}|${file || index}`,
    id,
    file: file || id,
    email,
    company,
    status: st,
    phone,
    owner,
    tenantId,
    createdAt,
    updatedAt,
    searchable: [id, file, email, company, st, phone, owner, tenantId].join(" ").toLowerCase(),
  };
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    credentials: "same-origin",
    cache: "no-store",
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
    ...options,
  });

  let body = null;
  try {
    body = await response.json();
  } catch {
    body = null;
  }

  if (!response.ok) {
    throw new Error(body?.message || body?.error || `HTTP ${response.status}`);
  }

  return body;
}

function Badge({ value }) {
  const st = status(value);
  return <span className={`badge badge-${st.toLowerCase()}`}>{STATUS_LABEL[st] || st}</span>;
}

function App() {
  const [rows, setRows] = useState([]);
  const [selectedKey, setSelectedKey] = useState("");
  const [q, setQ] = useState("");
  const [filter, setFilter] = useState("ALL");
  const [notice, setNotice] = useState({ type: "info", text: "Kayıtlı şirketler yükleniyor…" });
  const [lastRefresh, setLastRefresh] = useState("");
  const [busy, setBusy] = useState("");

  const filtered = useMemo(() => {
    const query = q.trim().toLowerCase();
    return rows.filter((row) => {
      const statusOk = filter === "ALL" || row.status === filter;
      const queryOk = !query || row.searchable.includes(query);
      return statusOk && queryOk;
    });
  }, [rows, q, filter]);

  const selected = useMemo(() => {
    return rows.find((row) => row.key === selectedKey) || filtered[0] || rows[0] || null;
  }, [rows, filtered, selectedKey]);

  const counts = useMemo(() => {
    const base = { TOTAL: rows.length, PENDING: 0, APPROVED: 0, ACTIVE: 0, REJECTED: 0, UNKNOWN: 0 };
    for (const row of rows) base[row.status] = (base[row.status] || 0) + 1;
    return base;
  }, [rows]);

  async function load(showNotice = true) {
    if (showNotice) setNotice({ type: "info", text: "API okunuyor…" });

    try {
      const attempts = [
        `${API_BASE}/companies`,
        `${API_BASE}/applications`,
        `${API_BASE}/list`,
      ];

      let finalList = [];
      let finalEndpoint = "";

      for (const endpoint of attempts) {
        try {
          const payload = await fetchJson(endpoint);
          const list = extractArray(payload);
          if (list.length > 0) {
            finalList = list;
            finalEndpoint = endpoint;
            break;
          }
        } catch {
          continue;
        }
      }

      const normalized = finalList
        .map(normalize)
        .filter((row) => !String(row.file || "").startsWith(".backup."))
        .sort((a, b) => {
        const order = { PENDING: 0, APPROVED: 1, ACTIVE: 2, REJECTED: 3, UNKNOWN: 4 };
        const as = order[a.status] ?? 9;
        const bs = order[b.status] ?? 9;
        if (as !== bs) return as - bs;
        return String(b.updatedAt).localeCompare(String(a.updatedAt));
      });

      setRows(normalized);

      if (!selectedKey && normalized.length) {
        setSelectedKey(normalized[0].key);
      }

      setLastRefresh(new Date().toLocaleString("tr-TR"));
      setNotice({
        type: normalized.length ? "success" : "warning",
        text: normalized.length
          ? `${normalized.length} kayıt yüklendi. Kaynak: ${finalEndpoint}`
          : "API döndü ama liste alanı boş geldi.",
      });
    } catch (error) {
      setRows([]);
      setNotice({ type: "error", text: `Kayıtlar okunamadı: ${error.message}` });
    }
  }

  async function mutate(row, action) {
    if (!row || row.status !== "PENDING") {
      setNotice({ type: "warning", text: "Sadece bekleyen başvurularda onay/red yapılabilir." });
      return;
    }

    const actionText = action === "approve" ? "onaylamak" : "reddetmek";
    if (!window.confirm(`${row.company} başvurusunu ${actionText} istediğine emin misin?`)) return;

    setBusy(row.key);
    setNotice({ type: "info", text: "İşlem yapılıyor…" });

    const payload = {
      id: row.id,
      file: row.file,
      filename: row.file,
      application_id: row.id,
      status: action === "approve" ? "APPROVED" : "REJECTED",
    };

    const endpoints = action === "approve"
      ? [`${API_BASE}/approve`, `${API_BASE}/applications/${encodeURIComponent(row.id)}/approve`]
      : [`${API_BASE}/reject`, `${API_BASE}/applications/${encodeURIComponent(row.id)}/reject`];

    let lastError = null;
    for (const endpoint of endpoints) {
      try {
        await fetchJson(endpoint, { method: "POST", body: JSON.stringify(payload) });
        setNotice({ type: "success", text: action === "approve" ? "Başvuru onaylandı." : "Başvuru reddedildi." });
        await load(false);
        setBusy("");
        return;
      } catch (error) {
        lastError = error;
      }
    }

    setBusy("");
    setNotice({ type: "error", text: `İşlem tamamlanamadı: ${lastError?.message || "Bilinmeyen hata"}` });
  }

  async function deleteRow(row) {
    if (!row) return;

    const confirm1 = window.confirm(`${row.company} kaydını silmek istediğine emin misin?`);
    if (!confirm1) return;

    const confirm2 = window.confirm("Bu işlem kayıt dosyasını kaldırabilir. Devam edilsin mi?");
    if (!confirm2) return;

    setBusy(row.key);
    setNotice({ type: "info", text: "Silme işlemi deneniyor…" });

    const payload = {
      id: row.id,
      file: row.file,
      filename: row.file,
      application_id: row.id,
      email: row.email,
      company: row.company,
    };

    const endpoints = [
      { url: `${API_BASE}/delete`, method: "POST", body: JSON.stringify(payload) },
      { url: `${API_BASE}/applications/${encodeURIComponent(row.id)}`, method: "DELETE" },
      { url: `${API_BASE}/companies/${encodeURIComponent(row.id)}`, method: "DELETE" },
      { url: `${API_BASE}/applications/${encodeURIComponent(row.file)}`, method: "DELETE" },
      { url: `${API_BASE}/companies/${encodeURIComponent(row.file)}`, method: "DELETE" },
    ];

    let lastError = null;

    for (const endpoint of endpoints) {
      try {
        await fetchJson(endpoint.url, {
          method: endpoint.method,
          body: endpoint.body,
        });

        setNotice({ type: "success", text: "Kayıt silindi." });
        setSelectedKey("");
        await load(false);
        setBusy("");
        return;
      } catch (error) {
        lastError = error;
      }
    }

    setBusy("");
    setNotice({
      type: "error",
      text: `Silme endpointi bulunamadı veya işlem reddedildi: ${lastError?.message || "Bilinmeyen hata"}`,
    });
  }

  function logout() {
    window.location.href = "/owner-panel/register-approvals/logout";
  }

  useEffect(() => {
    load(true);
    const timer = window.setInterval(() => load(false), 60000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <main className="page" data-marker={MARKER}>
      <header className="top">
        <section>
          <div className="kicker">Phoenix Owner Panel</div>
          <h1>Kayıtlı Şirketler</h1>
          <p>Başvuruları, onaylı firmaları ve aktif hesapları tek ekranda gör.</p>
        </section>

        <section className="topButtons">
          <button className="btn light" onClick={() => load(true)}>Yenile</button>
          <button className="btn dark" onClick={logout}>Çıkış</button>
        </section>
      </header>

      <section className={`notice notice-${notice.type}`}>
        <strong>{notice.text}</strong>
        {lastRefresh ? <span>Son yenileme: {lastRefresh}</span> : null}
      </section>

      <section className="stats">
        <button className={filter === "ALL" ? "stat active" : "stat"} onClick={() => setFilter("ALL")}><span>Toplam</span><b>{counts.TOTAL}</b></button>
        <button className={filter === "PENDING" ? "stat active" : "stat"} onClick={() => setFilter("PENDING")}><span>Bekleyen</span><b>{counts.PENDING || 0}</b></button>
        <button className={filter === "APPROVED" ? "stat active" : "stat"} onClick={() => setFilter("APPROVED")}><span>Onaylı</span><b>{counts.APPROVED || 0}</b></button>
        <button className={filter === "ACTIVE" ? "stat active" : "stat"} onClick={() => setFilter("ACTIVE")}><span>Aktif</span><b>{counts.ACTIVE || 0}</b></button>
        <button className={filter === "REJECTED" ? "stat active" : "stat"} onClick={() => setFilter("REJECTED")}><span>Reddedilen</span><b>{counts.REJECTED || 0}</b></button>
      </section>

      <section className="toolbar">
        <label>
          <span>Arama</span>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Firma, e-posta, telefon, tenant veya başvuru ID" />
        </label>

        <label>
          <span>Durum</span>
          <select value={filter} onChange={(e) => setFilter(e.target.value)}>
            <option value="ALL">Tümü</option>
            <option value="PENDING">Bekleyen</option>
            <option value="APPROVED">Onaylı</option>
            <option value="ACTIVE">Aktif</option>
            <option value="REJECTED">Reddedilen</option>
          </select>
        </label>
      </section>

      <section className="grid">
        <section className="panel listPanel">
          <div className="panelHead">
            <strong>Şirket Listesi</strong>
            <span>{filtered.length} kayıt</span>
          </div>

          <div className="rows">
            {filtered.length ? filtered.map((row) => (
              <button
                key={row.key}
                className={selected?.key === row.key ? "row selected" : "row"}
                onClick={() => setSelectedKey(row.key)}
              >
                <span>
                  <b>{row.company}</b>
                  <small>{row.email}</small>
                </span>
                <span className="rowRight">
                  <Badge value={row.status} />
                  <small>{row.file}</small>
                </span>
              </button>
            )) : (
              <div className="empty">
                <b>Kayıt görünmüyor</b>
                <span>API boş döndüyse veri/API; arama filtresi doluysa filtre sorunudur.</span>
              </div>
            )}
          </div>
        </section>

        <aside className="panel detailPanel">
          <div className="panelHead">
            <strong>Şirket Detayı</strong>
            {selected ? <Badge value={selected.status} /> : null}
          </div>

          {selected ? (
            <>
              <section className="heroCard">
                <span>Firma</span>
                <h2>{selected.company}</h2>
                <p>{selected.email}</p>
              </section>

              <section className="detailGrid">
                <div><span>Başvuru ID</span><b>{selected.id}</b></div>
                <div><span>Dosya</span><b>{selected.file}</b></div>
                <div><span>Yetkili</span><b>{selected.owner}</b></div>
                <div><span>Telefon</span><b>{selected.phone}</b></div>
                <div><span>Tenant</span><b>{selected.tenantId}</b></div>
                <div><span>Güncelleme</span><b>{selected.updatedAt}</b></div>
              </section>

              <section className="actions">
                <button className="btn approve" disabled={selected.status !== "PENDING" || busy === selected.key} onClick={() => mutate(selected, "approve")}>Onayla</button>
                <button className="btn reject" disabled={selected.status !== "PENDING" || busy === selected.key} onClick={() => mutate(selected, "reject")}>Reddet</button>
                <button className="btn delete" disabled={busy === selected.key} onClick={() => deleteRow(selected)}>Sil</button>
              </section>

              <section className="note">
                {selected.status === "PENDING"
                  ? "Bu başvuru bekliyor. Onay, red veya silme işlemi yapılabilir."
                  : "Bu kayıt bekleme durumunda değil. Onay/red kapalı; silme butonu admin temizliği için açıktır."}
              </section>
            </>
          ) : (
            <div className="empty">
              <b>Şirket seçilmedi</b>
              <span>Soldan bir kayıt seç.</span>
            </div>
          )}
        </aside>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
