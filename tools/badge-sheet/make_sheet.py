#!/usr/bin/env python3
"""Routine Planner — Achievement Badge Sheet (۴۸ نشان، SVG برداری + PNG).
یک Design System مشترک: لبه‌ی فلزیِ ظریف (Tier) + صفحه‌ی فرورفته‌ی رنگیِ هر ردیف + نمادِ هندسیِ خطی. بدون متن، بدون پیکسل‌آرت."""
import math, os, sys
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
os.makedirs(OUT, exist_ok=True)

# ------------------------------------------------------------------ پالت
METAL = {  # (روشن, میانی, تیره)
    'bronze': ('#F2C9A4', '#C98E5E', '#7B4B2D'),
    'silver': ('#F8FAFC', '#BEC7D2', '#707B8A'),
    'gold': ('#FFEFB8', '#E2B94A', '#8E6914'),
    'platinum': ('#F3FBFF', '#B5D2E2', '#5E89A2'),
    'legendary': ('#FFF4D6', '#D8B87A', '#9C7B3A'),
}
ROWS = {  # (روشن, تیره) صفحه  +  رنگِ خط  +  رنگِ درخشش
    0: ('#2F5BA8', '#12295A', '#F4EBD3', '#9DB8F0'),   # Deep Blue
    1: ('#8A74D6', '#40308E', '#F3EEFF', '#C9BBFF'),   # Soft Violet
    2: ('#2FA27E', '#0F5642', '#EEF8E8', '#9FE3C4'),   # Emerald
    3: ('#A5415F', '#541629', '#F8E7DD', '#F0A9BF'),   # Burgundy
    4: ('#EAD9B0', '#B79C63', '#1F2B4E', '#FFF3CF'),   # Champagne (خطِ نیوی)
    5: ('#3C3F78', '#14163A', '#F2DFA6', '#E8D49A'),   # Midnight + gold
}

# ------------------------------------------------------------------ هندسه
def P(r, a):  # a به درجه، ۰ = بالا، ساعت‌گرد
    t = math.radians(a - 90)
    return (r * math.cos(t), r * math.sin(t))
def f(v): return ('%.2f' % v).rstrip('0').rstrip('.')
def pts(lst): return ' '.join(f(x) + ',' + f(y) for x, y in lst)
def ngon(n, r, rot=0): return [P(r, rot + i * 360 / n) for i in range(n)]

def rounded_poly(points, k=0.2):
    n = len(points); d = ''
    for i in range(n):
        p, a, b = points[i], points[i - 1], points[(i + 1) % n]
        def toward(q): return (p[0] + (q[0] - p[0]) * k, p[1] + (q[1] - p[1]) * k)
        s, e = toward(a), toward(b)
        d += ('M' if i == 0 else 'L') + f(s[0]) + ',' + f(s[1]) + 'Q' + f(p[0]) + ',' + f(p[1]) + ' ' + f(e[0]) + ',' + f(e[1])
    return d + 'Z'

def frame_path(kind, r):
    if kind == 'circle': return f'M{f(-r)},0A{f(r)},{f(r)} 0 1 0 {f(r)},0A{f(r)},{f(r)} 0 1 0 {f(-r)},0Z'
    if kind == 'hex': return rounded_poly(ngon(6, r * 1.04, 0), .2)
    if kind == 'diamond': return rounded_poly(ngon(4, r * 1.12, 0), .26)
    if kind == 'octagon': return rounded_poly(ngon(8, r * 1.04, 22.5), .2)
    if kind == 'square':
        s = r * .9; return rounded_poly([(-s, -s), (s, -s), (s, s), (-s, s)], .24)
    raise ValueError(kind)

# ------------------------------------------------------------------ عناصرِ نماد (مختصات: مرکز ۰،۰؛ ناحیه ≈ شعاع ۴۸)
class G:
    def __init__(s): s.l = []; s.soft = []
    def add(s, x): s.l.append(x)
    def line(s, a, b, w=1, op=1): s.add(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" stroke-width="{f(3.2*w)}" opacity="{op}"/>')
    def ring(s, r, w=1, op=1, c=(0, 0)): s.add(f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}" fill="none" stroke-width="{f(3.2*w)}" opacity="{op}"/>')
    def disc(s, r, c=(0, 0), op=1, glow=False): s.add(f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}" class="{"gl" if glow else "fl"}" stroke="none" opacity="{op}"/>')
    def dots(s, n, R, size, rot=0, op=1):
        for i in range(n):
            x, y = P(R, rot + i * 360 / n); s.disc(size, (x, y), op)
    def arc(s, r, a0, a1, w=1, op=1):
        x0, y0 = P(r, a0); x1, y1 = P(r, a1); large = 1 if (a1 - a0) % 360 > 180 else 0
        s.add(f'<path d="M{f(x0)},{f(y0)}A{f(r)},{f(r)} 0 {large} 1 {f(x1)},{f(y1)}" fill="none" stroke-width="{f(3.2*w)}" opacity="{op}"/>')
    def poly(s, points, w=1, op=1, close=True, fill=False):
        d = pts(points); tag = 'polygon' if close else 'polyline'
        s.add(f'<{tag} points="{d}" class="{"sf" if fill else "nf"}" stroke-width="{f(3.2*w)}" opacity="{op}"/>')
    def path(s, d, w=1, op=1, fill=False): s.add(f'<path d="{d}" class="{"sf" if fill else "nf"}" stroke-width="{f(3.2*w)}" opacity="{op}"/>')
    def rect(s, x, y, w_, h_, r=3, w=1, op=1, fill=False):
        s.add(f'<rect x="{f(x)}" y="{f(y)}" width="{f(w_)}" height="{f(h_)}" rx="{f(r)}" class="{"sf" if fill else "nf"}" stroke-width="{f(3.2*w)}" opacity="{op}"/>')
    def star(s, n, R, r, rot=0, w=.8, fill=True, op=1):
        p = []
        for i in range(n * 2): p.append(P(R if i % 2 == 0 else r, rot + i * 180 / n))
        s.poly(p, w, op, True, fill)
    def spark(s, R, k=.14, w=.8, fill=True, c=(0, 0)):
        d = f'M{f(c[0])},{f(c[1]-R)}Q{f(c[0]+R*k)},{f(c[1]-R*k)} {f(c[0]+R)},{f(c[1])}Q{f(c[0]+R*k)},{f(c[1]+R*k)} {f(c[0])},{f(c[1]+R)}Q{f(c[0]-R*k)},{f(c[1]+R*k)} {f(c[0]-R)},{f(c[1])}Q{f(c[0]-R*k)},{f(c[1]-R*k)} {f(c[0])},{f(c[1]-R)}Z'
        s.path(d, w, 1, fill)

def book_open(g, sc=1.0, c=(0, 4)):
    def T(x, y): return (c[0] + x * sc, c[1] + y * sc)
    L = [T(0, -10), T(-30, -16), T(-30, 22), T(0, 28)]
    R = [T(0, -10), T(30, -16), T(30, 22), T(0, 28)]
    g.poly(L, 1, 1, True, True); g.poly(R, 1, 1, True, True)
    g.line(T(0, -10), T(0, 28), .8)

def book_closed(g, c=(0, 0), w=40, h=56):
    g.rect(c[0] - w / 2, c[1] - h / 2, w, h, 5, 1, 1, True)
    g.line((c[0] - w / 2 + 9, c[1] - h / 2 + 3), (c[0] - w / 2 + 9, c[1] + h / 2 - 3), .6, .9)
    g.add(f'<path d="M{f(c[0]+5)},{f(c[1]-6)}l7,7l-7,7l-7,-7z" class="fl" stroke="none"/>')

# ------------------------------------------------------------------ ۴۸ نشان
def motif(i):
    g = G()
    if i == 1: g.ring(30, .95); g.ring(41, .45, .55); g.disc(7, glow=True)
    elif i == 2:
        for a in (0, 120, 240): g.ring(17, .85, 1, P(16, a))
        g.disc(3.5)
    elif i == 3:
        for k in range(7): g.arc(36, k * 360 / 7 + 5, (k + 1) * 360 / 7 - 5, 1.5)
        g.ring(15, .5, .7); g.disc(3.4)
    elif i == 4:
        g.ring(37, .95); g.ring(22, .95); g.dots(14, 29.5, 1.5, 0, .85)
    elif i == 5:
        g.ring(38, .95); g.star(8, 25, 9, 0, .5); g.disc(4, glow=True)
        for k in range(30):
            a = k * 12; g.line(P(42.5, a), P(46.5, a), .35, .75)
    elif i == 6:
        g.ring(10, .8); g.arc(24, -20, 250, .95); g.arc(38, 40, 290, .95); g.disc(3)
    elif i == 7:
        h1 = ngon(6, 38); h2 = ngon(6, 21, 30)
        g.poly(h1, 1.05); g.poly(h2, .8)
        for a in range(6): g.line(P(21, 30 + a * 60), P(38, a * 60), .45, .8) if False else g.line(h2[a], h1[a], .45, .8)
        g.disc(5, glow=True)
    elif i == 8:
        g.disc(11, glow=True)
        for r, o in ((19, 1), (28, .8), (38, .6)): g.ring(r, .45, o)
        g.dots(12, 46, 1.9, 0, .9); g.dots(4, 46, 2.8, 45)
    elif i == 9: g.disc(6.5, glow=True); g.ring(18, .75); g.ring(32, .7, .65)
    elif i == 10:
        g.ring(34, .95); g.ring(19, .95); g.disc(4.5)
        for a in (0, 90, 180, 270): g.line(P(27, a), P(46, a), .7)
    elif i == 11:
        for h, o in ((42, 1), (30, .85), (18, .7)): g.poly([(0, -h), (h, 0), (0, h), (-h, 0)], .85, o)
        g.disc(3.5, glow=True)
    elif i == 12:
        for a in range(0, 360, 45):
            x0, y0 = P(42, a); cx, cy = P(21, a + 38)
            g.path(f'M{f(x0)},{f(y0)}Q{f(cx)},{f(cy)} 0,0', .7)
        g.ring(44, .35, .5); g.disc(4.5, glow=True)
    elif i == 13:
        g.ring(22, .95, 1, (0, -12)); g.ring(22, .95, 1, (0, 12)); g.ring(41, .4, .5); g.disc(3)
    elif i == 14:
        g.dots(10, 33, 4.2); g.ring(44, .4, .6); g.ring(13, .5, .7); g.disc(3)
    elif i == 15:
        g.dots(12, 40, 2.8); g.dots(8, 28, 3.2, 22.5); g.poly(ngon(6, 15), .6); g.disc(3.4, glow=True)
    elif i == 16:
        g.spark(41, .12, .7); g.ring(45, .4, .6)
        for a in (45, 135, 225, 315): g.disc(2.4, P(27, a))
    elif i == 17:
        g.poly([(0, -38), (38, 0), (0, 38), (-38, 0)], .95); g.poly([(-15, 0), (-4, 12), (17, -13)], 1.35, 1, False)
    elif i == 18:
        for r in range(2):
            for c in range(5): g.rect(-38 + c * 16.5, -14 + r * 18 if r == 0 else 6, 12, 12, 2.5, .8, 1, True)
    elif i == 19:
        g.rect(-37, -37, 74, 74, 7, .95)
        for v in (-12, 12): g.line((v, -37), (v, 37), .4, .7); g.line((-37, v), (37, v), .4, .7)
        for x in (-12, 12):
            for y in (-12, 12): g.disc(2.6, (x, y))
    elif i == 20:
        for r in range(5):
            for c in range(5): g.rect(-33 + c * 14.5 - 0, -33 + r * 14.5, 7.5, 7.5, 1.8, .6, 1, True)
    elif i == 21:
        for rot, o in ((0, 1), (22.5, .8), (45, .65)): g.poly(ngon(4, 38, rot + 45), .75, o)
        g.dots(8, 20, 2.2); g.disc(3.4, glow=True)
    elif i == 22:
        g.poly([(0, -44), (44, 0), (0, 44), (-44, 0)], .9); g.rect(-24, -24, 48, 48, 4, .8)
        for v in (-8, 8): g.line((v, -24), (v, 24), .35, .7); g.line((-24, v), (24, v), .35, .7)
        g.poly([(-9, 0), (-2, 7), (10, -8)], 1.1, 1, False)
    elif i == 23:
        g.ring(40, .95); g.poly([(-22, 3), (-7, 19), (25, -19)], 1.5, 1, False)
    elif i == 24:
        for rot, h in ((0, 36), (22.5, 31), (45, 26)): g.poly(ngon(4, h * 1.4, rot + 45), .7, .9)
        g.dots(8, 45, 1.9); g.disc(4.4, glow=True)
    elif i == 25: book_closed(g)
    elif i == 26:
        g.rect(-33, 4, 66, 22, 4, .95, 1, True); g.line((-24, 7), (-24, 23), .5, .9)
        g.rect(-26, -22, 52, 22, 4, .95, 1, True); g.line((-17, -19), (-17, -3), .5, .9)
    elif i == 27:
        for rot in (-26, 0, 26): g.add(f'<g transform="rotate({rot} 0 28)"><rect x="-17" y="-30" width="34" height="56" rx="5" class="sf" stroke-width="2.6" opacity="{1 if rot==0 else .8}"/></g>')
    elif i == 28:
        book_open(g, .86, (0, 12)); g.arc(24, -50, 50, .5, .9); g.arc(33, -56, 56, .4, .65); g.arc(42, -62, 62, .35, .45)
    elif i == 29: g.ring(42, .85); book_open(g, .62, (0, 4)); g.disc(2.8, (0, -27), glow=True)
    elif i == 30:
        book_open(g, .56, (0, 6)); g.ring(46, .35, .6)
        for k in range(24):
            a = k * 15; g.line(P(26 if k % 2 else 22, a), P(40 if k % 2 else 36, a) if False else P(40 if k % 2 else 36, a), .4, .9)
    elif i == 31:
        g.path('M-13,-36H13V36L0,23L-13,36Z', .95, 1, True); g.ring(44, .4, .55); g.disc(3.2, (0, -22), glow=True)
    elif i == 32:
        book_open(g, .8, (0, 10)); g.disc(6, (0, -24), glow=True); g.arc(18, -60, 60, .4, .7)
    elif i == 33:
        g.poly([(-30, 22), (-6, 2), (18, 12)], .9, 1, False); g.disc(5.5, (-30, 22)); g.ring(6.5, .55, 1, (18, 12))
    elif i == 34:
        g.poly([(-32, 24), (-10, 6), (8, 14), (30, -18)], .9, 1, False); g.disc(4.4, (-32, 24)); g.disc(3.5, (-10, 6)); g.disc(3.5, (8, 14))
        g.poly([(30, -30), (40, -18), (30, -6), (20, -18)], .65, 1, True, True)
    elif i == 35:
        g.poly([(-36, 28), (-36, 12), (-14, 12), (-14, -4), (8, -4), (8, -20), (30, -20)], .85, 1, False)
        for p in ((-36, 28), (-14, 12), (8, -4)): g.disc(3.4, p)
        g.poly([(30, -32), (40, -20), (30, -8), (20, -20)], .6, 1, True, True)
    elif i == 36:
        g.poly([(0, -46), (14, 0), (0, 46), (-14, 0)], .95)
        for y in (-22, 0, 22): g.line((-9 + abs(y) * .0, y), (9, y), .45, .85)
        g.disc(3.2, (0, -52 + 6)); g.ring(3.5, .5, .9, (0, 40))
    elif i == 37:
        g.dots(7, 32, 5); g.poly(ngon(7, 32), .35, .55); g.ring(43, .4, .55); g.disc(3.4, glow=True)
    elif i == 38:
        g.rect(-34, -32, 68, 68, 8, .95); g.line((-34, -15), (34, -15), .5)
        g.line((-16, -42), (-16, -30), .7); g.line((16, -42), (16, -30), .7)
        for r in range(4):
            for c in range(5): g.disc(2.5, (-24 + c * 12, -3 + r * 11))
    elif i == 39:
        g.poly(ngon(6, 39), .95, 1, True, True); g.poly(ngon(6, 26, 30), .8, 1, True, True); g.poly(ngon(6, 13), .7, 1, True, True)
    elif i == 40:
        g.arc(35, 15, 335, .95); g.disc(4.4, P(35, 15)); g.ring(5.4, .5, 1, P(35, 335)); g.poly([(0, -10), (9, 0), (0, 10), (-9, 0)], .6, 1, True, True)
    elif i == 41:
        g.ring(30, .95); g.poly([(0, -13), (13, 0), (0, 13), (-13, 0)], .6, 1, True, True)
        for k in range(10):
            a = k * 36; g.line(P(40, a), P(46, a), .45)
    elif i == 42:
        g.ring(17, .9, 1, P(17, 90)); g.line((-26, -22), (-26, 22), .9); g.line((-26, -22), (-33, -15), .9)
        g.ring(46, .35, .6); g.disc(3.4, P(46, 0), glow=True)
    elif i == 43:
        for a in (90, 210, 330): g.ring(19, .7, .95, P(14, a))
        g.disc(3.6, glow=True); g.ring(44, .4, .6); g.dots(6, 44, 1.6, 30)
    elif i == 44:
        for r, o in ((42, 1), (35, .85), (28, .7), (21, .6), (14, .5)): g.ring(r, .38, o)
        g.spark(9, .16, .45)
    elif i == 45:
        for k in range(24):
            a = k * 15; g.line(P(24, a), P(45 if k % 2 == 0 else 38, a), .4, .95)
        g.ring(18, .8); g.poly([(0, -10), (10, 0), (0, 10), (-10, 0)], .5, 1, True, True); g.ring(49, .3, .5)
    elif i == 46:
        g.ring(14.5, .5)
        for a in range(0, 360, 60): g.ring(14.5, .5, 1, P(14.5, a))
        g.ring(29, .5, .85); g.ring(42, .7, .9)
    elif i == 47:
        g.poly(ngon(6, 41), .5); g.poly(ngon(8, 33, 22.5), .5); g.poly(ngon(12, 25, 15), .5)
        for a in range(12): g.line(P(25, a * 30 + 15), P(41, a * 30 + 15) if False else P(33, a * 30 + 15), .3, .8)
        g.disc(3.4, glow=True)
    elif i == 48:
        g.ring(46, .3, .7); g.ring(38, .5, .9); g.spark(36, .1, .6)
        for a in range(0, 360, 45): g.disc(1.9 if a % 90 else 2.6, P(43, a + 22.5))
        g.disc(5, glow=True)
    return g

try:
    import os
    if os.environ.get('CLASSIC') != '1':
        import sys; sys.modules.setdefault('make_sheet', sys.modules[__name__])
        import progressive; motif = progressive.motif
        _PF = progressive.ROW_FRAMES
except ImportError as e:
    print('progressive not loaded', e)
FRAMES = {1: 'circle', 2: 'circle', 3: 'circle', 4: 'circle', 5: 'circle', 6: 'circle', 7: 'hex', 8: 'circle',
          9: 'circle', 10: 'circle', 11: 'diamond', 12: 'circle', 13: 'circle', 14: 'circle', 15: 'hex', 16: 'circle',
          17: 'diamond', 18: 'square', 19: 'square', 20: 'square', 21: 'octagon', 22: 'diamond', 23: 'circle', 24: 'octagon',
          25: 'square', 26: 'square', 27: 'hex', 28: 'circle', 29: 'circle', 30: 'circle', 31: 'hex', 32: 'circle',
          33: 'hex', 34: 'hex', 35: 'diamond', 36: 'diamond', 37: 'circle', 38: 'square', 39: 'hex', 40: 'circle',
          41: 'circle', 42: 'octagon', 43: 'circle', 44: 'circle', 45: 'circle', 46: 'hex', 47: 'octagon', 48: 'circle'}
if 'progressive' in globals(): FRAMES = {i: _PF[(i - 1) // 8] for i in range(1, 49)}
TIERS = ('bronze bronze silver silver gold gold platinum legendary '
         'bronze bronze silver gold silver silver gold platinum '
         'bronze bronze silver silver gold platinum gold platinum '
         'bronze bronze silver gold gold platinum silver silver '
         'bronze silver gold silver silver gold platinum gold '
         'bronze silver gold platinum legendary platinum legendary legendary').split()

SHARED_DEFS = '''
<filter id="blur8" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="7"/></filter>
<filter id="blur3" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2.6"/></filter>
<filter id="emb" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="1.6" stdDeviation="1.1" flood-color="#000" flood-opacity=".38"/></filter>
'''

def badge_svg(i, uid):
    row = (i - 1) // 8
    kind = FRAMES[i]; tier = TIERS[i - 1]
    light, mid, dark = METAL[tier]
    p_top, p_bot, line, glow = ROWS[row]
    R = 86
    outer = frame_path(kind, R); plate = frame_path(kind, R - 13)
    g = motif(i)
    crown = i % 8 == 0
    if crown: tier = 'legendary'; light, mid, dark = METAL[tier]
    legend = tier == 'legendary'
    rim_stops = (f'<stop offset="0" stop-color="{light}"/><stop offset=".28" stop-color="{mid}"/><stop offset=".52" stop-color="{dark}"/>'
                 f'<stop offset=".76" stop-color="{mid}"/><stop offset="1" stop-color="{light}"/>')
    if legend:
        rim_stops = ('<stop offset="0" stop-color="#FFF1CF"/><stop offset=".22" stop-color="#E7C98C"/><stop offset=".45" stop-color="#C6B4F0"/>'
                     '<stop offset=".68" stop-color="#9FD0F2"/><stop offset=".86" stop-color="#EBD08C"/><stop offset="1" stop-color="#FFF1CF"/>')
    inner_rings = ''.join(f'<path d="{frame_path(kind, (R-13) * k)}" fill="none" stroke="#fff" stroke-opacity=".10" stroke-width=".9"/>' for k in (.92, .84))
    extra = ''
    if legend:
        extra = ''.join(f'<line x1="{f(P(R+4,a)[0])}" y1="{f(P(R+4,a)[1])}" x2="{f(P(R+8,a)[0])}" y2="{f(P(R+8,a)[1])}" stroke="{mid}" stroke-width="1.2" stroke-linecap="round" opacity=".85"/>' for a in range(0, 360, 10))
        extra += f'<path d="M0,{-R-6}l5,6l-5,6l-5,-6z" fill="url(#{uid}r)"/>'
    back = ''
    if crown:
        rays = ''.join(f'<line x1="{f(P(R+1,a)[0])}" y1="{f(P(R+1,a)[1])}" x2="{f(P(R+(17 if k%2==0 else 9),a)[0])}" y2="{f(P(R+(17 if k%2==0 else 9),a)[1])}" stroke="url(#{uid}r)" stroke-width="{3.4 if k%2==0 else 1.8}" stroke-linecap="round"/>' for k, a in enumerate(range(0, 360, 15)))
        def sp(a, r, z):
            x, y = P(r, a); return f'<path transform="translate({f(x)} {f(y)})" d="M0,{-z}Q0,0 {z},0Q0,0 0,{z}Q0,0 {-z},0Q0,0 0,{-z}z" fill="#D9A93A"/>'
        back = (f'<circle r="108" fill="url(#{uid}h)"/>' + rays)
        sparkles = sp(45, R + 22, 6) + sp(135, R + 20, 4) + sp(225, R + 22, 5) + sp(315, R + 20, 4)
        extra = (sparkles + f'<path d="M0,{-R-20}l7,10l-7,10l-7,-10z" fill="url(#{uid}r)" stroke="#000" stroke-opacity=".3" stroke-width=".8"/>'
                 f'<path d="M0,{-R-14}l3,4l-3,4l-3,-4z" fill="{glow}"/>'
                 f'<path d="{frame_path(kind, R + 3.5)}" fill="none" stroke="url(#{uid}r)" stroke-width="1" opacity=".9"/>')
    return f'''
<defs>
 <radialGradient id="{uid}h" cx=".5" cy=".5" r=".5"><stop offset=".6" stop-color="#F3D58A" stop-opacity="0"/><stop offset=".82" stop-color="#F3D58A" stop-opacity=".95"/><stop offset="1" stop-color="#F3D58A" stop-opacity="0"/></radialGradient>
 <linearGradient id="{uid}r" x1="0" y1="0" x2="1" y2="1">{rim_stops}</linearGradient>
 <radialGradient id="{uid}p" cx=".3" cy=".22" r="1.15"><stop offset="0" stop-color="{p_top}"/><stop offset="1" stop-color="{p_bot}"/></radialGradient>
 <radialGradient id="{uid}g" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="{glow}" stop-opacity=".95"/><stop offset="1" stop-color="{glow}" stop-opacity=".55"/></radialGradient>
 <linearGradient id="{uid}s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".34"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
 <clipPath id="{uid}c"><path d="{plate}"/></clipPath>
</defs>
{back}
<path d="{outer}" transform="translate(0 7)" fill="#000" opacity=".26" filter="url(#blur8)"/>
<path d="{outer}" fill="url(#{uid}r)"/>
<path d="{outer}" fill="none" stroke="#000" stroke-opacity=".38" stroke-width="1.1"/>
<path d="{frame_path(kind, R - 6.5)}" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width=".9"/>
<path d="{plate}" fill="url(#{uid}p)"/>
<g clip-path="url(#{uid}c)">
 <path d="{plate}" fill="none" stroke="#000" stroke-opacity=".42" stroke-width="12" filter="url(#blur3)"/>
 {inner_rings}
 <ellipse cx="0" cy="-58" rx="92" ry="64" fill="url(#{uid}s)"/>
</g>
<path d="{plate}" fill="none" stroke="{light}" stroke-opacity=".6" stroke-width="1.2"/>
<g filter="url(#emb)" fill="none" stroke="{line}" stroke-linecap="round" stroke-linejoin="round" class="m{uid}" transform="scale(1.16)">
 {''.join(g.l)}
</g>
{extra}
'''

CSS = '''
.nf{fill:none}.sf{fill:rgba(255,255,255,.16)}.fl{fill:CLINE}.gl{fill:url(#GID)}
'''

def symbol_style(i, uid):
    line = ROWS[(i - 1) // 8][2]
    return (f'.m{uid} .nf{{fill:none}} .m{uid} .sf{{fill:{line};fill-opacity:.17}} .m{uid} .fl{{fill:{line};stroke:none}} '
            f'.m{uid} .gl{{fill:url(#{uid}g);stroke:none}}')

def single_svg(i):
    uid = f'b{i}'
    VB = -118 if i % 8 == 0 else -100
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{VB} {VB} {-2*VB} {-2*VB}" width="400" height="400"><defs>{SHARED_DEFS}</defs>'
            f'<style>{symbol_style(i, uid)}</style>{badge_svg(i, uid)}</svg>')

def sheet_svg():
    cols, rows, cell, margin, size = 8, 6, 250, 70, 205
    W = margin * 2 + cols * cell; H = margin * 2 + rows * cell
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
           f'<defs>{SHARED_DEFS}<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6F4EF"/><stop offset="1" stop-color="#EEEBE4"/></linearGradient></defs>',
           f'<rect width="{W}" height="{H}" fill="url(#bg)"/>', '<style>']
    for i in range(1, 49): out.append(symbol_style(i, f'b{i}'))
    out.append('</style>')
    for i in range(1, 49):
        r, c = divmod(i - 1, 8)
        cx = margin + c * cell + cell / 2; cy = margin + r * cell + cell / 2
        out.append(f'<g transform="translate({f(cx)} {f(cy)}) scale({size/200})">{badge_svg(i, f"b{i}")}</g>')
    out.append('</svg>')
    return '\n'.join(out)

if __name__ == '__main__':
    open(os.path.join(OUT, 'badge-sheet.svg'), 'w', encoding='utf8').write(sheet_svg())
    for i in range(1, 49):
        open(os.path.join(OUT, f'badge_{i:02d}.svg'), 'w', encoding='utf8').write(single_svg(i))
    print('ok')
