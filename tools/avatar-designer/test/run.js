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
  A('app seed counts', c0.ch === 2 && c0.fam === 251 && c0.im > 250 && c0.va > 270 && c0.items >= 7);
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
  // mood: دو دهان می‌سازیم و نگاشت می‌کنیم؛ فقط لایه‌ی mouth عوض شود
  A('mood swaps only mouth', await ev(() => {
    const mk = (nm, col) => { const f = newFamily(nm, 'mouth'); const p = newPart('m', 6, 2, -3, 0); p.px.fill(1); f.parts.push(p); f.slots[0].color = col; f.anchor = 'top-center'; f.geometry['*'] = newGeometry(90, 60); P.families.push(f); return f; };
    const a = mk('mouth-n', '#ff0000'), b = mk('mouth-h', '#00ff00'); P.moods.neutral = { familyId: a.id, variantId: a.variants[0].id }; P.moods.happy = { familyId: b.id, variantId: b.variants[0].id };
    P.scene.equipped.L_mouth = { familyId: a.id, variantId: a.variants[0].id }; P.scene.mood = 'neutral'; const x = sceneItems(); P.scene.mood = 'happy'; const y = sceneItems();
    const diff = x.filter((it, i) => it.fam.id !== y[i].fam.id).map(i => i.layer.category); return diff.length === 1 && diff[0] === 'mouth'; }));
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
