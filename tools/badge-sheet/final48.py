# ساخت شیتِ ۴۸ نشانِ «تصویرسازیِ مینیمالِ برجسته» + SVGِ تک‌تکِ نشان‌ها (برای PNGِ اپ).
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); os.environ['MOTIFS'] = 'none'
import make_sheet as m
import illustrated as i1, illustrated2 as i2, illustrated3 as i3, illustrated4 as i4
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'premium3d.py')).read().split("def render")[0])  # mat, EXTRA

A = {**{'candle': i1.candle, 'lantern': i1.lantern, 'owl': i1.owl}, **i2.ICONS2, **i3.ICONS3, **i4.ICONS4, 'campfire': i1.campfire, 'sun': i1.sun, 'trophy': i1.trophy}
ORDER = ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'tree',
         'match', 'candle', 'lantern', 'campfire', 'torch', 'lamp', 'lighthouse', 'sun',
         'b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8',
         'r1', 'book_ribbon', 'r3', 'r4', 'r5', 'shelf', 'r7', 'r8',
         'm1', 'm2', 'm3', 'm4', 'm5', 'm6', 'summit', 'summit_glory',
         'stone', 'gem', 'medal', 'podium', 'trophy', 'crown', 'wcrown', 'laurel']
ROWD = ['#13295E', '#3A2A82', '#0F5A43', '#5C1830', '#4A2A14', '#1C1E55']
m.ROWS[4] = ('#9A6A40', '#4A2A14', '#FFD36A', '#FFE9A8')
m.TIERS = list(m.TIERS)
for i in range(1, 49): m.FRAMES[i] = 'circle'

def badge_group(i):
    r = (i - 1) // 8
    g = m.G(); g.add(i1.DEFS); g.add(EXTRA)
    g.add(f'<g filter="url(#bev)"><g transform="scale(1.12)">{mat(A[ORDER[i - 1]](), ROWD[r])}</g></g>')
    m.motif = lambda _i, g=g: g
    return m.badge_svg(i, f'b{i}')

def sheet(path):
    cols, rows, cell, margin, size = 8, 6, 250, 70, 205
    W = margin * 2 + cols * cell; H = margin * 2 + rows * cell
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{m.SHARED_DEFS}<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6F4EF"/><stop offset="1" stop-color="#EEEBE4"/></linearGradient></defs><rect width="{W}" height="{H}" fill="url(#bg)"/><style>']
    for i in range(1, 49): out.append(m.symbol_style(i, f'b{i}'))
    out.append('</style>')
    for i in range(1, 49):
        r, c = divmod(i - 1, 8)
        out.append(f'<g transform="translate({margin + c * cell + cell / 2} {margin + r * cell + cell / 2}) scale({size / 200})">{badge_group(i)}</g>')
    out.append('</svg>'); open(path, 'w').write('\n'.join(out)); return W, H

def single(i):
    VB = -118 if i % 8 == 0 else -100
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{VB} {VB} {-2 * VB} {-2 * VB}" width="400" height="400"><defs>{m.SHARED_DEFS}</defs><style>{m.symbol_style(i, f"b{i}")}</style>{badge_group(i)}</svg>')

if __name__ == '__main__':
    from playwright.sync_api import sync_playwright
    os.makedirs('out/final', exist_ok=True)
    W, H = sheet('out/sheet-final.svg')
    for i in range(1, 49): open(f'out/final/badge_{i:02d}.svg', 'w').write(single(i))
    with sync_playwright() as pw:
        b = pw.chromium.launch(executable_path='/opt/pw-browsers/chromium-1194/chrome-linux/chrome'); pg = b.new_page(viewport={'width': W, 'height': H}, device_scale_factor=1.5)
        pg.goto('file://' + os.path.abspath('out/sheet-final.svg')); pg.wait_for_timeout(500); pg.screenshot(path='out/sheet-final.png'); b.close()
    print('ok')
