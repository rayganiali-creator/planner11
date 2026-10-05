'use strict';
// ===== اتاق (چوب + پنجره)، خرید و چیدمان آیتم‌ها، حیوانِ خانگی =====
const W = 384, H = 224, FLOOR = 140;
const $ = (s, r = document) => r.querySelector(s);
const h = (tag, a, ...kids) => { const e = document.createElement(tag); for (const [k, v] of Object.entries(a || {})) { if (v == null || v === false) continue; if (k === 'class') e.className = v; else if (k === 'style') Object.assign(e.style, v); else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else if (k === 'disabled') e.disabled = !!v; else e.setAttribute(k, v); } for (const c of kids.flat(Infinity)) if (c != null && c !== false) e.append(c.nodeType ? c : document.createTextNode(c)); return e; };
function setKids(el, kids) { while (el.firstChild) el.removeChild(el.firstChild); for (const k of [].concat(kids).flat(Infinity)) if (k != null && k !== false) el.append(k.nodeType ? k : document.createTextNode(k)); }
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

// ---- ذخیره‌ی امن (در پیش‌نمایش‌های محدود localStorage ممنوع است)
const MEM = {};
const store = {
  get() { try { return JSON.parse(localStorage.getItem('room-proto') || MEM.v || 'null'); } catch (e) { return MEM.v ? JSON.parse(MEM.v) : null; } },
  set(o) { const s = JSON.stringify(o); try { localStorage.setItem('room-proto', s); } catch (e) { MEM.v = s; } },
};
let S = { coins: 2000, owned: {}, placed: [], pet: null, uid: 1, tab: 'plant', sel: null, night: 'auto', wall: 0 };
function save() { const { sel, ...r } = S; store.set(r); }
function load() { const o = store.get(); if (o) S = Object.assign(S, o, { sel: null }); if (S.pet) S.pet.pet = true; }

// ---- اتاق: دیوار و کف چوبی + پنجره
const WIN = { x: 40, y: 26, w: 76, h: 62 };
function hourNow() { const d = new Date(); return d.getHours() + d.getMinutes() / 60; }
function isNight() { return S.night === 'auto' ? (hourNow() < 6 || hourNow() >= 19) : S.night === 'night'; }
function rr(seed) { let s = seed; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }
function drawOutside(g, x, y, w, hh) {
  const night = isNight(), t = hourNow();
  const dusk = !night && (t < 7.5 || t >= 17);
  const top = night ? '#0f1738' : dusk ? '#f4a36b' : '#6fc3ff', bot = night ? '#25306a' : dusk ? '#ffd9a0' : '#cdeeff';
  for (let j = 0; j < hh; j++) { g.fillStyle = (() => { const k = j / hh; const a = rgb(top), b = rgb(bot); return hx(a.map((v, i) => v + (b[i] - v) * k)); })(); g.fillRect(x, y + j, w, 1); }
  const R = rr(7);
  if (night) { for (let i = 0; i < 22; i++) { g.fillStyle = i % 4 ? '#ffffff' : '#ffe9a0'; g.fillRect(x + (R() * w | 0), y + (R() * hh * 0.6 | 0), 1, 1); } g.fillStyle = '#fff6c8'; g.beginPath(); g.arc(x + w - 18, y + 14, 7, 0, 7); g.fill(); g.fillStyle = '#0f1738'; g.beginPath(); g.arc(x + w - 15, y + 12, 6, 0, 7); g.fill(); }
  else { const sx = x + 8 + clamp((t - 6) / 13, 0, 1) * (w - 24), sy = y + 24 - Math.sin(clamp((t - 6) / 13, 0, 1) * Math.PI) * 18; g.fillStyle = '#fff3a0'; g.beginPath(); g.arc(sx, sy, 7, 0, 7); g.fill(); g.fillStyle = '#ffd23a'; g.beginPath(); g.arc(sx, sy, 5, 0, 7); g.fill(); for (const [cx, cy] of [[x + 14, y + 12], [x + w - 28, y + 22]]) { g.fillStyle = '#ffffff'; g.fillRect(cx, cy, 14, 3); g.fillRect(cx + 3, cy - 2, 8, 3); g.fillRect(cx - 2, cy + 2, 18, 2); } }
  g.fillStyle = night ? '#1a2a4a' : '#7fae8a'; for (let i = 0; i < w; i++) g.fillRect(x + i, y + hh - 22 - Math.round(Math.sin(i / 9 + 1) * 5), 1, 22);
  g.fillStyle = night ? '#162a3a' : '#58a868'; for (let i = 0; i < w; i++) g.fillRect(x + i, y + hh - 12 - Math.round(Math.sin(i / 6) * 2), 1, 12);
  g.fillStyle = night ? '#2a1f2a' : '#7a4a2a'; g.fillRect(x + 20, y + hh - 26, 3, 14); g.fillStyle = night ? '#1f4a3a' : '#2f9a55'; for (const [cx, cy, r] of [[x + 21, y + hh - 30, 8], [x + 15, y + hh - 26, 6], [x + 27, y + hh - 26, 6]]) { g.beginPath(); g.arc(cx, cy, r, 0, 7); g.fill(); }
  g.fillStyle = night ? '#ffd27a' : '#e85a5a'; g.fillRect(x + w - 24, y + hh - 22, 14, 10); g.fillStyle = night ? '#3a2a3a' : '#7a3a3a'; g.fillRect(x + w - 26, y + hh - 26, 18, 4); g.fillStyle = '#fff'; g.fillRect(x + w - 20, y + hh - 18, 3, 4);
}
let roomCache = null, roomKey = '';
function roomCanvas() {
  const key = isNight() + '|' + Math.floor(hourNow() * 2);
  if (roomCache && roomKey === key) return roomCache;
  roomKey = key;
  const c = roomCache || (roomCache = document.createElement('canvas')); c.width = W; c.height = H;
  const g = c.getContext('2d'); g.imageSmoothingEnabled = false;
  // دیوارِ تخته‌ای چوبی
  const R = rr(3), wallCols = ['#a9743f', '#b27c45', '#a06c3a', '#ad7742'];
  for (let i = 0; i * 12 < W; i++) { const col = wallCols[i % 4]; g.fillStyle = col; g.fillRect(i * 12, 0, 12, FLOOR); g.fillStyle = dk(col, 0.35); g.fillRect(i * 12, 0, 1, FLOOR); g.fillStyle = lt(col, 0.12); g.fillRect(i * 12 + 1, 0, 1, FLOOR); for (let k = 0; k < 9; k++) { g.fillStyle = dk(col, 0.14); g.fillRect(i * 12 + 3 + (R() * 7 | 0), (R() * FLOOR) | 0, 1, 2 + (R() * 5 | 0)); } }
  g.fillStyle = '#7a4a24'; g.fillRect(0, 0, W, 5); g.fillStyle = '#946034'; g.fillRect(0, 5, W, 1);
  g.fillStyle = '#6b4423'; g.fillRect(0, FLOOR - 9, W, 9); g.fillStyle = '#8a5a30'; g.fillRect(0, FLOOR - 9, W, 2); g.fillStyle = '#4a2c14'; g.fillRect(0, FLOOR - 1, W, 1);
  // کفِ چوبی
  const fc = ['#c48a52', '#cc9459', '#bc8049', '#c68e55'];
  for (let j = 0, row = 0; FLOOR + j < H; j += 10, row++) { const y = FLOOR + j; for (let x = -(row % 2) * 24, i = 0; x < W; x += 48, i++) { const col = fc[(i + row) % 4]; g.fillStyle = col; g.fillRect(x, y, 48, 10); g.fillStyle = lt(col, 0.14); g.fillRect(x, y, 48, 1); g.fillStyle = dk(col, 0.3); g.fillRect(x, y + 9, 48, 1); g.fillRect(x, y, 1, 10); for (let k = 0; k < 5; k++) { g.fillStyle = dk(col, 0.12); g.fillRect(x + 3 + (R() * 42 | 0), y + 2 + (R() * 6 | 0), 4 + (R() * 8 | 0), 1); } } }
  g.fillStyle = 'rgba(0,0,0,0.18)'; g.fillRect(0, FLOOR, W, 3);
  // پنجره
  const wx = WIN.x, wy = WIN.y, ww = WIN.w, wh = WIN.h;
  g.fillStyle = '#4a2c14'; g.fillRect(wx - 5, wy - 5, ww + 10, wh + 10); g.fillStyle = '#d9a064'; g.fillRect(wx - 4, wy - 4, ww + 8, wh + 8); g.fillStyle = '#6b4423'; g.fillRect(wx - 2, wy - 2, ww + 4, wh + 4);
  drawOutside(g, wx, wy, ww, wh);
  g.fillStyle = '#d9a064'; g.fillRect(wx + ww / 2 - 2, wy, 4, wh); g.fillRect(wx, wy + wh / 2 - 2, ww, 4); g.fillStyle = '#f0c088'; g.fillRect(wx + ww / 2 - 2, wy, 1, wh); g.fillRect(wx, wy + wh / 2 - 2, ww, 1);
  g.fillStyle = 'rgba(255,255,255,0.18)'; g.beginPath(); g.moveTo(wx + 6, wy); g.lineTo(wx + 22, wy); g.lineTo(wx + 4, wy + 36); g.lineTo(wx, wy + 36); g.closePath(); g.fill();
  g.fillStyle = '#8a5a30'; g.fillRect(wx - 9, wy + wh + 5, ww + 18, 5); g.fillStyle = '#b27c45'; g.fillRect(wx - 9, wy + wh + 5, ww + 18, 1); g.fillStyle = 'rgba(0,0,0,0.2)'; g.fillRect(wx - 9, wy + wh + 10, ww + 18, 2);
  // لکه‌ی نورِ پنجره روی کف (فقط روز)
  if (!isNight()) { g.fillStyle = 'rgba(255,240,180,0.16)'; g.beginPath(); g.moveTo(wx - 8, FLOOR + 6); g.lineTo(wx + ww + 8, FLOOR + 6); g.lineTo(wx + ww + 56, FLOOR + 64); g.lineTo(wx + 26, FLOOR + 64); g.closePath(); g.fill(); }
  else { g.fillStyle = 'rgba(20,30,80,0.18)'; g.fillRect(0, 0, W, H); }
  return c;
}

// ---- حیوان‌ها (همان PNGهای اپ)
const petImgs = {};
function petImg(src) { if (!petImgs[src]) { const i = new Image(); i.onload = () => dirty(); i.src = src; petImgs[src] = i; } return petImgs[src]; }

// ---- مدلِ صحنه
const itemDef = id => CATALOG.find(c => c.id === id);
const placedCount = id => S.placed.filter(p => p.id === id).length;
const freeCount = id => (S.owned[id] || 0) - placedCount(id);
function dims(p) { if (p.pet) { return { w: 48, h: 48 }; } const s = spriteOf(p.id); return { w: s.width, h: s.height }; }
function bounds(p) { const d = dims(p), def = p.pet ? null : itemDef(p.id); const anchorBottom = p.pet || def.anchor === 'bottom'; return { x: p.x - d.w / 2, y: anchorBottom ? p.y - d.h : p.y - d.h / 2, w: d.w, h: d.h }; }
function clampPos(p) {
  const d = dims(p), def = p.pet ? null : itemDef(p.id), zone = p.pet ? 'free' : def.zone;
  p.x = Math.round(clamp(p.x, d.w / 2, W - d.w / 2));
  if (zone === 'wall') p.y = Math.round(clamp(p.y, d.h / 2 + 7, FLOOR - 9 - d.h / 2 + 4));
  else if (zone === 'floor') p.y = Math.round(clamp(p.y, FLOOR + 6, H - 1));
  else p.y = Math.round(clamp(p.y, 56, H - 1));       // گل/گلدان و حیوان: هرجا (حتی روی میز)
}
function drawList() {
  const items = S.placed.map(p => ({ p, def: itemDef(p.id) }));
  const layer = it => (it.def.zone === 'wall' ? 0 : it.def.cat === 'rug' ? 1 : 2);
  items.sort((a, b) => layer(a) - layer(b) || (layer(a) === 2 ? (a.p.z || 0) - (b.p.z || 0) || a.p.y - b.p.y : (a.p.z || 0) - (b.p.z || 0) || a.p.y - b.p.y));
  const out = items.map(it => ({ kind: 'item', p: it.p, def: it.def, layer: layer(it) }));
  if (S.pet) { const pe = { kind: 'pet', p: S.pet, layer: 2 }; let i = out.findIndex(o => o.layer === 2 && ((o.p.z || 0) > (S.pet.z || 0) || ((o.p.z || 0) === (S.pet.z || 0) && o.p.y > S.pet.y))); if (i < 0) i = out.length; out.splice(i, 0, pe); }
  return out;
}
function drawPet(g, pet) {
  const P = PETS.find(x => x.id === pet.id); if (!P) return;
  const im = petImg(pet.sleep && P.sleep ? P.sleep : P.img); if (!im.complete || !im.naturalWidth) return;
  const x = Math.round(pet.x - 24), y = Math.round(pet.y - 48);
  g.save(); g.globalAlpha = 0.28; g.fillStyle = '#000'; g.beginPath(); g.ellipse(pet.x, pet.y - 1, 14, 3, 0, 0, 7); g.fill(); g.restore();
  g.save(); if (pet.flip) { g.translate(2 * x + 48, 0); g.scale(-1, 1); } g.drawImage(im, x, y); g.restore();
}
const cv = () => $('#room');
let dirtyFlag = true; function dirty() { dirtyFlag = true; }
function render() {
  const c = cv(); if (!c) return; const g = c.getContext('2d'); g.imageSmoothingEnabled = false;
  g.drawImage(roomCanvas(), 0, 0);
  const now = new Date();
  for (const o of drawList()) {
    if (o.kind === 'pet') drawPet(g, o.p);
    else { const s = spriteOf(o.p.id), b = bounds(o.p), bx = Math.round(b.x), by = Math.round(b.y); g.save(); if (o.p.flip) { g.translate(2 * bx + s.width, 0); g.scale(-1, 1); } g.drawImage(s, bx, by); g.restore(); if (o.def.dyn) clockDyn(g, o.def.dyn, o.p.flip ? bx : bx, by, now); }
  }
  const sel = selected();
  if (sel) { const b = bounds(sel.p); g.strokeStyle = '#ffffff'; g.setLineDash([2, 2]); g.lineWidth = 1; g.strokeRect(Math.round(b.x) + 0.5, Math.round(b.y) + 0.5, b.w + 1, b.h + 1); g.setLineDash([]); }
}
function selected() { if (!S.sel) return null; if (S.sel === 'pet') return S.pet ? { p: S.pet, pet: true } : null; const p = S.placed.find(x => x.uid === S.sel); return p ? { p } : null; }

// ---- تعامل: کشیدن و رها کردن
function toLogical(e) { const r = cv().getBoundingClientRect(); return [((e.clientX - r.left) / r.width) * W, ((e.clientY - r.top) / r.height) * H]; }
function hit(x, y) {
  const list = drawList();
  for (let i = list.length - 1; i >= 0; i--) {
    const o = list[i], p = o.p; let bx, by, w, hh, src;
    if (o.kind === 'pet') { bx = p.x - 24; by = p.y - 48; w = 48; hh = 48; src = null; } else { const s = spriteOf(p.id), b = bounds(p); bx = Math.round(b.x); by = Math.round(b.y); w = s.width; hh = s.height; src = s; }
    let lx = Math.floor(x - bx), ly = Math.floor(y - by); if (lx < 0 || ly < 0 || lx >= w || ly >= hh) continue;
    if (p.flip) lx = w - 1 - lx;
    const img = src || (() => { const P = PETS.find(q => q.id === p.id), im = petImg(p.sleep && P.sleep ? P.sleep : P.img); return im; })();
    if (!img || (img.complete === false)) continue;
    const t = document.createElement('canvas'); t.width = 1; t.height = 1; const tg = t.getContext('2d'); tg.drawImage(img, lx, ly, 1, 1, 0, 0, 1, 1);
    if (tg.getImageData(0, 0, 1, 1).data[3] > 20) return o.kind === 'pet' ? 'pet' : p.uid;
  }
  return null;
}
let drag = null;
function onDown(e) {
  const [x, y] = toLogical(e), id = hit(x, y);
  S.sel = id; dirty(); renderPanel(); renderBar();
  if (id) { const o = selected().p; drag = { id, dx: o.x - x, dy: o.y - y, moved: false, lastX: x }; cv().setPointerCapture(e.pointerId); }
}
function onMove(e) {
  if (!drag) return; const [x, y] = toLogical(e), o = selected().p;
  const nx = x + drag.dx, ny = y + drag.dy; if (Math.abs(nx - o.x) + Math.abs(ny - o.y) >= 1) drag.moved = true;
  if (S.sel === 'pet' && Math.abs(x - drag.lastX) > 2) { o.flip = x < drag.lastX; drag.lastX = x; }
  o.x = nx; o.y = ny; clampPos(o); dirty();
}
function onUp() { if (drag && drag.moved) save(); drag = null; }

// ---- خرید و قرار دادن
function buy(id) { const d = itemDef(id); if (S.coins < d.price) return toast('سکه‌ی کافی نداری'); S.coins -= d.price; S.owned[id] = (S.owned[id] || 0) + 1; save(); renderAll(); toast(`«${d.name}» خریده شد ✓`); }
function place(id) {
  if (freeCount(id) <= 0) return toast('این آیتم در انبار نیست؛ اول بخرش');
  const d = itemDef(id), p = { uid: S.uid++, id, x: 150 + Math.round(Math.random() * 80), y: d.zone === 'wall' ? 60 + Math.round(Math.random() * 20) : 168 + Math.round(Math.random() * 14), flip: false, z: 0 };
  if (d.zone === 'wall') p.x = 150 + Math.round(Math.random() * 150);
  clampPos(p); S.placed.push(p); S.sel = p.uid; save(); renderAll();
}
function unplace() { const s = selected(); if (!s) return; if (s.pet) { S.pet = null; } else S.placed = S.placed.filter(p => p.uid !== s.p.uid); S.sel = null; save(); renderAll(); }
function flipSel() { const s = selected(); if (!s) return; s.p.flip = !s.p.flip; save(); dirty(); }
function zSel(d) { const s = selected(); if (!s) return; s.p.z = (s.p.z || 0) + d; save(); dirty(); }
function setPet(id) { const P = PETS.find(x => x.id === id); S.pet = S.pet ? { ...S.pet, id, pet: true } : { id, pet: true, x: 250, y: 190, flip: false, sleep: false, z: 0 }; S.sel = 'pet'; save(); renderAll(); }
function toast(m) { const t = $('#toast'); t.textContent = m; t.style.display = 'block'; clearTimeout(toast.t); toast.t = setTimeout(() => (t.style.display = 'none'), 2000); }

// ---- رابط کاربری
const fmt = n => n.toLocaleString('fa-IR');
function thumb(src, w, hh, max = 64) { const c = document.createElement('canvas'); c.width = w; c.height = hh; c.getContext('2d').drawImage(src, 0, 0); const k = Math.max(1, Math.floor(max / Math.max(w, hh))); c.style.width = w * k + 'px'; c.style.height = hh * k + 'px'; c.className = 'th'; return c; }
function renderBar() {
  const s = selected();
  setKids($('#bar'), [
    h('span', { class: 'muted' }, s ? (s.pet ? 'حیوان انتخاب شده' : itemDef(s.p.id).name) : 'روی یک آیتم بزن یا بکش'),
    h('button', { disabled: !s, onclick: flipSel }, '⇄ برعکس'),
    h('button', { disabled: !s || (s.pet), onclick: () => zSel(1) }, '▲ جلو'),
    h('button', { disabled: !s || (s.pet), onclick: () => zSel(-1) }, '▼ عقب'),
    s && s.pet ? h('button', { onclick: () => { S.pet.sleep = !S.pet.sleep; save(); dirty(); } }, '😴 خواب/بیدار') : null,
    h('button', { disabled: !s, class: 'danger', onclick: unplace }, s && s.pet ? '↩ برداشتن' : '↩ برگردان به انبار')]);
}
function renderPanel() {
  const tabs = [...CATS, ['pet', 'حیوان'], ['inv', 'انبار']];
  const list = $('#items'); setKids($('#tabs'), tabs.map(([k, l]) => h('button', { class: S.tab === k ? 'on' : '', onclick: () => { S.tab = k; renderPanel(); } }, l)));
  if (S.tab === 'pet') { setKids(list, PETS.map(P => { const im = petImg(P.img); const c = h('canvas', { width: 48, height: 48, class: 'th' }); const draw = () => c.getContext('2d').drawImage(im, 0, 0); im.complete ? draw() : im.addEventListener('load', draw); c.style.width = '64px'; c.style.height = '64px'; return h('div', { class: 'card' + (S.pet && S.pet.id === P.id ? ' sel' : '') }, c, h('b', {}, P.name), h('button', { class: 'primary', onclick: () => setPet(P.id) }, S.pet && S.pet.id === P.id ? 'در اتاق ✓' : 'بگذار در اتاق')); })); return; }
  const items = S.tab === 'inv' ? CATALOG.filter(c => (S.owned[c.id] || 0) > 0) : CATALOG.filter(c => c.cat === S.tab);
  if (!items.length) { setKids(list, h('div', { class: 'muted pad' }, 'هنوز چیزی نخریده‌ای.')); return; }
  setKids(list, items.map(d => {
    const s = spriteOf(d.id), own = S.owned[d.id] || 0, fr = freeCount(d.id);
    return h('div', { class: 'card' }, thumb(s, s.width, s.height), h('b', {}, d.name),
      h('span', { class: 'muted' }, d.zone === 'wall' ? 'روی دیوار' : d.zone === 'free' ? 'هرجا' : 'روی کف', own ? ` · داری: ${fmt(own)}` : ''),
      h('div', { class: 'row' }, h('button', { class: 'primary', disabled: S.coins < d.price, onclick: () => buy(d.id) }, `🪙 ${fmt(d.price)} خرید`), h('button', { disabled: fr <= 0, onclick: () => place(d.id) }, fr > 0 ? `بگذار (${fmt(fr)})` : 'بگذار')));
  }));
}
function renderAll() { $('#coins').textContent = fmt(S.coins); renderPanel(); renderBar(); dirty(); }
function fit() { const box = $('#stagebox'), r = box.getBoundingClientRect(), k = Math.max(1, Math.min(r.width / W, r.height / H)); const kk = k >= 2 ? Math.floor(k) : k; const c = cv(); c.style.width = Math.floor(W * kk) + 'px'; c.style.height = Math.floor(H * kk) + 'px'; }

function init() {
  load();
  const c = cv(); c.width = W; c.height = H;
  c.addEventListener('pointerdown', onDown); c.addEventListener('pointermove', onMove); c.addEventListener('pointerup', onUp); c.addEventListener('pointercancel', onUp);
  document.addEventListener('keydown', e => { if (e.key === 'Delete') unplace(); });
  new ResizeObserver(fit).observe($('#stagebox')); fit();
  $('#addcoins').onclick = () => { S.coins += 500; save(); renderAll(); };
  $('#reset').onclick = () => { if ($('#reset').dataset.arm) { S = { coins: 2000, owned: {}, placed: [], pet: null, uid: 1, tab: 'plant', sel: null, night: 'auto' }; save(); $('#reset').textContent = 'شروع از نو'; delete $('#reset').dataset.arm; renderAll(); } else { $('#reset').dataset.arm = 1; $('#reset').textContent = 'مطمئنی؟ دوباره بزن'; setTimeout(() => { delete $('#reset').dataset.arm; $('#reset').textContent = 'شروع از نو'; }, 3000); } };
  $('#daynight').onclick = () => { S.night = isNight() ? 'day' : 'night'; save(); $('#daynight').textContent = isNight() ? '🌙 شب' : '☀ روز'; dirty(); };
  $('#daynight').textContent = isNight() ? '🌙 شب' : '☀ روز';
  if (!S.pet) { S.pet = { id: PETS[0].id, pet: true, x: 250, y: 190, flip: false, sleep: false, z: 0 }; save(); }
  renderAll();
  (function loop() { const t = Math.floor(Date.now() / 250); if (dirtyFlag || loop.t !== t) { loop.t = t; dirtyFlag = false; render(); } requestAnimationFrame(loop); })();
}
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
