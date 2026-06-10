import React, { useState } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

function App() {
  const [form, setForm] = useState({
    companyName: "",
    ownerName: "",
    email: "",
    phone: "",
    password: ""
  });

  const updateField = (event) => {
    const { name, value } = event.target;
    setForm((current) => ({
      ...current,
      [name]: value
    }));
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    alert("Kayıt formu hazır. API bağlantısı eklendiğinde gönderim buradan yapılacak.");
  };

  return (
    <>
      <nav className="top-menu" aria-label="Kayıt menüsü">
        <a href="/">Ana Sayfa</a>
        <a href="/Grs/">Giriş</a>
      </nav>

      <main className="page">
        <form className="register-box" onSubmit={handleSubmit}>
          <h1>Kayıt Ol</h1>

          <label htmlFor="companyName">Şirket / İşletme Adı</label>
          <input
            id="companyName"
            name="companyName"
            type="text"
            placeholder="Şirket veya işletme adı"
            value={form.companyName}
            onChange={updateField}
          />

          <label htmlFor="ownerName">Yetkili Ad Soyad</label>
          <input
            id="ownerName"
            name="ownerName"
            type="text"
            placeholder="Yetkili ad soyad"
            value={form.ownerName}
            onChange={updateField}
          />

          <label htmlFor="email">E-posta</label>
          <input
            id="email"
            name="email"
            type="email"
            placeholder="E-posta adresi"
            value={form.email}
            onChange={updateField}
          />

          <label htmlFor="phone">Telefon</label>
          <input
            id="phone"
            name="phone"
            type="tel"
            placeholder="Telefon numarası"
            value={form.phone}
            onChange={updateField}
          />

          <label htmlFor="password">Şifre</label>
          <input
            id="password"
            name="password"
            type="password"
            placeholder="Şifre"
            value={form.password}
            onChange={updateField}
          />

          <button type="submit">Kayıt Ol</button>

          <a className="small-link" href="/Grs/">
            Hesabın varsa Giriş Yap
          </a>
        </form>
      </main>
    </>
  );
}

createRoot(document.getElementById("root")).render(<App />);
