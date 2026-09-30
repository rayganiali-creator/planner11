# -*- coding: utf-8 -*-
"""نسخه‌ی مخصوص تست از www/index.html می‌سازد: توابع خالصِ برنامه را زیر window.__rpFn
   در دسترس می‌گذارد تا Playwright بتواند «خروجی طلایی» بگیرد و با پورت Dart مقایسه شود.
   این فقط ابزار تست است؛ محصول (www/index.html) را تغییر نمی‌دهد.

   استفاده:  python3 tools/html-harness/build_harness.py [خروجی=/tmp/harness/index.html]
"""
import io, os, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/harness/index.html')
s = io.open(ROOT / 'www' / 'index.html', encoding='utf-8').read()

ANCHOR = '            const HELP_CONTENT = {'
assert s.count(ANCHOR) == 1, 'لنگر درج پیدا نشد'

HOOK = r'''            // ===== فقط ابزار تست (tools/html-harness): توابع خالص برای گرفتنِ خروجی طلایی =====
            window.__rpFn = {
                // --- تقویم ---
                jalCal, g2d, j2d, d2g, d2j, toJalaali, toGregorian, jalaaliMonthLength,
                toPersianDigits, pad2,
                dateToISO_ymd: (y, m, d) => dateToISO(new Date(y, m - 1, d)),
                isoAddDays, jsWeekdayToPersianIndex,
                isoToDate_ymd: (iso) => { const d = isoToDate(iso); return [d.getFullYear(), d.getMonth() + 1, d.getDate(), d.getDay()]; },
                // --- state (برای توابعی که از state می‌خوانند) ---
                setState(s) { state = s; pointsCacheMap = null; },
                getState() { return JSON.parse(JSON.stringify(state)); },
            };
'''
s = s.replace(ANCHOR, HOOK + ANCHOR, 1)
os.makedirs(out.parent, exist_ok=True)
io.open(out, 'w', encoding='utf-8').write(s)
print('harness →', out, round(len(s.encode()) / 1024), 'KB')
