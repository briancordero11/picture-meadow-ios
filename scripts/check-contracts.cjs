const fs=require('node:fs');
const assert=require('node:assert/strict');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
(async()=>{
  const project=path.resolve(__dirname,'..');
  const {catalog}=await import(pathToFileURL(path.join(project,'backend/src/catalog.js')));
  const {buildWishPreview}=await import(pathToFileURL(path.join(project,'backend/src/preview.js')));
  const swift=fs.readFileSync(path.join(project,'ios/WishExplorer/Models.swift'),'utf8');
  const sorted=values=>[...values].sort();
  const enumValues=name=>swift.match(new RegExp('enum '+name+'[^\\{]*\\{\\s*case ([^\\r\\n]+)'))[1].split(',').map(s=>s.trim());
  assert.deepEqual(sorted(enumValues('CoasterColor')),sorted(catalog.coasterColors.map(c=>c.id)));
  assert.deepEqual(sorted(enumValues('WishAnimal')),sorted(catalog.animals.map(c=>c.id)));
  const ids=[...swift.matchAll(/\.init\(id: "([^"]+)"/g)].map(m=>m[1]);
  assert.deepEqual(sorted(ids),sorted(catalog.destinations.map(d=>d.id)));
  const normalized=s=>s.toLowerCase().replace(/[^a-z0-9]/g,'');
  const sourceWords=JSON.parse(fs.readFileSync(path.join(project,'docs/communication-board.json'),'utf8').replace(/^\uFEFF/,''));
  const nativeWords=[...swift.matchAll(/\.init\(label: "([^"]+)"/g)].map(m=>m[1]);
  assert.equal(nativeWords.length,54);
  assert.deepEqual(sorted(nativeWords.map(normalized)),sorted(sourceWords.flat().map(normalized)));
  const idsSeen=new Set();
  for(const d of catalog.destinations)for(const color of catalog.coasterColors)for(let mask=0;mask<8;mask++){
    const animalIds=catalog.animals.filter((_,i)=>mask&(1<<i)).map(a=>a.id);
    const result=buildWishPreview({categoryId:'go',destinationId:d.id,coasterColor:color.id,animalIds});
    assert.equal(result.provider,'illustrated-demo');
    assert.equal(result.image.mimeType,'image/svg+xml');
    assert(result.description.includes(d.name));
    assert(result.description.includes(color.name.toLowerCase()));
    assert(result.image.data.startsWith('<svg'));
    idsSeen.add(result.id);
  }
  assert.equal(idsSeen.size,96);
  console.log('Integration verified: native/server destination/color/animal IDs match; all54 AAC concepts match supplied board; 96 selection combinations produce unique illustrated postcards.');
})().catch(error=>{console.error(error);process.exitCode=1;});
