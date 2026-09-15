const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('Docs/AppStore/site/NATURaL/language.js', 'utf8');
function run({lang='en', languages=['en-US'], stored, query='', section='', blocked=false}={}) {
  let redirected, selected, saved;
  const location={search:query,hash:'#main',replace:v=>redirected=v,assign:v=>selected=v};
  let change;
  const context={URLSearchParams,URL,location,navigator:{languages},localStorage:{getItem(){if(blocked)throw Error();return stored},setItem(k,v){if(blocked)throw Error();saved=v}},document:{documentElement:{lang,dataset:{section}},querySelectorAll:()=>[],getElementById:()=>({addEventListener:(name,fn)=>change=fn})}};
  vm.runInNewContext(source,context);
  return {redirected,select(code){change.call({value:code});return {selected,saved}}};
}
assert.equal(run({languages:['sv-SE','FR_ca']}).redirected,'/NATURaL/fr/#main');
for (const tag of ['es-MX','ja-JP','zh-Hant-TW','ko-KR','ru-RU','de-AT','ar-SA','it-IT','pt-BR']) {
 const code=tag.split('-')[0];assert.equal(run({languages:[tag],section:'support'}).redirected,`/NATURaL/${code}/support/#main`);
}
assert.equal(run({languages:['sv-SE']}).redirected,undefined);
assert.equal(run({languages:['fr'],stored:'de'}).redirected,'/NATURaL/de/#main');
assert.equal(run({lang:'fr',languages:['de']}).redirected,undefined);
assert.equal(run({languages:['fr'],query:'?lang=en',blocked:true}).redirected,undefined);
assert.equal(run({languages:['fr'],query:'?lang=../../elsewhere'}).redirected,undefined);
assert.equal(run({lang:'ar',section:'privacy',blocked:true}).select('en').selected,'/NATURaL/privacy/?lang=en#main');
console.log('PASS: OS language ordering, all regional variants, manual preference, deep links, unavailable storage, English fallback and safe routes.');
