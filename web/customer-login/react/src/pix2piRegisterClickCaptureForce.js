(function () {
  const marker = 'PIX2PI_LOGIN_REGISTER_CLICK_CAPTURE_FORCE_REACT';
  const target = '/customer-register/react/';

  function textOf(el) {
    return (el && el.textContent ? el.textContent : '').replace(/\s+/g, ' ').trim();
  }

  function isRegisterClickTarget(el) {
    let cur = el;
    for (let i = 0; cur && i < 8; i += 1) {
      const tag = (cur.tagName || '').toLowerCase();
      const txt = textOf(cur);

      if ((tag === 'button' || tag === 'a' || cur.getAttribute?.('role') === 'button') && txt === 'Kayıt Ol') {
        return cur;
      }

      cur = cur.parentElement;
    }

    return null;
  }

  function go(ev) {
    const hit = isRegisterClickTarget(ev.target);
    if (!hit) return;

    ev.preventDefault();
    ev.stopPropagation();
    if (ev.stopImmediatePropagation) ev.stopImmediatePropagation();

    try {
      localStorage.setItem('PIX2PI_REGISTER_FORCE_TARGET', target);
      localStorage.setItem('PIX2PI_REGISTER_FORCE_MARKER', marker);
    } catch (_) {}

    window.location.assign(target);
  }

  function markButtons() {
    const items = Array.from(document.querySelectorAll('button, a, [role="button"]'));
    items.forEach((el) => {
      if (textOf(el) === 'Kayıt Ol') {
        el.setAttribute('data-pix2pi-register-force-marker', marker);
        el.setAttribute('data-pix2pi-register-force-target', target);

        if ((el.tagName || '').toLowerCase() === 'button') {
          el.setAttribute('type', 'button');
        }

        if ((el.tagName || '').toLowerCase() === 'a') {
          el.setAttribute('href', target);
        }
      }
    });
  }

  window.addEventListener('click', go, true);
  document.addEventListener('click', go, true);

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', markButtons);
  } else {
    markButtons();
  }

  setTimeout(markButtons, 300);
  setTimeout(markButtons, 1000);
  setTimeout(markButtons, 2000);

  try {
    const observer = new MutationObserver(markButtons);
    observer.observe(document.documentElement, { childList: true, subtree: true });
  } catch (_) {}
})();
