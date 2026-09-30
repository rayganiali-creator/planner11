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
# لحظه‌ی پایانِ خطِ لوله‌ی بارگذاریِ state (قبل از هر کدِ دیگری که ممکن است state را عوض کند)
LOADED_ANCHOR = '''            rpInitClock(); // برای نصب تازه (بدون داده‌ی ذخیره‌شده) هم ساعت مطمئن مقداردهی بشه
            recomputeTrustedPremiumFlag();
'''
assert s.count(LOADED_ANCHOR) == 1, 'لنگر بارگذاری پیدا نشد'
s = s.replace(LOADED_ANCHOR, LOADED_ANCHOR + "            window.__rpLoaded = { state: JSON.parse(JSON.stringify(state)), repaired: !!_rpStateWasRepaired };   // فقط تست\\n", 1)
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
                habitProgressPct_id(hid) { return habitProgressPct(window.__rpFn._h(hid)); },
                computeHabitStreak_id(hid) { return computeHabitStreak(window.__rpFn._h(hid)); },
                computeHabitBestRecord_id(hid) { return computeHabitBestRecord(window.__rpFn._h(hid)); },
                collectSeries(range) { return collectSeries(range); },
                smart(range, lang) {
                    const oldLang = state.lang; state.lang = lang; saRange = range;
                    const cur = saCompute(saPeriod(0)), prev = saCompute(saPeriod(1));
                    const strip = t => String(t).replace(/<\/?bdi>/g, '');
                    const pack = r => ({ succ: r.succ, fail: r.fail, rate: r.rate, perfect: r.perfect, zero: r.zero, activeDays: r.activeDays, dueDays: r.dueDays,
                        recovery: r.recovery, recN: r.recN, consistency: r.consistency, byWeekday: r.byWeekday.map(w => [w.s, w.f]),
                        byHabit: Object.fromEntries(Object.entries(r.byHabit).map(([k, h]) => [k, { s: h.s, f: h.f, best: h.best, name: h.name }])),
                        trig: JSON.parse(JSON.stringify(r.trig)), failReasons: r.failReasons, winReasons: r.winReasons, series: r.series });
                    const res = { cur: pack(cur), prev: pack(prev), insights: saInsights(cur, prev).map(x => ({ level: x.level, ico: x.ico, t: strip(x.t), s: strip(x.s), w: x.w })) };
                    state.lang = oldLang; return res;
                },
                getTotalStats(range) { return getTotalStats(range); },
                getWeekStart_iso() { return dateToISO(getWeekStart(startOfDay(new Date()))); },
                getAccountLevelFromCoins(c) { return getAccountLevelFromCoins(c); },
                // --- پرو: ساعت قابل‌کنترل (Date.now / performance.now / لنگرها) ---
                _withClock(a, fn) {
                    const od = Date.now, op = performance.now;
                    Date.now = () => a.date; performance.now = () => a.perf;
                    const os = rpSessionAnchor, ot = rpTrustedAnchor;
                    rpSessionAnchor = a.sess || null; rpTrustedAnchor = a.trust || null;
                    try { return fn(); } finally { Date.now = od; performance.now = op; rpSessionAnchor = os; rpTrustedAnchor = ot; }
                },
                rpNowWith(st, a) { state = st; return window.__rpFn._withClock(a, () => rpNow()); },
                proWindow(purchases) { const w = computeProWindow(purchases); return { lifetime: w.lifetime, expiresAt: w.expiresAt, list: w.list }; },
                rpSig_obj(o) { return rpSig(o); },
                recomputePremium(st, a) { state = st; return window.__rpFn._withClock(a, () => { recomputeTrustedPremiumFlag(); return state.isPremium; }); },
                daysLeft(st, a) { state = st; return window.__rpFn._withClock(a, () => proDaysLeft()); },
                segments(st, a) { state = st; return window.__rpFn._withClock(a, () => proPurchaseSegments().map(s => ({ pid: s.p.productId, plan: s.plan ? s.plan.id : null, lifetime: !!s.lifetime, unknown: !!s.unknown, from: s.from, to: s.to }))); },
                ownerMark() { return RP_OWNER_MARK_VALUE; },
                // --- گیم‌پلی: ثبتِ عادت + مشتق‌سازی (renderDashboard) با ضبطِ toast/پنجره ---
                runOps(st, ops) {
                    state = window.__rpFn._clone(st); pointsCacheMap = null;
                    const ev = [];
                    const oShow = showToast, oCap = openLevelCapstoneModal, oAll = renderAll;
                    showToast = (m, d, c) => { ev.push(['toast', c || '', m, d]); };
                    openLevelCapstoneModal = (h, lv) => { ev.push(['capstone', h.id, lv.num]); };
                    renderAll = () => { renderDashboard(); };
                    try {
                        ops.forEach(op => {
                            if (op[0] === 'bin') setBinaryRecord(op[1], op[2], op[3]);
                            else if (op[0] === 'val') setValueRecord(op[1], op[2], op[3]);
                            else if (op[0] === 'clear') clearRecord(op[1], op[2]);
                            else if (op[0] === 'derive') renderDashboard();
                        });
                    } finally { showToast = oShow; openLevelCapstoneModal = oCap; renderAll = oAll; }
                    const out = window.__rpFn._clone(state); delete out.clock;
                    return { state: out, events: ev };
                },
                clockText(lang) { state.lang = lang; renderClock(); return document.getElementById('clockText').textContent; },
                traceOps(st, ops) {   // عیب‌یابی: وضعیتِ امتیاز/سکه بعد از هر گام
                    state = window.__rpFn._clone(st); pointsCacheMap = null;
                    const oShow = showToast, oCap = openLevelCapstoneModal, oAll = renderAll;
                    showToast = () => {}; openLevelCapstoneModal = () => {}; renderAll = () => { renderDashboard(); };
                    const tr = [];
                    try { ops.forEach(op => {
                        if (op[0] === 'bin') setBinaryRecord(op[1], op[2], op[3]); else if (op[0] === 'val') setValueRecord(op[1], op[2], op[3]);
                        else if (op[0] === 'clear') clearRecord(op[1], op[2]); else renderDashboard();
                        tr.push([op[0], state.scores.coins, state.scores.lastPoints, state.scores.points]);
                    }); } finally { showToast = oShow; openLevelCapstoneModal = oCap; renderAll = oAll; }
                    return tr;
                },
                hpInfo(st) { state = window.__rpFn._clone(st); rpDataVersion++; const hp = computeAvatarHP(); return { hp, cond: [0, 6, 7, 12, 18, 19, 23].map(h => { const o = Date.prototype.getHours; Date.prototype.getHours = () => h; try { return avConditionOf(hp); } finally { Date.prototype.getHours = o; } }) }; },
                // --- یادآوری‌ها: پلاگین اعلانِ جعلی که فراخوانی‌ها را ضبط می‌کند ---
                async _recordNotifs(fn) {
                    const log = [];
                    const fake = {
                        checkPermissions: async () => ({ display: 'granted' }), requestPermissions: async () => ({ display: 'granted' }),
                        cancel: async (o) => { log.push(['cancel', o.notifications[0].id]); },
                        schedule: async (o) => { const n = o.notifications[0]; log.push(['schedule', n.id, n.title, n.body, n.schedule.at.getTime()]); },
                    };
                    const old = window.Capacitor;
                    window.Capacitor = { isNativePlatform: () => true, Plugins: { LocalNotifications: fake } };
                    try { fn(); await new Promise(r => setTimeout(r, 120)); } finally { window.Capacitor = old; }
                    return log;
                },
                async planResync(st) { state = window.__rpFn._clone(st); return await window.__rpFn._recordNotifs(() => nativeResyncAllReminders()); },
                async planDaily(st, hid, hh, mm) { state = window.__rpFn._clone(st); return await window.__rpFn._recordNotifs(() => nativeScheduleDailyHabit(hid, 'T', 'B', hh, mm)); },
                async planChallenge(st, ch) { state = window.__rpFn._clone(st); return await window.__rpFn._recordNotifs(() => nativeScheduleChallengeNotifications(ch)); },
                async planCancelChallenge(chId) { return await window.__rpFn._recordNotifs(() => nativeCancelChallengeNotifications(chId)); },
                numericId(str) { return rpNumericId(str); },
                nextHabitOccurrence(hh, mm) { return rpNextHabitOccurrence(hh, mm); },
                nextTodo(t) { return computeNextTodoOccurrence(t); },
                todoToday(t) { return todoAppliesToday(t); },
                // --- پشتیبان ---
                _clone: (x) => (x === undefined ? undefined : JSON.parse(JSON.stringify(x))),
                validateBackup(raw) { return window.__rpFn._clone(rpValidateBackup(window.__rpFn._clone(raw))); },
                restoreInto(st, raw) {
                    raw = window.__rpFn._clone(raw); state = window.__rpFn._clone(st); const v = rpValidateBackup(raw);
                    if (!v.ok) return { ok: false };
                    Object.keys(v.next).forEach(k => { state[k] = v.next[k]; });
                    if (!state.scores || typeof state.scores !== 'object') state.scores = { points: 0, level: 1, streak: 0, lastDate: null, coins: 0, lastPoints: 0 };
                    rpNormalizeState();
                    return { ok: true, state: JSON.parse(JSON.stringify(state)), skipped: v.skipped, version: v.version };
                },
                async createBackup(st) { state = st; return await createBackupJSON(); },
                async encrypt(plain, pass) { return await rpEncryptBackup(plain, pass); },
                async decrypt(envText, pass) { return await rpDecryptBackup(JSON.parse(envText), pass); },
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
