import { readFileSync } from 'node:fs';
import { createHash, randomUUID, timingSafeEqual } from 'node:crypto';
import { generateText } from 'ai';
import { InputError } from './preview.js';

export const MAX_SCENE_IMAGE_BYTES = Math.floor(2.8 * 1024 * 1024);
export const SCENE_PROVIDER = 'Google Vertex AI via Vercel AI Gateway';
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

/** Calls the real Gateway API. SDK telemetry and automatic retries are disabled. */
export function createGatewaySceneProvider({ model, generate = generateText } = {}) {
  if (typeof model !== 'string' || !/^google\/[a-z0-9.-]+$/.test(model)) throw new Error('AI_GATEWAY_MODEL must be a verified Google multimodal image-output model ID.');
  return async ({ prompt, signal }) => {
    const result = await generate({
      model,
      prompt,
      maxRetries: 0,
      abortSignal: signal,
      timeout: 90_000,
      providerOptions: {
        gateway: { only: ['vertex'], zeroDataRetention: true, disallowPromptTraining: true },
        google: { responseModalities: ['IMAGE'], imageConfig: { aspectRatio: '4:3', imageSize: '1K' } },
      },
      telemetry: { isEnabled: false },
    });
    if (result.finishReason === 'content-filter') throw new SceneError(422, 'generation_refused', 'The image service could not draw this idea. Try different picture choices.');
    const file = result.files?.find(item => ['image/png', 'image/jpeg', 'image/webp'].includes(item.mediaType));
    if (!file) throw new SceneError(422, 'generation_refused', 'The image service did not draw a picture. Try different picture choices.');
    return { mimeType: file.mediaType, bytes: file.uint8Array };
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
        if ([401, 402, 403].includes(error?.statusCode)) throw new SceneError(503, 'generation_unavailable', 'The image service is not available. A grown-up can check its connection.');
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
  // Deployed Functions receive OIDC on each invocation, not necessarily as an
  // environment variable. The AI SDK obtains the current request's token.
  const credentialPath = env.VERCEL === '1' || env.AI_GATEWAY_API_KEY || env.VERCEL_OIDC_TOKEN;
  const configured = Boolean(enabled && env.SCENE_ACCESS_TOKEN && env.AI_GATEWAY_MODEL && credentialPath);
  return createSceneService({
    accessToken: env.SCENE_ACCESS_TOKEN || undefined,
    enabled: configured,
    provider: configured ? createGatewaySceneProvider({ model: env.AI_GATEWAY_MODEL }) : undefined,
  });
}
