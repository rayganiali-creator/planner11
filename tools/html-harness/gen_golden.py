# -*- coding: utf-8 -*-
"""خروجی طلایی (golden) از خودِ JS می‌گیرد: ورودیِ ثابت (seed ثابت + مرزی) → خروجیِ واقعیِ برنامه.
   تست‌های Dart همین فایل‌ها را می‌خوانند و باید «دقیقاً» همان را بدهند.
   استفاده:  python3 tools/html-harness/gen_golden.py [ماژول ...]      (بدون آرگومان = همه)
"""
import gzip, json, os, random, subprocess, sys, time, glob, pathlib
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parents[2]
GOLD = ROOT / 'flutter_app' / 'test' / 'golden'
HARNESS = '/tmp/harness'
PORT = 9170


def chromium():
    p = os.environ.get('CHROMIUM_PATH')
    if p: return p
    c = sorted(glob.glob('/opt/pw-browsers/chromium-*/chrome-linux/chrome'))
    return c[-1] if c else None


TZNAME = os.environ.get('RP_TZ', 'Europe/Berlin')   # منطقه‌ای با DST تا لبه‌های ساعت تابستانی هم آزموده شود


class Page:
    def __init__(self, pw):
        exe = chromium()
        self.b = pw.chromium.launch(executable_path=exe) if exe else pw.chromium.launch()
        self.ctx = self.b.new_context(timezone_id=TZNAME)
        self.pg = self.ctx.new_page()
        self.errs = []
        self.pg.on('pageerror', lambda e: 'cdnjs' not in str(e) and self.errs.append(str(e)[:200]))
        self.pg.goto(f'http://127.0.0.1:{PORT}/index.html')
        self.pg.wait_for_function('window.__rpFn !== undefined', timeout=20000)

    def set_now(self, y, mo, d, h=10, mi=0):
        from datetime import datetime
        from zoneinfo import ZoneInfo
        # datetime آگاه از منطقه‌ی زمانی بدهیم؛ عدد خام را Playwright-Python به‌صورت «ثانیه» می‌گیرد.
        self.pg.clock.set_fixed_time(datetime(y, mo, d, h, mi, tzinfo=ZoneInfo(TZNAME)))
        got = self.pg.evaluate('() => { const n = new Date(); return [n.getFullYear(), n.getMonth() + 1, n.getDate(), n.getHours(), n.getMinutes()]; }')
        assert got == [y, mo, d, h, mi], f'ساعت ثابت اعمال نشد: خواسته {[y, mo, d, h, mi]}، مرورگر {got}'

    def call(self, fn, args):
        return self.pg.evaluate('([f,a]) => window.__rpFn[f](...a)', [fn, args])

    def abatch(self, cases):
        """مثل batch ولی برای توابع async (Promise) — یکی‌یکی await می‌شوند."""
        return self.pg.evaluate(
            '''async (cs) => { const out = []; for (const [f, a] of cs) { try { out.push({ok: await window.__rpFn[f](...a)}); } catch (e) { out.push({err: String(e)}); } } return out; }''',
            [[c[0], c[1]] for c in cases])

    def batch(self, cases):
        """cases = [(fn, args)] → [out]  (یک رفت‌وبرگشت برای هزاران مورد)"""
        return self.pg.evaluate(
            '(cs) => cs.map(([f,a]) => { try { return {ok: window.__rpFn[f](...a)}; } catch(e) { return {err: String(e)}; } })',
            [[c[0], c[1]] for c in cases])


def dump_gz(name, obj):
    """JSON فشرده‌شده (گیت را سنگین نمی‌کند). NaN/Infinity مجاز نیست؛ خروجیِ طلایی باید JSON معتبر باشد."""
    os.makedirs(GOLD, exist_ok=True)
    path = GOLD / f'{name}.json.gz'
    raw = json.dumps(obj, ensure_ascii=False, separators=(',', ':'), allow_nan=False).encode('utf-8')
    with gzip.GzipFile(filename='', mode='wb', fileobj=open(path, 'wb'), mtime=0) as f:
        f.write(raw)
    return path, len(raw)


def write(name, cases, outs):
    rows = []
    for (fn, args), o in zip(cases, outs):
        rows.append({'fn': fn, 'args': args, **o})
    path, n = dump_gz(name, rows)
    errs = sum(1 for r in rows if 'err' in r)
    print(f'  {name}: {len(rows)} مورد  ({errs} استثنا) → {path.relative_to(ROOT)}  [{round(path.stat().st_size / 1024)} KB فشرده / {round(n / 1024)} KB خام]')


# ------------------------------------------------------------------ ماژول‌ها
def m_calendar(P):
    rnd = random.Random(20260930)
    cs = []
    # جرین‌گوریَن → روز ژولین و برعکس، مرزهای ماه/سال کبیسه
    for gy in list(range(1900, 2101, 7)) + [2000, 2020, 2024, 2025, 2026, 2100]:
        for gm in (1, 2, 3, 6, 9, 12):
            for gd in (1, 15, 28):
                cs.append(('g2d', [gy, gm, gd]))
    for _ in range(1500):
        cs.append(('g2d', [rnd.randint(1, 3500), rnd.randint(1, 12), rnd.randint(1, 28)]))
    for jy in list(range(-61, 3178, 13)) + [1398, 1399, 1403, 1404, 1405, 1408, 1409, 1403, 1420, 1500]:
        cs.append(('jalCal', [jy]))
        for jm in (1, 6, 7, 11, 12):
            cs.append(('jalaaliMonthLength', [jy, jm]))
    for _ in range(1500):
        jy = rnd.randint(1, 3177)
        jm = rnd.randint(1, 12)
        jd = rnd.randint(1, 29 if jm == 12 else 30)
        cs.append(('j2d', [jy, jm, jd]))
        cs.append(('toGregorian', [jy, jm, jd]))
    for _ in range(1500):
        cs.append(('toJalaali', [rnd.randint(622, 3800), rnd.randint(1, 12), rnd.randint(1, 28)]))
    for jdn in list(range(1948321, 2816787, 401)):
        cs.append(('d2g', [jdn]))
        cs.append(('d2j', [jdn]))
    # تبدیل‌های امروزی (۱۴۰۰–۱۴۱۰) روز به روز
    for jy in range(1400, 1411):
        for jm in range(1, 13):
            for jd in (1, 15, 29):
                cs.append(('toGregorian', [jy, jm, jd]))
    for x in (0, 7, 12345, '۱۲۳', 'a1b2', -5, 3.5, '', 1405):
        cs.append(('toPersianDigits', [x]))
    for n in (0, 5, 9, 10, 11, 99, 100, -1):
        cs.append(('pad2', [n]))
    for y, m, d in [(2026, 1, 1), (2026, 12, 31), (2024, 2, 29), (1999, 7, 4), (2026, 3, 20)]:
        cs.append(('dateToISO_ymd', [y, m, d]))
        cs.append(('isoToDate_ymd', [f'{y:04d}-{m:02d}-{d:02d}']))
    for iso in ('2026-01-01', '2026-02-28', '2024-02-28', '2026-12-31', '2026-10-25', '2026-03-29'):
        for n in (-400, -31, -1, 0, 1, 7, 30, 365, 400):
            cs.append(('isoAddDays', [iso, n]))
    for d in range(7):
        cs.append(('jsWeekdayToPersianIndex', [d]))
    write('calendar', cs, P.batch(cs))



# ------------------------------------------------------------------ تولید state تصادفی
from datetime import date, timedelta


def gen_state(rnd, today):
    habits = []
    for i in range(rnd.randint(1, 7)):
        typ = rnd.choice(['binary', 'binary', 'binary', 'numeric', 'timer'])
        created = today - timedelta(days=rnd.randint(0, 160))
        h = {'id': f'h{i}_{rnd.randint(0, 99)}', 'name': f'عادت {i}', 'type': typ, 'createdAt': created.isoformat()}
        r = rnd.random()
        if r < 0.25:
            h['permanent'] = False
            h['endDate'] = (created + timedelta(days=rnd.randint(1, 200))).isoformat()
        elif r < 0.6:
            h['permanent'] = True
        if rnd.random() < 0.3:
            h['scheduleMode'] = 'custom'
            h['activeDays'] = sorted(rnd.sample(range(7), rnd.randint(0, 7)))
        elif rnd.random() < 0.08:
            h['scheduleMode'] = 'custom'
        if rnd.random() < 0.7: h['direction'] = rnd.choice(['more', 'less'])
        if typ == 'numeric' and rnd.random() < 0.85: h['numericTarget'] = rnd.choice([1, 3, 5, 8, 10, 2.5, 0, '7'])
        if typ == 'timer' and rnd.random() < 0.85: h['timerTarget'] = rnd.choice([10, 20, 30, 45, 60, 0])
        if rnd.random() < 0.7: h['rewardPoints'] = rnd.choice([5, 10, 10, 10, 20, 25, 50, 100, 1000, 12.5, 0, -5, '20'])
        if rnd.random() < 0.3: h['unlockedStage'] = rnd.choice([1, 2, 0, 3])
        habits.append(h)

    records = {}
    first = min(date.fromisoformat(h['createdAt']) for h in habits) - timedelta(days=3)
    bias = rnd.choice([0.15, 0.5, 0.9, 0.97])
    good = rnd.choice([0.5, 0.8, 0.97])            # احتمال موفقیت؛ برای streak‌های بلند
    d = first
    while d <= today + timedelta(days=4):
        iso = d.isoformat()
        day = {}
        for h in habits:
            if rnd.random() > bias: continue
            t = h.get('numericTarget', 1) if h['type'] == 'numeric' else h.get('timerTarget', 30)
            try: t = float(t) or 1
            except Exception: t = 1
            if h['type'] == 'binary':
                day[h['id']] = rnd.choices(['success', 'fail', 'x', None], [good, 1 - good, 0.03, 0.02])[0]
            else:
                v = round(rnd.uniform(0, 2 * t + 1), 1)
                day[h['id']] = rnd.choice([v, str(v), {'value': str(v), 'targetAtTime': t}, {'value': v, 'targetAtTime': t},
                                           {'value': str(v)}, 'abc', None, {'value': 'x', 'targetAtTime': 1}, [1, 2], True])
        if rnd.random() < 0.05: day['zz_unknown'] = 'success'
        if day or rnd.random() < 0.1:
            records[iso] = day
        if rnd.random() < 0.01: records[iso] = rnd.choice([None, [], 5])
        d += timedelta(days=1)
    st = {'habits': habits, 'records': records, 'todos': [], 'books': [], 'journal': [], 'challenges': [], 'lang': rnd.choice(['fa', 'en']),
          'calendarType': rnd.choice(['jalali', 'gregorian']), 'scores': {'coins': rnd.choice([0, 7, 999, 1000, 2500, 123456]), 'lastPoints': rnd.choice([0, 50, 400])}}
    r = rnd.random()
    if r < 0.8: st['weekStart'] = rnd.randint(0, 6)
    return st


def m_habits(P):
    rnd = random.Random(20260930 + 1)
    states, rows = [], []

    def add(si, now, fn, args):
        rows.append({'s': si, 'now': list(now), 'fn': fn, 'args': args})

    for si in range(110):
        today = date(2026, 1, 1) + timedelta(days=rnd.randint(0, 460))
        st = gen_state(rnd, today)
        states.append(st)
        hids = [h['id'] for h in st['habits']]
        nows = [(today.year, today.month, today.day, 10, 0), (today.year, today.month, today.day, 0, 30),
                (today.year, today.month, today.day, 23, 59)]
        for now in nows:
            isos = [(today + timedelta(days=rnd.randint(-70, 6))).isoformat() for _ in range(6)] + [today.isoformat()]
            for hid in hids:
                add(si, now, 'computeHabitStreak_id', [hid])
                add(si, now, 'computeHabitBestRecord_id', [hid])
                add(si, now, 'stageCount_id', [hid])
                add(si, now, 'getHabitRewardPoints_id', [hid])
                for pts in (0, 249, 250, 499, 2000, 2499, 2500, 4999, 5000, 9000, -30):
                    add(si, now, 'level_habit', [pts, hid])
                for iso in isos:
                    add(si, now, 'habitAppliesOnISO_id', [hid, iso])
                    add(si, now, 'habitSuccessOnISO_id', [hid, iso])
                for v in ('success', 'fail', 'x', None, 5, '5', '0', 'abc', {'value': '9', 'targetAtTime': 4}, {'value': 2},
                          {'value': '1', 'targetAtTime': None}, [3], 12.5, True):
                    add(si, now, 'getStatusFromRecord_id', [v, hid])
                    add(si, now, 'getRecordPoints_id', [v, hid])
            add(si, now, 'computeStreak', [])
            add(si, now, 'computePermanentStreak', [])
            add(si, now, 'computeAllHabitPoints', [])
            add(si, now, 'computeTotalPoints', [])
            add(si, now, 'getWeekStart_iso', [])
            for rg in ('week', 'month', 'year'):
                add(si, now, 'collectSeries', [rg])
                add(si, now, 'getTotalStats', [rg])
            for iso in isos:
                add(si, now, 'dayStats_all', [iso])
                add(si, now, 'dayStats_perm', [iso])
                add(si, now, 'applicableIds', [iso])
        # سکه: سناریوهای دنباله‌ای (state را تغییر می‌دهد)
        ops = []
        for _ in range(rnd.randint(2, 8)):
            ops.append([rnd.choice(['add', 'remove', 'sync']), rnd.choice([0, 1, 7, 49.5, 50, 51, 500, -10, 0.4, 0.5, 1.5, 2.5, 100000])])
        add(si, nows[0], 'coinOps', [ops])

    for x in (0, 1, 249, 250, 251, 499, 500, 749, 750, 999, 1000, 1499, 1500, 1999, 2000, 2001, -1, 0.5, 250.0):
        add(0, (2026, 6, 1, 10, 0), 'level_base', [x])
    for c in (None, 0, -5, 999, 1000, 1999, 2000, 123456, 0.5):
        add(0, (2026, 6, 1, 10, 0), 'getAccountLevelFromCoins', [c])

    # اجرا: برای هر (state, now) یک بار state و ساعت را می‌گذاریم و همه‌ی فراخوانی‌هایش را یک‌جا می‌زنیم
    outs = [None] * len(rows)
    groups = {}
    for i, r in enumerate(rows):
        groups.setdefault((r['s'], tuple(r['now'])), []).append(i)
    import copy
    for (si, now), idxs in groups.items():
        P.call('setState', [copy.deepcopy(states[si])])
        P.set_now(*now)
        res = P.batch([(rows[i]['fn'], rows[i]['args']) for i in idxs])
        # coinOps اجرا شد و state را عوض کرد؛ برای گروه بعدی دوباره setState می‌شود
        for i, o in zip(idxs, res):
            outs[i] = o
    for r, o in zip(rows, outs): r.update(o)
    path, n = dump_gz('habits', {'tz': TZNAME, 'states': states, 'cases': rows})
    errs = sum(1 for r in rows if 'err' in r)
    print(f'  habits: {len(rows)} مورد روی {len(states)} state ({errs} استثنا) → {path.relative_to(ROOT)}  [{round(path.stat().st_size / 1024)} KB فشرده / {round(n / 1024)} KB خام]')


def m_pro(P):
    rnd = random.Random(20260930 + 2)
    PIDS = ['rp_pro_1m', 'rp_pro_2m', 'rp_pro_3m', 'rp_pro_6m', 'premium_unlock', 'pro_1m', 'unknown_x', None, 5]
    T0 = 1790000000000

    def purchase():
        pid = rnd.choice(PIDS)
        p = {'productId': pid, 'purchaseToken': rnd.choice(['tok' + str(rnd.randint(0, 999)), 'توکن-' + str(rnd.randint(0, 9)), 'a"b\\c', '', None])}
        r = rnd.random()
        if r < 0.85: p['purchaseTime'] = T0 + rnd.randint(0, 120) * 86400000 + rnd.choice([0, 0, 1, 12345])
        elif r < 0.92: p['purchaseTime'] = 0
        elif r < 0.96: p['purchaseTime'] = None
        return p

    cases = []
    for _ in range(700):
        n = rnd.randint(0, 6)
        ps = [purchase() for _ in range(n)]
        if rnd.random() < 0.3 and ps:          # زمان‌های برابر → آزمونِ پایداریِ مرتب‌سازی
            t = ps[0].get('purchaseTime', T0)
            for q in ps[1:]: q['purchaseTime'] = t
        cases.append(('proWindow', [ps]))
    # امضا: کش‌های گوناگون
    caches = []
    for _ in range(500):
        ps = [purchase() for _ in range(rnd.randint(0, 4))]
        c = {'isPro': rnd.choice([True, False]), 'expiresAt': rnd.choice([None, 0, T0 + 86400000 * rnd.randint(-50, 400)]), 'purchases': ps}
        if rnd.random() < 0.1: c['legacyUntil'] = rnd.choice([0, 12345, T0])
        if rnd.random() < 0.1: del c['purchases']
        caches.append(c)
        cases.append(('rpSig_obj', [c]))
    # ساعت‌ها
    def clk(now, scenario):
        if scenario == 0: return {'date': now, 'perf': 5000.5, 'sess': None, 'trust': None}
        if scenario == 1: return {'date': now, 'perf': 9000, 'sess': {'eff': now - 3000, 'perf': 2000}, 'trust': None}
        if scenario == 2: return {'date': now - 500000, 'perf': 7000, 'sess': {'eff': now - 100, 'perf': 7000}, 'trust': None}
        return {'date': now - 9e7, 'perf': 4000, 'sess': None, 'trust': {'server': now, 'perf': 1000}}
    for _ in range(150):
        now = T0 + rnd.randint(0, 200) * 86400000 + rnd.randint(0, 86399999)
        a = clk(now, rnd.randint(0, 3))
        for last in (None, 0, now - 1000, now + 5000000):
            st = {'clock': {'lastSeen': last} if last is not None else {}}
            cases.append(('rpNowWith', [st, a]))
    cases.append(('rpNowWith', [{}, clk(T0, 0)]))
    # تشخیص پرو + روز مانده + خط‌زمانی
    def build_state():
        ps = [purchase() for _ in range(rnd.randint(0, 4))]
        w = P.call('proWindow', [ps])
        c = {'isPro': rnd.choice([True, True, True, False, None]), 'expiresAt': w['expiresAt'], 'purchases': ps,
             'checkedAt': T0}
        if rnd.random() < 0.85:
            c['purchaseToken'] = rnd.choice(['t1', None, ''])
        r = rnd.random()
        if r < 0.65: c['sig'] = P.call('rpSig_obj', [c])
        elif r < 0.8: c['sig'] = 'wrong'
        elif r < 0.9: c['sig'] = None
        if rnd.random() < 0.1: c['expiresAt'] = None
        st = {'proCache': rnd.choice([c, c, c, None, {}, 'x']), 'clock': {'lastSeen': rnd.choice([0, T0])}}
        if rnd.random() < 0.15: st['__rpOwnerMark'] = rnd.choice([P.call('ownerMark', []), 'nope'])
        st['isPremium'] = rnd.choice([True, False])
        return st
    states = [build_state() for _ in range(450)]
    for st in states:
        now = T0 + rnd.randint(0, 260) * 86400000 + rnd.randint(0, 86399999)
        a = clk(now, rnd.randint(0, 3))
        cases.append(('recomputePremium', [st, a]))
        cases.append(('daysLeft', [dict(st, isPremium=True), a]))
        cases.append(('daysLeft', [dict(st, isPremium=False), a]))
        cases.append(('segments', [st, a]))
    write('pro', cases, P.batch(cases))


STORAGE_KEY = 'alshadow-v14-level-colors'


def load_case(P, raw, y=2026, mo=9, d=30, h=10, mi=0):
    """یک بارگذاریِ واقعیِ صفحه با یک localStorage مشخص؛ state را درست پس از خطِ لوله‌ی بارگذاری برمی‌گرداند."""
    from datetime import datetime
    from zoneinfo import ZoneInfo
    pg = P.ctx.new_page()
    try:
        if raw is not None:
            pg.add_init_script(f"try{{localStorage.setItem({json.dumps(STORAGE_KEY)}, {json.dumps(raw)});}}catch(e){{}}")
        pg.clock.set_fixed_time(datetime(y, mo, d, h, mi, tzinfo=ZoneInfo(TZNAME)))
        pg.goto(f'http://127.0.0.1:{PORT}/index.html')
        pg.wait_for_function('window.__rpLoaded !== undefined', timeout=20000)
        out = pg.evaluate('window.__rpLoaded')
        now_ms = pg.evaluate('Date.now()')
        return out, now_ms
    finally:
        pg.close()


def m_load(P):
    rnd = random.Random(20260930 + 3)
    T_NOW = 1790762400000
    raws = [None, '', '{bad json', 'null', '5', '[1,2]', '"ab"', 'true', '{}', '{"habits":"x","records":[],"scores":5,"avatar":7}']
    base_keys = ['theme', 'lang', 'bgColor', 'accentTheme', 'tileColors', 'habits', 'records', 'journal', 'todos', 'books', 'scores',
                 'weekStart', 'showHolidays', 'calendarType', 'fontSize', 'bgPattern', 'tileShape', 'tileEffect', 'bgPatternOpacity',
                 'themeIntensity', 'profileName', 'reasons', 'triggers', 'triggerType', 'levelToastSent', 'levelReachedColor',
                 'masteryColor', 'customUrgeSuggestions', 'urgeHiddenIds', 'habitNotes', 'onboardingDone', 'langChosen',
                 'avatar', 'termsAcceptedVersion', 'termsAcceptedAt', 'challenges', 'medals', 'behaviorJournal', 'pomodoro']
    WRONG = [None, 5, 'x', [], {}, True, [1, 2], {'a': 1}, 0, '']
    from datetime import date
    for i in range(150):
        today = date(2026, 9, 30)
        st = gen_state(rnd, today)
        st.update({'theme': rnd.choice(['light', 'dark']), 'profileName': rnd.choice(['کاربر', 'علی', '', None]),
                   'onboardingDone': rnd.choice([True, False]), 'unknown_future_field': {'k': [1, 2, {'z': None}]},
                   'scores': {'points': rnd.choice([0, 120, '300', None, 'x']), 'level': rnd.choice([1, 3, '2', 'abc']),
                              'streak': rnd.choice([0, 4]), 'coins': rnd.choice([0, 550, '70', None, 1.5]), 'lastPoints': rnd.choice([0, 40, None])}})
        r = rnd.random()
        if r < 0.45:   # خرابی‌های هدفمند
            for _ in range(rnd.randint(1, 4)):
                k = rnd.choice(base_keys)
                st[k] = rnd.choice(WRONG)
        if rnd.random() < 0.3:  # عادت/کار/کتاب بی‌شناسه و تکراری
            st['habits'] = (st['habits'] if isinstance(st.get('habits'), list) else []) + [{'name': 'بی‌شناسه'}, None, 5, [], {'id': ''}, {'id': 0}]
            st['todos'] = [{'id': 't1', 'title': 'x'}, {'title': 'noid'}, 7]
            st['books'] = [{'id': 'b1'}, None]
            st['challenges'] = [{'id': 'c1'}, {'x': 1}]
            st['journal'] = [{'text': 'a'}, None, 5, 'str', [], {}]
        if rnd.random() < 0.25:  # فیلدهای مرده
            for k in ('coins', 'level', 'calorie', 'vows'): st[k] = rnd.choice([1, {'a': 1}, 'x'])
        if rnd.random() < 0.25 and isinstance(st.get('records'), dict):  # روزهای خراب
            st['records']['2026-01-01'] = rnd.choice([None, 5, 'x', [], [1]])
        if rnd.random() < 0.3:  # حذف کلیدهای پیش‌فرض (نسخه‌های قدیمی)
            for k in rnd.sample(base_keys, rnd.randint(1, 10)): st.pop(k, None)
        if rnd.random() < 0.2:
            st['avatar'] = rnd.choice([{'gender': 'male'}, {'owned': [], 'equipped': 5}, {'owned': {}, 'equipped': {'male': 5}},
                                       {'owned': {'a': True}, 'equipped': {'male': {}, 'female': []}}])
        if rnd.random() < 0.15:
            st['tileColors'] = rnd.choice([{'fail': '#fff'}, {'success': ''}, {'success': '#000', 'fail': '#111'}])
        # پرو: کش معتبر/نامعتبر/منقضی + نشانه‌ی مالک
        if rnd.random() < 0.6:
            ps = [{'productId': rnd.choice(['rp_pro_1m', 'rp_pro_3m', 'rp_pro_6m', 'premium_unlock']), 'purchaseToken': 'tk' + str(i),
                   'purchaseTime': T_NOW + rnd.randint(-200, 20) * 86400000}]
            w = P.call('proWindow', [ps])
            c = {'isPro': rnd.choice([True, True, False]), 'expiresAt': w['expiresAt'], 'purchases': ps, 'purchaseToken': 'tk' + str(i), 'checkedAt': T_NOW}
            c['sig'] = P.call('rpSig_obj', [c]) if rnd.random() < 0.75 else 'bad'
            st['proCache'] = c
        if rnd.random() < 0.1: st['__rpOwnerMark'] = rnd.choice([P.call('ownerMark', []), 'nope'])
        if rnd.random() < 0.15: st['clock'] = {'lastSeen': rnd.choice([0, T_NOW - 10**7, T_NOW + 10**9]), 'lastSync': 0}
        # رکوردهای قدیمیِ عددی/زمانی برای آزمونِ migrateTargetSnapshots
        if isinstance(st.get('habits'), list) and isinstance(st.get('records'), dict):
            for h in st['habits']:
                if isinstance(h, dict) and h.get('type') in ('numeric', 'timer') and rnd.random() < 0.7:
                    st['records']['2026-09-28'] = {**(st['records'].get('2026-09-28') if isinstance(st['records'].get('2026-09-28'), dict) else {}),
                                                   h['id']: rnd.choice([5, '7', 2.5, {'value': '3'}, {'value': 4, 'targetAtTime': 9}, None, True, [1]])}
        raws.append(json.dumps(st, ensure_ascii=False))
    rows = []
    for raw in raws:
        out, now_ms = load_case(P, raw)
        rows.append({'raw': raw, 'nowMs': now_ms, 'ok': out})
    path, n = dump_gz('load', rows)
    print(f'  load: {len(rows)} مورد بارگذاریِ واقعیِ صفحه → {path.relative_to(ROOT)}  [{round(path.stat().st_size / 1024)} KB فشرده / {round(n / 1024)} KB خام]')


def m_backup(P):
    import copy
    from datetime import date
    rnd = random.Random(20260930 + 4)
    P.set_now(2026, 9, 30, 10, 0)
    # ---- ۱) اعتبارسنجی + بازیابی ----
    def good_state(i):
        st = gen_state(rnd, date(2026, 9, 30))
        st.update({'theme': 'dark', 'fontSize': 'large', 'bgColor': '#112233', 'accentTheme': 'rose', 'weekStart': 6, 'showHolidays': False,
                   'calendarType': 'gregorian', 'tileColors': {'success': '#0a0', 'fail': '#a00', 'neutral': '#ccc'}, 'bgPattern': 'dots',
                   'tileShape': 'square', 'tileEffect': 'glow', 'bgPatternOpacity': 0.5, 'themeIntensity': 40, 'profileName': f'نام {i}',
                   'triggerType': 'reason', 'levelReachedColor': '#123456', 'masteryColor': '#654321', 'medals': [{'id': 'm1'}],
                   'pomodoro': {'phase': 'focus'}, 'behaviorJournal': {'r': [{'text': 'x'}]}, 'habitNotes': {'h': 'n'},
                   'avatar': {'gender': 'male', 'owned': {'a/b': True}, 'equipped': {'male': {'base': 'base/male'}, 'female': {}}}})
        return st
    cases, cur_states = [], []
    for i in range(120):
        st = good_state(i)
        data = {k: st[k] for k in ['habits', 'records', 'journal', 'todos', 'books', 'challenges', 'scores', 'medals', 'pomodoro', 'behaviorJournal', 'habitNotes',
                                   'reasons', 'triggers', 'customUrgeSuggestions', 'urgeHiddenIds', 'avatar', 'levelToastSent', 'theme', 'lang', 'bgColor',
                                   'accentTheme', 'weekStart', 'showHolidays', 'calendarType', 'fontSize', 'tileColors', 'bgPattern', 'tileShape', 'tileEffect',
                                   'bgPatternOpacity', 'themeIntensity', 'profileName', 'triggerType', 'levelReachedColor', 'masteryColor'] if k in st}
        data.setdefault('reasons', {}); data.setdefault('triggers', {})
        raw = {'version': rnd.choice(['3.0', 3, 0, None, '2.1']), 'exportedAt': '2026-09-30T08:00:00.000Z', 'appName': 'روتین پلنر', 'data': data,
               'bookPhotos': {}, 'habitPhotos': {}}
        if raw['version'] is None: del raw['version']
        mode = rnd.random()
        if mode < 0.55:
            for _ in range(rnd.randint(1, 4)):
                k = rnd.choice(list(data.keys()) + ['habits', 'records'])
                data[k] = rnd.choice([None, 5, 'x', [], {}, True, [1], {'a': 1}, 0, '', 3.5, False])
        if rnd.random() < 0.15: data['avatar'] = rnd.choice([{'owned': [], 'equipped': {}}, {'owned': {}, 'equipped': None}, {'owned': {}}, {'x': 1}, {'owned': {}, 'equipped': {}}])
        if rnd.random() < 0.05: raw['data'] = rnd.choice([None, [], 'x', 5, []])
        if rnd.random() < 0.05: raw = rnd.choice([None, [], 'x', 5, True, {}, {'data': 0}])
        cases.append(('validateBackup', [raw]))
        cur = good_state(i + 1000)
        if rnd.random() < 0.3: cur['scores'] = rnd.choice([5, None, 'x'])
        cases.append(('restoreInto', [cur, raw]))
    write('backup_validate', cases, P.batch(cases))

    # ---- ۲) ساخت JSON (با رسانه‌ی خالی؛ رسانه جداگانه تست می‌شود) ----
    rows = []
    cs = []
    for i in range(60):
        st = good_state(i)
        st['habits'] = [{**h, 'name': h['name']} for h in st['habits']]
        if rnd.random() < 0.3:
            for k in rnd.sample(['theme', 'weekStart', 'profileName', 'avatar', 'pomodoro', 'medals', 'scores', 'tileColors', 'fontSize', 'showHolidays'], rnd.randint(1, 5)): st.pop(k, None)
        if rnd.random() < 0.2: st['weekStart'] = 0; st['showHolidays'] = False; st['habits'] = []   # مقدارهای falsy
        st['books'] = []   # رسانه‌ی کتاب از IndexedDB می‌آید؛ اینجا خالی نگه می‌داریم
        cs.append(('createBackup', [st]))
        rows.append(st)
    outs = P.abatch(cs)
    path, n = dump_gz('backup_create', [{'state': st, 'now': '2026-09-30T08:00:00.000Z', **o} for st, o in zip(rows, outs)])
    print(f'  backup_create: {len(rows)} مورد → {path.relative_to(ROOT)}  [{round(path.stat().st_size / 1024)} KB]')

    # ---- ۳) رمزنگاری: JS رمز می‌کند، Dart باید باز کند (و خطاها برابر باشد) ----
    plains = ['{}', 'a', 'روتین پلنر — یادداشتِ خصوصی 🔒 ✓ «نقل» "quote" \\ back\nline\ttab', '{"k":"' + ('متن طولانی ' * 1800) + '"}', '😀' * 120]
    passes = ['abcdef', 'my-strong-pass-42', 'رمزِ فارسی ۱۲۳۴۵۶', 'p@ss w0rd with spaces', 'x' * 200, '😀🔑', 'é']
    cs = []
    for pl in plains:
        for pw in rnd.sample(passes, 3):
            cs.append(('encrypt', [pl, pw]))
    encs = P.abatch(cs)
    rows = []
    for (fn, (pl, pw)), o in zip(cs, encs):
        env = o['ok']
        rows.append({'plain': pl, 'pass': pw, 'env': env, 'expect': pl})
        # رمز غلط → null
        rows.append({'plain': pl, 'pass': pw + 'x', 'env': env, 'expect': None})
        # دست‌کاری: یک بیتِ داده را عوض کن → null
        e = json.loads(env); d = bytearray(__import__('base64').b64decode(e['data'])); d[len(d) // 2] ^= 1
        e['data'] = __import__('base64').b64encode(bytes(d)).decode(); rows.append({'plain': pl, 'pass': pw, 'env': json.dumps(e), 'expect': None})
        # برچسب کوتاه/خراب
        e2 = json.loads(env); e2['data'] = 'AAAA'; rows.append({'plain': pl, 'pass': pw, 'env': json.dumps(e2), 'expect': None})
    # تأیید: JS خودش هم همین انتظارها را دارد
    chk = P.abatch([('decrypt', [r['env'], r['pass']]) for r in rows])
    bad = [i for i, (r, c) in enumerate(zip(rows, chk)) if c.get('ok') != r['expect']]
    assert not bad, f'خروجی طلایی با خودِ JS سازگار نیست: {bad[:5]}'
    path, n = dump_gz('backup_crypto', rows)
    print(f'  backup_crypto: {len(rows)} مورد (رمزگشایی موفق و ناموفق) → {path.relative_to(ROOT)}  [{round(path.stat().st_size / 1024)} KB]')


def m_reminders(P):
    from datetime import date, datetime
    from zoneinfo import ZoneInfo
    rnd = random.Random(20260930 + 5)
    cases = []
    # ---- توابع کوچک ----
    ids = ['habit-h1-d0', 'todo-abc', 'journal-x', 'book-1', 'challenge-deadline-c1', 'challenge-reminder-c1-r59', '', 'ا', 'روتین', '😀'] + \
          [''.join(rnd.choice('abcdefghijklmnopqrstuvwxyz0123456789-_ابپ') for _ in range(rnd.randint(1, 40))) for _ in range(300)]
    for i in ids: cases.append(('numericId', [i]))
    out = []
    def at(y, mo, d, h, mi): return int(datetime(y, mo, d, h, mi, tzinfo=ZoneInfo(TZNAME)).timestamp() * 1000)
    # ساعت‌ها: شامل شب‌های تغییر ساعت تابستانی
    NOWS = [(2026, 9, 30, 10, 0), (2026, 3, 28, 22, 30), (2026, 3, 29, 1, 59), (2026, 10, 24, 23, 59), (2026, 10, 25, 2, 30), (2027, 1, 1, 0, 0), (2026, 6, 15, 8, 0)]
    rows = []
    for now in NOWS:
        P.set_now(*now)
        ncs = []
        for hh in (0, 1, 7, 8, 9, 12, 23, 24, 25):
            for mm in (0, 1, 30, 59):
                ncs.append(('nextHabitOccurrence', [hh, mm]))
        for _ in range(60):
            t = {'id': 't', 'title': 'x'}
            r = rnd.random()
            if r < 0.85: t['dueAt'] = at(*now[:3], rnd.randint(0, 23), rnd.choice([0, 15, 30, 59])) + rnd.randint(-5, 30) * 86400000
            t['repeatMode'] = rnd.choice(['none', 'daily', 'custom', None, 'weird'])
            if t['repeatMode'] == 'custom' or rnd.random() < 0.1: t['repeatDays'] = rnd.choice([[], [0, 6], list(range(7)), [3], 'x', None])
            ncs.append(('nextTodo', [t])); ncs.append(('todoToday', [t]))
        res = P.batch(ncs)
        for c, o in zip(ncs, res): rows.append({'now': list(now), 'fn': c[0], 'args': c[1], **o})
    # ---- برنامه‌ریز کامل ----
    def mk_state(now):
        nowms = at(*now)
        st = gen_state(rnd, date(*now[:3]))
        for h in st['habits']:
            if rnd.random() < 0.7:
                h['reminderEnabled'] = rnd.choice([True, True, False])
                h['reminderTime'] = rnd.choice(['08:30', '00:00', '00:30', '7:5', '23:59', '12', '8:xx', '25:61', 'ab:cd', ' 9:15', '09:60', '', None])
        st['todos'] = []
        for i in range(rnd.randint(0, 6)):
            t = {'id': f'td{i}', 'title': rnd.choice(['کار', 'task "q"', '😀', '']), 'done': rnd.choice([False, False, True])}
            if rnd.random() < 0.85: t['dueAt'] = nowms + rnd.randint(-3, 40) * 3600000 * rnd.choice([1, 24])
            t['repeatMode'] = rnd.choice(['none', 'daily', 'custom', None])
            if t['repeatMode'] == 'custom': t['repeatDays'] = rnd.sample(range(7), rnd.randint(0, 7))
            st['todos'].append(t)
        st['journal'] = [{'id': f'j{i}', 'text': rnd.choice(['x' * 200, 'یادداشت ' * 30, 'کوتاه', '', None]), 'remindAt': rnd.choice([None, nowms + 3600000 * rnd.randint(-5, 50), 0])} for i in range(rnd.randint(0, 4))]
        st['books'] = [{'id': f'b{i}', 'title': rnd.choice(['کتاب', None, 'B']), 'remindAt': rnd.choice([None, nowms + 86400000 * rnd.randint(-2, 9)])} for i in range(rnd.randint(0, 3))]
        st['challenges'] = []
        for i in range(rnd.randint(0, 4)):
            c = {'id': f'c{i}', 'name': rnd.choice(['چالش «ویژه»', 'Run "5k"', 'x']), 'status': rnd.choice(['active', 'active', 'done']),
                 'kind': rnd.choice(['timed', 'both', 'count']), 'deadlineAt': nowms + rnd.randint(-2, 500) * 3600000}
            if rnd.random() < 0.7: c['reminderIntervalHours'] = rnd.choice([0.5, 1, 2, 6, 24, 48, 0])
            st['challenges'].append(c)
        st['lang'] = rnd.choice(['fa', 'en'])
        return st
    for now in NOWS:
        P.set_now(*now)
        for _ in range(28):
            st = mk_state(now)
            res = P.abatch([('planResync', [st])])[0]
            rows.append({'now': list(now), 'fn': 'planResync', 'args': [st], **res})
            if st['challenges']:
                c = rnd.choice(st['challenges'])
                res = P.abatch([('planChallenge', [st, c])])[0]
                rows.append({'now': list(now), 'fn': 'planChallenge', 'args': [st, c], **res})
            if st['habits']:
                h = rnd.choice(st['habits']); hh, mm = rnd.choice([(8, 0), (0, 30), (23, 59), (12, 15)])
                res = P.abatch([('planDaily', [st, h['id'], hh, mm])])[0]
                rows.append({'now': list(now), 'fn': 'planDaily', 'args': [st, h['id'], hh, mm], **res})
        rows.append({'now': list(now), 'fn': 'planCancelChallenge', 'args': ['c1'], **P.abatch([('planCancelChallenge', ['c1'])])[0]})
    path, n = dump_gz('reminders', rows)
    print(f'  reminders: {len(rows)} مورد → {path.relative_to(ROOT)}  [{round(path.stat().st_size / 1024)} KB فشرده / {round(n / 1024)} KB خام]')


def m_gameplay(P):
    from datetime import date, timedelta
    rnd = random.Random(20260930 + 6)
    cases = []
    base = date(2026, 9, 30)
    P.set_now(2026, 9, 30, 10, 0)
    for si in range(130):
        st = gen_state(rnd, base)
        # state در برنامه همیشه از rpNormalizeState گذشته است: روزهای خراب حذف و این کلیدها ساخته‌اند
        st['records'] = {k: v for k, v in st['records'].items() if isinstance(v, dict)}
        for k in ('levelToastSent', 'reasons', 'triggers', 'habitNotes'): st.setdefault(k, {})
        for h in st['habits']:
            if rnd.random() < 0.8: h['rewardPoints'] = rnd.choice([50, 50, 40, 25, 100, 10])
            if rnd.random() < 0.3: h['unlockedStage'] = rnd.choice([1, 2])
        st['scores'] = {'coins': rnd.choice([0, 0, 950, 999, 1990, 2000, 7000]), 'lastPoints': rnd.choice([0, 0, 10, 600]),
                        'points': 0, 'level': 1, 'streak': 0}
        if rnd.random() < 0.3: st['scores']['accountLevelToastSent'] = {'1': True}
        if rnd.random() < 0.3: st['levelToastSent'] = {f"{h['id']}_level_1": True for h in st['habits'][:2]}
        st['reasons'] = {h['id']: {(base - timedelta(days=rnd.randint(0, 8))).isoformat(): {'text': 'r'}} for h in st['habits'][:3]} if rnd.random() < 0.5 else {}
        hids = [h['id'] for h in st['habits']]
        typ = {h['id']: h['type'] for h in st['habits']}
        ops = []
        for _ in range(rnd.randint(8, 40)):
            iso = (base - timedelta(days=rnd.randint(0, 12))).isoformat()
            hid = rnd.choice(hids + ['nope'])
            k = rnd.random()
            if k < 0.55 and typ.get(hid, 'binary') == 'binary': ops.append(['bin', iso, hid, rnd.choice(['success', 'success', 'fail'])])
            elif k < 0.75: ops.append(['val', iso, hid, rnd.choice([3, '7', 12.5, 'abc', 0, 45])])
            elif k < 0.85: ops.append(['clear', iso, hid])
            elif k < 0.92: ops.append(['bin', iso, hid, 'success'])
            else: ops.append(['derive'])
        ops.append(['derive'])
        cases.append(('runOps', [st, ops]))
        cases.append(('hpInfo', [st]))
    write('gameplay', cases, P.batch(cases))


MODULES = {'calendar': m_calendar, 'habits': m_habits, 'pro': m_pro, 'load': m_load, 'backup': m_backup, 'reminders': m_reminders, 'gameplay': m_gameplay}


def main():
    names = sys.argv[1:] or list(MODULES)
    srv = subprocess.Popen([sys.executable, '-m', 'http.server', str(PORT), '--bind', '127.0.0.1'],
                           cwd=HARNESS, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1)
    try:
        with sync_playwright() as pw:
            P = Page(pw)
            for n in names:
                MODULES[n](P)
            if P.errs: print('خطاهای صفحه:', P.errs[:3])
            P.b.close()
    finally:
        srv.terminate()


if __name__ == '__main__':
    main()
