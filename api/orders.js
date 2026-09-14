const {sb,json,preflight,body,text,rateLimit}=require('./_store');
const {priceFor}=require('./_products');
async function authUserId(req){const h=req.headers?.authorization||'';if(!h.startsWith('Bearer '))return null;const base=process.env.SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!base||!key)return null;const r=await fetch(base.replace(/\/$/,'')+'/auth/v1/user',{headers:{apikey:key,Authorization:h}});if(!r.ok)return null;const u=await r.json();return u.id||null;}
module.exports=async(req,res)=>{if(preflight(req,res))return;try{
  if(req.method!=='POST')return json(res,405,{error:'Method not allowed'},req);
  if(!rateLimit(req,'orders'))return json(res,429,{error:'Too many requests'},req);
  const b=body(req); const userId=await authUserId(req); const region=b.region==='sweden'?'sweden':'kurdistan'; const currency=region==='sweden'?'SEK':'IQD';
  const customer={user_id:userId,name:text(b.customer?.name,100),phone:text(b.customer?.phone,40),city:text(b.customer?.city,80),address:text(b.customer?.address,250)};
  if(!text(b.id,80)||!customer.name||!customer.phone||!customer.city||!Array.isArray(b.items)||!b.items.length)return json(res,400,{error:'Invalid order'},req);
  const items=b.items.slice(0,50).map(i=>{const id=text(i.id,80);const itemType=i.itemType==='bundle'?'bundle':'single';const qty=Math.max(1,Math.min(Math.floor(Number(i.qty)||1),1000));const unitPrice=priceFor(id,itemType,region);if(unitPrice===null)throw new Error('Invalid product or regional pricing');return {id,name:text(i.name,120),qty,itemType,unitPrice};});
  const total=items.reduce((sum,i)=>sum+i.unitPrice*i.qty,0);
  const row={id:text(b.id,80),region,currency,customer,items,total,status:'pending',created_at:new Date().toISOString()};
  const rows=await sb('zico_orders',{method:'POST',body:JSON.stringify(row)},req); return json(res,201,{ok:true,item:{id:row.id,region,currency,total,status:'pending'}},req);
}catch(e){return json(res,500,{error:'Order service unavailable'},req);}};
