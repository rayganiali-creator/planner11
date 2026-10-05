const path = require('path'), fs = require('fs'), os = require('os');
const pw = require('playwright');
(async () => {
  const b = await pw.chromium.launch({ executablePath: process.env.CHROME || '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const pg = await b.newPage({ viewport: { width: 1400, height: 900 } });
  const errs = []; pg.on('pageerror', e => errs.push(e.message));
  const url = 'file://' + path.resolve(__dirname, '../dist/room.html');
  await pg.goto(url); await pg.waitForFunction(() => typeof S !== 'undefined' && document.querySelectorAll('#items .card').length > 0);
  let fails = 0; const A = (n, c) => { if (!c) fails++; console.log((c ? 'PASS ' : 'FAIL ') + n); }, ev = (f, a) => pg.evaluate(f, a);
  const cnt = await ev(() => Object.fromEntries(CATS.map(([k]) => [k, CATALOG.filter(c => c.cat === k).length])));
  A('catalog counts 10/5/5/10/10/5', JSON.stringify(Object.values(cnt)) === '[10,5,5,10,10,5]');
  { const r = await ev(() => { const u = new Set(); for (const d of CATALOG) { const s = spriteOf(d.id); const data = s.getContext('2d').getImageData(0, 0, s.width, s.height).data; let n = 0; for (let i = 3; i < data.length; i += 4) if (data[i]) n++; if (n < 40) return 'small ' + d.id + n; u.add(s.toDataURL()); } return u.size === 45 ? true : 'dups ' + u.size; }); if (r !== true) console.log(r); A('all 45 sprites distinct & non-empty', r === true); }
  A('room empty at start (no furniture) + a pet', await ev(() => S.placed.length === 0 && S.pet && PETS.length === 20));
  A('room has window, wooden wall & floor pixels', await ev(() => { const g = roomCanvas().getContext('2d'); const px = (x, y) => Array.from(g.getImageData(x, y, 1, 1).data); const wall = px(300, 60), floor = px(200, 190), win = px(WIN.x + 10, WIN.y + 10); return wall[0] > wall[2] + 30 && floor[0] > floor[2] + 30 && win[2] > win[0]; }));
  // خرید
  const c0 = await ev(() => S.coins);
  await ev(() => buy('plant_01')); A('buy deducts coins & adds to inventory', await ev(c => S.coins === c - 60 && S.owned.plant_01 === 1, c0));
  await ev(() => { S.coins = 10; }); await ev(() => buy('bed_05')); A('cannot buy without enough coins', await ev(() => !S.owned.bed_05 && S.coins === 10));
  await pg.click('#tabs button:has-text("تخت")'); A('buy button disabled when poor', await pg.evaluate(() => [...document.querySelectorAll('#items .card button.primary')].every(b => b.disabled)));
  await ev(() => { S.coins = 100000; renderAll(); });
  // خرید و قرار دادن همه‌ی ۴۰ آیتم + چیدن
  await ev(() => { for (const d of CATALOG) buy(d.id); });
  A('bought all items', await ev(() => CATALOG.every(d => (S.owned[d.id] || 0) >= 1)));
  A('cannot place un-owned dup beyond owned', await ev(() => { place('bed_01'); place('bed_01'); return placedCount('bed_01') === 1; }));
  await ev(() => { S.placed = []; for (const d of CATALOG) place(d.id); });
  A('all items placed inside their zones', await ev(() => S.placed.every(p => { const d = itemDef(p.id), b = bounds(p); return b.x >= 0 && b.x + b.w <= W && (d.zone !== 'wall' || b.y + b.h <= FLOOR) && (d.zone !== 'floor' || p.y >= FLOOR); })));
  // کشیدن با ماوس
  await ev(() => { S.placed = []; S.sel = null; place('table_02'); S.placed[0].x = 120; S.placed[0].y = 180; dirty(); });
  await pg.waitForTimeout(400);
  const pt = await ev(() => { const r = cv().getBoundingClientRect(), p = S.placed[0], b = bounds(p), s = spriteOf(p.id); let sp; for (let y = 0; y < s.height && !sp; y++) for (let x = 0; x < s.width && !sp; x++) if (s.getContext('2d').getImageData(x, y, 1, 1).data[3] > 100 && y > 6) sp = [b.x + x, b.y + y]; return [r.left + sp[0] / W * r.width, r.top + sp[1] / H * r.height, r.width / W, p.x, p.y]; });
  await pg.mouse.move(pt[0], pt[1]); await pg.mouse.down(); await pg.mouse.move(pt[0] + 60 * pt[2], pt[1] - 20 * pt[2], { steps: 6 }); await pg.mouse.up();
  A('drag moves furniture on floor', await ev(([x, y]) => S.placed[0].x > x + 40 && S.placed[0].y < y && S.placed[0].y >= FLOOR + 6, [pt[3], pt[4]]));
  A('drag clamps furniture to the floor', await ev(() => { const p = S.placed[0]; p.x = 5000; p.y = -500; clampPos(p); return p.x <= W && p.y >= FLOOR + 6; }));
  A('wall item clamps to wall', await ev(() => { place('frame_01'); const p = S.placed[S.placed.length - 1]; p.y = 900; clampPos(p); const b = bounds(p); return b.y + b.h <= FLOOR; }));
  A('plant can sit on a table (free zone, z-order)', await ev(() => { place('plant_02'); const p = S.placed[S.placed.length - 1]; p.x = S.placed[0].x; p.y = 100; clampPos(p); return p.y === 100; }));
  await ev(() => { S.sel = S.placed[S.placed.length - 1].uid; zSel(1); }); A('bring forward changes z', await ev(() => S.placed[S.placed.length - 1].z === 1));
  A('return to inventory keeps ownership', await ev(() => { const n = S.placed.length, o = S.owned.plant_02; unplace(); return S.placed.length === n - 1 && S.owned.plant_02 === o && freeCount('plant_02') === o; }));
  // حیوان
  A('pet placed anywhere & switchable', await ev(() => { setPet('pets/05_owl'); S.pet.x = 60; S.pet.y = 100; clampPos(S.pet); S.sel = 'pet'; flipSel(); S.pet.sleep = true; return S.pet.id === 'pets/05_owl' && S.pet.y === 100 && S.pet.flip === true; }));
  await ev(() => { S.placed = []; S.pet.x = 192; S.pet.y = 180; S.pet.sleep = false; dirty(); }); await pg.waitForTimeout(500);
  A('pet hit-test + drag works', await (async () => { const r = await ev(() => { const r = cv().getBoundingClientRect(); return [r.left + 192 / W * r.width, r.top + 160 / H * r.height, r.width / W]; }); await pg.mouse.move(r[0], r[1]); await pg.mouse.down(); await pg.mouse.move(r[0] - 50 * r[2], r[1] - 30 * r[2], { steps: 5 }); await pg.mouse.up(); return ev(() => S.sel === 'pet' && S.pet.x < 160 && S.pet.y < 180); })());
  // ساعت‌ها پویا
  A('analog clock hands follow real time', await ev(() => { const d = itemDef('clock_01'), c = document.createElement('canvas'); c.width = 40; c.height = 40; const g = c.getContext('2d'); const f = h => { g.clearRect(0, 0, 40, 40); clockDyn(g, d.dyn, 0, 0, new Date(2026, 0, 1, h, 0, 0)); return c.toDataURL(); }; return f(3) !== f(9) && f(12) !== f(6); }));
  A('digital clock shows digits', await ev(() => { const d = itemDef('clock_04'), c = document.createElement('canvas'); c.width = 40; c.height = 20; const g = c.getContext('2d'); clockDyn(g, d.dyn, 0, 0, new Date(2026, 0, 1, 12, 34, 0)); const a = c.toDataURL(); g.clearRect(0, 0, 40, 20); clockDyn(g, d.dyn, 0, 0, new Date(2026, 0, 1, 21, 58, 0)); return a !== c.toDataURL(); }));
  // روز/شب
  A('window outside changes day/night', await ev(() => { S.night = 'day'; roomKey = ''; const d = roomCanvas().toDataURL(); S.night = 'night'; roomKey = ''; const n = roomCanvas().toDataURL(); S.night = 'auto'; roomKey = ''; return d !== n; }));
  // ذخیره و بازیابی
  await ev(() => { S.placed = []; S.coins = 777; place('rug_05'); save(); });
  await pg.reload(); await pg.waitForFunction(() => typeof S !== 'undefined' && document.querySelectorAll('#items .card').length > 0);
  A('state persists across reload', await ev(() => S.coins === 777 && S.placed.length === 1 && S.placed[0].id === 'rug_05' && S.owned.rug_05 >= 1));
  // رندر نهایی پر از آیتم برای بازبینی چشمی
  await ev(() => { S = Object.assign(S, { placed: [], night: 'day' }); roomKey = ''; const put = (id, x, y, z) => { place(id); const p = S.placed[S.placed.length - 1]; p.x = x; p.y = y; p.z = z || 0; clampPos(p); }; put('rug_05', 170, 196); put('rug_01', 300, 205); put('bed_02', 320, 168); put('table_01', 110, 184); put('plant_03', 110, 150, 1); put('plant_07', 40, 178); put('frame_02', 190, 40); put('frame_05', 235, 52); put('clock_03', 165, 90); put('clock_05', 345, 70); put('plant_10', 20, 150); S.pet = { id: 'pets/02_dog', pet: true, x: 220, y: 200, flip: false, sleep: false, z: 0 }; S.sel = null; renderAll(); });
  await pg.waitForTimeout(600);
  await pg.screenshot({ path: path.join(os.tmpdir(), 'room-full.png') });
  // محیط سندباکس
  const sb = await b.newPage({ viewport: { width: 1300, height: 800 } }); const sbe = []; sb.on('pageerror', e => sbe.push(e.message));
  await sb.setContent('<iframe id=f sandbox="allow-scripts" style="width:1280px;height:780px;border:0"></iframe>');
  await sb.evaluate(h => { document.getElementById('f').srcdoc = h; }, fs.readFileSync(path.resolve(__dirname, '../dist/room.html'), 'utf8'));
  await sb.waitForTimeout(2000); const fr = sb.frames()[1];
  A('sandboxed iframe works (storage blocked)', await fr.evaluate(() => document.querySelectorAll('#items .card').length > 0 && CATALOG.length === 45).catch(() => false) && sbe.length === 0);
  await fr.evaluate(() => { buy('plant_01'); place('plant_01'); }); A('sandbox: buy & place', await fr.evaluate(() => S.placed.length === 1));
  A('no page errors', errs.length === 0); if (errs.length) console.log(errs);
  await b.close(); process.exit(fails ? 1 : 0);
})();
