import { createHash } from 'node:crypto';
import { animals, coasterColors, destinations } from './catalog.js';

export class InputError extends Error {
  constructor(message) {
    super(message);
    this.name = 'InputError';
  }
}

const allowedFields = new Set(['categoryId', 'destinationId', 'coasterColor', 'animalIds']);

export function validateWish(input) {
  if (input === null || typeof input !== 'object' || Array.isArray(input)) {
    throw new InputError('Send a JSON object with the four supported choice fields.');
  }
  if (Object.keys(input).length !== 4 || Object.keys(input).some(key => !allowedFields.has(key))) {
    throw new InputError('Only categoryId, destinationId, coasterColor, and animalIds are supported. Do not send personal information.');
  }
  if (input.categoryId !== 'go') throw new InputError('The illustrated demo supports categoryId "go".');
  if (!destinations.some(item => item.id === input.destinationId)) throw new InputError('Choose a supported destinationId from the catalog.');
  if (!coasterColors.some(item => item.id === input.coasterColor)) throw new InputError('Choose a supported coasterColor from the catalog.');
  if (!Array.isArray(input.animalIds) || input.animalIds.length > animals.length || input.animalIds.some(id => !animals.some(item => item.id === id))) {
    throw new InputError('animalIds must be an array of up to three supported animal IDs.');
  }
  if (new Set(input.animalIds).size !== input.animalIds.length) throw new InputError('Each animal ID may appear only once.');
  // Normalize order so the same choices always produce the same postcard and ID.
  return {
    categoryId: 'go',
    destinationId: input.destinationId,
    coasterColor: input.coasterColor,
    animalIds: animals.filter(item => input.animalIds.includes(item.id)).map(item => item.id),
  };
}

export function escapeXML(value) {
  return String(value).replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' })[character]);
}

function animalDrawing(id, x) {
  const shape = {
    giraffe: '<path d="M-20 72V4Q-15-20 8-18Q32-16 32 5V72" fill="#E9B85C"/><ellipse cx="7" cy="-18" rx="37" ry="29" fill="#F3C873"/><path d="M-11-41L-16-56M21-41L26-56" stroke="#975C36" stroke-width="9" stroke-linecap="round"/><ellipse cx="-24" cy="-31" rx="17" ry="9" fill="#E9B85C"/><ellipse cx="34" cy="-31" rx="17" ry="9" fill="#E9B85C"/><circle cx="-5" cy="-20" r="4" fill="#243B53"/><circle cx="23" cy="-20" r="4" fill="#243B53"/><ellipse cx="9" cy="-4" rx="21" ry="11" fill="#FBE6B5"/><path d="M-7 17L9 13L14 28L-4 33ZM13 45L29 40L29 58L14 61Z" fill="#B47B42"/>',
    dolphin: '<path d="M-70 29Q-24-45 45-18L81-31L70-7L91 3L53 9Q22 50-28 51L-48 74L-53 48L-77 42Z" fill="#6FB8D4"/><path d="M-12-17L2-49L21-20M5 27L34 57L32 19" fill="#4299BE"/><path d="M-47 35Q-1 16 49 8Q22 44-25 46Z" fill="#B8E4EE"/><circle cx="43" cy="-2" r="5" fill="#243B53"/>',
    tiger: '<circle cx="-35" cy="-27" r="22" fill="#E99C43"/><circle cx="35" cy="-27" r="22" fill="#E99C43"/><circle cy="15" r="59" fill="#F2B459"/><path d="M-48-17L-22-4L-46 6M48-17L22-4L46 6M-52 26L-30 34L-45 45M52 26L30 34L45 45M-7-42L0-14L7-42" fill="#7E522F"/><ellipse cy="40" rx="32" ry="23" fill="#FFF1D6"/><circle cx="-20" cy="14" r="5" fill="#243B53"/><circle cx="20" cy="14" r="5" fill="#243B53"/><path d="M-8 34L0 42L8 34ZM0 43V53M-13 53Q0 63 13 53" fill="#243B53" stroke="#243B53" stroke-width="3" stroke-linecap="round"/>',
  }[id];
  const label = animals.find(item => item.id === id).name;
  return `<g transform="translate(${x} 700)">${shape}<text x="0" y="112" text-anchor="middle" font-size="26" fill="#274B65">${escapeXML(label)}</text></g>`;
}

export function buildWishPreview(input) {
  const wish = validateWish(input);
  const destination = destinations.find(item => item.id === wish.destinationId);
  const color = coasterColors.find(item => item.id === wish.coasterColor);
  const animalNames = wish.animalIds.map(id => animals.find(item => item.id === id).name.toLowerCase());
  const animalPhrase = animalNames.length ? ` I am imagining ${animalNames.join(', ')} too.` : '';
  const title = `My wish: ${destination.name}`;
  const description = `I wish to go to ${destination.name} and imagine a ${color.name.toLowerCase()} roller coaster.${animalPhrase} This is an illustrated idea to discuss with my grown-up, not a confirmed trip.`;
  const id = `wish_${createHash('sha256').update(JSON.stringify(wish)).digest('hex').slice(0, 20)}`;
  const animalX = { 1: [600], 2: [470, 730], 3: [350, 600, 850] }[wish.animalIds.length] ?? [];
  const spokes = Array.from({ length: 8 }, (_, index) => {
    const radians = index * Math.PI / 4;
    const x = 320 + 120 * Math.cos(radians);
    const y = 367 + 120 * Math.sin(radians);
    return `<path d="M320 367L${x.toFixed(2)} ${y.toFixed(2)}" stroke="#7FACC6" stroke-width="5"/><rect x="${(x - 19).toFixed(2)}" y="${(y - 12).toFixed(2)}" width="38" height="32" rx="10" fill="#F3C76E"/>`;
  }).join('');
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="900" viewBox="0 0 1200 900" role="img" aria-labelledby="title description">
<title id="title">${escapeXML(title)}</title><desc id="description">${escapeXML(description)}</desc>
<rect width="1200" height="900" rx="42" fill="#F8F4E9"/><rect x="32" y="32" width="1136" height="836" rx="30" fill="#E9F5FA"/>
<circle cx="1010" cy="182" r="68" fill="#F5D47D"/><path d="M100 223Q155 166 211 213Q260 170 309 223M674 215Q722 165 775 206Q816 169 857 215" fill="white" stroke="white" stroke-width="22" stroke-linecap="round"/>
<text x="600" y="108" text-anchor="middle" font-family="system-ui, sans-serif" font-size="28" font-weight="600" fill="#417391">MY WISH POSTCARD</text>
<text x="600" y="164" text-anchor="middle" font-family="system-ui, sans-serif" font-size="43" font-weight="700" fill="#173C57">${escapeXML(destination.name)}</text>
<path d="M32 562Q253 509 476 555Q766 493 1168 554V868H32Z" fill="#D2E8D0"/>
<path d="M259 555L320 367L381 555" fill="none" stroke="#6C9FB8" stroke-width="16" stroke-linejoin="round"/><circle cx="320" cy="367" r="120" fill="none" stroke="#7FACC6" stroke-width="10"/>${spokes}<circle cx="320" cy="367" r="16" fill="#417391"/>
<path d="M503 552V455M572 552V350M650 552V320M730 552V455M811 552V458M902 552V331M999 552V295M1095 552V453" stroke="#B2C6CE" stroke-width="9"/>
<path d="M480 484C540 483 530 313 633 309S701 489 782 490S856 288 977 287S1041 471 1110 467" fill="none" stroke="${color.hex}" stroke-width="19" stroke-linecap="round"/>
<g transform="translate(613 294) rotate(-8)"><rect x="-32" y="-20" width="65" height="32" rx="10" fill="#F5D47D"/><circle cx="-19" cy="13" r="8" fill="#274B65"/><circle cx="20" cy="13" r="8" fill="#274B65"/><circle cx="-12" cy="-25" r="11" fill="#BC8768"/><circle cx="16" cy="-25" r="11" fill="#E5B997"/></g>
<text x="600" y="609" text-anchor="middle" font-family="system-ui, sans-serif" font-size="31" fill="#274B65">A ${escapeXML(color.name.toLowerCase())} coaster. My imagination.</text>
<g font-family="system-ui, sans-serif">${wish.animalIds.map((animal, index) => animalDrawing(animal, animalX[index])).join('')}</g>
${wish.animalIds.length === 0 ? '<path d="M570 711L580 735L606 737L586 754L592 780L570 766L548 780L554 754L534 737L560 735Z" fill="#F3C76E"/>' : ''}
<text x="600" y="851" text-anchor="middle" font-family="system-ui, sans-serif" font-size="19" fill="#417391">An illustrated idea for a conversation. Experiences are not confirmed.</text></svg>`;
  return { id, title, description, image: { mimeType: 'image/svg+xml', data: svg }, provider: 'illustrated-demo' };
}
