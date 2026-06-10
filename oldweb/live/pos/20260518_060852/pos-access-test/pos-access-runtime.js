(function(){
  const createEndpoint="/api/pos/access/session-create";
  const checkEndpoint="/api/pos/access/check";
  async function post(url, body){
    const r=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
    const j=await r.json();
    return {status:r.status,json:j};
  }
  window.PIX2PI_351_POS_ACCESS={createEndpoint,checkEndpoint,post};
})();
