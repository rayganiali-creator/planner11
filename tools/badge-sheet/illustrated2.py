# دستهٔ دوم موضوع‌ها، هم‌سبکِ جغد/شمع/فانوس: ساده، گرد، با کمی شخصیت.
from illustrated import O, ell, pth, shine, flame
from make_sheet import P, f

def faceDots(x1, x2, y, r=2.4, smile=True, sy=None):
    s = f'<circle cx="{x1}" cy="{y}" r="{r}" fill="#1b2a49"/><circle cx="{x2}" cy="{y}" r="{r}" fill="#1b2a49"/>'
    if smile: s += f'<path d="M{x1+1},{(sy or y+5)} Q{(x1+x2)/2},{(sy or y+5)+5} {x2-1},{(sy or y+5)}" stroke="#1b2a49" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
    return s

def seedling_pot():
    return ('<path d="M0,6 V-14" stroke="#6B4126" stroke-width="3" stroke-linecap="round"/>'
            + pth('M0,-12 C-6,-32 -28,-32 -32,-22 C-28,-8 -10,-6 0,-12Z', 'url(#iGold)') + pth('M0,-17 C4,-38 26,-40 32,-30 C28,-14 10,-12 0,-17Z', 'url(#iGold)')
            + '<path d="M-6,-14 C-14,-18 -22,-22 -26,-24 M6,-20 C14,-24 20,-28 26,-30" stroke="#B97C0A" stroke-width="1.6" fill="none" opacity=".7"/>'
            + pth('M-17,10 H17 L13,34 C13,36 11,37 9,37 H-9 C-11,37 -13,36 -13,34Z', 'url(#iBrown)') + pth('M-21,3 H21 V11 H-21Z', 'url(#iBrown)') + shine('M-17,11 H-12 L-10,33 H-13Z', .35)
            + faceDots(-6, 6, 20, 2.2, True, 25))

def genie_lamp():
    return (pth('M-24,12 C-24,-2 -2,-6 14,-2 C24,0 28,6 26,12 C22,22 -18,24 -24,12Z', 'url(#iGold)')
            + pth('M-22,6 C-34,6 -40,-2 -36,-12 L-31,-10 C-32,-4 -28,0 -20,0Z', 'url(#iGold)') + '<path d="M24,6 C38,0 42,14 28,18" stroke="#E5A400" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
            + pth('M-9,-2 C-9,-14 9,-14 9,-2Z', 'url(#iGold)') + '<circle cx="0" cy="-17" r="3.4" fill="#FFE27A"/>' + pth('M-10,22 H10 L7,29 H-7Z', 'url(#iGold)')
            + '<path d="M-38,-14 C-30,-24 -42,-30 -30,-38" stroke="#FFF1B8" stroke-width="3" fill="none" stroke-linecap="round" opacity=".9"/>'
            + '<path d="M-30,-38 l2,4 l4,2 l-4,2 l-2,4 l-2,-4 l-4,-2 l4,-2z" fill="#FFF6D0"/>' + shine('M-18,4 C-12,-2 0,-3 8,-1 C-2,1 -12,4 -18,10Z', .5))
def lighthouse():
    return ('<path d="M-6,-19 L-44,-31 L-44,-7 Z" fill="#FFF1B8" opacity=".35"/><path d="M6,-19 L44,-31 L44,-7 Z" fill="#FFF1B8" opacity=".35"/>'
            + ell(0, 36, 22, 5, 'url(#iBrown)') + pth('M-11,34 L-7,-10 H7 L11,34Z', 'url(#iPaper)') + '<path d="M-9.5,12 L-8.3,2 H8.3 L9.5,12Z M-10.6,28 L-9.8,19 H9.8 L10.6,28Z" fill="#1b2a49" opacity=".85"/>'
            + pth('M-13,-10 H13 V-6 H-13Z', 'url(#iGold)') + pth('M-7,-26 H7 V-10 H-7Z', 'url(#iGlass)') + '<rect x="-4" y="-24" width="8" height="12" rx="3" fill="#FFE27A"/>'
            + pth('M-10,-26 L0,-39 L10,-26Z', 'url(#iRed)') + '<circle cx="0" cy="-41" r="2.2" fill="#FFE27A"/>' + shine('M-9,30 L-6,-8 H-4 L-6,30Z', .5))
def firefly_jar():
    fl = ''.join(f'<g transform="translate({x} {y})"><circle r="9" fill="url(#iGlow)"/><circle r="2.8" fill="#FFE27A"/><ellipse cx="-3" cy="-3" rx="3" ry="1.6" fill="#fff" opacity=".7" transform="rotate(-30 -3 -3)"/><ellipse cx="3" cy="-3" rx="3" ry="1.6" fill="#fff" opacity=".7" transform="rotate(30 3 -3)"/></g>' for x, y in ((-7, -2), (8, 6), (-2, 18), (9, -12), (-10, 24)))
    return (pth('M-18,-12 H18 C22,-12 24,-8 24,-4 V26 C24,34 18,38 10,38 H-10 C-18,38 -24,34 -24,26 V-4 C-24,-8 -22,-12 -18,-12Z', 'url(#iGlass)') + fl
            + pth('M-17,-24 H17 V-12 H-17Z', 'url(#iGold)') + '<path d="M-17,-18 H17" stroke="#B97C0A" stroke-width="1.6" opacity=".6"/>' + shine('M-18,-6 C-20,6 -20,20 -17,32 C-22,22 -22,4 -18,-6Z', .5))
def tree_of_life():
    fruits = ''.join(f'<circle cx="{x}" cy="{y}" r="3.2" fill="url(#iGold)"/>' for x, y in ((-18, -12), (-6, -26), (10, -22), (20, -8), (0, -8), (-22, 4), (14, 6)))
    return (f'<circle cy="-8" r="38" fill="url(#iGlow)"/>' + pth('M-4,38 C-3,24 -3,14 -2,4 H2 C3,14 3,24 4,38 C8,38 14,36 18,38 M-4,38 C-8,38 -14,36 -18,38', 'none', 'stroke-width="3" stroke="#6B4126"', False)
            + pth('M-5,36 C-3,22 -3,12 -2,2 H2 C3,12 3,22 5,36Z', 'url(#iBrown)')
            + pth('M-20,-6 C-34,-8 -34,-28 -20,-30 C-20,-42 4,-44 8,-32 C22,-38 34,-24 24,-12 C32,-4 20,6 8,2 C0,8 -14,6 -20,-6Z', 'url(#iGold)') + fruits
            + shine('M-22,-28 C-14,-36 0,-38 6,-32 C-4,-32 -16,-26 -22,-18Z', .5))
def bee():
    return ('<ellipse cx="-12" cy="-14" rx="12" ry="7" fill="#fff" opacity=".85" transform="rotate(-25 -12 -14)"/><ellipse cx="12" cy="-14" rx="12" ry="7" fill="#fff" opacity=".85" transform="rotate(25 12 -14)"/>'
            + '<path d="M-6,-24 C-8,-32 -12,-34 -14,-34 M6,-24 C8,-32 12,-34 14,-34" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/><circle cx="-14" cy="-34" r="2" fill="#1b2a49"/><circle cx="14" cy="-34" r="2" fill="#1b2a49"/>'
            + ell(0, 6, 22, 26, 'url(#iGold)') + '<path d="M-21,-4 C-8,0 8,0 21,-4 M-22,10 C-8,15 8,15 22,10 M-17,23 C-6,28 6,28 17,23" stroke="#1b2a49" stroke-width="6" fill="none" opacity=".92"/>'
            + pth('M-3,30 L0,40 L3,30Z', '#1b2a49') + ell(0, -16, 15, 13, 'url(#iGold)') + faceDots(-6, 6, -17, 2.8, True, -11) + shine('M-14,-4 C-16,6 -14,18 -10,24 C-16,16 -18,4 -14,-4Z', .5))
def koi():
    return ('<path d="M-36,2 C-26,-18 8,-20 24,-4 C30,-10 36,-18 38,-28 C40,-14 40,6 38,18 C36,10 30,4 24,6 C8,20 -26,18 -36,2Z" fill="url(#iGold)" stroke="#1a1030" stroke-opacity=".3" stroke-width="1.6" stroke-linejoin="round"/>'
            + '<path d="M-6,-12 C0,-24 14,-26 18,-18 C10,-18 2,-14 -6,-12Z M-4,14 C0,24 12,26 16,20 C8,20 2,18 -4,14Z" fill="url(#iGold)" opacity=".9" stroke="#1a1030" stroke-opacity=".25" stroke-width="1.2"/>'
            + '<path d="M-12,-8 C-8,-2 -8,6 -12,12 M-2,-9 C2,-3 2,7 -2,13 M8,-7 C11,-2 11,5 8,10" stroke="#1b2a49" stroke-width="2" fill="none" opacity=".55" stroke-linecap="round"/>'
            + '<circle cx="-26" cy="-2" r="3.6" fill="#fff"/><circle cx="-26.4" cy="-2" r="1.8" fill="#1b2a49"/>' + '<path d="M-38,24 C-26,30 -10,30 4,24 M-30,32 C-20,36 -8,36 2,32" stroke="#FFF1B8" stroke-width="2" fill="none" stroke-linecap="round" opacity=".6"/>')
def lotus_frog():
    petals = ''.join(f'<path d="M0,0 C-8,-12 -8,-24 0,-34 C8,-24 8,-12 0,0Z" fill="url(#iPaper)" stroke="#1a1030" stroke-opacity=".3" stroke-width="1.4" transform="translate(0 34) rotate({a})"/>' for a in (-60, -30, 30, 60, 0))
    return (petals + ell(0, 36, 34, 6, 'url(#iGold)') + ell(0, 0, 18, 15, 'url(#iGold)')
            + f'<circle cx="-11" cy="-14" r="7" fill="url(#iGold)" {O}/><circle cx="11" cy="-14" r="7" fill="url(#iGold)" {O}/><circle cx="-11" cy="-14" r="4.2" fill="#fff"/><circle cx="11" cy="-14" r="4.2" fill="#fff"/><circle cx="-11" cy="-13" r="2.2" fill="#1b2a49"/><circle cx="11" cy="-13" r="2.2" fill="#1b2a49"/>'
            + '<path d="M-9,2 Q0,10 9,2" stroke="#1b2a49" stroke-width="2.2" fill="none" stroke-linecap="round"/>' + shine('M-14,-4 C-10,-8 -4,-10 0,-9 C-6,-6 -10,0 -12,6Z', .5))
def tomato():
    return (ell(0, 8, 30, 27, 'url(#iFire)') + '<path d="M-6,-16 L0,-8 L6,-16 L14,-12 L8,-4 L16,2 L8,2 L0,6 L-8,2 L-16,2 L-8,-4 L-14,-12Z" fill="#1b2a49" opacity=".0"/>'
            + pth('M0,-18 C-4,-24 -14,-22 -18,-16 C-10,-14 -6,-10 0,-12 C6,-10 10,-14 18,-16 C14,-22 4,-24 0,-18Z', 'url(#iBrown)') + '<path d="M0,-18 V-28" stroke="#6B4126" stroke-width="3.4" stroke-linecap="round"/>'
            + shine('M-22,-2 C-20,-14 -10,-18 -4,-16 C-14,-12 -20,-6 -22,6Z', .55) + faceDots(-9, 9, 6, 2.6, True, 13) + '<path d="M-16,22 C-8,28 8,28 16,22" stroke="#fff" stroke-width="2" fill="none" opacity=".35" stroke-linecap="round"/>')
def bookworm():
    seg = ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#iGold)" {O}/>' for x, y, r in ((-20, 12, 6), (-10, 6, 7), (2, 2, 8), (14, -2, 9)))
    return (pth('M0,18 C-12,10 -28,12 -36,16 V34 C-28,30 -12,30 0,36Z', 'url(#iPaper)') + pth('M0,18 C12,10 28,12 36,16 V34 C28,30 12,30 0,36Z', '#EEF1FA') + '<path d="M0,18 V36" stroke="#8fa0c8" stroke-width="2"/>'
            + seg + '<circle cx="22" cy="-12" r="11" fill="url(#iGold)" ' + O + '/>'
            + '<circle cx="18" cy="-14" r="4.6" fill="none" stroke="#1b2a49" stroke-width="2"/><circle cx="28" cy="-14" r="4.6" fill="none" stroke="#1b2a49" stroke-width="2"/><path d="M22.6,-14 H23.4" stroke="#1b2a49" stroke-width="2"/><circle cx="18" cy="-14" r="1.6" fill="#1b2a49"/><circle cx="28" cy="-14" r="1.6" fill="#1b2a49"/>'
            + '<path d="M18,-6 Q23,-2 28,-6" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/><path d="M18,-22 C16,-30 12,-32 10,-32 M26,-23 C26,-30 30,-33 32,-33" stroke="#1b2a49" stroke-width="2" fill="none" stroke-linecap="round"/>')
def gem():
    return (f'<circle r="38" fill="url(#iGlow)"/>' + pth('M-30,-8 L-18,-26 H18 L30,-8 L0,34Z', 'url(#iBlue)')
            + '<path d="M-30,-8 H30 M-18,-26 L-8,-8 L0,34 M18,-26 L8,-8 L0,34 M-8,-8 L0,-26 L8,-8" stroke="#fff" stroke-opacity=".6" stroke-width="1.8" fill="none" stroke-linejoin="round"/>'
            + '<path d="M-18,-26 L-8,-8 L-30,-8Z" fill="#fff" opacity=".35"/><path d="M0,-26 L8,-8 H-8Z" fill="#fff" opacity=".55"/>' + '<path d="M30,-30 l2,5 l5,2 l-5,2 l-2,5 l-2,-5 l-5,-2 l5,-2z" fill="#FFF6D0"/>')
def summit():
    return (pth('M-40,34 L-14,-14 L2,12 L14,-6 L40,34Z', 'url(#iPaper)') + pth('M-14,-14 L-22,0 L-16,-3 L-12,3 L-7,-4 L-2,2Z', '#FFFFFF', stroke=False)
            + '<path d="M-14,-14 V-34" stroke="#1b2a49" stroke-width="2.6" stroke-linecap="round"/>' + pth('M-14,-34 H4 L-2,-28 L4,-22 H-14Z', 'url(#iRed)')
            + '<circle cx="26" cy="-24" r="7" fill="url(#iGold)"/>' + shine('M-34,30 L-16,-8 L-14,-4 L-28,30Z', .4))
ICONS2 = {'pot': seedling_pot, 'lamp': genie_lamp, 'lighthouse': lighthouse, 'jar': firefly_jar, 'tree': tree_of_life, 'bee': bee, 'koi': koi, 'frog': lotus_frog, 'tomato': tomato, 'worm': bookworm, 'gem': gem, 'summit': summit}
