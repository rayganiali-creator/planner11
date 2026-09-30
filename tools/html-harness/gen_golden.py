# -*- coding: utf-8 -*-
"""خروجی طلایی (golden) از خودِ JS می‌گیرد: ورودیِ ثابت (seed ثابت + مرزی) → خروجیِ واقعیِ برنامه.
   تست‌های Dart همین فایل‌ها را می‌خوانند و باید «دقیقاً» همان را بدهند.
   استفاده:  python3 tools/html-harness/gen_golden.py [ماژول ...]      (بدون آرگومان = همه)
"""
import json, os, random, subprocess, sys, time, glob, pathlib
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


class Page:
    def __init__(self, pw):
        exe = chromium()
        self.b = pw.chromium.launch(executable_path=exe) if exe else pw.chromium.launch()
        self.pg = self.b.new_page()
        self.errs = []
        self.pg.on('pageerror', lambda e: 'cdnjs' not in str(e) and self.errs.append(str(e)[:200]))
        self.pg.goto(f'http://127.0.0.1:{PORT}/index.html')
        self.pg.wait_for_function('window.__rpFn !== undefined', timeout=20000)

    def call(self, fn, args):
        return self.pg.evaluate('([f,a]) => window.__rpFn[f](...a)', [fn, args])

    def batch(self, cases):
        """cases = [(fn, args)] → [out]  (یک رفت‌وبرگشت برای هزاران مورد)"""
        return self.pg.evaluate(
            '(cs) => cs.map(([f,a]) => { try { return {ok: window.__rpFn[f](...a)}; } catch(e) { return {err: String(e)}; } })',
            [[c[0], c[1]] for c in cases])


def write(name, cases, outs):
    rows = []
    for (fn, args), o in zip(cases, outs):
        rows.append({'fn': fn, 'args': args, **o})
    os.makedirs(GOLD, exist_ok=True)
    path = GOLD / f'{name}.json'
    json.dump(rows, open(path, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    errs = sum(1 for r in rows if 'err' in r)
    print(f'  {name}: {len(rows)} مورد  ({errs} مورد با استثنا) → {path.relative_to(ROOT)}')


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


MODULES = {'calendar': m_calendar}


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
