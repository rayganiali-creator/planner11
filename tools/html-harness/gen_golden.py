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


MODULES = {'calendar': m_calendar, 'habits': m_habits}


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
