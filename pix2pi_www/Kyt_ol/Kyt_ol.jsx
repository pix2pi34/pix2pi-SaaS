import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import "./Kyt_ol.css";

function KytOl() {
  const [form, setForm] = useState({
    firma: "",
    yetkili: "",
    email: "",
    telefon: "",
    sifre: "",
    sifreTekrar: "",
    onay: false
  });

  const [mesaj, setMesaj] = useState("");

  const uygun = useMemo(() => {
    return (
      form.firma.trim().length >= 2 &&
      form.yetkili.trim().length >= 2 &&
      form.email.includes("@") &&
      form.telefon.trim().length >= 10 &&
      form.sifre.length >= 8 &&
      form.sifre === form.sifreTekrar &&
      form.onay
    );
  }, [form]);

  function yaz(e) {
    const { name, value, checked, type } = e.target;
    setForm((x) => ({ ...x, [name]: type === "checkbox" ? checked : value }));
  }

  function gonder(e) {
    e.preventDefault();

    if (!uygun) {
      setMesaj("Lütfen tüm zorunlu alanları doğru doldurun.");
      return;
    }

    setMesaj("Başvurunuz alındı. Onay sonrası bilgilendirileceksiniz.");
  }

  return (
    <main className="kyt-page" data-marker="PIX2PI_KYT_OL_LIVE_MARKER">
      <section className="kyt-wrap">
        <div className="kyt-text">
          <div className="kyt-logo">Pix2pi</div>
          <h1>Kayıt Ol</h1>
          <p>
            İşletmenizi Pix2pi ticaret operasyon sistemine taşımak için
            başvuru formunu doldurun.
          </p>

          <div className="kyt-steps">
            <div><b>1</b><span>Firma bilgileri alınır</span></div>
            <div><b>2</b><span>Yetkili kullanıcı kontrol edilir</span></div>
            <div><b>3</b><span>Onay sonrası panel erişimi açılır</span></div>
          </div>
        </div>

        <form className="kyt-card" onSubmit={gonder}>
          <h2>Yeni Hesap Başvurusu</h2>

          <label>
            <span>Firma / İşletme Adı</span>
            <input name="firma" value={form.firma} onChange={yaz} />
          </label>

          <label>
            <span>Yetkili Ad Soyad</span>
            <input name="yetkili" value={form.yetkili} onChange={yaz} />
          </label>

          <label>
            <span>E-posta</span>
            <input name="email" type="email" value={form.email} onChange={yaz} />
          </label>

          <label>
            <span>Telefon</span>
            <input name="telefon" type="tel" value={form.telefon} onChange={yaz} />
          </label>

          <div className="kyt-two">
            <label>
              <span>Şifre</span>
              <input name="sifre" type="password" value={form.sifre} onChange={yaz} />
            </label>

            <label>
              <span>Şifre Tekrar</span>
              <input name="sifreTekrar" type="password" value={form.sifreTekrar} onChange={yaz} />
            </label>
          </div>

          <label className="kyt-check">
            <input name="onay" type="checkbox" checked={form.onay} onChange={yaz} />
            <span>KVKK ve kullanım şartları bilgilendirmesini okudum.</span>
          </label>

          <button type="submit">Kayıt Başvurusu Gönder</button>

          {mesaj && <p className="kyt-msg">{mesaj}</p>}

          <p className="kyt-login">
            Hesabınız var mı? <a href="../Grs/Grs.html">Giriş yap</a>
          </p>
        </form>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<KytOl />);
