'use strict';
// ===== خروجی: avatarSystem JSON، مشخصات Markdown، CLAUDE_AVATAR_IMPLEMENTATION.md، پروژه (.rpa) و بسته‌ی ZIP =====

const FORMAT_VERSION = 1;
function resolvedColors(f, v) { return Object.fromEntries(f.slots.map(s => [s.id, slotColor(f, v, s.id)])); }
function layerIndex(cat) { return P.layers.findIndex(l => l.category === cat); }

function buildSystem() {
  const layers = P.layers.map((L, i) => ({ id: L.id, name: L.name, category: L.category, order: i, visible: L.visible, locked: L.locked }));
  const assetFamilies = P.families.map(f => ({
    id: f.id, name: f.name, category: f.category, anchor: f.anchor, tags: f.tags, characterIds: f.characterIds, shared: !f.characterIds.length,
    slots: f.slots, variantIds: f.variants.map(v => v.id),
    layerId: (P.layers.find(l => l.category === f.category) || {}).id || null,
    geometry: Object.fromEntries(Object.entries(f.geometry).map(([k, g]) => [k, { ...g }])),
    parts: f.parts.map(p => ({ id: p.id, name: p.name, width: p.w, height: p.h, x: p.dx, y: p.dy, scale: p.scale, rotation: p.rotation, flipX: p.flipX, flipY: p.flipY, visible: p.visible, rows: encodeRows(p) })),
  }));
  const variants = [];
  for (const f of P.families) for (const v of f.variants) {
    const o = Object.fromEntries(Object.entries(v.overrides || {}).filter(([, x]) => x && (x.visible === false || (x.colors && Object.keys(x.colors).length))));
    variants.push({ id: v.id, familyId: f.id, name: v.name, colors: resolvedColors(f, v), overrides: o, sprite: `sprites/${f.id}/${v.id}.png` });
  }
  const characters = P.characters.map(c => ({
    id: c.id, name: c.name, notes: c.notes || '',
    sharedFamilyIds: P.families.filter(f => !f.characterIds.length).map(f => f.id),
    exclusiveFamilyIds: P.families.filter(f => f.characterIds.includes(c.id)).map(f => f.id),
    geometryOverrides: Object.fromEntries(P.families.filter(f => f.geometry[c.id]).map(f => [f.id, f.geometry[c.id]])),
  }));
  const geometry = {};
  for (const f of P.families) geometry[f.id] = { anchor: f.anchor, base: f.geometry['*'], characterOverrides: Object.fromEntries(Object.entries(f.geometry).filter(([k]) => k !== '*')) };
  const palette = [...new Set(variants.flatMap(v => Object.values(v.colors)).concat(P.backgrounds.flatMap(b => [b.color, b.color2])))].sort();
  const assets = [];
  for (const f of P.families) {
    const L = P.layers.find(l => l.category === f.category), moodsOf = MOODS.filter(([m]) => P.moods[m] && P.moods[m].familyId === f.id).map(([m]) => m);
    for (const v of f.variants) {
      const s = familySprite(f, v), g = f.geometry['*'] || newGeometry();
      assets.push({ id: f.id + ':' + v.id, familyId: f.id, variantId: v.id, category: f.category, name: f.name, variant: v.name, width: s.w || 0, height: s.h || 0, x: g.x, y: g.y, scale: g.scale, rotation: g.rotation, opacity: g.opacity, layer: L ? L.id : null, layerOrder: L ? P.layers.indexOf(L) : -1, anchor: f.anchor, flipX: g.flipX, flipY: g.flipY, visible: L ? L.visible : true, locked: L ? L.locked : false, color: Object.values(resolvedColors(f, v))[0], tags: f.tags, mood: moodsOf, characterCompatibility: f.characterIds.length ? f.characterIds : 'all', sprite: `sprites/${f.id}/${v.id}.png`, spriteOffset: { x: s.ox || 0, y: s.oy || 0 } });
    }
  }
  const relationships = {
    familyToVariants: Object.fromEntries(P.families.map(f => [f.id, f.variants.map(v => v.id)])),
    variantsShareGeometryWithFamily: true,
    characterToFamilies: Object.fromEntries(P.characters.map(c => [c.id, P.families.filter(f => compatible(f, c.id)).map(f => f.id)])),
    moodToMouth: P.moods,
  };
  const instructions = {
    layerOrder: 'layers[] is ordered bottom -> top; draw in that order.',
    coordinateSpace: `Canvas ${P.canvas.w}x${P.canvas.h}. Geometry x/y places the family origin on the canvas. Part x/y are in family space (origin = family origin, +y down, negative y = up).`,
    transformOrder: 'translate(geometry.x, geometry.y) -> rotate(geometry.rotation deg) -> scale(scale * flip) -> translate(-anchorPoint) -> draw sprite at its spriteOffset.',
    geometryResolution: 'effective = base ("*") overridden by geometry[characterId] when present. All variants of a family share the same geometry.',
    moodRule: 'When a mood is active, the layer with category "mouth" is drawn with moods[mood] family/variant instead of the equipped one. Other layers do not change.',
    pixelFormat: 'parts[].rows are base-36 strings, one char per pixel: 0 = transparent, n = family slot number n (1-based, slots[n-1]). Slot color comes from variant.colors[slot.id], overridden by variant.overrides[partId].colors[slot.id].',
  };
  return {
    avatarSystem: {
      version: FORMAT_VERSION, name: P.name, generatedAt: new Date().toISOString(), canvas: P.canvas,
      characters, assetFamilies, variants, layers, moods: P.moods, backgrounds: P.backgrounds, scene: P.scene,
      geometry, palette, assets, relationships, instructions,
    },
  };
}
function counts(sys) {
  const a = sys.avatarSystem;
  return { Characters: a.characters.length, 'Asset Families': a.assetFamilies.length, Variants: a.variants.length, Layers: a.layers.length, Moods: Object.keys(a.moods).length, Backgrounds: a.backgrounds.length, Parts: a.assetFamilies.reduce((n, f) => n + f.parts.length, 0), Colors: a.palette.length };
}

function buildSpecMd(sys) {
  const a = sys.avatarSystem, c = counts(sys), L = [];
  L.push(`# Avatar System Spec — ${a.name}`, '', `Generated: ${a.generatedAt}`, '', '## Summary', '', ...Object.entries(c).map(([k, v]) => `- **${k}**: ${v}`), '');
  L.push('## Characters', '', ...a.characters.map(x => `- **${x.name}** (\`${x.id}\`) — ${x.exclusiveFamilyIds.length} exclusive families, ${x.sharedFamilyIds.length} shared`), '');
  L.push('## Layer Structure (bottom → top)', '', ...a.layers.map(l => `${l.order + 1}. \`${l.id}\` — ${l.name} (category \`${l.category}\`)${l.visible ? '' : ' [hidden]'}${l.locked ? ' [locked]' : ''}`), '');
  L.push('## Asset Families', '');
  for (const f of a.assetFamilies) {
    L.push(`### ${f.name} (\`${f.id}\`)`, '', `- Category: \`${f.category}\` · Anchor: \`${f.anchor}\` · ${f.shared ? 'shared by all characters' : 'characters: ' + f.characterIds.map(i => (a.characters.find(x => x.id === i) || {}).name).join(', ')}`, `- Base geometry: ${JSON.stringify(f.geometry['*'])}`);
    const ov = Object.entries(f.geometry).filter(([k]) => k !== '*'); if (ov.length) L.push(`- Character geometry overrides: ${ov.map(([k, g]) => `${(a.characters.find(x => x.id === k) || {}).name || k} ${JSON.stringify(g)}`).join('; ')}`);
    L.push(`- Slots: ${f.slots.map((s, i) => `${i + 1}=${s.name}`).join(', ')}`, `- Parts: ${f.parts.map(p => `${p.name} ${p.width}×${p.height} @(${p.x},${p.y})`).join(', ')}`, `- Variants: ${a.variants.filter(v => v.familyId === f.id).map(v => `${v.name} [${Object.values(v.colors).join(' ')}]`).join(' | ')}`, '');
  }
  L.push('## Mood Mapping', '', ...MOODS.map(([m]) => { const x = a.moods[m]; const fam = x && a.assetFamilies.find(f => f.id === x.familyId); const v = x && a.variants.find(y => y.id === x.variantId); return `- \`${m}\` → ${fam ? fam.name + (v ? ' / ' + v.name : '') : '(none)'}`; }), '');
  L.push('## Backgrounds', '', ...a.backgrounds.map(b => `- **${b.name}** — ${b.type}, ${b.color}${b.type === 'gradient' ? ' → ' + b.color2 : ''}, pattern ${(b.pattern || {}).kind || 'none'}, effects ${JSON.stringify(b.effects || {})}`), '');
  L.push('## Scene (shadow / ground / lighting / glow)', '', '```json', JSON.stringify({ shadow: a.scene.shadow, ground: a.scene.ground, lighting: a.scene.lighting, glow: a.scene.glow }, null, 2), '```', '');
  L.push('## Color Palette', '', a.palette.map(x => '`' + x + '`').join(' '), '', '## Rules', '', ...Object.entries(a.instructions).map(([k, v]) => `- **${k}**: ${v}`), '');
  return L.join('\n');
}
function buildClaudeMd(sys) {
  const a = sys.avatarSystem, c = counts(sys);
  return `# CLAUDE_AVATAR_IMPLEMENTATION

> Instructions for the engineer/agent that implements this avatar system inside the Routine Planner (Flutter) app. Source data: \`avatar-system.json\` (this bundle). Visual reference: \`sprites/\` and \`previews/\`.

## 1. What to build
A layered, pixel-art avatar renderer driven entirely by \`avatar-system.json\`:
- ${c.Characters} character(s), ${c['Asset Families']} asset families, ${c.Variants} variants, ${c.Layers} layers, ${c.Moods} moods, ${c.Backgrounds} backgrounds.
- The existing avatar/wardrobe/coins/ownership data in the app's state must keep working (map old item ids to new families where equivalent; never delete user data).

## 2. Where assets go
- Copy \`avatar-system.json\` to \`flutter_app/assets/avatar/avatar-system.json\` and declare it (and \`assets/avatar/sprites/\`) in \`pubspec.yaml\`.
- Either (a) render from \`parts[].rows\` + variant colors at runtime (preferred: recolor-able, tiny), or (b) use the pre-rendered \`sprites/<familyId>/<variantId>.png\` with \`spriteOffset\`.
- Use \`FilterQuality.none\` / nearest-neighbour everywhere; never anti-alias pixel art.

## 3. Components to implement
1. \`AvatarSystem\` model + loader (parse JSON once, cache).
2. \`AvatarComposer\` (CustomPainter or pre-composited \`ui.Image\`): input = characterId, equipped map (layerId → {familyId, variantId}), mood, background id, scene options; output = canvas ${a.canvas.w}×${a.canvas.h} scaled by an integer factor.
3. \`AvatarView\` widget with sizes: full, inventory, profile (circle crop of head), small icon, modal — see \`previews/\` for framing.
4. Wardrobe UI reads categories/families/variants from the JSON (no hard-coded lists).

## 4. Layer order (bottom → top)
${a.layers.map(l => `${l.order + 1}. ${l.id} (${l.category})`).join('\n')}

Draw strictly in this order. Hidden layers are skipped.

## 5. Geometry
- Effective geometry of a family = \`geometry[familyId].base\` overridden by \`characterOverrides[characterId]\` (per-field).
- Transform: translate(x,y) → rotate(rotation°) → scale(scale·flip) → translate(−anchor) → draw sprite at spriteOffset. Coordinates are canvas pixels (${a.canvas.w}×${a.canvas.h}); origin of characters = feet center.
- **All variants of a family share the same geometry** — never store position per variant.

## 6. Variants
Colors per variant: \`variants[].colors[slotId]\`; optional per-part \`overrides[partId] = {visible?, colors?}\`. Pixel slot n ↔ \`slots[n-1]\`.

## 7. Moods
\`moods[mood] = {familyId, variantId}\` → replaces the drawn asset of the layer with category \`mouth\` only. Moods: ${MOODS.map(m => m[0]).join(', ')}. Wire to app events (e.g. completed all habits → happy, missed → sad, late night → tired, streak milestone → excited) — keep mapping in one place.

## 8. Shared vs character-specific
- \`characterIds: []\` ⇒ shared by all characters. Otherwise only those characters may equip it (hide others in the wardrobe; ignore if equipped).
- Character-specific geometry overrides live in \`geometry[familyId].characterOverrides\`.

## 9. Background & scene
\`backgrounds[]\` (solid/gradient/image + pattern + vignette/scanlines/noise) and \`scene.shadow/ground/lighting/glow\`. Draw order: background → glow → ground → shadow → layers → lighting overlay. Day/night themes may pick different background ids.

## 10. Must not change
- User state schema/keys, backups/restore, coins/points/ownership logic, Free/Pro gating, habit data.
- Accessibility labels and RTL layout of existing screens.
- Add migration only; old saved avatars must still render (fall back to default character + default outfit).

## 11. Verification
- Golden-image tests: render each family×variant and compare with \`sprites/\`; render 3 full compositions and compare with \`previews/\`.
- Unit-test geometry resolution (base vs override), layer order, mood→mouth swap, variant recolor, backup round-trip.

## 12. Data summary
${Object.entries(c).map(([k, v]) => `- ${k}: ${v}`).join('\n')}
`;
}

// ---------------------------------------------------------------- ZIP (store) + CRC32
const CRC_T = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
function crc32(b) { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = CRC_T[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
function makeZip(files) {
  const enc = new TextEncoder(), chunks = [], cd = []; let off = 0;
  const u16 = n => [n & 255, (n >> 8) & 255], u32 = n => [n & 255, (n >> 8) & 255, (n >> 16) & 255, (n >>> 24) & 255];
  const d = new Date(), time = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1), date = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
  for (const f of files) {
    const name = enc.encode(f.name), data = typeof f.data === 'string' ? enc.encode(f.data) : f.data, crc = crc32(data);
    const lh = new Uint8Array([0x50, 0x4b, 3, 4, ...u16(20), ...u16(0x0800), ...u16(0), ...u16(time), ...u16(date), ...u32(crc), ...u32(data.length), ...u32(data.length), ...u16(name.length), ...u16(0)]);
    chunks.push(lh, name, data);
    cd.push(new Uint8Array([0x50, 0x4b, 1, 2, ...u16(20), ...u16(20), ...u16(0x0800), ...u16(0), ...u16(time), ...u16(date), ...u32(crc), ...u32(data.length), ...u32(data.length), ...u16(name.length), ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u32(0), ...u32(off)]), name);
    off += lh.length + name.length + data.length;
  }
  const cdSize = cd.reduce((n, c) => n + c.length, 0);
  const end = new Uint8Array([0x50, 0x4b, 5, 6, 0, 0, 0, 0, ...u16(files.length), ...u16(files.length), ...u32(cdSize), ...u32(off), 0, 0]);
  return new Blob([...chunks, ...cd, end], { type: 'application/zip' });
}
const canvasPng = c => new Promise(r => c.toBlob(async b => r(new Uint8Array(await b.arrayBuffer())), 'image/png'));
async function buildZipFiles() {
  const sys = buildSystem(), files = [];
  files.push({ name: 'avatar-system.json', data: JSON.stringify(sys, null, 2) }, { name: 'AVATAR_SPEC.md', data: buildSpecMd(sys) }, { name: 'CLAUDE_AVATAR_IMPLEMENTATION.md', data: buildClaudeMd(sys) }, { name: 'project.rpa', data: JSON.stringify(serialize(P)) });
  for (const f of P.families) for (const v of f.variants) { const s = familySprite(f, v); if (!s.empty) files.push({ name: `sprites/${f.id}/${v.id}.png`, data: await canvasPng(s.canvas) }); }
  for (const [k, label, w, hh] of PREVIEWS) { const c = mkCanvas(w, hh); renderPreview(k, c, true); files.push({ name: `previews/${k}.png`, data: await canvasPng(c) }); }
  return files;
}
function download(name, blobOrText, type) {
  const b = blobOrText instanceof Blob ? blobOrText : new Blob([blobOrText], { type: type || 'text/plain' });
  const a = h('a', { href: URL.createObjectURL(b), download: name }); document.body.append(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500);
}
const safeName = () => (P.name || 'avatar').replace(/[^\w\-]+/g, '_');

function openExportPreview() {
  const sys = buildSystem(), c = counts(sys);
  const bg = h('div', { class: 'modal-bg', onclick: e => e.target === bg && bg.remove() }, h('div', { class: 'modal' },
    h('h3', {}, h('span', { class: 'grow' }, 'Export Preview'), btn('✕', () => bg.remove())),
    h('div', { class: 'mb' },
      ...Object.entries(c).map(([k, v]) => h('div', { class: 'stat' }, h('b', {}, k), v)),
      h('hr'),
      h('div', { class: 'muted' }, 'بستهٔ ZIP شامل: avatar-system.json · AVATAR_SPEC.md · CLAUDE_AVATAR_IMPLEMENTATION.md · project.rpa · sprites/ · previews/'),
      h('div', { class: 'row wrap', style: { marginTop: '10px' } },
        btn('⬇ بسته‌ی کامل (ZIP) — این را برای Claude بفرستید', async () => { setStatus('در حال ساخت ZIP…'); const z = makeZip(await buildZipFiles()); download(safeName() + '-avatar-export.zip', z); setStatus('ZIP ساخته شد ✓'); }, 'primary'),
        btn('avatar-system.json', () => download('avatar-system.json', JSON.stringify(sys, null, 2), 'application/json')),
        btn('AVATAR_SPEC.md', () => download('AVATAR_SPEC.md', buildSpecMd(sys))),
        btn('CLAUDE_AVATAR_IMPLEMENTATION.md', () => download('CLAUDE_AVATAR_IMPLEMENTATION.md', buildClaudeMd(sys))),
        btn('پروژه (.rpa)', () => download(safeName() + '.rpa', JSON.stringify(serialize(P)), 'application/json')))),
  ));
  document.body.append(bg);
}
