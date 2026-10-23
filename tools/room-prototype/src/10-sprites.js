'use strict';
// ===== پیکسل‌آرتِ اتاق و ۴۰ آیتم (همه با کد کشیده شده‌اند؛ هر آیتم یک Canvas کوچک با خط‌دورِ خودکار) =====
const OUT = '#2a1d1a';
const rgb = h => { const n = parseInt(h.slice(1), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; };
const hx = a => '#' + a.map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0')).join('');
const mix = (a, b, t) => { const x = rgb(a), y = rgb(b); return hx(x.map((v, i) => v + (y[i] - v) * t)); };
const dk = (c, t = 0.25) => mix(c, '#000000', t);
const lt = (c, t = 0.3) => mix(c, '#ffffff', t);

function outline(c, col) {
  const x = c.getContext('2d'), w = c.width, h = c.height, d = x.getImageData(0, 0, w, h), a = d.data, o = rgb(col);
  const solid = (i, j) => i >= 0 && j >= 0 && i < w && j < h && a[(j * w + i) * 4 + 3] > 40;
  const add = [];
  for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) if (!solid(i, j) && (solid(i + 1, j) || solid(i - 1, j) || solid(i, j + 1) || solid(i, j - 1))) add.push([i, j]);
  for (const [i, j] of add) { const k = (j * w + i) * 4; a[k] = o[0]; a[k + 1] = o[1]; a[k + 2] = o[2]; a[k + 3] = 255; }
  x.putImageData(d, 0, 0);
}
/** Canvas به اندازه‌ی (w+2)×(h+2)؛ مختصاتِ ترسیم از (0,0) و یک پیکسل حاشیه برای خط‌دور */
function spr(w, h, fn, opt = {}) {
  const c = document.createElement('canvas'); c.width = w + 2; c.height = h + 2;
  const x = c.getContext('2d');
  const g = {
    w, h,
    P: (px, py, col) => { x.fillStyle = col; x.fillRect(px + 1, py + 1, 1, 1); },
    R: (px, py, rw, rh, col) => { x.fillStyle = col; x.fillRect(px + 1, py + 1, rw, rh); },
    E: (cx, cy, rx, ry, col) => { x.fillStyle = col; for (let j = -ry; j <= ry; j++) for (let i = -rx; i <= rx; i++) if ((i * i) / (rx * rx + 0.4) + (j * j) / (ry * ry + 0.4) <= 1) x.fillRect(cx + i + 1, cy + j + 1, 1, 1); },
    L: (x0, y0, x1, y1, col) => { x.fillStyle = col; let dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, e = dx + dy; for (;;) { x.fillRect(x0 + 1, y0 + 1, 1, 1); if (x0 === x1 && y0 === y1) break; const e2 = 2 * e; if (e2 >= dy) { e += dy; x0 += sx; } if (e2 <= dx) { e += dx; y0 += sy; } } },
  };
  fn(g);
  if (!opt.noOutline) outline(c, opt.out || OUT);
  return c;
}
/** سطلِ مخروطی: لبه‌ی روشن، بدنه‌ی سایه‌دار */
function pot(g, cx, top, wTop, wBot, h, col) {
  const rim = 3, hw = Math.floor(wTop / 2) + 1;
  g.R(cx - hw, top, hw * 2, rim, lt(col, 0.22)); g.R(cx - hw, top + rim - 1, hw * 2, 1, dk(col, 0.15));
  for (let r = 0; r < h - rim; r++) { const w = Math.round(wTop - (wTop - wBot) * (r / (h - rim))), x0 = cx - Math.floor(w / 2); g.R(x0, top + rim + r, w, 1, col); g.R(x0 + 1, top + rim + r, 1, 1, lt(col, 0.18)); g.R(x0 + w - 2, top + rim + r, 2, 1, dk(col, 0.22)); }
}
const leaf = (g, cx, cy, rx, ry, col) => { g.E(cx, cy, rx, ry, col); g.E(cx - 1, cy - 1, Math.max(1, rx - 2), Math.max(1, ry - 2), lt(col, 0.18)); };

// ------------------------------------------------------------------ گل و گلدان (۱۰)
const PLANTS = [
  ['کاکتوس کوچک', 60, () => spr(16, 26, g => {
    pot(g, 8, 19, 11, 8, 7, '#c4673d');
    g.R(5, 6, 6, 14, '#4f9a52'); g.E(8, 6, 3, 3, '#4f9a52'); g.R(2, 12, 4, 2, '#4f9a52'); g.R(2, 8, 3, 5, '#4f9a52'); g.R(10, 13, 4, 2, '#4f9a52'); g.R(11, 9, 3, 5, '#4f9a52');
    g.R(7, 4, 1, 15, '#7bc67a'); g.R(3, 9, 1, 4, '#7bc67a'); g.R(12, 10, 1, 4, '#7bc67a');
    for (const [x, y] of [[6, 8], [9, 11], [6, 14], [9, 16], [3, 10], [12, 11]]) g.P(x, y, '#e8f5c8');
    g.R(7, 1, 3, 2, '#ff6fa5'); g.P(8, 0, '#ff9cc4');
  })],
  ['ساکولنت فیروزه‌ای', 90, () => spr(20, 20, g => {
    pot(g, 10, 12, 14, 10, 8, '#3aa6a0');
    for (const [cx, cy, rx, ry, c] of [[10, 9, 8, 3, '#6fae8f'], [10, 8, 6, 3, '#8cc9a8'], [10, 6, 4, 3, '#a9e0c0'], [10, 5, 2, 2, '#d3f2dc']]) g.E(cx, cy, rx, ry, c);
    for (const x of [4, 8, 12, 16]) g.P(x, 9, '#4d8a70');
  })],
  ['آفتابگردان در گلدان', 140, () => spr(20, 38, g => {
    g.R(9, 14, 2, 14, '#3f8f3f'); leaf(g, 5, 20, 3, 2, '#4fae4f'); leaf(g, 15, 23, 3, 2, '#4fae4f');
    g.R(5, 27, 10, 10, '#5a86b8'); g.R(4, 27, 12, 2, '#7aa6d6'); g.R(13, 29, 2, 8, '#3f6592'); g.R(6, 30, 2, 3, '#8fb8e6');
    for (let a = 0; a < 12; a++) { const t = a / 12 * Math.PI * 2; g.E(10 + Math.round(Math.cos(t) * 6), 8 + Math.round(Math.sin(t) * 6), 2, 2, a % 2 ? '#ffd23a' : '#ffc01a'); }
    g.E(10, 8, 4, 4, '#6b4020'); g.E(9, 7, 2, 2, '#8a5a30');
  })],
  ['گل رز قرمز', 180, () => spr(18, 34, g => {
    g.R(6, 13, 1, 12, '#3f8f3f'); g.R(9, 10, 1, 15, '#3f8f3f'); g.R(12, 14, 1, 11, '#3f8f3f'); leaf(g, 4, 19, 2, 1, '#4fae4f'); leaf(g, 14, 20, 2, 1, '#4fae4f');
    for (const [cx, cy] of [[6, 11], [9, 7], [12, 12]]) { g.E(cx, cy, 3, 3, '#d62f45'); g.E(cx - 1, cy - 1, 1, 1, '#ff7a8a'); g.P(cx, cy, '#8f1427'); }
    g.R(4, 24, 10, 9, '#3a4f8c'); g.R(3, 24, 12, 2, '#5a74b8'); g.R(11, 26, 2, 7, '#27386a'); for (const [x, y] of [[6, 28], [8, 30], [5, 31], [9, 27]]) g.P(x, y, '#e8eeff');
  })],
  ['لاله‌های صورتی', 160, () => spr(20, 34, g => {
    for (const [x, c, h] of [[6, '#f26aa0', 8], [10, '#ffc93a', 5], [14, '#f26aa0', 9]]) { g.R(x, h + 5, 1, 17, '#3f8f3f'); g.R(x - 2, h, 5, 5, c); g.P(x - 2, h, 'rgba(0,0,0,0)'); g.R(x - 1, h - 1, 3, 1, lt(c, 0.25)); g.R(x, h + 1, 1, 3, dk(c, 0.2)); }
    g.R(3, 21, 14, 12, '#cfeaf4'); g.R(3, 21, 14, 1, '#ffffff'); g.R(4, 25, 12, 8, '#9fd0e6'); g.R(5, 22, 2, 9, '#ffffff'); g.R(4, 32, 12, 1, '#6aa6c4');
    g.R(7, 26, 1, 6, '#3f8f3f'); g.R(11, 26, 1, 6, '#3f8f3f'); g.R(14, 26, 1, 5, '#3f8f3f');
  })],
  ['بونسای', 320, () => spr(30, 30, g => {
    g.R(6, 22, 18, 7, '#5b3a2a'); g.R(5, 22, 20, 2, '#7a523c'); g.R(7, 28, 3, 2, '#3e271c'); g.R(20, 28, 3, 2, '#3e271c'); g.R(8, 24, 14, 1, '#7a523c');
    g.R(14, 14, 3, 9, '#7a4a2a'); g.R(12, 18, 3, 3, '#7a4a2a'); g.R(17, 16, 5, 2, '#7a4a2a'); g.R(15, 14, 1, 8, '#9a6238');
    for (const [cx, cy, rx, ry, c] of [[9, 12, 8, 5, '#2f8f4a'], [20, 9, 8, 5, '#2f8f4a'], [15, 6, 8, 5, '#3fae5f'], [24, 15, 5, 3, '#2f8f4a'], [14, 11, 6, 4, '#3fae5f']]) g.E(cx, cy, rx, ry, c);
    for (const [x, y] of [[8, 9], [17, 5], [21, 7], [12, 12], [24, 14]]) g.P(x, y, '#7fd89a');
  })],
  ['سرخس در سبد', 200, () => spr(30, 32, g => {
    for (let a = 0; a < 9; a++) { const t = Math.PI * (0.1 + a * 0.1), x1 = 15 + Math.round(Math.cos(t + Math.PI) * 13 * -1), y1 = 14 - Math.round(Math.sin(t) * 11); g.L(15, 17, 15 + Math.round(Math.cos(Math.PI - t) * 13), 17 - Math.round(Math.sin(t) * 13), a % 2 ? '#3f9a4f' : '#58b868'); g.L(15, 16, 15 + Math.round(Math.cos(Math.PI - t) * 11), 17 - Math.round(Math.sin(t) * 11) + 1, '#2f7a3f'); }
    g.R(5, 18, 20, 12, '#d9b26a'); g.R(4, 18, 22, 3, '#ecc98a'); g.R(6, 29, 18, 2, '#a07a3a');
    for (let y = 22; y < 29; y += 2) for (let x = 6 + ((y / 2) % 2); x < 24; x += 3) g.R(x, y, 2, 1, '#a07a3a'); g.R(5, 18, 20, 1, '#f3dca6');
  })],
  ['گیاه برگ‌بزرگ', 420, () => spr(34, 52, g => {
    g.R(16, 22, 2, 18, '#2f7a3f'); g.R(10, 26, 2, 14, '#2f7a3f'); g.R(23, 24, 2, 16, '#2f7a3f');
    for (const [cx, cy, rx, ry, c] of [[17, 14, 8, 8, '#2f9a55'], [8, 20, 7, 6, '#3fae65'], [26, 18, 7, 7, '#3fae65'], [14, 6, 5, 5, '#58c87c'], [24, 8, 5, 4, '#58c87c']]) { g.E(cx, cy, rx, ry, c); g.L(cx, cy - ry + 1, cx, cy + ry - 1, dk(c, 0.2)); g.E(cx - 2, cy - 2, Math.max(1, rx - 4), Math.max(1, ry - 4), lt(c, 0.12)); }
    for (const [x, y] of [[17, 14], [8, 20], [26, 18]]) g.R(x - 1, y + 2, 2, 2, 'rgba(0,0,0,0)');
    g.R(9, 36, 16, 15, '#f1ece2'); g.R(8, 36, 18, 3, '#ffffff'); g.R(21, 39, 4, 12, '#cfc7b6'); g.R(10, 39, 2, 10, '#ffffff'); g.R(9, 50, 16, 1, '#b8b09c');
  })],
  ['اسطوخودوس', 130, () => spr(18, 32, g => {
    for (const [x, h] of [[5, 4], [8, 1], [11, 3], [14, 6]]) { g.R(x, h + 7, 1, 16, '#5f9a4f'); for (let k = 0; k < 7; k++) g.R(x - (k % 2), h + k, 2, 1, k % 2 ? '#9a6fd6' : '#b890f0'); g.P(x, h - 1, '#d4b8ff'); }
    g.R(3, 20, 12, 11, '#dff3f7'); g.R(3, 20, 12, 1, '#ffffff'); g.R(4, 23, 10, 7, '#f6e9c8'); g.R(5, 25, 8, 3, '#c85a5a'); g.R(5, 25, 8, 1, '#e88a8a'); g.R(3, 20, 12, 2, '#b8c8cc'); g.R(4, 30, 10, 1, '#9fb4ba');
  })],
  ['بامبو', 260, () => spr(24, 56, g => {
    for (const [x, top, c] of [[8, 2, '#5aa84a'], [12, 10, '#6bbf58'], [16, 5, '#5aa84a']]) { g.R(x, top, 3, 36, c); g.R(x, top, 1, 36, lt(c, 0.25)); for (let y = top + 6; y < 38; y += 7) g.R(x - 1, y, 5, 1, dk(c, 0.3)); }
    for (const [x, y, d] of [[10, 8, -1], [14, 16, 1], [18, 12, 1], [8, 20, -1]]) { g.L(x, y, x + d * 6, y - 3, '#7fd86a'); g.L(x, y, x + d * 5, y - 1, '#4f9a45'); }
    g.R(6, 36, 14, 19, '#2b2f3a'); g.R(5, 36, 16, 3, '#454b5c'); g.R(17, 39, 3, 16, '#1a1d25'); g.R(8, 40, 2, 12, '#454b5c'); g.R(7, 46, 12, 2, '#c9a24a'); g.R(5, 54, 16, 1, '#1a1d25');
  })],
];

// ------------------------------------------------------------------ میزها (۵)
const woodC = '#c98d52';
const TABLES = [
  ['میز گرد چوبی', 300, () => spr(46, 36, g => {
    g.E(23, 14, 21, 8, dk(woodC, 0.35)); g.E(23, 11, 21, 8, woodC); g.E(23, 11, 17, 6, lt(woodC, 0.1)); g.E(19, 9, 6, 2, lt(woodC, 0.3));
    g.R(20, 18, 6, 14, dk(woodC, 0.3)); g.R(20, 18, 2, 14, woodC); g.E(23, 32, 11, 3, dk(woodC, 0.35)); g.E(23, 31, 11, 3, woodC);
  })],
  ['میز ناهارخوری', 650, () => spr(68, 40, g => {
    g.R(6, 12, 8, 22, dk('#8a5a30', 0.2)); g.R(54, 12, 8, 22, dk('#8a5a30', 0.2));
    g.R(2, 8, 64, 8, '#a8703a'); g.R(0, 5, 68, 5, '#c98d52'); g.R(1, 6, 66, 1, '#e1ab72'); g.R(0, 10, 68, 1, '#8a5a30');
    g.R(4, 16, 60, 3, '#8a5a30'); g.R(5, 19, 6, 20, '#a8703a'); g.R(57, 19, 6, 20, '#a8703a'); g.R(5, 19, 2, 20, '#c98d52'); g.R(57, 19, 2, 20, '#c98d52'); g.R(4, 38, 8, 2, '#6b4423'); g.R(56, 38, 8, 2, '#6b4423');
    for (let x = 6; x < 64; x += 9) g.R(x, 7, 4, 1, '#b97d45');
  })],
  ['میز تحریر', 520, () => spr(64, 44, g => {
    g.R(0, 8, 64, 6, '#b5651d'); g.R(0, 6, 64, 3, '#d68a3c'); g.R(1, 7, 62, 1, '#eea85a');
    g.R(3, 14, 20, 28, '#8f4f16'); g.R(5, 16, 16, 11, '#a85f1e'); g.R(5, 29, 16, 11, '#a85f1e'); g.R(11, 20, 4, 2, '#f0d27a'); g.R(11, 33, 4, 2, '#f0d27a'); g.R(5, 16, 16, 1, '#c97a2c'); g.R(5, 29, 16, 1, '#c97a2c');
    g.R(52, 14, 5, 29, '#a85f1e'); g.R(52, 14, 1, 29, '#c97a2c'); g.R(23, 14, 29, 4, '#8f4f16'); g.R(3, 42, 20, 2, '#5e330e'); g.R(52, 42, 5, 2, '#5e330e');
  })],
  ['میز عسلی کم‌ارتفاع', 280, () => spr(52, 26, g => {
    g.R(2, 8, 48, 8, '#3a2a24'); g.R(0, 4, 52, 5, '#5a4036'); g.R(1, 5, 50, 1, '#7a5a4c'); g.R(5, 5, 42, 3, '#9fd0e6'); g.R(7, 5, 12, 1, '#e4f6ff'); g.R(4, 16, 6, 9, '#3a2a24'); g.R(42, 16, 6, 9, '#3a2a24'); g.R(4, 16, 2, 9, '#5a4036'); g.R(42, 16, 2, 9, '#5a4036');
  })],
  ['میز سفید مدرن', 380, () => spr(40, 38, g => {
    g.E(20, 11, 18, 7, '#cfd3da'); g.E(20, 9, 18, 7, '#f4f6f8'); g.E(16, 7, 6, 2, '#ffffff'); g.R(17, 14, 6, 17, '#e3e6ea'); g.R(17, 14, 2, 17, '#ffffff'); g.R(21, 14, 2, 17, '#b8bdc6'); g.E(20, 33, 12, 3, '#cfd3da'); g.E(20, 32, 12, 3, '#f4f6f8');
  })],
];

// ------------------------------------------------------------------ تخت‌ها (۵)
function bed(w, h, o) {
  return spr(w, h, g => {
    const hh = o.hh || 18, f = o.frame;
    g.R(0, 0, w, hh, f); g.R(1, 1, w - 2, 2, lt(f, 0.25)); g.R(3, 4, w - 6, hh - 6, lt(f, 0.1)); g.R(3, 4, w - 6, 1, dk(f, 0.15));
    if (o.arch) { g.R(0, 0, 4, 2, 'rgba(0,0,0,0)'); g.R(w - 4, 0, 4, 2, 'rgba(0,0,0,0)'); }
    g.R(2, hh - 3, w - 4, h - hh - 5, '#f6f1e6');                 // تشک
    const pc = o.pillow, pn = o.pillows || 1, pw = Math.floor((w - 10) / pn) - 2;
    for (let i = 0; i < pn; i++) { const x = 5 + i * (pw + 2); g.R(x + 1, hh - 6, pw - 2, 9, pc); g.R(x, hh - 5, pw, 7, pc); g.R(x + 1, hh - 6, pw - 2, 1, lt(pc, 0.4)); g.R(x, hh + 1, pw, 1, dk(pc, 0.15)); }
    g.R(2, hh + 6, w - 4, h - hh - 14, o.blanket); g.R(2, hh + 6, w - 4, 3, lt(o.blanket, 0.35)); g.R(2, hh + 9, w - 4, 1, dk(o.blanket, 0.2));
    if (o.pattern) o.pattern(g, 2, hh + 10, w - 4, h - hh - 18);
    g.R(0, h - 11, w, 10, f); g.R(1, h - 11, w - 2, 2, lt(f, 0.3)); g.R(3, h - 8, w - 6, 4, dk(f, 0.12)); g.R(1, h - 2, 4, 2, dk(f, 0.45)); g.R(w - 5, h - 2, 4, 2, dk(f, 0.45));
  });
}
const BEDS = [
  ['تخت یک‌نفره آبی', 450, () => bed(60, 46, { frame: '#a8703a', blanket: '#4a7fd6', pillow: '#ffffff' })],
  ['تخت دونفره قرمز', 900, () => bed(80, 50, { frame: '#6b3a22', blanket: '#c8344a', pillow: '#fff4e0', pillows: 2, hh: 20 })],
  ['تخت چوبی با لحاف چهارخانه', 650, () => bed(64, 46, { frame: '#d9a560', blanket: '#4faa62', pillow: '#fffbe8', pattern: (g, x, y, w, h) => { for (let j = 0; j < h; j += 4) for (let i = 0; i < w; i += 4) if (((i + j) / 4) % 2 === 0) g.R(x + i, y + j, 4, 4, '#7bc98a'); } })],
  ['تخت صورتی قلب‌دار', 750, () => bed(62, 46, { frame: '#f3f0f5', blanket: '#f48fb1', pillow: '#ffd6e4', pattern: (g, x, y, w, h) => { const cx = x + Math.floor(w / 2), cy = y + 2; g.E(cx - 2, cy, 2, 2, '#ffffff'); g.E(cx + 2, cy, 2, 2, '#ffffff'); g.R(cx - 4, cy + 1, 8, 2, '#ffffff'); g.R(cx - 3, cy + 3, 6, 1, '#ffffff'); g.R(cx - 1, cy + 4, 2, 1, '#ffffff'); } })],
  ['تخت دوطبقه', 1200, () => spr(58, 72, g => {
    const f = '#7a4a2a';
    g.R(0, 0, 5, 72, f); g.R(53, 0, 5, 72, f); g.R(0, 0, 1, 72, lt(f, 0.3)); g.R(53, 0, 1, 72, lt(f, 0.3));
    g.R(5, 14, 48, 4, '#c9965a'); g.R(5, 12, 48, 3, '#f6f1e6'); g.R(8, 6, 14, 7, '#fff'); g.R(24, 8, 26, 5, '#e05a5a'); g.R(5, 3, 48, 2, f);
    g.R(5, 48, 48, 4, '#c9965a'); g.R(5, 46, 48, 3, '#f6f1e6'); g.R(8, 40, 14, 7, '#fff'); g.R(24, 42, 26, 5, '#4a9ad6');
    g.R(5, 27, 48, 2, f); g.R(5, 62, 48, 3, f); g.R(8, 20, 1, 7, f); g.R(48, 20, 1, 7, f);
    for (let y = 18; y < 62; y += 6) g.R(10, y, 10, 1, '#e8c08a'); g.R(9, 18, 1, 44, '#c9965a'); g.R(20, 18, 1, 44, '#c9965a');
    g.R(0, 70, 7, 2, '#3e2615'); g.R(51, 70, 7, 2, '#3e2615');
  })],
];

// ------------------------------------------------------------------ قاب عکس (۱۰)
function frame(w, h, f, mat, pic, round) {
  return spr(w, h, g => {
    if (round) { g.E(w / 2 | 0, h / 2 | 0, (w / 2 | 0) - 1, (h / 2 | 0) - 1, f); g.E(w / 2 | 0, h / 2 | 0, (w / 2 | 0) - 3, (h / 2 | 0) - 3, mat); }
    else { g.R(0, 0, w, h, f); g.R(1, 1, w - 2, 1, lt(f, 0.35)); g.R(1, h - 2, w - 2, 1, dk(f, 0.3)); g.R(2, 2, w - 4, h - 4, dk(f, 0.35)); g.R(3, 3, w - 6, h - 6, mat); }
    const m = round ? 5 : 4; pic(g, m, m, w - m * 2, h - m * 2);
  });
}
const FRAMES = [
  ['کوه و آفتاب', 200, () => frame(32, 26, '#8a5a30', '#f1e6cc', (g, x, y, w, h) => { g.R(x, y, w, h, '#8fd0ff'); g.E(x + w - 5, y + 4, 2, 2, '#ffd23a'); g.R(x, y + h - 5, w, 5, '#4f9a52'); for (const [cx, hh, c] of [[x + 6, 9, '#6b7a99'], [x + 15, 12, '#56637f']]) { for (let i = 0; i < hh; i++) g.R(cx - i * 1 + 0, y + h - 5 - hh + i, i * 2 + 1, 1, c); g.R(cx - 1, y + h - 5 - hh, 3, 2, '#ffffff'); } })],
  ['غروب دریا', 220, () => frame(34, 24, '#d9b24a', '#fff4d9', (g, x, y, w, h) => { g.R(x, y, w, h * 0.45 | 0, '#ff9a5a'); g.R(x, y + (h * 0.25 | 0), w, 3, '#ffc27a'); g.E(x + w / 2 | 0, y + (h * 0.45 | 0), 5, 4, '#ffe08a'); g.R(x, y + (h * 0.45 | 0), w, h - (h * 0.45 | 0), '#2f6fb8'); for (let i = 0; i < 5; i++) g.R(x + i * 5 + 1, y + (h * 0.55 | 0) + (i % 2) * 3, 3, 1, '#8fc4f2'); g.R(x + (w / 2 | 0) - 2, y + (h * 0.5 | 0), 4, 1, '#ffd27a'); })],
  ['پرتره گربه', 260, () => frame(26, 30, '#202228', '#e9e4da', (g, x, y, w, h) => { g.R(x, y, w, h, '#9fb8d6'); const cx = x + w / 2 | 0, cy = y + h / 2 + 1 | 0; g.E(cx, cy, 6, 5, '#8a8f99'); g.R(cx - 6, cy - 7, 3, 4, '#8a8f99'); g.R(cx + 4, cy - 7, 3, 4, '#8a8f99'); g.R(cx - 5, cy - 6, 1, 2, '#f2a0b0'); g.R(cx + 5, cy - 6, 1, 2, '#f2a0b0'); g.P(cx - 3, cy - 1, '#2a2f3a'); g.P(cx + 3, cy - 1, '#2a2f3a'); g.P(cx, cy + 1, '#f2a0b0'); g.L(cx - 8, cy + 1, cx - 5, cy + 2, '#fff'); g.L(cx + 8, cy + 1, cx + 5, cy + 2, '#fff'); })],
  ['گل مروارید', 150, () => frame(26, 26, '#f3f0f5', '#ffffff', (g, x, y, w, h) => { g.R(x, y, w, h, '#bfe6c4'); const cx = x + w / 2 | 0, cy = y + h / 2 - 1 | 0; g.R(cx, cy + 3, 1, h / 2 | 0, '#3f8f3f'); for (let a = 0; a < 8; a++) { const t = a / 8 * Math.PI * 2; g.E(cx + Math.round(Math.cos(t) * 4), cy + Math.round(Math.sin(t) * 4), 1, 1, '#ffffff'); } g.E(cx, cy, 2, 2, '#ffc93a'); })],
  ['ماه و ستاره', 240, () => frame(28, 28, '#3a2a6a', '#cbbce8', (g, x, y, w, h) => { g.R(x, y, w, h, '#14183a'); g.E(x + 7, y + 8, 4, 4, '#ffe9a0'); g.E(x + 9, y + 7, 3, 3, '#14183a'); for (const [a, b] of [[14, 4], [18, 9], [10, 15], [16, 17], [4, 17], [19, 3]]) { g.P(x + a, y + b, '#fff'); } g.P(x + 15, y + 4, '#fff'); g.P(x + 14, y + 5, '#fff'); g.P(x + 16, y + 5, '#fff'); g.P(x + 14, y + 3, '#fff'); })],
  ['خط افق شهر', 280, () => frame(36, 24, '#4a4f5c', '#d8dbe3', (g, x, y, w, h) => { g.R(x, y, w, h, '#2a2f5e'); for (let i = 0; i < 6; i++) { const bh = 6 + (i * 5 % 9), bx = x + i * 5; g.R(bx, y + h - bh, 5, bh, i % 2 ? '#3a3f6e' : '#1f2350'); for (let j = 0; j < bh - 2; j += 3) g.P(bx + 1 + (j % 2) * 2, y + h - bh + 1 + j, '#ffd27a'); } g.P(x + w - 4, y + 3, '#fff'); g.E(x + w - 6, y + 4, 2, 2, '#fff4c0'); })],
  ['درخت تنها', 190, () => frame(26, 30, '#a8703a', '#f6ecd2', (g, x, y, w, h) => { g.R(x, y, w, h, '#a8dcff'); g.R(x, y + h - 5, w, 5, '#58b868'); const cx = x + w / 2 | 0; g.R(cx - 1, y + h - 12, 3, 8, '#7a4a2a'); g.E(cx, y + h - 15, 6, 5, '#2f9a55'); g.E(cx - 2, y + h - 17, 3, 2, '#58c87c'); g.E(x + 4, y + 4, 3, 1, '#fff'); })],
  ['قلب صورتی', 170, () => frame(24, 24, '#c2185b', '#ffe4ee', (g, x, y, w, h) => { g.R(x, y, w, h, '#ffc1d6'); const cx = x + w / 2 | 0, cy = y + h / 2 - 1 | 0; g.E(cx - 2, cy - 1, 2, 2, '#e53a5a'); g.E(cx + 2, cy - 1, 2, 2, '#e53a5a'); g.R(cx - 4, cy, 8, 2, '#e53a5a'); g.R(cx - 3, cy + 2, 6, 1, '#e53a5a'); g.R(cx - 1, cy + 3, 2, 1, '#e53a5a'); g.P(cx - 3, cy - 2, '#ff9ab0'); })],
  ['نقاشی انتزاعی', 320, () => frame(30, 30, '#d9d9d9', '#ffffff', (g, x, y, w, h) => { g.R(x, y, w, h, '#f4f4f4'); g.R(x, y, 9, 11, '#d62f2f'); g.R(x + 11, y, w - 11, 7, '#2f5fd6'); g.R(x + 11, y + 9, w - 11, h - 9, '#ffd23a'); g.R(x, y + 13, 9, h - 13, '#f4f4f4'); g.R(x + 9, y, 2, h, '#202228'); g.R(x, y + 11, w, 2, '#202228'); g.R(x + 11, y + 7, w - 11, 2, '#202228'); g.R(x + 2, y + 16, 5, 6, '#2f5fd6'); })],
  ['عکس خانوادگی', 350, () => frame(36, 26, '#6b3a22', '#f4e8d0', (g, x, y, w, h) => { g.R(x, y, w, h, '#b8d8a8'); g.R(x, y + h - 4, w, 4, '#6fae5f'); const c = (cx, cy, r, s, hc) => { g.E(cx, cy, r, r, '#f2c6a0'); g.R(cx - r, cy - r, r * 2 + 1, 2, hc); g.R(cx - r - 1, cy + r + 1, r * 2 + 3, 5, s); g.P(cx - 1, cy, '#2a1d1a'); g.P(cx + 1, cy, '#2a1d1a'); }; c(x + 8, y + 6, 3, '#4a7fd6', '#4a2a1a'); c(x + 17, y + 7, 3, '#d6507a', '#2a1a10'); c(x + 25, y + 9, 2, '#ffd23a', '#c98a3a'); })],
];
FRAMES[0][3] = null;

// ------------------------------------------------------------------ فرش (۱۰) — دید از بالا با پرسپکتیو کف (کم‌ارتفاع)
function rugRect(w, h, base, border, inner) { return spr(w, h, g => { g.R(0, 0, w, h, border); g.R(2, 2, w - 4, h - 4, base); g.R(2, 2, w - 4, 1, lt(base, 0.18)); inner && inner(g, w, h); for (let x = 1; x < w; x += 3) { g.P(x, 0, dk(border, 0.25)); g.P(x, h - 1, dk(border, 0.25)); } }); }
const RUGS = [
  ['فرش گرد قرمز', 220, () => spr(64, 28, g => { g.E(32, 14, 31, 13, '#a82a3a'); g.E(32, 14, 27, 11, '#d6495a'); g.E(32, 14, 21, 8, '#f6e4c8'); g.E(32, 14, 16, 6, '#d6495a'); g.E(32, 14, 8, 3, '#f6e4c8'); g.E(32, 13, 25, 9, 'rgba(255,255,255,0.08)'); })],
  ['فرش آبی لوزی', 260, () => rugRect(72, 30, '#2f5fb8', '#f1e6cc', (g, w, h) => { for (let i = 0; i < 5; i++) { const cx = 10 + i * 13, cy = h / 2 | 0; for (let k = -6; k <= 6; k++) g.R(cx - (6 - Math.abs(k)), cy + (k >> 1), (6 - Math.abs(k)) * 2 + 1, 1, i % 2 ? '#ffd23a' : '#8fc4f2'); } })],
  ['فرش راه‌راه رنگین‌کمان', 200, () => spr(66, 28, g => { const cs = ['#e53a3a', '#ff9a2a', '#ffd23a', '#4faa62', '#3a8fe5', '#8a4ad6']; g.R(0, 0, 66, 28, '#f6f1e6'); cs.forEach((c, i) => g.R(2, 2 + i * 4, 62, 4, c)); g.R(2, 2, 62, 1, 'rgba(255,255,255,0.3)'); for (let y = 1; y < 28; y += 2) { g.P(0, y, '#d9d2c2'); g.P(65, y, '#d9d2c2'); } })],
  ['فرش چهارخانه سبز', 180, () => rugRect(64, 28, '#58b868', '#2f7a3f', (g, w, h) => { for (let j = 0; j < h - 4; j += 5) for (let i = 0; i < w - 4; i += 5) if (((i + j) / 5 | 0) % 2 === 0) g.R(2 + i, 2 + j, 5, 5, '#f1f6e8'); })],
  ['فرش ایرانی', 600, () => rugRect(80, 34, '#8a1f2b', '#d9b24a', (g, w, h) => { g.R(5, 5, w - 10, h - 10, '#a8283a'); g.R(6, 6, w - 12, 1, '#c8485a'); g.E(w / 2 | 0, h / 2 | 0, 14, 7, '#1f3a6a'); g.E(w / 2 | 0, h / 2 | 0, 10, 5, '#d9b24a'); g.E(w / 2 | 0, h / 2 | 0, 6, 3, '#8a1f2b'); g.P(w / 2 | 0, h / 2 | 0, '#f6e4c8'); for (const x of [12, 18, 54, 60]) { g.R(x, 8, 3, 3, '#1f3a6a'); g.R(x, h - 11, 3, 3, '#1f3a6a'); } for (let x = 8; x < w - 8; x += 4) { g.P(x, 3, '#1f3a6a'); g.P(x, h - 4, '#1f3a6a'); } })],
  ['فرش قلبی صورتی', 240, () => spr(56, 32, g => { g.E(15, 12, 13, 11, '#e85a8a'); g.E(41, 12, 13, 11, '#e85a8a'); for (let r = 0; r < 18; r++) g.R(2 + (r * 26 / 18 | 0), 14 + r, 52 - (r * 26 / 18 | 0) * 2, 1, '#e85a8a'); g.E(15, 12, 9, 7, '#ff8fb1'); g.E(41, 12, 9, 7, '#ff8fb1'); for (let r = 0; r < 12; r++) g.R(8 + (r * 20 / 12 | 0), 14 + r, 40 - (r * 20 / 12 | 0) * 2, 1, '#ff8fb1'); g.R(8, 6, 6, 2, '#ffd0e0'); })],
  ['فرش ستاره‌ای زرد', 240, () => spr(60, 32, g => { const cx = 30, cy = 16; const pts = []; for (let i = 0; i < 10; i++) { const r = i % 2 ? 7 : 15, t = -Math.PI / 2 + i * Math.PI / 5; pts.push([cx + Math.cos(t) * r * 1.9, cy + Math.sin(t) * r * 0.95]); } for (let y = 0; y < 32; y++) for (let x = 0; x < 60; x++) { let c = false; for (let i = 0, j = 9; i < 10; j = i++) if ((pts[i][1] > y) !== (pts[j][1] > y) && x < (pts[j][0] - pts[i][0]) * (y - pts[i][1]) / (pts[j][1] - pts[i][1]) + pts[i][0]) c = !c; if (c) g.P(x, y, y < 16 ? '#ffd23a' : '#f2b01a'); } g.E(cx, cy, 5, 3, '#fff0a0'); })],
  ['فرش پشمی قهوه‌ای', 350, () => spr(64, 30, g => { g.E(32, 15, 31, 14, '#7a5238'); g.E(32, 15, 28, 12, '#9a6c4a'); g.E(30, 13, 22, 8, '#b4825c'); for (let a = 0; a < 40; a++) { const t = a / 40 * Math.PI * 2; g.P(32 + Math.round(Math.cos(t) * 31), 15 + Math.round(Math.sin(t) * 14), '#b4825c'); } for (const [x, y] of [[14, 12], [22, 18], [30, 10], [40, 16], [48, 12], [34, 20], [20, 9]]) { g.L(x, y, x + 2, y - 1, '#d4a27a'); } })],
  ['فرش بنفش لوزی', 260, () => spr(64, 28, g => { g.E(32, 14, 31, 13, '#5a2f8f'); g.E(32, 14, 28, 11, '#8a55c8'); for (let i = 0; i < 6; i++) { const cx = 10 + i * 9; for (let k = -4; k <= 4; k++) g.R(cx - (4 - Math.abs(k)), 14 + (k >> 1) * 1 + k % 2 * 0, (4 - Math.abs(k)) * 2 + 1, 1, i % 2 ? '#e6d4ff' : '#c9a8f0'); } g.E(32, 14, 28, 11, 'rgba(255,255,255,0.0)'); })],
  ['فرش رد پا', 280, () => spr(60, 30, g => { g.E(30, 15, 29, 13, '#6b7280'); g.E(30, 15, 26, 11, '#a3aab8'); for (const [cx, cy] of [[16, 15], [30, 11], [44, 16]]) { g.E(cx, cy + 2, 4, 3, '#4a4f5c'); for (const [dx, dy] of [[-5, -2], [-2, -5], [2, -5], [5, -2]]) g.E(cx + dx, cy + dy, 1, 1, '#4a4f5c'); } })],
];

// ------------------------------------------------------------------ ساعت دیواری (۵) — عقربه‌ها پویا (ساعتِ واقعی)
function clockFace(g, cx, cy, r, ring, face, ticks) { g.E(cx, cy, r, r, ring); g.E(cx, cy, r - 2, r - 2, face); for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) g.R(cx + dx * (r - 3) - (dx === 0 ? 0 : 0), cy + dy * (r - 3), 1, 1, ticks); for (let a = 0; a < 12; a++) { const t = a / 12 * Math.PI * 2; g.P(cx + Math.round(Math.sin(t) * (r - 3)), cy - Math.round(Math.cos(t) * (r - 3)), ticks); } }
const CLOCKS = [
  ['ساعت گرد سفید', 180, () => spr(24, 24, g => clockFace(g, 12, 12, 11, '#2a2f3a', '#fafafa', '#2a2f3a')), { kind: 'analog', cx: 12, cy: 12, r: 8, hc: '#2a2f3a', mc: '#2a2f3a', sc: '#d62f2f' }],
  ['ساعت چوبی مربعی', 260, () => spr(26, 26, g => { g.R(0, 0, 26, 26, '#a8703a'); g.R(1, 1, 24, 1, '#d9a064'); g.R(2, 2, 22, 22, '#6b4423'); g.R(3, 3, 20, 20, '#f6ecd2'); for (const [x, y] of [[13, 4], [13, 21], [4, 13], [21, 13]]) g.R(x, y, 1, 2, '#6b4423'); for (const [x, y] of [[8, 6], [18, 6], [8, 19], [18, 19], [6, 9], [20, 9], [6, 16], [20, 16]]) g.P(x, y, '#a8703a'); }), { kind: 'analog', cx: 13, cy: 13, r: 8, hc: '#4a2a14', mc: '#4a2a14', sc: '#c8344a' }],
  ['ساعت طلایی', 480, () => spr(30, 30, g => { g.E(15, 15, 14, 14, '#d9b24a'); g.E(15, 15, 12, 12, '#f2d27a'); g.E(15, 15, 10, 10, '#fffaf0'); for (let a = 0; a < 12; a++) { const t = a / 12 * Math.PI * 2; g.E(15 + Math.round(Math.sin(t) * 12.5), 15 - Math.round(Math.cos(t) * 12.5), 1, 1, '#b8892a'); } for (let a = 0; a < 12; a++) { const t = a / 12 * Math.PI * 2; g.P(15 + Math.round(Math.sin(t) * 8), 15 - Math.round(Math.cos(t) * 8), a % 3 ? '#b8892a' : '#2a1d1a'); } g.E(15, 1, 2, 1, '#d9b24a'); g.R(12, 0, 7, 1, '#f2d27a'); }), { kind: 'analog', cx: 15, cy: 15, r: 8, hc: '#2a1d1a', mc: '#2a1d1a', sc: '#c8344a' }],
  ['ساعت دیجیتال', 220, () => spr(32, 16, g => { g.R(0, 0, 32, 16, '#2b2f3a'); g.R(1, 1, 30, 1, '#4a5062'); g.R(2, 3, 28, 11, '#0f1a14'); g.R(3, 4, 26, 1, '#16281e'); g.P(1, 14, '#d62f2f'); }), { kind: 'digital', x: 4, y: 5 }],
  ['ساعت آونگی', 520, () => spr(22, 50, g => { g.R(2, 0, 18, 4, '#8a5a30'); g.R(4, 4, 14, 3, '#a8703a'); g.R(3, 7, 16, 42, '#a8703a'); g.R(3, 7, 2, 42, '#c98d52'); g.R(17, 7, 2, 42, '#6b4423'); g.E(11, 14, 6, 6, '#6b4423'); g.E(11, 14, 5, 5, '#fffaf0'); for (let a = 0; a < 12; a += 3) { const t = a / 12 * Math.PI * 2; g.P(11 + Math.round(Math.sin(t) * 4), 14 - Math.round(Math.cos(t) * 4), '#2a1d1a'); } g.R(6, 24, 10, 22, '#3a2415'); g.R(7, 25, 8, 20, '#caa070'); g.R(2, 47, 18, 3, '#6b4423'); }), { kind: 'pendulum', cx: 11, cy: 14, r: 4, px: 11, py: 26, len: 14, hc: '#2a1d1a', mc: '#2a1d1a' }],
];
const DIGITS = ['111101101101111', '010110010010111', '111001111100111', '111001111001111', '101101111001001', '111100111001111', '111100111101111', '111001001001001', '111101111101111', '111101111001111'];
function drawDigit(ctx, d, x, y, col) { ctx.fillStyle = col; const m = DIGITS[d]; for (let i = 0; i < 15; i++) if (m[i] === '1') ctx.fillRect(x + (i % 3), y + ((i / 3) | 0), 1, 1); }
function clockDyn(ctx, spec, ox, oy, now) {
  const hh = now.getHours(), mm = now.getMinutes(), ss = now.getSeconds();
  const px = (x, y, c) => { ctx.fillStyle = c; ctx.fillRect(ox + 1 + x, oy + 1 + y, 1, 1); };
  const line = (x0, y0, x1, y1, c) => { let dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, e = dx + dy; for (;;) { px(x0, y0, c); if (x0 === x1 && y0 === y1) break; const e2 = 2 * e; if (e2 >= dy) { e += dy; x0 += sx; } if (e2 <= dx) { e += dx; y0 += sy; } } };
  if (spec.kind === 'digital') {
    const d = [(hh / 10) | 0, hh % 10, (mm / 10) | 0, mm % 10];
    drawDigit(ctx, d[0], ox + 1 + spec.x, oy + 1 + spec.y, '#5dff9a'); drawDigit(ctx, d[1], ox + 1 + spec.x + 4, oy + 1 + spec.y, '#5dff9a');
    if (ss % 2 === 0) { px(spec.x + 9, spec.y + 1, '#5dff9a'); px(spec.x + 9, spec.y + 3, '#5dff9a'); }
    drawDigit(ctx, d[2], ox + 1 + spec.x + 12, oy + 1 + spec.y, '#5dff9a'); drawDigit(ctx, d[3], ox + 1 + spec.x + 16, oy + 1 + spec.y, '#5dff9a');
    return;
  }
  const am = (mm + ss / 60) / 60 * Math.PI * 2, ah = ((hh % 12) + mm / 60) / 12 * Math.PI * 2;
  line(spec.cx, spec.cy, spec.cx + Math.round(Math.sin(ah) * (spec.r - 3)), spec.cy - Math.round(Math.cos(ah) * (spec.r - 3)), spec.hc);
  line(spec.cx, spec.cy, spec.cx + Math.round(Math.sin(am) * (spec.r - 0.5)), spec.cy - Math.round(Math.cos(am) * (spec.r - 0.5)), spec.mc);
  if (spec.sc) { const as = ss / 60 * Math.PI * 2; line(spec.cx, spec.cy, spec.cx + Math.round(Math.sin(as) * spec.r), spec.cy - Math.round(Math.cos(as) * spec.r), spec.sc); }
  px(spec.cx, spec.cy, '#2a1d1a');
  if (spec.kind === 'pendulum') { const sw = Math.round(Math.sin(Date.now() / 1000 * Math.PI) * 3); line(spec.px, spec.py, spec.px + sw, spec.py + spec.len, '#d9b24a'); for (const [dx, dy] of [[-1, 0], [0, 0], [1, 0], [-1, 1], [0, 1], [1, 1]]) px(spec.px + sw + dx, spec.py + spec.len + dy, '#f2d27a'); }
}

// ------------------------------------------------------------------ فهرستِ آیتم‌ها
const CATS = [['plant', 'گل و گلدان'], ['table', 'میز'], ['bed', 'تخت'], ['frame', 'قاب عکس'], ['rug', 'فرش'], ['clock', 'ساعت دیواری']];
const ZONE = { plant: 'free', table: 'floor', bed: 'floor', frame: 'wall', rug: 'floor', clock: 'wall' };
const CATALOG = [];
[['plant', PLANTS], ['table', TABLES], ['bed', BEDS], ['frame', FRAMES], ['rug', RUGS], ['clock', CLOCKS]].forEach(([cat, list]) => list.forEach((it, i) => CATALOG.push({ id: cat + '_' + String(i + 1).padStart(2, '0'), cat, name: it[0], price: it[1], make: it[2], dyn: it[3] || null, zone: ZONE[cat], anchor: ZONE[cat] === 'wall' ? 'center' : 'bottom' })));
const SPR = {};
function spriteOf(id) { return SPR[id] || (SPR[id] = CATALOG.find(c => c.id === id).make()); }
