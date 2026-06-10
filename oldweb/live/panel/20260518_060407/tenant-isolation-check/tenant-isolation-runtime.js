(function(){
  const readEndpoint="/api/panel/tenant-isolation/read";
  const writeEndpoint="/api/panel/tenant-isolation/write";
  async function post(url, body){
    const r=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
    const j=await r.json();
    return {status:r.status,json:j};
  }
  window.PIX2PI_352_TENANT_ISOLATION={readEndpoint,writeEndpoint,post};
})();
