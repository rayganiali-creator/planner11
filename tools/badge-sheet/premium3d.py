import sys,os,re; sys.path.insert(0,'/home/user/planner11/tools/badge-sheet'); os.chdir('/home/user/planner11/tools/badge-sheet'); os.environ['MOTIFS']='none'
import make_sheet as m, illustrated as il
ROWD={0:'#13295E',1:'#3A2A82',2:'#0F5A43'}
EXTRA='''<defs><linearGradient id="cham" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFBEF"/><stop offset=".55" stop-color="#F1DDB0"/><stop offset="1" stop-color="#C9A765"/></linearGradient>
<linearGradient id="gld" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFEFA0"/><stop offset=".5" stop-color="#F4BE3C"/><stop offset="1" stop-color="#B8780C"/></linearGradient>
<filter id="bev" x="-25%" y="-25%" width="150%" height="150%"><feGaussianBlur in="SourceAlpha" stdDeviation="1.7" result="b"/>
<feSpecularLighting in="b" surfaceScale="3.2" specularConstant="1" specularExponent="18" lighting-color="#ffffff" result="s"><fePointLight x="-30" y="-70" z="80"/></feSpecularLighting>
<feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/><feComposite in="SourceGraphic" in2="s2" operator="arithmetic" k1="0" k2="1" k3=".9" k4="0" result="m"/>
<feDropShadow in="m" dx="0" dy="2.2" stdDeviation="1.6" flood-color="#000" flood-opacity=".5"/></filter></defs>'''
def mat(svg,D):
    mp={'url(#iPaper)':'url(#cham)','url(#iWax)':'url(#cham)','url(#iSteel)':'url(#cham)','url(#iGold)':'url(#gld)','url(#iSand)':'url(#gld)','url(#iFire)':'url(#gld)','url(#iFire2)':'#FFF6D0','url(#iRed)':'url(#gld)','url(#iBlue)':D,'url(#iBrown)':'url(#cham)','url(#iWood)':'url(#cham)','url(#iGlass)':D,'url(#iGlow)':'none','#14264E':D,'#1b2a49':D,'#5a3a2a':D,'#B97C0A':D,'#C98A0C':'url(#gld)','#D9A21B':'url(#gld)','#6B4126':D,'#E8C79A':'url(#gld)','#F6C443':'url(#gld)','#9aa6c4':D,'#c9d2e8':'#E6D9B8','#8fa0c8':D,'#2EA06A':D,'#E0A33A':'url(#gld)','#EEF1FA':'url(#cham)','#FFF8E6':'url(#cham)','#FFFDF4':'url(#cham)','#FFE9A0':'#FFF4C6','#1a1030':D}
    for k,v in mp.items(): svg=svg.replace(k,v)
    svg=svg.replace('stroke-opacity=".38"','stroke-opacity="0"')
    # stroke="url(#..)" ممنوع → رنگ ساده
    svg=re.sub(r'stroke="url\(#(?:gld|cham)\)"','stroke="#F4D27A"',svg)
    return svg
def render(ids_rows, out, title=None):
    cols=4; size=300; n=len(ids_rows); rows=(n+cols-1)//cols; W=cols*size; H=rows*size
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{m.SHARED_DEFS}</defs><rect width="{W}" height="{H}" fill="#F3F1EC"/><style>']
    for k,(n_,row,tier) in enumerate(ids_rows): svg.append(m.symbol_style(row*8+1+(k%4),f'b{k}'))
    svg.append('</style>')
    for k,(n_,row,tier) in enumerate(ids_rows):
        i=row*8+1+(k%4)
        g=m.G(); g.add(il.DEFS); g.add(EXTRA); g.add(f'<g filter="url(#bev)"><g transform="scale(1.12)">{mat(il.ICONS[n_][1](),ROWD[row])}</g></g>')
        m.motif=lambda _i,g=g: g
        m.TIERS=list(m.TIERS); m.TIERS[i-1]=tier; m.FRAMES[i]='circle'
        r,c=divmod(k,cols)
        svg.append(f'<g transform="translate({c*size+size/2} {r*size+size/2}) scale({size*0.78/200})">{m.badge_svg(i,f"b{k}")}</g>')
    svg.append('</svg>'); open(out+'.svg','w').write('\n'.join(svg))
    from playwright.sync_api import sync_playwright
    with sync_playwright() as pw:
        b=pw.chromium.launch(executable_path='/opt/pw-browsers/chromium-1194/chrome-linux/chrome'); pg=b.new_page(viewport={'width':W,'height':H},device_scale_factor=1.4)
        pg.goto('file://'+os.path.abspath(out+'.svg')); pg.wait_for_timeout(400); pg.screenshot(path=out+'.png'); b.close()
if __name__=='__main__':
    sel=[(1,0,'bronze'),(2,0,'silver'),(3,0,'gold'),(4,0,'legendary'),(5,1,'bronze'),(6,1,'silver'),(7,1,'gold'),(8,1,'legendary'),(9,2,'bronze'),(10,2,'silver'),(11,2,'gold'),(12,2,'legendary')]
    render(sel,'out/premium3d-sample')
