import React, { useState } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'

function App() {
  const [form, setForm] = useState({
    vergiNo: '',
    vergiDairesi: '',
    firmaAdi: '',
    adres: '',
    ilce: '',
    il: '',
    telNo: '',
    webAdresi: '',
    mersisNo: '',
    ticaretSicilNo: '',
    mail: '',
    sifre: '',
    sifreTekrar: ''
  })

  const [message, setMessage] = useState('')

  function update(name, value) {
    setForm(prev => ({ ...prev, [name]: value }))
  }

  async function submit(e) {
    e.preventDefault()

    if (form.sifre.length < 6) {
      setMessage('Hata: Şifre en az 6 karakter olmalı.')
      return
    }

    if (form.sifre !== form.sifreTekrar) {
      setMessage('Hata: Şifre ve Şifre Tekrar aynı olmalı.')
      return
    }

    setMessage('Başvuru alındı. Durum: PENDING. Tenant admin onayı olmadan açılmayacak.')

    try {
      await fetch('/api/customer-register/applications', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form)
      })
    } catch (_) {}
  }

  return (
    <main className="page" data-marker="PIX2PI_REGISTER_PAGE_REACT_PASSWORD_MARKER">
      <section className="hero">
        <p className="eyebrow">Pix2pi SaaS ERP</p>
        <h1>İşletme Kaydı Başlat</h1>
        <p className="lead">
          Bilgilerinizi girin. Başvuru <b>PENDING</b> durumunda alınır; tenant hemen açılmaz.
        </p>
      </section>

      <form className="card" onSubmit={submit}>
        <div className="note">
          <b>Not:</b> Yıldızlı (*) alanların doldurulması zorunlu değildir.
        </div>

        <div className="grid">
          <label>Vergi No<input required value={form.vergiNo} onChange={e => update('vergiNo', e.target.value)} /></label>
          <label>Vergi Dairesi<input required value={form.vergiDairesi} onChange={e => update('vergiDairesi', e.target.value)} /></label>
          <label>Firmanızın Adı<input required value={form.firmaAdi} onChange={e => update('firmaAdi', e.target.value)} /></label>
          <label>Adres<input required value={form.adres} onChange={e => update('adres', e.target.value)} /></label>
          <label>İlçe<input required value={form.ilce} onChange={e => update('ilce', e.target.value)} /></label>
          <label>İl<input required value={form.il} onChange={e => update('il', e.target.value)} /></label>
          <label>* Tel No<input value={form.telNo} onChange={e => update('telNo', e.target.value)} /></label>
          <label>* Web Adresi<input value={form.webAdresi} onChange={e => update('webAdresi', e.target.value)} /></label>
          <label>MERSİS No<input required value={form.mersisNo} onChange={e => update('mersisNo', e.target.value)} /></label>
          <label>* Ticaret Sicil No<input value={form.ticaretSicilNo} onChange={e => update('ticaretSicilNo', e.target.value)} /></label>
          <label>Mail<input required type="email" value={form.mail} onChange={e => update('mail', e.target.value)} /></label>
          <label>Şifre<input required type="password" minLength="6" value={form.sifre} onChange={e => update('sifre', e.target.value)} /></label>
          <label>Şifre Tekrar<input required type="password" minLength="6" value={form.sifreTekrar} onChange={e => update('sifreTekrar', e.target.value)} /></label>
        </div>

        <button className="submit" type="submit">Başvuruyu Gönder</button>

        {message && <div className={message.startsWith('Hata') ? 'error' : 'success'}>{message}</div>}
      </form>
    </main>
  )
}

createRoot(document.getElementById('root')).render(<App />)
