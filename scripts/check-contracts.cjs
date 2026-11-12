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
  const pictureCatalog=JSON.parse(fs.readFileSync(path.join(project,'assets/picture-catalog.json'),'utf8'));
  const topicPictures=pictureCatalog.items.filter(item=>item.kind==='interest');
  const corePictures=pictureCatalog.items.filter(item=>item.kind==='core');
  assert.equal(nativeWords.length,34);
  assert.equal(topicPictures.length,20);
  assert.equal(corePictures.length,34);
  assert.deepEqual(sorted(nativeWords.map(normalized)),sorted(corePictures.map(item=>normalized(item.label))));
  assert.deepEqual(sorted(pictureCatalog.items.map(item=>normalized(item.label))),sorted(sourceWords.flat().map(normalized)));
  const interestEnum=swift.match(/enum InterestChoice[^\{]*\{([\s\S]*?)var id/)[1];
  const interestIDs=[...interestEnum.matchAll(/^\s*case ([^\r\n]+)/gm)].flatMap(match=>match[1].split(',').map(value=>value.match(/=\s*"([^"]+)"/)?.[1]??value.trim()));
  assert.deepEqual(interestIDs,topicPictures.map(item=>item.id));
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(project,'ios/WishExplorer/Resources/Pictures/picture-catalog.json'),'utf8')),pictureCatalog);
  const journeyCatalog=JSON.parse(fs.readFileSync(path.join(project,'assets/journey-catalog.json'),'utf8'));
  const nativeJourneyCatalog=JSON.parse(fs.readFileSync(path.join(project,'ios/WishExplorer/Resources/journey-catalog.json'),'utf8'));
  assert.deepEqual(nativeJourneyCatalog,journeyCatalog,'Native journey resource must match assets/journey-catalog.json');
  const backendJourneyPath=path.join(project,'backend/src/journey-catalog.json');
  if(fs.existsSync(backendJourneyPath)){
    assert.deepEqual(JSON.parse(fs.readFileSync(backendJourneyPath,'utf8')),journeyCatalog,'Backend journey mirror must match assets/journey-catalog.json');
  }
  assert.equal(journeyCatalog.version,1);
  assert(Array.isArray(journeyCatalog.interests));
  assert(Array.isArray(journeyCatalog.favorites));
  assert.deepEqual(journeyCatalog.interests.map(item=>item.id),interestIDs,'All 20 interest journeys must preserve the home picture order');
  const slug=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/;
  const journeyChoiceIDs=new Set();
  const favoriteGroupIDs=new Set();
  let journeyActions=0,journeySettings=0,favoriteOptions=0;
  function checkJourneyChoice(choice,context){
    assert.deepEqual(sorted(Object.keys(choice)),['id','label','prompt','symbol'],context+' requires exactly id, label, symbol and prompt');
    for(const field of ['id','label','symbol','prompt']){
      assert.equal(typeof choice[field],'string',context+' '+field+' must be a string');
      assert(choice[field].trim().length>0,context+' '+field+' must be nonempty');
      assert.equal(choice[field],choice[field].trim(),context+' '+field+' has surrounding whitespace');
    }
    assert(slug.test(choice.id),context+' ID must be a lowercase slug');
    assert(!journeyChoiceIDs.has(choice.id),'Action, setting and favorite IDs must be globally distinct: '+choice.id);
    journeyChoiceIDs.add(choice.id);
  }
  for(const interest of journeyCatalog.interests){
    assert(Array.isArray(interest.actions));
    assert(Array.isArray(interest.settings));
    assert(interest.actions.length>=4&&interest.actions.length<=6,interest.id+' needs 4–6 actions');
    assert(interest.settings.length>=3&&interest.settings.length<=5,interest.id+' needs 3–5 settings');
    interest.actions.forEach(choice=>checkJourneyChoice(choice,interest.id+' action'));
    interest.settings.forEach(choice=>checkJourneyChoice(choice,interest.id+' setting'));
    journeyActions+=interest.actions.length;
    journeySettings+=interest.settings.length;
  }
  for(const group of journeyCatalog.favorites){
    assert.equal(typeof group.id,'string');
    assert(slug.test(group.id),'Favorite group ID must be a lowercase slug');
    assert(!favoriteGroupIDs.has(group.id),'Favorite group IDs must be distinct');
    favoriteGroupIDs.add(group.id);
    assert.equal(typeof group.label,'string');
    assert(group.label.trim().length>0,'Favorite groups need a label');
    assert(Array.isArray(group.options));
    assert(group.options.length>=4&&group.options.length<=8,group.id+' needs 4–8 favorite options');
    group.options.forEach(choice=>checkJourneyChoice(choice,group.id+' favorite'));
    favoriteOptions+=group.options.length;
  }
  assert.equal(journeyChoiceIDs.size,216,'The current catalog must retain all 216 action, setting and favorite choices');
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
  console.log('Integration verified: native/server choice IDs match; 20 topic + 34 core pictures cover all 54 source concepts with matching native assets; 20 journeys contain '+journeyActions+' actions, '+journeySettings+' settings and '+favoriteOptions+' favorites with 216 distinct IDs and matching catalog copies; 96 selection combinations produce unique illustrated postcards.');
})().catch(error=>{console.error(error);process.exitCode=1;});
