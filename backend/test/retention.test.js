import test from 'node:test';
import assert from 'node:assert/strict';
import { setTimeout as delay } from 'node:timers/promises';
import { spawnSync } from 'node:child_process';
import { createRateLimiter } from '../src/server.js';

test('expired address metadata is removed while the limiter is idle', async t => {
  const limiter = createRateLimiter({ windowMs: 30, maxRequests: 2, maxClients: 1 });
  t.after(() => limiter.dispose());
  limiter.start();
  limiter.check('test-address');
  assert.equal(limiter.retainedClientCount, 1);
  // No check/request is made after this one. A lazy sweep would leave the entry present.
  await delay(120);
  assert.equal(limiter.retainedClientCount, 0);
});

test('retained metadata remains bounded and disposal clears it immediately', () => {
  const limiter = createRateLimiter({ windowMs: 60_000, maxClients: 1 });
  limiter.start();
  limiter.check('first-address');
  assert.throws(() => limiter.check('second-address'), error => error.status === 503);
  assert.equal(limiter.retainedClientCount, 1);
  limiter.dispose();
  assert.equal(limiter.retainedClientCount, 0);
  assert.throws(() => limiter.check('first-address'), error => error.status === 503);
  limiter.dispose();
});

test('the cleanup timer does not keep an otherwise idle Node process alive', () => {
  const moduleURL = new URL('../src/server.js', import.meta.url).href;
  const script = `import { createRateLimiter } from ${JSON.stringify(moduleURL)}; const limiter = createRateLimiter(); limiter.start(); limiter.check('test-address');`;
  const child = spawnSync(process.execPath, ['--input-type=module', '-e', script], { timeout: 5_000, encoding: 'utf8' });
  assert.equal(child.error, undefined);
  assert.equal(child.status, 0, child.stderr);
});
