# دستهٔ چهارم: «مسیر پیشرفت» — هر ردیف یک شیء که مرحله‌به‌مرحله رشد می‌کند.
from illustrated import O, ell, pth, shine, flame
from illustrated2 import faceDots

def soil(w=32): return pth(f'M-{w},30 C-{w//2},18 {w//2},18 {w},30 V36 H-{w}Z', 'url(#iBrown)')
def leaf(x, y, rot, s=1, flip=1):
    return f'<g transform="translate({x} {y}) rotate({rot}) scale({s*flip} {s})">' + pth('M0,0 C6,-12 22,-12 28,-20 C30,0 14,10 0,0Z', 'url(#iGold)') + '<path d="M2,-1 C10,-6 18,-10 24,-16" stroke="#fff" stroke-opacity=".5" stroke-width="1.6" fill="none"/></g>'
def stem(y1, y2): return f'<path d="M0,{y1} C-3,{(y1+y2)//2} 3,{(y1+y2)//2} 0,{y2}" stroke="url(#iGold)" stroke-width="4.4" fill="none" stroke-linecap="round"/>'

def g1_seed(): return soil() + ell(0, 20, 9, 6, 'url(#iGold)') + '<path d="M-4,18 Q0,15 4,18" stroke="#fff" stroke-opacity=".7" stroke-width="1.6" fill="none"/>' + f'<circle cx="0" cy="-8" r="20" fill="url(#iGlow)"/>'
def g2_sprout(): return soil() + stem(22, 0) + leaf(0, 2, -35, .6) + leaf(0, 2, 35, .6, -1)
def g3_seedling(): return soil() + stem(22, -14) + leaf(0, -12, -25, .95) + leaf(0, -12, 25, .95, -1)
def g4_plant(): return soil() + stem(22, -24) + leaf(0, 14, -5, 1.05) + leaf(0, 14, 5, 1.05, -1) + leaf(0, -4, -30, 1.0) + leaf(0, -4, 30, 1.0, -1) + leaf(0, -24, -50, .75) + leaf(0, -24, 50, .75, -1)
def g5_bud(): return soil() + stem(22, -20) + leaf(0, 14, -5, 1.05) + leaf(0, 14, 5, 1.05, -1) + leaf(0, -2, -45, .9) + leaf(0, -2, 45, .9, -1) + pth('M0,-44 C10,-38 12,-26 0,-18 C-12,-26 -10,-38 0,-44Z', 'url(#iRed)') + pth('M-9,-30 C-9,-22 -4,-17 0,-17 C4,-17 9,-22 9,-30 C5,-24 -5,-24 -9,-30Z', 'url(#iGold)')
def g6_flower():
    petals = ''.join(f'<g transform="rotate({a} 0 -30)">' + pth('M0,-30 C-12,-38 -10,-58 0,-62 C10,-58 12,-38 0,-30Z', 'url(#iRed)') + '</g>' for a in range(0, 360, 60))
    return soil() + stem(22, -30) + leaf(0, 14, -5, 1.0) + leaf(0, 14, 5, 1.0, -1) + petals + f'<circle cx="0" cy="-30" r="10" fill="url(#iGold)" {O}/>' + faceDots(-4, 4, -31, 1.5, True)
def g7_tree():
    return (f'<circle r="44" fill="url(#iGlow)" opacity=".6"/>' + pth('M-6,36 C-4,16 -3,4 -8,-10 L8,-10 C3,4 4,16 6,36Z', 'url(#iBrown)')
            + ell(-16, -12, 20, 18, 'url(#iGold)') + ell(16, -12, 20, 18, 'url(#iGold)') + ell(0, -26, 24, 20, 'url(#iGold)') + shine('M-30,-14 C-28,-24 -18,-30 -8,-32 C-20,-26 -26,-20 -30,-8Z', .5)
            + '<path d="M-28,36 H28" stroke="#fff" stroke-opacity=".0"/>' + soil(38))

def brick(x, y, w=26, h=13, fill='url(#iRed)'): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="{fill}" {O}/>' + f'<rect x="{x+2}" y="{y+1.5}" width="{w-4}" height="3" rx="1.5" fill="#fff" opacity=".35"/>'
def b1_brick(): return brick(-24, -8, 48, 26) + '<path d="M-24,5 H24" stroke="#fff" stroke-opacity=".0"/>' + '<circle cx="-12" cy="5" r="2" fill="#fff" opacity=".4"/><circle cx="12" cy="5" r="2" fill="#fff" opacity=".4"/>'
def b2_pile(): return brick(-30, 8, 28, 15) + brick(2, 8, 28, 15) + brick(-14, -8, 28, 15)
def b3_wall(): return ''.join(brick(x + (10 if r % 2 else 0), 22 - r * 14, 28, 13) for r in range(4) for x in (-42, -14, 14) if -40 < x + (10 if r % 2 else 0) < 40)
def hut():
    return (pth('M-26,34 V0 H26 V34Z', 'url(#iPaper)') + pth('M-34,2 L0,-30 L34,2Z', 'url(#iRed)') + pth('M-7,34 V14 H7 V34Z', 'url(#iBrown)') + shine('M-22,6 H-8 V14 H-22Z', .0))
def house():
    return (pth('M-30,34 V-2 H30 V34Z', 'url(#iPaper)') + pth('M-38,0 L0,-34 L38,0Z', 'url(#iRed)') + pth('M16,-18 V-34 H26 V-10Z', 'url(#iBrown)')
            + pth('M-6,34 V12 H8 V34Z', 'url(#iBrown)') + pth('M-26,8 H-14 V20 H-26Z', 'url(#iGlass)') + pth('M14,8 H26 V20 H14Z', 'url(#iGlass)') + '<path d="M-20,8 V20 M-26,14 H-14 M20,8 V20 M14,14 H26" stroke="#B97C0A" stroke-width="1.4"/>')
def tower():
    cren = ''.join(pth(f'M{x},-34 h8 v8 h-8Z', 'url(#iPaper)') for x in (-22, -4, 14))
    return (pth('M-20,36 V-26 H20 V36Z', 'url(#iPaper)') + cren + pth('M-6,36 V14 A6,6 0 0 1 6,14 V36Z', 'url(#iBrown)') + pth('M-5,-14 h10 v14 h-10Z', 'url(#iGlass)')
            + '<path d="M-20,-8 H20 M-20,6 H20" stroke="#1b2a49" stroke-opacity=".15"/>')
def castle():
    def tw(x, h, w=16): return pth(f'M{x-w//2},36 V{-h} H{x+w//2} V36Z', 'url(#iPaper)') + ''.join(pth(f'M{x-w//2+i*(w//3)},{-h-7} h{w//3-1} v7 h-{w//3-1}Z', 'url(#iPaper)') for i in range(3))
    return (pth('M-32,36 V-6 H32 V36Z', 'url(#iPaper)') + tw(-30, 16) + tw(30, 16) + tw(0, 30, 20) + pth('M-7,36 V14 A7,7 0 0 1 7,14 V36Z', 'url(#iBrown)') + pth('M-3,-16 h6 v10 h-6Z', 'url(#iGlass)')
            + '<path d="M0,-37 V-50" stroke="#B97C0A" stroke-width="2.4" stroke-linecap="round"/>' + pth('M0,-50 L14,-45 L0,-40Z', 'url(#iRed)'))
def palace():
    dome = lambda x, r: pth(f'M{x-r},-4 A{r},{r} 0 0 1 {x+r},-4Z', 'url(#iGold)') + f'<path d="M{x},{-4-r} v-8" stroke="#B97C0A" stroke-width="2" stroke-linecap="round"/><circle cx="{x}" cy="{-14-r}" r="2.4" fill="#FFE9A8"/>'
    return (f'<circle r="46" fill="url(#iGlow)"/>' + pth('M-38,36 V-4 H38 V36Z', 'url(#iPaper)') + dome(0, 22) + dome(-30, 11) + dome(30, 11)
            + ''.join(pth(f'M{x-4},36 V8 A4,4 0 0 1 {x+4},8 V36Z', 'url(#iBlue)') for x in (-26, -9, 9, 26)) + '<path d="M-38,-4 H38" stroke="#B97C0A" stroke-width="2.4"/>')

def book_closed():
    return (pth('M-24,-34 H20 C26,-34 28,-30 28,-26 V30 C28,34 26,36 20,36 H-24Z', 'url(#iBlue)') + pth('M-24,-34 V36 H-30 V-28 C-30,-32 -28,-34 -24,-34Z', 'url(#iGold)')
            + pth('M-14,-22 H18 V-8 H-14Z', 'url(#iGold)', stroke=False) + '<path d="M-8,-15 H12" stroke="#1b2a49" stroke-opacity=".5" stroke-width="2.4" stroke-linecap="round"/>' + '<path d="M-30,30 H22 C26,30 28,32 28,34" stroke="#fff" stroke-opacity=".5" stroke-width="2" fill="none"/>' + shine('M-18,-30 H-10 V30 H-18Z', .3))
def stack(n):
    cols = ['url(#iBlue)', 'url(#iRed)', 'url(#iGold)', 'url(#iPaper)', 'url(#iBlue)', 'url(#iRed)']
    out = ''
    for k in range(n):
        y = 36 - (k + 1) * 19
        dx = ((-1) ** k) * (2 + k % 3 * 2)
        out += f'<g transform="translate({dx} {y})">' + pth('M-30,0 H30 C33,0 34,2 34,4 V15 C34,17 33,18 30,18 H-30Z', cols[k]) + pth('M-30,0 V18 H-35 V0Z', 'url(#iGold)') + '<path d="M-20,9 H-4" stroke="#fff" stroke-opacity=".7" stroke-width="2.6" stroke-linecap="round"/>' + pth('M28,3 h4 v12 h-4Z', '#fff', 'fill-opacity=".6"', False) + '</g>'
    return out
def stack_s(n):
    sc = 1 if n <= 3 else 0.8
    return f'<g transform="translate(0 {0 if n<=3 else -2}) scale({sc})">{stack(n)}</g>'
def big_shelf():
    def row(y, ks):
        x = -34; o = ''
        for w, c in ks:
            h = 22 if w > 8 else 18; o += f'<rect x="{x}" y="{y-h}" width="{w}" height="{h}" rx="1.6" fill="{c}" {O}/>'; x += w + 1.4
        return o
    cs = ['url(#iBlue)', 'url(#iRed)', 'url(#iGold)', 'url(#iPaper)']
    ks = [(9, cs[0]), (7, cs[1]), (11, cs[2]), (8, cs[3]), (10, cs[0]), (7, cs[1]), (9, cs[2])]
    return (pth('M-40,-38 H40 V38 H-40Z', 'url(#iBrown)') + pth('M-36,-34 H36 V34 H-36Z', '#1b2a49', 'fill-opacity=".35"', False) + row(-8, ks) + row(18, ks[::-1]) + row(-34 + 22 - 22 + 0, []) + '<path d="M-40,-8 H40 M-40,18 H40" stroke="url(#iGold)" stroke-width="3"/>')
def radiant_book():
    rays = ''.join(f'<path d="M0,-6 L{x},{y}" stroke="url(#iGold)" stroke-width="3.4" stroke-linecap="round"/>' for x, y in ((-30, -34), (-14, -42), (0, -46), (14, -42), (30, -34)))
    return (f'<circle cy="-6" r="34" fill="url(#iGlow)"/>' + rays + pth('M0,6 C-12,-2 -26,-2 -36,2 V32 C-26,28 -12,28 0,36Z', 'url(#iPaper)') + pth('M0,6 C12,-2 26,-2 36,2 V32 C26,28 12,28 0,36Z', 'url(#iPaper)')
            + '<path d="M-30,10 C-20,8 -12,10 -6,14 M-30,18 C-20,16 -12,18 -6,22 M30,10 C20,8 12,10 6,14 M30,18 C20,16 12,18 6,22" stroke="#1b2a49" stroke-opacity=".3" stroke-width="1.6" fill="none"/>')

def mountain(kind):
    flagp = lambda x, y: f'<path d="M{x},{y} V{y-16}" stroke="#B97C0A" stroke-width="2.4" stroke-linecap="round"/>' + pth(f'M{x},{y-16} L{x+14},{y-11} L{x},{y-6}Z', 'url(#iRed)')
    if kind == 1: return soil(36) + flagp(0, 20)
    if kind == 2: return pth('M-40,34 C-26,2 -10,-8 0,-8 C10,-8 26,2 40,34Z', 'url(#iGold)') + '<path d="M0,34 C-8,22 6,14 0,6" stroke="#fff" stroke-opacity=".6" stroke-width="3" fill="none" stroke-linecap="round" stroke-dasharray="1 6"/>'
    if kind == 3: return pth('M-44,34 L-14,-10 L10,22 L22,6 L44,34Z', 'url(#iGold)') + '<path d="M-14,-10 L-22,4 L-12,2 L-8,10Z" fill="#fff" fill-opacity=".85"/>' + '<path d="M-6,34 C-14,26 4,20 -2,12" stroke="#fff" stroke-opacity=".6" stroke-width="2.6" fill="none" stroke-dasharray="1 6" stroke-linecap="round"/>'
    if kind == 4: return pth('M-46,36 L-4,-30 L46,36Z', 'url(#iGold)') + pth('M-4,-30 L-16,-12 L-8,-16 L-2,-8 L6,-16 L14,-12Z', '#fff', 'fill-opacity=".92"', False) + pth('M-4,-30 L16,36 H-46Z', '#1b2a49', 'fill-opacity=".12"', False)
    if kind == 5: return pth('M-46,36 L-4,-30 L46,36Z', 'url(#iGold)') + pth('M-4,-30 L-16,-12 L-8,-16 L-2,-8 L6,-16 L14,-12Z', '#fff', 'fill-opacity=".92"', False) + flagp(-4, -30)
    if kind == 6: return ('<circle cx="-24" cy="-22" r="10" fill="url(#iGold)"/>' + pth('M-48,36 L-18,-4 L-4,12 L14,-22 L48,36Z', 'url(#iGold)') + pth('M14,-22 L4,-8 L10,-10 L14,-2 L20,-10 L26,-8Z', '#fff', 'fill-opacity=".92"', False) + flagp(14, -22))

def stone_rough():
    return (pth('M-26,6 L-16,-20 L8,-26 L28,-8 L24,20 L-4,30 L-24,22Z', 'url(#iPaper)') + '<path d="M-16,-20 L-4,0 L8,-26 M-4,0 L-24,22 M-4,0 L24,20 M-4,0 L28,-8" stroke="#1b2a49" stroke-opacity=".22" stroke-width="1.6" fill="none"/>' + shine('M-14,-16 L-4,-2 L-12,4 L-22,2Z', .5))
def star_laurel_crown():
    leaves = ''.join(f'<g transform="rotate({a} 0 4)"><path d="M-36,4 C-40,-6 -34,-14 -26,-14 C-24,-4 -28,2 -36,4Z" fill="url(#iGold)" {O}/></g>' for a in (-10, 20, 50, 80))
    mirror = ''.join(f'<g transform="scale(-1 1)"><g transform="rotate({a} 0 4)"><path d="M-36,4 C-40,-6 -34,-14 -26,-14 C-24,-4 -28,2 -36,4Z" fill="url(#iGold)" {O}/></g></g>' for a in (-10, 20, 50, 80))
    star = '<path d="M0,-28 L5,-14 L20,-14 L8,-5 L12,10 L0,1 L-12,10 L-8,-5 L-20,-14 L-5,-14Z" fill="url(#iGold)" ' + O + '/>'
    return f'<circle r="46" fill="url(#iGlow)"/>' + leaves + mirror + star
ICONS4 = dict(g1=g1_seed, g2=g2_sprout, g3=g3_seedling, g4=g4_plant, g5=g5_bud, g6=g6_flower, g7=g7_tree,
              b1=b1_brick, b2=b2_pile, b3=b3_wall, b4=hut, b5=house, b6=tower, b7=castle, b8=palace,
              r1=book_closed, r3=lambda: stack_s(2), r4=lambda: stack_s(3), r5=lambda: stack_s(5), r7=big_shelf, r8=radiant_book,
              m1=lambda: mountain(1), m2=lambda: mountain(2), m3=lambda: mountain(3), m4=lambda: mountain(4), m5=lambda: mountain(5), m6=lambda: mountain(6),
              stone=stone_rough, laurel=star_laurel_crown)
def match():
    return (f'<circle cx="0" cy="-16" r="26" fill="url(#iGlow)"/>' + '<g transform="rotate(-18)">' + pth('M-4,-6 H4 V40 H-4Z', 'url(#iWood)') + ell(0, -6, 7, 8, 'url(#iRed)') + '</g>' + flame(-3, -26, .5))
def torch():
    return ('<g transform="rotate(-20)">' + pth('M-5,6 H5 L8,40 H-8Z', 'url(#iWood)') + pth('M-11,-2 H11 L8,10 H-8Z', 'url(#iGold)') + '</g>' + flame(-6, -14, 1.05) + f'<circle cx="-6" cy="-14" r="34" fill="url(#iGlow)"/>')
def summit_glory():
    st = '<path d="M-32,-30 l2,5 l5,2 l-5,2 l-2,5 l-2,-5 l-5,-2 l5,-2z M34,-6 l1.6,4 l4,1.6 l-4,1.6 l-1.6,4 l-1.6,-4 l-4,-1.6 l4,-1.6z" fill="#FFF3C4"/>'
    from illustrated2 import summit
    return f'<circle cx="0" cy="-6" r="46" fill="url(#iGlow)"/>' + summit() + st
def m7(): 
    from illustrated2 import summit
    return summit()
def m6b(): return mountain(6)
ICONS4.update(match=match, torch=torch, summit_glory=summit_glory)
