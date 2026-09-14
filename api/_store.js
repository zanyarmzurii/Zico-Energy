const TABLES={demand:'zico_demand',distributors:'zico_distributors',reviews:'zico_reviews',club:'zico_club',orders:'zico_orders'};
async function sb(path, options={}){const base=process.env.SUPABASE_URL;const key=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!base||!key)throw new Error('Supabase environment variables are not configured');const r=await fetch(base+'/rest/v1/'+path,{...options,headers:{apikey:key,Authorization:'Bearer '+key,'Content-Type':'application/json',Prefer:'return=representation',...(options.headers||{})}});if(!r.ok)throw new Error(await r.text());return r.status===204?null:r.json();}
function json(res,status,data){res.statusCode=status;res.setHeader('Content-Type','application/json');res.end(JSON.stringify(data));}
module.exports={TABLES,sb,json};
