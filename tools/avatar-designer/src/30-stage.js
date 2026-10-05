'use strict';
// ===== صحنه (Canvas): زوم/جابه‌جایی/شبکه/خط‌کش/راهنما/ناحیه‌ی امن/دستگیره‌های جابه‌جایی-مقیاس-چرخش =====

const S = { tool: 'select', cat: 'body', leftTab: 'assets', rightTab: 'layers', bottomTab: 'parts', famId: null, partId: null, varId: null, bgId: null, scope: 'auto', partMode: false, onlyCompat: true, space: false, drag: null, sizeW: 0, sizeH: 0 };
const ST = { cv: null, ctx: null, off: null, pointers: new Map(), pinch: null };
const RULER = 18;

const selFam = () => (S.famId ? famById(S.famId) : null);
const selPart = () => { const f = selFam(); return f ? f.parts.find(p => p.id === S.partId) || null : null; };
function layerOfFam(famId) { for (const L of P.layers) { const e = P.scene.equipped[L.id]; if (e && e.familyId === famId) return L; } return null; }
function toScreen(x, y) { const v = P.view; return [v.panX + x * v.zoom, v.panY + y * v.zoom]; }
function toScene(sx, sy) { const v = P.view; return [(sx - v.panX) / v.zoom, (sy - v.panY) / v.zoom]; }

function geomKey(fam) {
  const c = P.scene.characterId;
  if (S.scope === 'char' && c) return c;
  if (S.scope === 'auto' && c && fam.geometry[c]) return c;
  return '*';
}
function setGeom(fam, patch) {
  const k = geomKey(fam);
  fam.geometry[k] = Object.assign(fam.geometry[k] || (k === '*' ? newGeometry() : {}), patch);
}
function selItem() {
  const f = selFam();
  if (!f) return null;
  return sceneItems().find(it => it.fam.id === f.id) || null;
}

function fitView() {
  const r = ST.cv.getBoundingClientRect();
  const z = Math.max(1, Math.floor(Math.min((r.width - RULER - 40) / P.canvas.w, (r.height - RULER - 40) / P.canvas.h) * 2) / 2);
  P.view.zoom = z;
  P.view.panX = Math.round(RULER + (r.width - RULER - P.canvas.w * z) / 2);
  P.view.panY = Math.round(RULER + (r.height - RULER - P.canvas.h * z) / 2);
}
function zoomAt(sx, sy, factor) {
  const v = P.view, [x, y] = toScene(sx, sy);
  v.zoom = clamp(v.zoom * factor, 1, 32);
  v.panX = sx - x * v.zoom; v.panY = sy - y * v.zoom;
  renderStage();
}

function initStage() {
  const cv = (ST.cv = $('#stage'));
  ST.ctx = cv.getContext('2d');
  ST.off = mkCanvas(1, 1);
  new ResizeObserver(() => { const r = cv.getBoundingClientRect(); const d = devicePixelRatio || 1; cv.width = Math.round(r.width * d); cv.height = Math.round(r.height * d); if (P) renderStage(); }).observe(cv);
  cv.addEventListener('pointerdown', onDown);
  cv.addEventListener('pointermove', onMove);
  cv.addEventListener('pointerup', onUp);
  cv.addEventListener('pointercancel', onUp);
  cv.addEventListener('wheel', e => { e.preventDefault(); const r = cv.getBoundingClientRect(); zoomAt(e.clientX - r.left, e.clientY - r.top, e.deltaY < 0 ? 1.15 : 1 / 1.15); }, { passive: false });
  cv.addEventListener('contextmenu', e => e.preventDefault());
}

// ---------------------------------------------------------------- رسم
function renderStage() {
  if (!ST.cv || !P) return;
  const cv = ST.cv, ctx = ST.ctx, d = devicePixelRatio || 1, W = cv.width / d, H = cv.height / d, v = P.view, z = v.zoom;
  ctx.setTransform(d, 0, 0, d, 0, 0);
  ctx.fillStyle = '#0b0d12'; ctx.fillRect(0, 0, W, H);
  const cw = P.canvas.w, ch = P.canvas.h;
  // زمینه‌ی شطرنجی (نشان‌دهنده‌ی شفافیت)
  ctx.save(); ctx.beginPath(); ctx.rect(v.panX, v.panY, cw * z, ch * z); ctx.clip();
  const cs = 8 * z;
  for (let y = 0; y * cs < ch * z; y++) for (let x = 0; x * cs < cw * z; x++) { ctx.fillStyle = (x + y) % 2 ? '#1a1e29' : '#222836'; ctx.fillRect(v.panX + x * cs, v.panY + y * cs, cs, cs); }
  ST.off.width = cw; ST.off.height = ch;
  const o = ST.off.getContext('2d'); o.clearRect(0, 0, cw, ch);
  drawScene(o, { onLoad: renderStage });
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(ST.off, v.panX, v.panY, cw * z, ch * z);
  ctx.restore();
  ctx.strokeStyle = '#4a5270'; ctx.lineWidth = 1; ctx.strokeRect(v.panX - 0.5, v.panY - 0.5, cw * z + 1, ch * z + 1);

  const line = (x0, y0, x1, y1, col, dash) => { ctx.beginPath(); ctx.setLineDash(dash || []); ctx.strokeStyle = col; ctx.moveTo(x0, y0); ctx.lineTo(x1, y1); ctx.stroke(); ctx.setLineDash([]); };
  if (v.showGrid && v.grid * z >= 5) {
    ctx.globalAlpha = 0.22;
    for (let x = 0; x <= cw; x += v.grid) { const [sx] = toScreen(x, 0); line(Math.round(sx) + 0.5, v.panY, Math.round(sx) + 0.5, v.panY + ch * z, '#8d96ad'); }
    for (let y = 0; y <= ch; y += v.grid) { const [, sy] = toScreen(0, y); line(v.panX, Math.round(sy) + 0.5, v.panX + cw * z, Math.round(sy) + 0.5, '#8d96ad'); }
    ctx.globalAlpha = 1;
  }
  if (v.showSafe) { const s = P.canvas.safe, [sx, sy] = toScreen(s.x, s.y); ctx.strokeStyle = '#e7b34a'; ctx.setLineDash([5, 4]); ctx.strokeRect(sx + 0.5, sy + 0.5, s.w * z, s.h * z); ctx.setLineDash([]); }
  if (v.showCenter) { const [cx, cy] = toScreen(cw / 2, ch / 2); line(cx + 0.5, v.panY, cx + 0.5, v.panY + ch * z, '#3fb97b', [3, 3]); line(v.panX, cy + 0.5, v.panX + cw * z, cy + 0.5, '#3fb97b55', [3, 3]); }
  for (const g of v.guides) { if (g.axis === 'v') { const [sx] = toScreen(g.pos, 0); line(Math.round(sx) + 0.5, 0, Math.round(sx) + 0.5, H, '#e5564f'); } else { const [, sy] = toScreen(0, g.pos); line(0, Math.round(sy) + 0.5, W, Math.round(sy) + 0.5, '#e5564f'); } }

  const items = sceneItems();
  if (v.showLayerBoxes) for (const it of items) { const q = itemQuad(it).map(p => toScreen(...p)); poly(ctx, q, '#7c8cff66', 1, [3, 3]); ctx.fillStyle = '#7c8cffcc'; ctx.font = '10px system-ui'; ctx.fillText(it.layer.name, q[0][0] + 2, q[0][1] - 2); }
  const si = selItem();
  if (si) {
    const q = itemQuad(si).map(p => toScreen(...p));
    poly(ctx, q, '#ffffff', 1.5, []);
    const hs = handles(si);
    if (!si.layer.locked) { for (const k of ['tl', 'tr', 'br', 'bl']) box(ctx, hs[k], '#fff'); line(...hs.tc, ...hs.rot, '#fff'); ctx.beginPath(); ctx.arc(hs.rot[0], hs.rot[1], 5, 0, 7); ctx.fillStyle = '#7c8cff'; ctx.fill(); }
    const [ax, ay] = toScreen(si.g.x, si.g.y); line(ax - 6, ay, ax + 6, ay, '#ff5fd0'); line(ax, ay - 6, ax, ay + 6, '#ff5fd0');
    if (S.partMode) { const pt = selPart(); if (pt) { const m = itemMatrix(si); poly(ctx, partCorners(pt).map(c => toScreen(...m(...c))), '#3fb97b', 2, []); } }
  }
  if (v.showRuler) rulers(ctx, W, H);
  const hud = $('#zoomlbl'); if (hud) hud.textContent = Math.round(z * 100) + '%';
}
function poly(ctx, pts, col, w, dash) { ctx.beginPath(); ctx.setLineDash(dash); ctx.strokeStyle = col; ctx.lineWidth = w; pts.forEach((p, i) => (i ? ctx.lineTo(...p) : ctx.moveTo(...p))); ctx.closePath(); ctx.stroke(); ctx.setLineDash([]); ctx.lineWidth = 1; }
function box(ctx, p, col) { ctx.fillStyle = col; ctx.strokeStyle = '#000'; ctx.fillRect(p[0] - 4, p[1] - 4, 8, 8); ctx.strokeRect(p[0] - 4.5, p[1] - 4.5, 9, 9); }
function handles(it) {
  const q = itemQuad(it).map(p => toScreen(...p));
  const tc = [(q[0][0] + q[1][0]) / 2, (q[0][1] + q[1][1]) / 2];
  const bc = [(q[2][0] + q[3][0]) / 2, (q[2][1] + q[3][1]) / 2];
  let dx = tc[0] - bc[0], dy = tc[1] - bc[1]; const L = Math.hypot(dx, dy) || 1;
  return { tl: q[0], tr: q[1], br: q[2], bl: q[3], tc, rot: [tc[0] + (dx / L) * 22, tc[1] + (dy / L) * 22] };
}
function rulers(ctx, W, H) {
  const v = P.view, z = v.zoom;
  ctx.fillStyle = '#171a23'; ctx.fillRect(0, 0, W, RULER); ctx.fillRect(0, 0, RULER, H);
  ctx.fillStyle = '#8d96ad'; ctx.strokeStyle = '#4a5270'; ctx.font = '9px system-ui';
  const step = z >= 8 ? 4 : z >= 4 ? 8 : z >= 2 ? 16 : 32;
  for (let x = 0; x <= P.canvas.w; x += step) { const [sx] = toScreen(x, 0); ctx.beginPath(); ctx.moveTo(sx + 0.5, RULER - (x % (step * 2) ? 5 : 9)); ctx.lineTo(sx + 0.5, RULER); ctx.stroke(); if (x % (step * 2) === 0) ctx.fillText(x, sx + 2, 9); }
  for (let y = 0; y <= P.canvas.h; y += step) { const [, sy] = toScreen(0, y); ctx.beginPath(); ctx.moveTo(RULER - (y % (step * 2) ? 5 : 9), sy + 0.5); ctx.lineTo(RULER, sy + 0.5); ctx.stroke(); if (y % (step * 2) === 0) ctx.fillText(y, 1, sy - 2); }
  ctx.fillStyle = '#171a23'; ctx.fillRect(0, 0, RULER, RULER);
}

// ---------------------------------------------------------------- تعامل
function pos(e) { const r = ST.cv.getBoundingClientRect(); return [e.clientX - r.left, e.clientY - r.top]; }
function snapPos(x, y, noMagnet) {
  const v = P.view;
  x = Math.round(x); y = Math.round(y);
  if (!v.snap || noMagnet) return [x, y];
  const th = 4 / v.zoom, cands = { x: [P.canvas.w / 2], y: [P.canvas.h / 2] };
  for (let k = 0; k <= P.canvas.w; k += v.grid) cands.x.push(k);
  for (let k = 0; k <= P.canvas.h; k += v.grid) cands.y.push(k);
  for (const g of v.guides) cands[g.axis === 'v' ? 'x' : 'y'].push(g.pos);
  for (const c of cands.x) if (Math.abs(c - x) <= th) { x = c; break; }
  for (const c of cands.y) if (Math.abs(c - y) <= th) { y = c; break; }
  return [x, y];
}
function onDown(e) {
  if (!P) return;
  ST.cv.setPointerCapture(e.pointerId);
  const [sx, sy] = pos(e);
  ST.pointers.set(e.pointerId, [sx, sy]);
  if (ST.pointers.size === 2) { const [a, b] = [...ST.pointers.values()]; ST.pinch = { d: Math.hypot(a[0] - b[0], a[1] - b[1]), zoom: P.view.zoom, mx: (a[0] + b[0]) / 2, my: (a[1] + b[1]) / 2 }; S.drag = null; return; }
  const v = P.view;
  if (v.showRuler && (sx < RULER || sy < RULER) && !(sx < RULER && sy < RULER)) {
    const g = { axis: sx < RULER ? 'v' : 'h', pos: 0 }; v.guides.push(g); S.drag = { type: 'guide', g, fresh: true }; return;
  }
  const [px, py] = toScene(sx, sy);
  if (e.button === 1 || S.space || S.tool === 'pan') { S.drag = { type: 'pan', sx, sy, px: v.panX, py: v.panY }; return; }
  for (const g of v.guides) { const gp = g.axis === 'v' ? toScreen(g.pos, 0)[0] : toScreen(0, g.pos)[1]; if (Math.abs((g.axis === 'v' ? sx : sy) - gp) < 4) { S.drag = { type: 'guide', g }; return; } }
  const si = selItem();
  if (si && !si.layer.locked) {
    const hs = handles(si), near = p => Math.hypot(p[0] - sx, p[1] - sy) <= 9;
    const [ax, ay] = toScreen(si.g.x, si.g.y);
    if (near(hs.rot)) { S.drag = { type: 'rotate', fam: si.fam, g0: { ...si.g }, ax, ay }; return; }
    for (const k of ['tl', 'tr', 'br', 'bl']) if (near(hs[k])) { S.drag = { type: 'scale', fam: si.fam, g0: { ...si.g }, ax, ay, d0: Math.hypot(sx - ax, sy - ay) || 1 }; return; }
    if (S.partMode && selPart()) {
      const pt = selPart(), m = itemMatrix(si);
      if (pointInPoly(sx, sy, partCorners(pt).map(c => toScreen(...m(...c))))) { S.drag = { type: 'part', si, pt, px, py, d0: [pt.dx, pt.dy], moved: false }; return; }
    }
  }
  const hit = hitItems(px, py);
  if (hit) {
    S.famId = hit.fam.id; S.varId = hit.variant.id; if (S.partId && !hit.fam.parts.some(p => p.id === S.partId)) S.partId = null;
    S.drag = hit.layer.locked ? null : { type: 'move', fam: hit.fam, g0: { ...hit.g }, px, py, moved: false };
    renderPanelsOnly();
  } else {
    if (S.famId) { S.famId = null; S.partId = null; renderPanelsOnly(); }
    S.drag = { type: 'pan', sx, sy, px: v.panX, py: v.panY };
  }
  renderStage();
}
function pointInPoly(x, y, q) { let c = false; for (let i = 0, j = q.length - 1; i < q.length; j = i++) if ((q[i][1] > y) !== (q[j][1] > y) && x < ((q[j][0] - q[i][0]) * (y - q[i][1])) / (q[j][1] - q[i][1]) + q[i][0]) c = !c; return c; }
function onMove(e) {
  if (!P) return;
  const [sx, sy] = pos(e);
  if (ST.pointers.has(e.pointerId)) ST.pointers.set(e.pointerId, [sx, sy]);
  if (ST.pinch && ST.pointers.size === 2) {
    const [a, b] = [...ST.pointers.values()], d = Math.hypot(a[0] - b[0], a[1] - b[1]);
    const v = P.view, [x, y] = toScene(ST.pinch.mx, ST.pinch.my); v.zoom = clamp(ST.pinch.zoom * (d / ST.pinch.d), 1, 32); v.panX = ST.pinch.mx - x * v.zoom; v.panY = ST.pinch.my - y * v.zoom; renderStage(); return;
  }
  const [px, py] = toScene(sx, sy);
  const hudp = $('#coords'); if (hudp) hudp.textContent = `x ${Math.round(px)}  y ${Math.round(py)}`;
  const d = S.drag; if (!d) return;
  if (d.type === 'pan') { P.view.panX = d.px + sx - d.sx; P.view.panY = d.py + sy - d.sy; }
  else if (d.type === 'guide') { const [x, y] = toScene(sx, sy); d.g.pos = Math.round(d.g.axis === 'v' ? x : y); d.moved = true; }
  else if (d.type === 'move') { const [nx, ny] = snapPos(d.g0.x + (px - d.px), d.g0.y + (py - d.py), e.altKey); d.moved = true; setGeom(d.fam, { x: nx, y: ny }); }
  else if (d.type === 'scale') { let s = d.g0.scale * (Math.hypot(sx - d.ax, sy - d.ay) / d.d0); s = P.view.snap ? Math.round(s * 20) / 20 : s; d.moved = true; setGeom(d.fam, { scale: clamp(+s.toFixed(3), 0.1, 8) }); }
  else if (d.type === 'rotate') { let a = (Math.atan2(sy - d.ay, sx - d.ax) * 180) / Math.PI + 90; if (P.view.snap || e.shiftKey) a = Math.round(a / 5) * 5; a = ((a + 540) % 360) - 180; d.moved = true; setGeom(d.fam, { rotation: a }); }
  else if (d.type === 'part') {
    const g = d.si.g, a = (-g.rotation * Math.PI) / 180, dx = px - d.px, dy = py - d.py;
    let X = dx * Math.cos(a) - dy * Math.sin(a), Y = dx * Math.sin(a) + dy * Math.cos(a);
    X /= g.scale * (g.flipX ? -1 : 1); Y /= g.scale * (g.flipY ? -1 : 1);
    d.pt.dx = Math.round(d.d0[0] + X); d.pt.dy = Math.round(d.d0[1] + Y); d.moved = true; invalidateCache();
  }
  renderStage();
  if (d.moved && d.type !== 'pan') liveFields();
}
function onUp(e) {
  ST.pointers.delete(e.pointerId);
  if (ST.pointers.size < 2) ST.pinch = null;
  const d = S.drag; S.drag = null;
  if (!d || !P) return;
  if (d.type === 'guide') {
    const [sx, sy] = pos(e);
    if ((d.g.axis === 'v' && sx < RULER) || (d.g.axis === 'h' && sy < RULER)) P.view.guides = P.view.guides.filter(g => g !== d.g);
    commit('guide'); return;
  }
  if (d.type === 'pan') { scheduleSave(); return; }
  if (d.moved) commit(d.type);
}
function nudge(dx, dy) {
  const f = selFam(); if (!f) return;
  const L = layerOfFam(f.id); if (L && L.locked) return;
  if (S.partMode && selPart()) { selPart().dx += dx; selPart().dy += dy; invalidateCache(); } else { const g = geomFor(f, P.scene.characterId); setGeom(f, { x: g.x + dx, y: g.y + dy }); }
  commit('nudge');
}
