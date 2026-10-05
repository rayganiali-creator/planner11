#!/usr/bin/env python3
"""آواتار واقعیِ اپ (flutter_app/assets/avatar + avatar_data.json) را به پروژه‌ی Avatar Studio تبدیل می‌کند → src/10-appseed.js
هندسه از همان منطقِ avCompose در avatar_compose.dart گرفته شده (بومِ ۱۸۰×۱۸۶، آفستِ افقی ۲۵)."""
import json, base64, hashlib, io, os, time
from PIL import Image
here = os.path.dirname(os.path.abspath(__file__))
app = os.path.join(here, '../../flutter_app/assets')
d = json.load(open(f'{app}/avatar_data.json'))
OFFX, W, H = 25, 180, 186
images = {}
def img_id(path, size=None):
    im = Image.open(f'{app}/avatar/{path}').convert('RGBA')
    if size and im.size != tuple(size): im = im.resize(tuple(size), Image.NEAREST)
    buf = io.BytesIO(); im.save(buf, 'PNG', optimize=True); raw = buf.getvalue()
    k = 'img_' + hashlib.sha1(raw).hexdigest()[:12]
    images[k] = 'data:image/png;base64,' + base64.b64encode(raw).decode()
    return k, im.size
LAYERS = [('pet', 'حیوان'), ('petgear', 'تجهیزات حیوان'), ('capeback', 'شنل (پشت)'), ('body', 'بدن'), ('shoes', 'کفش'), ('pants', 'شلوار'), ('clothes', 'لباس'),
          ('armor', 'زره'), ('cape', 'شنل'), ('sleep', 'خواب'), ('hair', 'مو'), ('hijab', 'روسری'), ('condition', 'وضعیت (مریض/زخمی)'),
          ('hat', 'کلاه'), ('helmet', 'کلاه‌خود'), ('sword', 'شمشیر'), ('shield', 'سپر'), ('hands', 'دست‌ها'), ('mouth', 'دهان (Mood)'), ('effect', 'افکت')]
chars = {'male': {'id': 'char_male', 'name': 'Character 01 — مرد', 'notes': ''}, 'female': {'id': 'char_female', 'name': 'Character 02 — زن', 'notes': ''}}
fams = []
def geom(x, y, flip=False): return {'x': x, 'y': y, 'scale': 1, 'rotation': 0, 'opacity': 1, 'flipX': bool(flip), 'flipY': False}
def family(fid, name, cat, gender, imgpath, size, g, anchor, meta, variants=None):
    """variants: [(name, imgpath)] ؛ اولین، تصویرِ اصلیِ قطعه است و بقیه Override می‌شوند."""
    iid, sz = img_id(imgpath, size)
    pid = fid + ':main'
    part = {'id': pid, 'name': 'image', 'w': sz[0], 'h': sz[1], 'dx': 0, 'dy': 0, 'scale': 1, 'rotation': 0, 'flipX': False, 'flipY': False, 'visible': True, 'img': iid, 'rows': []}
    vs = []
    for i, (vn, vp) in enumerate(variants or [('Default', imgpath)]):
        v = {'id': f'{fid}#v{i}', 'name': vn, 'colors': {}, 'overrides': {}}
        if i: v['overrides'][pid] = {'img': img_id(vp, size)[0]}
        vs.append(v)
    fams.append({'id': fid, 'name': name, 'category': cat, 'characterIds': [chars[gender]['id']] if gender else [], 'anchor': anchor, 'tags': [], 'slots': [{'id': 's1', 'name': 'اصلی', 'color': '#cccccc'}],
                 'parts': [part], 'variants': vs, 'geometry': {'*': g}, 'meta': meta})
    return fams[-1]
def top(r, flip=False): return geom(OFFX + r[0] + r[2] / 2, r[1], flip)

# ---- بدن‌ها (۵ پوست برای هر جنسیت = Variant)
for gdr in ('male', 'female'):
    bs = [b for b in d['bases'] if b['g'] == gdr]
    r = bs[0]['rect']
    family(f'base_{gdr}', f'Body — {gdr}', 'body', gdr, bs[0]['f'], (r[2], r[3]), top(r), 'top-center', {'appItemIds': [b['id'] for b in bs], 'gender': gdr},
           [(f'Skin {i+1}', b['f']) for i, b in enumerate(bs)])
    # دست (فقط L)، خواب
    h0 = d['hands'][bs[0]['id']]['L']
    family(f'hands_{gdr}', f'Hand L — {gdr}', 'hands', gdr, h0['f'], (h0['rect'][2], h0['rect'][3]), top(h0['rect']), 'top-center', {'appKind': 'hands', 'appBaseIds': [b['id'] for b in bs]},
           [(f'Skin {i+1}', d['hands'][b['id']]['L']['f']) for i, b in enumerate(bs)])
    s0 = d['sleep'][bs[0]['id']]
    family(f'sleep_{gdr}', f'Sleep Z — {gdr}', 'sleep', gdr, s0['f'], (s0['rect'][2], s0['rect'][3]), top(s0['rect']), 'top-center', {'appKind': 'sleep', 'appBaseIds': [b['id'] for b in bs]},
           [(f'Skin {i+1}', d['sleep'][b['id']]['f']) for i, b in enumerate(bs)])
    for cond in ('hurt', 'sick'):
        c = d['cond'][cond][gdr]
        family(f'cond_{cond}_{gdr}', f'{cond.title()} — {gdr}', 'condition', gdr, c['f'], (c['rect'][2], c['rect'][3]), top(c['rect']), 'top-center', {'appKind': 'cond', 'cond': cond})

# ---- آیتم‌ها
pets = {}
for it in d['items']:
    cat, kind = it['c'], it['k']
    meta = {'appItemId': it['id'], 'appKind': kind, 'price': it.get('price'), 'name': it.get('n')}
    if kind == 'pet':
        w, h = it['size']
        fam = family(it['id'], it.get('n', it['id']), 'pet', None, it['f'], (w, h), geom(round(142 - w / 2), 182 - h), 'origin', meta,
                     [('Awake', it['f'])] + ([('Sleep', it['fs'])] if it.get('fs') else []))
        pets[it['id']] = fam
        continue
    if kind == 'petgear':
        cat0 = d['petAnchor']['pets/01_cat']
        po = (it.get('po') or {}).get('pets/01_cat', {})
        off = po.get('off', it.get('off', [0, 0])); w, h = po.get('size', it['size'])
        onw = it.get('on', 'head'); p = cat0[onw]; px, py = round(142 - 24 + 0) + 0, 0
        cx, cy = (118 + p[0]), (134 + p[1])
        gx = round(cx - w / 2 + off[0]); gy = round(cy - h + off[1]) if onw == 'head' else round(cy + off[1])
        meta['petgearOn'] = onw; meta['note'] = 'جای نمایش برای گربه محاسبه شده؛ در اپ نسبت به هر حیوان (petAnchor) تنظیم می‌شود'
        family(it['id'], it.get('n', it['id']), 'petgear', None, it['f'], (w, h), geom(gx, gy, it.get('flip')), 'origin', meta)
        continue
    for gdr in ('male', 'female'):
        if gdr not in it['files'] or gdr not in it['fit']: continue
        r = it['fit'][gdr]
        family(f"{it['id']}#{gdr}", f"{it.get('n', it['id'])} ({'♂' if gdr == 'male' else '♀'})", cat if cat != 'pants' else 'pants', gdr, it['files'][gdr], (r[2], r[3]), top(r, it.get('flip')), 'top-center', {**meta, 'gender': gdr})
        if it.get('backFiles') and gdr in it['backFiles']:
            br = it['backFit'][gdr]
            family(f"{it['id']}#{gdr}#back", f"{it.get('n', it['id'])} — پشت ({'♂' if gdr == 'male' else '♀'})", 'capeback', gdr, it['backFiles'][gdr], (br[2], br[3]), top(br), 'top-center', {**meta, 'gender': gdr, 'appKind': 'cape_back'})

def bg(name, t, c1, c2, pat='none', pc='#ffffff', ps=8, po=0.1, vig=0, scan=0, noise=0):
    return {'id': 'bg_' + name.lower().replace(' ', '_'), 'name': name, 'type': t, 'color': c1, 'color2': c2, 'angle': 0, 'pattern': {'kind': pat, 'color': pc, 'size': ps, 'opacity': po}, 'image': None, 'x': 0, 'y': 0, 'scale': 1, 'opacity': 1, 'effects': {'vignette': vig, 'scanlines': scan, 'noise': noise}}
bgs = [bg('Day', 'gradient', '#bfe3ff', '#eaf6ff'), bg('Night', 'gradient', '#101a3a', '#2a2f5e', 'dots', '#ffffff', 10, 0.08, 0.3), bg('Soft Gray', 'gradient', '#e8eaf0', '#b8bdca', vig=0.1),
       bg('Sunset', 'gradient', '#ffb36b', '#7a3a8a', vig=0.2, noise=0.2), bg('Forest', 'gradient', '#a7d8a0', '#2f6a46', 'stripes', '#ffffff', 12, 0.05, 0.25),
       bg('Checker', 'solid', '#cfd6e4', '#000000', 'checker', '#aab4c8', 8, 0.6), bg('Retro Grid', 'gradient', '#14102a', '#4a1e78', 'grid', '#ff5fd0', 12, 0.18, 0.3, 0.25)]
byid = {f['id']: f for f in fams}
eq = {}
def put(cat, fid):
    eq['L_' + cat] = {'familyId': fid, 'variantId': byid[fid]['variants'][0]['id']}
put('body', 'base_male'); put('pants', 'pants/pants_01#male'); put('clothes', 'clothes/top_01#male'); put('hair', 'hair/hair_01#male'); put('shoes', 'shoes/shoes_01#male'); put('sword', 'sword/weapon_01#male'); put('hands', 'hands_male'); put('pet', 'pets/01_cat')
proj = {
    'format': 'rp-avatar-project', 'version': 1, 'id': 'proj_app_avatar', 'name': 'آواتار فعلی اپ (Routine Planner)', 'createdAt': 0, 'updatedAt': 0,
    'canvas': {'w': W, 'h': H, 'safe': {'x': OFFX, 'y': 0, 'w': 130, 'h': H}},
    'characters': list(chars.values()), 'families': fams,
    'layers': [{'id': 'L_' + c, 'name': n, 'category': c, 'visible': True, 'locked': False} for c, n in LAYERS],
    'moods': {}, 'backgrounds': bgs,
    'scene': {'characterId': 'char_male', 'mood': 'neutral', 'equipped': eq, 'backgroundId': bgs[0]['id'], 'bgVisible': True,
              'shadow': {'on': True, 'color': '#000000', 'opacity': 0.26, 'w': 60, 'h': 10, 'x': OFFX + 65, 'y': 182}, 'ground': {'on': False, 'color': '#3a4a3a', 'opacity': 1, 'height': 16},
              'lighting': {'on': False, 'color': '#ffe9b0', 'angle': 45, 'opacity': 0.18}, 'glow': {'on': False, 'color': '#9fb0ff', 'radius': 60, 'opacity': 0.25, 'x': 90, 'y': 100}},
    'view': {'zoom': 3, 'panX': 0, 'panY': 0, 'grid': 10, 'snap': True, 'showGrid': False, 'showRuler': True, 'showSafe': True, 'showCenter': True, 'showLayerBoxes': False, 'guides': []},
    'images': images,
}
open(f'{here}/src/10-appseed.js', 'w', encoding='utf8').write("'use strict';\n// تولیدشده توسط import_app.py — آواتار واقعیِ اپ\nconst APP_SEED = " + json.dumps(proj, ensure_ascii=False, separators=(',', ':')) + ';\n')
print(len(fams), 'families,', len(images), 'images,', os.path.getsize(f'{here}/src/10-appseed.js') // 1024, 'KB')
