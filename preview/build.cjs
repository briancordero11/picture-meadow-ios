#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const vm = require('node:vm');

const project = path.resolve(__dirname, '..');
const assetRoot = path.join(project, 'assets');
const pngRoot = path.join(assetRoot, 'visual', 'png');
const args = process.argv.slice(2);
let destination = path.join(__dirname, 'dist');
if (args.length) {
  if (args[0] === '--out' && args.length === 2) destination = path.resolve(process.cwd(), args[1]);
  else if (args.length === 1 && !args[0].startsWith('-')) destination = path.resolve(process.cwd(), args[0]);
  else throw new Error('Usage: node preview/build.cjs [--out <output-directory>]');
}
if ([project, __dirname, assetRoot, path.join(project, 'ios')].includes(destination)) {
  throw new Error('Choose a generated output directory, such as preview/dist or work/app-preview.');
}

const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const readJSON = filename => JSON.parse(fs.readFileSync(filename, 'utf8'));
const jsonLiteral = value => JSON.stringify(value).replace(/</g, '\\u003c');
const outputFiles = new Map();
function within(root, relative) {
  const resolved = path.resolve(root, relative);
  const remainder = path.relative(root, resolved);
  if (remainder.startsWith('..') || path.isAbsolute(remainder)) throw new Error('Asset path leaves its source folder: ' + relative);
  return resolved;
}
function write(relative, bytes) {
  const target = within(destination, relative);
  const buffer = Buffer.isBuffer(bytes) ? bytes : Buffer.from(bytes);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, buffer);
  outputFiles.set(relative.replaceAll('\\', '/'), { bytes: buffer.length, sha256: sha256(buffer) });
}
function copy(source, relative, expectedHash) {
  const bytes = fs.readFileSync(source);
  if (expectedHash && sha256(bytes) !== expectedHash) throw new Error('Canonical asset hash mismatch: ' + source);
  write(relative, bytes);
  return bytes;
}
function pngSize(bytes, label) {
  if (bytes.length < 24 || bytes.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') throw new Error('Invalid PNG: ' + label);
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

const pictures = readJSON(path.join(assetRoot, 'picture-catalog.json'));
const journeys = readJSON(path.join(assetRoot, 'journey-catalog.json'));
const artwork = readJSON(path.join(assetRoot, 'visual', 'journey-artwork.json'));
const pictureData = { version: pictures.version, atlases: {}, items: pictures.items };
for (const [id, atlas] of Object.entries(pictures.atlases)) {
  const bytes = copy(within(assetRoot, atlas.file), 'assets/' + atlas.file, atlas.sha256);
  const actual = pngSize(bytes, atlas.file);
  if (actual.width !== atlas.width || actual.height !== atlas.height) throw new Error('Atlas dimensions differ: ' + id);
  pictureData.atlases[id] = { width: atlas.width, height: atlas.height, url: './assets/' + atlas.file };
}
const pictureIDs = new Set();
for (const item of pictures.items) {
  if (pictureIDs.has(item.id)) throw new Error('Duplicate picture ID: ' + item.id);
  pictureIDs.add(item.id);
  const atlas = pictureData.atlases[item.atlas];
  const frame = item.frame;
  if (!atlas || !frame || ![frame.x, frame.y, frame.width, frame.height].every(Number.isInteger)
      || frame.x < 0 || frame.y < 0 || frame.width <= 0 || frame.height <= 0
      || frame.x + frame.width > atlas.width || frame.y + frame.height > atlas.height) {
    throw new Error('Invalid canonical picture viewport: ' + item.id);
  }
}
if (pictureIDs.size !== 54 || pictures.items.filter(item => item.kind === 'interest').length !== 20) {
  throw new Error('Expected the shared 20 topic pictures and 34 core pictures.');
}

const visualFiles = fs.readdirSync(pngRoot).filter(filename => filename.endsWith('.png')).sort();
for (const filename of visualFiles) {
  const bytes = copy(path.join(pngRoot, filename), 'assets/visual/png/' + filename);
  pngSize(bytes, filename);
}
const artworkData = { symbols: {}, choices: artwork.choices, icons: {} };
for (const [symbol, entry] of Object.entries(artwork.symbols)) {
  if (path.basename(entry.file) !== entry.file || !visualFiles.includes(entry.file)) throw new Error('Missing journey artwork: ' + symbol);
  const bytes = fs.readFileSync(path.join(pngRoot, entry.file));
  if (entry.sha256 && sha256(bytes) !== entry.sha256) throw new Error('Journey artwork hash mismatch: ' + entry.file);
  artworkData.symbols[symbol] = { url: './assets/visual/png/' + entry.file };
}
for (const filename of visualFiles.filter(filename => filename.startsWith('ui-'))) {
  artworkData.icons[filename.slice(3, -4)] = './assets/visual/png/' + filename;
}
for (const name of ['house', 'star', 'x', 'arrow-left', 'volume-off', 'volume-2', 'delete', 'chevron-up', 'chevron-down', 'check', 'circle-help']) {
  if (!artworkData.icons[name]) throw new Error('Missing fixed UI icon: ' + name);
}
const choices = journeys.interests.flatMap(topic => [...topic.actions, ...topic.settings])
  .concat(journeys.favorites.flatMap(group => group.options));
for (const choice of choices) {
  if (artwork.choices[choice.id] !== choice.symbol || !artworkData.symbols[choice.symbol]) {
    throw new Error('Shared artwork does not cover choice: ' + choice.id);
  }
}
for (const symbol of ['🌈', '🍓', '🐾', '🎵', '🎮', '🗺️']) {
  if (!artworkData.symbols[symbol]) throw new Error('Missing intake artwork: ' + symbol);
}

for (const filename of ['ComicNeue-Regular.ttf', 'ComicNeue-Bold.ttf', 'WishBody-Regular.ttf', 'WishBody-Bold.ttf']) {
  copy(path.join(assetRoot, 'visual', 'fonts', filename), 'assets/visual/fonts/' + filename);
}
for (const filename of fs.readdirSync(path.join(assetRoot, 'visual', 'licenses')).sort()) {
  const source = path.join(assetRoot, 'visual', 'licenses', filename);
  if (fs.statSync(source).isFile()) copy(source, 'assets/visual/licenses/' + filename);
}
copy(path.join(assetRoot, 'picture-catalog.json'), 'assets/picture-catalog.json');
copy(path.join(assetRoot, 'journey-catalog.json'), 'assets/journey-catalog.json');
copy(path.join(assetRoot, 'visual', 'journey-artwork.json'), 'assets/visual/journey-artwork.json');
copy(path.join(project, 'ios', 'WishExplorer', 'Assets.xcassets', 'ClientDemoLogo.imageset', 'ClientDemoLogo.svg'), 'assets/ClientDemoLogo.svg');

const template = fs.readFileSync(path.join(__dirname, 'template.html'), 'utf8');
const sourceScript = fs.readFileSync(path.join(__dirname, 'picture-board.js'), 'utf8');
const script = sourceScript.replace('__PICTURE_DATA__', jsonLiteral(pictureData))
  .replace('__JOURNEY_DATA__', jsonLiteral(journeys)).replace('__ARTWORK_DATA__', jsonLiteral(artworkData));
if (/__(?:PICTURE|JOURNEY|ARTWORK)_DATA__/.test(script)) throw new Error('An app data placeholder was not filled.');
new vm.Script(script, { filename: 'app.js' });
const styles = [...template.matchAll(/<style>([\s\S]*?)<\/style>/g)].map(match => match[1]).join('\n');
if (!styles) throw new Error('The preview template must include its approved stylesheet.');
const fragment = template.replace(/<style>[\s\S]*?<\/style>/g, '')
  .replace('__OPENING_LOGO_URL__', './assets/ClientDemoLogo.svg')
  .replace(/<script>\s*__PREVIEW_SCRIPT__\s*<\/script>/, '<script src="./app.js" defer></script>');
if (/__(?:OPENING_LOGO|PREVIEW_SCRIPT)/.test(fragment)) throw new Error('A template placeholder was not filled.');
const csp = "default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'";
const html = `<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<meta http-equiv="Content-Security-Policy" content="${csp}">
<title>Wish Explorer — local app preview</title>
<link rel="stylesheet" href="./app.css">
</head><body>${fragment}</body></html>\n`;
write('app.js', script);
write('app.css', 'html{background:#eee9df}body{margin:0;padding:16px}@media(max-width:500px){body{padding:6px}}\n' + styles);
write('index.html', html);
write('build-manifest.json', JSON.stringify({ version: 1, canonicalPictures: pictureIDs.size, journeyChoices: choices.length,
  journeySymbols: Object.keys(artworkData.symbols).length, fixedUIIcons: Object.keys(artworkData.icons).length,
  fonts: 4, files: Object.fromEntries([...outputFiles.entries()].sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0)) }, null, 2) + '\n');
console.log(JSON.stringify({ outputDirectory: destination, pictures: pictureIDs.size, choices: choices.length,
  fixedSymbols: Object.keys(artworkData.symbols).length, fixedUIIcons: Object.keys(artworkData.icons).length,
  fonts: 4, generatedFiles: outputFiles.size, canonicalHashesAndFrames: 'verified', scriptSyntax: 'passed', networkDependencies: 0 }));
