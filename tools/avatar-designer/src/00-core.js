'use strict';
// ===== Avatar Designer — هسته: مدل داده، تاریخچه، ذخیره‌سازی محلی =====
// ابزارِ مستقل و موقت؛ هیچ سروری ندارد. پروژه در IndexedDB/localStorage مرورگر ذخیره می‌شود.

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
function h(tag, attrs, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') e.className = v;
    else if (k === 'style' && typeof v === 'object') Object.assign(e.style, v);
    else if (k === 'value' || k === 'checked' || k === 'disabled' || k === 'selected') e[k] = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v);
    else e.setAttribute(k, v === true ? '' : v);
  }
  for (const c of kids.flat(Infinity)) { if (c == null || c === false) continue; e.append(c.nodeType ? c : document.createTextNode(c)); }
  return e;
}
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const num = (v, d = 0) => { const n = parseFloat(v); return Number.isFinite(n) ? n : d; };
const clone = o => JSON.parse(JSON.stringify(o));
function newId(p) { return p + '_' + Math.random().toString(36).slice(2, 7) + Date.now().toString(36).slice(-3); }
function toast(msg, ms = 2200) { const t = $('#toast'); t.textContent = msg; t.style.display = 'block'; clearTimeout(toast._t); toast._t = setTimeout(() => (t.style.display = 'none'), ms); }

const CATS = [
  ['body', 'بدن'], ['face', 'صورت'], ['hair', 'مو'], ['eyes', 'چشم'], ['eyebrows', 'ابرو'], ['mouth', 'دهان'], ['hat', 'کلاه'], ['hijab', 'روسری'],
  ['helmet', 'کلاه‌خود'], ['clothes', 'لباس'], ['shirt', 'پیراهن'], ['pants', 'شلوار'], ['shoes', 'کفش'], ['armor', 'زره'], ['sword', 'شمشیر'],
  ['weapon', 'سلاح'], ['shield', 'سپر'], ['accessory', 'اکسسوری'], ['pet', 'حیوان'], ['petgear', 'تجهیزات حیوان'], ['cape', 'شنل'], ['capeback', 'شنل (پشت)'], ['hands', 'دست'], ['sleep', 'خواب'], ['condition', 'وضعیت'], ['shadow', 'سایه'], ['effect', 'افکت'],
];
const CAT_FA = Object.fromEntries(CATS);
const MOODS = [['neutral', 'خنثی'], ['happy', 'شاد'], ['sad', 'غمگین'], ['angry', 'عصبانی'], ['surprised', 'متعجب'], ['tired', 'خسته'], ['excited', 'هیجان‌زده']];
const ANCHORS = ['origin', 'center', 'top-center', 'bottom-center', 'left-center', 'right-center'];
const DEFAULT_LAYERS = ['pet', 'body', 'shoes', 'pants', 'shirt', 'clothes', 'armor', 'face', 'eyes', 'eyebrows', 'mouth', 'hair', 'hijab', 'hat', 'helmet', 'accessory', 'sword', 'weapon', 'shield', 'effect'];
const SLOT_CHARS = '0123456789abcdefghijklmnopqrstuvwxyz';

// ---------------------------------------------------------------- ساخت مدل
function newGeometry(x = 48, y = 134) { return { x, y, scale: 1, rotation: 0, opacity: 1, flipX: false, flipY: false }; }
function newPart(name, w = 16, h = 16, dx = 0, dy = 0) {
  return { id: newId('part'), name, w, h, px: new Uint8Array(w * h), dx, dy, scale: 1, rotation: 0, flipX: false, flipY: false, visible: true };
}
function newFamily(name, category, slots) {
  return {
    id: newId('fam'), name, category, characterIds: [], anchor: 'origin', tags: [],
    slots: slots || [{ id: 's1', name: 'اصلی', color: '#cccccc' }, { id: 's2', name: 'سایه', color: '#888888' }, { id: 's3', name: 'خط دور', color: '#222222' }],
    parts: [], variants: [{ id: newId('var'), name: 'Default', colors: {}, overrides: {} }],
    geometry: { '*': newGeometry() },
  };
}
function emptyProject(name = 'Avatar Project') {
  return {
    format: 'rp-avatar-project', version: 1, id: newId('proj'), name, createdAt: Date.now(), updatedAt: Date.now(),
    canvas: { w: 96, h: 144, safe: { x: 8, y: 8, w: 80, h: 128 } },
    characters: [], families: [], images: {},
    layers: DEFAULT_LAYERS.map(c => ({ id: 'L_' + c, name: CAT_FA[c] || c, category: c, visible: true, locked: false })),
    moods: {}, backgrounds: [],
    scene: {
      characterId: null, mood: 'neutral', equipped: {}, backgroundId: null,
      bgVisible: true,
      shadow: { on: true, color: '#000000', opacity: 0.35, w: 34, h: 8, x: 48, y: 134 },
      ground: { on: false, color: '#3a4a3a', opacity: 1, height: 16 },
      lighting: { on: false, color: '#ffe9b0', angle: 45, opacity: 0.18 },
      glow: { on: false, color: '#9fb0ff', radius: 60, opacity: 0.25, x: 48, y: 80 },
    },
    view: { zoom: 4, panX: 0, panY: 0, grid: 8, snap: true, showGrid: true, showRuler: true, showSafe: true, showCenter: true, showLayerBoxes: false, guides: [] },
  };
}

// ---------------------------------------------------------------- ابزارهای جستجو
let P = null; // پروژه‌ی جاری
const famById = id => P.families.find(f => f.id === id);
const charById = id => P.characters.find(c => c.id === id);
const layerById = id => P.layers.find(l => l.id === id);
const varOf = (f, vid) => f.variants.find(v => v.id === vid) || f.variants[0];
function compatible(f, charId) { return !f.characterIds.length || !charId || f.characterIds.includes(charId); }
function geomFor(f, charId) {
  const base = f.geometry['*'] || newGeometry();
  const o = charId && f.geometry[charId];
  return Object.assign({}, base, o || {});
}
function slotColor(f, variant, slotId, partId) {
  const ov = partId && variant.overrides && variant.overrides[partId];
  if (ov && ov.colors && ov.colors[slotId]) return ov.colors[slotId];
  return (variant.colors && variant.colors[slotId]) || (f.slots.find(s => s.id === slotId) || {}).color || '#ff00ff';
}

// ---------------------------------------------------------------- (د)سریال‌سازی
function encodeRows(part) {
  const rows = [];
  for (let y = 0; y < part.h; y++) { let s = ''; for (let x = 0; x < part.w; x++) s += SLOT_CHARS[part.px[y * part.w + x]] || '0'; rows.push(s); }
  return rows;
}
function decodeRows(rows, w, h) {
  const px = new Uint8Array(w * h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) px[y * w + x] = Math.max(0, SLOT_CHARS.indexOf((rows[y] || '')[x] || '0'));
  return px;
}
/** تصاویر (PNG) جدا از Snapshotهای Undo نگه‌داری می‌شوند؛ فقط در ذخیره/Export همراه‌اند */
function serialize(p, withImages = true) {
  const { images, ...rest } = p;
  const c = { ...rest, families: p.families.map(f => ({ ...f, parts: f.parts.map(pt => { const { px, ...r } = pt; return { ...r, rows: pt.img ? [] : encodeRows(pt) }; }) })) };
  const o = JSON.parse(JSON.stringify(c));
  if (withImages) o.images = images || {};
  return o;
}
function deserialize(o) {
  const p = JSON.parse(JSON.stringify(o));
  p.images = p.images || {};
  for (const f of p.families) for (const pt of f.parts) { pt.px = decodeRows(pt.rows || [], pt.w, pt.h); delete pt.rows; }
  const base = emptyProject();
  p.view = Object.assign(base.view, p.view || {});
  p.scene = Object.assign(base.scene, p.scene || {});
  p.canvas = Object.assign(base.canvas, p.canvas || {});
  return p;
}

// ---------------------------------------------------------------- تاریخچه (Undo/Redo)
const H = { undo: [], redo: [], max: 120 };
function snap() { return JSON.stringify(serialize(P, false)); }
function resetHistory() { H.undo = [snap()]; H.redo = []; }
function commit(msg) {
  P.updatedAt = Date.now();
  const s = snap();
  if (H.undo[H.undo.length - 1] !== s) { H.undo.push(s); if (H.undo.length > H.max) H.undo.shift(); H.redo = []; }
  scheduleSave();
  invalidateCache();
  renderAll();
}
function restore(s) { const imgs = P.images; P = deserialize(JSON.parse(s)); P.images = imgs; invalidateCache(); scheduleSave(); renderAll(); }
function undo() { if (H.undo.length < 2) return toast('چیزی برای بازگردانی نیست'); H.redo.push(H.undo.pop()); restore(H.undo[H.undo.length - 1]); }
function redo() { if (!H.redo.length) return toast('چیزی برای تکرار نیست'); const s = H.redo.pop(); H.undo.push(s); restore(s); }

// ---------------------------------------------------------------- ذخیره‌سازی محلی (IndexedDB با پشتیبانِ localStorage)
const DB = {
  db: null,
  async open() {
    if (this.db) return this.db;
    try {
      this.db = await new Promise((res, rej) => {
        const r = indexedDB.open('avatar-designer', 1);
        r.onupgradeneeded = () => r.result.createObjectStore('projects', { keyPath: 'id' });
        r.onsuccess = () => res(r.result);
        r.onerror = () => rej(r.error);
      });
    } catch (e) { this.db = 'ls'; }
    return this.db;
  },
  async put(rec) {
    const db = await this.open();
    if (db === 'ls') { localStorage.setItem('ad:' + rec.id, JSON.stringify(rec)); return; }
    await new Promise((res, rej) => { const tx = db.transaction('projects', 'readwrite'); tx.objectStore('projects').put(rec); tx.oncomplete = res; tx.onerror = () => rej(tx.error); });
  },
  async get(id) {
    const db = await this.open();
    if (db === 'ls') return JSON.parse(localStorage.getItem('ad:' + id) || 'null');
    return new Promise((res, rej) => { const r = db.transaction('projects').objectStore('projects').get(id); r.onsuccess = () => res(r.result || null); r.onerror = () => rej(r.error); });
  },
  async all() {
    const db = await this.open();
    if (db === 'ls') return Object.keys(localStorage).filter(k => k.startsWith('ad:')).map(k => JSON.parse(localStorage.getItem(k)));
    return new Promise((res, rej) => { const r = db.transaction('projects').objectStore('projects').getAll(); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });
  },
  async del(id) {
    const db = await this.open();
    if (db === 'ls') { localStorage.removeItem('ad:' + id); return; }
    await new Promise((res, rej) => { const tx = db.transaction('projects', 'readwrite'); tx.objectStore('projects').delete(id); tx.oncomplete = res; tx.onerror = () => rej(tx.error); });
  },
};
let saveTimer = null;
function scheduleSave() { clearTimeout(saveTimer); saveTimer = setTimeout(saveNow, 400); }
async function saveNow() {
  if (!P) return;
  try { await DB.put({ id: P.id, name: P.name, updatedAt: P.updatedAt, json: JSON.stringify(serialize(P)) }); localStorage.setItem('ad:current', P.id); setStatus('ذخیره شد ✓'); } catch (e) { setStatus('خطا در ذخیره: ' + e.message); }
}
function setStatus(t) { const s = $('#status'); if (s) s.textContent = t; }
