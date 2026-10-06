# برش شیتِ ۴۸ نشانِ تأییدشده (user-sheet/source.webp) به PNG شفاف: ۶ ردیف × ۸ ستون → flutter_app/assets/badges/badge_NN.png
import numpy as np, os
from PIL import Image, ImageDraw, ImageFilter
here = os.path.dirname(os.path.abspath(__file__))
import sys
dest = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(here, '../../../flutter_app/assets/badges'))
os.makedirs(dest, exist_ok=True)
im = Image.open(f'{here}/source.webp').convert('RGB')
W, H = im.size
A = np.asarray(im).astype(float)
bg = np.median(np.concatenate([A[:4].reshape(-1, 3), A[-4:].reshape(-1, 3), A[:, :4].reshape(-1, 3), A[:, -4:].reshape(-1, 3)]), axis=0)
D = np.sqrt(((A - bg) ** 2).sum(axis=2))
M = Image.fromarray(((D > int(os.environ.get('THR', 30))) * 255).astype(np.uint8), 'L')
fl = M.copy()
ImageDraw.floodfill(fl, (0, 0), 128)
SUBJ = Image.fromarray(((np.asarray(fl) != 128) * 255).astype(np.uint8), 'L').filter(ImageFilter.MinFilter(int(os.environ.get('OPEN', 5)))).filter(ImageFilter.MaxFilter(int(os.environ.get('OPEN', 5)))).filter(ImageFilter.MinFilter(int(os.environ.get('ERODE', 5))))
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
        # برازشِ شکلِ هندسی (دایره/شش‌ضلعی/لوزی) با لبه‌ی چپ/راست/بالا؛ پایین را از تقارن می‌گیریم تا سایه‌ی زیرِ نشان حذف شود
        w = x1 - x0
        def poly_mask(kind, h):
            im_ = Image.new('L', (W, H), 0); dr = ImageDraw.Draw(im_)
            cx_, cy_ = (x0 + x1) / 2, y0 + h / 2
            if kind == 'circle': dr.ellipse((x0, y0, x1, y0 + h), fill=255)
            elif kind == 'diamond': dr.polygon([(cx_, y0), (x1, cy_), (cx_, y0 + h), (x0, cy_)], fill=255)
            else:
                dr.polygon([(cx_, y0), (x1, y0 + h * .25), (x1, y0 + h * .75), (cx_, y0 + h), (x0, y0 + h * .75), (x0, y0 + h * .25)], fill=255)
            return np.asarray(im_) > 0
        cand = {'circle': w, 'diamond': w, 'hex': w * 2 / 3 ** .5}
        best = None
        for kind, h in cand.items():
            tm = poly_mask(kind, h)
            top = np.zeros_like(tm); top[int(y0):int(y0 + h * .8), int(x0):int(x1)] = True
            inter = (tm & S & top).sum(); uni = ((tm | S) & top).sum()
            iou = inter / max(uni, 1)
            if best is None or iou > best[0]: best = (iou, kind, h, tm)
        print(n, best[1], round(best[0], 3))
        Sd = Image.fromarray((S * 255).astype(np.uint8), 'L').filter(ImageFilter.MaxFilter(7))
        if best[0] > 0.94:
            tmpl = Image.fromarray((best[3] * 255).astype(np.uint8), 'L').filter(ImageFilter.MinFilter(3))
            SUBJ_N = Image.fromarray(np.minimum(np.asarray(tmpl), np.asarray(Sd)), 'L')
        else:
            clip = np.zeros((H, W), np.uint8); clip[int(y0):int(y0 + best[2]) + 1, int(x0):int(x1)] = 255
            SUBJ_N = Image.fromarray(np.minimum(np.asarray(SUBJ.filter(ImageFilter.MinFilter(3))), clip), 'L')
        y1 = int(y0 + best[2])
        side = max(x1 - x0, y1 - y0); cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        pad = side * 0.08
        box = tuple(int(round(v)) for v in (cx - side / 2 - pad, cy - side / 2 - pad, cx + side / 2 + pad, cy + side / 2 + pad))
        # آلفا فقط از همین نشان (نشان‌های همسایه کنار نمی‌آیند)
        al = Image.new('L', (W, H), 0)
        if SUBJ_N is not None: al = SUBJ_N
        else: al.paste(SUBJ.crop((xa, ya, xb, yb)), (xa, ya))
        al = al.filter(ImageFilter.GaussianBlur(1.1))
        # حذفِ رنگِ زمینه از لبه‌ها (defringe): c = (c - bg(1-a)) / a
        a_ = np.asarray(al).astype(float)[..., None] / 255
        rgb = np.asarray(im).astype(float)
        dec = np.where(a_ > 0.02, (rgb - bg * (1 - a_)) / np.maximum(a_, 0.02), rgb)
        dec = np.clip(dec, 0, 255).astype(np.uint8)
        rgba = Image.fromarray(dec, 'RGB').convert('RGBA'); rgba.putalpha(al)
        out = rgba.crop(box).resize((OUT, OUT), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
        out.save(f'{dest}/badge_{n:02d}.png', optimize=True)
print('done')
