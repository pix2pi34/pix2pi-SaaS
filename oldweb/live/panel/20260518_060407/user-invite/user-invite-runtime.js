(function(){
  const endpoint="/api/panel/user-invite/send";
  const $=n=>document.querySelector(`[name="${n}"]`);
  const v=n=>($(`${n}`)?.value||"").trim();
  async function submit(e){
    e.preventDefault();
    const body={
      tenant_id:v("tenant_id"), business_name:v("business_name"), email:v("email"),
      display_name:v("display_name"), role_code:v("role_code"),
      invited_by_user_id:"user-owner-e2e", correlation_id:"corr-web-348"
    };
    const status=document.querySelector("[data-invite-status]");
    const pre=document.querySelector("[data-invite-payload]");
    if(pre) pre.textContent=JSON.stringify(body,null,2);
    const res=await fetch(endpoint,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
    const json=await res.json();
    if(pre) pre.textContent=JSON.stringify(json,null,2);
    if(status){ status.textContent=res.status===201?"Davet gönderildi":"Hata: "+(json.error||res.status); status.dataset.status=res.status===201?"ok":"error"; }
  }
  document.addEventListener("submit",e=>{ if(e.target.matches("[data-user-invite-form]")) submit(e); });
})();
