const {sb,json,preflight,body,text,rateLimit}=require('./_store');
function auth(req){const k=process.env.ZICO_ADMIN_KEY;return !!k&&req.headers['x-admin-key']===k;}
module.exports=async(req,res)=>{
 if(preflight(req,res))return; if(!auth(req))return json(res,401,{error:'Unauthorized'},req); if(!rateLimit(req,'admin'))return json(res,429,{error:'Too many requests'},req);
 try{
  const u=new URL(req.url,'http://localhost'),type=u.searchParams.get('type')||'summary';
  if(type==='summary'){
   const [d,dist,rev,ord,club,rewards,members,redemptions,referrals]=await Promise.all([
    sb('zico_demand?select=id,country,city,flavor,qty,created_at&order=created_at.desc&limit=500',{},req),
    sb('zico_distributors?select=id,name,phone,city,business,capacity,status,created_at&order=created_at.desc&limit=200',{},req),
    sb('zico_reviews?select=id,flavor,stars,text,status,created_at&order=created_at.desc&limit=200',{},req),
    sb('zico_orders?select=id,region,currency,customer,items,total,status,created_at&order=created_at.desc&limit=200',{},req),
    sb('zico_club_events?select=id,type,code,points,created_at&order=created_at.desc&limit=200',{},req),
    sb('zico_rewards?select=id,slug,name,description,icon,reward_type,points_cost,inventory,requires_code,active,sort_order&order=sort_order.asc',{},req),
    sb('zico_members?select=id,display_name,referral_code,points,lifetime_points,level,verified_at,created_at&order=created_at.desc&limit=500',{},req),
    sb('zico_redemptions?select=id,user_id,reward_id,points_spent,status,code,created_at&order=created_at.desc&limit=500',{},req),
    sb('zico_referrals?select=id,inviter_user_id,referred_user_id,referral_code,status,points_awarded,created_at&order=created_at.desc&limit=500',{},req)
   ]); return json(res,200,{demand:d,distributors:dist,reviews:rev,orders:ord,club,rewards,members,redemptions,referrals},req);
  }
  if(req.method!=='POST')return json(res,405,{error:'Method not allowed'},req); const b=body(req);
  if(type==='reward-save'){
   const row={name:text(b.name,120),description:text(b.description,240),icon:text(b.icon,8),reward_type:['gift_card','product','merch','discount','shipping','exclusive','spin'].includes(b.reward_type)?b.reward_type:'physical',points_cost:Math.max(1,Math.min(10000000,Math.floor(Number(b.points_cost)||1))),inventory:Math.max(0,Math.min(1000000,Math.floor(Number(b.inventory)||0))),requires_code:!!b.requires_code,active:b.active!==false,sort_order:Math.floor(Number(b.sort_order)||100),updated_at:new Date().toISOString()};
   let rows;if(b.id) rows=await sb('zico_rewards?id=eq.'+encodeURIComponent(text(b.id,80)),{method:'PATCH',body:JSON.stringify(row)},req); else {row.slug=text(b.slug,80).toLowerCase().replace(/[^a-z0-9-]/g,'-').slice(0,80);rows=await sb('zico_rewards',{method:'POST',body:JSON.stringify(row)},req);} return json(res,200,{ok:true,item:rows?.[0]},req);
  }
  if(type==='reward-code-add'){
   const rewardId=text(b.reward_id,80),codes=Array.isArray(b.codes)?b.codes.map(x=>text(x,100).toUpperCase()).filter(Boolean).slice(0,500):[];if(!rewardId||!codes.length)return json(res,400,{error:'Reward and codes required'},req);
   const rows=await sb('zico_reward_codes',{method:'POST',body:JSON.stringify(codes.map(code=>({reward_id:rewardId,code,status:'available'})))},req); const rr=await sb('zico_rewards?id=eq.'+encodeURIComponent(rewardId)+'&select=inventory',{},req); const inv=Number(rr?.[0]?.inventory||0)+codes.length; await sb('zico_rewards?id=eq.'+encodeURIComponent(rewardId),{method:'PATCH',body:JSON.stringify({inventory:inv,updated_at:new Date().toISOString()})},req); return json(res,200,{ok:true,items:rows},req);
  }
  if(type==='review-status'){const id=text(b.id,80),status=['pending','approved','rejected'].includes(b.status)?b.status:null;if(!id||!status)return json(res,400,{error:'Invalid status'},req);const rows=await sb('zico_reviews?id=eq.'+encodeURIComponent(id),{method:'PATCH',body:JSON.stringify({status})},req);if(status==='approved'&&b.user_id){try{await sb('rpc/zico_award_points',{method:'POST',body:JSON.stringify({p_user_id:b.user_id,p_points:100,p_kind:'review',p_description:'Approved ZICO review',p_reference:id})},req)}catch(e){}}return json(res,200,{ok:true,item:rows?.[0]},req);}
  if(type==='distributor-status'){const id=text(b.id,80),status=['pending','reviewing','approved','rejected'].includes(b.status)?b.status:null;if(!id||!status)return json(res,400,{error:'Invalid status'},req);const rows=await sb('zico_distributors?id=eq.'+encodeURIComponent(id),{method:'PATCH',body:JSON.stringify({status})},req);return json(res,200,{ok:true,item:rows?.[0]},req);}
  if(type==='order-status'){const id=text(b.id,80),status=['pending','confirmed','processing','completed','cancelled'].includes(b.status)?b.status:null;if(!id||!status)return json(res,400,{error:'Invalid status'},req);const rows=await sb('zico_orders?id=eq.'+encodeURIComponent(id),{method:'PATCH',body:JSON.stringify({status})},req);if(status==='completed'&&rows?.[0]?.customer?.user_id){try{await sb('rpc/zico_award_order_points',{method:'POST',body:JSON.stringify({p_user_id:rows[0].customer.user_id,p_order_id:rows[0].id,p_total:rows[0].total})},req)}catch(e){}}return json(res,200,{ok:true,item:rows?.[0]},req);}
  if(type==='redemption-status'){const id=text(b.id,80),status=['pending','fulfilled','cancelled'].includes(b.status)?b.status:null;if(!id||!status)return json(res,400,{error:'Invalid status'},req);if(status==='cancelled'){const x=await sb('rpc/zico_cancel_redemption',{method:'POST',body:JSON.stringify({p_redemption_id:id})},req);return json(res,200,{ok:true,result:x},req);}const rows=await sb('zico_redemptions?id=eq.'+encodeURIComponent(id),{method:'PATCH',body:JSON.stringify({status})},req);return json(res,200,{ok:true,item:rows?.[0]},req);}
  return json(res,400,{error:'Unknown admin action'},req);
 }catch(e){console.error(e);return json(res,500,{error:'Admin service unavailable'},req)}
};
