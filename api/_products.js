// Server-side price source. Never trust product prices or totals sent by the browser.
const PRODUCTS={
  'zico-60':{single:1500,bundle:30000},
  'zico-55':{single:1500,bundle:30000},
  'zico-66':{single:1500,bundle:30000},
  'zico-63':{single:1500,bundle:30000},
  'zico-69':{single:1500,bundle:30000},
  'zico-65':{single:1500,bundle:30000}
};
function priceFor(id,itemType,region){
  const p=PRODUCTS[id]; if(!p) return null;
  if(region==='sweden'){
    const single=Number(process.env.ZICO_SWEDEN_SINGLE_PRICE||0);
    const bundle=Number(process.env.ZICO_SWEDEN_BUNDLE_PRICE||0);
    if(!single||!bundle)return null;
    return itemType==='bundle'?bundle:single;
  }
  return itemType==='bundle'?p.bundle:p.single;
}
module.exports={priceFor};
