# -*- coding: utf-8 -*-
"""دارایی‌های Flutter را از خودِ www/index.html استخراج می‌کند (تکرارپذیر، بدون وابستگی به جای دیگر):
   • فونت وزیرمتن (woff2 → ttf؛ Flutter از woff2 پشتیبانی نمی‌کند). دو زیرمجموعه‌ی عربی و لاتین،
     هر دو variable با محور wght ۱۰۰..۹۰۰ — دقیقاً همان‌هایی که نسخه‌ی HTML نشان می‌دهد.
   • تصاویر آواتار (۲۹۹ PNG) از window.__AV_DATA
   • avatar_data.json (همان AV_DATA: آیتم‌ها، بدن‌ها، دست‌ها، لنگر حیوان، …)
   اجرا:  python3 tool/extract_assets.py   (به fonttools و brotli نیاز دارد)
"""
import re, io, os, json, base64, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
OUT = os.path.join(HERE, '..', 'assets')
s = io.open(os.path.join(ROOT, 'www', 'index.html'), encoding='utf-8').read()

# ---- فونت ----
from fontTools.ttLib import TTFont
os.makedirs(os.path.join(OUT, 'fonts'), exist_ok=True)
blocks = re.findall(r"@font-face\s*\{(.*?)\}", s, flags=re.S)
seen = {}
for b in blocks:
    m = re.search(r"url\(data:font/woff2;base64,([A-Za-z0-9+/=]+)\)", b)
    if not m: continue
    raw = base64.b64decode(m.group(1))
    f = TTFont(io.BytesIO(raw))
    cmap = f.getBestCmap()
    kind = 'arabic' if sum(1 for c in cmap if 0x600 <= c <= 0x6FF) > 50 else 'latin'
    if kind in seen: continue          # سه وزن‌بازه یک فایلِ یکسان‌اند؛ یک نسخه کافی است
    f.flavor = None
    path = os.path.join(OUT, 'fonts', f'Vazirmatn-{kind}.ttf')
    f.save(path); seen[kind] = os.path.getsize(path)
print('fonts:', seen)

# ---- تصاویر آواتار ----
i = s.index('window.__AV_DATA=') + len('window.__AV_DATA=')
j = s.index(';</script>', i)
imgs = json.loads(s[i:j])
n = 0
for rel, data in imgs.items():
    head, b64 = data.split(',', 1)
    p = os.path.join(OUT, rel)             # rel مثل avatar/base/male.png
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'wb').write(base64.b64decode(b64)); n += 1
print('avatar images:', n)

# ---- avatar_data.json ----
PRE = 'const AV_DATA = '
a = s.index(PRE) + len(PRE); b = s.index('\n', a)
data = json.loads(s[a:b].rstrip().rstrip(';'))
json.dump(data, open(os.path.join(OUT, 'avatar_data.json'), 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print('avatar_data.json: items =', len(data['items']), 'keys =', list(data.keys()))
