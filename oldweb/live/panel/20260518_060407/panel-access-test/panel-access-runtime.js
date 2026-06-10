(function(){
  const createEndpoint="/api/panel/access/session-create";
  const checkEndpoint="/api/panel/access/check";
  async function post(url, body){
    const r=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
    const j=await r.json(); return {status:r.status,json:j};
  }
  window.PIX2PI_350_PANEL_ACCESS={createEndpoint,checkEndpoint,post};
})();
