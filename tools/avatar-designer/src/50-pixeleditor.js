'use strict';
// ===== ویرایشگر پیکسلی قطعه: قلم، پاک‌کن، خط، مستطیل، چندضلعی، سطل، انتخاب/جابه‌جایی/کپی/پیست/تکثیر، وارونه/چرخش، تغییر اندازه، Undo/Redo =====

function openPixelEditor(fam, part) {
  const E = { w: part.w, h: part.h, px: new Uint8Array(part.px), tool: 'pencil', slot: 1, size: 1, fill: false, zoom: 16, sel: null, clip: null, hist: [], redo: [], poly: [], drag: null, floating: null };
  const variant = varOf(fam, S.varId);
  const cv = h('canvas', { width: 10, height: 10 });
  const ctx = cv.getContext('2d');
  const prev = h('canvas', { width: 10, height: 10, style: { width: '100%', imageRendering: 'pixelated', border: '1px solid var(--line)' } });
  const info = h('div', { class: 'muted' });
  const pushH = () => { E.hist.push({ w: E.w, h: E.h, px: new Uint8Array(E.px) }); if (E.hist.length > 100) E.hist.shift(); E.redo = []; };
  const undoE = () => { if (!E.hist.length) return; E.redo.push({ w: E.w, h: E.h, px: new Uint8Array(E.px) }); const s = E.hist.pop(); Object.assign(E, { w: s.w, h: s.h, px: s.px, sel: null }); draw(); };
  const redoE = () => { if (!E.redo.length) return; E.hist.push({ w: E.w, h: E.h, px: new Uint8Array(E.px) }); const s = E.redo.pop(); Object.assign(E, { w: s.w, h: s.h, px: s.px, sel: null }); draw(); };
  const colorOf = s => (s ? slotColor(fam, variant, fam.slots[s - 1].id, part.id) : null);
  const inb = (x, y) => x >= 0 && y >= 0 && x < E.w && y < E.h;
  const put = (x, y, v) => { if (inb(x, y)) E.px[y * E.w + x] = v; };
  const get = (x, y) => (inb(x, y) ? E.px[y * E.w + x] : 0);
  const val = () => (E.tool === 'eraser' ? 0 : E.slot);

  function draw() {
    const z = E.zoom;
    cv.width = E.w * z; cv.height = E.h * z;
    ctx.imageSmoothingEnabled = false;
    for (let y = 0; y < E.h; y++) for (let x = 0; x < E.w; x++) {
      ctx.fillStyle = (x + y) % 2 ? '#1a1e29' : '#222836'; ctx.fillRect(x * z, y * z, z, z);
      const s = E.px[y * E.w + x]; if (s) { ctx.fillStyle = colorOf(s); ctx.fillRect(x * z, y * z, z, z); }
    }
    ctx.strokeStyle = '#ffffff18'; ctx.beginPath();
    for (let x = 0; x <= E.w; x++) { ctx.moveTo(x * z + 0.5, 0); ctx.lineTo(x * z + 0.5, E.h * z); }
    for (let y = 0; y <= E.h; y++) { ctx.moveTo(0, y * z + 0.5); ctx.lineTo(E.w * z, y * z + 0.5); }
    ctx.stroke();
    if (E.floating) { const f = E.floating; for (let y = 0; y < f.h; y++) for (let x = 0; x < f.w; x++) if (f.px[y * f.w + x]) { ctx.fillStyle = colorOf(f.px[y * f.w + x]); ctx.globalAlpha = 0.85; ctx.fillRect((f.x + x) * z, (f.y + y) * z, z, z); ctx.globalAlpha = 1; } ctx.strokeStyle = '#3fb97b'; ctx.strokeRect(f.x * z + 0.5, f.y * z + 0.5, f.w * z, f.h * z); }
    if (E.sel) { ctx.strokeStyle = '#7c8cff'; ctx.setLineDash([4, 3]); ctx.strokeRect(E.sel.x * z + 0.5, E.sel.y * z + 0.5, E.sel.w * z, E.sel.h * z); ctx.setLineDash([]); }
    if (E.poly.length) { ctx.strokeStyle = '#ffd24a'; ctx.beginPath(); E.poly.forEach(([x, y], i) => (i ? ctx.lineTo((x + 0.5) * z, (y + 0.5) * z) : ctx.moveTo((x + 0.5) * z, (y + 0.5) * z))); ctx.stroke(); }
    if (E.drag && E.drag.preview) { ctx.globalAlpha = 0.6; for (const [x, y] of E.drag.preview) { ctx.fillStyle = val() ? colorOf(val()) : '#ff4444'; ctx.fillRect(x * z, y * z, z, z); } ctx.globalAlpha = 1; }
    // پیش‌نمایش واقعی
    prev.width = E.w; prev.height = E.h; const pc = prev.getContext('2d'), im = pc.createImageData(E.w, E.h);
    for (let i = 0; i < E.px.length; i++) if (E.px[i]) { const c = hexToRgb(colorOf(E.px[i])); im.data.set([c[0], c[1], c[2], 255], i * 4); }
    pc.putImageData(im, 0, 0);
    info.textContent = `${E.w}×${E.h} px · ابزار: ${E.tool}${E.sel ? ` · انتخاب ${E.sel.w}×${E.sel.h}` : ''}`;
  }
  const line = (x0, y0, x1, y1) => { const out = []; let dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0), sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, er = dx + dy; for (;;) { out.push([x0, y0]); if (x0 === x1 && y0 === y1) break; const e2 = 2 * er; if (e2 >= dy) { er += dy; x0 += sx; } if (e2 <= dx) { er += dx; y0 += sy; } } return out; };
  const rectPts = (a, b, fill) => { const out = [], x0 = Math.min(a[0], b[0]), x1 = Math.max(a[0], b[0]), y0 = Math.min(a[1], b[1]), y1 = Math.max(a[1], b[1]); for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) if (fill || x === x0 || x === x1 || y === y0 || y === y1) out.push([x, y]); return out; };
  const polyPts = (pts, fill) => {
    const out = new Map(); const add = ([x, y]) => out.set(x + ',' + y, [x, y]);
    for (let i = 0; i < pts.length; i++) line(...pts[i], ...pts[(i + 1) % pts.length]).forEach(add);
    if (fill && pts.length > 2) { const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]); for (let y = Math.min(...ys); y <= Math.max(...ys); y++) for (let x = Math.min(...xs); x <= Math.max(...xs); x++) { let c = false; for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) if ((pts[i][1] > y) !== (pts[j][1] > y) && x + 0.5 < ((pts[j][0] - pts[i][0]) * (y + 0.5 - pts[i][1])) / (pts[j][1] - pts[i][1]) + pts[i][0]) c = !c; if (c) add([x, y]); } }
    return [...out.values()];
  };
  const brush = (x, y, v) => { const s = E.size, o = Math.floor((s - 1) / 2); for (let j = 0; j < s; j++) for (let i = 0; i < s; i++) put(x - o + i, y - o + j, v); };
  function floodFill(x, y, v) { if (!inb(x, y)) return; const t = get(x, y); if (t === v) return; const st = [[x, y]]; while (st.length) { const [cx, cy] = st.pop(); if (!inb(cx, cy) || get(cx, cy) !== t) continue; put(cx, cy, v); st.push([cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]); } }
  const at = e => { const r = cv.getBoundingClientRect(); return [Math.floor(((e.clientX - r.left) / r.width) * E.w), Math.floor(((e.clientY - r.top) / r.height) * E.h)]; };
  const inSel = (x, y) => E.sel && x >= E.sel.x && y >= E.sel.y && x < E.sel.x + E.sel.w && y < E.sel.y + E.sel.h;
  function liftSel() { // بالا بردنِ ناحیه‌ی انتخابی به‌صورت شناور
    if (E.floating || !E.sel) return; pushH();
    const s = E.sel, f = { x: s.x, y: s.y, w: s.w, h: s.h, px: new Uint8Array(s.w * s.h) };
    for (let y = 0; y < s.h; y++) for (let x = 0; x < s.w; x++) { f.px[y * s.w + x] = get(s.x + x, s.y + y); put(s.x + x, s.y + y, 0); }
    E.floating = f;
  }
  function dropFloat() { const f = E.floating; if (!f) return; for (let y = 0; y < f.h; y++) for (let x = 0; x < f.w; x++) { const v = f.px[y * f.w + x]; if (v) put(f.x + x, f.y + y, v); } E.sel = { x: f.x, y: f.y, w: f.w, h: f.h }; E.floating = null; }

  cv.addEventListener('pointerdown', e => {
    cv.setPointerCapture(e.pointerId);
    const [x, y] = at(e), t = E.tool;
    if (t === 'picker') { const v = get(x, y); if (v) { E.slot = v; renderPal(); } return; }
    if (t === 'polygon') { if (E.poly.length > 2 && x === E.poly[0][0] && y === E.poly[0][1]) closePoly(); else E.poly.push([x, y]); draw(); return; }
    if (t === 'fill') { pushH(); floodFill(x, y, E.slot); draw(); return; }
    if (t === 'select') {
      if (E.floating && x >= E.floating.x && y >= E.floating.y && x < E.floating.x + E.floating.w && y < E.floating.y + E.floating.h) { E.drag = { kind: 'floatmove', x0: x, y0: y, fx: E.floating.x, fy: E.floating.y }; return; }
      if (E.floating) dropFloat();
      if (inSel(x, y)) { liftSel(); E.drag = { kind: 'floatmove', x0: x, y0: y, fx: E.floating.x, fy: E.floating.y }; draw(); return; }
      E.sel = null; E.drag = { kind: 'select', a: [x, y] }; return;
    }
    pushH(); E.drag = { kind: t, a: [x, y], last: [x, y], preview: null };
    if (t === 'pencil' || t === 'eraser') { brush(x, y, val()); draw(); }
  });
  cv.addEventListener('pointermove', e => {
    const d = E.drag; if (!d) return; const [x, y] = at(e);
    if (d.kind === 'pencil' || d.kind === 'eraser') { line(d.last[0], d.last[1], x, y).forEach(([px, py]) => brush(px, py, val())); d.last = [x, y]; }
    else if (d.kind === 'line') d.preview = line(d.a[0], d.a[1], x, y).filter(([px, py]) => inb(px, py));
    else if (d.kind === 'rect') d.preview = rectPts(d.a, [x, y], E.fill).filter(([px, py]) => inb(px, py));
    else if (d.kind === 'select') { const x0 = clamp(Math.min(d.a[0], x), 0, E.w - 1), y0 = clamp(Math.min(d.a[1], y), 0, E.h - 1), x1 = clamp(Math.max(d.a[0], x), 0, E.w - 1), y1 = clamp(Math.max(d.a[1], y), 0, E.h - 1); E.sel = { x: x0, y: y0, w: x1 - x0 + 1, h: y1 - y0 + 1 }; }
    else if (d.kind === 'floatmove') { E.floating.x = d.fx + x - d.x0; E.floating.y = d.fy + y - d.y0; }
    draw();
  });
  const end = () => {
    const d = E.drag; E.drag = null; if (!d) return;
    if ((d.kind === 'line' || d.kind === 'rect') && d.preview) d.preview.forEach(([x, y]) => put(x, y, val()));
    if (d.kind === 'floatmove') { E.sel = { x: E.floating.x, y: E.floating.y, w: E.floating.w, h: E.floating.h }; }
    draw();
  };
  cv.addEventListener('pointerup', end); cv.addEventListener('pointercancel', end);
  cv.addEventListener('dblclick', () => { if (E.tool === 'polygon') closePoly(); });
  function closePoly() { if (E.poly.length < 2) { E.poly = []; return; } pushH(); polyPts(E.poly, E.fill).forEach(([x, y]) => put(x, y, E.slot)); E.poly = []; draw(); }

  // ---- عملیات
  const region = () => (E.floating ? { x: E.floating.x, y: E.floating.y, w: E.floating.w, h: E.floating.h, px: E.floating.px, f: true } : E.sel ? (() => { const s = E.sel, px = new Uint8Array(s.w * s.h); for (let y = 0; y < s.h; y++) for (let x = 0; x < s.w; x++) px[y * s.w + x] = get(s.x + x, s.y + y); return { ...s, px }; })() : null);
  const doCopy = () => { const r = region(); if (r) { E.clip = { w: r.w, h: r.h, px: new Uint8Array(r.px) }; toast('کپی شد'); } };
  const doPaste = () => { if (!E.clip) return; if (E.floating) dropFloat(); pushH(); E.floating = { x: 0, y: 0, w: E.clip.w, h: E.clip.h, px: new Uint8Array(E.clip.px) }; E.sel = { x: 0, y: 0, w: E.clip.w, h: E.clip.h }; E.tool = 'select'; renderTools(); draw(); };
  const doDup = () => { const r = region(); if (!r) return; E.clip = { w: r.w, h: r.h, px: new Uint8Array(r.px) }; if (E.floating) dropFloat(); pushH(); E.floating = { x: r.x + 2, y: r.y + 2, w: r.w, h: r.h, px: new Uint8Array(r.px) }; E.sel = { x: r.x + 2, y: r.y + 2, w: r.w, h: r.h }; draw(); };
  const doDel = () => { if (E.floating) { E.floating = null; E.sel = null; draw(); return; } if (E.sel) { pushH(); for (let y = 0; y < E.sel.h; y++) for (let x = 0; x < E.sel.w; x++) put(E.sel.x + x, E.sel.y + y, 0); draw(); } };
  const transform = (kind) => {
    pushH();
    const r = region(); const target = r ? { w: r.w, h: r.h, px: r.px } : { w: E.w, h: E.h, px: E.px };
    let out = { w: target.w, h: target.h, px: new Uint8Array(target.px) };
    if (kind === 'fh') for (let y = 0; y < target.h; y++) for (let x = 0; x < target.w; x++) out.px[y * target.w + x] = target.px[y * target.w + target.w - 1 - x];
    if (kind === 'fv') for (let y = 0; y < target.h; y++) for (let x = 0; x < target.w; x++) out.px[y * target.w + x] = target.px[(target.h - 1 - y) * target.w + x];
    if (kind === 'rot') { out = { w: target.h, h: target.w, px: new Uint8Array(target.px.length) }; for (let y = 0; y < target.h; y++) for (let x = 0; x < target.w; x++) out.px[x * out.w + (target.h - 1 - y)] = target.px[y * target.w + x]; }
    if (r) { if (!E.floating) { for (let y = 0; y < r.h; y++) for (let x = 0; x < r.w; x++) put(r.x + x, r.y + y, 0); E.floating = { x: r.x, y: r.y, ...out }; } else Object.assign(E.floating, out); E.sel = { x: E.floating.x, y: E.floating.y, w: E.floating.w, h: E.floating.h }; }
    else { E.w = out.w; E.h = out.h; E.px = out.px; }
    draw();
  };
  const resize = () => {
    const w = clamp(num(prompt('عرض جدید', E.w), E.w), 1, 96), hh = clamp(num(prompt('ارتفاع جدید', E.h), E.h), 1, 144);
    const ox = num(prompt('جابه‌جاییِ محتوا در X (پیکسل)', 0), 0), oy = num(prompt('جابه‌جاییِ محتوا در Y (پیکسل)', 0), 0);
    pushH(); const px = new Uint8Array(w * hh);
    for (let y = 0; y < E.h; y++) for (let x = 0; x < E.w; x++) { const nx = x + ox, ny = y + oy; if (nx >= 0 && ny >= 0 && nx < w && ny < hh) px[ny * w + nx] = E.px[y * E.w + x]; }
    E.w = w; E.h = hh; E.px = px; E.sel = null; draw();
  };

  const TOOLS = [['pencil', '✏ قلم'], ['eraser', '⌫ پاک‌کن'], ['line', '／ خط'], ['rect', '▭ مستطیل'], ['polygon', '⬠ چندضلعی'], ['fill', '🪣 سطل'], ['select', '⬚ انتخاب/جابه‌جایی'], ['picker', '💧 قطره‌چکان']];
  const tools = h('div', { class: 'tools' }), pal = h('div', { class: 'pal' });
  function renderTools() { tools.replaceChildren(...TOOLS.map(([k, l]) => h('button', { class: E.tool === k ? 'on' : '', onclick: () => { if (E.floating) dropFloat(); E.tool = k; E.poly = []; renderTools(); draw(); } }, l))); }
  function renderPal() { pal.replaceChildren(...fam.slots.map((sl, i) => h('div', { class: 'sw' + (E.slot === i + 1 ? ' sel' : ''), title: `${i + 1}: ${sl.name}`, style: { background: colorOf(i + 1) }, onclick: () => { E.slot = i + 1; if (E.tool === 'eraser') E.tool = 'pencil'; renderTools(); renderPal(); } }))); }
  const keyH = e => {
    if (e.target.tagName === 'INPUT') return;
    const k = e.key.toLowerCase();
    if ((e.ctrlKey || e.metaKey) && k === 'z') { e.preventDefault(); e.shiftKey ? redoE() : undoE(); }
    else if ((e.ctrlKey || e.metaKey) && k === 'y') { e.preventDefault(); redoE(); }
    else if ((e.ctrlKey || e.metaKey) && k === 'c') { e.preventDefault(); doCopy(); }
    else if ((e.ctrlKey || e.metaKey) && k === 'v') { e.preventDefault(); doPaste(); }
    else if ((e.ctrlKey || e.metaKey) && k === 'd') { e.preventDefault(); doDup(); }
    else if (k === 'delete' || k === 'backspace') doDel();
    else if (k === 'enter' && E.tool === 'polygon') closePoly();
    else if (k === 'escape') { E.poly = []; if (E.floating) dropFloat(); E.sel = null; draw(); }
    e.stopPropagation();
  };
  const close = save => {
    if (E.floating) dropFloat();
    document.removeEventListener('keydown', keyH, true); bg.remove();
    if (save) { part.w = E.w; part.h = E.h; part.px = E.px; invalidateCache(); commit('pixels'); }
  };
  const bg = h('div', { class: 'modal-bg' }, h('div', { class: 'modal' },
    h('h3', {}, h('span', { class: 'grow' }, `ویرایش پیکسلی — ${fam.name} / ${part.name}`), btn('لغو', () => close(false)), ' ', btn('✓ ذخیره', () => close(true), 'primary')),
    h('div', { class: 'mb' }, h('div', { id: 'pe' },
      h('div', {}, tools, h('hr'), h('div', { class: 'row' }, h('label', {}, 'ضخامت'), selIn('1', [['1', '1'], ['2', '2'], ['3', '3'], ['4', '4']], v => (E.size = +v))), h('label', { class: 'row' }, chkIn(false, v => (E.fill = v)), ' پر (مستطیل/چندضلعی)'), h('hr'),
        h('div', { class: 'row wrap' }, btn('↶', undoE, 'ib', 'Undo'), btn('↷', redoE, 'ib', 'Redo'), btn('⧉ کپی', doCopy), btn('📋 پیست', doPaste), btn('⧉⧉ تکثیر', doDup), btn('🗑 حذف انتخاب', doDel)),
        h('div', { class: 'row wrap' }, btn('⇋ H', () => transform('fh'), '', 'وارونه افقی'), btn('⇅ V', () => transform('fv'), '', 'وارونه عمودی'), btn('⟳ 90°', () => transform('rot'), '', 'چرخش'), btn('⤢ اندازه', resize), btn('پاک‌کردن همه', () => { pushH(); E.px.fill(0); draw(); }, 'danger'))),
      h('div', { style: { overflow: 'auto', maxHeight: '70vh' } }, cv),
      h('div', {}, h('b', {}, 'رنگ‌ها (Slot)'), pal, h('div', { class: 'row' }, h('label', {}, 'زوم'), rangeIn(E.zoom, v => { E.zoom = v; draw(); }, 4, 32, 2)), h('b', {}, 'پیش‌نمایش'), prev, info,
        h('div', { class: 'muted' }, 'Ctrl+Z/Y، Ctrl+C/V/D، Delete، چندضلعی: کلیک‌ها + دوبل‌کلیک/Enter'))))));
  document.addEventListener('keydown', keyH, true);
  document.body.append(bg);
  renderTools(); renderPal(); draw();
  return E;
}
