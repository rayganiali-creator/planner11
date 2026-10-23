# نمونه‌ی «تصویرسازی‌شده»: هر نشان یک موضوعِ آشنا و منحصربه‌فرد دارد (شمع، فانوس، آتش، خورشید، چشم، هدف، ساعت شنی، جغد، موشک، جام…).
from make_sheet import G, P, f

DEFS = '''<defs>
<linearGradient id="iGold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF3B0"/><stop offset=".45" stop-color="#F6C443"/><stop offset="1" stop-color="#B97C0A"/></linearGradient>
<linearGradient id="iFire" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE27A"/><stop offset=".5" stop-color="#FF9A2E"/><stop offset="1" stop-color="#E8481A"/></linearGradient>
<linearGradient id="iFire2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFBE0"/><stop offset="1" stop-color="#FFC24A"/></linearGradient>
<linearGradient id="iWax" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F3E7CF"/><stop offset=".5" stop-color="#FFFDF4"/><stop offset="1" stop-color="#D9C7A3"/></linearGradient>
<linearGradient id="iWood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C98A52"/><stop offset="1" stop-color="#7A4A26"/></linearGradient>
<linearGradient id="iGlass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF6D6" stop-opacity=".95"/><stop offset="1" stop-color="#FFC15A" stop-opacity=".55"/></linearGradient>
<linearGradient id="iSteel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#A9B6CC"/></linearGradient>
<linearGradient id="iPaper" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#DDE3F2"/></linearGradient>
<linearGradient id="iRed" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF7B6B"/><stop offset="1" stop-color="#C2352B"/></linearGradient>
<linearGradient id="iBlue" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8FD3FF"/><stop offset="1" stop-color="#2F6FD0"/></linearGradient>
<linearGradient id="iBrown" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B07A4C"/><stop offset="1" stop-color="#6B4126"/></linearGradient>
<radialGradient id="iGlow"><stop offset="0" stop-color="#FFE9A8" stop-opacity=".85"/><stop offset="1" stop-color="#FFE9A8" stop-opacity="0"/></radialGradient>
<linearGradient id="iSand" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE29A"/><stop offset="1" stop-color="#E0A33A"/></linearGradient>
</defs>'''
O = 'stroke="#1a1030" stroke-opacity=".38" stroke-width="1.6" stroke-linejoin="round"'
def ell(cx, cy, rx, ry, fill, extra=''): return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" {O} {extra}/>'
def pth(d, fill, extra='', stroke=True): return f'<path d="{d}" fill="{fill}" {O if stroke else ""} {extra}/>'
def shine(d, op=.45): return f'<path d="{d}" fill="#fff" fill-opacity="{op}"/>'
def flame(cx, cy, s):
    return (f'<g transform="translate({cx} {cy}) scale({s})">' + pth('M0,-26 C4,-16 15,-11 15,3 C15,15 8,24 0,24 C-8,24 -15,15 -15,3 C-15,-4 -10,-9 -6,-13 C-5,-6 -2,-3 0,-26Z', 'url(#iFire)')
            + pth('M0,2 C3,7 7,10 7,16 C7,21 4,23 0,23 C-4,23 -7,21 -7,16 C-7,11 -3,8 0,2Z', 'url(#iFire2)', stroke=False) + '</g>')

def candle():
    return (ell(0, 33, 20, 6, 'url(#iGold)') + pth('M-10,-6 H10 V32 H-10Z', 'url(#iWax)') + ell(0, -6, 10, 3.4, '#FFFDF4')
            + pth('M-10,2 C-10,8 -6,8 -6,14 L-6,2Z', '#fff', 'fill-opacity=".7"', False) + '<path d="M0,-6 V-12" stroke="#5a3a2a" stroke-width="2" stroke-linecap="round"/>'
            + flame(0, -24, 0.55) + f'<circle cx="0" cy="-22" r="22" fill="url(#iGlow)"/>')
def lantern():
    return ('<path d="M-12,-24 C-12,-40 12,-40 12,-24" fill="none" stroke="#C98A0C" stroke-width="3" stroke-linecap="round"/>'
            + pth('M-14,-24 H14 L10,-18 H-10Z', 'url(#iGold)') + pth('M-10,-18 H10 L14,22 H-14Z', 'url(#iGlass)')
            + '<path d="M-5,-18 L-8,22 M5,-18 L8,22" stroke="#B97C0A" stroke-width="2" opacity=".8"/>'
            + flame(0, 2, 0.5) + pth('M-16,22 H16 L13,30 H-13Z', 'url(#iGold)') + shine('M-9,-14 L-7,6 L-11,6Z', .5))
def campfire():
    return ('<g>' + f'<rect x="-30" y="16" width="60" height="9" rx="4.5" fill="url(#iWood)" {O} transform="rotate(18 0 20)"/>'
            + f'<rect x="-30" y="16" width="60" height="9" rx="4.5" fill="url(#iBrown)" {O} transform="rotate(-18 0 20)"/>' + '</g>' + flame(0, -2, 1.15)
            + ell(-10, 21, 4, 4, '#9a6a44', 'opacity=".0"'))
def sun():
    rays = ''.join(f'<path d="M0,-44 L5,-31 H-5Z" fill="url(#iGold)" {O} transform="rotate({a})"/>' for a in range(0, 360, 30))
    return (rays + f'<circle r="26" fill="url(#iGold)" {O}/>' + '<circle r="18" fill="#FFE9A0" opacity=".55"/>' + shine('M-16,-12 A20,20 0 0 1 4,-22 C-6,-18 -14,-8 -16,-12Z', .6))
def eye():
    return (pth('M-40,0 C-24,-26 24,-26 40,0 C24,26 -24,26 -40,0Z', '#FFFFFF') + f'<circle r="15" fill="url(#iBlue)" {O}/>' + '<circle r="8" fill="#14264E"/>' + '<circle cx="-4" cy="-5" r="3.4" fill="#fff"/>'
            + '<path d="M-34,-6 L-40,-12 M-20,-17 L-24,-25 M0,-21 L0,-30 M20,-17 L24,-25 M34,-6 L40,-12" stroke="#fff" stroke-width="2.6" stroke-linecap="round" opacity=".9"/>')
def bullseye():
    return (f'<circle r="36" fill="#fff" {O}/>' + '<circle r="28" fill="url(#iRed)"/><circle r="20" fill="#fff"/><circle r="12" fill="url(#iRed)"/><circle r="5" fill="#fff"/>'
            + '<path d="M0,0 L30,-30" stroke="#6B4126" stroke-width="3.6" stroke-linecap="round"/>' + pth('M30,-30 L40,-34 L36,-24Z', 'url(#iSteel)') + '<path d="M22,-22 L18,-32 M26,-26 L16,-30 M22,-22 L32,-18 M26,-26 L30,-14" stroke="#F6C443" stroke-width="3" stroke-linecap="round"/>')
def hourglass():
    return (pth('M-22,-34 H22 V-30 H-22Z', 'url(#iGold)') + pth('M-22,32 H22 V36 H-22Z', 'url(#iGold)')
            + pth('M-18,-30 H18 C18,-10 6,-4 3,0 C6,4 18,10 18,30 H-18 C-18,10 -6,4 -3,0 C-6,-4 -18,-10 -18,-30Z', 'url(#iGlass)')
            + pth('M-12,-26 H12 C11,-14 4,-8 0,-5 C-4,-8 -11,-14 -12,-26Z', 'url(#iSand)', stroke=False) + pth('M-14,28 C-13,16 -6,10 0,10 C6,10 13,16 14,28Z', 'url(#iSand)', stroke=False)
            + '<path d="M0,-3 V10" stroke="#E0A33A" stroke-width="1.6"/>' + shine('M-14,-26 C-14,-12 -8,-6 -6,-2 C-12,-8 -15,-16 -14,-26Z', .55))
def owl():
    return (pth('M-24,-8 C-24,-30 -8,-36 0,-36 C8,-36 24,-30 24,-8 V18 C24,32 12,38 0,38 C-12,38 -24,32 -24,18Z', 'url(#iBrown)')
            + pth('M-24,-26 L-16,-34 L-10,-30Z M24,-26 L16,-34 L10,-30Z', 'url(#iBrown)') + pth('M-12,14 C-8,22 8,22 12,14 C12,26 -12,26 -12,14Z', '#E8C79A', stroke=False)
            + f'<circle cx="-11" cy="-8" r="11" fill="#FFF8E6" {O}/><circle cx="11" cy="-8" r="11" fill="#FFF8E6" {O}/><circle cx="-11" cy="-7" r="5.6" fill="#1b2a49"/><circle cx="11" cy="-7" r="5.6" fill="#1b2a49"/><circle cx="-9" cy="-9" r="1.8" fill="#fff"/><circle cx="13" cy="-9" r="1.8" fill="#fff"/>'
            + pth('M-4,2 L4,2 L0,10Z', 'url(#iGold)') + '<path d="M-14,26 l-4,8 M-6,28 l-3,8 M6,28 l3,8 M14,26 l4,8" stroke="#F6C443" stroke-width="2.6" stroke-linecap="round"/>')
def rocket():
    return ('<g transform="rotate(35)">' + pth('M-12,18 L-24,34 L-8,28Z M12,18 L24,34 L8,28Z', 'url(#iRed)') + pth('M0,-40 C14,-26 14,6 10,24 H-10 C-14,6 -14,-26 0,-40Z', 'url(#iPaper)')
            + pth('M0,-40 C8,-34 12,-26 12,-20 H-12 C-12,-26 -8,-34 0,-40Z', 'url(#iRed)') + f'<circle cx="0" cy="-4" r="7" fill="url(#iBlue)" {O}/><circle cx="-2" cy="-6" r="2" fill="#fff" opacity=".8"/>'
            + pth('M-8,24 H8 L0,40Z', 'url(#iFire)') + '</g>')
def checklist():
    return (pth('M-24,-34 H18 L26,-26 V34 H-24Z', 'url(#iPaper)') + '<path d="M18,-34 V-26 H26" fill="#c9d2e8" stroke="none"/>'
            + '<path d="M-16,-14 l4,4 l8,-9 M-16,6 l4,4 l8,-9" stroke="#2EA06A" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            + '<path d="M0,-12 H16 M0,8 H16 M-16,26 H16" stroke="#9aa6c4" stroke-width="3.4" stroke-linecap="round"/>'
            + '<g transform="rotate(40 20 20)">' + pth('M16,-4 H24 V30 L20,38 L16,30Z', 'url(#iGold)') + pth('M16,-4 H24 V2 H16Z', 'url(#iRed)') + '</g>')
def finish_flag():
    sq = ''.join(f'<rect x="{-14 + (i % 4) * 9}" y="{-34 + (i // 4) * 9}" width="9" height="9" fill="{"#1a1030" if (i % 4 + i // 4) % 2 == 0 else "#fff"}"/>' for i in range(12))
    return ('<path d="M-18,38 V-36" stroke="#DDE3F2" stroke-width="5" stroke-linecap="round"/><path d="M-19.5,38 V-36" stroke="#8f9bb8" stroke-width="1.4" stroke-linecap="round"/>' + f'<g transform="translate(0 0)"><path d="M-16,-34 H22 V-4 H-16Z" fill="#fff" {O}/><g transform="translate(-2 0)">{sq}</g></g>'
            + '<circle cx="-18" cy="-37" r="4" fill="url(#iGold)"/>' + ell(-18, 38, 12, 3.6, 'url(#iGold)'))

def trophy():
    return (pth('M-22,-30 H22 V-6 C22,12 10,20 0,20 C-10,20 -22,12 -22,-6Z', 'url(#iGold)') + '<path d="M-22,-24 H-34 C-34,-8 -28,0 -18,2 M22,-24 H34 C34,-8 28,0 18,2" fill="none" stroke="#D9A21B" stroke-width="4" stroke-linecap="round"/>'
            + pth('M-5,20 H5 V28 H-5Z', 'url(#iGold)') + pth('M-16,28 H16 V36 H-16Z', 'url(#iGold)') + '<path d="M0,-22 l4.5,9 l10,1.4 l-7.3,7 l1.8,10 l-9,-4.8 l-9,4.8 l1.8,-10 l-7.3,-7 l10,-1.4z" fill="#FFF3B0" opacity=".9"/>' + shine('M-18,-26 V-6 C-18,2 -14,8 -10,12 C-14,2 -14,-10 -14,-26Z', .5))
def reader():
    return (f'<circle cy="-4" r="36" fill="url(#iGlow)"/>' + pth('M0,-8 C-12,-18 -28,-16 -36,-12 V26 C-28,22 -12,22 0,30Z', 'url(#iPaper)') + pth('M0,-8 C12,-18 28,-16 36,-12 V26 C28,22 12,22 0,30Z', '#EEF1FA')
            + '<path d="M0,-8 V30" stroke="#8fa0c8" stroke-width="2"/><path d="M-30,-4 C-20,-5 -10,-3 -5,2 M-30,6 C-20,5 -10,7 -5,12 M5,2 C10,-3 20,-5 30,-4 M5,12 C10,7 20,5 30,6" stroke="#9aa6c4" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
            + '<path d="M0,-18 l3,-8 M-10,-15 l-5,-7 M10,-15 l5,-7" stroke="#F6C443" stroke-width="3" stroke-linecap="round"/>' + f'<circle cx="0" cy="-26" r="4" fill="url(#iGold)"/>')

ICONS = {1: ('candle', candle), 2: ('lantern', lantern), 3: ('campfire', campfire), 4: ('sun', sun), 5: ('eye', eye), 6: ('bullseye', bullseye), 7: ('hourglass', hourglass), 8: ('owl', owl),
         9: ('checklist', checklist), 10: ('rocket', rocket), 11: ('finish', finish_flag), 12: ('trophy', trophy), 13: ('reader', reader)}
