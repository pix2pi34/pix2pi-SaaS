(function(){
  const roleEndpoint="/api/panel/users/role-assign";
  const checkEndpoint="/api/panel/rbac/check";
  const $=n=>document.querySelector(`[name="${n}"]`);
  const v=n=>($(`${n}`)?.value||"").trim();
  async function post(url, body){
    const r=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
    const j=await r.json(); return {status:r.status,json:j};
  }
  async function submit(e){
    e.preventDefault();
    const body={tenant_id:v("tenant_id"),user_id:v("user_id"),display_name:v("display_name"),role_code:v("role_code"),assigned_by_user_id:v("assigned_by_user_id")};
    const pre=document.querySelector("[data-role-payload]");
    const st=document.querySelector("[data-role-status]");
    const res=await post(roleEndpoint,body);
    if(pre) pre.textContent=JSON.stringify(res.json,null,2);
    if(st){ st.textContent=res.status===201?"Rol atandı":"Hata: "+(res.json.error||res.status); st.dataset.status=res.status===201?"ok":"error"; }
  }
  window.PIX2PI_321_RBAC={roleEndpoint,checkEndpoint};
  document.addEventListener("submit",e=>{ if(e.target.matches("[data-role-form]")) submit(e); });
})();
