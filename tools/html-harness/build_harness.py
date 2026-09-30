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
                // --- منطق عادت/امتیاز/streak (بر اساس state فعلی و «امروزِ» ثابتِ مرورگر) ---
                _h: (hid) => state.habits.find(x => x.id === hid),
                habitAppliesOnISO_id(hid, iso) { return habitAppliesOnISO(window.__rpFn._h(hid), iso); },
                applicableIds(iso) { return applicableHabitsForISO(iso).map(h => h.id); },
                habitSuccessOnISO_id(hid, iso) { return habitSuccessOnISO(window.__rpFn._h(hid), iso); },
                dayStats_all(iso) { return dayStatsAll(iso); },
                dayStats_perm(iso) { return dayStats(iso, h => h.permanent !== false); },
                getStatusFromRecord_id(value, hid) { return getStatusFromRecord(value, window.__rpFn._h(hid)); },
                getRecordPoints_id(value, hid) { return getRecordPoints(value, window.__rpFn._h(hid)); },
                getHabitRewardPoints_id(hid) { return getHabitRewardPoints(window.__rpFn._h(hid)); },
                computeAllHabitPoints() { pointsCacheMap = null; return computeAllHabitPoints(); },
                computeTotalPoints() { pointsCacheMap = null; return computeTotalPoints(); },
                level_habit(points, hid) { return getLevelFromPoints(points, habitActiveThresholds(window.__rpFn._h(hid))); },
                level_base(points) { return getLevelFromPoints(points); },
                stageCount_id(hid) { return habitUnlockedStageCount(window.__rpFn._h(hid)); },
                computeStreak() { return computeStreak(); },
                computePermanentStreak() { return computePermanentStreak(); },
                computeHabitStreak_id(hid) { return computeHabitStreak(window.__rpFn._h(hid)); },
                computeHabitBestRecord_id(hid) { return computeHabitBestRecord(window.__rpFn._h(hid)); },
                collectSeries(range) { return collectSeries(range); },
                getTotalStats(range) { return getTotalStats(range); },
                getWeekStart_iso() { return dateToISO(getWeekStart(startOfDay(new Date()))); },
                getAccountLevelFromCoins(c) { return getAccountLevelFromCoins(c); },
                coinOps(ops) {   // [['add',x],['remove',y],['sync',z]…] → نتیجه‌ی هر گام و موجودی پایانی
                    const out = [];
                    ops.forEach(([op, x]) => {
                        if (op === 'add') out.push(addCoins(x)); else if (op === 'remove') out.push(removeCoins(x));
                        else { syncCoinsFromPoints(x); out.push(null); }
                        out.push(state.scores.coins); out.push(state.scores.lastPoints);
                    });
                    return out;
                },
            };
'''
s = s.replace(ANCHOR, HOOK + ANCHOR, 1)
os.makedirs(out.parent, exist_ok=True)
io.open(out, 'w', encoding='utf-8').write(s)
print('harness →', out, round(len(s.encode()) / 1024), 'KB')
