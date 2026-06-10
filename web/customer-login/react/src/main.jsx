import './pix2piRegisterClickCaptureForce.js';
import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

async function postJSON(url, payload) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok || !data.ok) {
    throw new Error(data.message || "İşlem başarısız.");
  }

  return data;
}

function App() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("123");
  const [code, setCode] = useState("");
  const [step, setStep] = useState("password");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({ type: "ok", text: "" });

  async function requestCode(event) {
    event.preventDefault();
    setLoading(true);
    setMessage({ type: "ok", text: "" });

    try {
      const data = await postJSON("/auth-api/request-login-code", { email, password, ui: "react" });
      setStep("code");
      setMessage({ type: "ok", text: data.message });
    } catch (error) {
      setMessage({ type: "err", text: error.message });
    } finally {
      setLoading(false);
    }
  }

  async function verifyCode(event) {
    event.preventDefault();
    setLoading(true);
    setMessage({ type: "ok", text: "" });

    try {
      const data = await postJSON("/auth-api/verify-login-code", { email, code, ui: "react" });
      setMessage({ type: "ok", text: "Kod doğru. Panel açılıyor..." });
      setTimeout(() => { window.location.href = data.redirect || "/owner-panel/react/"; }, 500);
    } catch (error) {
      setMessage({ type: "err", text: error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="page">
      <section className="shell">
        <div className="brand">
          <div className="logo">PIX2PI</div>
          <h1>Müşteri Girişi</h1>
          <p>E-posta adresinizle giriş yapın veya işletme kaydı başlatın.</p>
        </div>

        {step === "password" ? (
          <form className="card" onSubmit={requestCode}>
            <div className="step"><span>1</span> E-posta ve şifre</div>

            <label>
              E-posta
              <input value={email} onChange={(e) => setEmail(e.target.value)} type="email" autoComplete="email" placeholder="ornek@mail.com" />
            </label>

            <label>
              Şifre
              <input value={password} onChange={(e) => setPassword(e.target.value)} type="password" autoComplete="current-password" />
            </label>

            <div className="actions">
              <button className="primary" disabled={loading}>{loading ? "Kod gönderiliyor..." : "Mail Kodu Gönder"}</button>
              <button className="secondary" type="button" onClick={() => window.location.href = "/customer-register/react/"}>Kayıt Ol</button>
            </div>

            {message.text && <div className={`message ${message.type}`}>{message.text}</div>}
          </form>
        ) : (
          <form className="card" onSubmit={verifyCode}>
            <div className="step"><span>2</span> Mail kodu doğrulama</div>

            <label>
              Mail Kodu
              <input value={code} onChange={(e) => setCode(e.target.value)} inputMode="numeric" placeholder="6 haneli kod" autoFocus />
            </label>

            <button className="primary" disabled={loading}>{loading ? "Kontrol ediliyor..." : "Kodu Doğrula ve Giriş Yap"}</button>
            <button type="button" className="link" onClick={() => setStep("password")}>E-postayı değiştir</button>

            {message.text && <div className={`message ${message.type}`}>{message.text}</div>}
          </form>
        )}

        <div className="note">Test şifresi: 123 · Gönderen: no-reply@pix2pi.com.tr</div>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
