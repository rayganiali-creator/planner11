'use strict';
// ===== پنل‌ها: دارایی‌ها/کاراکترها (چپ)، لایه‌ها/بازرس (راست)، قطعات/واریانت/Mood/پس‌زمینه/صحنه/پیش‌نمایش (پایین) =====

// ---- سازنده‌های فیلد
const row = (label, ...c) => h('div', { class: 'row' }, label != null ? h('label', {}, label) : null, ...c);
const btn = (t, fn, cls, title) => h('button', { class: cls || '', title, onclick: fn }, t);
const numIn = (v, fn, o = {}) => h('input', { type: 'number', value: +(+v).toFixed(3), step: o.step || 1, min: o.min, max: o.max, onchange: e => fn(num(e.target.value, v)) });
const txtIn = (v, fn, o = {}) => h('input', { type: 'text', value: v == null ? '' : v, style: o.style, placeholder: o.ph, onchange: e => fn(e.target.value) });
const chkIn = (v, fn) => h('input', { type: 'checkbox', checked: !!v, onchange: e => fn(e.target.checked) });
const colIn = (v, fn) => h('input', { type: 'color', value: /^#[0-9a-f]{6}$/i.test(v) ? v : '#ff00ff', onchange: e => fn(e.target.value) });
const selIn = (v, opts, fn) => h('select', { onchange: e => fn(e.target.value) }, opts.map(([val, lab]) => h('option', { value: val, selected: val === v }, lab)));
const rangeIn = (v, fn, min, max, step) => h('input', { type: 'range', value: v, min, max, step, onchange: e => fn(num(e.target.value, v)) });
function tabs(cur, list, fn) { return h('div', { class: 'tabs' }, list.map(([k, l]) => h('button', { class: cur === k ? 'on' : '', onclick: () => fn(k) }, l))); }
function paint(el, build) { const st = el.scrollTop; el.replaceChildren(...[].concat(build()).flat(Infinity).filter(Boolean)); el.scrollTop = st; }
function thumb(fam, variant, size = 36) {
  const c = h('canvas', { class: 'thumb', width: size, height: size });
  const s = familySprite(fam, variant || fam.variants[0]);
  if (!s.empty) { const k = Math.min((size - 2) / s.w, (size - 2) / s.h, 4); const ctx = c.getContext('2d'); ctx.imageSmoothingEnabled = false; ctx.drawImage(s.canvas, Math.round((size - s.w * k) / 2), Math.round((size - s.h * k) / 2), Math.round(s.w * k), Math.round(s.h * k)); }
  return c;
}

// ---- عملیات مشترک
function selectFam(fam, varId) {
  S.famId = fam.id; S.partId = null;
  const L = layerOfFam(fam.id);
  S.varId = varId || (L ? P.scene.equipped[L.id].variantId : fam.variants[0].id);
  renderAll();
}
function equip(fam, varId) {
  let L = layerOfFam(fam.id) || P.layers.find(l => l.category === fam.category && !P.scene.equipped[l.id]) || P.layers.find(l => l.category === fam.category);
  if (!L) { L = { id: 'L_' + newId('c'), name: CAT_FA[fam.category] || fam.category, category: fam.category, visible: true, locked: false }; P.layers.push(L); }
  P.scene.equipped[L.id] = { familyId: fam.id, variantId: varId || (P.scene.equipped[L.id] && P.scene.equipped[L.id].familyId === fam.id ? P.scene.equipped[L.id].variantId : fam.variants[0].id) };
  if (!compatible(fam, P.scene.characterId)) toast('این Asset با کاراکترِ فعلی سازگار نیست (نمایش داده نمی‌شود)');
  S.famId = fam.id; S.varId = P.scene.equipped[L.id].variantId;
  commit('equip');
}
function unequip(layerId) { delete P.scene.equipped[layerId]; commit('unequip'); }
function newBlankFamily(cat) {
  const f = newFamily((CAT_FA[cat] || cat) + ' جدید', cat);
  const p = newPart('part1', 16, 16, -8, -16); f.parts.push(p);
  P.families.push(f); equip(f);
  openPixelEditor(f, p);
}
function dupFamily(f) {
  const c = clone({ ...f, parts: [] });
  c.id = newId('fam'); c.name = f.name + ' کپی';
  c.parts = f.parts.map(p => ({ ...p, id: newId('part'), px: new Uint8Array(p.px) }));
  const idMap = Object.fromEntries(f.parts.map((p, i) => [p.id, c.parts[i].id]));
  c.variants = f.variants.map(v => { const nv = clone(v); nv.id = newId('var'); nv.overrides = Object.fromEntries(Object.entries(v.overrides || {}).map(([k, o]) => [idMap[k] || k, o])); return nv; });
  P.families.splice(P.families.indexOf(f) + 1, 0, c); S.famId = c.id; commit('dupFamily');
}
function delFamily(f) {
  if (!confirm(`«${f.name}» و همه‌ی واریانت‌هایش حذف شود؟`)) return;
  P.families = P.families.filter(x => x !== f);
  for (const k of Object.keys(P.scene.equipped)) if (P.scene.equipped[k].familyId === f.id) delete P.scene.equipped[k];
  for (const m of Object.keys(P.moods)) if (P.moods[m].familyId === f.id) delete P.moods[m];
  if (S.famId === f.id) { S.famId = null; S.partId = null; }
  commit('delFamily');
}

// ================================================================ چپ
function renderLeft() {
  paint($('#left'), () => [
    tabs(S.leftTab, [['assets', 'Assets'], ['chars', 'Characters']], k => { S.leftTab = k; renderLeft(); }),
    S.leftTab === 'assets' ? assetsList() : charsList(),
  ]);
}
function assetsList() {
  const cats = [['all', 'همه'], ...CATS];
  const fams = P.families.filter(f => S.cat === 'all' || f.category === S.cat);
  return [
    h('div', { class: 'tabs' }, cats.map(([k, l]) => h('button', { class: S.cat === k ? 'on' : '', onclick: () => { S.cat = k; renderLeft(); } }, l))),
    h('div', { class: 'pb' }, btn('＋ Asset Family جدید', () => newBlankFamily(S.cat === 'all' ? 'accessory' : S.cat), 'primary')),
    h('div', { class: 'list' }, fams.map(f => {
      const L = layerOfFam(f.id), ok = compatible(f, P.scene.characterId);
      return h('div', { class: 'item' + (S.famId === f.id ? ' sel' : ''), onclick: () => (L ? selectFam(f) : equip(f)) },
        thumb(f, L ? varOf(f, P.scene.equipped[L.id].variantId) : f.variants[0]),
        h('span', { class: 'nm' }, f.name, h('br'), h('small', {}, `${CAT_FA[f.category] || f.category} · ${f.variants.length} واریانت · ${f.parts.length} قطعه${ok ? '' : ' · ⛔ ناسازگار'}`)),
        L ? h('span', { class: 'chip' }, '✓') : null,
        btn('⧉', e => { e.stopPropagation(); dupFamily(f); }, 'ib', 'تکثیر'), btn('🗑', e => { e.stopPropagation(); delFamily(f); }, 'ib danger', 'حذف'));
    })),
    fams.length ? null : h('div', { class: 'pb muted' }, 'خانواده‌ای در این دسته نیست.'),
  ];
}
function charsList() {
  return [
    h('div', { class: 'pb' }, btn('＋ کاراکتر جدید', () => { const c = { id: newId('char'), name: 'Character ' + String(P.characters.length + 1).padStart(2, '0'), notes: '' }; P.characters.push(c); P.scene.characterId = c.id; commit('addChar'); }, 'primary')),
    h('div', { class: 'list' }, P.characters.map(c => h('div', { class: 'item' + (P.scene.characterId === c.id ? ' sel' : ''), onclick: () => { P.scene.characterId = c.id; commit('selChar'); } },
      h('span', { class: 'nm' }, h('input', { type: 'text', value: c.name, style: { width: '100%' }, onclick: e => e.stopPropagation(), onchange: e => { c.name = e.target.value; commit('renChar'); } }),
        h('small', {}, `${P.families.filter(f => f.characterIds.includes(c.id)).length} Asset اختصاصی · ${P.families.filter(f => !f.characterIds.length).length} مشترک`)),
      btn('⧉', e => { e.stopPropagation(); dupChar(c); }, 'ib', 'تکثیر'),
      btn('🗑', e => { e.stopPropagation(); if (P.characters.length > 1 && confirm('کاراکتر حذف شود؟')) { delChar(c); } else if (P.characters.length <= 1) toast('حداقل یک کاراکتر لازم است'); }, 'ib danger', 'حذف')))),
    h('div', { class: 'pb muted' }, 'Assetهای اختصاصیِ هر کاراکتر را در بازرس (Character Compatibility) تعیین کنید؛ Assetِ بدون محدودیت بین همه‌ی کاراکترها مشترک است.'),
  ];
}
function dupChar(c) {
  const n = { id: newId('char'), name: c.name + ' کپی', notes: c.notes };
  P.characters.push(n);
  for (const f of P.families) { if (f.characterIds.includes(c.id)) f.characterIds.push(n.id); if (f.geometry[c.id]) f.geometry[n.id] = clone(f.geometry[c.id]); }
  P.scene.characterId = n.id; commit('dupChar');
}
function delChar(c) {
  P.characters = P.characters.filter(x => x !== c);
  for (const f of P.families) { f.characterIds = f.characterIds.filter(i => i !== c.id); delete f.geometry[c.id]; }
  if (P.scene.characterId === c.id) P.scene.characterId = P.characters[0].id;
  commit('delChar');
}

// ================================================================ راست
function renderRight() {
  paint($('#right'), () => [tabs(S.rightTab, [['layers', 'Layers'], ['inspect', 'Inspector']], k => { S.rightTab = k; renderRight(); }), S.rightTab === 'layers' ? layersPanel() : inspector()]);
}
function layersPanel() {
  const ls = [...P.layers].reverse();
  return [
    h('div', { class: 'pb' }, btn('＋ لایه', () => { const n = prompt('نام لایه', 'لایه جدید'); if (n) { P.layers.push({ id: 'L_' + newId('c'), name: n, category: 'accessory', visible: true, locked: false }); commit('addLayer'); } })),
    h('div', { class: 'list' }, ls.map(L => {
      const eq = P.scene.equipped[L.id], fam = eq && famById(eq.familyId), i = P.layers.indexOf(L);
      return h('div', { class: 'item' + (fam && S.famId === fam.id ? ' sel' : ''), onclick: () => { if (fam) selectFam(fam, eq.variantId); } },
        btn(L.visible ? '👁' : '⌀', e => { e.stopPropagation(); L.visible = !L.visible; commit('vis'); }, 'ib', 'نمایش/مخفی'),
        btn(L.locked ? '🔒' : '🔓', e => { e.stopPropagation(); L.locked = !L.locked; commit('lock'); }, 'ib', 'قفل'),
        fam ? thumb(fam, varOf(fam, eq.variantId), 28) : h('span', { class: 'thumb', style: { width: '28px', height: '28px' } }),
        h('span', { class: 'nm', ondblclick: e => { e.stopPropagation(); const n = prompt('نام لایه', L.name); if (n) { L.name = n; commit('renLayer'); } } }, L.name, h('br'), h('small', {}, fam ? fam.name : '— خالی —')),
        btn('▲', e => { e.stopPropagation(); if (i < P.layers.length - 1) { [P.layers[i], P.layers[i + 1]] = [P.layers[i + 1], P.layers[i]]; commit('zup'); } }, 'ib', 'بالاتر'),
        btn('▼', e => { e.stopPropagation(); if (i > 0) { [P.layers[i], P.layers[i - 1]] = [P.layers[i - 1], P.layers[i]]; commit('zdn'); } }, 'ib', 'پایین‌تر'),
        btn('⧉', e => { e.stopPropagation(); const n = { ...L, id: 'L_' + newId('c'), name: L.name + ' کپی' }; P.layers.splice(i + 1, 0, n); if (eq) P.scene.equipped[n.id] = { ...eq }; commit('dupLayer'); }, 'ib', 'تکثیر لایه'),
        btn('🗑', e => { e.stopPropagation(); if (confirm('لایه حذف شود؟')) { P.layers.splice(i, 1); delete P.scene.equipped[L.id]; commit('delLayer'); } }, 'ib danger', 'حذف'));
    })),
  ];
}
function inspector() {
  const f = selFam();
  if (!f) return h('div', { class: 'pb muted' }, 'یک Asset را روی صحنه یا از فهرست انتخاب کنید.');
  const L = layerOfFam(f.id), cid = P.scene.characterId, g = geomFor(f, cid), variant = varOf(f, S.varId), spr = familySprite(f, variant);
  const set = (patch) => { setGeom(f, patch); commit('geom'); };
  const hasOv = !!(cid && f.geometry[cid]);
  const out = [h('div', { class: 'pb' },
    row('Family ID', h('input', { type: 'text', value: f.id, readonly: true })),
    row('Variant ID', h('input', { type: 'text', value: variant.id, readonly: true })),
    row('Name', txtIn(f.name, v => { f.name = v; commit('name'); })),
    row('Category', selIn(f.category, CATS, v => { f.category = v; commit('cat'); })),
    row('Variant', selIn(variant.id, f.variants.map(v => [v.id, v.name]), v => { S.varId = v; if (L) P.scene.equipped[L.id].variantId = v; commit('variant'); })),
    row('Width × Height', h('span', {}, `${spr.w || 0} × ${spr.h || 0} px`)),
    row('Geometry', selIn(S.scope, [['auto', 'خودکار' + (hasOv ? ' (override)' : ' (مشترک)')], ['shared', 'مشترک بین کاراکترها'], ['char', 'فقط این کاراکتر']], v => { S.scope = v; renderRight(); })),
    row('X', h('span', { id: 'f_x' }, numIn(g.x, v => set({ x: v })))), row('Y', h('span', { id: 'f_y' }, numIn(g.y, v => set({ y: v })))),
    row('Scale', h('span', { id: 'f_scale' }, numIn(g.scale, v => set({ scale: clamp(v, 0.1, 8) }), { step: 0.05 }))),
    row('Rotation', h('span', { id: 'f_rot' }, numIn(g.rotation, v => set({ rotation: v }), { step: 5 }))),
    row('Opacity', rangeIn(g.opacity, v => set({ opacity: v }), 0, 1, 0.05)),
    row('Flip', h('label', {}, chkIn(g.flipX, v => set({ flipX: v })), ' X  '), h('label', {}, chkIn(g.flipY, v => set({ flipY: v })), ' Y')),
    row('Anchor', selIn(f.anchor, ANCHORS.map(a => [a, a]), v => { f.anchor = v; commit('anchor'); })),
    row('Layer', selIn(L ? L.id : '', [['', '— روی صحنه نیست —'], ...P.layers.map(l => [l.id, l.name])], v => { if (L) { const e = P.scene.equipped[L.id]; delete P.scene.equipped[L.id]; if (v) P.scene.equipped[v] = e; } else if (v) P.scene.equipped[v] = { familyId: f.id, variantId: variant.id }; commit('layer'); })),
    row('Visible', chkIn(L ? L.visible : false, v => { if (L) { L.visible = v; commit('vis'); } })),
    row('Locked', chkIn(L ? L.locked : false, v => { if (L) { L.locked = v; commit('lock'); } })),
    row('Tags', txtIn(f.tags.join(', '), v => { f.tags = v.split(',').map(s => s.trim()).filter(Boolean); commit('tags'); })),
    row('Mood', f.category === 'mouth' ? h('span', {}, MOODS.filter(([m]) => P.moods[m] && P.moods[m].familyId === f.id).map(([, l]) => l).join('، ') || '— (در تب Moods تنظیم کنید)') : h('span', { class: 'muted' }, '— فقط برای دهان')),
  ), h('div', { class: 'ph' }, 'رنگ‌ها (واریانت جاری)'),
  h('div', { class: 'pb' }, f.slots.map(sl => row(sl.name, colIn(slotColor(f, variant, sl.id), v => { variant.colors[sl.id] = v; commit('color'); }), h('small', { class: 'muted' }, slotColor(f, variant, sl.id))))),
  h('div', { class: 'ph' }, 'Character Compatibility'),
  h('div', { class: 'pb' }, P.characters.map(c => h('label', { class: 'row' }, chkIn(!f.characterIds.length || f.characterIds.includes(c.id), v => {
    const all = P.characters.map(x => x.id);
    let cur = f.characterIds.length ? [...f.characterIds] : [...all];
    cur = v ? [...new Set([...cur, c.id])] : cur.filter(i => i !== c.id);
    f.characterIds = cur.length === all.length ? [] : cur; commit('compat');
  }), ' ' + c.name)), h('small', { class: 'muted' }, 'همه‌ی کاراکترها تیک‌خورده = Asset مشترک')),
  ];
  return out;
}
/** هنگام درگ، فقط مقدار فیلدهای هندسه به‌روز می‌شود (بدون بازسازی پنل) */
function liveFields() {
  const f = selFam(); if (!f) return;
  const g = geomFor(f, P.scene.characterId);
  for (const [id, k] of [['f_x', 'x'], ['f_y', 'y'], ['f_scale', 'scale'], ['f_rot', 'rotation']]) { const i = $('#' + id + ' input'); if (i) i.value = +(+g[k]).toFixed(3); }
}

// ================================================================ پایین
const BTABS = [['parts', 'Parts'], ['variants', 'Variants'], ['moods', 'Moods'], ['bg', 'Background'], ['scene', 'Shadow/Ground/Light'], ['previews', 'Previews']];
function renderBottom() {
  paint($('#bottombody'), () => ({ parts: partsTab, variants: variantsTab, moods: moodsTab, bg: bgTab, scene: sceneTab, previews: previewsTab }[S.bottomTab])());
  $('#bottomtabs').replaceChildren(...BTABS.map(([k, l]) => h('button', { class: S.bottomTab === k ? 'on' : '', onclick: () => { S.bottomTab = k; renderBottom(); } }, l)));
}
function needFam() { return h('div', { class: 'muted' }, 'ابتدا یک Asset را انتخاب کنید.'); }
function partsTab() {
  const f = selFam(); if (!f) return needFam();
  const variant = varOf(f, S.varId), pt = selPart();
  const ov = pt && (variant.overrides[pt.id] || (variant.overrides[pt.id] = {}));
  const upd = fn => v => { fn(v); invalidateCache(); commit('part'); };
  const list = h('div', { class: 'list', style: { width: '260px', flex: 'none', border: '1px solid var(--line)', borderRadius: '6px', maxHeight: '230px', overflow: 'auto' } },
    f.parts.map((p, i) => h('div', { class: 'item' + (pt && pt.id === p.id ? ' sel' : ''), onclick: () => { S.partId = p.id; S.partMode = true; renderAll(); } },
      btn(p.visible ? '👁' : '⌀', e => { e.stopPropagation(); p.visible = !p.visible; invalidateCache(); commit('pvis'); }, 'ib'),
      h('span', { class: 'nm' }, p.name, ' ', h('small', {}, `${p.w}×${p.h}`)),
      btn('▲', e => { e.stopPropagation(); if (i) { [f.parts[i], f.parts[i - 1]] = [f.parts[i - 1], f.parts[i]]; invalidateCache(); commit('porder'); } }, 'ib'),
      btn('▼', e => { e.stopPropagation(); if (i < f.parts.length - 1) { [f.parts[i], f.parts[i + 1]] = [f.parts[i + 1], f.parts[i]]; invalidateCache(); commit('porder'); } }, 'ib'))));
  const actions = h('div', { class: 'row wrap' },
    btn('＋ قطعه', () => { const w = num(prompt('عرض', 16), 16), hh = num(prompt('ارتفاع', 16), 16); const p = newPart('part' + (f.parts.length + 1), clamp(w, 1, 96), clamp(hh, 1, 144), -Math.floor(w / 2), -hh); f.parts.push(p); S.partId = p.id; invalidateCache(); commit('addPart'); }),
    btn('⧉ تکثیر', () => { if (!pt) return; const c = { ...clone({ ...pt, px: [] }), id: newId('part'), px: new Uint8Array(pt.px), name: pt.name + '2', dx: pt.dx + 2, dy: pt.dy + 2 }; f.parts.push(c); S.partId = c.id; invalidateCache(); commit('dupPart'); }),
    btn('🗑 حذف', () => { if (!pt) return; f.parts = f.parts.filter(p => p !== pt); S.partId = null; invalidateCache(); commit('delPart'); }, 'danger'),
    btn('✎ ویرایش پیکسلی', () => pt && openPixelEditor(f, pt), 'primary'),
    btn('✂ برش به محتوا', () => { if (pt) { cropPart(pt); invalidateCache(); commit('crop'); } }),
    btn('⑂ تقسیم (اجزای جدا)', () => { if (pt) { splitPart(f, pt); invalidateCache(); commit('split'); } }),
    btn('⇄ جایگزینی (از قطعه‌ی دیگر)', () => { if (!pt) return; const others = P.families.flatMap(x => x.parts.map(p => ({ x, p }))).filter(o => o.p !== pt); const n = prompt('نامِ قطعه‌ی منبع:\n' + others.map(o => o.x.name + '/' + o.p.name).join('\n')); const m = others.find(o => o.x.name + '/' + o.p.name === n); if (m) { pt.w = m.p.w; pt.h = m.p.h; pt.px = new Uint8Array(m.p.px); invalidateCache(); commit('replacePart'); } }));
  const fields = !pt ? h('div', { class: 'muted' }, 'قطعه‌ای انتخاب نشده (روی صحنه هم می‌توانید قطعه را جابه‌جا کنید).') : h('div', { class: 'grid2' },
    row('نام', txtIn(pt.name, upd(v => (pt.name = v)))), row('Part ID', h('input', { type: 'text', value: pt.id, readonly: true })),
    row('X', numIn(pt.dx, upd(v => (pt.dx = Math.round(v))))), row('Y', numIn(pt.dy, upd(v => (pt.dy = Math.round(v))))),
    row('Scale', numIn(pt.scale, upd(v => (pt.scale = clamp(v, 0.1, 8))), { step: 0.1 })), row('Rotation', numIn(pt.rotation, upd(v => (pt.rotation = v)), { step: 5 })),
    row('Flip', h('label', {}, chkIn(pt.flipX, upd(v => (pt.flipX = v))), ' X '), h('label', {}, chkIn(pt.flipY, upd(v => (pt.flipY = v))), ' Y')),
    row('اندازه', h('span', {}, `${pt.w}×${pt.h}`)),
    h('div', { class: 'row wrap', style: { gridColumn: '1/-1' } }, h('b', {}, `Override در واریانت «${variant.name}»:`), h('label', {}, chkIn(ov.visible !== false, v => { if (v) delete ov.visible; else ov.visible = false; invalidateCache(); commit('ovvis'); }), ' نمایش'),
      ...f.slots.map(sl => h('span', { class: 'chip' }, sl.name, colIn(slotColor(f, variant, sl.id, pt.id), v => { (ov.colors || (ov.colors = {}))[sl.id] = v; invalidateCache(); commit('ovcolor'); }), btn('×', () => { if (ov.colors) delete ov.colors[sl.id]; invalidateCache(); commit('ovclr'); }, 'ib', 'حذف override')))));
  return h('div', { style: { display: 'flex', gap: '14px', alignItems: 'flex-start', flexWrap: 'wrap' } }, h('div', {}, list, h('div', { class: 'muted' }, 'Collar/Sleeves/Body/Buttons… هر کدام یک قطعه‌اند.')), h('div', { style: { flex: 1, minWidth: '300px' } }, actions, fields));
}
function cropPart(pt) {
  let x0 = pt.w, y0 = pt.h, x1 = -1, y1 = -1;
  for (let y = 0; y < pt.h; y++) for (let x = 0; x < pt.w; x++) if (pt.px[y * pt.w + x]) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  if (x1 < 0) return toast('قطعه خالی است');
  const w = x1 - x0 + 1, hh = y1 - y0 + 1, px = new Uint8Array(w * hh);
  for (let y = 0; y < hh; y++) for (let x = 0; x < w; x++) px[y * w + x] = pt.px[(y + y0) * pt.w + x + x0];
  pt.px = px; pt.dx += x0; pt.dy += y0; pt.w = w; pt.h = hh;
}
function splitPart(f, pt) {
  const seen = new Uint8Array(pt.w * pt.h), comps = [];
  for (let i = 0; i < pt.px.length; i++) {
    if (!pt.px[i] || seen[i]) continue;
    const st = [i], cells = []; seen[i] = 1;
    while (st.length) { const c = st.pop(); cells.push(c); const x = c % pt.w, y = (c - x) / pt.w; for (const [nx, ny] of [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]]) { if (nx < 0 || ny < 0 || nx >= pt.w || ny >= pt.h) continue; const n = ny * pt.w + nx; if (pt.px[n] && !seen[n]) { seen[n] = 1; st.push(n); } } }
    comps.push(cells);
  }
  if (comps.length < 2) return toast('فقط یک جزء وجود دارد');
  const idx = f.parts.indexOf(pt);
  const news = comps.map((cells, k) => {
    const p = newPart(pt.name + '_' + (k + 1), pt.w, pt.h, pt.dx, pt.dy); Object.assign(p, { scale: pt.scale, rotation: pt.rotation, flipX: pt.flipX, flipY: pt.flipY });
    for (const c of cells) p.px[c] = pt.px[c]; cropPart(p); return p;
  });
  f.parts.splice(idx, 1, ...news); S.partId = news[0].id;
}

function variantsTab() {
  const f = selFam(); if (!f) return needFam();
  const L = layerOfFam(f.id), cur = varOf(f, S.varId);
  const list = h('div', { class: 'list', style: { width: '260px', flex: 'none', border: '1px solid var(--line)', borderRadius: '6px', maxHeight: '230px', overflow: 'auto' } },
    f.variants.map(v => h('div', { class: 'item' + (v.id === cur.id ? ' sel' : ''), onclick: () => { S.varId = v.id; if (L) P.scene.equipped[L.id].variantId = v.id; commit('selVar'); } },
      thumb(f, v, 28), h('span', { class: 'nm' }, h('input', { type: 'text', value: v.name, style: { width: '100%' }, onclick: e => e.stopPropagation(), onchange: e => { v.name = e.target.value; commit('renVar'); } })),
      f.slots.slice(0, 3).map(sl => h('span', { class: 'swatch', style: { background: slotColor(f, v, sl.id) } })),
      btn('⧉', e => { e.stopPropagation(); const n = clone(v); n.id = newId('var'); n.name = v.name + ' کپی'; f.variants.push(n); S.varId = n.id; commit('dupVar'); }, 'ib'),
      btn('🗑', e => { e.stopPropagation(); if (f.variants.length > 1) { f.variants = f.variants.filter(x => x !== v); S.varId = f.variants[0].id; for (const k of Object.keys(P.scene.equipped)) if (P.scene.equipped[k].familyId === f.id && P.scene.equipped[k].variantId === v.id) P.scene.equipped[k].variantId = f.variants[0].id; commit('delVar'); } else toast('حداقل یک واریانت لازم است'); }, 'ib danger'))));
  return h('div', { style: { display: 'flex', gap: '14px', flexWrap: 'wrap' } },
    h('div', {}, list, btn('＋ واریانت جدید', () => { const n = { id: newId('var'), name: 'Variant ' + (f.variants.length + 1), colors: clone(cur.colors), overrides: {} }; f.variants.push(n); S.varId = n.id; commit('addVar'); }, 'primary')),
    h('div', { style: { flex: 1, minWidth: '300px' } },
      h('div', { class: 'muted' }, 'همه‌ی واریانت‌ها هندسه (Base Geometry) و قطعه‌ها را مشترک دارند؛ فقط رنگ/Override قطعه‌ها فرق می‌کند.'),
      h('div', { class: 'grid2' }, f.slots.map((sl, i) => row(null, h('input', { type: 'text', value: sl.name, style: { width: '90px' }, onchange: e => { sl.name = e.target.value; commit('slotName'); } }), h('small', { class: 'muted' }, 'پایه'), colIn(sl.color, v => { sl.color = v; commit('slotBase'); }), h('small', { class: 'muted' }, 'واریانت'), colIn(slotColor(f, cur, sl.id), v => { cur.colors[sl.id] = v; commit('slotVar'); }),
        btn('↺', () => { delete cur.colors[sl.id]; commit('slotReset'); }, 'ib', 'برگرداندن به پایه')))),
      row(null, btn('＋ Slot رنگ', () => { if (f.slots.length >= 35) return; const id = 's' + (Math.max(0, ...f.slots.map(s => +s.id.slice(1))) + 1); f.slots.push({ id, name: 'رنگ ' + (f.slots.length + 1), color: '#888888' }); commit('addSlot'); }),
        btn('🗑 آخرین Slot', () => { if (f.slots.length > 1) { const s = f.slots.pop(); const n = f.slots.length; for (const p of f.parts) for (let i = 0; i < p.px.length; i++) if (p.px[i] > n) p.px[i] = 0; delete cur.colors[s.id]; invalidateCache(); commit('delSlot'); } }, 'danger')),
      h('div', { class: 'row wrap' }, h('b', {}, 'Base Geometry:'), ...Object.entries(f.geometry).map(([k, g]) => h('span', { class: 'chip' }, (k === '*' ? 'مشترک' : (charById(k) || { name: k }).name), ` x${g.x ?? '·'} y${g.y ?? '·'} s${g.scale ?? '·'} r${g.rotation ?? '·'}`, k === '*' ? null : btn('×', () => { delete f.geometry[k]; commit('delGeom'); }, 'ib', 'حذف override'))))));
}
function moodsTab() {
  const mouths = P.families.filter(f => f.category === 'mouth');
  return h('div', {},
    h('div', { class: 'row wrap' }, h('b', {}, 'Mood فعلی:'), ...MOODS.map(([k, l]) => h('button', { class: P.scene.mood === k ? 'on' : '', onclick: () => { P.scene.mood = k; commit('mood'); } }, l + ' · ' + k))),
    h('div', { class: 'grid2' }, MOODS.map(([k, l]) => { const m = P.moods[k] || {}, fam = famById(m.familyId); return row(l, selIn(m.familyId || '', [['', '— بدون —'], ...mouths.map(x => [x.id, x.name])], v => { if (v) P.moods[k] = { familyId: v, variantId: famById(v).variants[0].id }; else delete P.moods[k]; commit('moodMap'); }), fam ? selIn(m.variantId, fam.variants.map(v => [v.id, v.name]), v => { m.variantId = v; commit('moodVar'); }) : null); })),
    h('div', { class: 'muted' }, 'Mood فعلی لایه‌ی «mouth» را روی صحنه با دهانِ نگاشت‌شده جایگزین می‌کند؛ بقیه‌ی لایه‌ها دست‌نخورده می‌مانند.'));
}
function curBg() { return P.backgrounds.find(b => b.id === (S.bgId || P.scene.backgroundId)) || P.backgrounds[0]; }
function bgTab() {
  const b = curBg();
  const upd = fn => v => { fn(v); commit('bg'); };
  const list = h('div', { class: 'list', style: { width: '240px', flex: 'none', border: '1px solid var(--line)', borderRadius: '6px', maxHeight: '230px', overflow: 'auto' } }, P.backgrounds.map(x => h('div', { class: 'item' + (b && x.id === b.id ? ' sel' : ''), onclick: () => { S.bgId = x.id; P.scene.backgroundId = x.id; commit('selBg'); } },
    h('span', { class: 'swatch', style: { background: x.type === 'gradient' ? `linear-gradient(${x.color},${x.color2})` : x.color } }), h('span', { class: 'nm' }, x.name), P.scene.backgroundId === x.id ? h('span', { class: 'chip' }, '✓') : null,
    btn('⧉', e => { e.stopPropagation(); const n = clone(x); n.id = newId('bg'); n.name += ' کپی'; P.backgrounds.push(n); S.bgId = n.id; commit('dupBg'); }, 'ib'),
    btn('🗑', e => { e.stopPropagation(); P.backgrounds = P.backgrounds.filter(y => y !== x); if (P.scene.backgroundId === x.id) P.scene.backgroundId = P.backgrounds[0] ? P.backgrounds[0].id : null; S.bgId = null; commit('delBg'); }, 'ib danger'))));
  const add = btn('＋ پس‌زمینه', () => { const n = { id: newId('bg'), name: 'Background ' + (P.backgrounds.length + 1), type: 'solid', color: '#334155', color2: '#0f172a', angle: 0, pattern: { kind: 'none', color: '#ffffff', size: 8, opacity: 0.15 }, image: null, x: 0, y: 0, scale: 1, opacity: 1, effects: { vignette: 0, scanlines: 0, noise: 0 } }; P.backgrounds.push(n); S.bgId = n.id; P.scene.backgroundId = n.id; commit('addBg'); }, 'primary');
  if (!b) return h('div', {}, add);
  b.pattern = b.pattern || { kind: 'none', color: '#ffffff', size: 8, opacity: 0.15 }; b.effects = b.effects || { vignette: 0, scanlines: 0, noise: 0 };
  return h('div', { style: { display: 'flex', gap: '14px', flexWrap: 'wrap' } }, h('div', {}, list, add, h('label', { class: 'row' }, chkIn(P.scene.bgVisible, upd(v => (P.scene.bgVisible = v))), ' نمایش پس‌زمینه')),
    h('div', { class: 'grid2', style: { flex: 1, minWidth: '300px' } },
      row('نام', txtIn(b.name, upd(v => (b.name = v)))), row('نوع', selIn(b.type, [['solid', 'Color'], ['gradient', 'Gradient'], ['image', 'Image']], upd(v => (b.type = v)))),
      row('رنگ ۱', colIn(b.color, upd(v => (b.color = v)))), row('رنگ ۲', colIn(b.color2, upd(v => (b.color2 = v)))), row('زاویه', numIn(b.angle, upd(v => (b.angle = v)), { step: 15 })),
      row('تصویر', h('input', { type: 'file', accept: 'image/*', onchange: e => { const fl = e.target.files[0]; if (!fl) return; const r = new FileReader(); r.onload = () => { b.image = r.result; b.type = 'image'; commit('bgimg'); }; r.readAsDataURL(fl); } }), b.image ? btn('×', upd(() => { b.image = null; }), 'ib') : null),
      row('X / Y', numIn(b.x, upd(v => (b.x = v))), numIn(b.y, upd(v => (b.y = v)))), row('Scale', numIn(b.scale, upd(v => (b.scale = clamp(v, 0.05, 20))), { step: 0.1 })), row('Opacity', rangeIn(b.opacity, upd(v => (b.opacity = v)), 0, 1, 0.05)),
      row('Pattern', selIn(b.pattern.kind || 'none', ['none', 'dots', 'stripes', 'checker', 'grid'].map(k => [k, k]), upd(v => (b.pattern.kind = v)))), row('رنگ Pattern', colIn(b.pattern.color, upd(v => (b.pattern.color = v)))),
      row('اندازه Pattern', numIn(b.pattern.size, upd(v => (b.pattern.size = clamp(v, 2, 64))))), row('شفافیت Pattern', rangeIn(b.pattern.opacity, upd(v => (b.pattern.opacity = v)), 0, 1, 0.05)),
      row('Vignette', rangeIn(b.effects.vignette, upd(v => (b.effects.vignette = v)), 0, 1, 0.05)), row('Scanlines', rangeIn(b.effects.scanlines, upd(v => (b.effects.scanlines = v)), 0, 1, 0.05)), row('Noise', rangeIn(b.effects.noise, upd(v => (b.effects.noise = v)), 0, 1, 0.05))));
}
function sceneTab() {
  const sc = P.scene, u = fn => v => { fn(v); commit('scene'); };
  const sect = (title, o, fields) => h('div', {}, h('label', { class: 'row' }, chkIn(o.on, u(v => (o.on = v))), h('b', {}, ' ' + title)), ...fields);
  return h('div', { class: 'grid2' },
    sect('Shadow', sc.shadow, [row('رنگ', colIn(sc.shadow.color, u(v => (sc.shadow.color = v)))), row('Opacity', rangeIn(sc.shadow.opacity, u(v => (sc.shadow.opacity = v)), 0, 1, 0.05)), row('W × H', numIn(sc.shadow.w, u(v => (sc.shadow.w = v))), numIn(sc.shadow.h, u(v => (sc.shadow.h = v)))), row('X / Y', numIn(sc.shadow.x, u(v => (sc.shadow.x = v))), numIn(sc.shadow.y, u(v => (sc.shadow.y = v))))]),
    sect('Ground', sc.ground, [row('رنگ', colIn(sc.ground.color, u(v => (sc.ground.color = v)))), row('Opacity', rangeIn(sc.ground.opacity, u(v => (sc.ground.opacity = v)), 0, 1, 0.05)), row('ارتفاع', numIn(sc.ground.height, u(v => (sc.ground.height = v))))]),
    sect('Lighting', sc.lighting, [row('رنگ', colIn(sc.lighting.color, u(v => (sc.lighting.color = v)))), row('زاویه', numIn(sc.lighting.angle, u(v => (sc.lighting.angle = v)), { step: 15 })), row('Opacity', rangeIn(sc.lighting.opacity, u(v => (sc.lighting.opacity = v)), 0, 1, 0.05))]),
    sect('Glow', sc.glow, [row('رنگ', colIn(sc.glow.color, u(v => (sc.glow.color = v)))), row('Radius', numIn(sc.glow.radius, u(v => (sc.glow.radius = v)))), row('Opacity', rangeIn(sc.glow.opacity, u(v => (sc.glow.opacity = v)), 0, 1, 0.05)), row('X / Y', numIn(sc.glow.x, u(v => (sc.glow.x = v))), numIn(sc.glow.y, u(v => (sc.glow.y = v))))]));
}
function previewsTab() {
  const wrap = h('div', { class: 'row wrap', style: { gap: '16px', alignItems: 'flex-end' } });
  for (const [k, label, w, hh] of PREVIEWS) { const c = h('canvas', { width: w, height: hh, style: { width: w * 2 + 'px', height: hh * 2 + 'px', imageRendering: 'pixelated', border: '1px solid var(--line)', background: 'var(--chk)' } }); renderPreview(k, c, true); wrap.append(h('figure', { style: { margin: 0, textAlign: 'center' } }, c, h('figcaption', { class: 'muted' }, label + ` ${w}×${hh}`))); }
  return wrap;
}
