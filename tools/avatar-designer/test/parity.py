"""ترکیبِ مستقلِ آواتار با قواعدِ avCompose (از avatar_data.json) و مقایسه‌ی پیکسل‌به‌پیکسل با خروجی Studio"""
import json, sys, os, tempfile
from PIL import Image, ImageChops
g = sys.argv[1]
here = os.path.dirname(os.path.abspath(__file__))
app = f'{here}/../../../flutter_app/assets'
d = json.load(open(f'{app}/avatar_data.json'))
combo = json.load(open(f'{tempfile.gettempdir()}/ad-{g}.json'))
studio = Image.open(f'{tempfile.gettempdir()}/ad-{g}.png').convert('RGBA')
OFFX = 25
KIND = {'base': 0, 'shoes': 10, 'pants': 20, 'top': 30, 'outfit': 35, 'armor': 50, 'cape': 55, 'hair': 60, 'hijab': 60, 'hat': 70, 'helmet': 70, 'sword': 80, 'shield': 90}
items = {i['id']: i for i in d['items']}
bases = {b['id']: b for b in d['bases']}
layers = []  # (layer, order, file, rect, flip)
extra = []
n = 0
for fid, vi in combo:
    n += 1
    if fid.startswith('base_'):
        bs = [b for b in d['bases'] if b['g'] == g]; b = bs[vi]; layers.append((0, n, b['f'], b['rect'], False)); base_id = b['id']
    elif fid.startswith('hands_'):
        pass
    elif fid.endswith('#back'):
        it = items[fid.split('#')[0]]; layers.append((-5, n, it['backFiles'][g], it['backFit'][g], False))
    else:
        it = items[fid.split('#')[0]]
        layers.append((KIND[it['k']], n, it['files'][g], it['fit'][g], bool(it.get('flip'))))
layers.sort(key=lambda l: (l[0], l[1]))
out = Image.new('RGBA', (180, 186), (0, 0, 0, 0))
def paste(f, rect, flip=False):
    im = Image.open(f'{app}/avatar/{f}').convert('RGBA')
    if im.size != (rect[2], rect[3]): im = im.resize((rect[2], rect[3]), Image.NEAREST)
    if flip: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    layer = Image.new('RGBA', out.size, (0, 0, 0, 0)); layer.paste(im, (OFFX + rect[0], rect[1])); out.alpha_composite(layer)
for l in layers: paste(l[2], l[3], l[4])
hv = [vi for fid, vi in combo if fid.startswith('hands_')]
if hv and any(KIND.get(items[f.split('#')[0]]['k']) == 80 for f, _ in combo if not f.startswith(('base_', 'hands_'))):
    bid = [b for b in d['bases'] if b['g'] == g][hv[0]]['id']; h = d['hands'][bid]['L']; paste(h['f'], h['rect'])
diff = ImageChops.difference(out, studio)
bbox = diff.getbbox()
import warnings; warnings.simplefilter('ignore')
bad = sum(1 for p in diff.getdata() if max(p) > 2)
print('PARITY OK' if bad == 0 else f'PARITY FAIL {bad} px differ bbox={bbox}')
sys.exit(0 if bad == 0 else 1)
