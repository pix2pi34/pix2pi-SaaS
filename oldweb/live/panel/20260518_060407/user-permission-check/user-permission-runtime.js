(function(){
  const checkEndpoint="/api/panel/permission/check";
  const protectedEndpoint="/api/panel/permission/protected-action";
  async function post(url, body){
    const r=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
    const j=await r.json();
    return {status:r.status,json:j};
  }
  window.PIX2PI_353_USER_PERMISSION={checkEndpoint,protectedEndpoint,post};
})();
