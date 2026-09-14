const TABLES={demand:'zico_demand',distributors:'zico_distributors',reviews:'zico_reviews',club:'zico_club_events',orders:'zico_orders'};

// Security helpers: strict origin handling, basic abuse throttling and bounded input.
const buckets=new Map();
function originAllowed(req){
  const configured=(process.env.ZICO_ALLOWED_ORIGINS||'').split(',').map(s=>s.trim()).filter(Boolean);
  const origin=req.headers?.origin||'';
  if(!origin) return configured[0]||'';
  return configured.includes(origin)?origin:'';
}
function rejectBadOrigin(req){
  const configured=(process.env.ZICO_ALLOWED_ORIGINS||'').split(',').map(s=>s.trim()).filter(Boolean);
  const origin=req.headers?.origin||'';
  return configured.length>0 && origin && !configured.includes(origin);
}
function rateLimit(req,scope='public'){
  const ip=(req.headers?.['x-forwarded-for']||req.headers?.['x-real-ip']||'unknown').split(',')[0].trim().slice(0,80);
  const key=scope+':'+ip; const now=Date.now(); const windowMs=60_000;
  const max=scope==='admin'?60:30;
  const hit=buckets.get(key)||{start:now,count:0};
  if(now-hit.start>=windowMs){hit.start=now;hit.count=0;}
  hit.count++; buckets.set(key,hit);
  if(buckets.size>5000) for(const [k,v] of buckets) if(now-v.start>windowMs*2) buckets.delete(k);
  return hit.count<=max;
}
function headers(req){return {
  apikey:process.env.SUPABASE_SERVICE_ROLE_KEY,
  Authorization:'Bearer '+process.env.SUPABASE_SERVICE_ROLE_KEY,
  'Content-Type':'application/json',Prefer:'return=representation',
  'Access-Control-Allow-Origin':originAllowed(req),
  'Access-Control-Allow-Headers':'Content-Type, x-admin-key',
  'Access-Control-Allow-Methods':'GET,POST,PATCH,OPTIONS',
  Vary:'Origin'
};}
async function sb(path, options={}, req={headers:{}}){
  const base=process.env.SUPABASE_URL; const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!base||!key)throw new Error('Supabase environment variables are not configured');
  const r=await fetch(base.replace(/\/$/,'')+'/rest/v1/'+path,{...options,headers:{...headers(req),...(options.headers||{})}});
  if(!r.ok)throw new Error(await r.text());
  return r.status===204?null:r.json();
}
function json(res,status,data,req={headers:{}}){
  res.statusCode=status; res.setHeader('Content-Type','application/json; charset=utf-8'); res.setHeader('Cache-Control','no-store');
  const o=originAllowed(req); if(o)res.setHeader('Access-Control-Allow-Origin',o); res.setHeader('Vary','Origin');
  res.setHeader('Access-Control-Allow-Headers','Content-Type, x-admin-key'); res.setHeader('Access-Control-Allow-Methods','GET,POST,PATCH,OPTIONS');
  res.setHeader('X-Content-Type-Options','nosniff'); res.end(JSON.stringify(data));
}
function preflight(req,res){
  if(req.method==='OPTIONS'){
    if(rejectBadOrigin(req)){json(res,403,{error:'Origin not allowed'},req);return true;}
    res.statusCode=204; const o=originAllowed(req); if(o)res.setHeader('Access-Control-Allow-Origin',o); res.setHeader('Vary','Origin');
    res.setHeader('Access-Control-Allow-Headers','Content-Type, x-admin-key'); res.setHeader('Access-Control-Allow-Methods','GET,POST,PATCH,OPTIONS'); res.end(); return true;
  }
  if(rejectBadOrigin(req)){json(res,403,{error:'Origin not allowed'},req);return true;}
  return false;
}
function body(req){
  if(typeof req.body==='string'){if(req.body.length>100000)throw new Error('Request body too large');return JSON.parse(req.body||'{}');}
  return req.body||{};
}
function text(v,max){return String(v??'').trim().slice(0,max).replace(/[<>]/g,'');}
module.exports={TABLES,sb,json,preflight,body,text,rateLimit,rejectBadOrigin};
