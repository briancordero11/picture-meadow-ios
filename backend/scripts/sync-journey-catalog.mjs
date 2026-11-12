import { readFileSync, writeFileSync } from 'node:fs';

const source = readFileSync(new URL('../../assets/journey-catalog.json', import.meta.url));
const target = new URL('../src/journey-catalog.json', import.meta.url);
if (process.argv.includes('--check')) {
  if (!source.equals(readFileSync(target))) throw new Error('Backend journey catalog differs from assets/journey-catalog.json. Run npm run catalog:sync in backend.');
  console.log('Backend journey catalog matches the shared source.');
} else {
  writeFileSync(target, source);
  console.log('Copied the shared journey catalog into the deployable backend.');
}
