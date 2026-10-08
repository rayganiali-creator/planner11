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
    if n == 1: return o + f'<ellipse cx="0" cy="3" rx="6" ry="4" fill="{W}"/>'
    if n == 2: return o + stem(-4) + pair(-3, .55, -30)
    if n == 3: return o + stem(-14) + pair(-12, .85, -28)
    if n == 4: return o + stem(-24) + pair(-6, .85, -22) + pair(-22, .9, -32)
    if n == 5: return o + stem(-22) + pair(-4, .85, -22) + pair(-16, .9, -30) + f'<path d="M0,-44 C9,-36 9,-26 0,-20 C-9,-26 -9,-36 0,-44Z" fill="{W}"/>'
    def flower(cx, cy, r):
        p = ''.join(f'<ellipse cx="{cx}" cy="{cy-r*1.05}" rx="{r*.62}" ry="{r*.8}" fill="{W}" transform="rotate({a} {cx} {cy})"/>' for a in range(0, 360, 72))
        return p + f'<circle cx="{cx}" cy="{cy}" r="{r*.5}" fill="{Y}"/>'
    base = o + stem(-22) + pair(-2, .85, -22) + pair(-14, .8, -28)
    if n == 6: return base + flower(0, -32, 10)
    s7 = base + flower(0, -32, 10) + f'<path d="M0,2 C14,0 22,-4 24,-14" stroke="{W}" stroke-width="3.6" fill="none" stroke-linecap="round"/>' + flower(24, -20, 6.5)
    if n == 7: return s7
    return s7 + star(-30, -34, 7)

# ردیف ۲: خورشید و افق
def f(n, D):
    cy = {1: 42, 2: 36, 3: 26}.get(n, 4)
    hor = 26
    sun = f'<circle cx="0" cy="{cy}" r="19" fill="{Y}"/>'
    rays = ''
    if n >= 5:
        L = 31 if n == 5 else 36
        rays = ''.join(f'<path d="M0,-25 V-{L}" stroke="{Y}" stroke-width="4.4" stroke-linecap="round" transform="translate(0 {cy}) rotate({a})"/>' for a in range(-90, 91, 30)) if False else ''.join(f'<path d="M0,-25 V-{L}" stroke="{Y}" stroke-width="4.4" stroke-linecap="round" transform="translate(0 {cy}) rotate({a})"/>' for a in range(0, 360, 30))
    ring = f'<circle cx="0" cy="{cy}" r="43" fill="none" stroke="{W}" stroke-width="3"/>' if n >= 7 else ''
    cid = 'hz'
    out = f'<clipPath id="{cid}"><rect x="-60" y="-60" width="120" height="{60+hor}"/></clipPath><g clip-path="url(#{cid})">{ring}{rays}{sun}</g><path d="M-44,{hor+2} H44" stroke="{W}" stroke-width="4.4" stroke-linecap="round"/><path d="M-30,{hor+12} H30 M-16,{hor+22} H16" stroke="{W}" stroke-width="3" stroke-linecap="round" opacity=".7"/>'
    if n == 8: out += star(-34, -34, 7, W) + star(36, -22, 5, W)
    return out

# ردیف ۳: برجِ بلوک‌ها
def b(n, D):
    o = ''; h = 9.4; y = 44
    for k in range(n):
        w = 46 - k * 3
        y -= h
        o += f'<rect x="{-w/2}" y="{y}" width="{w}" height="{h}" rx="1.6" fill="{W}" stroke="{D}" stroke-width="2"/>'
    if n == 8: o += f'<path d="M0,{y} V{y-17}" stroke="{W}" stroke-width="3" stroke-linecap="round"/><path d="M0,{y-17} L15,{y-12} L0,{y-7}Z" fill="{Y}"/>'
    return o

# ردیف ۴: قفسه‌ی کتاب
def r(n, D):
    L, R = -34, 34
    planks = [-26, -2, 22, 44]
    o = f'<rect x="{L}" y="-26" width="3" height="70" fill="{W}"/><rect x="{R-3}" y="-26" width="3" height="70" fill="{W}"/>' + ''.join(f'<rect x="{L}" y="{p-2.4}" width="{R-L}" height="4.4" rx="1" fill="{W}"/>' for p in planks)
    hs = [17, 14, 18, 13, 16, 15]; ws = [8, 7, 9, 7, 8, 7]
    counts = {1: (1, 0, 0), 2: (3, 0, 0), 3: (6, 0, 0), 4: (6, 3, 0), 5: (6, 6, 0), 6: (6, 6, 3), 7: (6, 6, 6), 8: (6, 6, 6)}[n]
    for si, c in enumerate(counts):
        base = planks[si + 1] - 2.4; x = L + 6
        for k in range(c):
            o += f'<rect x="{x}" y="{base-hs[(k+si*2)%6]}" width="{ws[k]}" height="{hs[(k+si*2)%6]}" rx="1.2" fill="{W}" stroke="{D}" stroke-width="1.6"/>'
            x += ws[k] + 2.4
    if n == 8:
        o += f'<path d="M-9,-44 H9 L13,-30 H-13Z" fill="{Y}"/><rect x="-1.8" y="-30" width="3.6" height="5" fill="{W}"/><rect x="-9" y="-26" width="18" height="3.4" rx="1.4" fill="{W}"/>'
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
    o += f'<circle cx="{cx}" cy="{cy}" r="22" fill="{W}"/>'
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

SC = [1.5, 1.35, 1.5, 1.4, 1.25, 1.3]; SH = [8, -4, 4, 2, 0, -2]
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
