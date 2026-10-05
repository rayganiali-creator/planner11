# طرحِ «زنجیره‌ای»: هر ردیف یک تصویرِ واحد است که نشان‌به‌نشان کامل می‌شود؛ نشانِ ۸ام همان تصویرِ نهاییِ باشکوه.
import math
from make_sheet import G, P, ngon, f, book_open, book_closed

def tile(g, x, y, s, filled, glow=False, op=1):
    cls = 'gl' if glow else ('sf' if filled else 'nf')
    g.add(f'<rect x="{f(x)}" y="{f(y)}" width="{f(s)}" height="{f(s)}" rx="3" class="{cls}" stroke-width="2.4" opacity="{op}"/>')

def row_stairs(g, k):  # استمرار: پله‌ها بالا می‌روند تا خورشید
    base = 34; n = min(k, 5)
    g.line((-40, base), (40, base), .7, .9) if k > 5 else g.line((-40, base), (-38 + 15.5 * n + 2, base), .7, .9)
    for j in range(n):
        x0 = -38 + j * 15.5; top = base - 10 * (j + 1)
        if j == n - 1 and k < 8: g.add(f'<rect x="{f(x0)}" y="{f(top)}" width="15.5" height="{f(base - top)}" rx="1.5" class="gl" stroke-width="2.7"/>')
        else: g.rect(x0, top, 15.5, base - top, 1.5, .85, 1, True)
    if k >= 6:
        for j in range(5):
            g.disc(2, (-30 + j * 15.5, base - 10 * (j + 1) - 6), .95)
        g.line((-30, base - 16), (32, base - 56), .35, .6)
    if k >= 7: g.disc(8, (26, -27), 1, True); g.ring(11.5, .45, .8, (26, -27))
    if k >= 8:
        for a in range(0, 360, 30):
            x0, y0 = P(15.5, a); x1, y1 = P(21 if a % 60 == 0 else 18.5, a)
            g.line((26 + x0, -27 + y0), (26 + x1, -27 + y1), .45, .9)
        g.spark(5, .15, .6, True, (-34, -28)); g.spark(4, .15, .6, True, (-18, -38)); g.disc(1.6, (-40, -14))

def row_focus(g, k):  # تمرکز: از یک نقطه تا ماندالای کامل
    g.disc(6, glow=True); g.ring(16, .9)
    if k >= 2: g.ring(26, .8, .85)
    if k >= 3:
        for a in (0, 90, 180, 270): g.line(P(31, a), P(43, a), .7)
    if k >= 4: g.dots(8, 36.5, 2, 45)
    if k >= 5: g.poly(ngon(4, 23, 45), .55, .8)
    if k >= 6: g.star(8, 34, 25, 22.5, .45, False, .8)
    if k >= 7:
        g.ring(45, .4, .7)
        for a in range(0, 360, 15): g.line(P(41, a), P(44, a), .3, .7)
    if k >= 8:
        for a in range(0, 360, 45):
            x0, y0 = P(11, a + 22.5); cx, cy = P(30, a + 22.5 - 14); x1, y1 = P(40, a + 22.5)
            g.path(f'M{f(x0)},{f(y0)}Q{f(cx)},{f(cy)} {f(x1)},{f(y1)}Q{f(cx+ (P(30,a+22.5+14)[0]-cx))},{f(cy+(P(30,a+22.5+14)[1]-cy))} {f(x0)},{f(y0)}Z', .5, .9, False)

CELLS = [(2, 1), (2, 2), (3, 1), (3, 2), (1, 2), (1, 3), (2, 0), (2, 3), (3, 0), (3, 3), (1, 1), (1, 0), (0, 3), (0, 2), (0, 1), (0, 0)]
CHECK = {(2, 0), (3, 1), (2, 2), (1, 3), (0, 3)}
def row_tiles(g, k):  # بهره‌وری: موزائیکِ کارها که تیکِ بزرگ می‌شود
    cnt = [1, 2, 4, 6, 9, 12, 16, 16][k - 1]
    for (r, c) in CELLS[:cnt]:
        x, y = -38 + c * 20, -38 + r * 20
        if k == 8: tile(g, x, y, 16, (r, c) in CHECK, (r, c) in CHECK, 1 if (r, c) in CHECK else .5)
        else: tile(g, x, y, 16, True, (r, c) == CELLS[cnt - 1])
    if k == 8:
        g.poly([(-27, 2), (-10, 22), (28, -20)], 1.35, 1, False)

def row_book(g, k):  # مطالعه: صفحه ← کتاب ← کتابِ نورانی
    if k == 1: g.rect(-14, -22, 28, 40, 3, 1, 1, True); g.line((-7, -10), (7, -10), .5, .8); g.line((-7, -3), (7, -3), .5, .8)
    if k == 2:
        g.rect(-10, -20, 28, 40, 3, .9, .7, True); g.rect(-18, -24, 28, 40, 3, 1, 1, True)
    if k == 3: book_closed(g, (0, 2))
    if k >= 4:
        book_open(g, 1.0, (0, 8))
        for y in (-4, 4, 12): g.line((-24, y - 2), (-6, y + 2), .35, .75); g.line((24, y - 2), (6, y + 2), .35, .75)
    if k >= 5: g.add('<path d="M-6,-14l12,0l0,18l-6,-5l-6,5z" class="fl" stroke="none" opacity=".95" transform="translate(14 -2) scale(.8)"/>') if False else g.arc(40, 200, 340, .45, .6)
    if k >= 6:
        for a in range(-60, 61, 20): g.line(P(24, a), P(36 if a % 40 == 0 else 32, a), .5, .9)
    if k >= 7:
        g.spark(5, .15, .6, True, (-30, -26)); g.spark(4, .15, .6, True, (30, -28)); g.disc(1.8, (-36, -8)); g.disc(1.8, (36, -10))
    if k >= 8:
        g.disc(7, (0, -24), 1, True); g.arc(44, 232, 308, .6); g.arc(44, 52, 128, .6)
        g.ring(10.5, .4, .8, (0, -24))

PATH = [(-4, 30), (14, 19), (-10, 8), (8, -4), (0, -19)]
def row_path(g, k):  # انضباط/چالش: مسیر ← کوه ← پرچم و خورشید
    seg = {1: 2, 2: 3, 3: 4}.get(k, 5)
    if k >= 4:
        g.poly([(-42, 32), (0, -19), (42, 32)], .8, .6, False)
        g.poly([(14, 32), (30, 0), (46, 32)], .6, .4, False) if False else g.poly([(18, 32), (30, 8), (42, 32)], .6, .45, False)
    if k >= 5: g.poly([(-9, -9), (-4, -3), (0, -9), (4, -3), (9, -9)], .45, .7, False)
    g.poly(PATH[:seg], 1.05, 1, False)
    for p in PATH[:seg]: g.disc(2.8, p)
    if k >= 6: g.disc(8, (-30, -26), 1, True); g.ring(11.5, .4, .8, (-30, -26))
    if k >= 7:
        g.line((0, -19), (0, -39), .8); g.poly([(0, -39), (17, -33), (0, -27)], .6, 1, True, True)
    if k >= 8:
        g.line((-44, 32), (44, 32), .7, .9)
        for a in range(0, 360, 45):
            x0, y0 = P(15.5, a); x1, y1 = P(20.5, a)
            g.line((-30 + x0, -26 + y0), (-30 + x1, -26 + y1), .4, .9)
        g.spark(5, .15, .6, True, (30, -30)); g.disc(1.8, (38, -12)); g.disc(1.8, (-40, 10))
        g.arc(45, 215, 325, .5, .7); g.arc(45, 35, 145, .5, .7)

def row_master(g, k):  # تسلط: جواهرِ لایه‌لایه ← تاجِ ماندالایی
    g.poly([(0, -26), (26, 0), (0, 26), (-26, 0)], 1, 1, True, k < 8); g.disc(4.5, glow=True)
    if k >= 2: g.ring(34, .9)
    if k >= 3: g.poly(ngon(6, 41, 0), .85, .9)
    if k >= 4:
        for a in range(0, 360, 45):
            x0, y0 = P(8, a); x1, y1 = P(24, a); cx, cy = P(17, a + 13)
            g.path(f'M{f(x0)},{f(y0)}Q{f(cx)},{f(cy)} {f(x1)},{f(y1)}', .5, .8)
    if k >= 5: g.star(8, 18, 9, 22.5, .55, False, .95)
    if k >= 6:
        for a in range(0, 360, 10): g.line(P(43, a), P(46.5, a), .3, .75)
    if k >= 7: g.dots(16, 37.5, 1.6, 0, .95)
    if k >= 8:
        g.star(12, 47, 41, 0, .4, False, .8); g.ring(15, .55, .8); g.spark(10, .16, .6, True)
        g.arc(28, 240, 300, .6); g.arc(28, 60, 120, .6)

ROWFN = [row_stairs, row_focus, row_tiles, row_book, row_path, row_master]

def fit(r, k):
    """(scale, cx, cy): بزرگ‌نماییِ مراحلِ اولِ کم‌جزئیات تا نشان پر و جذاب باشد"""
    if r == 0 and k <= 5: return ([2.1, 1.8, 1.5, 1.3, 1.12][k - 1], -38 + 7.75 * k, 34 - 5 * k)
    if r == 1: return ([2.3, 1.7, 1.05][k - 1], 0, 0) if k <= 3 else (1, 0, 0)
    if r == 2:
        cnt = [1, 2, 4, 6, 9, 12, 16, 16][k - 1]
        xs = [-38 + c * 20 for _, c in CELLS[:cnt]]; ys = [-38 + rr * 20 for rr, _ in CELLS[:cnt]]
        w = max(xs) + 16 - min(xs); h = max(ys) + 16 - min(ys)
        return (min(2.4, 78 / max(w, h)), (max(xs) + 16 + min(xs)) / 2, (max(ys) + 16 + min(ys)) / 2)
    if r == 3: return {1: (1.7, 0, -2), 2: (1.5, 0, -2), 3: (1.15, 0, 2)}.get(k, (1, 0, 0))
    if r == 4 and k <= 3:
        seg = {1: 2, 2: 3, 3: 4}[k]; xs = [p[0] for p in PATH[:seg]]; ys = [p[1] for p in PATH[:seg]]
        return (min(2.2, 62 / max(max(xs) - min(xs), max(ys) - min(ys), 14)), (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2)
    if r == 5: return ([1.6, 1.28, 1.06][k - 1], 0, 0) if k <= 3 else (1, 0, 0)
    return (1, 0, 0)

def base_layer(g, r, k):
    """زمینه‌ی تزئینیِ مشترک: از همان نشانِ اول، نشان پُر و گران‌قیمت دیده شود"""
    g.disc(34, (0, 0), .22, True)
    g.ring(45.5, .28, .5)
    g.dots(24, 45.5, 0.9, 0, .55)
    g.dots(4, 45.5, 2.0, 0, .9)

def motif(i):
    r, k = divmod(i - 1, 8); k += 1
    inner = G(); ROWFN[r](inner, k)
    s_, cx, cy = fit(r, k)
    g = G(); base_layer(g, r, k)
    if (s_, cx, cy) != (1, 0, 0):
        g.add(f'<g transform="translate(0 0) scale({f(s_)}) translate({f(-cx)} {f(-cy)})">' + ''.join(inner.l) + '</g>')
    else: g.l += inner.l
    return g

ROW_FRAMES = ['circle', 'hex', 'octagon', 'circle', 'hex', 'octagon']
