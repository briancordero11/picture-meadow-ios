import { createWishHandler, parseAllowedOrigins } from '../src/server.js';
import { sceneServiceFromEnvironment } from '../src/scene.js';

// One shared Function serves all fixed API paths. No wish or image is persisted.
const handler = createWishHandler({
  allowedOrigins: parseAllowedOrigins(process.env.CORS_ALLOWED_ORIGINS),
  sceneService: sceneServiceFromEnvironment(),
});
handler.start();
export default handler;
