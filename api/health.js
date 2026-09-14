module.exports=(req,res)=>{res.statusCode=200;res.setHeader('Content-Type','application/json');res.end(JSON.stringify({ok:true,service:'zico-v6-api',time:new Date().toISOString()}));};
