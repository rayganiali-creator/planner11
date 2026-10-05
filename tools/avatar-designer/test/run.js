// Playwright: node test/run.js  (needs playwright + chromium)
const path = require('path');
let pw; try { pw = require('playwright'); } catch { pw = require(path.resolve(__dirname, '../../html-harness/node_modules/playwright')); }
const assert = require('assert');
(async () => {
  const b = await pw.chromium.launch({ executablePath: process.env.CHROME || '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const pg = await b.newPage({ viewport: { width: 1500, height: 900 }, acceptDownloads: true });
  const errs = []; pg.on('pageerror', e => errs.push(e.message)); pg.on('console', m => m.type() === 'error' && errs.push(m.text()));
  await pg.goto('file://' + path.resolve(__dirname, '../dist/avatar-designer.html'));
  await pg.waitForFunction(() => typeof P!=='undefined' && P && document.querySelector('#left .item'), null, {timeout:8000}).catch(e=>{console.log('ERRS',errs);throw e});
  console.log('early errs', errs);
  const T = (n, ok) => console.log((ok ? 'PASS ' : 'FAIL ') + n), ev = (f, a) => pg.evaluate(f, a);
  let fails = 0; const A = (n, c) => { if (!c) fails++; T(n, c); };

  // seed (آواتار واقعی اپ)
  const c0 = await ev(() => ({ ch: P.characters.length, fam: P.families.length, im: Object.keys(P.images).length, va: P.families.reduce((n, f) => n + f.variants.length, 0), items: sceneItems().length, layers: P.layers.length }));
  A('app seed counts', c0.ch === 2 && c0.fam === 258 && c0.im > 250 && c0.va > 270 && c0.items >= 7);
  A('stage draws pixels', await ev(() => { const d = ST.cv.getContext('2d').getImageData(0, 0, ST.cv.width, ST.cv.height).data; let n = 0; for (let i = 0; i < d.length; i += 4 * 97) if (d[i] > 60) n++; return n > 50; }));
  A('body variants share geometry & differ', await ev(() => { const f = famById('base_male'); const g = JSON.stringify(geomFor(f, P.scene.characterId)); return f.variants.length === 5 && JSON.stringify(geomFor(f, P.scene.characterId)) === g && familySprite(f, f.variants[0]).canvas.toDataURL() !== familySprite(f, f.variants[3]).canvas.toDataURL(); }));
  // parity با منطق ترکیبِ اپ (Python مستقل از Studio)
  const combos = { male: [['base_male', 2], ['hair/hair_03#male', 0], ['clothes/top_02#male', 0], ['pants/pants_05#male', 0], ['shoes/shoes_03#male', 0], ['sword/weapon_04#male', 0], ['shield/shield_02#male', 0], ['hands_male', 2], ['cape/cape_01#male', 0], ['cape/cape_01#male#back', 0], ['armor/armor_01#male', 0]],
    female: [['base_female', 1], ['hijab/hijab_03#female', 0], ['clothes/ow_01#female', 0], ['shoes/shoes_02#female', 0], ['sword/weapon_02#female', 0], ['hands_female', 1], ['cape/cape_01#female', 0], ['cape/cape_01#female#back', 0]] };
  const fs = require('fs'), os = require('os'), { execSync } = require('child_process');
  for (const g of ['male', 'female']) {
    const ids = await ev(([g, list]) => { P.scene.characterId = 'char_' + g; P.scene.equipped = {}; P.scene.bgVisible = false; for (const k of ['shadow', 'ground', 'lighting', 'glow']) P.scene[k].on = false;
      const out = []; for (const [fid, vi] of list) { const f = famById(fid); if (!f) { out.push(fid + ' MISSING'); continue; } const L = P.layers.find(l => l.category === f.category); P.scene.equipped[L.id] = { familyId: f.id, variantId: f.variants[vi].id }; out.push(f.meta.appItemId || (f.meta.appItemIds || [])[vi] || f.id); }
      invalidateCache(); const c = mkCanvas(P.canvas.w, P.canvas.h); drawScene(c.getContext('2d')); return { url: c.toDataURL(), out }; }, [g, combos[g]]);
    A(`${g}: all combo families exist`, !ids.out.some(x => x.includes('MISSING')));
    fs.writeFileSync(os.tmpdir() + `/ad-${g}.png`, Buffer.from(ids.url.split(',')[1], 'base64'));
    fs.writeFileSync(os.tmpdir() + `/ad-${g}.json`, JSON.stringify(combos[g]));
    let out = ''; try { out = execSync(`python3 test/parity.py ${g}`, { encoding: 'utf8' }); } catch (e) { out = e.stdout + e.stderr; }
    console.log(out.trim()); A(`${g}: Studio render == app compose rules`, /PARITY OK/.test(out));
  }
  await ev(async () => { await startProject(seedProject()); });
  await ev(async () => { await startProject(seedProject()); });
  // تعویض کاراکتر: آواتار زن/مرد هر دو با لباس معادل بارگذاری می‌شوند
  A('switch character swaps equipped items', await ev(() => { setCharacter('char_female'); const f = sceneItems().map(i => i.fam.id); const okF = f.includes('base_female') && f.includes('hair/hair_01#female') === false && sceneItems().length >= 6 && sceneItems().every(i => compatible(i.fam, 'char_female')); const clothesF = sceneItems().some(i => i.layer.category === 'clothes'); setCharacter('char_male'); const m = sceneItems().map(i => i.fam.id); return okF && clothesF && m.includes('base_male') && m.includes('shoes/shoes_01#male'); }));
  // Mood: ۷ دهنِ طراحی‌شده؛ فقط لایه‌ی mouth عوض شود و دهن روی صورتِ هر دو کاراکتر بنشیند
  A('7 moods mapped to 7 mouth families', await ev(() => Object.keys(P.moods).length === 7 && MOODS.every(([m]) => famById(P.moods[m].familyId).category === 'mouth')));
  A('mood swaps only mouth layer', await ev(() => { P.scene.mood = 'neutral'; const x = sceneItems(); P.scene.mood = 'happy'; const y = sceneItems(); const d = x.filter((it, i) => it.fam.id !== y[i].fam.id).map(i => i.layer.category); P.scene.mood = 'neutral'; return x.length === y.length && d.length === 1 && d[0] === 'mouth'; }));
  A('mouths differ per mood & sit on both faces', await ev(() => { const urls = new Set(); let ok = true; for (const cid of ['char_male', 'char_female']) { setCharacter(cid); const base = sceneItems().find(i => i.layer.category === 'body'), bq = itemQuad(base); for (const [m] of MOODS) { P.scene.mood = m; invalidateCache(); const it = sceneItems().find(i => i.layer.category === 'mouth'); if (!it) { ok = false; continue; } const q = itemQuad(it); const cx = (q[0][0] + q[2][0]) / 2, cy = (q[0][1] + q[2][1]) / 2; const bw = bq[1][0] - bq[0][0], bh = bq[2][1] - bq[0][1]; ok = ok && cx > bq[0][0] + bw * 0.25 && cx < bq[0][0] + bw * 0.75 && cy > bq[0][1] + bh * 0.1 && cy < bq[0][1] + bh * 0.3; urls.add(cid + m + it.spr.canvas.toDataURL()); } } setCharacter('char_male'); P.scene.mood = 'neutral'; invalidateCache(); return ok && urls.size === 14; }));
  // ویرایش هندسه، Undo/Redo، درگ با ماوس
  const sw = await ev(() => { P.scene.mood = 'neutral'; const f = famById('sword/weapon_01#male'); selectFam(f); return JSON.stringify(geomFor(f, P.scene.characterId)); });
  await ev(() => { const f = selFam(); const g = geomFor(f, P.scene.characterId); setGeom(f, { x: g.x + 6, y: g.y - 3 }); commit('t'); });
  const x0 = JSON.parse(sw).x;
  A('geometry edit', await ev(x => geomFor(selFam(), P.scene.characterId).x === x + 6, x0));
  await ev(() => undo()); A('undo restores', await ev(b => JSON.stringify(geomFor(famById('sword/weapon_01#male'), P.scene.characterId)) === b, sw));
  await ev(() => redo()); A('redo', await ev(x => geomFor(famById('sword/weapon_01#male'), P.scene.characterId).x === x + 6, x0));
  await ev(() => { fitView(); renderStage(); selectFam(famById('base_male')); });
  const pt = await ev(() => { const it = selItem(); let sp = null; for (let y = 20; y < 180 && !sp; y++) for (let x = 30; x < 150 && !sp; x++) { const hit = hitItems(x, y); if (hit && hit.fam.id === 'base_male') sp = [x, y]; } const [sx, sy] = toScreen(sp[0], sp[1]), r = ST.cv.getBoundingClientRect(); return [r.left + sx, r.top + sy, it.g.x]; });
  await pg.mouse.move(pt[0], pt[1]); await pg.mouse.down(); await pg.mouse.move(pt[0] + 40, pt[1], { steps: 5 }); await pg.mouse.up();
  A('mouse drag moves asset', await ev(x => selItem().g.x > x + 3, pt[2]));
  await ev(() => undo());
  // ایمپورت PNG واقعی به‌عنوان Asset جدید
  const png = os.tmpdir() + '/ad-import.png'; fs.writeFileSync(png, Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAEklEQVR4nGP4z8DwHwyBNBgAAIrfD/N1n4HvAAAAAElFTkSuQmCC', 'base64'));
  const [fc] = await Promise.all([pg.waitForEvent('filechooser'), pg.click('text=ایمپورت PNG')]); await fc.setFiles(png); await pg.waitForTimeout(400);
  A('png import creates image family', await ev(() => { const f = P.families[P.families.length - 1]; return f.parts[0].img && P.images[f.parts[0].img] && f.parts[0].w === 4 && !!layerOfFam(f.id); }));
  // ویرایشگر پیکسلی روی خانواده‌ی خالی
  await ev(() => { newBlankFamily('hat'); }); await pg.waitForSelector('#pe canvas');
  const box = await (await pg.$('#pe canvas')).boundingBox(), cell = box.width / 16;
  await pg.click('#pe .tools button:nth-child(1)'); await pg.mouse.move(box.x + cell * 2.5, box.y + cell * 2.5); await pg.mouse.down(); await pg.mouse.move(box.x + cell * 6.5, box.y + cell * 2.5, { steps: 4 }); await pg.mouse.up();
  await pg.click('#pe .tools button:nth-child(4)'); await pg.mouse.move(box.x + cell * 3.5, box.y + cell * 4.5); await pg.mouse.down(); await pg.mouse.move(box.x + cell * 7.5, box.y + cell * 7.5, { steps: 3 }); await pg.mouse.up();
  await pg.click('.modal h3 button.primary');
  A('pixel editor saved drawing', await ev(() => { const f = P.families[P.families.length - 1], p = f.parts[0]; return p.px[2 * p.w + 2] > 0 && p.px[2 * p.w + 6] > 0; }));
  // ویرایش پیکسلیِ تصویرِ واقعی (PNG) — مو
  A('pixel-edit a real PNG part', await (async () => {
    await ev(() => { startProject(seedProject()); }); await pg.waitForTimeout(800);
    await ev(() => { const f = famById('hair/hair_01#male'); selectFam(f); S.bottomTab = 'parts'; renderBottom(); });
    const before = await ev(() => { const f = selFam(); return [f.parts[0].img, familySprite(f, f.variants[0]).canvas.toDataURL(), Object.keys(P.images).length]; });
    await pg.click('text=ویرایش پیکسلی'); await pg.waitForSelector('#pe canvas');
    const bx = await (await pg.$('#pe canvas')).boundingBox(); const dims = await ev(() => [document.querySelector('#pe canvas').width, document.querySelector('#pe canvas').height]);
    const cell = bx.width / (dims[0] / (dims[0] / bx.width * 1)) ; // fallback below
    const wcells = await ev(() => { const f = selFam(); return f.parts[0].w; });
    const cs = bx.width / wcells;
    await pg.click('#pe .pal input[type=color]', { force: true }).catch(() => {});
    await ev(() => { const i = document.querySelector('#pe .pal input[type=color]'); i.value = '#ff0000'; i.dispatchEvent(new Event('change')); });
    await pg.mouse.move(bx.x + cs * 10.5, bx.y + cs * 10.5); await pg.mouse.down(); await pg.mouse.move(bx.x + cs * 14.5, bx.y + cs * 10.5, { steps: 4 }); await pg.mouse.up();
    await pg.click('.modal h3 button.primary'); await pg.waitForTimeout(300);
    const after = await ev(() => { const f = selFam(); const c = familySprite(f, f.variants[0]); const x = 10 - c.ox, y = 10 - c.oy; const d = c.canvas.getContext('2d').getImageData(x, y, 1, 1).data; return [f.parts[0].img, c.canvas.toDataURL(), Object.keys(P.images).length, Array.from(d)]; });
    return after[0] !== before[0] && after[1] !== before[1] && after[2] === before[2] + 1 && after[3][0] === 255 && after[3][1] === 0 && after[3][3] === 255;
  })());
  // محیط سندباکس (مثل پیش‌نمایش داخل اپ): بدون localStorage/IndexedDB/prompt/confirm هم باید کار کند
  const sb = await b.newPage({ viewport: { width: 1300, height: 800 } }); const sbErr = []; sb.on('pageerror', e => sbErr.push(e.message));
  await sb.setContent('<iframe id=f sandbox="allow-scripts" style="width:1280px;height:780px;border:0"></iframe>');
  await sb.evaluate(h => { document.getElementById('f').srcdoc = h; }, fs.readFileSync(path.resolve(__dirname, '../dist/avatar-designer.html'), 'utf8'));
  const fr = await (async () => { for (let i = 0; i < 60; i++) { const f = sb.frames()[1]; if (f && await f.evaluate(() => typeof P !== 'undefined' && P && document.querySelectorAll('#left .item').length > 0).catch(() => false)) return f; await sb.waitForTimeout(300); } return null; })();
  A('sandboxed iframe loads (storage blocked)', !!fr && sbErr.length === 0);
  if (fr) {
    A('sandbox: characters & avatar rendered', await fr.evaluate(() => P.characters.length === 2 && sceneItems().length >= 8 && document.querySelectorAll('#toolbar button').length > 10));
    await fr.click('text=New'); A('sandbox: in-app dialog (no confirm())', await fr.evaluate(() => !!document.querySelector('.modal-bg')));
    await fr.click('.modal-bg button >> text=لغو');
    await fr.click('text=Characters'); await fr.click('text=＋ کاراکتر جدید'); A('sandbox: add character works', await fr.evaluate(() => P.characters.length === 3));
    await fr.click('text=Layers'); await fr.click('text=＋ لایه'); await fr.fill('.modal-bg input', 'تست'); await fr.click('.modal-bg button >> text=تأیید'); A('sandbox: add layer via dialog', await fr.evaluate(() => P.layers.some(l => l.name === 'تست')));
  }
  await sb.close();
  // پایداری: reload بعد از ذخیره
  await ev(() => saveNow()); const fam0 = await ev(() => P.families.length); await pg.reload(); await pg.waitForFunction(() => typeof P !== 'undefined' && P && P.families.length > 0 && document.querySelector('#left .item'));
  A('persists across reload (IndexedDB)', await ev(n => P.families.length === n && Object.keys(P.images).length > 250, fam0));
  // export -> import بدون افت
  A('serialize roundtrip', await ev(() => { const a = JSON.stringify(serialize(P)); return a === JSON.stringify(serialize(deserialize(JSON.parse(a)))); }));
  A('import project lossless', await ev(async () => { const a = JSON.stringify(serialize(P)); const keep = P.id; await importProjectText(a); const o = JSON.parse(a), n = JSON.parse(JSON.stringify(serialize(P))); for (const x of [o, n]) { delete x.id; delete x.updatedAt; } return JSON.stringify(o) === JSON.stringify(n) && P.id !== keep; }));
  const sysA = await ev(() => JSON.stringify(buildSystem().avatarSystem.assetFamilies));
  await ev(async () => { await importProjectText(JSON.stringify(serialize(P))); });
  A('system export stable after import', sysA === await ev(() => JSON.stringify(buildSystem().avatarSystem.assetFamilies)));
  // export content
  const sys = await ev(() => buildSystem());
  const a = sys.avatarSystem;
  A('avatarSystem keys', ['version', 'characters', 'assetFamilies', 'variants', 'layers', 'moods', 'backgrounds', 'geometry', 'palette', 'assets', 'relationships', 'instructions'].every(k => k in a));
  A('asset manifest fields', ['id', 'familyId', 'category', 'name', 'variant', 'width', 'height', 'x', 'y', 'scale', 'rotation', 'opacity', 'layer', 'anchor', 'flipX', 'flipY', 'visible', 'locked', 'color', 'tags', 'mood', 'characterCompatibility'].every(k => k in a.assets[0]));
  A('counts consistent', a.variants.length === a.assets.length && a.layers.length === 20 && Object.keys(a.imageFiles).length > 250);
  // ZIP
  const [dl] = await Promise.all([pg.waitForEvent('download'), ev(async () => { const z = makeZip(await buildZipFiles()); download('t.zip', z); })]);
  const zp = path.join(os.tmpdir(), 'ad-test.zip'); await dl.saveAs(zp);
  let ok = true; try { execSync(`python3 -c "import zipfile,sys;z=zipfile.ZipFile('${zp}');assert z.testzip() is None;n=z.namelist();assert 'avatar-system.json' in n and any(x.startswith('images/') for x in n) and 'CLAUDE_AVATAR_IMPLEMENTATION.md' in n and any(x.startswith('sprites/') for x in n) and 'project.rpa' in n;print(len(n),'files')"`, { stdio: 'inherit' }); } catch { ok = false; }
  A('zip valid', ok);
  // zip project.rpa roundtrips
  A('zip project.rpa imports', await (async () => { const txt = execSync(`python3 -c "import zipfile;print(zipfile.ZipFile('${zp}').read('project.rpa').decode(),end='')"`, { maxBuffer: 1 << 28 }).toString(); return ev(async t => { await importProjectText(t); return P.families.length > 200 && Object.keys(P.images).length > 250; }, txt); })());
  // new project from scratch + empty family
  A('empty project works', await ev(async () => { const p = emptyProject('x'); p.characters.push({ id: 'c1', name: 'c', notes: '' }); p.scene.characterId = 'c1'; await startProject(p); newBlankFamily('hat'); const e = document.querySelector('.modal-bg'); if (e) e.querySelector('button').click(); return P.families.length === 1; }));
  await pg.screenshot({ path: path.join(os.tmpdir(), 'ad-shot.png') });
  A('no page errors', errs.length === 0); if (errs.length) console.log(errs);
  await b.close(); process.exit(fails ? 1 : 0);
})();
