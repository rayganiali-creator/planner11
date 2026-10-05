'use strict';
// ===== پروژه‌ی نمونه (دموی آماده): ۲ کاراکتر، چندین خانواده‌ی Asset با Variant رنگی، ۷ Mood، ۶ پس‌زمینه =====
// فضای مختصاتِ قطعه‌ها «فضای کاراکتر» است: مبدأ = وسطِ پاهای کاراکتر؛ y منفی = بالا. هندسه‌ی پیش‌فرضِ خانواده (x=48,y=134) آن را روی صحنه می‌گذارد.

function A(w, h) { return { w, h, px: new Uint8Array(w * h) }; }
function sp(a, x, y, s) { if (x >= 0 && y >= 0 && x < a.w && y < a.h) a.px[y * a.w + x] = s; }
function rf(a, x, y, w, h, s) { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) sp(a, x + i, y + j, s); }
/** جعبه با خط دور (slot اول=outline)، پرکننده، سایه‌ی راست/پایین؛ round = گوشه‌های گرد */
function sbox(w, h, fill, shade, outline, round) {
  const a = A(w, h);
  rf(a, 0, 0, w, h, outline);
  rf(a, 1, 1, w - 2, h - 2, fill);
  if (shade) { rf(a, w - 3, 1, 2, h - 2, shade); rf(a, 1, h - 3, w - 2, 2, shade); }
  if (round) for (const [x, y] of [[0, 0], [w - 1, 0], [0, h - 1], [w - 1, h - 1]]) sp(a, x, y, 0);
  return a;
}
function addPart(f, name, a, dx, dy) { const p = newPart(name, a.w, a.h, dx, dy); p.px = a.px; f.parts.push(p); return p; }
function dk(hex, k) { const [r, g, b] = hexToRgb(hex); const m = c => clamp(Math.round(c * k), 0, 255); return '#' + [m(r), m(g), m(b)].map(v => v.toString(16).padStart(2, '0')).join(''); }
function lt(hex, k) { const [r, g, b] = hexToRgb(hex); const m = c => clamp(Math.round(c + (255 - c) * k), 0, 255); return '#' + [m(r), m(g), m(b)].map(v => v.toString(16).padStart(2, '0')).join(''); }
function slots(...defs) { return defs.map(([name, color], i) => ({ id: 's' + (i + 1), name, color })); }
function setVariants(f, list) {
  f.variants = list.map(([name, cols]) => ({ id: newId('var'), name, colors: Object.fromEntries(Object.entries(cols).map(([k, v]) => [k, v])), overrides: {} }));
}

function seedProject() {
  const p = emptyProject('Demo — Avatar Studio');
  P = p; // ابزارهای newFamily به P نیاز ندارند؛ فقط برای سازگاری
  const hero = { id: newId('char'), name: 'Character 01 — Hero', notes: '' };
  const heroine = { id: newId('char'), name: 'Character 02 — Heroine', notes: '' };
  p.characters.push(hero, heroine);
  const fams = p.families;
  const mk = (name, cat, sl, charIds = []) => { const f = newFamily(name, cat, sl); f.characterIds = charIds; fams.push(f); return f; };

  // ---- بدن
  const skinSlots = slots(['skin', '#e9b48f'], ['shade', '#c98c68'], ['outline', '#3a2a24']);
  const skins = [['Light', { s1: '#f0c4a0', s2: '#d49a78', s3: '#3a2a24' }], ['Tan', { s1: '#d9a070', s2: '#b97f52', s3: '#3a2a24' }], ['Brown', { s1: '#a8683f', s2: '#85492a', s3: '#2e1d16' }], ['Dark', { s1: '#6e432b', s2: '#52301d', s3: '#22140e' }]];
  const body = (name, charId, headW) => {
    const f = mk(name, 'body', skinSlots.map(s => ({ ...s })), [charId]);
    addPart(f, 'legL', sbox(9, 30, 1 + 0, 0, 3), -10, -30);
    f.parts[0].px = (() => { const a = sbox(9, 30, 1, 2, 3); return a.px; })();
    addPart(f, 'legR', sbox(9, 30, 1, 2, 3), 1, -30);
    addPart(f, 'torso', sbox(26, 30, 1, 2, 3), -13, -60);
    addPart(f, 'armL', sbox(7, 28, 1, 2, 3, true), -20, -59);
    addPart(f, 'armR', sbox(7, 28, 1, 2, 3, true), 13, -59);
    addPart(f, 'neck', sbox(6, 4, 1, 2, 3), -3, -64);
    const head = sbox(headW, 22, 1, 2, 3, true);
    rf(head, 0, 9, 1, 5, 3); // گوش‌ها
    addPart(f, 'head', head, -Math.floor(headW / 2), -86);
    setVariants(f, skins);
    return f;
  };
  const bodyHero = body('Body — Hero', hero.id, 22);
  const bodyHeroine = body('Body — Heroine', heroine.id, 22);

  // ---- چشم / ابرو
  const eyes = mk('Eyes — Basic', 'eyes', slots(['iris', '#3a2a1a'], ['white', '#ffffff'], ['lash', '#1a1410']));
  for (const [nm, dx] of [['eyeL', -7], ['eyeR', 3]]) { const a = A(4, 4); rf(a, 0, 0, 4, 4, 2); rf(a, 1, 1, 2, 3, 1); sp(a, 1, 1, 3); addPart(eyes, nm, a, dx, -77); }
  setVariants(eyes, [['Brown', { s1: '#5a3a22' }], ['Blue', { s1: '#3b73d6' }], ['Green', { s1: '#3a9a5a' }], ['Gray', { s1: '#7a8696' }]]);
  const brows = mk('Eyebrows — Basic', 'eyebrows', slots(['brow', '#2a1a10']));
  for (const [nm, dx] of [['browL', -8], ['browR', 3]]) { const a = A(5, 1); rf(a, 0, 0, 5, 1, 1); addPart(brows, nm, a, dx, -81); }
  setVariants(brows, [['Dark', { s1: '#2a1a10' }], ['Brown', { s1: '#6b4426' }], ['Blond', { s1: '#c9a050' }], ['Gray', { s1: '#8a8a8a' }]]);

  // ---- دهان‌ها (Mood)
  const mouthDefs = {
    neutral: ['  XXXX  '.trim()],
  };
  const mouthPix = {
    neutral: ['.......', '.XXXXX.', '.......'],
    happy: ['X.....X', '.XXXXX.', '.......'],
    sad: ['.......', '.XXXXX.', 'X.....X'],
    angry: ['.......', 'XXXXXXX', '.X...X.'],
    surprised: ['..XXX..', '.X...X.', '..XXX..'],
    tired: ['.......', '.X.X.X.', '..X.X..'],
    excited: ['X.....X', 'XYYYYYX', '.XXXXX.'],
  };
  const mouthFam = {};
  for (const [m, rows] of Object.entries(mouthPix)) {
    const f = mk('Mouth — ' + m, 'mouth', slots(['lip', '#b04a4a'], ['teeth', '#ffffff']));
    const a = A(7, 3);
    rows.forEach((r, y) => [...r].forEach((c, x) => { if (c === 'X') sp(a, x, y, 1); if (c === 'Y') sp(a, x, y, 2); }));
    addPart(f, 'mouth', a, -3, -71);
    setVariants(f, [['Natural', { s1: '#b04a4a' }], ['Dark', { s1: '#7a2c34' }], ['Pink', { s1: '#d86a8a' }]]);
    mouthFam[m] = f;
    p.moods[m] = { familyId: f.id, variantId: f.variants[0].id };
  }

  // ---- مو
  const hairSlots = slots(['hair', '#3b2a20'], ['shade', '#2a1d16'], ['outline', '#140e0a']);
  const hairVars = [['Black', { s1: '#26211e', s2: '#15110f', s3: '#0a0807' }], ['Brown', { s1: '#6b4426', s2: '#4a2e18', s3: '#22150b' }], ['Blond', { s1: '#d9b45a', s2: '#b08a3a', s3: '#5a4519' }], ['Red', { s1: '#b4442a', s2: '#862e1a', s3: '#3a1209' }], ['Blue', { s1: '#3b5fd6', s2: '#2a45a0', s3: '#121f4a' }]];
  const hs = mk('Hair — Short', 'hair', hairSlots.map(s => ({ ...s })), [hero.id]);
  { const a = sbox(26, 12, 1, 2, 3, true); rf(a, 6, 9, 14, 3, 0); rf(a, 8, 9, 4, 3, 1); addPart(hs, 'cap', a, -13, -92); const s1 = sbox(3, 10, 1, 2, 3); addPart(hs, 'sideL', s1, -13, -82); addPart(hs, 'sideR', sbox(3, 10, 1, 2, 3), 10, -82); }
  setVariants(hs, hairVars);
  const hl = mk('Hair — Long', 'hair', hairSlots.map(s => ({ ...s })), [heroine.id]);
  { const back = sbox(30, 36, 1, 2, 3, true); rf(back, 5, 10, 20, 26, 0); addPart(hl, 'back', back, -15, -92); const fr = sbox(26, 10, 1, 2, 3, true); rf(fr, 5, 7, 16, 3, 0); addPart(hl, 'fringe', fr, -13, -92); }
  setVariants(hl, hairVars);

  // ---- کلاه / روسری / کلاه‌خود
  const cap = mk('Hat — Cap', 'hat', slots(['main', '#c0392b'], ['shade', '#8c2a20'], ['outline', '#2a0f0b']));
  addPart(cap, 'crown', sbox(24, 9, 1, 2, 3, true), -12, -96); addPart(cap, 'brim', sbox(28, 3, 2, 2, 3), -14, -88);
  setVariants(cap, [['Red', {}], ['Blue', { s1: '#2e63c9', s2: '#204a98', s3: '#0e1f44' }], ['Green', { s1: '#2e9a5a', s2: '#206f40', s3: '#0e2f1c' }], ['Black', { s1: '#34363c', s2: '#202226', s3: '#0a0b0d' }]]);
  cap.geometry[heroine.id] = { y: 134 };
  const hij = mk('Hijab — Wrap', 'hijab', slots(['cloth', '#222a3a'], ['fold', '#161c28'], ['outline', '#080b11']), [heroine.id]);
  { const a = sbox(32, 38, 1, 2, 3, true); rf(a, 7, 9, 18, 14, 0); addPart(hij, 'wrap', a, -16, -94); addPart(hij, 'drape', sbox(30, 8, 1, 2, 3), -15, -58); }
  setVariants(hij, [['Black', {}], ['White', { s1: '#f2f2ee', s2: '#cfcfc8', s3: '#6a6a66' }], ['Navy', { s1: '#26467a', s2: '#1a3256', s3: '#0a1730' }], ['Rose', { s1: '#c06a86', s2: '#94485f', s3: '#3d1a26' }]]);
  const helm = mk('Helmet — Knight', 'helmet', slots(['metal', '#b9c1cc'], ['shade', '#808a98'], ['outline', '#22262e'], ['plume', '#c0392b']));
  { addPart(helm, 'dome', sbox(28, 18, 1, 2, 3, true), -14, -98); const v = sbox(20, 5, 3, 3, 3); addPart(helm, 'visor', v, -10, -84); addPart(helm, 'plume', sbox(4, 10, 4, 4, 3), -2, -108); }
  setVariants(helm, [['Silver', {}], ['Gold', { s1: '#e3bf52', s2: '#b08a22', s3: '#3d2f08' }], ['Iron', { s1: '#6c7480', s2: '#464d58', s3: '#14161a' }]]);

  // ---- لباس‌ها
  const shirt = mk('Shirt — Basic', 'shirt', slots(['main', '#c0392b'], ['shade', '#8c2a20'], ['trim', '#f2e2c2'], ['outline', '#2a0f0b']));
  { addPart(shirt, 'body', sbox(26, 27, 1, 2, 4), -13, -60); addPart(shirt, 'sleeveL', sbox(8, 13, 1, 2, 4), -21, -60); addPart(shirt, 'sleeveR', sbox(8, 13, 1, 2, 4), 13, -60); const c = A(10, 3); rf(c, 0, 0, 10, 3, 3); addPart(shirt, 'collar', c, -5, -61); const b = A(1, 14); for (let y = 0; y < 14; y += 3) sp(b, 0, y, 3); addPart(shirt, 'buttons', b, 0, -57); }
  const shirtCols = [['Red', '#c0392b', '#f2e2c2'], ['Blue', '#2e63c9', '#f2e2c2'], ['Green', '#2e9a5a', '#f2e2c2'], ['Black', '#34363c', '#d0b050'], ['White', '#eeeeea', '#4a6acb']];
  setVariants(shirt, shirtCols.map(([n, m, t]) => [n, { s1: m, s2: dk(m, 0.72), s3: t, s4: dk(m, 0.3) }]));
  const pants = mk('Pants — Basic', 'pants', slots(['main', '#2e4a8a'], ['shade', '#203566'], ['outline', '#0e1630']));
  { addPart(pants, 'waist', sbox(26, 6, 1, 2, 3), -13, -36); addPart(pants, 'legL', sbox(9, 24, 1, 2, 3), -10, -30); addPart(pants, 'legR', sbox(9, 24, 1, 2, 3), 1, -30); }
  setVariants(pants, [['Blue', {}], ['Black', { s1: '#34363c', s2: '#202226', s3: '#0a0b0d' }], ['Khaki', { s1: '#b09a6a', s2: '#8a7648', s3: '#3d3319' }], ['Gray', { s1: '#7a8088', s2: '#565b62', s3: '#1a1c1f' }]]);
  const shoes = mk('Shoes — Basic', 'shoes', slots(['main', '#3a2a24'], ['sole', '#d8d2c4'], ['outline', '#120c0a']));
  for (const [nm, dx] of [['shoeL', -11], ['shoeR', 1]]) { const a = sbox(10, 6, 1, 0, 3, true); rf(a, 1, 4, 8, 1, 2); addPart(shoes, nm, a, dx, -6); }
  setVariants(shoes, [['Brown', {}], ['Black', { s1: '#26272c', s2: '#d8d2c4', s3: '#08080a' }], ['White', { s1: '#f0f0ee', s2: '#9a9a96', s3: '#3a3a38' }], ['Red', { s1: '#c0392b', s2: '#e8dccd', s3: '#2a0f0b' }]]);
  const armor = mk('Armor — Plate', 'armor', slots(['metal', '#b9c1cc'], ['shade', '#808a98'], ['trim', '#d8b04a'], ['outline', '#22262e']));
  { addPart(armor, 'chest', sbox(26, 24, 1, 2, 4), -13, -60); addPart(armor, 'pauldronL', sbox(9, 7, 1, 2, 4, true), -22, -62); addPart(armor, 'pauldronR', sbox(9, 7, 1, 2, 4, true), 13, -62); const t = A(26, 2); rf(t, 0, 0, 26, 2, 3); addPart(armor, 'belt', t, -13, -38); }
  setVariants(armor, [['Steel', {}], ['Bronze', { s1: '#c98a4a', s2: '#94602a', s3: '#e8d070', s4: '#3a2210' }], ['Dark', { s1: '#5a606c', s2: '#3a3f48', s3: '#9a7ad0', s4: '#0e1014' }]]);
  const scarf = mk('Scarf', 'accessory', slots(['main', '#d8a030'], ['shade', '#a87818'], ['outline', '#3a2808']));
  { addPart(scarf, 'wrap', sbox(14, 5, 1, 2, 3), -7, -67); addPart(scarf, 'tail', sbox(5, 11, 1, 2, 3), 2, -63); }
  setVariants(scarf, [['Yellow', {}], ['Red', { s1: '#c0392b', s2: '#8c2a20', s3: '#2a0f0b' }], ['Teal', { s1: '#2a9a96', s2: '#1c6e6a', s3: '#0a2c2a' }]]);

  // ---- سلاح‌ها (مبدأ = دست)
  const sword = mk('Sword — Long', 'sword', slots(['blade', '#c9d2dc'], ['edge', '#8b97a6'], ['hilt', '#6b4426'], ['guard', '#d8b04a']));
  { const bl = A(3, 26); rf(bl, 0, 0, 3, 26, 1); rf(bl, 2, 0, 1, 26, 2); rf(bl, 1, 0, 1, 1, 1); addPart(sword, 'blade', bl, -1, -32); addPart(sword, 'guard', sbox(9, 2, 4, 4, 4), -4, -6); addPart(sword, 'hilt', sbox(3, 7, 3, 3, 3), -1, -4); }
  sword.geometry['*'] = newGeometry(65, 104);
  setVariants(sword, [['Steel', {}], ['Gold', { s1: '#f0d060', s2: '#b08a22', s3: '#6b4426', s4: '#f8e8a0' }], ['Ice', { s1: '#b8e4f8', s2: '#6ab0d8', s3: '#3a5a78', s4: '#e0f4ff' }]]);
  const shield = mk('Shield — Round', 'shield', slots(['face', '#8a5a30'], ['rim', '#c9d2dc'], ['boss', '#d8b04a'], ['outline', '#22262e']));
  { const a = sbox(18, 18, 1, 0, 4, true); rf(a, 0, 0, 18, 1, 2); rf(a, 0, 17, 18, 1, 2); rf(a, 0, 0, 1, 18, 2); rf(a, 17, 0, 1, 18, 2); rf(a, 7, 7, 4, 4, 3); addPart(shield, 'disc', a, -9, -9); }
  shield.geometry['*'] = newGeometry(30, 104);
  setVariants(shield, [['Wood', {}], ['Steel', { s1: '#8a97a6', s2: '#c9d2dc', s3: '#d8b04a', s4: '#22262e' }], ['Royal', { s1: '#2e63c9', s2: '#d8b04a', s3: '#f2e2c2', s4: '#0e1f44' }]]);

  // ---- حیوان همراه
  const cat = mk('Pet — Cat', 'pet', slots(['fur', '#d98a3a'], ['dark', '#a8601c'], ['outline', '#2a170a'], ['eye', '#3a9a5a']));
  { addPart(cat, 'tail', sbox(3, 12, 1, 2, 3), 9, -16); addPart(cat, 'body', sbox(18, 10, 1, 2, 3, true), -9, -10); const hd = sbox(11, 9, 1, 2, 3, true); sp(hd, 3, 3, 4); sp(hd, 7, 3, 4); addPart(cat, 'head', hd, -14, -17); addPart(cat, 'earL', sbox(3, 3, 2, 2, 3), -14, -20); addPart(cat, 'earR', sbox(3, 3, 2, 2, 3), -6, -20); }
  cat.geometry['*'] = newGeometry(80, 134);
  setVariants(cat, [['Orange', {}], ['Gray', { s1: '#9a9ea6', s2: '#6a6e76', s3: '#1a1c20' }], ['Black', { s1: '#34363c', s2: '#202226', s3: '#08080a' }]]);
  const shadowF = mk('Shadow — Blob', 'shadow', slots(['shadow', '#000000']));
  { const a = A(34, 8); for (let y = 0; y < 8; y++) for (let x = 0; x < 34; x++) { const dx = (x - 16.5) / 17, dy = (y - 3.5) / 4; if (dx * dx + dy * dy <= 1) sp(a, x, y, 1); } addPart(shadowF, 'blob', a, -17, -4); }
  shadowF.geometry['*'] = newGeometry(48, 134);
  const spark = mk('Effect — Sparkle', 'effect', slots(['spark', '#ffe9a0']));
  { for (const [dx, dy] of [[-30, -90], [28, -80], [-26, -40], [32, -20]]) { const a = A(5, 5); rf(a, 2, 0, 1, 5, 1); rf(a, 0, 2, 5, 1, 1); addPart(spark, 'sp' + dx, a, dx, dy); } }
  setVariants(spark, [['Gold', {}], ['Cyan', { s1: '#a0f0ff' }], ['Pink', { s1: '#ffa0d8' }]]);

  // ---- پس‌زمینه‌ها
  const bgs = p.backgrounds;
  bgs.push({ id: newId('bg'), name: 'Night Blue', type: 'solid', color: '#1b2238', color2: '#000000', angle: 0, pattern: { kind: 'dots', color: '#ffffff', size: 10, opacity: 0.08 }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0.45, scanlines: 0, noise: 0 } });
  bgs.push({ id: newId('bg'), name: 'Sunset', type: 'gradient', color: '#ffb36b', color2: '#7a3a8a', angle: 0, pattern: { kind: 'none' }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0.2, scanlines: 0, noise: 0.2 } });
  bgs.push({ id: newId('bg'), name: 'Forest', type: 'gradient', color: '#a7d8a0', color2: '#2f6a46', angle: 0, pattern: { kind: 'stripes', color: '#ffffff', size: 12, opacity: 0.05 }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0.25, scanlines: 0, noise: 0 } });
  bgs.push({ id: newId('bg'), name: 'Checker', type: 'solid', color: '#cfd6e4', color2: '#000', angle: 0, pattern: { kind: 'checker', color: '#aab4c8', size: 8, opacity: 0.6 }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0, scanlines: 0, noise: 0 } });
  bgs.push({ id: newId('bg'), name: 'Retro Grid', type: 'gradient', color: '#14102a', color2: '#4a1e78', angle: 0, pattern: { kind: 'grid', color: '#ff5fd0', size: 12, opacity: 0.18 }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0.3, scanlines: 0.25, noise: 0 } });
  bgs.push({ id: newId('bg'), name: 'Soft Gray', type: 'gradient', color: '#e8eaf0', color2: '#b8bdca', angle: 0, pattern: { kind: 'none' }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0.1, scanlines: 0, noise: 0 } });

  // ---- صحنه‌ی پیش‌فرض
  const eq = (cat2, fam, vi = 0) => { p.scene.equipped['L_' + cat2] = { familyId: fam.id, variantId: fam.variants[vi].id }; };
  p.scene.characterId = hero.id;
  p.scene.backgroundId = bgs[0].id;
  eq('body', bodyHero); eq('shoes', shoes); eq('pants', pants); eq('shirt', shirt); eq('eyes', eyes); eq('eyebrows', brows); eq('mouth', mouthFam.neutral); eq('hair', hs, 1); eq('sword', sword); eq('shield', shield);
  p.scene.shadow = { on: true, color: '#000000', opacity: 0.35, w: 34, h: 8, x: 48, y: 134 };
  p.view.zoom = 4;
  return p;
}
