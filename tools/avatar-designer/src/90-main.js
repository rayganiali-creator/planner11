'use strict';
// ===== راه‌اندازی، نوار ابزار، میان‌برها، مدیریت پروژه‌ها =====

function renderAll() {
  if (!P) return;
  renderToolbar(); renderLeft(); renderRight(); renderBottom(); renderStage();
}
function renderPanelsOnly() { renderLeft(); renderRight(); renderBottom(); }

function renderToolbar() {
  const v = P.view, tg = (k, l, t) => h('button', { class: v[k] ? 'on' : '', title: t, onclick: () => { v[k] = !v[k]; scheduleSave(); renderToolbar(); renderStage(); } }, l);
  $('#toolbar').replaceChildren(
    h('span', { class: 'title' }, '🎨 Avatar Studio'),
    h('input', { type: 'text', id: 'projname', value: P.name, onchange: e => { P.name = e.target.value || 'Avatar Project'; commit('rename'); } }),
    btn('Projects', openProjects), btn('New', newProject), btn('Duplicate', dupProject), btn('Reset', resetProject, 'danger'),
    h('span', { class: 'sep' }), btn('↶', undo, '', 'Undo (Ctrl+Z)'), btn('↷', redo, '', 'Redo (Ctrl+Shift+Z)'),
    h('span', { class: 'sep' }),
    h('button', { class: S.tool === 'select' ? 'on' : '', onclick: () => { S.tool = 'select'; renderToolbar(); } }, '↖ Select'),
    h('button', { class: S.tool === 'pan' ? 'on' : '', onclick: () => { S.tool = 'pan'; renderToolbar(); } }, '✋ Pan'),
    h('button', { class: S.partMode ? 'on' : '', title: 'حرکت دادن قطعه‌ی انتخابی روی صحنه', onclick: () => { S.partMode = !S.partMode; renderToolbar(); renderStage(); } }, '🧩 Part mode'),
    h('span', { class: 'sep' }),
    tg('showGrid', 'Grid'), tg('snap', 'Snap'), tg('showRuler', 'Ruler'), tg('showSafe', 'Safe'), tg('showCenter', 'Center'), tg('showLayerBoxes', 'Boxes'),
    btn('Guide |', () => { v.guides.push({ axis: 'v', pos: Math.round(P.canvas.w / 2) }); commit('guide'); }), btn('Guide —', () => { v.guides.push({ axis: 'h', pos: Math.round(P.canvas.h / 2) }); commit('guide'); }), btn('Clear guides', () => { v.guides = []; commit('guide'); }),
    h('span', { class: 'sep' }),
    h('span', {}, 'Character '), selIn(P.scene.characterId || '', P.characters.map(c => [c.id, c.name]), id => { P.scene.characterId = id; commit('char'); }),
    h('span', {}, ' Mood '), selIn(P.scene.mood, MOODS.map(([k, l]) => [k, l]), m => { P.scene.mood = m; commit('mood'); }),
    h('span', { class: 'sep' }),
    btn('Import', importFile), btn('⬇ Export', openExportPreview, 'primary'),
    h('span', { id: 'status', class: 'muted', style: { marginInlineStart: '8px' } }, ''),
  );
  const hud = $('#stagehud');
  hud.replaceChildren(btn('−', () => zoomAt(ST.cv.clientWidth / 2, ST.cv.clientHeight / 2, 1 / 1.25)), h('span', { id: 'zoomlbl', style: { minWidth: '44px', textAlign: 'center' } }, ''), btn('+', () => zoomAt(ST.cv.clientWidth / 2, ST.cv.clientHeight / 2, 1.25)), btn('Fit', () => { fitView(); renderStage(); }), h('span', { id: 'coords', class: 'muted', style: { minWidth: '90px' } }, ''));
}

// ---- پروژه‌ها
async function loadProject(id) {
  const rec = await DB.get(id); if (!rec) return false;
  P = deserialize(JSON.parse(rec.json)); await preloadImages(P); resetHistory(); invalidateCache(); S.famId = null; S.partId = null; localStorage.setItem('ad:current', id); fitView(); renderAll(); return true;
}
async function startProject(p) { await preloadImages(p); P = p; resetHistory(); invalidateCache(); S.famId = null; S.partId = null; S.bgId = null; fitView(); saveNow(); renderAll(); }
function newProject() {
  const demo = confirm('با آواتار فعلیِ اپ شروع شود؟\nOK = آواتار فعلی اپ · Cancel = پروژه‌ی خالی');
  if (demo) startProject(seedProject());
  else { const p = emptyProject('Avatar Project'); p.characters.push({ id: newId('char'), name: 'Character 01', notes: '' }); p.scene.characterId = p.characters[0].id; startProject(p); }
}
function dupProject() { const c = deserialize(serialize(P)); c.id = newId('proj'); c.name = P.name + ' (copy)'; c.createdAt = Date.now(); startProject(c); toast('پروژه تکثیر شد'); }
function resetProject() { if (!confirm('پروژه به آواتار اولیه‌ی اپ برگردد؟ (با Undo می‌توانید برگردید)')) return; const imgs = P.images, id = P.id; const p = seedProject(); p.id = id; Object.assign(imgs, p.images); p.images = imgs; P = p; invalidateCache(); S.famId = null; S.partId = null; S.bgId = null; commit('reset'); fitView(); renderAll(); }
async function openProjects() {
  const all = (await DB.all()).sort((a, b) => b.updatedAt - a.updatedAt);
  const bg = h('div', { class: 'modal-bg', onclick: e => e.target === bg && bg.remove() }, h('div', { class: 'modal' }, h('h3', {}, h('span', { class: 'grow' }, 'پروژه‌ها (ذخیره‌ی محلی مرورگر)'), btn('✕', () => bg.remove())),
    h('div', { class: 'mb list' }, all.map(r => h('div', { class: 'item' + (r.id === P.id ? ' sel' : '') },
      h('span', { class: 'nm' }, r.name, ' ', h('small', {}, new Date(r.updatedAt).toLocaleString())),
      btn('باز کردن', async () => { await saveNow(); await loadProject(r.id); bg.remove(); }),
      btn('🗑', async () => { if (r.id === P.id) return toast('پروژه‌ی جاری را نمی‌توان حذف کرد'); if (confirm('حذف شود؟')) { await DB.del(r.id); bg.remove(); openProjects(); } }, 'danger')))))); 
  document.body.append(bg);
}
function importFile() {
  const inp = h('input', { type: 'file', accept: '.rpa,.json,application/json' });
  inp.onchange = async () => { const f = inp.files[0]; if (!f) return; try { importProjectText(await f.text()); } catch (e) { toast('فایل نامعتبر: ' + e.message); } };
  inp.click();
}
function importProjectText(txt) {
  const o = JSON.parse(txt);
  if (o.format !== 'rp-avatar-project') throw new Error('این فایل پروژه‌ی Avatar Studio (.rpa) نیست');
  const p = deserialize(o); p.id = newId('proj'); toast('پروژه وارد شد ✓'); return startProject(p);
}

// ---- میان‌برها
document.addEventListener('keydown', e => {
  if (!P || e.target.matches('input,textarea,select') || $('.modal-bg')) return;
  const k = e.key, ctrl = e.ctrlKey || e.metaKey;
  if (ctrl && k.toLowerCase() === 'z') { e.preventDefault(); e.shiftKey ? redo() : undo(); }
  else if (ctrl && k.toLowerCase() === 'y') { e.preventDefault(); redo(); }
  else if (k === ' ') { S.space = true; e.preventDefault(); }
  else if (k === 'ArrowLeft') { e.preventDefault(); nudge(e.shiftKey ? -8 : -1, 0); }
  else if (k === 'ArrowRight') { e.preventDefault(); nudge(e.shiftKey ? 8 : 1, 0); }
  else if (k === 'ArrowUp') { e.preventDefault(); nudge(0, e.shiftKey ? -8 : -1); }
  else if (k === 'ArrowDown') { e.preventDefault(); nudge(0, e.shiftKey ? 8 : 1); }
  else if (k === 'Delete') { const f = selFam(), L = f && layerOfFam(f.id); if (L) unequip(L.id); }
  else if (k === '+' || k === '=') zoomAt(ST.cv.clientWidth / 2, ST.cv.clientHeight / 2, 1.25);
  else if (k === '-') zoomAt(ST.cv.clientWidth / 2, ST.cv.clientHeight / 2, 1 / 1.25);
});
document.addEventListener('keyup', e => { if (e.key === ' ') S.space = false; });

async function init() {
  initStage();
  let ok = false;
  if (new URLSearchParams(location.search).has('fresh')) localStorage.removeItem('ad:current');
  if (localStorage.getItem('ad:seedver') !== '2') { localStorage.removeItem('ad:current'); localStorage.setItem('ad:seedver', '2'); } // نسخه‌ی قدیمیِ دمو را کنار بگذار (در Projects می‌ماند)
  const cur = localStorage.getItem('ad:current');
  if (cur) { try { ok = await loadProject(cur); } catch (e) { ok = false; } }
  if (!ok) { await startProject(seedProject()); }
  window.addEventListener('beforeunload', () => { saveNow(); });
  setStatus('آماده');
}
window.addEventListener('DOMContentLoaded', init);
