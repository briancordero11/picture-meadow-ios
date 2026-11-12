import { readFileSync } from 'node:fs';
import { createHash, randomUUID, timingSafeEqual } from 'node:crypto';
import { InputError } from './preview.js';

export const MAX_SCENE_IMAGE_BYTES = Math.floor(2.8 * 1024 * 1024);
export const SCENE_PROVIDER = 'OpenAI (direct)';
export const DEFAULT_SCENE_MODEL = 'gpt-image-2.5-flare';
const sceneModels = new Set([DEFAULT_SCENE_MODEL, 'gpt-image-2.5-flare-2026-09-08']);
const OPENAI_IMAGES_URL = 'https://api.openai.com/v1/images/generations';
const MAX_PROVIDER_RESPONSE_BYTES = 4_000_000;
const fields = new Set(['interestId', 'actionIds', 'settingId', 'favoriteIds', 'essentialChoiceId']);

export class SceneError extends Error {
  constructor(status, code, message) {
    super(message);
    Object.assign(this, { status, code });
  }
}

export function loadJourneyCatalog() {
  return JSON.parse(readFileSync(new URL('./journey-catalog.json', import.meta.url), 'utf8'));
}

export function validateScene(input, catalog = loadJourneyCatalog()) {
  if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).length !== fields.size || Object.keys(input).some(key => !fields.has(key))) {
    throw new InputError('Send only interestId, actionIds, settingId, favoriteIds, and essentialChoiceId. Do not send personal information.');
  }
  const interest = catalog.interests.find(item => item.id === input.interestId);
  if (!interest) throw new InputError('Choose a supported interest from the picture catalog.');
  const favorites = catalog.favorites.flatMap(group => group.options);
  function selection(ids, options, maximum, label) {
    if (!Array.isArray(ids) || ids.length > maximum || ids.some(id => typeof id !== 'string' || !options.some(option => option.id === id)) || new Set(ids).size !== ids.length) {
      throw new InputError(`Choose up to ${maximum} different supported ${label}.`);
    }
    return options.filter(option => ids.includes(option.id));
  }
  const actions = selection(input.actionIds, interest.actions, 3, 'actions for this interest');
  const selectedFavorites = selection(input.favoriteIds, favorites, 10, 'favorites');
  const setting = input.settingId === null ? null : interest.settings.find(option => option.id === input.settingId);
  if (setting === undefined) throw new InputError('Choose a supported setting for this interest, or leave it empty.');
  const selected = [...actions, ...(setting ? [setting] : []), ...selectedFavorites];
  if (input.essentialChoiceId !== null && !selected.some(option => option.id === input.essentialChoiceId)) {
    throw new InputError('The most important part must be one of the selected pictures, or left empty.');
  }
  // Catalog order makes the same selection canonical; arbitrary request text never becomes a prompt.
  return { interest, actions, setting, favorites: selectedFavorites, essential: selected.find(option => option.id === input.essentialChoiceId) ?? null };
}

export function composeScene(wish) {
  const fragments = [
    'Generate exactly one warm, clear, child-appropriate illustration of an imagined wish, in a landscape composition.',
    'Combine these selected picture concepts into one coherent scene rather than a grid of separate cards.',
    `Topic: ${wish.interest.label ?? wish.interest.id.replaceAll('-', ' ')}.`,
    wish.actions.length ? `Show these actions: ${wish.actions.map(item => item.prompt).join('; ')}.` : '',
    wish.setting ? `Scene or object: ${wish.setting.prompt}.` : '',
    wish.favorites.length ? `Optional favorite details: ${wish.favorites.map(item => item.prompt).join('; ')}.` : '',
    wish.essential ? `Make this selected part visually central: ${wish.essential.prompt}.` : '',
    'Colors are artistic preferences, never a claim about real ride availability. Show a whole experience when activities are chosen.',
    'Use generic places and objects except for a selected named natural destination. Do not invent sponsors, brands, logos, characters, specific rides, bookings, eligibility, approvals, or guaranteed equipment.',
    'Keep animals in suitable separate habitats; do not suggest unsafe contact, dangerous behavior, violence, medical treatment, or photorealistic child likenesses.',
    'Use a welcoming illustrated setting with no identifiable people, text, names, diagnoses, addresses, uniforms, watermarks, or product logos.',
    'Return the image only. This is an imagined idea for discussion, not a confirmed event or item.',
  ].filter(Boolean);
  const title = 'My imagined wish';
  const parts = [...wish.actions.map(item => item.label), ...(wish.setting ? [wish.setting.label] : []), ...wish.favorites.map(item => item.label)];
  const description = `I am imagining ${parts.length ? parts.join(', ') : wish.interest.id.replaceAll('-', ' ')}.${wish.essential ? ` The most important part is ${wish.essential.label}.` : ''} This picture is an idea to discuss with my grown-up. Experiences and items are not confirmed.`;
  return { prompt: fragments.join('\n'), title, description };
}

function imageMatchesMime(bytes, mimeType) {
  if (mimeType === 'image/png') return bytes.length >= 8 && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
  if (mimeType === 'image/jpeg') return bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  if (mimeType === 'image/webp') return bytes.length >= 12 && bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP';
  return false;
}

export function safeSceneImage(image) {
  if (!image || !(image.bytes instanceof Uint8Array) || image.bytes.byteLength === 0 || image.bytes.byteLength > MAX_SCENE_IMAGE_BYTES) {
    throw new SceneError(502, 'image_too_large', 'The generated picture could not be used. Please try again.');
  }
  const bytes = Buffer.from(image.bytes);
  if (!imageMatchesMime(bytes, image.mimeType)) throw new SceneError(502, 'generation_failed', 'The image service returned an unsupported picture. Please try again.');
  return { mimeType: image.mimeType, data: bytes.toString('base64') };
}

async function boundedProviderJSON(response, maximum, signal) {
  if (Number(response.headers.get('content-length')) > maximum || !response.headers.get('content-type')?.toLowerCase().startsWith('application/json') || !response.body) {
    await response.body?.cancel();
    throw new SceneError(502, 'generation_failed', 'The image service returned an unsupported response. Please try again.');
  }
  const reader = response.body.getReader();
  const chunks = [];
  let bytes = 0;
  try {
    for (;;) {
      signal.throwIfAborted();
      const chunk = await reader.read();
      if (chunk.done) break;
      bytes += chunk.value.byteLength;
      if (bytes > maximum) throw new SceneError(502, 'image_too_large', 'The generated picture could not be used. Please try again.');
      chunks.push(Buffer.from(chunk.value));
    }
    signal.throwIfAborted();
    try { return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(chunks))); }
    catch { throw new SceneError(502, 'generation_failed', 'The image service returned an unsupported response. Please try again.'); }
  } finally {
    await reader.cancel().catch(() => {});
    reader.releaseLock();
  }
}

/** One direct request to the fixed official Images API. No router, retry, or uploaded file. */
export function createOpenAISceneProvider({ apiKey, model = DEFAULT_SCENE_MODEL, fetchImpl = fetch, timeoutMs = 90_000 } = {}) {
  if (!sceneModels.has(model)) throw new Error('OPENAI_IMAGE_MODEL must be an allowlisted GPT Image 2.5 Flare model.');
  if (typeof apiKey !== 'string' || !apiKey.trim() || /\s/.test(apiKey)) throw new Error('Configure a server-only OPENAI_API_KEY.');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 90_000) throw new Error('Provider timeout must be between 1 and 90000 ms.');
  return async ({ prompt, signal }) => {
    const deadline = AbortSignal.timeout(timeoutMs);
    const combined = signal ? AbortSignal.any([signal, deadline]) : deadline;
    try {
      combined.throwIfAborted();
      const response = await fetchImpl(OPENAI_IMAGES_URL, {
        method: 'POST', redirect: 'error', cache: 'no-store', credentials: 'omit', signal: combined,
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify({ model, prompt, n: 1, size: '1536x1024', quality: 'medium', output_format: 'jpeg', output_compression: 80, moderation: 'auto' }),
      });
      if (!response.ok) {
        // Only stable, allowlisted error codes affect handling. Provider messages,
        // request IDs, moderation categories, and response bodies are discarded.
        if ([400, 422, 429].includes(response.status)) {
          const result = await boundedProviderJSON(response, 16_384, combined);
          if (result?.error?.code === 'moderation_blocked') throw new SceneError(422, 'generation_refused', 'The image service could not draw this idea. Try different picture choices.');
          if (['insufficient_quota', 'credit_balance_exhausted', 'organization_spend_limit_exceeded', 'project_spend_limit_exceeded', 'organization_usage_limit_exceeded'].includes(result?.error?.code)) throw new SceneError(503, 'generation_budget_unavailable', 'Image generation credits or a spending allowance are unavailable. The operator can check the service budget.');
        } else await response.body?.cancel();
        throw Object.assign(new Error('Image provider request failed.'), { statusCode: response.status });
      }
      const result = await boundedProviderJSON(response, MAX_PROVIDER_RESPONSE_BYTES, combined);
      const encoded = result?.data?.length === 1 ? result.data[0]?.b64_json : undefined;
      if (typeof encoded !== 'string' || !encoded) throw new SceneError(422, 'generation_refused', 'The image service did not draw a picture. Try different picture choices.');
      if (encoded.length > Math.ceil(MAX_SCENE_IMAGE_BYTES / 3) * 4) throw new SceneError(502, 'image_too_large', 'The generated picture could not be used. Please try again.');
      const decoded = Buffer.from(encoded, 'base64');
      if (decoded.toString('base64') !== encoded) throw new SceneError(502, 'generation_failed', 'The image service returned an unsupported picture. Please try again.');
      const image = { mimeType: 'image/jpeg', bytes: decoded };
      safeSceneImage(image);
      return image;
    } catch (error) {
      if (combined.aborted) throw new SceneError(deadline.aborted ? 504 : 499, deadline.aborted ? 'generation_timeout' : 'generation_cancelled', deadline.aborted ? 'Drawing took too long. You can try again.' : 'Drawing was cancelled.');
      throw error;
    }
  };
}

/** Access tokens are compared as fixed-size hashes; no token is logged or returned. */
export function sceneTokenAuthorized(header, accessToken) {
  if (typeof header !== 'string' || !header.startsWith('Bearer ') || !accessToken) return false;
  const supplied = header.slice(7);
  const suppliedBytes = Buffer.byteLength(supplied, 'utf8');
  if (suppliedBytes < 32 || suppliedBytes > 256) return false;
  const hash = value => createHash('sha256').update(value).digest();
  return timingSafeEqual(hash(supplied), hash(accessToken));
}

export function createSceneService({ accessToken, provider, catalog, enabled = true, timeoutMs = 95_000, maxConcurrent = 2 } = {}) {
  if (accessToken !== undefined && (typeof accessToken !== 'string' || Buffer.byteLength(accessToken, 'utf8') < 32 || Buffer.byteLength(accessToken, 'utf8') > 256 || /\s/.test(accessToken))) throw new Error('SCENE_ACCESS_TOKEN must contain 32–256 non-whitespace UTF-8 bytes.');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 120_000) throw new Error('Scene timeout must be between 1 and 120000 ms.');
  if (!Number.isSafeInteger(maxConcurrent) || maxConcurrent < 1 || maxConcurrent > 10) throw new Error('Scene concurrency must be between 1 and 10.');
  const available = enabled && Boolean(accessToken && provider);
  let inFlight = 0;
  return {
    capabilities: Object.freeze({ enabled: available, mode: available ? 'ai-scene' : 'offline-only', provider: SCENE_PROVIDER, accepts: 'catalog-choice-ids', uploads: false, requiresAdultPermission: true, maxImageBytes: MAX_SCENE_IMAGE_BYTES }),
    authorize(header) {
      if (!available) throw new SceneError(503, 'generation_unavailable', 'Online image generation is not connected. Your picture choices are still available on this device.');
      if (!sceneTokenAuthorized(header, accessToken)) throw new SceneError(401, 'unauthorized', 'A grown-up needs to connect the image service in Settings.');
    },
    async generate(input, { signal } = {}) {
      if (!available) throw new SceneError(503, 'generation_unavailable', 'Online image generation is not connected.');
      const wish = validateScene(input, catalog);
      if (inFlight >= maxConcurrent) throw new SceneError(429, 'generation_busy', 'The image service is busy. Please wait before trying again.');
      const scene = composeScene(wish);
      const deadline = AbortSignal.timeout(timeoutMs);
      const combined = signal ? AbortSignal.any([signal, deadline]) : deadline;
      let abort;
      inFlight += 1;
      try {
        combined.throwIfAborted();
        const interrupted = new Promise((_, reject) => {
          abort = () => reject(combined.reason);
          combined.addEventListener('abort', abort, { once: true });
        });
        const image = await Promise.race([provider({ prompt: scene.prompt, signal: combined }), interrupted]);
        combined.throwIfAborted();
        return { id: `scene_${randomUUID()}`, title: scene.title, description: scene.description, image: safeSceneImage(image), provider: SCENE_PROVIDER };
      } catch (error) {
        if (error instanceof SceneError) throw error;
        if (combined.aborted) throw new SceneError(deadline.aborted ? 504 : 499, deadline.aborted ? 'generation_timeout' : 'generation_cancelled', deadline.aborted ? 'Drawing took too long. You can try again.' : 'Drawing was cancelled.');
        // Provider errors can include request content or credentials. Return only fixed messages.
        if (error?.statusCode === 429) throw new SceneError(429, 'generation_busy', 'The image service is busy. Please wait before trying again.');
        if (error?.statusCode === 401) throw new SceneError(503, 'generation_not_authorized', 'The image service could not authenticate with its provider. The operator can check the server connection.');
        if (error?.statusCode === 402) throw new SceneError(503, 'generation_budget_unavailable', 'Image generation credits or a spending allowance are unavailable. The operator can check the service budget.');
        if (error?.statusCode === 403) throw new SceneError(503, 'generation_access_denied', 'The provider did not allow this image request. The operator can check model access and data-handling eligibility.');
        throw new SceneError(502, 'generation_failed', 'The picture could not be drawn. Your choices are still here. Please try again.');
      } finally {
        if (abort) combined.removeEventListener('abort', abort);
        inFlight -= 1;
      }
    },
  };
}

export function sceneServiceFromEnvironment(env = process.env) {
  const enabled = env.SCENE_GENERATION_ENABLED === 'true';
  // This attestation records an operator's review; it does not activate OpenAI
  // Zero Data Retention. That requires approval and account/project settings.
  const reviewed = env.SCENE_PROVIDER_REVIEWED === 'true';
  const configured = Boolean(enabled && reviewed && env.SCENE_ACCESS_TOKEN && env.OPENAI_IMAGE_MODEL && env.OPENAI_API_KEY);
  return createSceneService({
    accessToken: env.SCENE_ACCESS_TOKEN || undefined,
    enabled: configured,
    provider: configured ? createOpenAISceneProvider({ model: env.OPENAI_IMAGE_MODEL, apiKey: env.OPENAI_API_KEY }) : undefined,
  });
}
