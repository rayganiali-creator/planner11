# -*- coding: utf-8 -*-
"""پیش‌نمایشِ Design System را می‌سازد (HTML مستقل، بدون وابستگی بیرونی).
   آواتارها از خودِ برنامه‌ی فعلی گرفته می‌شوند (tools/design-preview/grab_avatars.py)،
   فونت و آیکون‌ها از خودِ www/index.html.
   استفاده:  python3 tools/design-preview/build_preview.py [خروجی]
"""
import base64, io, os, re, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
OUT = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'docs' / 'flutter-migration' / 'design-preview.html'
AV = pathlib.Path(os.environ.get('RP_AV_DIR', '/tmp/dsprev'))

tpl = io.open(HERE / 'template.html', encoding='utf-8').read()
b64 = lambda p: base64.b64encode(open(p, 'rb').read()).decode()
www = io.open(ROOT / 'www' / 'index.html', encoding='utf-8').read()

# ---- آیکون‌ها: فقط سمبل‌هایی که استفاده می‌شوند ----
USED = ('house target plus calendar-days calendar-range square-check timer trophy flame heart coins star sun moon-star '
        'droplet dumbbell book-open brain cup-soda library wallet notebook-pen zap chart-column settings shirt '
        'check x arrow-left bell sparkles user-round flag clipboard-list palette moon').split()
syms = {m.group(1): m.group(0) for m in re.finditer(r'<symbol id="i-([\w-]+)".*?</symbol>', www, flags=re.S)}
missing = [u for u in USED if u not in syms]
ICONS = {u: syms[u] for u in USED if u in syms}
sprite = '<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>' + ''.join(ICONS.values()) + '</defs></svg>'


def ic(n, extra=''):
    return f'<svg class="ic" {extra}><use href="#i-{n}"/></svg>'


AVM = 'data:image/png;base64,' + b64(AV / 'av_male.png')
AVF = 'data:image/png;base64,' + b64(AV / 'av_female.png')


# ---- اجزای مشترک ----
def nav(active='home', fab_open=False):
    def it(k, icon, label):
        return f'<div class="it{" on" if active == k else ""}">{ic(icon)}<span>{label}</span></div>'
    return ('<div class="nav">' + it('home', 'house', 'خانه') + it('habits', 'target', 'عادت‌ها') +
            f'<div class="fab{" open" if fab_open else ""}">{ic("plus")}</div>' +
            it('month', 'calendar-days', 'تقویم') + it('todo', 'square-check', 'کارها') + '</div>')


def header(av, title='سلام، کاربر', sub='سه‌شنبه، ۸ مهر ۱۴۰۵', theme_icon='moon'):
    return (f'<div class="hdr"><div class="me"><img src="{av}" alt=""></div>'
            f'<div class="who"><small>{sub}</small><b>{title}</b></div>'
            f'<div class="iconbtn">{ic("bell")}</div><div class="iconbtn">{ic(theme_icon)}</div></div>')


def stage(av):
    return f'''<div class="stage"><div class="sky">
<div class="stars"></div><div class="sun"></div>
<span class="cloud" style="top:52px;width:74px;inset-inline-end:46px"></span>
<span class="cloud" style="top:104px;width:52px;inset-inline-start:84px"></span>
<div class="hills"></div><div class="ground"></div><div class="glow"></div><div class="shadow"></div>
<img class="hero-av" src="{av}" alt="">
<div class="lvl"><div class="badge"><b>۳</b></div><div><small>سطح حساب</small><strong>۶۲٪ تا سطح ۴</strong></div></div>
<div class="wardrobe"><button class="btn tonal sm" style="background:var(--glass);backdrop-filter:blur(14px);border:1px solid var(--glass-line);color:var(--text)">{ic("shirt")} کمد</button></div>
</div>
<div class="stats">
<div class="stat hp"><div class="top">{ic("heart")}HP</div><b>۸۶٪</b><div class="bar"><i style="width:86%"></i></div></div>
<div class="stat xp"><div class="top">{ic("star")}XP</div><b>۶۲۰</b><div class="bar"><i style="width:62%"></i></div></div>
<div class="stat coin"><div class="top">{ic("coins")}سکه</div><b>۲٬۶۲۰</b><div class="bar"><i style="width:62%;background:linear-gradient(90deg,var(--gold),#F1D27A)"></i></div></div>
<div class="stat fire"><div class="top">{ic("flame")}پیاپی</div><b>۱۲ <small style="font-size:11px;color:var(--muted);font-weight:600">روز</small></b><div class="bar"><i style="width:40%;background:linear-gradient(90deg,#F08A24,#F7B267)"></i></div></div>
</div></div>'''


def progress():
    heights = [58, 74, 100, 66, 82, 0, 0]
    bars = ''.join(
        f'<i class="{"on" if h and k != 4 else ""}{" fut" if not h else ""}" style="height:{max(h, 14)}%;{"background:linear-gradient(180deg,#F1D27A,var(--gold))" if k == 4 else ""}"></i>'
        for k, h in enumerate(heights))
    days = ''.join(f'<span>{d}</span>' for d in 'ش ی د س چ پ ج'.split())
    return f'''<div class="card"><div class="prog"><div class="ring" style="--v:75"><div><b>۷۵٪</b></div></div>
<div class="tx"><b>پیشرفت امروز</b><span>۶ از ۸ عادتِ امروز انجام شد</span>
<div style="display:flex;gap:6px;margin-top:10px"><span class="chip ok">{ic("check")}۶ موفق</span><span class="chip bad">{ic("x")}۱ ناموفق</span></div></div></div>
<div class="mini">{bars}</div><div class="days">{days}</div></div>'''


def habits():
    def row(icon, tint, name, meta, state):
        chk = {'ok': f'<div class="chk ok">{ic("check")}</div>', 'no': f'<div class="chk no">{ic("x")}</div>',
               'pend': f'<div class="chk">{ic("check")}</div>'}[state]
        return (f'<div class="habit"><div class="hi tint-{tint}">{ic(icon)}</div><div class="ht"><b>{name}</b>'
                f'<span>{ic("flame")}{meta}</span></div>{chk}</div>')
    return f'''<div class="card"><div class="sec-h"><b>عادت‌های امروز</b><a>همه {ic("chevron-left") if False else "‹"}</a></div>
{row("droplet", "e", "نوشیدن آب", "۱۲ روز · سطح ۲", "ok")}
{row("dumbbell", "d", "ورزش صبحگاهی", "۷ روز · سطح ۱", "ok")}
{row("book-open", "b", "مطالعه", "۳۲ از ۳۰ دقیقه", "ok")}
{row("brain", "a", "مدیتیشن", "هنوز ثبت نشده", "pend")}
{row("cup-soda", "c", "ترک نوشابه", "دیروز شکست خورد", "no")}</div>'''


def tiles():
    cal = ''.join(f'<i class="{c}"></i>' for c in
                  's s s f s s h s s s s s f s s s s t . . . .'.replace('.', 'x').split())
    cal = cal.replace('class="x"', 'style="background:transparent"')
    return f'''<div class="tiles">
<div class="tile"><span class="go">‹</span><div class="ti tint-a">{ic("square-check")}</div><div><b>لیست کارها</b><span>۳ کار باز · ۱ امروز</span></div></div>
<div class="tile pomo"><span class="go">‹</span><div class="ti">{ic("timer")}</div><div><div class="time">۲۵:۰۰</div><span>شروع تمرکز</span></div></div>
<div class="tile"><span class="go">‹</span><div class="ti tint-c">{ic("trophy")}</div><div><b>چالش‌ها</b><span>۲ چالش فعال</span></div><div class="bar" style="height:6px"><i style="width:64%;background:linear-gradient(90deg,var(--gold),#F1D27A)"></i></div></div>
<div class="tile"><span class="go">‹</span><div><b>مهر ۱۴۰۵</b><span>ثبت ماهانه</span></div><div class="cal">{cal}</div></div></div>'''


def dashboard(theme, av):
    return (f'<div><div class="fr-label">داشبورد — {"روشن" if theme == "light" else "تاریک (شب)"} · اسکرول کامل</div>'
            f'<div class="phone theme-{theme}"><div class="scroll">{header(av, theme_icon="moon" if theme == "light" else "sun")}{stage(av)}{progress()}{habits()}{tiles()}</div>{nav()}</div></div>')


def sheet(theme, av):
    items = [('target', 'a', 'عادت‌ها'), ('calendar-days', 'e', 'ثبت ماهانه'), ('calendar-range', 'b', 'ثبت سالانه'),
             ('library', 'c', 'کتابخونه'), ('wallet', 'f', 'خریدها'), ('notebook-pen', 'd', 'یادداشت'),
             ('square-check', 'a', 'لیست کارها'), ('timer', 'b', 'پومودورو'), ('trophy', 'c', 'چالش‌ها'),
             ('zap', 'd', 'لحظه‌ی وسوسه'), ('chart-column', 'e', 'تحلیل'), ('settings', 'f', 'تنظیمات')]
    grid = ''.join(f'<div class="ag"><div class="ti tint-{t}">{ic(i)}</div><b>{n}</b></div>' for i, t, n in items)
    return f'''<div><div class="fr-label">منوی + — Bottom Sheet (تاریک)</div><div class="phone theme-{theme}" style="height:844px">
<div class="scroll" style="height:100%;overflow:hidden">{header(av, theme_icon="sun")}{stage(av)}{progress()}</div>
{nav(fab_open=True)}<div class="dim"></div>
<div class="sheet"><div class="grab"></div><h3>همه‌ی بخش‌ها</h3><div class="sub">برای رفتن به هر بخش لمس کنید</div>
<div class="agrid">{grid}</div>
<div class="qa"><button class="btn primary">{ic("plus")} عادت جدید</button><button class="btn tonal">{ic("plus")} کار جدید</button></div></div></div></div>'''


def charts(theme):
    vals = [70, 85, 100, 62, 80, None, None]
    lab = 'ش ی د س چ پ ج'.split()
    cols = ''
    for k, v in enumerate(vals):
        if v is None:
            cols += f'<div class="b"><i class="nul"></i><span>{lab[k]}</span></div>'
        else:
            cls = 'hi' if k == 4 else ('' if v >= 80 else 'dim2')
            cols += f'<div class="b"><i class="{cls}" style="height:{v * 1.3}px"><u>{str(v).translate(str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹"))}٪</u></i><span>{lab[k]}</span></div>'
    hb = ''.join(f'<div class="hbar"><span>{n}</span><div class="bar"><i style="width:{v}%;background:{c}"></i></div><b>{str(v).translate(str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹"))}٪</b></div>'
                 for n, v, c in [('نوشیدن آب', 92, 'linear-gradient(90deg,var(--primary),var(--primary-2))'),
                                 ('ورزش', 78, 'linear-gradient(90deg,var(--primary),var(--primary-2))'),
                                 ('مطالعه', 64, 'linear-gradient(90deg,var(--primary),var(--primary-2))'),
                                 ('مدیتیشن', 41, 'linear-gradient(90deg,var(--hp),#FF9AA5)')])
    return f'''<div><div class="fr-label">تحلیل — {"روشن" if theme == "light" else "تاریک"}</div><div class="phone theme-{theme}"><div class="scroll">
<div class="hdr"><div class="who"><small>عملکرد شما</small><b>تحلیل</b></div><div class="iconbtn">{ic("chart-column")}</div></div>
<div class="seg"><span class="on">هفته</span><span>ماه</span><span>سال</span></div>
<div class="card"><div class="sec-h"><b>نتیجه‌ی ثبت‌ها</b><span class="chip prim">این هفته</span></div>
<div class="donut-wrap"><div class="donut"><div><b>۵۸٪</b><small>موفقیت</small></div></div>
<div class="legend"><div><i style="background:var(--ok)"></i>موفق<em>۲۳</em></div><div><i style="background:var(--bad)"></i>ناموفق<em>۷</em></div><div><i style="background:var(--line)"></i>ثبت‌نشده<em>۱۰</em></div></div></div></div>
<div class="card"><div class="sec-h"><b>روند هفتگی</b><span class="chip gold">{ic("flag")}هدف ۸۰٪</span></div>
<div class="bars"><div class="goal" style="bottom:{24 + 0.8 * 130}px"><em>۸۰٪</em></div>{cols}</div></div>
<div class="card"><div class="sec-h"><b>مقایسه‌ی عادت‌ها</b><a>جزئیات ‹</a></div>{hb}</div>
</div>{nav('habits')}</div></div>'''


def tokens():
    def sw(name, var, hexv): return f'<div class="sw"><div class="c" style="background:var({var})"></div><div><b>{name}</b>{hexv}</div></div>'
    L = dict(bg='#F5F1E8', surface='#FFFFFF', line='#E9E0CF', text='#231C14', primary='#136B68', gold='#C99A2E', xp='#7357E8', hp='#E0485A', ok='#2F9E57', bad='#D04A3C')
    D = dict(bg='#0A1413', surface='#111E1D', line='#1E3330', text='#EEE8DB', primary='#3DC7BE', gold='#E6BF5C', xp='#9C86FF', hp='#FF6B7A', ok='#4FBF72', bad='#F0806F')
    names = {'bg': 'زمینه', 'surface': 'کارت', 'line': 'خط/مرز', 'text': 'متن', 'primary': 'برند (فیروزه‌ای)', 'gold': 'سکه/طلایی', 'xp': 'XP', 'hp': 'HP', 'ok': 'موفق', 'bad': 'ناموفق'}
    panel = lambda th, d: f'<div class="panel theme-{th}"><div class="swatches">' + ''.join(sw(names[k], '--' + k, v) for k, v in d.items()) + '</div></div>'
    scale = [('display · 32/800', 'نمایش اعداد بزرگ', 32, 800), ('title-l · 22/800', 'عنوان صفحه', 22, 800), ('title · 18/800', 'عنوان کارت', 18, 800),
             ('body-l · 16/700', 'متن درشت / عنوان بخش', 16, 700), ('body · 14/500', 'متن اصلی — Routine Planner 1405', 14, 500),
             ('label · 12/600', 'برچسب و توضیح کوتاه', 12, 600), ('caption · 11/500', 'ریزنوشته', 11, 500)]
    typ = ''.join(f'<div class="type-row"><small>{a}</small><span style="font-size:{s}px;font-weight:{w}">{b}</span></div>' for a, b, s, w in scale)
    rad = ''.join(f'<div style="border-radius:{v}px">{n}<br>{v}</div>' for n, v in [('xs', 8), ('sm', 12), ('md', 16), ('lg', 20), ('xl', 28), ('pill', 40)])
    return f'''<div class="dual">{panel('light', L)}{panel('dark', D)}</div>
<div class="row" style="margin-top:22px"><div class="panel theme-light" style="flex:1;min-width:440px;border-radius:18px;border:1px solid rgba(0,0,0,.08)"><div class="fr-label">تایپوگرافی (Vazirmatn — ۷ اندازه به‌جای ۲۳)</div>{typ}</div>
<div class="panel theme-light" style="flex:1;min-width:440px;border-radius:18px;border:1px solid rgba(0,0,0,.08)"><div class="fr-label">شعاع گوشه (۶ مقدار به‌جای ۱۷)</div><div class="rad">{rad}</div>
<div class="fr-label" style="margin-top:22px">سایه</div><div class="elev"><div style="box-shadow:var(--e1)">e1</div><div style="box-shadow:var(--e2)">e2 · کارت</div><div style="box-shadow:var(--e3)">e3 · شناور</div></div>
<div class="fr-label" style="margin-top:22px">فاصله (شبکه‌ی ۴)</div><div style="display:flex;gap:8px;align-items:flex-end">{''.join(f'<div style="width:{v}px;height:{v}px;background:var(--primary);border-radius:4px;opacity:.85"></div><small style="font-size:10px;color:var(--muted)">{v}</small>' for v in (4, 8, 12, 16, 20, 24, 32))}</div></div></div>
<div class="row" style="margin-top:22px">
<div class="panel theme-light" style="border-radius:18px;border:1px solid rgba(0,0,0,.08);flex:1;min-width:440px"><div class="fr-label">اجزا — روشن</div>{comps()}</div>
<div class="panel theme-dark" style="border-radius:18px;border:1px solid rgba(255,255,255,.08);flex:1;min-width:440px"><div class="fr-label" style="color:var(--muted)">اجزا — تاریک</div>{comps()}</div></div>
<div class="panel theme-light" style="border-radius:18px;border:1px solid rgba(0,0,0,.08);margin-top:22px"><div class="fr-label">حرکت و انیمیشن</div><ul class="mot" style="padding-inline-start:20px;font-size:14px">
<li><b>مدت:</b> ۱۲۰ms (لمس) · ۲۲۰ms (پایه) · ۳۶۰ms (صفحه/Sheet) — منحنی <code>cubic-bezier(.22,1,.36,1)</code>.</li>
<li><b>انتقال صفحه:</b> fade-through + جابه‌جایی ۱۲px در جهت ناوبری (در RTL معکوس). نوار پایین ثابت می‌ماند و نشانگر فعال می‌لغزد.</li>
<li><b>دکمه‌ی +:</b> ۴۵° می‌چرخد و Sheet با فنر از پایین بالا می‌آید؛ کاشی‌ها با تأخیر ۳۰ms پشت‌سرهم ظاهر می‌شوند.</li>
<li><b>ثبت عادت:</b> تیک با scale-pop، حلقه‌ی پیشرفت و عدد با count-up، سکه با پرش کوچک.</li>
<li><b>آواتار:</b> تنفس آرام، و هنگام تعویض آیتم cross-fade ۲۲۰ms با درخشش کوتاه.</li>
<li><b>احترام به دسترسی‌پذیری:</b> اگر «کاهش حرکت» در گوشی روشن باشد، همه‌ی این‌ها به fade ساده تبدیل می‌شود.</li></ul></div>'''


def comps():
    return f'''<div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px"><button class="btn primary">{ic("plus")} اصلی</button><button class="btn tonal">تونال</button><button class="btn ghost">خطی</button><button class="btn danger">حذف</button><button class="btn primary sm">کوچک</button></div>
<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:14px"><span class="chip prim">{ic("star")}برند</span><span class="chip ok">{ic("check")}موفق</span><span class="chip bad">{ic("x")}ناموفق</span><span class="chip gold">{ic("coins")}۲۵۰</span><span class="chip xp">XP ۶۲۰</span><span class="chip hp">{ic("heart")}۸۶٪</span></div>
<div style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;margin-bottom:14px"><div class="field">نام عادت…</div><div class="field on">نوشیدن آب</div></div>
<div style="display:flex;gap:16px;align-items:center;margin-bottom:14px"><div class="switch on"></div><div class="switch"></div><div class="bar" style="width:160px"><i style="width:64%;background:linear-gradient(90deg,var(--primary),var(--primary-2))"></i></div><div class="ring" style="--v:64;width:54px;height:54px"><b style="font-size:13px">۶۴٪</b></div></div>
<div style="display:flex;gap:10px"><div class="chk ok">{ic("check")}</div><div class="chk no">{ic("x")}</div><div class="chk">{ic("check")}</div><div class="iconbtn">{ic("bell")}</div></div>'''


def tablet():
    def sl(icon, label, on=False): return f'<div class="sl{" on" if on else ""}">{ic(icon)}{label}</div>'
    side = ('<div class="side"><div class="brand"><i>' + ic('sparkles') + '</i>روتین پلنر</div>' + sl('house', 'خانه', True) + sl('target', 'عادت‌ها') +
            sl('calendar-days', 'ثبت ماهانه') + sl('square-check', 'لیست کارها') + sl('timer', 'پومودورو') + sl('trophy', 'چالش‌ها') +
            sl('library', 'کتابخونه') + sl('notebook-pen', 'یادداشت') + sl('chart-column', 'تحلیل') + '<div class="sp"></div>' + sl('settings', 'تنظیمات') + '</div>')
    main = f'<div class="tmain"><div style="display:flex;flex-direction:column;gap:16px">{stage(AVM)}{progress()}</div><div style="display:flex;flex-direction:column;gap:16px">{habits()}{tiles()}</div></div>'
    return f'<div class="fr-label">تبلت / تاشو (≥ ۸۴۰dp) · روشن</div><div class="tablet theme-light">{side}{main}</div>'


html = tpl
for k, v in {'{{FONT_AR}}': b64(ROOT / 'flutter_app/assets/fonts/Vazirmatn-arabic.ttf'), '{{FONT_LAT}}': b64(ROOT / 'flutter_app/assets/fonts/Vazirmatn-latin.ttf'),
             '{{SPRITE}}': sprite, '{{DASH_LIGHT}}': dashboard('light', AVM), '{{DASH_DARK}}': dashboard('dark', AVF),
             '{{SHEET_DARK}}': sheet('dark', AVM), '{{CHARTS_LIGHT}}': charts('light'), '{{CHARTS_DARK}}': charts('dark'),
             '{{TOKENS}}': tokens(), '{{TABLET}}': tablet()}.items():
    assert k in html, k
    html = html.replace(k, v)
os.makedirs(OUT.parent, exist_ok=True)
io.open(OUT, 'w', encoding='utf-8').write(html)
print('→', OUT, round(len(html.encode()) / 1024), 'KB | آیکون‌های پیدا‌نشده:', missing)
