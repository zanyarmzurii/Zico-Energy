const {sb,json,preflight,body,text,rateLimit}=require('./_store');

function bearer(req){const h=req.headers?.authorization||req.headers?.Authorization||'';return h.startsWith('Bearer ')?h.slice(7).trim():'';}
async function authUser(req){
  const token=bearer(req); if(!token) return null;
  const base=process.env.SUPABASE_URL, key=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!base||!key) throw new Error('Supabase environment variables are not configured');
  const r=await fetch(base.replace(/\/$/,'')+'/auth/v1/user',{headers:{apikey:key,Authorization:'Bearer '+token}});
  if(!r.ok)return null; const u=await r.json(); if(!u.email_confirmed_at && !u.phone_confirmed_at)return null; return u;
}
function hashish(value){
  const crypto=require('crypto'); return crypto.createHash('sha256').update(String(value||'' )).digest('hex');
}
function clientFingerprint(req,deviceId=''){
  const ip=(req.headers?.['x-forwarded-for']||req.headers?.['x-real-ip']||'').split(',')[0].trim();
  const ua=req.headers?.['user-agent']||'';
  return hashish(`${deviceId}|${ip}|${ua}`);
}
async function rpc(fn,args,req){return sb(`rpc/${fn}`,{method:'POST',body:JSON.stringify(args)},req);}

module.exports=async(req,res)=>{
  if(preflight(req,res))return;
  if(!rateLimit(req,'public'))return json(res,429,{error:'Too many requests'},req);
  try{
    const u=new URL(req.url,'http://localhost');
    const action=u.searchParams.get('action')||'summary';
    const user=await authUser(req);
    if(action==='catalog'){
      const items=await sb('zico_rewards?select=id,slug,name,description,icon,points_cost,reward_type,inventory,requires_code,active,sort_order&active=eq.true&order=sort_order.asc,points_cost.asc',{},req);
      return json(res,200,{items},req);
    }
    if(action==='leaderboard'){
      const items=await sb('zico_rewards_leaderboard?select=rank,display_name,referrals,points&limit=20',{},req);
      return json(res,200,{items},req);
    }
    if(!user)return json(res,401,{error:'Sign in required'},req);
    if(action==='summary'){
      await rpc('zico_ensure_member',{p_user_id:user.id},req);
      const member=await sb(`zico_members?id=eq.${encodeURIComponent(user.id)}&select=id,display_name,referral_code,points,lifetime_points,level,verified_at,created_at`,{},req);
      if(!member?.length)return json(res,404,{error:'Member profile not found'},req);
      const history=await sb(`zico_points_ledger?user_id=eq.${encodeURIComponent(user.id)}&select=id,kind,points,description,created_at&order=created_at.desc&limit=30`,{},req);
      const red=await sb(`zico_redemptions?user_id=eq.${encodeURIComponent(user.id)}&select=id,reward_id,points_spent,status,code,created_at&order=created_at.desc&limit=30`,{},req);
      const m=member[0];
      return json(res,200,{member:m,history,redemptions:red},req);
    }
    if(req.method!=='POST')return json(res,405,{error:'Method not allowed'},req);
    const b=body(req);
    if(action==='referral'){
      const code=text(b.code,32).toUpperCase(); if(!/^ZICO-[A-Z0-9]{6,12}$/.test(code))return json(res,400,{error:'Invalid referral code'},req);
      const fp=clientFingerprint(req,text(b.deviceId,120));
      const result=await rpc('zico_complete_referral',{p_referred_user:user.id,p_code:code,p_fingerprint:fp},req);
      return json(res,200,{ok:true,result:Array.isArray(result)?result[0]:result},req);
    }
    if(action==='checkin'){
      const result=await rpc('zico_daily_checkin',{p_user_id:user.id,p_fingerprint:clientFingerprint(req,text(b.deviceId,120))},req);
      return json(res,200,{ok:true,result:Array.isArray(result)?result[0]:result},req);
    }
    if(action==='review'){
      const result=await rpc('zico_award_points',{p_user_id:user.id,p_points:100,p_kind:'review',p_description:'Approved ZICO review',p_reference:text(b.reference,80)},req);
      return json(res,200,{ok:true,result:Array.isArray(result)?result[0]:result},req);
    }
    if(action==='share'){
      const result=await rpc('zico_award_points',{p_user_id:user.id,p_points:50,p_kind:'share',p_description:'ZICO share',p_reference:text(b.reference,80)},req);
      return json(res,200,{ok:true,result:Array.isArray(result)?result[0]:result},req);
    }
    if(action==='redeem'){
      const rewardId=text(b.rewardId,80); if(!rewardId)return json(res,400,{error:'Reward required'},req);
      const result=await rpc('zico_redeem_reward',{p_user_id:user.id,p_reward_id:rewardId,p_fingerprint:clientFingerprint(req,text(b.deviceId,120))},req);
      return json(res,200,{ok:true,result:Array.isArray(result)?result[0]:result},req);
    }
    if(action==='spin'){
      const result=await rpc('zico_lucky_spin',{p_user_id:user.id,p_fingerprint:clientFingerprint(req,text(b.deviceId,120))},req);
      return json(res,200,{ok:true,result:Array.isArray(result)?result[0]:result},req);
    }
    return json(res,400,{error:'Unknown rewards action'},req);
  }catch(e){console.error(e);return json(res,400,{error:e?.message?.slice(0,240)||'Rewards service unavailable'},req);}
};
