# برش شیتِ ۴۸ نشانِ تأییدشده (user-sheet/source.webp) به PNG شفاف: ۶ ردیف × ۸ ستون → flutter_app/assets/badges/badge_NN.png
import numpy as np, os
from PIL import Image, ImageDraw, ImageFilter
here = os.path.dirname(os.path.abspath(__file__))
dest = os.path.abspath(os.path.join(here, '../../../flutter_app/assets/badges'))
os.makedirs(dest, exist_ok=True)
im = Image.open(f'{here}/source.webp').convert('RGB')
W, H = im.size
A = np.asarray(im).astype(float)
bg = np.median(np.concatenate([A[:4].reshape(-1, 3), A[-4:].reshape(-1, 3), A[:, :4].reshape(-1, 3), A[:, -4:].reshape(-1, 3)]), axis=0)
D = np.sqrt(((A - bg) ** 2).sum(axis=2))
M = Image.fromarray(((D > 30) * 255).astype(np.uint8), 'L')
fl = M.copy()
ImageDraw.floodfill(fl, (0, 0), 128)
SUBJ = Image.fromarray(((np.asarray(fl) != 128) * 255).astype(np.uint8), 'L').filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(5))
S = np.asarray(SUBJ) > 0

def runs(v, minlen=30):
    out, st = [], None
    for i, x in enumerate(list(v) + [0]):
        if x and st is None: st = i
        if not x and st is not None:
            if i - st >= minlen: out.append((st, i))
            st = None
    return out

rows = runs(S.sum(axis=1) > 3)
assert len(rows) == 6, rows
OUT = 320
for r, (ya, yb) in enumerate(rows):
    cols = runs(S[ya:yb].sum(axis=0) > 3)
    assert len(cols) == 8, (r, cols)
    for c, (xa, xb) in enumerate(cols):
        n = r * 8 + c + 1
        sub = S[ya:yb, xa:xb]
        ys, xs = np.nonzero(sub)
        x0, x1, y0, y1 = xa + xs.min(), xa + xs.max() + 1, ya + ys.min(), ya + ys.max() + 1
        side = max(x1 - x0, y1 - y0); cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        pad = side * 0.08
        box = tuple(int(round(v)) for v in (cx - side / 2 - pad, cy - side / 2 - pad, cx + side / 2 + pad, cy + side / 2 + pad))
        # آلفا فقط از همین نشان (نشان‌های همسایه کنار نمی‌آیند)
        al = Image.new('L', (W, H), 0)
        al.paste(SUBJ.crop((xa, ya, xb, yb)), (xa, ya))
        al = al.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.9))
        rgba = im.convert('RGBA'); rgba.putalpha(al)
        out = rgba.crop(box).resize((OUT, OUT), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
        out.save(f'{dest}/badge_{n:02d}.png', optimize=True)
print('done')
