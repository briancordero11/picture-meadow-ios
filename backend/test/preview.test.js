import test from 'node:test';
import assert from 'node:assert/strict';
import { buildWishPreview, escapeXML, InputError } from '../src/preview.js';
import { animals, coasterColors, destinations } from '../src/catalog.js';

const choices = { categoryId: 'go', destinationId: 'six-flags-great-america', coasterColor: 'blue', animalIds: ['giraffe', 'tiger'] };

test('the same choices generate one stable, accessible illustrated postcard', () => {
  const first = buildWishPreview(choices);
  assert.deepEqual(first, buildWishPreview(choices));
  assert.deepEqual(first, buildWishPreview({ ...choices, animalIds: ['tiger', 'giraffe'] }));
  assert.match(first.id, /^wish_[a-f0-9]{20}$/);
  assert.equal(first.provider, 'illustrated-demo');
  assert.equal(first.image.mimeType, 'image/svg+xml');
  assert.match(first.image.data, /aria-labelledby="title description"/);
  assert.match(first.image.data, /<title id="title">My wish: Six Flags Great America<\/title>/);
  assert.match(first.image.data, /#1675D1/);
  assert.match(first.description, /not a confirmed trip/);
  assert.doesNotMatch(first.image.data, /<script|<foreignObject|onload=|https?:\/\/(?!www\.w3\.org)/i);
});

test('every offered destination/color/animal choice generates a preview', () => {
  for (const destination of destinations) for (const color of coasterColors) {
    const preview = buildWishPreview({ ...choices, destinationId: destination.id, coasterColor: color.id, animalIds: animals.map(animal => animal.id) });
    assert.match(preview.title, new RegExp(destination.name));
    assert.ok(preview.image.data.includes(color.hex));
    assert.ok(preview.image.data.endsWith('</svg>'));
  }
  assert.doesNotThrow(() => buildWishPreview({ ...choices, animalIds: [] }));
});

test('personal fields, unsupported choices, duplicates, and wrong shapes are rejected', () => {
  for (const input of [null, [], 'go', 42, {}, { ...choices, name: 'A child' }, { ...choices, categoryId: 'meet' }, { ...choices, destinationId: '<script>alert(1)</script>' }, { ...choices, coasterColor: 'red' }, { ...choices, animalIds: 'tiger' }, { ...choices, animalIds: ['cat'] }, { ...choices, animalIds: ['tiger', 'tiger'] }, { ...choices, animalIds: ['giraffe', 'dolphin', 'tiger', 'giraffe'] }]) {
    assert.throws(() => buildWishPreview(input), InputError);
  }
});

test('XML escaping is safe for text and attributes', () => {
  assert.equal(escapeXML('<a title="x\'y">&'), '&lt;a title=&quot;x&apos;y&quot;&gt;&amp;');
});
