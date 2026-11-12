import { createWishServer, parseAllowedOrigins } from './server.js';
import { sceneServiceFromEnvironment } from './scene.js';

function integerSetting(name, fallback, min, max) {
  const raw = process.env[name];
  if (raw === undefined) return fallback;
  if (!/^\d+$/.test(raw) || !Number.isSafeInteger(Number(raw)) || Number(raw) < min || Number(raw) > max) {
    throw new Error(`${name} must be an integer from ${min} to ${max}.`);
  }
  return Number(raw);
}

try {
  const port = integerSetting('PORT', 8787, 1, 65535);
  const host = process.env.HOST || '127.0.0.1';
  const server = createWishServer({
    allowedOrigins: parseAllowedOrigins(process.env.CORS_ALLOWED_ORIGINS),
    bodyLimitBytes: integerSetting('MAX_BODY_BYTES', 2048, 128, 65536),
    sceneService: sceneServiceFromEnvironment(),
    rateLimit: {
      windowMs: integerSetting('RATE_LIMIT_WINDOW_MS', 60_000, 1000, 3_600_000),
      maxRequests: integerSetting('RATE_LIMIT_MAX', 60, 1, 10_000),
      maxClients: integerSetting('RATE_LIMIT_MAX_CLIENTS', 10_000, 1, 100_000),
    },
  });
  server.once('error', error => {
    console.error(`Wish Explorer could not listen (${error.code ?? 'server error'}).`);
    process.exitCode = 1;
  });
  server.listen(port, host, () => console.log(`Wish Explorer preview API listening on http://${host}:${port}`));
  let stopping = false;
  const shutdown = () => {
    if (stopping) return;
    stopping = true;
    server.close(() => { process.exitCode = 0; });
    server.closeIdleConnections();
    const deadline = setTimeout(() => { server.closeAllConnections(); }, 10_000);
    deadline.unref();
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
} catch (error) {
  console.error(`Configuration error: ${error.message}`);
  process.exitCode = 1;
}
