'use strict';
// ===== رندر: اسپرایتِ خانواده/واریانت، صحنه، پس‌زمینه و پیش‌نمایش‌ها =====

const spriteCache = new Map();
const imgCache = new Map();
function invalidateCache() { spriteCache.clear(); }
function mkCanvas(w, h) { const c = document.createElement('canvas'); c.width = Math.max(1, Math.ceil(w)); c.height = Math.max(1, Math.ceil(h)); return c; }
function hexToRgb(hex) { const m = /^#?([0-9a-f]{6})$/i.exec(hex || ''); if (!m) return [255, 0, 255]; const n = parseInt(m[1], 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; }

function partCanvas(f, variant, part) {
  const c = mkCanvas(part.w, part.h);
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(part.w, part.h);
  const cols = {};
  for (let i = 0; i < part.px.length; i++) {
    const s = part.px[i];
    if (!s) continue;
    const sl = f.slots[s - 1];
    if (!sl) continue;
    const col = cols[sl.id] || (cols[sl.id] = hexToRgb(slotColor(f, variant, sl.id, part.id)));
    img.data[i * 4] = col[0]; img.data[i * 4 + 1] = col[1]; img.data[i * 4 + 2] = col[2]; img.data[i * 4 + 3] = 255;
  }
  ctx.putImageData(img, 0, 0);
  return c;
}
function partCorners(pt) {
  const cx = pt.dx + pt.w / 2, cy = pt.dy + pt.h / 2, a = (pt.rotation * Math.PI) / 180, sx = pt.scale * (pt.flipX ? -1 : 1), sy = pt.scale * (pt.flipY ? -1 : 1);
  return [[-pt.w / 2, -pt.h / 2], [pt.w / 2, -pt.h / 2], [pt.w / 2, pt.h / 2], [-pt.w / 2, pt.h / 2]].map(([x, y]) => {
    const X = x * sx, Y = y * sy;
    return [cx + X * Math.cos(a) - Y * Math.sin(a), cy + X * Math.sin(a) + Y * Math.cos(a)];
  });
}
/** اسپرایتِ ترکیبیِ یک خانواده در یک واریانت: {canvas, ox, oy} (ox/oy نسبت به مبدأِ خانواده) */
function familySprite(f, variant) {
  const key = f.id + '|' + variant.id;
  let s = spriteCache.get(key);
  if (s) return s;
  const parts = f.parts.filter(p => p.visible && !(variant.overrides[p.id] && variant.overrides[p.id].visible === false));
  if (!parts.length) { s = { canvas: mkCanvas(1, 1), ox: 0, oy: 0, w: 0, h: 0, empty: true }; spriteCache.set(key, s); return s; }
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  for (const p of parts) for (const [x, y] of partCorners(p)) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  x0 = Math.floor(x0); y0 = Math.floor(y0); x1 = Math.ceil(x1); y1 = Math.ceil(y1);
  const c = mkCanvas(x1 - x0, y1 - y0);
  const ctx = c.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  for (const p of parts) {
    ctx.save();
    ctx.translate(p.dx + p.w / 2 - x0, p.dy + p.h / 2 - y0);
    ctx.rotate((p.rotation * Math.PI) / 180);
    ctx.scale(p.scale * (p.flipX ? -1 : 1), p.scale * (p.flipY ? -1 : 1));
    ctx.drawImage(partCanvas(f, variant, p), -p.w / 2, -p.h / 2);
    ctx.restore();
  }
  s = { canvas: c, ox: x0, oy: y0, w: x1 - x0, h: y1 - y0 };
  spriteCache.set(key, s);
  return s;
}
function anchorPoint(f, s) {
  switch (f.anchor) {
    case 'center': return [s.ox + s.w / 2, s.oy + s.h / 2];
    case 'top-center': return [s.ox + s.w / 2, s.oy];
    case 'bottom-center': return [s.ox + s.w / 2, s.oy + s.h];
    case 'left-center': return [s.ox, s.oy + s.h / 2];
    case 'right-center': return [s.ox + s.w, s.oy + s.h / 2];
    default: return [0, 0];
  }
}

/** فهرستِ آیتم‌های قابل‌رسم صحنه (پایین → بالا) */
function sceneItems() {
  const out = [];
  const charId = P.scene.characterId;
  for (const L of P.layers) {
    if (!L.visible) continue;
    const eq = P.scene.equipped[L.id];
    if (!eq) continue;
    let fam = famById(eq.familyId), vid = eq.variantId;
    if (L.category === 'mouth' && P.moods[P.scene.mood] && famById(P.moods[P.scene.mood].familyId)) { fam = famById(P.moods[P.scene.mood].familyId); vid = P.moods[P.scene.mood].variantId; }
    if (!fam || !compatible(fam, charId)) continue;
    const variant = varOf(fam, vid);
    const spr = familySprite(fam, variant);
    if (spr.empty) continue;
    out.push({ layer: L, fam, variant, spr, g: geomFor(fam, charId) });
  }
  return out;
}
function drawItem(ctx, it, extraAlpha = 1) {
  const { fam, spr, g } = it;
  const [ax, ay] = anchorPoint(fam, spr);
  ctx.save();
  ctx.globalAlpha = clamp(g.opacity, 0, 1) * extraAlpha;
  ctx.translate(g.x, g.y);
  ctx.rotate((g.rotation * Math.PI) / 180);
  ctx.scale(g.scale * (g.flipX ? -1 : 1), g.scale * (g.flipY ? -1 : 1));
  ctx.translate(-ax, -ay);
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(spr.canvas, spr.ox, spr.oy);
  ctx.restore();
}
function itemMatrix(it) {
  // نگاشتِ نقطه‌ی محلیِ اسپرایت (بدون ox/oy) به مختصاتِ صحنه
  const [ax, ay] = anchorPoint(it.fam, it.spr);
  const g = it.g, a = (g.rotation * Math.PI) / 180, sx = g.scale * (g.flipX ? -1 : 1), sy = g.scale * (g.flipY ? -1 : 1);
  return (lx, ly) => { const X = (lx - ax) * sx, Y = (ly - ay) * sy; return [g.x + X * Math.cos(a) - Y * Math.sin(a), g.y + X * Math.sin(a) + Y * Math.cos(a)]; };
}
function itemQuad(it) {
  const m = itemMatrix(it), s = it.spr;
  return [m(s.ox, s.oy), m(s.ox + s.w, s.oy), m(s.ox + s.w, s.oy + s.h), m(s.ox, s.oy + s.h)];
}
function hitItems(px, py) {
  const items = sceneItems();
  for (let i = items.length - 1; i >= 0; i--) {
    const it = items[i];
    const g = it.g, a = (-g.rotation * Math.PI) / 180, [ax, ay] = anchorPoint(it.fam, it.spr);
    const dx = px - g.x, dy = py - g.y;
    let X = dx * Math.cos(a) - dy * Math.sin(a), Y = dx * Math.sin(a) + dy * Math.cos(a);
    X = X / (g.scale * (g.flipX ? -1 : 1)) + ax; Y = Y / (g.scale * (g.flipY ? -1 : 1)) + ay;
    const sx = Math.floor(X - it.spr.ox), sy = Math.floor(Y - it.spr.oy);
    if (sx < 0 || sy < 0 || sx >= it.spr.w || sy >= it.spr.h) continue;
    const d = it.spr.canvas.getContext('2d').getImageData(sx, sy, 1, 1).data;
    if (d[3] > 10) return it;
  }
  return null;
}

// ---------------------------------------------------------------- پس‌زمینه و محیط
function getImg(src, cb) {
  let e = imgCache.get(src);
  if (e) return e.ok ? e.img : null;
  const img = new Image();
  e = { img, ok: false };
  imgCache.set(src, e);
  img.onload = () => { e.ok = true; cb && cb(); };
  img.src = src;
  return null;
}
function drawBackground(ctx, bg, W, H, onLoad) {
  if (!bg) return;
  ctx.save();
  ctx.globalAlpha = clamp(bg.opacity == null ? 1 : bg.opacity, 0, 1);
  if (bg.type === 'gradient') {
    const a = ((bg.angle || 0) * Math.PI) / 180, cx = W / 2, cy = H / 2, r = Math.hypot(W, H) / 2;
    const g = ctx.createLinearGradient(cx - Math.sin(a) * r, cy - Math.cos(a) * r, cx + Math.sin(a) * r, cy + Math.cos(a) * r);
    g.addColorStop(0, bg.color || '#223'); g.addColorStop(1, bg.color2 || '#556');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  } else if (bg.type === 'image' && bg.image) {
    ctx.fillStyle = bg.color || '#000'; ctx.fillRect(0, 0, W, H);
    const im = getImg(bg.image, onLoad);
    if (im) { const s = bg.scale || 1; ctx.imageSmoothingEnabled = false; ctx.drawImage(im, bg.x || 0, bg.y || 0, im.width * s, im.height * s); }
  } else {
    ctx.fillStyle = bg.color || '#334'; ctx.fillRect(0, 0, W, H);
  }
  const pt = bg.pattern;
  if (pt && pt.kind && pt.kind !== 'none') {
    ctx.globalAlpha = clamp(pt.opacity == null ? 0.15 : pt.opacity, 0, 1) * clamp(bg.opacity == null ? 1 : bg.opacity, 0, 1);
    ctx.fillStyle = ctx.strokeStyle = pt.color || '#ffffff';
    const s = Math.max(2, pt.size || 8);
    if (pt.kind === 'dots') for (let y = s / 2; y < H; y += s) for (let x = s / 2; x < W; x += s) ctx.fillRect(Math.floor(x), Math.floor(y), 1, 1);
    else if (pt.kind === 'stripes') for (let x = -H; x < W; x += s) { ctx.beginPath(); ctx.moveTo(x, H); ctx.lineTo(x + H, 0); ctx.lineWidth = 1; ctx.stroke(); }
    else if (pt.kind === 'checker') for (let y = 0; y < H; y += s) for (let x = 0; x < W; x += s) if (((x / s) + (y / s)) % 2 === 0) ctx.fillRect(x, y, s, s);
    else if (pt.kind === 'grid') { for (let x = 0; x < W; x += s) ctx.fillRect(x, 0, 1, H); for (let y = 0; y < H; y += s) ctx.fillRect(0, y, W, 1); }
  }
  const ef = bg.effects || {};
  ctx.globalAlpha = 1;
  if (ef.vignette) { const g = ctx.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.25, W / 2, H / 2, Math.hypot(W, H) / 2); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, `rgba(0,0,0,${clamp(ef.vignette, 0, 1)})`); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); }
  if (ef.scanlines) { ctx.fillStyle = `rgba(0,0,0,${clamp(ef.scanlines, 0, 1)})`; for (let y = 0; y < H; y += 2) ctx.fillRect(0, y, W, 1); }
  if (ef.noise) { let sd = 12345; const rnd = () => ((sd = (sd * 1664525 + 1013904223) >>> 0) / 4294967296); ctx.fillStyle = `rgba(255,255,255,${clamp(ef.noise, 0, 1) * 0.25})`; for (let i = 0; i < (W * H) / 40; i++) ctx.fillRect(Math.floor(rnd() * W), Math.floor(rnd() * H), 1, 1); }
  ctx.restore();
}
function drawEnvironment(ctx, W, H, phase, onLoad) {
  const sc = P.scene;
  if (phase === 'back') {
    if (sc.bgVisible) drawBackground(ctx, P.backgrounds.find(b => b.id === sc.backgroundId), W, H, onLoad);
    if (sc.glow.on) { const g = ctx.createRadialGradient(sc.glow.x, sc.glow.y, 0, sc.glow.x, sc.glow.y, Math.max(2, sc.glow.radius)); g.addColorStop(0, sc.glow.color); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.save(); ctx.globalAlpha = clamp(sc.glow.opacity, 0, 1); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); ctx.restore(); }
    if (sc.ground.on) { ctx.save(); ctx.globalAlpha = clamp(sc.ground.opacity, 0, 1); ctx.fillStyle = sc.ground.color; ctx.fillRect(0, H - sc.ground.height, W, sc.ground.height); ctx.restore(); }
    if (sc.shadow.on) { ctx.save(); ctx.globalAlpha = clamp(sc.shadow.opacity, 0, 1); ctx.fillStyle = sc.shadow.color; ctx.beginPath(); ctx.ellipse(sc.shadow.x, sc.shadow.y, sc.shadow.w / 2, sc.shadow.h / 2, 0, 0, Math.PI * 2); ctx.fill(); ctx.restore(); }
  } else if (sc.lighting.on) {
    const a = (sc.lighting.angle * Math.PI) / 180, r = Math.hypot(W, H) / 2, cx = W / 2, cy = H / 2;
    const g = ctx.createLinearGradient(cx - Math.sin(a) * r, cy - Math.cos(a) * r, cx + Math.sin(a) * r, cy + Math.cos(a) * r);
    g.addColorStop(0, sc.lighting.color); g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.save(); ctx.globalAlpha = clamp(sc.lighting.opacity, 0, 1); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); ctx.restore();
  }
}
/** کلِ صحنه روی ctx (۱ پیکسلِ بوم = ۱ پیکسل) */
function drawScene(ctx, opts = {}) {
  const W = P.canvas.w, H = P.canvas.h;
  drawEnvironment(ctx, W, H, 'back', opts.onLoad);
  for (const it of sceneItems()) drawItem(ctx, it);
  drawEnvironment(ctx, W, H, 'front');
}
function sceneBounds() {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  for (const it of sceneItems()) for (const [x, y] of itemQuad(it)) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  if (!Number.isFinite(x0)) return { x: 0, y: 0, w: P.canvas.w, h: P.canvas.h };
  return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
}
/** پیش‌نمایش در اندازه‌های مختلف */
const PREVIEWS = [
  ['full', 'Full Character', 96, 144], ['inventory', 'Inventory', 64, 64], ['profile', 'Profile', 72, 72], ['icon', 'Small Icon', 32, 32], ['modal', 'Modal', 90, 120],
];
function renderPreview(kind, canvas, withBg = true) {
  const full = mkCanvas(P.canvas.w, P.canvas.h);
  const fx = full.getContext('2d');
  if (withBg) drawScene(fx); else { for (const it of sceneItems()) drawItem(fx, it); }
  const b = sceneBounds();
  let r;
  if (kind === 'full' || kind === 'modal') r = { x: 0, y: 0, w: P.canvas.w, h: P.canvas.h };
  else if (kind === 'inventory') { const s = Math.max(b.w, b.h) + 8; r = { x: b.x + b.w / 2 - s / 2, y: b.y + b.h / 2 - s / 2, w: s, h: s }; }
  else if (kind === 'profile') { const s = Math.max(b.w * 0.55, 24); r = { x: b.x + b.w / 2 - s / 2, y: b.y - 2, w: s, h: s }; }
  else { const s = Math.max(b.w, b.h) + 4; r = { x: b.x + b.w / 2 - s / 2, y: b.y + b.h / 2 - s / 2, w: s, h: s }; }
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  if (kind === 'profile') { ctx.save(); ctx.beginPath(); ctx.arc(canvas.width / 2, canvas.height / 2, canvas.width / 2, 0, Math.PI * 2); ctx.clip(); }
  ctx.drawImage(full, r.x, r.y, r.w, r.h, 0, 0, canvas.width, canvas.height);
  if (kind === 'profile') ctx.restore();
}
