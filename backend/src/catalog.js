// Demo choices are examples, not a promise of eligibility, availability, or fulfillment.
export const destinations = Object.freeze([
  Object.freeze({ id: 'six-flags-great-america', name: 'Six Flags Great America', region: 'Gurnee, Illinois' }),
  Object.freeze({ id: 'disney-world', name: 'Walt Disney World', region: 'Orlando, Florida' }),
  Object.freeze({ id: 'universal-orlando', name: 'Universal Orlando', region: 'Orlando, Florida' }),
]);

export const coasterColors = Object.freeze([
  Object.freeze({ id: 'blue', name: 'Blue', hex: '#1675D1' }),
  Object.freeze({ id: 'pink', name: 'Pink', hex: '#D84D8D' }),
  Object.freeze({ id: 'purple', name: 'Purple', hex: '#7D55BE' }),
  Object.freeze({ id: 'green', name: 'Green', hex: '#208A62' }),
]);

export const animals = Object.freeze([
  Object.freeze({ id: 'giraffe', name: 'Giraffe' }),
  Object.freeze({ id: 'dolphin', name: 'Dolphin' }),
  Object.freeze({ id: 'tiger', name: 'Tiger' }),
]);

export const catalog = Object.freeze({
  version: '1',
  previewCategoryId: 'go',
  categories: [
    { id: 'go', name: 'I wish to go', previewAvailable: true },
    { id: 'meet', name: 'I wish to meet', previewAvailable: false },
    { id: 'have', name: 'I wish to have', previewAvailable: false },
    { id: 'be', name: 'I wish to be', previewAvailable: false },
    { id: 'give', name: 'I wish to give', previewAvailable: false },
    { id: 'explore', name: 'Help me choose', kind: 'navigation', previewAvailable: false },
  ],
  destinations,
  coasterColors,
  animals,
  notice: 'Explore ideas together. These example destinations and experiences are not confirmed wishes. Animals are imagination choices, not claims about a park.',
});
