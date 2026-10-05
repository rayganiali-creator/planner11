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

  // seed
  const c0 = await ev(() => ({ ch: P.characters.length, fam: P.families.length, va: P.families.reduce((n, f) => n + f.variants.length, 0), mo: Object.keys(P.moods).length, bg: P.backgrounds.length, items: sceneItems().length }));
  A('seed counts', c0.ch === 2 && c0.fam >= 20 && c0.va >= 40 && c0.mo === 7 && c0.bg === 6 && c0.items >= 10);
  // render non-empty
  A('stage draws pixels', await ev(() => { const d = ST.cv.getContext('2d').getImageData(0, 0, ST.cv.width, ST.cv.height).data; let n = 0; for (let i = 0; i < d.length; i += 4 * 97) if (d[i] > 60) n++; return n > 50; }));
  // variants share geometry
  A('variants share geometry', await ev(() => { const f = P.families.find(f => f.category === 'shirt'); const g = JSON.stringify(geomFor(f, P.scene.characterId)); f.variants.forEach(v => { P.scene.equipped.L_shirt = { familyId: f.id, variantId: v.id }; }); return f.variants.length >= 2 && JSON.stringify(geomFor(f, P.scene.characterId)) === g; }));
  // variant recolor changes pixels
  A('variant recolor', await ev(() => { const f = P.families.find(f => f.category === 'shirt'); const a = familySprite(f, f.variants[0]).canvas.toDataURL(), b = familySprite(f, f.variants[1]).canvas.toDataURL(); return a !== b; }));
  // mood swap
  A('mood swaps only mouth', await ev(() => { const key = () => sceneItems().map(i => i.fam.id + i.variant.id).join(); P.scene.mood = 'neutral'; const a = sceneItems(); P.scene.mood = 'happy'; const b = sceneItems(); const diff = a.filter((x, i) => x.fam.id !== b[i].fam.id).map(x => x.layer.category); return diff.length === 1 && diff[0] === 'mouth'; }));
  // drag move on stage -> geometry changes and undo reverts
  const before = await ev(() => { P.scene.mood = 'neutral'; const f = P.families.find(f => f.category === 'sword'); selectFam(f); return JSON.stringify(geomFor(f, P.scene.characterId)); });
  await ev(() => { const f = selFam(); const g = geomFor(f, P.scene.characterId); setGeom(f, { x: g.x + 6, y: g.y - 3 }); commit('t'); });
  A('geometry edit', await ev(() => geomFor(selFam(), P.scene.characterId).x === 71));
  await ev(() => undo());
  A('undo restores', await ev(b => JSON.stringify(geomFor(selFam() || P.families.find(f => f.category === 'sword'), P.scene.characterId)) === b, before));
  await ev(() => redo()); A('redo', await ev(() => geomFor(P.families.find(f => f.category === 'sword'), P.scene.characterId).x === 71));
  // real mouse drag on canvas
  await ev(() => { fitView(); renderStage(); const it = sceneItems().find(i => i.layer.category === 'body'); selectFam(it.fam); });
  const pt = await ev(() => { const it = selItem(), q = itemQuad(it), cx = (q[0][0] + q[2][0]) / 2, cy = (q[0][1] + q[2][1]) / 2, [sx, sy] = toScreen(cx, cy), r = ST.cv.getBoundingClientRect(); return [r.left + sx, r.top + sy, it.g.x]; });
  await pg.mouse.move(pt[0], pt[1]); await pg.mouse.down(); await pg.mouse.move(pt[0] + 40, pt[1], { steps: 5 }); await pg.mouse.up();
  A('mouse drag moves asset', await ev(x => selItem().g.x > x + 3, pt[2]));
  await ev(() => undo());
  // pixel edit via editor API
  const px = await ev(() => { const f = P.families.find(f => f.category === 'hat') || P.families[0]; const p = f.parts[0]; const E = openPixelEditor(f, p); return [f.id, p.id, E.w, E.h]; });
  await pg.waitForSelector('#pe canvas');
  const box = await (await pg.$('#pe canvas')).boundingBox();
  const cell = box.width / px[2];
  await pg.click('#pe .tools button:nth-child(1)');
  await pg.mouse.move(box.x + cell * 2.5, box.y + cell * 2.5); await pg.mouse.down(); await pg.mouse.move(box.x + cell * 6.5, box.y + cell * 2.5, { steps: 4 }); await pg.mouse.up();
  await pg.click('#pe .tools button:nth-child(4)'); // rect
  await pg.mouse.move(box.x + cell * 3.5, box.y + cell * 4.5); await pg.mouse.down(); await pg.mouse.move(box.x + cell * 7.5, box.y + cell * 7.5, { steps: 3 }); await pg.mouse.up();
  await pg.click('#pe .tools button:nth-child(6)'); await pg.mouse.click(box.x + cell * 3.5, box.y + cell * 12.5); // fill
  await pg.click('.modal h3 button.primary');
  A('pixel editor saved drawing', await ev(([fid, pid]) => { const p = famById(fid).parts.find(x => x.id === pid); return p.px[2 * p.w + 2] > 0 && p.px[2 * p.w + 6] > 0; }, px));
  // export -> import lossless
  const rt = await ev(() => { const a = JSON.stringify(serialize(P)); const bb = deserialize(JSON.parse(a)); return a === JSON.stringify(serialize(bb)); });
  A('serialize roundtrip', rt);
  const rt2 = await ev(() => { const a = JSON.stringify(serialize(P)); const keep = P.id; importProjectText(a); const b = JSON.stringify(serialize(P)); const o = JSON.parse(a), n = JSON.parse(b); delete o.id; delete n.id; delete o.updatedAt; delete n.updatedAt; return JSON.stringify(o) === JSON.stringify(n) && P.id !== keep; });
  A('import project lossless', rt2);
  const sysA = await ev(() => JSON.stringify(buildSystem().avatarSystem.assetFamilies));
  await ev(() => { const a = JSON.stringify(serialize(P)); importProjectText(a); });
  A('system export stable after import', sysA === await ev(() => JSON.stringify(buildSystem().avatarSystem.assetFamilies)));
  // export content
  const sys = await ev(() => buildSystem());
  const a = sys.avatarSystem;
  A('avatarSystem keys', ['version', 'characters', 'assetFamilies', 'variants', 'layers', 'moods', 'backgrounds', 'geometry', 'palette', 'assets', 'relationships', 'instructions'].every(k => k in a));
  A('asset manifest fields', ['id', 'familyId', 'category', 'name', 'variant', 'width', 'height', 'x', 'y', 'scale', 'rotation', 'opacity', 'layer', 'anchor', 'flipX', 'flipY', 'visible', 'locked', 'color', 'tags', 'mood', 'characterCompatibility'].every(k => k in a.assets[0]));
  A('counts consistent', a.variants.length === a.assets.length && a.layers.length === 20);
  // ZIP
  const [dl] = await Promise.all([pg.waitForEvent('download'), ev(async () => { const z = makeZip(await buildZipFiles()); download('t.zip', z); })]);
  const zp = path.join(require('os').tmpdir(), 'ad-test.zip'); await dl.saveAs(zp);
  const { execSync } = require('child_process');
  let ok = true; try { execSync(`python3 -c "import zipfile,sys;z=zipfile.ZipFile('${zp}');assert z.testzip() is None;n=z.namelist();assert 'avatar-system.json' in n and 'CLAUDE_AVATAR_IMPLEMENTATION.md' in n and any(x.startswith('sprites/') for x in n) and 'project.rpa' in n;print(len(n),'files')"`, { stdio: 'inherit' }); } catch { ok = false; }
  A('zip valid', ok);
  // zip project.rpa roundtrips
  A('zip project.rpa imports', await (async () => { const txt = execSync(`python3 -c "import zipfile;print(zipfile.ZipFile('${zp}').read('project.rpa').decode(),end='')"`, { maxBuffer: 1 << 28 }).toString(); return ev(t => { importProjectText(t); return P.families.length > 0; }, txt); })());
  // new project from scratch + empty family
  A('empty project works', await ev(() => { const p = emptyProject('x'); p.characters.push({ id: 'c1', name: 'c', notes: '' }); p.scene.characterId = 'c1'; startProject(p); newBlankFamily('hat'); const e = document.querySelector('.modal-bg'); if (e) e.querySelector('button').click(); return P.families.length === 1; }));
  await pg.screenshot({ path: path.join(require('os').tmpdir(), 'ad-shot.png') });
  A('no page errors', errs.length === 0); if (errs.length) console.log(errs);
  await b.close(); process.exit(fails ? 1 : 0);
})();
