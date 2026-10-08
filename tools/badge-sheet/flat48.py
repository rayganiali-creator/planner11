# ۴۸ نشان به سبک تخت (flat) با سیر پیشرفتِ منطقی: هر ردیف یک شیء ثابت، و هر نشان = قبلی + یک عنصر جدید.
import math, os, sys
W = '#FFFFFF'; Y = '#FFD23F'
ROWS = [('#10A898', '#0A7F73', 'رشد'), ('#6A4A8C', '#4B3166', 'تمرکز'), ('#8EA335', '#667725', 'ساخت'), ('#B5107E', '#850B5C', 'مطالعه'), ('#F26122', '#C0480F', 'صعود'), ('#24527F', '#173A5C', 'تسلط')]
RIMS = ['#B87333', '#B87333', '#C3C7CF', '#C3C7CF', '#D8B13A', '#D8B13A', '#D8B13A', '#D8B13A']

def star(cx, cy, r, fill=Y):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5; rr = r if k % 2 == 0 else r * .45
        pts.append(f'{cx + rr * math.cos(a):.1f},{cy + rr * math.sin(a):.1f}')
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke-linejoin="round"/>'
def leaf(x, y, ang, s=1, fill=W):
    return f'<g transform="translate({x} {y}) rotate({ang})"><ellipse cx="{11*s}" cy="0" rx="{11*s}" ry="{5.2*s}" fill="{fill}"/></g>'

# ردیف ۱: گلدان
def g(n, D):
    o = f'<path d="M-17,16 H17 L12,44 H-12Z" fill="{W}"/><rect x="-21" y="10" width="42" height="9" rx="2.5" fill="{W}"/>'
    def stem(top): return f'<path d="M0,10 V{top}" stroke="{W}" stroke-width="4.4" stroke-linecap="round"/>'
    def pair(y, s, up=-28):
        return leaf(0, y, up, s) + leaf(0, y, 180 - up, s)
    if n == 1: return o + f'<ellipse cx="0" cy="-4" rx="11" ry="7.5" fill="{W}" transform="rotate(-18 0 -4)"/><path d="M-6,-6 Q0,-11 7,-8" stroke="{D}" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
    if n == 2: return o + stem(-4) + pair(-3, .55, -30)
    if n == 3: return o + stem(-14) + pair(-12, .85, -28)
    if n == 4: return o + stem(-24) + pair(-6, .85, -22) + pair(-22, .9, -32)
    if n == 5: return o + stem(-22) + pair(-4, .85, -22) + pair(-16, .9, -30) + f'<path d="M0,-44 C9,-36 9,-26 0,-20 C-9,-26 -9,-36 0,-44Z" fill="{W}"/>'
    def flower(cx, cy, r):
        p = ''.join(f'<ellipse cx="{cx}" cy="{cy-r*1.05}" rx="{r*.62}" ry="{r*.8}" fill="{W}" transform="rotate({a} {cx} {cy})"/>' for a in range(0, 360, 72))
        return p + f'<circle cx="{cx}" cy="{cy}" r="{r*.5}" fill="{Y}"/>'
    base = o + stem(-22) + pair(-2, .85, -22) + pair(-14, .8, -28)
    if n == 6: return base + flower(0, -32, 10)
    def side(sg, r=7):
        return f'<path d="M0,10 C{sg*4},-2 {sg*18},0 {sg*22},-14" stroke="{W}" stroke-width="3.6" fill="none" stroke-linecap="round"/>' + flower(sg * 22, -22, r)
    if n == 7: return base + flower(0, -32, 10) + side(1)
    return base + flower(0, -32, 10) + side(1) + side(-1) + star(0, -52, 7)

# ردیف ۲: بذر ← درخت تنومند
def circ(x, y, r, fill=W): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"/>'
def f(n, D):
    o = f'<path d="M-42,40 Q0,26 42,40Z" fill="{W}"/>'
    def stem(top, w): return f'<path d="M0,34 V{top}" stroke="{W}" stroke-width="{w}" stroke-linecap="round"/>'
    if n == 1: return o + f'<ellipse cx="0" cy="25" rx="10" ry="6.5" fill="{W}" transform="rotate(-18 0 25)"/><path d="M-3,22 Q1,25 4,23" stroke="{D}" stroke-width="2" fill="none" stroke-linecap="round"/>' + star(0, 4, 5, Y)
    if n == 2: return o + stem(10, 4) + leaf(0, 12, -35, .85) + leaf(0, 12, 215, .85)
    if n == 3: return o + stem(-8, 4.6) + leaf(0, 16, -30, .85) + leaf(0, 16, 210, .85) + leaf(0, 3, -35, .95) + leaf(0, 3, 215, .95) + leaf(0, -8, -60, .8) + leaf(0, -8, 240, .8)
    crown = {4: [(0, -16, 15), (-12, -6, 11), (12, -6, 11)],
             5: [(0, -26, 18), (-17, -12, 14), (17, -12, 14), (0, -8, 14)],
             6: [(0, -34, 21), (-24, -18, 17), (24, -18, 17), (-10, -8, 14), (10, -8, 14), (-33, -4, 9), (33, -4, 9)],
             7: [(0, -36, 22), (-25, -19, 18), (25, -19, 18), (-10, -8, 15), (10, -8, 15), (-34, -3, 10), (34, -3, 10)],
             8: [(0, -38, 23), (-26, -20, 18), (26, -20, 18), (-12, -8, 15), (12, -8, 15), (-30, -2, 11), (30, -2, 11)]}[n]
    c = ''.join(circ(*k) for k in crown)
    if n == 8: c = circ(0, -18, 50, Y).replace('fill="%s"' % Y, f'fill="{Y}" opacity=".25"') + c
    if n == 4: trunk = f'<path d="M0,34 V-4" stroke="{W}" stroke-width="9" stroke-linecap="round"/>'
    elif n == 5: trunk = f'<path d="M-9,38 C-6,18 -5,6 -6,-8 L6,-8 C5,6 6,18 9,38Z" fill="{W}"/>'
    else:
        wd = 14 if n >= 7 else 12
        trunk = f'<path d="M-{wd+6},40 C-{wd-2},24 -{wd//2},8 -{wd//2+1},-10 L{wd//2+1},-10 C{wd//2},8 {wd-2},24 {wd+6},40Z" fill="{W}"/>'
    det = ''
    if n >= 6:
        det = f'<path d="M0,-4 L-14,-18 M0,-4 L14,-18 M0,-14 V-30" stroke="{D}" stroke-width="2.2" stroke-opacity=".4" fill="none" stroke-linecap="round"/>'
    fr = ''
    if n >= 7:
        pts = [(-14, -24), (10, -30), (20, -14), (-24, -12), (2, -14)] + ([(-6, -44), (28, -26), (-32, -2)] if n == 8 else [])
        fr = ''.join(circ(x, y, 3.6, Y) for x, y in pts)
    roots = ''
    if n >= 7:
        roots = f'<path d="M-5,40 C-8,46 -14,48 -20,52 M5,40 C8,46 14,48 20,52 M0,40 V54" stroke="{W}" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
    out = o + roots + c + trunk + det + fr
    if n == 8: out += star(-40, -42, 6.5, Y) + star(42, -40, 5, W)
    return out

# ردیف ۳: بچه‌شیر ← شیرِ افسانه‌ای
def spikes(N, Ro, Ri, fill, rot=0, cy=0):
    pts = ' '.join(f'{(Ro if k % 2 == 0 else Ri) * math.cos(rot + k * math.pi / N):.1f},{cy + (Ro if k % 2 == 0 else Ri) * math.sin(rot + k * math.pi / N):.1f}' for k in range(2 * N))
    return f'<polygon points="{pts}" fill="{fill}" stroke-linejoin="round" stroke="{fill}" stroke-width="3"/>'
def b(n, D):
    R = 20; cy = 4
    o = ''
    if n == 8: o += circ(0, cy, 52, Y).replace(f'fill="{Y}"', f'fill="{Y}" opacity=".22"')
    if n >= 8: o += spikes(16, R + 31, R + 21, '#FF9A1F', math.pi / 16, cy)
    if n >= 6: o += spikes(14, R + 25, R + 16, '#FFB020', 0, cy)
    if n >= 2: o += spikes({2: 12, 3: 10, 4: 12, 5: 12}.get(n, 12), R + {2: 7, 3: 11, 4: 15, 5: 19}.get(n, 18), R + {2: 2, 3: 4, 4: 7, 5: 9}.get(n, 10), Y, math.pi / 12, cy)
    ex = R * .78
    o += circ(-ex, cy - R * .74, R * .3) + circ(ex, cy - R * .74, R * .3) + circ(-ex, cy - R * .74, R * .15, D).replace('/>', ' opacity=".45"/>') + circ(ex, cy - R * .74, R * .15, D).replace('/>', ' opacity=".45"/>')
    o += circ(0, cy, R)
    er = R * (.2 if n <= 2 else .15)
    o += circ(-R * .4, cy - R * .08, er, D) + circ(R * .4, cy - R * .08, er, D) + circ(-R * .4 + er * .35, cy - R * .08 - er * .35, er * .35) + circ(R * .4 + er * .35, cy - R * .08 - er * .35, er * .35)
    o += f'<ellipse cx="0" cy="{cy + R * .4}" rx="{R * .46}" ry="{R * .32}" fill="#F4E4B8"/><path d="M{-R*.14},{cy+R*.2} h{R*.28} l{-R*.14},{R*.15}Z" fill="{D}"/><path d="M0,{cy+R*.35} v{R*.1} M0,{cy+R*.45} q{-R*.14},{R*.14} {-R*.26},{R*.02} M0,{cy+R*.45} q{R*.14},{R*.14} {R*.26},{R*.02}" stroke="{D}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
    o += f'<path d="M0,{cy-R*.35} V{cy+R*.2}" stroke="{D}" stroke-width="2" stroke-opacity=".35" stroke-linecap="round"/>'
    if n == 1: o += f'<path d="M-5,{cy-R-1} q-2,-9 4,-11 M0,{cy-R-1} q1,-11 8,-10 M4,{cy-R} q6,-6 10,-1" stroke="{Y}" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
    if n >= 7:
        ty = cy - R - 6
        o += f'<g transform="translate(0 {ty})"><path d="M-13,6 L-15,-9 L-7,-3 L0,-13 L7,-3 L15,-9 L13,6Z" fill="{W}" stroke="{D}" stroke-width="1.8" stroke-linejoin="round"/><circle cx="0" cy="-1" r="2.4" fill="{Y}"/><circle cx="-8" cy="1" r="1.8" fill="{Y}"/><circle cx="8" cy="1" r="1.8" fill="{Y}"/></g>'
    if n == 8: o += star(-48, -34, 7, Y) + star(48, -30, 6, W) + star(46, 36, 5, Y)
    return o

# ردیف ۴: تخم ← جغدِ افسانه‌ای
def r(n, D):
    def eye(x, y, rr, rim=D, fill=W, pupil=D):
        return f'<circle cx="{x}" cy="{y}" r="{rr}" fill="{fill}" stroke="{rim}" stroke-width="2.4"/><circle cx="{x}" cy="{y+rr*.1}" r="{rr*.5}" fill="{pupil}"/><circle cx="{x+rr*.2}" cy="{y-rr*.15}" r="{rr*.17}" fill="{W}"/>'
    def beak(x, y, s=1): return f'<path d="M{x-4*s},{y} L{x+4*s},{y} L{x},{y+7*s}Z" fill="{Y}"/>'
    def feet(y, s=1): return f'<path d="M-9,{y} v6 M-12,{y+6} h6 M9,{y} v6 M6,{y+6} h6" stroke="{Y}" stroke-width="3" stroke-linecap="round" fill="none"/>'
    def belly(cy, w, h):
        return ''.join(f'<path d="M{x-5},{y} q5,6 10,0" stroke="{D}" stroke-width="2" stroke-opacity=".38" fill="none" stroke-linecap="round"/>' for y in (cy, cy + 9, cy + 18) for x in ((-w / 2, w / 2) if False else (-10, 0, 10)))
    if n == 1:
        return f'<ellipse cx="0" cy="6" rx="23" ry="30" fill="{W}"/>' + ''.join(f'<ellipse cx="{x}" cy="{y}" rx="3.2" ry="2.4" fill="{D}" fill-opacity=".3"/>' for x, y in ((-9, 0), (8, 14), (-4, 20), (10, -8))) + f'<path d="M-14,-10 Q-12,-20 -4,-24" stroke="{D}" stroke-opacity=".25" stroke-width="3" fill="none" stroke-linecap="round"/>'
    if n == 2:
        return (f'<g transform="translate(-1 -5) rotate(-7 0 -8)"><path d="M-22,-4 C-22,-22 -10,-36 0,-36 C10,-36 22,-22 22,-4 L13,-12 L6,-3 L-2,-13 L-9,-4Z" fill="{W}"/></g>'
                + f'<path d="M-22,0 L-13,-8 L-6,1 L2,-9 L9,0 L13,-8 L22,0 C22,18 12,36 0,36 C-12,36 -22,18 -22,0Z" fill="{W}"/>'
                + f'<circle cx="0" cy="0" r="1.2" fill="{D}"/>' + star(24, -30, 5, Y) + star(-26, -26, 4, Y))
    if n == 3:
        return (f'<path d="M-26,10 L-17,2 L-9,12 L0,2 L9,12 L17,2 L26,10 C26,28 14,40 0,40 C-14,40 -26,28 -26,10Z" fill="{W}"/>'
                + f'<circle cx="0" cy="-6" r="19" fill="{W}"/><path d="M-12,-22 L-9,-30 L-3,-24Z M12,-22 L9,-30 L3,-24Z" fill="{W}"/>' + eye(-8, -6, 7.2) + eye(8, -6, 7.2) + beak(0, 3, .9)
                + f'<path d="M-22,22 L-14,16 L-6,24 L2,16" stroke="{D}" stroke-opacity=".35" stroke-width="2" fill="none"/>')
    if n == 4:
        return (f'<ellipse cx="0" cy="8" rx="25" ry="27" fill="{W}"/><path d="M-17,-14 L-14,-26 L-6,-17Z M17,-14 L14,-26 L6,-17Z" fill="{W}"/>' + eye(-10, -2, 9) + eye(10, -2, 9) + beak(0, 8, 1)
                + belly(18, 20, 10) + feet(33, .9))
    if n == 5:
        return (f'<path d="M-24,10 C-30,24 -22,34 -12,34 L-12,-4 C-20,0 -26,4 -24,10Z M24,10 C30,24 22,34 12,34 L12,-4 C20,0 26,4 24,10Z" fill="{W}" stroke="{D}" stroke-width="1.8" stroke-opacity=".5"/>'
                + f'<ellipse cx="0" cy="6" rx="23" ry="30" fill="{W}"/><path d="M-20,-18 L-22,-34 L-9,-24Z M20,-18 L22,-34 L9,-24Z" fill="{W}"/>' + eye(-10, -8, 9.4) + eye(10, -8, 9.4) + beak(0, 3, 1.05)
                + belly(14, 20, 10) + feet(33, 1))
    # ۶-۸: جغدِ بالغ روی شاخه
    o = ''
    if n == 8:
        o += circ(0, -2, 52, Y).replace(f'fill="{Y}"', f'fill="{Y}" opacity=".22"')
        for sg in (-1, 1):
            o += ''.join(f'<path d="M{sg*20},{8-i*0} C{sg*(34+i*5)},{-4+i*13} {sg*(46)},{4+i*12} {sg*(50-i*4)},{22+i*7}" stroke="{W}" stroke-width="7" stroke-linecap="round" fill="none"/>' for i in range(3))
    wings = f'<path d="M-24,2 C-32,18 -26,36 -13,38 L-12,-8 C-20,-6 -24,-2 -24,2Z M24,2 C32,18 26,36 13,38 L12,-8 C20,-6 24,-2 24,2Z" fill="{W}" stroke="{D}" stroke-width="2" stroke-opacity=".5"/>' if n < 8 else ''
    o += wings + f'<ellipse cx="0" cy="4" rx="24" ry="32" fill="{W}"/><path d="M-21,-20 L-24,-38 L-9,-27Z M21,-20 L24,-38 L9,-27Z" fill="{W}"/>'
    ec = Y if n == 8 else D
    o += eye(-10, -8, 10.4, ec) + eye(10, -8, 10.4, ec) + beak(0, 3, 1.1) + belly(14, 20, 10)
    o += f'<path d="M-30,38 H30" stroke="{W}" stroke-width="4.6" stroke-linecap="round"/>' + feet(33, 1)
    if n >= 7:
        o += f'<path d="M30,-34 a14,14 0 1 0 12,-12 a10,10 0 1 1 -12,12Z" fill="{Y}"/>' if n == 7 else ''
        if n == 7: o += star(-38, -30, 6, Y) + star(-32, -8, 4, W)
    if n == 8:
        o += f'<g transform="translate(0 -40)"><path d="M-13,6 L-15,-9 L-7,-3 L0,-13 L7,-3 L15,-9 L13,6Z" fill="{Y}" stroke="{D}" stroke-width="1.8" stroke-linejoin="round"/></g>' + star(-46, -34, 7, Y) + star(46, -32, 6, W) + star(-44, 14, 4.5, W)
    return o

# ردیف ۵: کوه و مسیر زیگزاگ
WPS = [(0, 34), (-15, 22), (13, 8), (-9, -8), (6, -20), (0, -31)]
def m(n, D):
    o = f'<path d="M-46,38 L0,-34 L46,38Z" fill="{W}"/>' + f'<path d="M0,34 L-15,22 L13,8 L-9,-8 L6,-20 L0,-31" stroke="{D}" stroke-width="3" fill="none" stroke-linejoin="round" stroke-linecap="round" stroke-dasharray="1 7"/>'
    if n >= 7: o = f'<circle cx="30" cy="-24" r="11" fill="{Y}"/>' + o
    idx = min(n, 6) - 1; x, yy = WPS[idx]
    o += f'<path d="M{x},{yy} V{yy-17}" stroke="{Y}" stroke-width="3" stroke-linecap="round"/><path d="M{x},{yy-17} L{x+13},{yy-12} L{x},{yy-7}Z" fill="{Y}"/>'
    if n == 8: o += star(-30, -26, 6, Y) + star(34, 4, 4.5, Y) + star(-22, -4, 3.6, W)
    return o

# ردیف ۶: مدال
def s(n, D):
    cx, cy = 0, 8
    o = f'<path d="M-13,28 L-19,50 L-9,44 L-3,50 L2,30Z M13,28 L19,50 L9,44 L3,50 L-2,30Z" fill="{Y}"/>'
    if n >= 7: o = f'<circle cx="0" cy="{cy}" r="38" fill="none" stroke="{W}" stroke-width="2.6" stroke-dasharray="2 5" stroke-linecap="round"/>' + o
    if n >= 5:
        for sg in (-1, 1):
            o += ''.join(f'<path d="M{sg*28},{cy+4-i*6} C{sg*36},{cy+2-i*6-4} {sg*44},{cy-i*6-10} {sg*46},{cy-i*6-16}" stroke="{W}" stroke-width="4" fill="none" stroke-linecap="round"/>' for i in range(3))
    o += (f'<circle cx="{cx}" cy="{cy}" r="19" fill="none" stroke="{W}" stroke-width="5"/>' if n == 1 else f'<circle cx="{cx}" cy="{cy}" r="22" fill="{W}"/>')
    if n >= 3:
        o += ''.join(f'<ellipse cx="{sg*(27)*math.cos(math.radians(a))}" cy="{cy+27*math.sin(math.radians(a))}" rx="5" ry="2.6" fill="{W}" transform="rotate({sg*(a+90)*1 if sg==1 else -(a+90)+180} {sg*(27)*math.cos(math.radians(a))} {cy+27*math.sin(math.radians(a))})"/>' for sg in (-1, 1) for a in (60, 20, -20, -60)) if False else ''
    if n >= 3:
        for sg in (-1, 1):
            for a in (70, 40, 10, -20, -50):
                px = sg * 29 * math.cos(math.radians(a)); py = cy + 29 * math.sin(math.radians(a))
                o += f'<ellipse cx="{px:.1f}" cy="{py:.1f}" rx="5.2" ry="2.5" fill="{Y}" transform="rotate({(-a-90)*sg+90 if False else sg*(a)+0} {px:.1f} {py:.1f})"/>'
    if n >= 2: o += star(cx, cy, 13, D if n < 4 else D)
    if n >= 4: o += f'<polygon points="{cx},{cy-6} {cx+5},{cy} {cx},{cy+7} {cx-5},{cy}" fill="{Y}"/>'
    if n >= 6: o += f'<path d="M-15,-20 L-18,-36 L-8,-28 L0,-40 L8,-28 L18,-36 L15,-20Z" fill="{Y}"/><rect x="-15" y="-21" width="30" height="4" rx="1.5" fill="{Y}"/>'
    if n == 8: o += star(-40, -30, 6, Y) + star(40, -30, 6, Y)
    return o

SC = [1.5, 1.4, 1.35, 1.3, 1.25, 1.3]; SH = [8, 4, 0, 2, 0, -2]
FN = [g, f, b, r, m, s]
def badge(i, idprefix=''):
    row, col = divmod(i - 1, 8); D, DK, _ = ROWS[row]; rim = RIMS[col]
    extra = ''
    if col >= 6: extra += f'<circle r="90" fill="none" stroke="{W}" stroke-width="2.4"/>'
    if col == 7: extra += ''.join(f'<circle cx="{93*math.cos(math.radians(a)):.1f}" cy="{93*math.sin(math.radians(a)):.1f}" r="2.2" fill="{W}"/>' for a in range(0, 360, 30))
    glyph = FN[row](col + 1, D).replace('id="hz"', f'id="{idprefix}hz"').replace('url(#hz)', f'url(#{idprefix}hz)')
    return (f'<circle r="98" fill="{rim}"/><circle r="89" fill="{DK}" opacity=".35"/><circle r="84" fill="{D}"/><circle r="84" fill="none" stroke="{DK}" stroke-width="2.4"/>' + extra
            + f'<g transform="translate(0 {SH[row]}) scale({SC[row]})">{glyph}</g>')

def single(i): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-100 -100 200 200" width="400" height="400">{badge(i)}</svg>'
def sheet(path):
    cols, rows, cell, margin, size = 8, 6, 250, 70, 205
    Wd = margin * 2 + cols * cell; H = margin * 2 + rows * cell
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{Wd}" height="{H}" viewBox="0 0 {Wd} {H}"><rect width="{Wd}" height="{H}" fill="#F5F5F5"/>']
    for i in range(1, 49):
        r_, c = divmod(i - 1, 8)
        out.append(f'<g transform="translate({margin + c * cell + cell / 2} {margin + r_ * cell + cell / 2}) scale({size / 200})">{badge(i, f"b{i}")}</g>')
    out.append('</svg>'); open(path, 'w').write('\n'.join(out)); return Wd, H

if __name__ == '__main__':
    from playwright.sync_api import sync_playwright
    os.makedirs('out/flat', exist_ok=True)
    Wd, H = sheet('out/sheet-flat.svg')
    for i in range(1, 49): open(f'out/flat/badge_{i:02d}.svg', 'w').write(single(i))
    with sync_playwright() as pw:
        br = pw.chromium.launch(executable_path='/opt/pw-browsers/chromium-1194/chrome-linux/chrome'); pg = br.new_page(viewport={'width': Wd, 'height': H}, device_scale_factor=1.2)
        pg.goto('file://' + os.path.abspath('out/sheet-flat.svg')); pg.wait_for_timeout(300); pg.screenshot(path='out/sheet-flat.png'); br.close()
    print('ok')
