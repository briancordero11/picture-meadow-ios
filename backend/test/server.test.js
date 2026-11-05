import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { request as httpRequest } from 'node:http';
import { createWishServer, parseAllowedOrigins } from '../src/server.js';

const choices = { categoryId: 'go', destinationId: 'disney-world', coasterColor: 'purple', animalIds: ['dolphin'] };

async function start(t, options) {
  const server = createWishServer(options);
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(async () => {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  });
  return `http://127.0.0.1:${server.address().port}`;
}

function rawPost(base, chunks, headers = {}) {
  return new Promise((resolve, reject) => {
    const request = httpRequest(`${base}/v1/wish-preview`, { method: 'POST', headers: { 'content-type': 'application/json', ...headers } }, response => {
      let body = '';
      response.setEncoding('utf8');
      response.on('data', data => { body += data; });
      response.once('end', () => resolve({ status: response.statusCode, body }));
      response.once('error', reject);
    });
    request.once('error', reject);
    for (const chunk of chunks) request.write(chunk);
    request.end();
  });
}

test('health, catalog, and preview follow the native client contract', async t => {
  const base = await start(t);
  const health = await fetch(`${base}/health`);
  assert.equal(health.status, 200);
  assert.equal((await health.json()).status, 'ok');
  assert.equal(health.headers.get('cache-control'), 'no-store');
  const response = await fetch(`${base}/v1/catalog`);
  const catalog = await response.json();
  assert.equal(catalog.previewCategoryId, 'go');
  assert.equal(catalog.categories.filter(category => category.previewAvailable).length, 1);
  assert.equal(catalog.categories.find(category => category.id === 'explore').kind, 'navigation');
  const previewResponse = await fetch(`${base}/v1/wish-preview`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=utf-8' }, body: JSON.stringify(choices) });
  assert.equal(previewResponse.status, 200);
  const preview = await previewResponse.json();
  assert.deepEqual(Object.keys(preview).sort(), ['description', 'id', 'image', 'provider', 'title']);
  assert.equal(preview.provider, 'illustrated-demo');
  assert.equal(preview.title, 'My wish: Walt Disney World');
  assert.equal(preview.image.mimeType, 'image/svg+xml');
});

test('malformed/invalid UTF-8 JSON and personal fields are rejected without reflecting input', async t => {
  const base = await start(t);
  for (const body of ['{', '', 'null', '[]', JSON.stringify({ ...choices, childName: 'SENSITIVE_CHILD_NAME' }), JSON.stringify({ ...choices, destinationId: '<script>attack</script>' })]) {
    const response = await rawPost(base, [body]);
    assert.equal(response.status, 400);
    assert.doesNotMatch(response.body, /SENSITIVE_CHILD_NAME|<script>|attack/);
  }
  const invalidUtf8 = await rawPost(base, [Buffer.from([0x7b, 0x22, 0x78, 0x22, 0x3a, 0x22, 0xff, 0x22, 0x7d])]);
  assert.equal(invalidUtf8.status, 400);
  assert.equal(JSON.parse(invalidUtf8.body).error.code, 'invalid_json');
});

test('body limits apply to known-length and chunked bodies', async t => {
  const base = await start(t, { bodyLimitBytes: 256 });
  const oversized = ' '.repeat(257);
  const known = await rawPost(base, [oversized], { 'Content-Length': Buffer.byteLength(oversized) });
  assert.equal(known.status, 413);
  const chunked = await rawPost(base, [' '.repeat(200), ' '.repeat(200)]);
  assert.equal(chunked.status, 413);
  assert.equal((await fetch(`${base}/health`)).status, 200);
});

test('unsupported media types and compression are rejected', async t => {
  const base = await start(t);
  assert.equal((await rawPost(base, ['{}'], { 'Content-Type': 'text/plain' })).status, 415);
  assert.equal((await rawPost(base, ['{}'], { 'Content-Encoding': 'gzip' })).status, 415);
});

test('browser origins are opt-in and preflight is restricted', async t => {
  const origin = 'http://localhost:4173';
  const base = await start(t, { allowedOrigins: [origin] });
  const accepted = await fetch(`${base}/v1/catalog`, { headers: { Origin: origin } });
  assert.equal(accepted.status, 200);
  assert.equal(accepted.headers.get('access-control-allow-origin'), origin);
  assert.equal(accepted.headers.get('vary'), 'Origin');
  const blocked = await fetch(`${base}/v1/catalog`, { headers: { Origin: 'https://untrusted.example' } });
  assert.equal(blocked.status, 403);
  assert.equal(blocked.headers.get('access-control-allow-origin'), null);
  const preflight = await fetch(`${base}/v1/wish-preview`, { method: 'OPTIONS', headers: { Origin: origin, 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type' } });
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get('access-control-allow-methods'), 'POST');
  const badPreflight = await fetch(`${base}/v1/wish-preview`, { method: 'OPTIONS', headers: { Origin: origin, 'Access-Control-Request-Method': 'DELETE' } });
  assert.equal(badPreflight.status, 400);
  const defaultBase = await start(t);
  assert.equal((await fetch(`${defaultBase}/v1/catalog`, { headers: { Origin: origin } })).status, 403);
});

test('rate limit rejects bursts, recovers, and does not block health checks', async t => {
  let time = 1000;
  const base = await start(t, { rateLimit: { maxRequests: 2, windowMs: 1000 }, now: () => time });
  assert.equal((await fetch(`${base}/v1/catalog`)).status, 200);
  assert.equal((await fetch(`${base}/v1/catalog`)).status, 200);
  const limited = await fetch(`${base}/v1/catalog`, { headers: { 'X-Forwarded-For': 'different-client' } });
  assert.equal(limited.status, 429);
  assert.equal(limited.headers.get('retry-after'), '1');
  assert.equal(limited.headers.get('x-ratelimit-remaining'), '0');
  assert.equal((await fetch(`${base}/health`)).status, 200);
  time += 1001;
  assert.equal((await fetch(`${base}/v1/catalog`)).status, 200);
});

test('unknown endpoints, query parameters, and unsupported methods return controlled errors', async t => {
  const base = await start(t);
  assert.equal((await fetch(`${base}/missing`)).status, 404);
  assert.equal((await fetch(`${base}/health?name=private`)).status, 400);
  const response = await fetch(`${base}/v1/wish-preview`, { method: 'GET' });
  assert.equal(response.status, 405);
  assert.equal(response.headers.get('allow'), 'POST, OPTIONS');
});

test('CORS configuration rejects wildcard, paths, credentials, and non-HTTP schemes', () => {
  assert.deepEqual(parseAllowedOrigins(' http://localhost:4173,https://app.example,http://localhost:4173 '), ['http://localhost:4173', 'https://app.example']);
  for (const origin of ['*', 'https://app.example/', 'https://app.example/path', 'https://user:pass@app.example', 'file:///tmp/app']) {
    assert.throws(() => parseAllowedOrigins(origin));
  }
});
