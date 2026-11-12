(() => {
  const pictures = __PICTURE_DATA__;
  const journeys = __JOURNEY_DATA__;
  const artwork = __ARTWORK_DATA__;
  const root = document.getElementById('wish-picture-board-preview');
  const app = root.querySelector('.pb-app');
  const screen = root.querySelector('.pb-screen');
  const drawer = root.querySelector('.pb-drawer');
  const panel = root.querySelector('#pb-core-panel');
  const handle = root.querySelector('.pb-handle');
  const homeButton = root.querySelector('.pb-home');
  const heading = root.querySelector('.pb-wordmark');
  const phraseOutput = root.querySelector('output');
  const status = root.querySelector('.pb-status');
  const settingsButton = root.querySelector('.pb-settings');
  const settingsDialog = root.querySelector('#pb-settings-dialog');
  const interests = pictures.items.filter(item => item.kind === 'interest');
  const allChoices = journeys.interests.flatMap(item => [...item.actions, ...item.settings])
    .concat(journeys.favorites.flatMap(group => group.options));
  const coreRows = [
    ['i', 'want', 'see', 'wet', 'more'], ['you', 'go', 'help', 'dry', 'where'],
    ['we', 'stop', 'act', 'hot', 'what'], ['watch', 'like', 'give', 'cold', 'when'],
    ['wish', 'eat', 'meet', 'tired', 'who'], ['yes', 'no-dont', 'finished', 'happy', 'why']
  ];
  const phraseIDs = ['this-is-fun', 'thank-you', 'time-to-think', 'break'];
  const state = { view: 'home', stage: 0, interest: null, actionIds: [], settingId: null, favoriteIds: [], essentialId: null, phrase: [], open: false, pause: false };
  const lastJourneyStage = 2;
  const journeyProgress = () => (state.stage + 1) / (lastJourneyStage + 1) * 100;
  let readChoicesAloud = true;
  let voicePreset = 'woman';
  const voicePresets = [
    { id: 'boy', label: 'Boy', male: true, pitch: 1.16 },
    { id: 'girl', label: 'Girl', male: false, pitch: 1.16 },
    { id: 'man', label: 'Man', male: true, pitch: 1 },
    { id: 'woman', label: 'Woman', male: false, pitch: 1 }
  ];
  function selectedVoice() {
    const preset = voicePresets.find(item => item.id === voicePreset) ?? voicePresets[3];
    const voices = 'speechSynthesis' in window ? window.speechSynthesis.getVoices().filter(voice => voice.localService && /^en(?:-|$)/i.test(voice.lang)) : [];
    const maleNames = /\b(david|mark|guy|ryan|christopher|eric|brian|andrew|daniel|alex|evan|tom|oliver|arthur|george)\b/i;
    const femaleNames = /\b(zira|jenny|aria|jane|sara|michelle|emma|ava|allison|samantha|susan|karen|moira|serena|salli)\b/i;
    const matching = voices.filter(voice => (preset.male ? maleNames : femaleNames).test(voice.name));
    const candidates = matching.length ? matching : voices;
    candidates.sort((a, b) => {
      const score = voice => (/natural|premium|enhanced/i.test(voice.name) ? 4 : 0) + (/^en-US$/i.test(voice.lang) ? 2 : 0) + (voice.default ? 1 : 0);
      return score(b) - score(a) || a.name.localeCompare(b.name);
    });
    return { preset, voice: candidates[0] ?? null, matched: matching.length > 0 };
  }
  let gateCode = '';
  let adultSettingsOpen = false;
  let settingsView = 'gate';
  let settingsDestination = 'options';
  let resetReturnView = 'privacy';
  let dialogOpener = settingsButton;
  let drawerMaximum = 0;
  let drawerY = 0;
  let drag = null;
  let suppressClick = false;
  let settleTimer;
  let animating = false;
  let pageAnimations = [];
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  function cancelPageMotion() {
    pageAnimations.forEach(animation => animation.cancel());
    pageAnimations = [];
  }
  function animateBackPage() {
    if (reduceMotion.matches || document.hidden) return;
    pageAnimations.push(...[heading, ...screen.children].filter(element => typeof element.animate === 'function').map(element => element.animate([
      { opacity: 0.5, transform: 'translate3d(-18px,0,0)' },
      { opacity: 1, transform: 'translate3d(0,0,0)' }
    ], { duration: 320, easing: 'cubic-bezier(.22,1,.36,1)' })));
  }
  reduceMotion.addEventListener('change', event => { if (event.matches) cancelPageMotion(); });
  const esc = value => String(value).replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character]));
  const picture = id => pictures.items.find(item => item.id === id);
  const choice = id => allChoices.find(item => item.id === id);
  const symbolArtwork = symbol => '<img class="pb-journey-art" src="' + esc(artwork.symbols[symbol].url) + '" alt="" draggable="false">';
  const choiceSymbol = item => symbolArtwork(artwork.choices[item.id] ?? item.symbol);
  const intakeSymbols = () => ['🌈', '🍓', '🐾', '🎵', '🎮', '🗺️'].map(symbolArtwork).join('');
  const journey = () => journeys.interests.find(item => item.id === state.interest);
  const chosenPictures = () => [...new Set([...state.actionIds, state.settingId, ...state.favoriteIds].filter(Boolean))].map(choice).filter(Boolean);
  const iconize = () => {
    root.querySelectorAll('[data-lucide]').forEach(element => {
      const name = element.getAttribute('data-lucide');
      const image = document.createElement('img');
      image.src = artwork.icons[name];
      image.alt = '';
      image.className = 'pb-ui-icon';
      image.dataset.icon = name;
      image.draggable = false;
      image.setAttribute('aria-hidden', 'true');
      element.replaceWith(image);
    });
  };
  const stopSpeaking = () => { if ('speechSynthesis' in window) { try { window.speechSynthesis.cancel(); } catch {} } };
  const speak = text => {
    if (!text || !('speechSynthesis' in window)) return;
    try {
      stopSpeaking();
      const selection = selectedVoice();
      if (!selection.voice) { status.textContent = 'No English device voice is available in this browser. Your picture choices still work.'; return; }
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.voice = selection.voice;
      utterance.lang = selection.voice.lang;
      utterance.pitch = selection.preset.pitch;
      utterance.rate = 0.9;
      window.speechSynthesis.speak(utterance);
    } catch {}
  };
  function symbol(item) {
    const atlas = pictures.atlases[item.atlas], frame = item.frame;
    const x = atlas.width === frame.width ? 0 : frame.x / (atlas.width - frame.width) * 100;
    const y = atlas.height === frame.height ? 0 : frame.y / (atlas.height - frame.height) * 100;
    return '<span class="pb-picture-box" aria-hidden="true"><span class="pb-symbol" style="width:100%;aspect-ratio:' + frame.width + '/' + frame.height + ';max-height:100%;background-image:url(&quot;' + esc(atlas.url) + '&quot;);background-size:' + atlas.width / frame.width * 100 + '% ' + atlas.height / frame.height * 100 + '%;background-position:' + x + '% ' + y + '%"></span></span>';
  }
  function pictureTile(item, kind) {
    const agency = ['break', 'time-to-think', 'finished', 'thank-you', 'this-is-fun'].includes(item.id);
    return '<button type="button" class="pb-tile" data-' + kind + '="' + item.id + '"' + (item.group ? ' data-group="' + esc(item.group) + '"' : '') + (agency ? ' data-agency="true"' : '') + (item.id === 'no-dont' ? ' data-no="true"' : '') + '><strong>' + esc(item.label) + '</strong>' + symbol(item) + '</button>';
  }
  function choiceTile(item, kind, selected) {
    return '<button type="button" class="pb-tile pb-journey-tile" data-' + kind + '="' + item.id + '" aria-pressed="' + selected + '"><strong>' + esc(item.label) + '</strong><span class="pb-emoji" aria-hidden="true">' + choiceSymbol(item) + '</span></button>';
  }
  const action = (label, attributes, primary = false) => '<button type="button" class="pb-action' + (primary ? ' primary' : '') + '" ' + attributes + '>' + label + '</button>';
  const backAction = () => action('<i data-lucide="arrow-left" aria-hidden="true"></i> Back', 'data-back');
  const navigation = () => '<div class="pb-actions">' + backAction() + action(state.stage === lastJourneyStage ? 'See my wish picture' : 'Next', 'data-next', true) + '</div>';
  function favoriteGroups() {
    return journeys.favorites.map(group => '<section class="pb-favorite-group"><h4>' + esc(group.label) + '</h4><div class="pb-choice-grid">' + group.options.map(item => choiceTile(item, 'favorite', state.favoriteIds.includes(item.id))).join('') + '</div></section>').join('');
  }
  function wishSummary() {
    const interest = picture(state.interest);
    const actions = state.actionIds.map(choice).filter(Boolean).map(item => item.label.toLowerCase());
    const favorites = state.favoriteIds.map(choice).filter(Boolean).map(item => item.label.toLowerCase());
    return ['My ' + (interest?.label.toLowerCase() ?? 'wish') + ' idea.', actions.length ? 'I want to ' + actions.join(', ') + '.' : '', state.settingId ? 'I imagine ' + choice(state.settingId).label.toLowerCase() + '.' : '', favorites.length ? 'I like ' + favorites.join(', ') + '.' : '', state.essentialId ? choice(state.essentialId).label + ' matters most to me.' : ''].filter(Boolean).join(' ');
  }
  function fitSymbols() {
    root.querySelectorAll('.pb-symbol').forEach(view => {
      const box = view.parentElement;
      const [width, height] = view.style.aspectRatio.split('/').map(Number);
      const fittedWidth = Math.min(box.clientWidth, box.clientHeight * width / height);
      view.style.width = fittedWidth + 'px';
      view.style.height = fittedWidth * height / width + 'px';
    });
  }
  function sanitizeEssential() {
    if (!chosenPictures().some(item => item.id === state.essentialId)) state.essentialId = null;
  }
  function render({ resetScroll = false, focus = null } = {}) {
    cancelPageMotion();
    const previousProgress = Number(screen.querySelector('[data-wish-progress]')?.getAttribute('aria-valuenow') ?? 0);
    const previousScroll = screen.scrollTop;
    homeButton.disabled = state.pause || state.view === 'home';
    if (state.view === 'home') {
      heading.innerHTML = '<span>Create your </span><span class="pb-wordmark-wish">wish<span class="pb-wordmark-arc" aria-hidden="true"></span><span class="pb-wordmark-star" aria-hidden="true">★</span></span>';
      heading.setAttribute('aria-label', 'Create your wish');
    } else if (state.view === 'favorites-intake') {
      heading.textContent = 'My favorites';
      heading.setAttribute('aria-label', 'My favorites');
    } else {
      heading.textContent = 'My ' + (picture(state.interest)?.label.toLowerCase() ?? '') + ' wish';
      heading.setAttribute('aria-label', heading.textContent);
    }
    if (state.pause) {
      screen.innerHTML = '<div class="pb-detail"><div class="pb-large-picture">' + symbol(picture('break')) + '</div><h3>Let’s take a break</h3><p>Take all the time you need.</p><div class="pb-actions">' + action('I’m ready', 'data-resume', true) + action('Finished for now', 'data-finish') + '</div></div>';
    } else if (state.view === 'home') {
      screen.innerHTML = '<button type="button" class="pb-intake-card" data-open-intake aria-label="What are your favorites?" aria-describedby="pb-intake-description"><strong>What are your favorites?</strong><span class="pb-intake-symbols" aria-hidden="true">' + intakeSymbols() + '</span><span id="pb-intake-description">Choose colors, food, animals, music, games, and adventures.</span></button><div class="pb-topic-grid" aria-label="Wish pictures">' + interests.map(item => pictureTile(item, 'interest')).join('') + '</div>';
    } else if (state.view === 'favorites-intake') {
      screen.innerHTML = '<div class="pb-detail"><h3>What are your favorites?</h3><p>Pick any pictures you like, up to ten. Every choice is optional.</p>' + favoriteGroups() + '<div class="pb-intake-footer"><div class="pb-actions">' + backAction() + action('Save favorites', 'data-complete-intake data-save-favorites', true) + '</div><p>Saved for this preview session; reloading clears them. The iPad app can retain favorites with Remember choices.</p></div></div>';
    } else if (state.view === 'postcard') {
      screen.innerHTML = '<div class="pb-detail"><h3>My wish picture</h3><div class="pb-picture-card"><div class="pb-large-picture">' + symbol(picture(state.interest)) + '</div><div class="pb-collage">' + chosenPictures().map(item => '<div class="pb-collage-card"><span class="pb-emoji" aria-hidden="true">' + choiceSymbol(item) + '</span><strong>' + esc(item.label) + '</strong>' + (state.essentialId === item.id ? '<span class="pb-essential">♥ Most important</span>' : '') + '</div>').join('') + '</div><p>' + esc(wishSummary()) + '</p></div><p class="pb-note">A picture board from your imagination. Optional AI picture generation is currently off in this preview.</p><div class="pb-actions">' + backAction() + action('Make an AI picture', 'data-ai-picture aria-haspopup="dialog" aria-expanded="false" aria-controls="pb-settings-dialog"', true) + action('Read my wish', 'data-read-wish') + action('<i data-lucide="volume-off" aria-hidden="true"></i>', 'data-stop-speaking aria-label="Stop speaking" title="Stop speaking"') + action('Change my choices', 'data-change') + action('Choose another wish', 'data-home') + '</div></div>';
    } else {
      const current = journey();
      const titles = ['What would you like to do?', 'Choose a place or thing', 'What matters most?'];
      const descriptions = ['Choose up to three pictures.', 'Choose a place or thing for your wish.', 'Pick the picture that is most important to you.'];
      let content;
      if (state.stage === 0) content = '<div class="pb-choice-grid">' + current.actions.map(item => choiceTile(item, 'action', state.actionIds.includes(item.id))).join('') + '</div>';
      else if (state.stage === 1) content = '<div class="pb-choice-grid">' + current.settings.map(item => choiceTile(item, 'setting', state.settingId === item.id)).join('') + '</div>';
      else content = chosenPictures().length ? '<div class="pb-choice-grid">' + chosenPictures().map(item => choiceTile(item, 'essential', state.essentialId === item.id)).join('') + '</div>' : '<p>You can make your picture board now, or go back and add pictures.</p>';
      screen.innerHTML = '<div class="pb-detail"><div class="pb-journey-progress" data-wish-progress role="progressbar" aria-label="Wish progress" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' + Math.round(journeyProgress()) + '"><span class="pb-progress-fill" style="width:' + journeyProgress() + '%"></span></div><h3>' + titles[state.stage] + '</h3><p>' + descriptions[state.stage] + '</p>' + content + navigation() + '</div>';
    }
    phraseOutput.textContent = state.phrase.length ? state.phrase.join(' ') : 'My words…';
    screen.scrollTop = resetScroll ? 0 : previousScroll;
    iconize();
    fitSymbols();
    const progressFill = screen.querySelector('.pb-progress-fill');
    if (progressFill && !reduceMotion.matches && !document.hidden) {
      const currentProgress = journeyProgress();
      if (previousProgress !== Math.round(currentProgress) && typeof progressFill.animate === 'function') {
        pageAnimations.push(progressFill.animate([{ width: previousProgress + '%' }, { width: currentProgress + '%' }], { duration: 360, easing: 'cubic-bezier(.22,1,.36,1)' }));
      }
    }
    if (focus) screen.querySelector(focus)?.focus({ preventScroll: true });
    syncDrawerSemantics();
  }
  function syncDrawerSemantics() {
    const closed = !state.open && !drag && !animating;
    panel.inert = closed;
    panel.setAttribute('aria-hidden', String(closed));
    handle.setAttribute('aria-expanded', String(state.open));
    handle.setAttribute('aria-label', state.open ? 'Close communication words' : 'Open communication words');
    const chevron = root.querySelector('.pb-chevron .pb-ui-icon');
    const chevronName = state.open ? 'chevron-down' : 'chevron-up';
    if (chevron && chevron.dataset.icon !== chevronName) { chevron.src = artwork.icons[chevronName]; chevron.dataset.icon = chevronName; }
    screen.inert = state.open;
    screen.classList.toggle('is-covered', state.open);
  }
  function placeDrawer(y) {
    drawerY = Math.min(Math.max(y, 0), drawerMaximum);
    drawer.style.transform = 'translate3d(0,' + drawerY + 'px,0)';
  }
  function snapDrawer(open, animate = true) {
    clearTimeout(settleTimer);
    drag = null;
    state.open = open;
    animating = animate && !reduceMotion.matches;
    drawer.classList.toggle('pb-is-snapping', animating);
    placeDrawer(open ? 0 : drawerMaximum);
    syncDrawerSemantics();
    if (animating) settleTimer = setTimeout(() => { animating = false; drawer.classList.remove('pb-is-snapping'); syncDrawerSemantics(); }, 400);
  }
  function measureDrawer() {
    drawerMaximum = Math.max(0, drawer.offsetHeight - root.querySelector('.pb-handle-area').offsetHeight);
    snapDrawer(state.open, false);
  }
  handle.addEventListener('pointerdown', event => {
    if (event.button !== 0) return;
    clearTimeout(settleTimer);
    const transform = getComputedStyle(drawer).transform;
    const shownY = transform === 'none' ? drawerY : new DOMMatrixReadOnly(transform).m42;
    drawer.classList.remove('pb-is-snapping');
    animating = false;
    placeDrawer(shownY);
    drag = { pointer: event.pointerId, startY: event.clientY, startDrawerY: drawerY, lastY: event.clientY, lastTime: performance.now(), velocity: 0, moved: false };
    handle.setPointerCapture(event.pointerId);
  });
  handle.addEventListener('pointermove', event => {
    if (!drag || drag.pointer !== event.pointerId) return;
    const delta = event.clientY - drag.startY;
    if (!drag.moved && Math.abs(delta) < 5) return;
    drag.moved = true;
    const now = performance.now();
    drag.velocity = (event.clientY - drag.lastY) / Math.max(1, now - drag.lastTime);
    drag.lastY = event.clientY; drag.lastTime = now;
    placeDrawer(drag.startDrawerY + delta);
    syncDrawerSemantics();
  });
  handle.addEventListener('pointerup', event => {
    if (!drag || drag.pointer !== event.pointerId) return;
    if (drag.moved) {
      suppressClick = true;
      const velocity = performance.now() - drag.lastTime < 100 ? drag.velocity : 0;
      snapDrawer(drawerY + velocity * 150 < drawerMaximum / 2);
    } else drag = null;
    if (handle.hasPointerCapture(event.pointerId)) handle.releasePointerCapture(event.pointerId);
  });
  handle.addEventListener('pointercancel', () => snapDrawer(state.open));
  handle.addEventListener('lostpointercapture', () => { if (drag) snapDrawer(state.open); });
  handle.addEventListener('click', () => { if (suppressClick) { suppressClick = false; return; } snapDrawer(!state.open); });
  handle.addEventListener('keydown', event => {
    if (['ArrowUp', 'ArrowDown', 'Escape'].includes(event.key)) { event.preventDefault(); snapDrawer(event.key === 'ArrowUp'); }
  });
  function freshWish() {
    stopSpeaking();
    Object.assign(state, { view: 'home', stage: 0, interest: null, actionIds: [], settingId: null, favoriteIds: [], essentialId: null, phrase: [], pause: false });
    snapDrawer(false); render({ resetScroll: true });
  }
  function privacyInformation() {
    return [
      '<h4>This browser preview</h4>',
      '<p>Your wish choices, talking-board sentence, read-aloud preference, and selected voice style stay in this page’s memory. Reloading or closing the page clears them.</p>',
      '<p>This preview sends no AI requests. It has no saved drafts, accounts, photo uploads, or service access codes. Speech uses an available English device voice in your browser.</p>',
      '<h4>Native app data on the iPad</h4>',
      '<p>A grown-up can opt in to remembering selected picture concepts in local app preferences. These saved preferences may be included in device backups. Turning remembering off removes the app’s saved draft.</p>',
      '<p>The native app also saves narration and voice preferences locally. Forget choices restores their defaults.</p>',
      '<p>A configured image-service access code persists separately in this device’s Keychain. It can be read only while the device is unlocked and does not sync to other devices.</p>',
      '<p>The talking-board sentence is temporary. Generated AI pictures stay in working memory (RAM), are omitted from saved drafts, and have no app-saved gallery.</p>',
      '<h4>Optional online AI — currently off</h4>',
      '<p>AI is off in this preview and in the current default native app configuration. If connected later, a grown-up confirms each request. Selected concept IDs go to the image-service host, which builds a prompt for OpenAI (direct). Original pictures, photographs, and child identity are excluded from that request.</p>',
      '<p>The image service processes requests and returned pictures in memory, with no application database or image gallery. Temporary IP-based rate limits and the hosting provider’s technical metadata or logs can still exist.</p>',
      '<p>OpenAI’s standard abuse-monitoring logs are normally retained for up to 30 days, subject to policy exceptions. Zero Data Retention requires actual provider approval and account setup. It is not enabled for this prototype, and changing an app setting does not activate it.</p>'
    ].join('');
  }
  function appInformation() {
    return [
      '<h4>Exploring a wish</h4>',
      '<p>Start with What are your favorites? or choose an interest picture directly. Favorites carry across interest choices. Choose up to three actions, a place or thing, and the picture that matters most. Use Next to leave a part unanswered, Back to revisit a part, or Home to return to the wish pictures. You can take a break at any time.</p>',
      '<h4>Using the talking board</h4>',
      '<p>Tap the center tab or drag it up to open the words. Tap pictures to speak, use the crossed-out speaker to stop speech, and use Clear to empty the sentence. Tap or drag the tab down to close the board.</p>',
      '<h4>About this prototype</h4>',
      '<p>Wish Explorer is an independent prototype for exploring a child’s interests with a grown-up. The browser preview shows picture concepts and a collage. Real wish arrangements and approvals are handled separately.</p>',
      '<h4>Contact or report an issue</h4>',
      '<p>Publisher and support details are being finalized. This preview has no configured support address, public policy link, or report-sending service.</p>',
      '<p>When a publisher’s support address is configured in the native app, Contact can open a generic email draft. You choose what to include, can edit the draft, and control Send in your email app. A wish sentence, images, and child identity are not attached automatically.</p>'
    ].join('');
  }
  function aiPictureInformation() {
    const selected = chosenPictures();
    const summary = selected.length
      ? '<ul class="pb-ai-summary">' + selected.map(item => '<li><span aria-hidden="true">' + choiceSymbol(item) + '</span> ' + esc(item.label) + (state.essentialId === item.id ? ' — most important' : '') + '</li>').join('') + '</ul>'
      : '<p>Choose some wish pictures to bring together in a scene.</p>';
    return '<p>Optional AI picture making combines selected concepts into one imagined scene. A grown-up reviews the result before showing it.</p><h4>Selected picture concepts</h4>' + (state.interest ? '<p><strong>' + esc(picture(state.interest).label) + '</strong></p>' : '') + summary + '<button class="pb-action primary" type="button" disabled>Generate AI picture</button><p role="status">AI service not connected in this preview.</p><p class="pb-settings-note">Image generation is currently off. Your chosen picture board remains available.</p>';
  }
  function voiceInformation() {
    return '<p>Choose how the picture board and wish ideas sound. Selection stays quiet until you tap Preview voice.</p><fieldset class="pb-voice-options"><legend>Voice style</legend>' + voicePresets.map(preset => '<label>' + esc(preset.label) + '<input type="radio" name="voice-style" data-voice-preset value="' + preset.id + '"' + (voicePreset === preset.id ? ' checked' : '') + '></label>').join('') + '</fieldset><p data-voice-detail aria-live="polite"></p><button class="pb-action primary" type="button" data-preview-voice>Preview voice</button><button class="pb-action" type="button" data-stop-voice aria-label="Stop speaking"><i data-lucide="volume-off" aria-hidden="true"></i> Stop speaking</button><p class="pb-settings-note">Available voices vary by device. Boy and girl styles use a slightly higher pitch, not child recordings. Options may share a base voice. This preview uses available device voices and keeps your selection for this session.</p>';
  }
  function updateVoiceInformation() {
    if (!adultSettingsOpen || settingsView !== 'voices') return;
    const selection = selectedVoice();
    const detail = settingsDialog.querySelector('[data-voice-detail]');
    if (detail) detail.textContent = selection.voice
      ? 'Device voice: ' + selection.voice.name + (selection.matched ? '' : ' (available fallback)') + (selection.preset.pitch > 1 ? ' · higher pitch' : ' · natural pitch')
      : 'An English device voice is not available in this browser yet. You can still use the picture board.';
    const previewButton = settingsDialog.querySelector('[data-preview-voice]');
    if (previewButton) previewButton.disabled = !selection.voice;
  }
  if ('speechSynthesis' in window) window.speechSynthesis.addEventListener('voiceschanged', updateVoiceInformation);
  function openSettings(destination = 'options', opener = settingsButton) {
    stopSpeaking();
    settingsDestination = destination;
    dialogOpener = opener;
    showSettings('gate');
    if (!settingsDialog.open) settingsDialog.showModal();
    settingsButton.setAttribute('aria-expanded', 'true');
    dialogOpener.setAttribute('aria-expanded', 'true');
    settingsDialog.querySelector('input').focus();
  }
  function showSettings(view = 'gate', retry = false) {
    if (view !== 'gate' && !adultSettingsOpen) { showSettings('gate'); return; }
    settingsView = view;
    const close = '<button type="button" class="pb-settings-close" data-settings-close aria-label="Close settings"><i data-lucide="x" aria-hidden="true"></i></button>';
    if (view === 'gate') {
      adultSettingsOpen = false;
      const digits = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
      gateCode = Array.from({ length: 4 }, () => Math.floor(Math.random() * 10)).join('');
      settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">Ask a grown-up</h3><p>A grown-up can enter these four digits:</p><p class="pb-gate-prompt">' + [...gateCode].map(digit => digits[Number(digit)]).join(' · ') + '</p><form data-gate-form><label for="pb-gate-answer">Four-digit code</label><input id="pb-gate-answer" type="text" inputmode="numeric" pattern="[0-9]{4}" maxlength="4" autocomplete="off" required aria-describedby="pb-gate-status"><p id="pb-gate-status" role="status">' + (retry ? 'Try the new code shown above.' : '') + '</p><button class="pb-action primary" type="submit">Continue</button></form>';
      settingsDialog.querySelector('form').addEventListener('submit', event => { event.preventDefault(); if (settingsDialog.querySelector('input').value === gateCode) { gateCode = ''; adultSettingsOpen = true; showSettings(settingsDestination); } else showSettings('gate', true); });
    } else if (view === 'options') {
      settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">For grown-ups</h3><button class="pb-action" type="button" data-open-voices>Voice preference</button><button class="pb-action" type="button" data-open-ai>AI picture generation</button><button class="pb-action" type="button" data-open-privacy>Privacy &amp; Data</button><button class="pb-action" type="button" data-open-help>App information &amp; help</button><button class="pb-action" type="button" data-fresh-wish>Start a new wish</button><button class="pb-action" type="button" data-settings-done>Done</button>';
    } else if (view === 'voices') {
      settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">Voice preference</h3>' + voiceInformation() + '<button class="pb-action" type="button" data-settings-back>Back to settings</button><button class="pb-action" type="button" data-settings-done>Done</button>';
    } else if (view === 'privacy') {
      settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">Privacy &amp; Data</h3><label>Read choice labels aloud<input type="checkbox" data-narration ' + (readChoicesAloud ? 'checked' : '') + '></label><p class="pb-settings-note">This preference lasts until the preview page is reloaded or closed. Talking-board pictures and Read my wish still speak when tapped.</p><button class="pb-action pb-danger" type="button" data-fresh-wish>Start a new wish</button><p class="pb-settings-clear-status" role="status"></p>' + privacyInformation() + '<button class="pb-action" type="button" data-settings-back>Back to settings</button><button class="pb-action" type="button" data-settings-done>Done</button>';
    } else if (view === 'ai') {
      settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">AI picture generation</h3>' + aiPictureInformation() + '<button class="pb-action" type="button" data-settings-back>Back to settings</button><button class="pb-action" type="button" data-settings-done>Done</button>';
    } else if (view === 'help') {
      settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">App information &amp; help</h3>' + appInformation() + '<button class="pb-action" type="button" data-settings-back>Back to settings</button><button class="pb-action" type="button" data-settings-done>Done</button>';
    } else settingsDialog.innerHTML = close + '<h3 id="pb-settings-title">Start a new wish?</h3><p>This clears the current journey choices and talking-board sentence. The read-aloud preference stays as you set it for this preview session.</p><button class="pb-action pb-danger" type="button" data-confirm-fresh>Start a new wish</button><button class="pb-action" type="button" data-keep-choices>Keep my choices</button>';
    iconize();
    updateVoiceInformation();
    settingsDialog.scrollTop = 0;
    if (settingsDialog.open) settingsDialog.querySelector(view === 'gate' ? 'input' : '[data-settings-close]').focus();
  }
  settingsButton.addEventListener('click', () => openSettings());
  settingsDialog.addEventListener('close', () => { stopSpeaking(); gateCode = ''; adultSettingsOpen = false; settingsView = 'gate'; settingsDestination = 'options'; settingsDialog.innerHTML = ''; settingsButton.setAttribute('aria-expanded', 'false'); dialogOpener.setAttribute('aria-expanded', 'false'); (dialogOpener.isConnected ? dialogOpener : settingsButton).focus(); });
  settingsDialog.addEventListener('change', event => {
    if (!adultSettingsOpen) return;
    if (event.target.hasAttribute('data-narration')) readChoicesAloud = event.target.checked;
    if (event.target.hasAttribute('data-voice-preset') && voicePresets.some(item => item.id === event.target.value)) {
      stopSpeaking(); voicePreset = event.target.value; updateVoiceInformation();
    }
  });
  settingsDialog.addEventListener('click', event => {
    const button = event.target.closest('button'); if (!button) return;
    if (button.hasAttribute('data-settings-close') || button.hasAttribute('data-settings-done')) settingsDialog.close();
    else if (button.hasAttribute('data-open-voices')) showSettings('voices');
    else if (button.hasAttribute('data-preview-voice') && adultSettingsOpen) speak('Hello! This is my voice. I can tell you what I like.');
    else if (button.hasAttribute('data-stop-voice')) stopSpeaking();
    else if (button.hasAttribute('data-open-ai')) showSettings('ai');
    else if (button.hasAttribute('data-open-privacy')) showSettings('privacy');
    else if (button.hasAttribute('data-open-help')) showSettings('help');
    else if (button.hasAttribute('data-settings-back')) showSettings('options');
    else if (button.hasAttribute('data-fresh-wish')) { resetReturnView = settingsView; showSettings('confirm'); }
    else if (button.hasAttribute('data-keep-choices')) showSettings(resetReturnView);
    else if (button.hasAttribute('data-confirm-fresh') && adultSettingsOpen) { freshWish(); settingsDialog.close(); status.textContent = 'A new wish is ready. Your previous journey choices and words were cleared.'; }
  });
  root.addEventListener('click', event => {
    if (event.target.closest('#pb-settings-dialog') || event.target.closest('.pb-settings') || event.target.closest('.pb-handle')) return;
    const button = event.target.closest('button'); if (!button) return;
    if (button.hasAttribute('data-stop-speaking')) { stopSpeaking(); return; }
    if (button.hasAttribute('data-read-wish')) { speak(wishSummary()); return; }
    if (button.hasAttribute('data-speak')) { speak(state.phrase.join(' ')); return; }
    if (button.hasAttribute('data-ai-picture')) { openSettings('ai', button); return; }
    let resetScroll = false, focus = null, narration = '';
    if (button === homeButton || button.hasAttribute('data-home')) {
      state.view = 'home'; state.stage = 0; state.pause = false;
      stopSpeaking(); snapDrawer(false); resetScroll = true;
    } else if (button.hasAttribute('data-back')) {
      if (state.view === 'favorites-intake') state.view = 'home';
      else if (state.view === 'postcard') { state.view = 'journey'; state.stage = lastJourneyStage; }
      else if (state.stage > 0) state.stage -= 1;
      else state.view = 'home';
      resetScroll = true; stopSpeaking();
    } else if (button.hasAttribute('data-open-intake')) {
      state.view = 'favorites-intake'; resetScroll = true;
    } else if (button.hasAttribute('data-complete-intake')) {
      state.view = 'home'; resetScroll = true; status.textContent = 'Favorites saved for this preview session.';
    } else if (button.dataset.interest) {
      const id = button.dataset.interest;
      if (state.interest !== id) Object.assign(state, { interest: id, actionIds: [], settingId: null, essentialId: null });
      state.view = 'journey'; state.stage = 0; resetScroll = true; narration = picture(id).label;
    } else if (button.dataset.action) {
      const id = button.dataset.action;
      if (state.actionIds.includes(id)) state.actionIds = state.actionIds.filter(value => value !== id);
      else if (state.actionIds.length < 3) state.actionIds.push(id);
      else { status.textContent = 'Choose up to three actions, or remove one first.'; speak(status.textContent); return; }
      narration = choice(id).label; focus = '[data-action="' + id + '"]';
    } else if (button.dataset.setting) {
      const id = button.dataset.setting;
      state.settingId = state.settingId === id ? null : id; narration = choice(id).label; focus = '[data-setting="' + id + '"]';
    } else if (button.dataset.favorite) {
      const id = button.dataset.favorite;
      if (state.favoriteIds.includes(id)) state.favoriteIds = state.favoriteIds.filter(value => value !== id);
      else if (state.favoriteIds.length < 10) state.favoriteIds.push(id);
      else { status.textContent = 'Choose up to ten favorites, or remove one first.'; speak(status.textContent); return; }
      narration = choice(id).label; focus = '[data-favorite="' + id + '"]';
    } else if (button.dataset.essential) {
      const id = button.dataset.essential;
      state.essentialId = state.essentialId === id ? null : id; narration = choice(id).label; focus = '[data-essential="' + id + '"]';
    } else if (button.hasAttribute('data-next')) {
      if (state.stage < lastJourneyStage) state.stage += 1; else state.view = 'postcard';
      resetScroll = true;
    } else if (button.dataset.word) {
      const item = picture(button.dataset.word);
      state.phrase = [...state.phrase, item.speech ?? item.label].slice(-18);
      speak(item.speech ?? item.label);
      if (['stop', 'break'].includes(item.id)) { state.pause = true; snapDrawer(false); resetScroll = true; }
      else if (item.id === 'finished') { state.view = 'home'; state.pause = false; state.phrase = []; snapDrawer(false); resetScroll = true; }
    } else if (button.hasAttribute('data-finish')) {
      state.view = 'home'; state.pause = false; state.phrase = []; snapDrawer(false); resetScroll = true;
    } else if (button.hasAttribute('data-resume')) { state.pause = false; resetScroll = true; }
    else if (button.hasAttribute('data-change')) { state.view = 'journey'; state.stage = 0; resetScroll = true; }
    else if (button.hasAttribute('data-clear')) state.phrase = [];
    else if (button.hasAttribute('data-erase')) state.phrase.pop();
    sanitizeEssential();
    if (readChoicesAloud && narration) speak(narration);
    render({ resetScroll, focus });
    if (button.hasAttribute('data-back') || button === homeButton || button.hasAttribute('data-home')) animateBackPage();
  });
  document.addEventListener('visibilitychange', () => { if (document.hidden) { cancelPageMotion(); stopSpeaking(); if (settingsDialog.open) settingsDialog.close(); } });
  window.addEventListener('pagehide', () => { cancelPageMotion(); stopSpeaking(); });
  window.addEventListener('blur', stopSpeaking);
  root.querySelector('.pb-core-grid').innerHTML = coreRows.flat().map(id => pictureTile(picture(id), 'word')).join('');
  root.querySelector('.pb-phrase-grid').innerHTML = phraseIDs.map(id => pictureTile(picture(id), 'word')).join('');
  panel.hidden = false;
  render(); measureDrawer();
  document.fonts?.ready.then(fitSymbols);
  new ResizeObserver(() => { measureDrawer(); fitSymbols(); }).observe(app);
  const opening = root.querySelector('.pb-opening');
  app.inert = true;
  setTimeout(() => {
    if (reduceMotion.matches) {
      opening.remove();
      app.inert = false;
      return;
    }
    opening.classList.add('pb-opening-fade');
    setTimeout(() => { opening.remove(); app.inert = false; }, 400);
  }, 800);
})();
