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

# ---- ردیف‌های ۲ تا ۴: سبکِ «نشان‌واره»ی باوقار، فرمِ سفید + برش‌های منفی (رنگِ صفحه) + تکیه‌ی زرد ----
def circ(x, y, r, fill=W, op=None): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"' + (f' opacity="{op}"' if op else '') + '/>'
def ln(x1, y1, x2, y2, w, c=W, op=None): return f'<path d="M{x1:.1f},{y1:.1f} L{x2:.1f},{y2:.1f}" stroke="{c}" stroke-width="{w:.1f}" stroke-linecap="round"' + (f' stroke-opacity="{op}"' if op else '') + '/>'
def rec(x, y, ang, L, w, depth, spread, shrink, out, tips):
    x2 = x + L * math.sin(ang); y2 = y - L * math.cos(ang)
    out.append((x, y, x2, y2, w))
    if depth == 0: tips.append((x2, y2)); return
    rec(x2, y2, ang - spread, L * shrink, w * .68, depth - 1, spread, shrink, out, tips)
    rec(x2, y2, ang + spread, L * shrink, w * .68, depth - 1, spread, shrink, out, tips)

# ردیف ۲: خورشید و افق
def f(n, D):
    cy = {1: 42, 2: 36, 3: 26}.get(n, 4)
    hor = 26
    sun = f'<circle cx="0" cy="{cy}" r="19" fill="{Y}"/>'
    rays = ''
    if n >= 5:
        L = 31 if n == 5 else 36
        rays = ''.join(f'<path d="M0,-25 V-{L}" stroke="{Y}" stroke-width="4.4" stroke-linecap="round" transform="translate(0 {cy}) rotate({a})"/>' for a in range(-90, 91, 30)) if False else ''.join(f'<path d="M0,-25 V-{L}" stroke="{Y}" stroke-width="4.4" stroke-linecap="round" transform="translate(0 {cy}) rotate({a})"/>' for a in range(0, 360, 30))
    ring = f'<circle cx="0" cy="{cy}" r="43" fill="none" stroke="{W}" stroke-width="3"/>' if n == 7 else (f'<circle cx="0" cy="{cy}" r="42" fill="none" stroke="{W}" stroke-width="3"/><circle cx="0" cy="{cy}" r="49" fill="none" stroke="{W}" stroke-width="2" stroke-dasharray="1 6" stroke-linecap="round"/>' if n == 8 else '')
    cid = 'hz'
    out = f'<clipPath id="{cid}"><rect x="-60" y="-60" width="120" height="{60+hor}"/></clipPath><g clip-path="url(#{cid})">{ring}{rays}{sun}</g><path d="M-44,{hor+2} H44" stroke="{W}" stroke-width="4.4" stroke-linecap="round"/><path d="M-30,{hor+12} H30 M-16,{hor+22} H16" stroke="{W}" stroke-width="3" stroke-linecap="round" opacity=".7"/>'
    if n == 8: out += star(-36, -30, 9, Y) + star(38, -34, 6.5, Y) + star(0, -50, 7.5, W)
    return out

# ردیف ۳: پله‌ها (هر نشان یک پله‌ی بیشتر + آدمکِ بالای پله)
def b(n, D):
    sw, sh, x0, base = 10, 8.5, -40, 32
    o = ''
    for k in range(1, 9):
        x = x0 + (k - 1) * sw; hh = k * sh
        if k <= n: o += f'<rect x="{x}" y="{base-hh}" width="{sw}" height="{hh}" fill="{W}" stroke="{D}" stroke-width="1.8"/>'
        else: o += f'<rect x="{x}" y="{base-hh}" width="{sw}" height="{hh}" fill="{W}" opacity=".22"/>'
    cx = x0 + (n - 1) * sw + sw / 2; top = base - n * sh
    if n < 8:
        o += f'<circle cx="{cx}" cy="{top-13}" r="5.4" fill="{Y}"/><path d="M{cx},{top-6} V{top-1}" stroke="{Y}" stroke-width="4.6" stroke-linecap="round"/>'
    else:
        o += f'<path d="M{cx},{top} V{top-17}" stroke="{Y}" stroke-width="3" stroke-linecap="round"/><path d="M{cx},{top-17} L{cx+12},{top-13} L{cx},{top-9}Z" fill="{Y}"/>'
    if n >= 7: o += star(-28, -30, 7, Y)
    if n == 8: o += star(-10, -40, 5, W) + star(-38, -12, 4.5, W)
    return o

# ردیف ۴: تخم ← جغدِ افسانه‌ای
def r(n, D):
    def eye(x, y, rr, lid=False):
        e = f'<circle cx="{x}" cy="{y}" r="{rr}" fill="{D}"/><circle cx="{x}" cy="{y}" r="{rr*.66}" fill="{Y}"/><circle cx="{x}" cy="{y}" r="{rr*.34}" fill="{D}"/><circle cx="{x+rr*.2}" cy="{y-rr*.2}" r="{rr*.13}" fill="{W}"/>'
        if lid: e += f'<path d="M{x-rr-1},{y-rr*.1} Q{x},{y-rr*1.5} {x+rr+1},{y-rr*.1}Z" fill="{W}"/>'
        return e
    def beak(y, s=1): return f'<path d="M-4.5,{y} L4.5,{y} L0,{y+8*s}Z" fill="{Y}"/>'
    def feet(y): return f'<path d="M-9,{y} v7 M-13,{y+7} l4,-1 M-5,{y+7} l-4,-1 M9,{y} v7 M13,{y+7} l-4,-1 M5,{y+7} l4,-1" stroke="{Y}" stroke-width="2.8" stroke-linecap="round" fill="none"/>'
    def chev(y0, rows, w=8):
        return ''.join(f'<path d="M{x-w/2},{y} l{w/2},{w*.6} l{w/2},{-w*.6}" stroke="{D}" stroke-width="2.2" stroke-opacity=".42" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' for i in range(rows) for y in [y0 + i * 9] for x in (-9, 0, 9) if abs(x) <= 9 - i * 0)
    body = lambda rx, ry, cy: f'<path d="M0,{cy-ry} C{rx*.7},{cy-ry} {rx},{cy-ry*.5} {rx},{cy} C{rx},{cy+ry*.7} {rx*.6},{cy+ry} 0,{cy+ry} C{-rx*.6},{cy+ry} {-rx},{cy+ry*.7} {-rx},{cy} C{-rx},{cy-ry*.5} {-rx*.7},{cy-ry} 0,{cy-ry}Z" fill="{W}"/>'
    if n == 1:
        return f'<path d="M0,-34 C17,-34 25,-12 25,6 C25,24 14,36 0,36 C-14,36 -25,24 -25,6 C-25,-12 -17,-34 0,-34Z" fill="{W}"/>' + f'<path d="M-25,8 Q-12,2 0,8 T25,8" stroke="{D}" stroke-width="2.4" stroke-opacity=".28" fill="none"/><path d="M-20,-8 Q-10,-14 0,-10 T20,-8" stroke="{D}" stroke-width="2.4" stroke-opacity=".28" fill="none"/>' + f'<path d="M-14,-18 Q-12,-27 -5,-30" stroke="{D}" stroke-opacity=".22" stroke-width="3" fill="none" stroke-linecap="round"/>'
    if n == 2:
        return (f'<g transform="translate(-2 -6) rotate(-9 0 0)"><path d="M-25,2 C-25,-18 -14,-34 0,-34 C14,-34 25,-18 25,2 L15,-6 L7,5 L-1,-7 L-9,4Z" fill="{W}"/></g>'
                f'<path d="M-25,4 L-15,-4 L-7,7 L1,-5 L9,5 L15,-4 L25,4 C25,24 14,36 0,36 C-14,36 -25,24 -25,4Z" fill="{W}"/><path d="M-6,22 Q0,26 6,22" stroke="{D}" stroke-opacity=".3" stroke-width="2.2" fill="none"/>' + star(28, -30, 5, Y) + star(-30, -28, 4, Y))
    if n == 3:
        return (f'<path d="M-27,12 L-19,4 L-10,14 L0,4 L10,14 L19,4 L27,12 C27,30 15,40 0,40 C-15,40 -27,30 -27,12Z" fill="{W}"/>'
                f'<path d="M0,-30 C14,-30 20,-18 20,-6 C20,6 12,14 0,14 C-12,14 -20,6 -20,-6 C-20,-18 -14,-30 0,-30Z" fill="{W}"/><path d="M-15,-24 L-19,-34 L-8,-28Z M15,-24 L19,-34 L8,-28Z" fill="{W}"/>' + eye(-8, -8, 7, True) + eye(8, -8, 7, True) + beak(0, .9))
    cy = 6
    if n == 4:
        o = body(25, 30, cy) + f'<path d="M-17,-18 L-21,-33 L-7,-24Z M17,-18 L21,-33 L7,-24Z" fill="{W}"/>' + eye(-10, -6, 9.4) + eye(10, -6, 9.4) + beak(5, 1) + chev(14, 3, 8) + feet(33)
        return o
    wing = f'<path d="M-25,0 C-33,14 -29,32 -16,36 L-14,-6Z M25,0 C33,14 29,32 16,36 L14,-6Z" fill="{W}" stroke="{D}" stroke-width="1.8" stroke-opacity=".55"/>'
    if n == 5:
        return wing + body(24, 32, cy) + f'<path d="M-19,-20 L-24,-38 L-7,-27Z M19,-20 L24,-38 L7,-27Z" fill="{W}"/>' + f'<path d="M-24,-14 L-5,-6 M24,-14 L5,-6" stroke="{D}" stroke-width="3" stroke-linecap="round"/>' + eye(-10, -6, 9) + eye(10, -6, 9) + beak(6, 1.05) + chev(16, 3, 8) + feet(34)
    o = ''
    if n == 8:
        o += circ(0, -2, 55, Y, .2)
        for sg in (-1, 1):
            for i in range(5):
                a = sg * (62 + i * 14); L = 38 - i * 3
                o += f'<g transform="translate({sg*18} -4) rotate({a} 0 0)"><rect x="-4" y="{-L}" width="8" height="{L}" rx="4" fill="{W}"/></g>'
    elif n >= 6: o += wing
    o += body(24, 33, cy) + f'<path d="M-19,-22 L-25,-41 L-7,-29Z M19,-22 L25,-41 L7,-29Z" fill="{W}"/>' + f'<path d="M-25,-15 L-5,-6 M25,-15 L5,-6" stroke="{D}" stroke-width="3.2" stroke-linecap="round"/>'
    o += eye(-10, -6, 10) + eye(10, -6, 10) + beak(6, 1.1) + chev(17, 3, 8)
    o += f'<path d="M-32,40 H32" stroke="{W}" stroke-width="4" stroke-linecap="round"/>' + feet(35)
    if n == 7:
        o += f'<path d="M30,-30 a15,15 0 1 0 14,-14 a11,11 0 1 1 -14,14Z" fill="{Y}"/>' + star(-38, -30, 6, Y) + star(-34, -10, 4, W)
    if n == 8: o += f'<path d="M-12,-44 L-15,-56 L-6,-50 L0,-60 L6,-50 L15,-56 L12,-44Z" fill="{Y}"/>' + star(-50, -30, 6, Y) + star(50, -30, 5, W)
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

SC = [1.5, 1.35, 1.2, 1.2, 1.25, 1.3]; SH = [8, -4, 4, 2, 0, -2]
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
