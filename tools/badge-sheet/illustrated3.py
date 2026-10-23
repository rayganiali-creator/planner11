# دستهٔ سوم موضوع‌ها (ادامهٔ illustrated2) — همه هم‌سبکِ جغد/شمع/فانوس.
from illustrated import O, ell, pth, shine
from illustrated2 import faceDots
from make_sheet import P, f

K = '#1b2a49'
def crescent_moon():
    return (f'<circle cx="2" cy="-2" r="38" fill="url(#iGlow)"/>' + pth('M12,-34 C-14,-34 -32,-14 -32,8 C-32,28 -14,40 6,38 C-6,30 -10,18 -8,6 C-6,-8 2,-26 12,-34Z', 'url(#iGold)')
            + '<circle cx="-18" cy="4" r="2.6" fill="#1b2a49"/><path d="M-22,14 Q-16,20 -10,14" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>'
            + '<path d="M24,-22 l2.4,6 l6,2.4 l-6,2.4 l-2.4,6 l-2.4,-6 l-6,-2.4 l6,-2.4z M30,14 l1.6,4 l4,1.6 l-4,1.6 l-1.6,4 l-1.6,-4 l-4,-1.6 l4,-1.6z" fill="#FFF3C4"/>' + shine('M-26,-4 C-22,-18 -12,-28 0,-32 C-12,-24 -20,-12 -22,2Z', .5))
def sunrise():
    rays = ''.join(f'<path d="M0,-38 L3.4,-26 H-3.4Z" fill="url(#iGold)" {O} transform="translate(0 6) rotate({a})"/>' for a in (-70, -45, -22, 0, 22, 45, 70))
    return (rays + '<path d="M-24,22 A24,24 0 0 1 24,22Z" fill="url(#iGold)" ' + O + '/>' + '<circle cx="-8" cy="14" r="2.4" fill="#1b2a49"/><circle cx="8" cy="14" r="2.4" fill="#1b2a49"/><path d="M-5,18 Q0,22 5,18" stroke="#1b2a49" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
            + pth('M-40,26 C-26,16 -10,18 0,24 C12,16 28,18 40,26 V36 H-40Z', 'url(#iBrown)') + shine('M-34,26 C-24,20 -14,20 -6,24Z', .4))
def fox():
    return (pth('M-30,-8 L-26,-34 L-8,-20 L8,-20 L26,-34 L30,-8 C30,16 14,30 0,34 C-14,30 -30,16 -30,-8Z', 'url(#iGold)')
            + pth('M-26,-30 L-14,-20 L-24,-14Z M26,-30 L14,-20 L24,-14Z', '#1b2a49', 'opacity=".8"', False)
            + pth('M-30,0 C-22,4 -10,14 0,34 C10,14 22,4 30,0 C26,16 14,30 0,34 C-14,30 -26,16 -30,0Z', 'url(#iPaper)')
            + '<ellipse cx="-12" cy="-4" rx="3.4" ry="4.4" fill="#1b2a49"/><ellipse cx="12" cy="-4" rx="3.4" ry="4.4" fill="#1b2a49"/><circle cx="-11" cy="-5.6" r="1.2" fill="#fff"/><circle cx="13" cy="-5.6" r="1.2" fill="#fff"/><ellipse cx="0" cy="22" rx="4.4" ry="3.4" fill="#1b2a49"/>' + shine('M-24,-6 C-22,-16 -16,-24 -10,-26 C-16,-18 -20,-10 -20,0Z', .45))
def whale():
    return ('<path d="M10,-8 C10,-18 6,-22 2,-28 M10,-8 C10,-18 14,-22 18,-28" stroke="#FFF1B8" stroke-width="3.4" fill="none" stroke-linecap="round" opacity=".9"/>'
            + pth('M-38,8 C-38,-6 -22,-14 -4,-14 C16,-14 30,-4 32,12 C36,10 40,4 40,-4 C44,6 42,20 32,26 C22,32 -4,34 -22,30 C-34,26 -38,18 -38,8Z', 'url(#iGold)')
            + pth('M-30,18 C-14,28 14,28 30,18 C22,30 -14,32 -30,18Z', '#FFFBEF', 'opacity=".95"', False) + '<circle cx="-22" cy="4" r="3" fill="#1b2a49"/><circle cx="-23" cy="3" r="1" fill="#fff"/><path d="M-30,12 Q-26,16 -20,13" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>'
            + '<path d="M-38,38 C-24,42 -4,42 10,38" stroke="#FFF1B8" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".6"/>' + shine('M-30,-4 C-24,-10 -14,-12 -6,-12 C-18,-8 -26,-2 -30,8Z', .5))
def tomato_timer():
    ticks = ''.join(f'<path d="M0,-17 V-13" stroke="#1b2a49" stroke-width="2" stroke-linecap="round" transform="rotate({a})"/>' for a in range(0, 360, 90))
    return (ell(0, 8, 31, 28, 'url(#iFire)') + pth('M0,-18 C-4,-26 -14,-24 -18,-17 C-10,-15 -6,-11 0,-13 C6,-11 10,-15 18,-17 C14,-24 4,-26 0,-18Z', '#1b2a49')
            + '<circle cx="0" cy="9" r="17" fill="#fff"/>' + f'<g transform="translate(0 9)">{ticks}<path d="M0,0 V-11 M0,0 L8,5" stroke="#1b2a49" stroke-width="2.6" stroke-linecap="round"/><circle r="2" fill="#1b2a49"/></g>')
def ant():
    legs = ''.join(f'<path d="M{x},{y} l{dx},{dy}" stroke="#1b2a49" stroke-width="2.6" stroke-linecap="round"/>' for x, y, dx, dy in ((-14, 10, -12, 14), (-2, 12, -4, 18), (8, 12, 6, 18), (-14, 10, -22, 4), (14, 10, 22, 4), (14, 10, 12, 14)))
    return (legs + ell(-16, 4, 15, 12, 'url(#iGold)') + ell(6, 6, 9, 8, 'url(#iGold)') + ell(24, -6, 12, 11, 'url(#iGold)')
            + '<path d="M26,-16 C28,-26 34,-28 38,-26 M32,-14 C38,-20 42,-20 44,-18" stroke="#1b2a49" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
            + '<circle cx="22" cy="-7" r="2.6" fill="#1b2a49"/><circle cx="30" cy="-7" r="2.6" fill="#1b2a49"/><path d="M23,-1 Q26,2 29,-1" stroke="#1b2a49" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
            + '<path d="M-16,-14 V-34" stroke="#1b2a49" stroke-width="2.4" stroke-linecap="round"/>' + pth('M-16,-34 H-2 L-6,-30 L-2,-26 H-16Z', 'url(#iRed)') + shine('M-28,-2 C-26,-6 -20,-8 -14,-8 C-22,-6 -26,0 -28,4Z', .5))
def acorn():
    return (pth('M-24,-4 C-26,24 -10,36 0,38 C10,36 26,24 24,-4Z', 'url(#iGold)') + pth('M-28,-6 C-30,-24 -14,-32 0,-32 C14,-32 30,-24 28,-6Z', 'url(#iBrown)')
            + '<path d="M-22,-14 L-12,-6 M-8,-24 L2,-8 M10,-26 L16,-8 M22,-16 L16,-6 M-14,-22 L-8,-10" stroke="#1b2a49" stroke-width="1.6" opacity=".35"/><path d="M0,-32 V-40" stroke="#6B4126" stroke-width="3.4" stroke-linecap="round"/>'
            + '<circle cx="-8" cy="8" r="2.4" fill="#1b2a49"/><circle cx="8" cy="8" r="2.4" fill="#1b2a49"/><path d="M-4,14 Q0,18 4,14" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>' + shine('M-18,0 C-18,14 -12,24 -6,30 C-14,22 -20,10 -20,0Z', .5))
def wheat():
    grains = ''
    for k in range(5):
        y = -30 + k * 11
        grains += f'<ellipse cx="-7" cy="{y}" rx="4.4" ry="8" fill="url(#iGold)" {O} transform="rotate(-28 -7 {y})"/><ellipse cx="7" cy="{y + 4}" rx="4.4" ry="8" fill="url(#iGold)" {O} transform="rotate(28 7 {y + 4})"/>'
    return ('<path d="M0,38 V-26" stroke="#E0A33A" stroke-width="3.4" stroke-linecap="round"/>' + grains + f'<ellipse cx="0" cy="-34" rx="4.4" ry="8" fill="url(#iGold)" {O}/>'
            + '<path d="M-12,34 C-4,28 4,28 12,34 L8,40 H-8Z" fill="url(#iBrown)" ' + O + '/>')
def apple_basket():
    return (pth('M-24,0 C-24,-18 -8,-22 0,-12 C8,-22 24,-18 24,0 C24,12 12,16 0,14 C-12,16 -24,12 -24,0Z', 'url(#iFire)')
            + '<path d="M0,-12 V-20" stroke="#6B4126" stroke-width="3" stroke-linecap="round"/>' + pth('M0,-18 C4,-26 12,-26 14,-22 C10,-18 4,-16 0,-18Z', 'url(#iGold)')
            + pth('M-34,8 H34 L28,36 C28,38 26,39 24,39 H-24 C-26,39 -28,38 -28,36Z', 'url(#iBrown)') + '<path d="M-24,16 L-20,34 M-12,16 L-10,34 M0,16 V34 M12,16 L10,34 M24,16 L20,34 M-30,22 H30 M-28,30 H28" stroke="#1b2a49" stroke-width="1.6" opacity=".4"/>'
            + shine('M-18,-6 C-16,-12 -10,-14 -6,-12 C-12,-10 -14,-4 -14,2Z', .55))
def honey_pot():
    return (pth('M-24,-4 C-30,6 -28,26 -14,34 C-4,38 4,38 14,34 C28,26 30,6 24,-4Z', 'url(#iGold)') + pth('M-20,-14 H20 V-4 H-20Z', 'url(#iBrown)')
            + '<path d="M-20,-14 C-20,-22 20,-22 20,-14" fill="#FFF1B8" opacity=".9"/>'
            + '<path d="M-14,-4 C-14,4 -8,6 -8,12 M6,-4 C6,2 10,4 10,9" stroke="#FFFBEF" stroke-width="3" fill="none" stroke-linecap="round" opacity=".7"/>'
            + '<circle cx="-7" cy="16" r="2.4" fill="#1b2a49"/><circle cx="7" cy="16" r="2.4" fill="#1b2a49"/><path d="M-3,21 Q0,24 3,21" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>'
            + '<path d="M16,-18 L32,-34" stroke="#C98A52" stroke-width="3.6" stroke-linecap="round"/><ellipse cx="34" cy="-36" rx="5" ry="3.6" fill="url(#iGold)" ' + O + ' transform="rotate(-45 34 -36)"/>' + shine('M-24,2 C-26,12 -22,22 -16,28 C-24,22 -28,10 -24,2Z', .5))
def beehive():
    rows = ''.join(f'<path d="M-{w},{y} C-{w - 2},{y + 5} {w - 2},{y + 5} {w},{y}" stroke="#1b2a49" stroke-width="2.4" fill="none" opacity=".45" stroke-linecap="round"/>' for w, y in ((28, -14), (30, 0), (28, 14), (24, 26)))
    return (pth('M-30,34 C-34,20 -32,0 -22,-14 C-14,-26 -6,-34 0,-34 C6,-34 14,-26 22,-14 C32,0 34,20 30,34Z', 'url(#iGold)') + rows
            + '<ellipse cx="0" cy="16" rx="9" ry="11" fill="#1b2a49"/>' + pth('M-34,36 H34 V42 H-34Z', 'url(#iBrown)')
            + '<g transform="translate(24 -24) scale(.55)"><ellipse cx="0" cy="0" rx="9" ry="12" fill="#FFD36A"/><path d="M-9,-3 H9 M-8,5 H8" stroke="#1b2a49" stroke-width="3"/><ellipse cx="-5" cy="-11" rx="6" ry="3" fill="#fff" opacity=".85"/><ellipse cx="5" cy="-11" rx="6" ry="3" fill="#fff" opacity=".85"/></g>' + shine('M-24,-10 C-18,-22 -8,-30 -2,-31 C-12,-24 -18,-14 -22,0Z', .55))
def turtle():
    shell = ''.join(f'<path d="{d}" stroke="#1b2a49" stroke-width="2" fill="none" opacity=".45"/>' for d in ('M-12,-12 L0,-6 L12,-12 M0,-6 V8 M-12,-12 L-16,0 L-6,8 L0,8 L6,8 L16,0 L12,-12', 'M-16,0 L-22,6 M16,0 L22,6'))
    return (pth('M24,2 C32,-4 40,0 40,6 C40,14 30,14 24,12Z', 'url(#iGold)') + '<circle cx="35" cy="5" r="1.8" fill="#1b2a49"/>' + pth('M-18,14 L-24,28 H-12 L-8,16Z M18,14 L24,28 H12 L8,16Z', 'url(#iGold)')
            + pth('M-30,16 C-30,-14 -14,-24 0,-24 C14,-24 30,-14 30,16Z', 'url(#iGold)') + shell + pth('M-34,16 H34 V22 H-34Z', 'url(#iBrown)') + shine('M-24,6 C-24,-8 -16,-18 -8,-20 C-16,-12 -20,-2 -20,8Z', .55)
            + '<path d="M-38,-8 L-44,-14 M-40,-2 L-48,-4" stroke="#FFF1B8" stroke-width="2.4" stroke-linecap="round" opacity=".7"/>')
def queen_bee():
    return ('<ellipse cx="-14" cy="-6" rx="12" ry="7" fill="#fff" opacity=".85" transform="rotate(-25 -14 -6)"/><ellipse cx="14" cy="-6" rx="12" ry="7" fill="#fff" opacity=".85" transform="rotate(25 14 -6)"/>'
            + ell(0, 14, 20, 24, 'url(#iGold)') + '<path d="M-19,6 C-8,10 8,10 19,6 M-18,18 C-8,22 8,22 18,18" stroke="#1b2a49" stroke-width="5.4" fill="none" opacity=".92"/>' + pth('M-3,36 L0,44 L3,36Z', '#1b2a49')
            + ell(0, -8, 14, 12, 'url(#iGold)') + faceDots(-5.5, 5.5, -9, 2.6, True, -3.5)
            + pth('M-12,-18 L-14,-30 L-6,-24 L0,-34 L6,-24 L14,-30 L12,-18Z', 'url(#iGold)') + '<circle cx="0" cy="-23" r="2" fill="#E8481A"/>' + shine('M-12,6 C-14,14 -12,24 -8,28 C-14,22 -16,12 -12,6Z', .5))
def open_book_ribbon():
    return (pth('M0,-14 C-10,-24 -26,-22 -34,-18 V22 C-26,18 -10,18 0,28Z', 'url(#iPaper)') + pth('M0,-14 C10,-24 26,-22 34,-18 V22 C26,18 10,18 0,28Z', '#EEF1FA')
            + '<path d="M0,-14 V28" stroke="#8fa0c8" stroke-width="2"/><path d="M-28,-8 C-18,-9 -10,-7 -5,-2 M-28,2 C-18,1 -10,3 -5,8 M5,-2 C10,-7 18,-9 28,-8 M5,8 C10,3 18,1 28,2" stroke="#9aa6c4" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
            + pth('M10,-22 V10 L15,5 L20,10 V-20Z', 'url(#iRed)') + '<path d="M0,-30 l2,5 l5,2 l-5,2 l-2,5 l-2,-5 l-5,-2 l5,-2z" fill="#FFF3C4"/>')
def books_tea():
    return (pth('M-30,22 H20 V34 H-30Z', 'url(#iRed)') + pth('M-26,10 H18 V22 H-26Z', 'url(#iBlue)') + pth('M-22,-2 H14 V10 H-22Z', 'url(#iGold)')
            + '<path d="M-24,28 H18 M-20,16 H14 M-16,4 H10" stroke="#fff" stroke-width="1.8" opacity=".6"/>'
            + pth('M20,6 H38 V20 C38,26 32,28 29,28 C24,28 20,26 20,20Z', 'url(#iPaper)') + '<path d="M38,10 C44,10 44,20 38,20" stroke="#fff" stroke-width="2.6" fill="none"/>' + '<path d="M25,-4 C22,-10 28,-12 25,-18 M31,-4 C28,-10 34,-12 31,-18" stroke="#FFF1B8" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".85"/>')
def glasses():
    return (f'<circle cx="-16" cy="2" r="14" fill="url(#iGlass)" stroke="#FFD36A" stroke-width="4"/><circle cx="16" cy="2" r="14" fill="url(#iGlass)" stroke="#FFD36A" stroke-width="4"/>'
            + '<path d="M-2,0 Q0,-4 2,0 M-30,-2 L-40,-8 M30,-2 L40,-8" stroke="#FFD36A" stroke-width="4" fill="none" stroke-linecap="round"/>' + '<path d="M-24,-4 C-22,-8 -18,-10 -14,-10 M8,-4 C10,-8 14,-10 18,-10" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".7"/>')
def bookshelf():
    bk = lambda x, w, h, fill: f'<rect x="{x}" y="{-h}" width="{w}" height="{h}" rx="1.6" fill="{fill}" {O} transform="translate(0 0)"/>'
    row1 = ''.join(bk(x, w, h, fl) for x, w, h, fl in ((-26, 8, 18, 'url(#iRed)'), (-17, 6, 22, 'url(#iGold)'), (-10, 9, 16, 'url(#iBlue)'), (0, 7, 20, 'url(#iPaper)'), (8, 8, 17, 'url(#iRed)'), (17, 9, 21, 'url(#iGold)')))
    return (pth('M-34,-34 H34 V38 H-34Z', 'url(#iBrown)') + '<path d="M-30,-30 H30 V34 H-30Z" fill="#1b2a49" opacity=".55"/>' + f'<g transform="translate(0 4)">{row1}</g>'
            + f'<g transform="translate(0 38)">{row1}</g>' + pth('M-34,4 H34 V9 H-34Z', 'url(#iBrown)') + pth('M-34,36 H34 V41 H-34Z', 'url(#iBrown)'))
def quill():
    return ('<path d="M-6,32 C-16,6 -2,-26 32,-36 C28,-8 12,20 -6,32Z" fill="url(#iPaper)" ' + O + '/><path d="M-6,32 C4,10 14,-6 30,-34" stroke="#8fa0c8" stroke-width="2" fill="none"/>'
            + '<path d="M2,18 C8,14 12,10 16,4 M10,8 C16,4 20,-2 22,-8" stroke="#9aa6c4" stroke-width="1.6" fill="none"/>' + pth('M-34,40 C-22,34 -10,36 -6,32 L-8,38Z', '#1b2a49', stroke=False)
            + pth('M-30,26 H-14 V42 H-30Z', 'url(#iGold)') + '<rect x="-27" y="22" width="10" height="5" rx="1.6" fill="url(#iBrown)"/>')
def reading_lamp():
    return (f'<path d="M-6,-12 L-34,26 H26Z" fill="#FFF1B8" opacity=".25"/>' + pth('M-24,38 H0 V34 H-24Z', 'url(#iGold)') + '<path d="M-12,34 L-4,6 L12,-18" stroke="#FFD36A" stroke-width="4.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            + pth('M2,-28 L26,-12 L16,-2 L-6,-14Z', 'url(#iGold)') + '<circle cx="8" cy="-8" r="5" fill="#FFF6D0"/>' + pth('M-36,40 C-26,36 -16,36 -6,40 V44 H-36Z', 'url(#iPaper)'))
def book_sprout():
    return ('<path d="M0,-4 V-18" stroke="#6B4126" stroke-width="3" stroke-linecap="round"/>' + pth('M0,-14 C-4,-30 -24,-32 -28,-24 C-24,-10 -8,-8 0,-14Z', 'url(#iGold)') + pth('M0,-18 C4,-36 24,-38 28,-30 C24,-16 8,-14 0,-18Z', 'url(#iGold)')
            + pth('M0,0 C-10,-10 -26,-8 -34,-4 V28 C-26,24 -10,24 0,34Z', 'url(#iPaper)') + pth('M0,0 C10,-10 26,-8 34,-4 V28 C26,24 10,24 0,34Z', '#EEF1FA') + '<path d="M0,0 V34" stroke="#8fa0c8" stroke-width="2"/>')
def ladder():
    return (pth('M-18,38 L-14,-34 H-8 L-12,38Z M8,38 L12,-34 H18 L14,38Z', 'url(#iBrown)') + ''.join(f'<rect x="-14" y="{y}" width="28" height="5" rx="2" fill="url(#iGold)" {O}/>' for y in (-24, -10, 4, 18, 30))
            + '<path d="M0,-40 l3,7 l8,1 l-6,5 l2,8 l-7,-4 l-7,4 l2,-8 l-6,-5 l8,-1z" fill="#FFF3C4" transform="translate(0 -2) scale(.8)"/>')
def medal():
    return ('<path d="M-14,-38 L-4,-8 H10 L0,-38Z" fill="url(#iRed)" ' + O + '/><path d="M14,-38 L4,-8 H-10 L0,-38Z" fill="url(#iBlue)" opacity=".0"/>' + f'<circle cx="0" cy="14" r="22" fill="url(#iGold)" {O}/><circle cx="0" cy="14" r="16" fill="none" stroke="#B97C0A" stroke-width="2" opacity=".6"/>'
            + '<path d="M-9,14 L-2,22 L11,6" stroke="#1b2a49" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' + shine('M-18,6 C-14,-4 -4,-8 4,-8 C-6,-4 -12,2 -14,14Z', .55))
def podium():
    return (pth('M-14,-4 H14 V38 H-14Z', 'url(#iGold)') + pth('M-38,12 H-14 V38 H-38Z', 'url(#iPaper)') + pth('M14,20 H38 V38 H14Z', 'url(#iBrown)')
            + '<path d="M0,12 l-3,0 v12 M-26,28 h5 M26,30 h-5" stroke="#1b2a49" stroke-width="3" stroke-linecap="round" opacity=".0"/>' + '<path d="M-2,8 v14 M-5,11 l3,-3" stroke="#1b2a49" stroke-width="3.4" stroke-linecap="round" fill="none"/>'
            + '<path d="M0,-34 l5,10 l11,2 l-8,8 l2,11 l-10,-5 l-10,5 l2,-11 l-8,-8 l11,-2z" fill="url(#iGold)" ' + O + '/>' + shine('M-4,-26 L0,-30 L4,-26Z', .6))
def padlock():
    return ('<path d="M-14,-8 V-18 C-14,-34 14,-34 14,-18 V-8" stroke="#FFF1B8" stroke-width="6" fill="none" stroke-linecap="round"/>' + pth('M-24,-8 H24 V34 C24,37 22,38 20,38 H-20 C-22,38 -24,37 -24,34Z', 'url(#iGold)')
            + '<circle cx="0" cy="10" r="5" fill="#1b2a49"/><path d="M-2,12 L-3,24 H3 L2,12Z" fill="#1b2a49"/>' + shine('M-20,-4 H-14 V32 H-20Z', .45))
def calendar_smile():
    return (pth('M-28,-22 H28 V36 H-28Z', 'url(#iPaper)') + pth('M-28,-22 H28 V-8 H-28Z', 'url(#iRed)') + '<path d="M-14,-30 V-16 M14,-30 V-16" stroke="#FFD36A" stroke-width="5" stroke-linecap="round"/>'
            + '<circle cx="-8" cy="10" r="2.6" fill="#1b2a49"/><circle cx="8" cy="10" r="2.6" fill="#1b2a49"/><path d="M-6,18 Q0,25 6,18" stroke="#1b2a49" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
            + '<path d="M20,-6 l2.4,5 l5.4,.8 l-4,3.8 l1,5.4 l-4.8,-2.6 l-4.8,2.6 l1,-5.4 l-4,-3.8 l5.4,-.8z" fill="url(#iGold)" transform="translate(4 18) scale(.9)"/>')
def full_moon():
    return (f'<circle r="42" fill="url(#iGlow)"/>' + f'<circle r="28" fill="url(#iGold)" {O}/>' + '<circle cx="-9" cy="-8" r="5" fill="#B97C0A" opacity=".35"/><circle cx="10" cy="6" r="7" fill="#B97C0A" opacity=".3"/><circle cx="-4" cy="16" r="3.4" fill="#B97C0A" opacity=".3"/>'
            + '<circle cx="-8" cy="-2" r="2.4" fill="#1b2a49"/><circle cx="8" cy="-2" r="2.4" fill="#1b2a49"/><path d="M-5,6 Q0,11 5,6" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>' + shine('M-22,-12 C-18,-20 -8,-26 0,-26 C-12,-20 -18,-10 -20,0Z', .55))
def hatching_egg():
    return (pth('M0,-34 C16,-34 26,-12 26,6 C26,24 14,36 0,36 C-14,36 -26,24 -26,6 C-26,-12 -16,-34 0,-34Z', 'url(#iPaper)') + pth('M-26,6 L-18,0 L-10,8 L-2,0 L6,8 L14,0 L22,8 L26,6 C26,24 14,36 0,36 C-14,36 -26,24 -26,6Z', 'url(#iGold)')
            + '<circle cx="-7" cy="14" r="2.4" fill="#1b2a49"/><circle cx="7" cy="14" r="2.4" fill="#1b2a49"/>' + pth('M-3,19 L3,19 L0,24Z', '#E5A400', stroke=False) + shine('M-18,-6 C-16,-18 -10,-26 -4,-28 C-12,-20 -16,-10 -16,4Z', .6))
def chick():
    return (pth('M-26,6 C-26,-14 -12,-26 0,-26 C12,-26 26,-14 26,6 C26,26 12,36 0,36 C-12,36 -26,26 -26,6Z', 'url(#iGold)') + '<path d="M0,-26 C-2,-34 -8,-36 -8,-36 M0,-26 C2,-36 8,-38 8,-38" stroke="#E5A400" stroke-width="3" fill="none" stroke-linecap="round"/>'
            + '<circle cx="-9" cy="2" r="3" fill="#1b2a49"/><circle cx="9" cy="2" r="3" fill="#1b2a49"/><circle cx="-8" cy="1" r="1" fill="#fff"/><circle cx="10" cy="1" r="1" fill="#fff"/>' + pth('M-5,10 H5 L0,17Z', 'url(#iRed)')
            + pth('M-26,16 C-34,12 -36,22 -28,26Z M26,16 C34,12 36,22 28,26Z', 'url(#iGold)') + '<path d="M-10,36 V42 M10,36 V42" stroke="#E5A400" stroke-width="3" stroke-linecap="round"/>' + shine('M-20,-4 C-18,-14 -10,-22 -4,-23 C-12,-16 -16,-6 -16,6Z', .55))
def robin():
    return ('<path d="M-22,10 L-40,2 L-38,18Z" fill="url(#iBrown)" ' + O + '/>' + ell(0, 10, 26, 24, 'url(#iGold)') + pth('M-6,16 C4,22 18,20 24,10 C20,28 6,34 -4,32Z', 'url(#iPaper)', stroke=False)
            + f'<circle cx="14" cy="-14" r="14" fill="url(#iGold)" {O}/>' + '<circle cx="19" cy="-17" r="2.8" fill="#1b2a49"/><circle cx="20" cy="-18" r="1" fill="#fff"/>' + pth('M26,-14 L38,-10 L26,-6Z', 'url(#iRed)')
            + pth('M-14,6 C-24,2 -26,16 -14,22 C-6,20 0,14 -2,8Z', 'url(#iBrown)') + '<path d="M-4,34 V40 M8,34 V40" stroke="#B97C0A" stroke-width="3" stroke-linecap="round"/>' + shine('M-16,0 C-14,-10 -6,-14 0,-14 C-8,-8 -12,0 -12,10Z', .5))
def lion():
    mane = ''.join(f'<circle cx="{f(P(30, a)[0])}" cy="{f(P(30, a)[1])}" r="10" fill="url(#iBrown)" {O}/>' for a in range(0, 360, 36))
    return (mane + f'<circle r="25" fill="url(#iGold)" {O}/>' + pth('M-22,-16 C-26,-26 -14,-30 -12,-22Z M22,-16 C26,-26 14,-30 12,-22Z', 'url(#iGold)', stroke=False)
            + '<circle cx="-9" cy="-4" r="3" fill="#1b2a49"/><circle cx="9" cy="-4" r="3" fill="#1b2a49"/><circle cx="-8" cy="-5" r="1" fill="#fff"/><circle cx="10" cy="-5" r="1" fill="#fff"/>'
            + pth('M-5,4 H5 L0,10Z', '#1b2a49', stroke=False) + '<path d="M0,10 V14 M0,14 Q-6,20 -11,16 M0,14 Q6,20 11,16" stroke="#1b2a49" stroke-width="2.2" fill="none" stroke-linecap="round"/>' + shine('M-18,-14 C-14,-20 -8,-22 -2,-22 C-10,-16 -14,-8 -16,0Z', .5))
def phoenix():
    wl = 'M0,-2 C-10,-16 -28,-22 -42,-18 C-36,-12 -30,-6 -34,2 C-26,0 -20,2 -22,10 C-14,6 -8,8 -6,16 C-4,10 0,6 0,-2Z'
    wr = 'M0,-2 C10,-16 28,-22 42,-18 C36,-12 30,-6 34,2 C26,0 20,2 22,10 C14,6 8,8 6,16 C4,10 0,6 0,-2Z'
    return (f'<path d="{wl}" fill="url(#iFire)" {O}/><path d="{wr}" fill="url(#iFire)" {O}/>'
            + pth('M-8,40 C-14,30 -10,22 0,14 C10,22 14,30 8,40 C4,34 2,30 0,28 C-2,30 -4,34 -8,40Z', 'url(#iFire)') + pth('M-3,40 C-5,34 -2,30 0,26 C2,30 5,34 3,40Z', 'url(#iFire2)', stroke=False)
            + ell(0, 4, 11, 16, 'url(#iGold)') + f'<circle cx="0" cy="-14" r="9" fill="url(#iGold)" {O}/>' + '<path d="M-3,-22 C-6,-32 -2,-36 2,-34 M2,-22 C2,-32 8,-36 11,-32" stroke="#FFD36A" stroke-width="3" fill="none" stroke-linecap="round"/>'
            + '<circle cx="-3" cy="-15" r="1.8" fill="#1b2a49"/><circle cx="3" cy="-15" r="1.8" fill="#1b2a49"/>' + pth('M-2.4,-11 H2.4 L0,-6.5Z', 'url(#iRed)', stroke=False))
def star_ribbon():
    return ('<path d="M-16,12 L-26,40 L-14,34 L-8,42 L0,18Z M16,12 L26,40 L14,34 L8,42 L0,18Z" fill="url(#iRed)" ' + O + '/>'
            + '<path d="M0,-36 l8,16 l18,2.6 l-13,12.6 l3,17.8 l-16,-8.4 l-16,8.4 l3,-17.8 l-13,-12.6 l18,-2.6z" fill="url(#iGold)" ' + O + ' transform="translate(0 4) scale(.98)"/>'
            + '<circle cx="-6" cy="2" r="2.4" fill="#1b2a49"/><circle cx="6" cy="2" r="2.4" fill="#1b2a49"/><path d="M-4,8 Q0,12 4,8" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>' + shine('M-8,-22 L0,-32 L6,-22Z', .6))
def crown_cute():
    return (pth('M-30,24 L-34,-14 L-16,2 L0,-26 L16,2 L34,-14 L30,24Z', 'url(#iGold)') + pth('M-32,24 H32 V34 H-32Z', 'url(#iGold)')
            + '<circle cx="-34" cy="-16" r="4" fill="url(#iGold)" ' + O + '/><circle cx="34" cy="-16" r="4" fill="url(#iGold)" ' + O + '/><circle cx="0" cy="-28" r="4.4" fill="url(#iGold)" ' + O + '/>'
            + '<circle cx="-16" cy="26" r="3.4" fill="#E8481A"/><circle cx="0" cy="26" r="3.8" fill="#2F6FD0"/><circle cx="16" cy="26" r="3.4" fill="#2EA06A"/>' + '<path d="M0,-4 l4,8 l9,1 l-6.5,6 l1.8,9 l-8.3,-4.4 l-8.3,4.4 l1.8,-9 l-6.5,-6 l9,-1z" fill="#FFF3C4" opacity=".9" transform="translate(0 2) scale(.7)"/>' + shine('M-26,18 L-30,-8 L-18,4 L-16,10Z', .5))
def winged_crown():
    wing = lambda s: ''.join(f'<path d="M{s*30},{y} C{s*40},{y-10} {s*46},{y-4} {s*50},{y-14 + i*3}" stroke="#FFF1B8" stroke-width="4" fill="none" stroke-linecap="round" opacity="{1 - i*.18}"/>' for i, y in enumerate((8, 16, 24)))
    return wing(-1) + wing(1) + '<g transform="scale(.82) translate(0 4)">' + crown_cute() + '</g>'
def phoenix():
    return ('<path d="M0,-6 C-20,-8 -38,-26 -44,-40 C-30,-36 -16,-28 -6,-18Z M0,-6 C20,-8 38,-26 44,-40 C30,-36 16,-28 6,-18Z" fill="url(#iFire)" ' + O + '/>'
            + '<path d="M0,-6 C-14,2 -26,16 -30,34 C-16,26 -6,18 0,12 C6,18 16,26 30,34 C26,16 14,2 0,-6Z" fill="url(#iFire)" ' + O + '/>'
            + pth('M0,-6 C-6,-6 -10,-12 -8,-20 C-6,-28 4,-30 8,-22 C10,-16 6,-6 0,-6Z', 'url(#iGold)') + '<path d="M-2,-30 C-4,-38 2,-42 6,-40 M2,-28 C6,-36 12,-36 14,-32" stroke="#FFD36A" stroke-width="3" fill="none" stroke-linecap="round"/>'
            + '<circle cx="-2" cy="-18" r="2" fill="#1b2a49"/>' + pth('M-8,-14 L-14,-11 L-8,-9Z', 'url(#iRed)', stroke=False) + '<path d="M0,12 C-4,24 -2,34 0,40 C2,34 4,24 0,12Z" fill="url(#iFire2)" opacity=".9"/>')
ICONS3 = dict(moon=crescent_moon, sunrise=sunrise, fox=fox, whale=whale, tomato_timer=tomato_timer, ant=ant, acorn=acorn, wheat=wheat, apples=apple_basket, honey=honey_pot, hive=beehive, turtle=turtle, queen=queen_bee,
              book_ribbon=open_book_ribbon, books_tea=books_tea, glasses=glasses, shelf=bookshelf, quill=quill, lamp_read=reading_lamp, book_sprout=book_sprout, ladder=ladder, medal=medal, podium=podium,
              padlock=padlock, calendar=calendar_smile, full_moon=full_moon, egg=hatching_egg, chick=chick, robin=robin, lion=lion, star_ribbon=star_ribbon, crown=crown_cute, wcrown=winged_crown, phoenix=phoenix)
