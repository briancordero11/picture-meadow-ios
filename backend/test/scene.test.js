import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { request as httpRequest } from 'node:http';
import { createWishServer } from '../src/server.js';
import { composeScene, createGatewaySceneProvider, createSceneService, loadJourneyCatalog, MAX_SCENE_IMAGE_BYTES, safeSceneImage, sceneServiceFromEnvironment, sceneTokenAuthorized, validateScene } from '../src/scene.js';

const catalog = loadJourneyCatalog();
const token = 'test-access-code-with-at-least-32-characters';
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==', 'base64');
const picture = { mimeType: 'image/png', bytes: png };
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
  for (const env of [{}, { SCENE_GENERATION_ENABLED: 'true' }, { SCENE_GENERATION_ENABLED: 'false', SCENE_ACCESS_TOKEN: token, AI_GATEWAY_MODEL: 'google/gemini-nano-banana-2.1', AI_GATEWAY_API_KEY: 'test' }]) {
    const service = sceneServiceFromEnvironment(env);
    assert.equal(service.capabilities.enabled, false);
    assert.throws(() => service.authorize(`Bearer ${token}`), { status: 503 });
  }
});

test('Vercel invocation OIDC enables configured scenes without an environment credential', () => {
  const options = { SCENE_GENERATION_ENABLED: 'true', SCENE_ACCESS_TOKEN: token, AI_GATEWAY_MODEL: 'google/gemini-nano-banana-2.1' };
  assert.equal(sceneServiceFromEnvironment(options).capabilities.enabled, false);
  const deployed = sceneServiceFromEnvironment({ ...options, VERCEL: '1' });
  assert.equal(deployed.capabilities.enabled, true);
  assert.equal(deployed.capabilities.mode, 'ai-scene');
  assert.doesNotThrow(() => deployed.authorize(`Bearer ${token}`));
  // A plain external process must supply credentials; VERCEL=0 isn't a deployment.
  assert.equal(sceneServiceFromEnvironment({ ...options, VERCEL: '0' }).capabilities.enabled, false);
  assert.equal(sceneServiceFromEnvironment({ ...options, AI_GATEWAY_API_KEY: 'test-only' }).capabilities.enabled, true);
  assert.equal(sceneServiceFromEnvironment({ ...options, VERCEL_OIDC_TOKEN: 'test-only' }).capabilities.enabled, true);
  assert.equal(sceneServiceFromEnvironment({ ...options, VERCEL: '1', SCENE_GENERATION_ENABLED: 'false' }).capabilities.enabled, false);
});

test('real SDK adapter pins Vertex with ZDR/no training and disables cost-multiplying retries', async () => {
  let supplied;
  const provider = createGatewaySceneProvider({ model: 'google/gemini-nano-banana-2.1', generate: async options => {
    supplied = options;
    return { finishReason: 'stop', files: [{ mediaType: 'image/png', uint8Array: png }] };
  } });
  const signal = new AbortController().signal;
  assert.deepEqual(await provider({ prompt: 'DRAW', signal }), picture);
  assert.equal(supplied.model, 'google/gemini-nano-banana-2.1');
  assert.equal(supplied.prompt, 'DRAW');
  assert.equal(supplied.abortSignal, signal);
  assert.equal(supplied.maxRetries, 0);
  assert.deepEqual(supplied.providerOptions.gateway, { only: ['vertex'], zeroDataRetention: true, disallowPromptTraining: true });
  assert.deepEqual(supplied.providerOptions.google, { responseModalities: ['IMAGE'], imageConfig: { aspectRatio: '4:3', imageSize: '1K' } });
  assert.equal(supplied.telemetry.isEnabled, false);
  assert.throws(() => createGatewaySceneProvider({ model: 'arbitrary/unknown' }));
});

test('model refusals and missing image output are actionable without leaking model text', async () => {
  for (const output of [{ finishReason: 'content-filter', text: 'PRIVATE' }, { finishReason: 'stop', text: 'PRIVATE', files: [] }]) {
    const provider = createGatewaySceneProvider({ model: 'google/gemini-nano-banana-2.1', generate: async () => output });
    await assert.rejects(provider({ prompt: 'DRAW' }), error => error.status === 422 && error.code === 'generation_refused' && !error.message.includes('PRIVATE'));
  }
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
