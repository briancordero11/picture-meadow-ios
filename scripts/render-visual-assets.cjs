// Render checked-in, pinned SVG sources into identical browser/iPad PNG resources.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const sharp = require(process.env.WISH_SHARP_MODULE || 'sharp');
const lucide = require(process.env.WISH_LUCIDE_MODULE || 'lucide');
const visual = path.join(root, 'assets/visual');
const native = path.join(root, 'ios/WishExplorer/Resources/Visual');
const manifest = JSON.parse(fs.readFileSync(path.join(visual, 'journey-artwork.json')));
const palette = { blue:'#078eea',pink:'#f5a5ca',purple:'#9c6ade',green:'#26b944',red:'#ed2455',yellow:'#ffe033' };
const symbols = {blue:'🔵',pink:'🩷',purple:'🟣',green:'🟢',red:'🔴',yellow:'🟡'};
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
async function main() {
  fs.mkdirSync(path.join(visual,'png'),{recursive:true});
  fs.mkdirSync(native,{recursive:true});
  for (const [color,symbol] of Object.entries(symbols)) {
    const file = manifest.symbols[symbol].file.replace('.png','.svg');
    fs.writeFileSync(path.join(visual,'svg',file),`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 54 54"><circle cx="27" cy="27" r="24" fill="${palette[color]}" stroke="#211c18" stroke-width="3"/></svg>`);
    manifest.symbols[symbol].modification='Project color swatch, replacing a platform emoji';
  }
  for (const entry of Object.values(manifest.symbols)) {
    const svg = fs.readFileSync(path.join(visual,'svg',entry.file.replace('.png','.svg')));
    const png = await sharp(svg).resize(256,256,{fit:'contain',background:'#00000000'}).png().toBuffer();
    fs.writeFileSync(path.join(visual,'png',entry.file),png);
    fs.writeFileSync(path.join(native,entry.file),png);
    entry.sha256=hash(png);
  }
  for (const name of ['house','star','x','arrow-left','volume-off','volume-2','delete','chevron-up','chevron-down','check','circle-help']) {
    const key=name.split('-').map(word=>word[0].toUpperCase()+word.slice(1)).join('');
    const attrs=Object.entries({xmlns:'http://www.w3.org/2000/svg',width:24,height:24,viewBox:'0 0 24 24',fill:name==='star'?'#ffcc40':'none',stroke:name==='star'?'#79521a':'#423021','stroke-width':name==='star'?1.5:1.8,'stroke-linecap':'round','stroke-linejoin':'round'}).map(([k,v])=>`${k}="${v}"`).join(' ');
    const body=lucide.icons[key].map(([tag,props])=>`<${tag} ${Object.entries(props).map(([k,v])=>`${k}="${v}"`).join(' ')}/>`).join('');
    const svg=`<svg ${attrs}>${body}</svg>`;
    const png=await sharp(Buffer.from(svg)).resize(128,128).png().toBuffer();
    fs.writeFileSync(path.join(visual,'png',`ui-${name}.png`),png);
    fs.writeFileSync(path.join(native,`ui-${name}.png`),png);
  }
  for (const file of fs.readdirSync(path.join(visual,'fonts'))) fs.copyFileSync(path.join(visual,'fonts',file),path.join(native,file));
  for (const file of fs.readdirSync(path.join(visual,'licenses'))) fs.copyFileSync(path.join(visual,'licenses',file),path.join(native,file));
  const output=JSON.stringify(manifest,null,2)+'\n';
  fs.writeFileSync(path.join(visual,'journey-artwork.json'),output);
  fs.writeFileSync(path.join(native,'journey-artwork.json'),output);
  console.log(JSON.stringify({symbols:Object.keys(manifest.symbols).length,choices:Object.keys(manifest.choices).length,sharedNativeResources:native}));
}
main().catch(error=>{console.error(error);process.exitCode=1});
