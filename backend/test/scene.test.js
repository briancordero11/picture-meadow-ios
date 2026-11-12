import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { request as httpRequest } from 'node:http';
import { createWishServer } from '../src/server.js';
import { composeScene, createOpenAISceneProvider, createSceneService, DEFAULT_SCENE_MODEL, loadJourneyCatalog, MAX_SCENE_IMAGE_BYTES, safeSceneImage, sceneServiceFromEnvironment, sceneTokenAuthorized, validateScene } from '../src/scene.js';

const catalog = loadJourneyCatalog();
const token = 'test-access-code-with-at-least-32-characters';
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==', 'base64');
const picture = { mimeType: 'image/png', bytes: png };
const jpeg = Buffer.from('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q==', 'base64');
const imageResponse = () => Response.json({ data: [{ b64_json: jpeg.toString('base64') }], output_format: 'jpeg' });
const choose = (interest = catalog.interests.find(item => item.id === 'camp')) => ({
  interestId: interest.id,
  actionIds: interest.actions.slice(0, 2).map(item => item.id),
  settingId: interest.settings[0].id,
  favoriteIds: [catalog.favorites[0].options[0].id],
  essentialChoiceId: interest.actions[0].id,
});

async function start(t, options = {}) {
  const server = createWishServer(options);
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); });
  return `http://127.0.0.1:${server.address().port}`;
}
const post = (base, input = choose(), accessCode = token) => fetch(`${base}/v1/wish-scene`, {
  method: 'POST', headers: { 'Content-Type': 'application/json', ...(accessCode ? { Authorization: `Bearer ${accessCode}` } : {}) }, body: JSON.stringify(input),
});

test('all 20 topics create action-led scene prompts from canonical choices', () => {
  assert.equal(catalog.interests.length, 20);
  for (const interest of catalog.interests) {
    const scene = composeScene(validateScene(choose(interest)));
    assert.match(scene.prompt, /one coherent scene/);
    assert.ok(scene.prompt.includes(interest.actions[0].prompt));
    assert.ok(scene.prompt.includes(interest.settings[0].prompt));
    assert.ok(scene.description.includes(interest.actions[0].label));
    assert.match(scene.description, /not confirmed/);
  }
});

test('scene validation rejects private fields, free text, wrong topics, duplicate selections, and unselected essentials', () => {
  const valid = choose();
  const other = catalog.interests.find(item => item.id !== valid.interestId);
  for (const input of [null, [], {}, { ...valid, childName: 'PRIVATE' }, { ...valid, interestId: 'PRIVATE' }, { ...valid, actionIds: [other.actions[0].id] }, { ...valid, actionIds: [valid.actionIds[0], valid.actionIds[0]] }, { ...valid, actionIds: catalog.interests[0].actions.slice(0, 4).map(item => item.id) }, { ...valid, settingId: other.settings[0].id }, { ...valid, favoriteIds: ['PRIVATE'] }, { ...valid, favoriteIds: Array(11).fill(valid.favoriteIds[0]) }, { ...valid, favoriteIds: [valid.favoriteIds[0], valid.favoriteIds[0]] }, { ...valid, essentialChoiceId: other.actions[0].id }]) {
    assert.throws(() => validateScene(input), error => error.name === 'InputError' && !error.message.includes('PRIVATE'));
  }
  assert.doesNotThrow(() => validateScene({ ...valid, actionIds: [], settingId: null, favoriteIds: [], essentialChoiceId: null }));
});

test('selection order is canonical and the essential detail stays visually central', () => {
  const valid = choose();
  assert.deepEqual(validateScene(valid), validateScene({ ...valid, actionIds: [...valid.actionIds].reverse() }));
  assert.match(composeScene(validateScene(valid)).prompt, /Make this selected part visually central/);
});

test('scene authorization requires a fixed-size secure code and fails closed when unconfigured', () => {
  assert.equal(sceneTokenAuthorized(`Bearer ${token}`, token), true);
  for (const header of [undefined, token, `Bearer ${token}wrong`, 'Bearer short']) assert.equal(sceneTokenAuthorized(header, token), false);
  assert.throws(() => createSceneService({ accessToken: 'short' }));
  assert.throws(() => createSceneService({ accessToken: 'x'.repeat(257) }));
  assert.equal(sceneTokenAuthorized(`Bearer ${'x'.repeat(257)}`, 'x'.repeat(257)), false);
  for (const env of [{}, { SCENE_GENERATION_ENABLED: 'true' }, { SCENE_GENERATION_ENABLED: 'false', SCENE_ACCESS_TOKEN: token, OPENAI_IMAGE_MODEL: DEFAULT_SCENE_MODEL, OPENAI_API_KEY: 'test-only', SCENE_PROVIDER_REVIEWED: 'true' }]) {
    const service = sceneServiceFromEnvironment(env);
    assert.equal(service.capabilities.enabled, false);
    assert.throws(() => service.authorize(`Bearer ${token}`), { status: 503 });
  }
});

test('direct provider requires both enable/review flags, an access code, a model, and a server key', () => {
  const options = { SCENE_GENERATION_ENABLED: 'true', SCENE_PROVIDER_REVIEWED: 'true', SCENE_ACCESS_TOKEN: token, OPENAI_IMAGE_MODEL: DEFAULT_SCENE_MODEL, OPENAI_API_KEY: 'test-only' };
  const configured = sceneServiceFromEnvironment(options);
  assert.equal(configured.capabilities.enabled, true);
  assert.equal(configured.capabilities.provider, 'OpenAI (direct)');
  assert.doesNotThrow(() => configured.authorize(`Bearer ${token}`));
  for (const field of Object.keys(options)) {
    const incomplete = { ...options }; delete incomplete[field];
    assert.equal(sceneServiceFromEnvironment(incomplete).capabilities.enabled, false);
  }
  assert.equal(sceneServiceFromEnvironment({ ...options, SCENE_PROVIDER_REVIEWED: 'false' }).capabilities.enabled, false);
  assert.equal(sceneServiceFromEnvironment({ ...options, SCENE_GENERATION_ENABLED: 'false' }).capabilities.enabled, false);
  const noKey = { ...options }; delete noKey.OPENAI_API_KEY;
  assert.equal(sceneServiceFromEnvironment({ ...noKey, VERCEL: '1', VERCEL_OIDC_TOKEN: 'test-only' }).capabilities.enabled, false);
});

test('direct adapter uses only the fixed official API, one moderated JPEG, and no redirects/retries', async () => {
  let supplied; let calls = 0;
  const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl: async (url, options) => {
    supplied = { url, options }; calls += 1; return imageResponse();
  } });
  const signal = new AbortController().signal;
  assert.deepEqual(await provider({ prompt: 'DRAW', signal }), { mimeType: 'image/jpeg', bytes: jpeg });
  assert.equal(supplied.url, 'https://api.openai.com/v1/images/generations');
  assert.equal(supplied.options.headers.Authorization, 'Bearer test-only');
  assert.equal(supplied.options.redirect, 'error');
  assert.equal(supplied.options.cache, 'no-store');
  assert.equal(supplied.options.credentials, 'omit');
  assert.deepEqual(JSON.parse(supplied.options.body), { model: DEFAULT_SCENE_MODEL, prompt: 'DRAW', n: 1, size: '1536x1024', quality: 'medium', output_format: 'jpeg', output_compression: 80, moderation: 'auto' });
  assert.equal(calls, 1);
  assert.throws(() => createOpenAISceneProvider({ apiKey: 'test-only', model: 'gpt-image-2.6-flare' }));
  assert.throws(() => createOpenAISceneProvider({ apiKey: '' }));
});

test('model refusals and missing image output are actionable without leaking model text', async () => {
  for (const [status, output] of [[400, { error: { code: 'moderation_blocked', message: 'PRIVATE' } }], [200, { data: [], text: 'PRIVATE' }]]) {
    const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl: async () => Response.json(output, { status }) });
    await assert.rejects(provider({ prompt: 'DRAW' }), error => error.status === 422 && error.code === 'generation_refused' && !error.message.includes('PRIVATE'));
  }
});

test('direct adapter bounds announced and streamed response bodies and cancels oversized streams', async () => {
  for (const announced of [true, false]) {
    let cancelled = false;
    const stream = new ReadableStream({
      start(controller) { if (!announced) controller.enqueue(new Uint8Array(4_000_001)); },
      cancel() { cancelled = true; },
    });
    const response = new Response(stream, { headers: { 'Content-Type': 'application/json', ...(announced ? { 'Content-Length': '4000001' } : {}) } });
    const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl: async () => response });
    await assert.rejects(provider({ prompt: 'DRAW' }), error => error.status === 502);
    assert.equal(cancelled, true);
  }
});

test('direct adapter rejects malformed/non-image outputs and never follows image URLs', async () => {
  for (const response of [
    new Response('PRIVATE', { headers: { 'Content-Type': 'text/plain' } }),
    new Response('{', { headers: { 'Content-Type': 'application/json' } }),
    Response.json({ data: [{ b64_json: 'PRIVATE' }] }),
    Response.json({ data: [{ b64_json: png.toString('base64') }] }),
    Response.json({ data: [{ url: 'https://private.invalid/child-photo' }] }),
  ]) {
    let calls = 0;
    const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl: async () => { calls += 1; return response; } });
    await assert.rejects(provider({ prompt: 'DRAW' }), error => [422, 502].includes(error.status) && !error.message.includes('PRIVATE'));
    assert.equal(calls, 1);
  }
});

test('direct API failures preserve only status, distinguish exhausted budgets, and never retry', async () => {
  for (const status of [401, 402, 403, 429, 500]) {
    let calls = 0;
    const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl: async () => { calls += 1; return Response.json({ error: { message: 'PRIVATE prompt and secret' } }, { status }); } });
    const service = createSceneService({ accessToken: token, provider });
    await assert.rejects(service.generate(choose()), error => !error.message.includes('PRIVATE') && !error.message.includes('secret') && [429, 502, 503].includes(error.status));
    assert.equal(calls, 1);
  }
  for (const code of ['insufficient_quota', 'credit_balance_exhausted', 'organization_spend_limit_exceeded', 'project_spend_limit_exceeded', 'organization_usage_limit_exceeded']) {
    const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl: async () => Response.json({ error: { code, message: 'PRIVATE' } }, { status: 429 }) });
    await assert.rejects(provider({ prompt: 'DRAW' }), { code: 'generation_budget_unavailable' });
  }
});

test('direct fetch receives caller cancellation and a bounded provider deadline', async () => {
  const controller = new AbortController();
  let observed;
  const fetchImpl = (_, { signal }) => new Promise((resolve, reject) => {
    observed = signal;
    const keepAlive = setTimeout(() => resolve(imageResponse()), 80);
    signal.addEventListener('abort', () => { clearTimeout(keepAlive); reject(signal.reason); }, { once: true });
  });
  const provider = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl });
  const pending = provider({ prompt: 'DRAW', signal: controller.signal });
  controller.abort();
  await assert.rejects(pending, { code: 'generation_cancelled' });
  assert.equal(observed.aborted, true);
  const timed = createOpenAISceneProvider({ apiKey: 'test-only', fetchImpl, timeoutMs: 10 });
  await assert.rejects(timed({ prompt: 'DRAW' }), { code: 'generation_timeout' });
  assert.equal(observed.aborted, true);
});

test('only bounded PNG/JPEG/WebP bytes can become response data', () => {
  assert.equal(safeSceneImage(picture).data, png.toString('base64'));
  for (const invalid of [{ mimeType: 'image/svg+xml', bytes: Buffer.from('<svg/>') }, { mimeType: 'image/png', bytes: Buffer.from('PRIVATE') }, { mimeType: 'image/png', bytes: Buffer.alloc(MAX_SCENE_IMAGE_BYTES + 1) }, { mimeType: 'image/png', bytes: Buffer.alloc(0) }]) assert.throws(() => safeSceneImage(invalid));
});

test('authenticated HTTP scene returns actual provider bytes and safe fixed metadata', async t => {
  let calls = 0;
  const service = createSceneService({ accessToken: token, provider: async ({ prompt }) => { calls += 1; assert.match(prompt, /watching wildlife/); return picture; } });
  const base = await start(t, { sceneService: service });
  const response = await post(base);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  const scene = await response.json();
  assert.deepEqual(Object.keys(scene).sort(), ['description', 'id', 'image', 'provider', 'title']);
  assert.equal(scene.image.data, png.toString('base64'));
  assert.equal(scene.image.mimeType, 'image/png');
  assert.equal(calls, 1);
  assert.ok(Buffer.byteLength(JSON.stringify(scene)) < 4_000_000);
});

test('unauthorized/private input cannot invoke the provider; capability response exposes no token', async t => {
  let calls = 0;
  const base = await start(t, { sceneService: createSceneService({ accessToken: token, provider: async () => { calls += 1; return picture; } }) });
  assert.equal((await post(base, choose(), null)).status, 401);
  assert.equal((await post(base, choose(), `${token}wrong`)).status, 401);
  const privateResponse = await post(base, { ...choose(), notes: 'PRIVATE' });
  assert.equal(privateResponse.status, 400);
  assert.doesNotMatch(await privateResponse.text(), /PRIVATE/);
  const capabilities = await (await fetch(`${base}/v1/scene-capabilities`)).json();
  assert.equal(capabilities.enabled, true);
  assert.equal(capabilities.uploads, false);
  assert.doesNotMatch(JSON.stringify(capabilities), new RegExp(token));
  assert.equal(calls, 0);
});

test('disabled production route returns503 while offline legacy API remains available', async t => {
  const base = await start(t);
  assert.equal((await post(base)).status, 503);
  assert.equal((await (await fetch(`${base}/v1/scene-capabilities`)).json()).mode, 'offline-only');
  assert.equal((await fetch(`${base}/v1/catalog`)).status, 200);
});

test('provider failures return fixed errors without exposing credentials or prompts', async t => {
  const base = await start(t, { sceneService: createSceneService({ accessToken: token, provider: async () => { throw new Error(`PRIVATE ${token}`); } }) });
  const response = await post(base);
  assert.equal(response.status, 502);
  assert.doesNotMatch(await response.text(), /PRIVATE|test-access-code/);
});

test('provider authentication, credit, and access failures have distinct sanitized operator guidance', async t => {
  for (const [providerStatus, expectedCode] of [[401, 'generation_not_authorized'], [402, 'generation_budget_unavailable'], [403, 'generation_access_denied']]) {
    const base = await start(t, { sceneService: createSceneService({ accessToken: token, provider: async () => {
      throw Object.assign(new Error(`PRIVATE prompt and ${token}`), { statusCode: providerStatus, responseBody: 'PRIVATE_PROVIDER_BODY' });
    } }) });
    const response = await post(base);
    assert.equal(response.status, 503);
    const body = await response.text();
    assert.equal(JSON.parse(body).error.code, expectedCode);
    assert.doesNotMatch(body, /PRIVATE|test-access-code|responseBody|stack/);
    assert.match(JSON.parse(body).error.message, /operator/i);
  }
});

test('scene rate limit prevents excess paid calls and accepts Authorization in explicit CORS preflight', async t => {
  let calls = 0;
  const origin = 'http://127.0.0.1:48318';
  const base = await start(t, { allowedOrigins: [origin], sceneRateLimit: { windowMs: 60_000, maxRequests: 1 }, sceneService: createSceneService({ accessToken: token, provider: async () => { calls += 1; return picture; } }) });
  const preflight = await fetch(`${base}/v1/wish-scene`, { method: 'OPTIONS', headers: { Origin: origin, 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type,authorization' } });
  assert.equal(preflight.status, 204);
  assert.match(preflight.headers.get('access-control-allow-headers'), /Authorization/);
  assert.equal((await post(base)).status, 200);
  const limited = await post(base);
  assert.equal(limited.status, 429);
  assert.ok(Number(limited.headers.get('retry-after')) > 0);
  assert.equal(calls, 1);
});

test('cancellation/timeout abort provider work and discard late results', async () => {
  let observedSignal;
  const provider = ({ signal }) => { observedSignal = signal; return new Promise(resolve => setTimeout(() => resolve(picture), 60)); };
  const controller = new AbortController();
  const service = createSceneService({ accessToken: token, provider, timeoutMs: 100 });
  const pending = service.generate(choose(), { signal: controller.signal });
  controller.abort();
  await assert.rejects(pending, { code: 'generation_cancelled' });
  assert.equal(observedSignal.aborted, true);
  const deadlineService = createSceneService({ accessToken: token, provider, timeoutMs: 10 });
  await assert.rejects(deadlineService.generate(choose()), { code: 'generation_timeout' });
  assert.equal(observedSignal.aborted, true);
});

test('disconnecting HTTP client aborts the image request', { timeout: 2000 }, async t => {
  let markStarted;
  let markAborted;
  const started = new Promise(resolve => { markStarted = resolve; });
  const aborted = new Promise(resolve => { markAborted = resolve; });
  const service = createSceneService({ accessToken: token, provider: ({ signal }) => new Promise((resolve, reject) => {
    signal.addEventListener('abort', () => { markAborted(); reject(signal.reason); }, { once: true });
    markStarted();
  }) });
  const base = await start(t, { sceneService: service });
  const request = httpRequest(`${base}/v1/wish-scene`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` } });
  request.on('error', () => {});
  request.end(JSON.stringify(choose()));
  await started;
  request.destroy();
  await aborted;
});

test('simultaneous image work stays bounded and a cancelled slot can be reused', async () => {
  const pending = [];
  const service = createSceneService({ accessToken: token, maxConcurrent: 2, provider: () => new Promise(resolve => pending.push(resolve)) });
  const controller = new AbortController();
  const first = service.generate(choose(), { signal: controller.signal });
  const second = service.generate(choose());
  await assert.rejects(service.generate(choose()), { code: 'generation_busy' });
  controller.abort();
  await assert.rejects(first, { code: 'generation_cancelled' });
  const third = service.generate(choose());
  assert.equal(pending.length, 3);
  pending.forEach(resolve => resolve(picture));
  await Promise.all([second, third]);
});
