# طرحِ «مفهومی»: هر نشان یک تصویرِ آشنا و مرتبط با کارش دارد (شعله+عددِ روزِ استمرار، کرونومتر، تیر و هدف، کتاب، سپر، تاج…).
import math
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from make_sheet import G, P, f

_FONT = TTFont('../../flutter_app/assets/fonts/Vazirmatn-arabic.ttf')
_CM = _FONT.getBestCmap(); _GS = _FONT.getGlyphSet(); _UPM = _FONT['head'].unitsPerEm
_PD = '۰۱۲۳۴۵۶۷۸۹'

def num(g, text, cx, cy, size, cls='fl', w=0.8):
    """عددِ فارسی به‌صورت مسیر (بدون وابستگی به قلم)"""
    t = ''.join(_PD[int(c)] if c.isdigit() else c for c in str(text))
    adv = []; paths = []; x = 0
    for ch in t:
        gn = _CM[ord(ch)]; pen = SVGPathPen(_GS); _GS[gn].draw(pen)
        paths.append((x, pen.getCommands())); x += _GS[gn].width
    k = size / _UPM
    off = cx - x * k / 2
    # ارتفاعِ رقم ≈ 0.7·em
    base = cy + size * 0.35
    for px, d in paths:
        g.add(f'<path d="{d}" class="{cls}" stroke-width="{w}" stroke-linejoin="round" transform="translate({f(off + px * k)} {f(base)}) scale({f(k)} {f(-k)})"/>')

DEFS = ('<defs><linearGradient id="fireG" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFD66B"/><stop offset=".55" stop-color="#FF9A2E"/><stop offset="1" stop-color="#F0561B"/></linearGradient>'
        '<linearGradient id="goldG" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF0A8"/><stop offset=".5" stop-color="#F2BE3A"/><stop offset="1" stop-color="#C98A0C"/></linearGradient></defs>')

def grp(g, inner, cx=0, cy=0, s=1.0):
    g.add(f'<g transform="translate({f(cx)} {f(cy)}) scale({f(s)})">{inner}</g>')

SW = 3.0
def L(d, cls='nf', sw=SW, extra=''):
    fill = {'fire': 'url(#fireG)', 'gold': 'url(#goldG)'}.get(cls)
    if fill: return f'<path d="{d}" fill="{fill}" stroke-width="{sw}" {extra}/>'
    return f'<path d="{d}" class="{cls}" stroke-width="{sw}" {extra}/>'

# ---------------------------------------------------------------- نمادها (مرکز ۰،۰؛ حدودِ ±۳۰)
def flame(s=1.0, glow=True):
    outer = 'M0,-30 C4,-20 17,-14 17,3 C17,17 9,27 0,27 C-9,27 -17,17 -17,3 C-17,-5 -12,-11 -7,-15 C-6,-8 -3,-4 0,-30Z'
    inner = 'M0,-2 C3,4 8,8 8,15 C8,21 4,25 0,25 C-4,25 -8,21 -8,15 C-8,9 -3,6 0,-2Z'
    return L(outer, 'fire', 2.0) + L(inner, 'gold', 0.4)

def seedling():
    return (L('M0,26 L0,-4', 'nf', 3.2) + L('M0,2 C-4,-10 -16,-12 -26,-8 C-24,2 -12,8 0,2Z', 'sf', 2.8) + L('M0,-6 C4,-18 16,-22 26,-18 C24,-8 12,-2 0,-6Z', 'gl', 2.8)
            + L('M-16,27 C-8,22 8,22 16,27', 'nf', 3.2))

def calendar(s=1.0):
    return (L('M-26,-18 H26 V26 H-26Z', 'sf', 3.0, 'stroke-linejoin="round"') + L('M-26,-6 H26', 'nf', 2.6)
            + L('M-14,-26 V-14 M14,-26 V-14', 'nf', 3.4))

def stopwatch(glow=False):
    ticks = ''.join(L(f'M{f(P(18, a)[0])},{f(P(18, a)[1])} L{f(P(21, a)[0])},{f(P(21, a)[1])}', 'nf', 2.2) for a in range(0, 360, 90))
    return (L('M-5,-26 H5 M0,-26 V-21', 'nf', 3.4) + '<circle cx="0" cy="3" r="22" class="' + ('gl' if glow else 'sf') + '" stroke-width="3"/>'
            + f'<g transform="translate(0 3)">{ticks}</g>' + L('M0,3 L0,-11 M0,3 L10,9', 'nf', 3.2) + '<circle cx="0" cy="3" r="2.6" class="fl"/>'
            + L('M17,-18 L22,-23', 'nf', 3.2))

def target(arrow=False):
    s = ('<circle r="26" class="sf" stroke-width="3"/><circle r="16" class="nf" stroke-width="2.6"/><circle r="6.5" class="gl" stroke-width="2.4"/>')
    if arrow:
        s += L('M3,-3 L27,-27 M20,-27 H27 V-20 M14,-27 H21 V-20', 'nf', 3.2)
    return s

def clipboard():
    return (L('M-20,-22 H20 V28 H-20Z', 'sf', 3.0, 'stroke-linejoin="round"') + L('M-9,-27 H9 V-18 H-9Z', 'gl', 2.6)
            + L('M-11,-4 L-6,1 L2,-9', 'nf', 3.2) + L('M6,-4 H12 M-11,12 L-6,17 L2,7 M6,12 H12', 'nf', 3.0))

def book_stack():
    return (L('M-26,12 H26 V26 H-26Z', 'sf', 2.8, 'stroke-linejoin="round"') + L('M-18,12 V26 M18,12 V26', 'nf', 2.0)
            + L('M-22,-3 H22 V12 H-22Z', 'sf', 2.8, 'stroke-linejoin="round"') + L('M-14,-3 V12 M14,-3 V12', 'nf', 2.0)
            + L('M-18,-18 H18 V-3 H-18Z', 'gold', 2.4, 'stroke-linejoin="round"') + L('M-10,-18 V-3', 'nf', 2.0))

def book_closed():
    return (L('M-18,-26 H20 V26 H-18Z', 'sf', 3.0, 'stroke-linejoin="round"') + L('M-10,-26 V26', 'nf', 2.6)
            + L('M-2,-12 H12 M-2,-4 H10', 'nf', 2.4) + '<path d="M2,12 l5,-6 l5,6 l-5,6z" class="gl" stroke-width="2"/>')

def book_open(glowing=False):
    return (L('M0,-12 C-10,-22 -22,-20 -28,-17 V20 C-22,17 -10,16 0,24 Z', 'sf', 3.0, 'stroke-linejoin="round"')
            + L('M0,-12 C10,-22 22,-20 28,-17 V20 C22,17 10,16 0,24 Z', 'gl' if glowing else 'sf', 3.0, 'stroke-linejoin="round"')
            + L('M0,-12 V24', 'nf', 2.4) + L('M-22,-8 C-14,-9 -8,-7 -5,-4 M-22,2 C-14,1 -8,3 -5,6', 'nf', 2.0))

def glasses():
    return L('M-26,-3 a9,9 0 1 0 0.1,0z M8,-3 a9,9 0 1 0 0.1,0z', 'nf', 3.0, 'transform="translate(10 0)"') if False else \
        ('<circle cx="-12" cy="0" r="9" class="nf" stroke-width="3"/><circle cx="12" cy="0" r="9" class="nf" stroke-width="3"/>' + L('M-3,-1 Q0,-5 3,-1 M-21,-2 L-27,-6 M21,-2 L27,-6', 'nf', 3.0))

def flag(planted=False):
    return (L('M-12,28 V-26', 'nf', 3.4) + L('M-12,-26 H18 L10,-14 L18,-2 H-12', 'gold', 2.4, 'stroke-linejoin="round"')
            + (L('M-22,28 H0', 'nf', 3.4) if True else ''))

def trophy():
    return (L('M-16,-22 H16 V-6 C16,6 8,12 0,12 C-8,12 -16,6 -16,-6Z', 'gold', 2.6, 'stroke-linejoin="round"')
            + L('M-16,-18 H-26 C-26,-6 -22,0 -14,2 M16,-18 H26 C26,-6 22,0 14,2', 'nf', 3.0)
            + L('M0,12 V20 M-10,26 H10 M-7,20 H7', 'nf', 3.2))

def shield(check=False, gem=False):
    s = L('M0,-28 L22,-20 V0 C22,14 10,24 0,28 C-10,24 -22,14 -22,0 V-20Z', 'sf', 3.2, 'stroke-linejoin="round"')
    if check: s += L('M-10,0 L-3,8 L11,-8', 'nf', 3.6)
    if gem: s += '<path d="M0,-12 l10,10 l-10,12 l-10,-12z" fill="url(#goldG)" stroke-width="2.2" class="nf"/>'
    return s

def mountain():
    return (L('M-30,26 L-8,-12 L4,8 L14,-4 L30,26Z', 'sf', 3.0, 'stroke-linejoin="round"') + L('M-8,-12 V-28', 'nf', 3.2) + L('M-8,-28 H8 L2,-22 L8,-16 H-8', 'gold', 2.2, 'stroke-linejoin="round"'))

def chevrons(n):
    s = ''
    for i in range(n):
        y = 14 - i * 14
        s += L(f'M-22,{y} L0,{y - 14} L22,{y}', 'nf' if i < n - 1 else 'gl', 4.4, 'stroke-linejoin="round" stroke-linecap="round"')
    return s

def star(r=26):
    pts = []
    for i in range(10):
        a = i * 36; rr = r if i % 2 == 0 else r * 0.44
        pts.append(P(rr, a))
    return '<polygon points="' + ' '.join(f'{f(x)},{f(y)}' for x, y in pts) + f'" fill="url(#goldG)" stroke-width="2.4" class="nf" stroke-linejoin="round"/>'

def crown(gems=False):
    s = L('M-26,16 L-30,-14 L-14,0 L0,-24 L14,0 L30,-14 L26,16Z', 'gold', 2.6, 'stroke-linejoin="round"') + L('M-26,24 H26', 'nf', 3.6)
    if gems: s += '<circle cx="-12" cy="9" r="3" class="fl"/><circle cx="0" cy="6" r="3.6" class="fl"/><circle cx="12" cy="9" r="3" class="fl"/>'
    return s

def laurel(n=7, r=38):
    out = ''
    for side in (-1, 1):
        for i in range(n):
            a = 190 + i * 15
            x, y = P(r, 180 + (a - 180) * side)
            rot = 180 + (a - 180) * side + 90
            out += f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="3.4" ry="7.5" class="fl" opacity=".9" transform="rotate({f(rot)} {f(x)} {f(y)})"/>'
    return out

def rays(r0=34, r1=44, n=16):
    return ''.join(L(f'M{f(P(r0, a)[0])},{f(P(r0, a)[1])} L{f(P(r1, a)[0])},{f(P(r1, a)[1])}', 'nf', 2.0) for a in range(0, 360, int(360 / n)))

def waves():
    return (L('M-28,-14 C-18,-24 -10,-4 0,-14 C10,-24 18,-4 28,-14', 'nf', 3.2) + L('M-28,2 C-18,-8 -10,12 0,2 C10,-8 18,12 28,2', 'gl', 3.2)
            + L('M-28,18 C-18,8 -10,28 0,18 C10,8 18,28 28,18', 'nf', 3.2))

def lotus():
    return (L('M0,22 C-8,10 -8,-8 0,-24 C8,-8 8,10 0,22Z', 'gl', 2.8) + L('M0,22 C-14,16 -24,4 -26,-10 C-14,-8 -4,4 0,22Z', 'sf', 2.8) + L('M0,22 C14,16 24,4 26,-10 C14,-8 4,4 0,22Z', 'sf', 2.8)
            + L('M-30,26 C-14,20 14,20 30,26', 'nf', 3.0))

def medal():
    return (L('M-10,-28 L-4,-8 M10,-28 L4,-8', 'nf', 4.0) + '<circle cx="0" cy="8" r="16" fill="url(#goldG)" class="nf" stroke-width="2.6"/>' + '<path d="M0,-1 l4,8 l9,1 l-6.5,6 l1.8,9 l-8.3,-4.4 l-8.3,4.4 l1.8,-9 l-6.5,-6 l9,-1z" class="fl" transform="scale(.62) translate(0 6)"/>')

def wings():
    s = ''
    for side in (-1, 1):
        s += ''.join(L(f'M{side*12},{y} C{side*28},{y-14} {side*38},{y-6} {side*44},{y-16 + i*3}', 'nf', 2.6 - i * 0.2) for i, y in enumerate((-4, 4, 12)))
    return s

# ---------------------------------------------------------------- ۴۸ نشان
def _count_icon(g, icon, text, s=1.05):
    grp(g, icon, 0, -17, s * 0.82)
    num(g, text, 0, 35, 27 if len(str(text)) < 3 else 22, 'fl', 1.0)

def _watch_num(g, text):
    grp(g, '<circle cx="0" cy="3" r="22" class="sf" stroke-width="3"/>' + L('M-5,-26 H5 M0,-26 V-21 M17,-18 L22,-23', 'nf', 3.4), 0, 0, 1.3)
    num(g, text, 0, 4, 29 if len(str(text)) < 3 else 22, 'fl', 0.9)

def _cal_num(g, text, stars=False):
    grp(g, calendar(), 0, -2, 1.3)
    num(g, text, 0, 13, 34 if len(str(text)) < 3 else 26, 'fl', 0.9)
    if stars: grp(g, star(8), 24, -30, 0.75)

def motif(i):
    g = G(); g.add(DEFS); r, k = divmod(i - 1, 8)
    if r == 0:  # استمرار: شعله + عددِ روز
        days = [None, 3, 7, 14, 30, 60, 100, 365][k]
        if k == 0: grp(g, seedling(), 0, 2, 1.5)
        elif k == 7:
            g.add(''.join(L(f'M{f(P(38, a)[0])},{f(P(38, a)[1])} L{f(P(46, a)[0])},{f(P(46, a)[1])}', 'nf', 2.4) for a in range(-75, 76, 15))); grp(g, flame(), 0, -14, 1.05); num(g, 365, 0, 34, 25, 'fl', 1.0)
        else: _count_icon(g, flame(), days, 1.15)
    elif r == 1:  # تمرکز
        if k == 0: grp(g, stopwatch(), 0, 0, 1.55)
        elif k == 1: grp(g, target(), 0, 0, 1.6)
        elif k == 2: grp(g, target(True), 0, 2, 1.5)
        elif k == 3: grp(g, waves(), 0, 0, 1.6)
        elif k == 4: grp(g, lotus(), 0, 2, 1.6)
        elif k == 5: _watch_num(g, 10)
        elif k == 6: _watch_num(g, 100)
        else: g.add(laurel(7, 40)); grp(g, target(True), 0, 0, 1.15)
    elif r == 2:  # بهره‌وری
        if k == 0: grp(g, '<rect x="-24" y="-24" width="48" height="48" rx="9" class="sf" stroke-width="3.2"/>' + L('M-13,0 L-4,10 L14,-12', 'nf', 5.0), 0, 0, 1.5)
        elif k == 6: grp(g, flag(), 0, 2, 1.55)
        elif k == 7:
            g.add(laurel(7, 40)); grp(g, crown(True), 0, -14, 0.85); grp(g, '<circle r="14" class="gl" stroke-width="2.6"/>' + L('M-7,0 L-2,6 L8,-6', 'nf', 3.6), 0, 18, 0.95)
        else: _count_icon(g, clipboard(), [None, 10, 50, 100, 500, 1000][k], 1.05)
    elif r == 3:  # مطالعه
        if k == 0: grp(g, book_closed(), 0, 0, 1.5)
        elif k == 6: grp(g, book_open(), 0, 12, 1.25); grp(g, glasses(), 0, -22, 0.85)
        elif k == 7: g.add(laurel(7, 40)); grp(g, book_open(True), 0, 6, 1.1); grp(g, star(8), 0, -30, 0.55)
        else: _count_icon(g, book_stack(), [None, 5, 10, 25, 50, 100][k], 1.1)
    elif r == 4:  # انضباط و چالش
        if k == 0: grp(g, flag(), 0, 2, 1.55)
        elif k == 1: grp(g, flag(), -6, -2, 1.3); grp(g, L('M-8,0 L-1,8 L14,-10', 'nf', 4.4), 20, 18, 0.95)
        elif k == 2: grp(g, trophy(), 0, 0, 1.5)
        elif k == 3: grp(g, shield(True), 0, 0, 1.55)
        elif k == 4: _cal_num(g, 7)
        elif k == 5: _cal_num(g, 30, True)
        elif k == 6: grp(g, shield(False, True), 0, 0, 1.55)
        else: grp(g, mountain(), 0, 4, 1.4); grp(g, '<circle r="7" class="gl" stroke-width="2"/>', 24, -26, 1.0)
    else:  # تسلط
        if k <= 2: grp(g, chevrons(k + 1), 0, -8 + k * 3, 1.0); num(g, [10, 25, 50][k], 0, 31, 30, 'fl', 1.0)
        elif k == 3: grp(g, star(26), 0, -8, 1.0); num(g, 75, 0, 32, 30, 'fl', 1.0)
        elif k == 4: grp(g, crown(), 0, -10, 1.05); num(g, 100, 0, 31, 26, 'fl', 1.0)
        elif k == 5: grp(g, medal(), 0, 0, 1.5)
        elif k == 6: g.add(laurel(7, 40)); grp(g, crown(True), 0, 0, 1.05)
        else:
            g.add(laurel(8, 41)); grp(g, crown(True), 0, 6, 0.9); grp(g, star(8), 0, -26, 0.9)
    return g

ROW_FRAMES = ['circle', 'hex', 'octagon', 'circle', 'hex', 'octagon']
