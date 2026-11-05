import { createServer } from 'node:http';
import { catalog } from './catalog.js';
import { buildWishPreview, InputError } from './preview.js';

class HTTPError extends Error {
  constructor(status, code, message) {
    super(message);
    Object.assign(this, { status, code });
  }
}

export function parseAllowedOrigins(value = '') {
  return [...new Set(value.split(',').map(origin => origin.trim()).filter(Boolean))].map(origin => {
    const url = new URL(origin);
    if (!['http:', 'https:'].includes(url.protocol) || url.origin !== origin || url.username || url.password) {
      throw new Error('CORS_ALLOWED_ORIGINS must contain exact HTTP(S) origins, without paths, credentials, or a wildcard.');
    }
    return origin;
  });
}

// Exported for aggregate retention/lifecycle verification, not exposed by an HTTP endpoint.
export function createRateLimiter({ windowMs = 60_000, maxRequests = 60, maxClients = 10_000 } = {}, now = Date.now) {
  for (const value of [windowMs, maxRequests, maxClients]) {
    if (!Number.isSafeInteger(value) || value < 1) throw new Error('Rate limit options must be positive integers.');
  }
  const clients = new Map();
  const cleanupIntervalMs = Math.min(windowMs, 1_000);
  let timer;
  let disposed = false;
  const sweep = (time = now()) => {
    for (const [client, entry] of clients) if (entry.resetAt <= time) clients.delete(client);
  };
  return {
    start() {
      if (timer || disposed) return;
      // Expired addresses must be deleted even when no more API calls arrive.
      timer = setInterval(sweep, cleanupIntervalMs);
      timer.unref();
    },
    dispose() {
      disposed = true;
      clearInterval(timer);
      timer = undefined;
      clients.clear();
    },
    get retainedClientCount() { return clients.size; },
    check(key) {
      if (disposed) throw new HTTPError(503, 'temporarily_unavailable', 'Please try again shortly.');
      const time = now();
      let entry = clients.get(key);
      if (entry && entry.resetAt <= time) {
        clients.delete(key);
        entry = undefined;
      }
      if (!entry) {
        // Reclaim expired entries before enforcing the bounded address capacity.
        if (clients.size >= maxClients) sweep(time);
        if (clients.size >= maxClients) throw new HTTPError(503, 'temporarily_unavailable', 'Please try again shortly.');
        entry = { count: 0, resetAt: time + windowMs };
        clients.set(key, entry);
      }
      entry.count += 1;
      return {
        allowed: entry.count <= maxRequests,
        limit: maxRequests,
        remaining: Math.max(0, maxRequests - entry.count),
        retryAfter: Math.max(1, Math.ceil((entry.resetAt - time) / 1000)),
      };
    },
  };
}

function readJSON(request, maxBytes) {
  return new Promise((resolve, reject) => {
    const mediaType = request.headers['content-type']?.split(';')[0].trim().toLowerCase();
    if (mediaType !== 'application/json') {
      request.resume();
      reject(new HTTPError(415, 'unsupported_media_type', 'Use Content-Type: application/json.'));
      return;
    }
    if (request.headers['content-encoding'] && request.headers['content-encoding'] !== 'identity') {
      request.resume();
      reject(new HTTPError(415, 'unsupported_encoding', 'Compressed request bodies are not supported.'));
      return;
    }
    if (Number(request.headers['content-length'] ?? 0) > maxBytes) {
      request.resume();
      reject(new HTTPError(413, 'payload_too_large', `The request body must be at most ${maxBytes} bytes.`));
      return;
    }
    let size = 0;
    let chunks = [];
    let settled = false;
    request.on('data', chunk => {
      size += chunk.length;
      if (size > maxBytes) {
        chunks = [];
        if (!settled) {
          settled = true;
          reject(new HTTPError(413, 'payload_too_large', `The request body must be at most ${maxBytes} bytes.`));
        }
      } else if (!settled) chunks.push(chunk);
    });
    request.once('end', () => {
      if (settled) return;
      settled = true;
      try {
        // Fatal decoding rejects malformed UTF-8 instead of silently replacing it.
        const text = new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(chunks));
        resolve(JSON.parse(text));
      } catch {
        reject(new HTTPError(400, 'invalid_json', 'Send a valid UTF-8 JSON object.'));
      }
    });
    request.once('error', () => {
      if (!settled) {
        settled = true;
        reject(new HTTPError(400, 'incomplete_body', 'The request body could not be read.'));
      }
    });
    request.once('aborted', () => {
      if (!settled) {
        settled = true;
        reject(new HTTPError(400, 'incomplete_body', 'The request was interrupted.'));
      }
    });
  });
}

const endpointMethods = new Map([
  ['/health', 'GET'],
  ['/v1/catalog', 'GET'],
  ['/v1/wish-preview', 'POST'],
]);

/** Payloads are never written to a database or request log. */
export function createWishServer({ allowedOrigins = [], bodyLimitBytes = 2_048, rateLimit, now } = {}) {
  if (!Number.isSafeInteger(bodyLimitBytes) || bodyLimitBytes < 128 || bodyLimitBytes > 65_536) {
    throw new Error('bodyLimitBytes must be an integer between 128 and 65536.');
  }
  const origins = new Set(parseAllowedOrigins(allowedOrigins.join(',')));
  const limiter = createRateLimiter(rateLimit, now);
  const server = createServer(async (request, response) => {
    response.setHeader('Content-Type', 'application/json; charset=utf-8');
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
    response.setHeader('Referrer-Policy', 'no-referrer');
    response.setHeader('Vary', 'Origin');
    const send = (status, data) => {
      if (response.destroyed || response.writableEnded) return;
      response.statusCode = status;
      response.end(data === undefined ? undefined : JSON.stringify(data));
    };
    try {
      const origin = request.headers.origin;
      if (origin !== undefined) {
        if (!origins.has(origin)) throw new HTTPError(403, 'origin_not_allowed', 'This browser origin is not allowed.');
        response.setHeader('Access-Control-Allow-Origin', origin);
      }
      const url = new URL(request.url ?? '/', 'http://localhost');
      // URLs are fixed so accidentally supplied personal data in a query is not processed.
      if (url.search) throw new HTTPError(400, 'query_not_supported', 'These endpoints do not accept query parameters.');
      const requiredMethod = endpointMethods.get(url.pathname);
      if (!requiredMethod) throw new HTTPError(404, 'not_found', 'Endpoint not found.');
      if (request.method === 'OPTIONS') {
        const requestedMethod = request.headers['access-control-request-method'];
        const requestedHeaders = request.headers['access-control-request-headers']?.split(',').map(header => header.trim().toLowerCase()) ?? [];
        if (!origin || !requestedMethod || requestedMethod !== requiredMethod || requestedHeaders.some(header => header !== 'content-type')) {
          throw new HTTPError(400, 'invalid_preflight', 'The requested browser operation is not supported.');
        }
        response.setHeader('Access-Control-Allow-Methods', requiredMethod);
        response.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        response.setHeader('Access-Control-Max-Age', '600');
        send(204);
        return;
      }
      if (request.method !== requiredMethod) {
        response.setHeader('Allow', `${requiredMethod}, OPTIONS`);
        throw new HTTPError(405, 'method_not_allowed', 'Method not allowed for this endpoint.');
      }
      if (url.pathname === '/health') {
        send(200, { status: 'ok', service: 'wish-explorer', version: '0.1.0' });
        return;
      }
      // Do not trust client-controlled X-Forwarded-For. See deployment notes for proxies.
      const rate = limiter.check(request.socket.remoteAddress ?? 'unknown');
      response.setHeader('X-RateLimit-Limit', String(rate.limit));
      response.setHeader('X-RateLimit-Remaining', String(rate.remaining));
      if (!rate.allowed) {
        response.setHeader('Retry-After', String(rate.retryAfter));
        throw new HTTPError(429, 'rate_limited', 'Please wait a moment before trying again.');
      }
      if (url.pathname === '/v1/catalog') {
        send(200, catalog);
        return;
      }
      const input = await readJSON(request, bodyLimitBytes);
      send(200, buildWishPreview(input));
    } catch (error) {
      // Never reflect bodies, headers, stack traces, or arbitrary input in an error.
      if (error instanceof InputError) send(400, { error: { code: 'invalid_choices', message: error.message } });
      else if (error instanceof HTTPError) {
        if (error.status === 413 || error.status === 415) response.setHeader('Connection', 'close');
        send(error.status, { error: { code: error.code, message: error.message } });
      } else send(500, { error: { code: 'internal_error', message: 'The preview could not be created. Please try again.' } });
    }
  });
  server.once('listening', () => limiter.start());
  server.once('close', () => limiter.dispose());
  server.requestTimeout = 10_000;
  server.headersTimeout = 5_000;
  server.keepAliveTimeout = 5_000;
  server.maxHeadersCount = 40;
  server.maxRequestsPerSocket = 100;
  return server;
}
