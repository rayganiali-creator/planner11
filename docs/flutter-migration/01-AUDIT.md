# ۰۱ — Audit نسخه‌ی فعلی (HTML/CSS/JS + Capacitor)

> مبنا: commit `7e98b0f` (نسخه‌ی ۱.۰.۵، versionCode 6). همه‌ی اعداد از روی خودِ کد استخراج شده‌اند، نه حدسی.

## ۱. اندازه و ساختار

| مورد | مقدار |
|---|---|
| فایل اصلی | `www/index.html` — تک‌فایل، ۱۵٬۳۲۴ خط، ۲٫۶ MB (با ۲۹۹ تصویر base64 و فونت) |
| کد بدون داده‌های embed | ۱٫۳۷ MB |
| CSS | خط ۲۴ تا ۴۹۷۴ (~۵۰۰۰ خط) |
| HTML (بدنه) | خط ۴۹۷۹ تا ۶۱۶۵ — ۵۳۶ `id` یکتا، ۲۳ `modal-backdrop`، ۱۰ `section.view` |
| JS درون‌خطی | خط ۶۱۶۵ تا ۱۵۳۲۴ — ۳۹۷ تابع (۴۴ async)، ۲۵۹ `addEventListener` |
| بومی (Android) | `MainActivity.java`، `BazaarBillingPlugin.kt` (Poolakey 2.2.0)، Capacitor 8.5.2 |
| پلاگین‌های Capacitor | `@capacitor/app`, `filesystem`, `local-notifications`, `share` + `CapacitorHttp` (داخلی) |
| کتابخانه‌های وب | Chart.js 4.4.0، jsPDF 2.5.1، html2canvas 1.4.1، فونت Vazirmatn، آیکون‌های Lucide (sprite) |

## ۲. صفحه‌ها (`section.view`)

`dashboard` (خانه) · `habits` (عادت‌ها) · `month` (ثبت ماهانه) · `year` (ثبت سالانه) · `library` (کتابخونه) · `purchases` (خریدها) · `journal` (یادداشت) · `pomodoro` · `todo` (لیست کارها) · `settings`.

ناوبری: نوار پایین (خانه، عادت‌ها، **+**، ثبت ماهانه، کارها) و پنجره‌ی «انتخاب صفحه» (دکمه‌ی +). «چالش‌ها» و «لحظه‌ی وسوسه» صفحه نیستند، Modal‌اند.
پشته‌ی تاریخچه‌ی تب (`viewHistoryStack`، سقف ۲۰) و **دکمه‌ی Back اندروید** با اولویت ثابت (بخش ۷).

## ۳. Modal / Overlay‌ها (۲۳ + overlayهای تمام‌صفحه)

`addBookModal`, `logPagesModal`, `bookCompleteModal`, `habitModal`, `dayModal`, `reasonModal`, `levelCapstoneModal`, `urgeModal`, `challengeModal` (+ check-in), `habitChartsModal`, `proPlansModal`, `premiumPaywall`, `proExpiredModal`, `avatarPanel` + `avatarGenderPicker`، `todoEditModal`, `reminderPicker`, `helpModal`, `rpConfirm`, `rpPass` (رمز پشتیبان)، `tabsPicker`، `habitPhotoLightbox`، `profileDropdown`؛ تمام‌صفحه: `langOverlay`, `termsOverlay`, `onboardingOverlay`.
`openModalStack` ردیابی می‌کند چه چیزی «روی همه» است (برای Back).

## ۴. قابلیت‌ها (هر مورد باید در Flutter عیناً باشد)

### ۴.۱ عادت‌ها
- انواع: `binary` (موفق/ناموفق)، `numeric` (مقدار + هدف + `numericUnit`)، `timer` (دقیقه + هدف).
- `direction`: `more` | `less`. `priority`، `rewardPoints` (سقف ۵۰)، `rewardText`/`punishmentText`.
- زمان‌بندی: `permanent` / `endDate` / `durationDays`؛ `scheduleMode: custom` + `activeDays` (اندیس فارسی، شنبه=۰)؛ `weeklyGoal`.
- یادآوری: `reminderEnabled`, `reminderTime`, `lastReminderDate`.
- `targetAtTime` روی هر رکورد عددی/زمانی (تغییر هدف، گذشته را دوباره ارزیابی نمی‌کند — `freezeHabitRecordTargets`).
- سطح‌ها: دو مرحله‌ی ۶ تایی (۲۵۰…۲۰۰۰ = «استادی»؛ ۲۵۰۰…۵۰۰۰ = «استاد اعظم»)، `unlockedStage`، `levelToastSent`.
- دلایل (`reasons[hid][iso]`)، محرک‌ها (`triggers`, `triggerType`)، یادداشت هر عادت (`habitNotes`)، عکس هر عادت (IndexedDB).
- نمودار کوچک هر عادت (محرک/مشوق/علت موفقیت/علت شکست) — `openHabitChartsModal`.
- بهترین رکورد، streak، درصد پیشرفت.
- محدودیت رایگان: ۳ عادت.

### ۴.۲ امتیاز / سکه / سطح حساب
- `getRecordPoints`: موفق = `+reward` (سقف ۵۰)، ناموفق = `−max(1, round(reward/2))`.
- `computeAllHabitPoints` (cache با `pointsCacheMap` که با `saveState` باطل می‌شود).
- `addCoins/removeCoins`: **سقف ۵۰ در هر عملیات** (`COIN_MAX_PER_OP`). `syncCoinsFromPoints` (delta مثبت → سکه).
- `getAccountLevelFromCoins` (دستاوردها)، `announceAccountLevelUpIfNeeded`.
- streak: `computeStreak`, `computePermanentStreak`, `computeHabitStreak`, `computeHabitBestRecord`.

### ۴.۳ لیست کارها
زیرکارها (رایگان: ۳)، تکرار (`repeatMode`, `repeatDays`, `lastActiveResetDate`)، `dueAt`، یادآوری، ویرایش.

### ۴.۴ کتابخونه
کتاب (`totalPages`, `pagesRead`, `history`, `reward`, `remindAt`)، سطح کتابخوان، عکس‌ها و **یادداشت صوتی** (IndexedDB)، ثبت صفحه، پایان کتاب. رایگان: ۳ کتابِ در حال خواندن.

### ۴.۵ ژورنال / یادداشت
`journal[]` با `{jy,jm,jd,text,remindAt,at}` + یادآوری. ژورنال رفتاری (`behaviorJournal`) در تحلیل هوشمند. *(«عهدنامه» در کد فعلی حذف شده: `state.vows` در هر بارگذاری پاک می‌شود — باید در Flutter هم **همین** رفتار حفظ شود، یعنی پاک‌شدن؛ نه بازسازی.)*

### ۴.۶ چالش‌ها و مدال‌ها
`CHALLENGE_PRESETS` (رایگان: ۲ آماده)، چالش سفارشی (`kind`: count | timed | both)، `deadlineAt`، `reminderIntervalHours` (تا ۶۰ آلارم)، `rewardCoins`، check-in، تاریخچه، مدال‌ها (پرو).

### ۴.۷ پومودورو
`POMO_DEFAULTS {focus:25, short:5, long:15}`، فاز، شروع/مکث/ادامه، زمان‌بندی با «لحظه‌ی پایان»، نوتیفیکیشن پایان، صدای `AudioContext`، ارتعاش.

### ۴.۸ آواتار و فروشگاه
- بوم ۱۸۰×۱۸۶، `AV_OFF_X=25`، جعبه‌ی حیوان `{cx:142,bottom:182}`.
- **۱۶۳ آیتم**: clothes/top ۱۰، clothes/outfit ۲۰، pants ۱۰، shoes ۹، hair ۱۰، hat ۱۰، hijab ۱۰، armor ۵، helmet ۹، cape ۱۰، sword ۱۵، shield ۹، pet ۲۰، petgear ۱۶. جنسیت: both ۹۴ / male ۴۹ / female ۲۰.
- داده‌ی هندسی: `bases` (مدل‌های مرد/زن)، `sleep`، `hands` (مشت بسته)، `head`، `petAnchor` (سر/گردن/مقیاس)، `cond` (hurt/sick)، per-item `fit`, `flip`, `po`, `price`.
- لایه‌بندی، `avHairUnderHat`، سایه، پاپ‌آپ، آینه (`avMirror`)، **تنفس** (`rpBreathe`)، بستن چشم در حالت خواب/بیماری، **HP** (`computeAvatarHP`: ۳ روز کامل گذشته + امروز).
- حیوان: چند آیتم هم‌زمان (`petgear_head` / `petgear_neck`) + مهاجرت از `eq.petgear` قدیمی.
- خرید با سکه (`spendCoins`)، کمد، تعویض جنسیت، پیش‌نمایش، پین.
- **شبانه‌روزی** (`rpApplySkyPhase`, `rpIsDay`, `rpIsNightSleep`) بر اساس ساعت دستگاه.

### ۴.۹ پرو / پرداخت
`PRO_PLANS`: `rp_pro_1m/2m/3m/6m` (۳۹/۶۸/۹۹/۱۷۹ هزار تومان)، محصول قدیمیِ `premium_unlock` (همیشگی).
- `computeProWindow`: هر پلن از **انتهای پلن قبلی** شروع می‌شود؛ ماه = ۳۰ روز.
- ساعت مطمئن (`rpNow`): یکنوا + `performance.now` + هدر `Date` از `cafebazaar.ir`/`api.cafebazaar.ir`.
- امضای کش (`rpSig`، FNV-1a + salt)، `recomputeTrustedPremiumFlag` (هرگز `isPremium` خام را باور نمی‌کند).
- انقضا → پیام + `consume` خریدهای تمام‌شده. یادآوری سیستمی پایان پلن.
- تب «خریدها»: کارت وضعیت، پلن‌ها، تاریخچه‌ی خط‌زمانی، بازیابی.
- کد مالک: PBKDF2-HMAC-SHA256 (۳۰۰٬۰۰۰) روی `SHA-256(salt+code)`.
- قفل‌های پرو: تحلیل هوشمند، مدال‌ها، آیتم‌های پولی آواتار، عکس/صوت کتاب، …

### ۴.۱۰ تحلیل رفتار هوشمند (پرو)
`saCompute/saInsights/saSuggestion` + نمودار + ژورنال رفتاری.

### ۴.۱۱ تنظیمات
زبان (fa/en)، تم روشن/تاریک + `themeIntensity` (۰..۱۰۰ ترکیب پیوسته)، رنگ زمینه، ۶ تم تأکید (فیروزه‌ای، آبی، بنفش، صورتی، کهربایی، خاکستری؛ هرکدام روشن+تاریک)، الگوی زمینه (`PATTERNS`) + شفافیت، شکل و افکت کاشی، رنگ کاشی‌ها، رنگ سطح/استادی، اندازه‌ی فونت (small/medium/large)، تقویم (شمسی/میلادی)، شروع هفته، نمایش تعطیلات، نام پروفایل، قوانین، راهنما، آموزش اولیه، تماس، نسخه، **پشتیبان‌گیری**.

### ۴.۱۲ Backup / Export
- JSON نسخه‌ی `3.0` (بخش ۶). خروجی: `exportDataBtn` (Downloads) و `shareDataBtn` (Share sheet).
- **رمزگذاری اختیاری** AES-GCM-256 + PBKDF2-SHA256 (۳۰۰٬۰۰۰)، پوشش JSON `{rpEncrypted:1,…}`.
- CSV (با BOM UTF-8، ستون‌های تاریخ/تاریخ شمسی/عادت/وضعیت/مقدار) و PDF (یک صفحه، از DOM با html2canvas → jsPDF).
- اعتبارسنجی `rpValidateBackup` + بازیابی «کاندید، بعد جایگزین» (داده‌ی خراب هیچ‌وقت نیمه‌کاره نمی‌نشیند).

### ۴.۱۳ راهنما/آموزش/قوانین
`ONBOARDING_SLIDES` (نسخه‌ی ۳)، `HELP_CONTENT`، `TERMS_SECTIONS` (نسخه‌ی ۵، ۹ بخش) با پذیرش اجباری قبل از هر چیز، انتخاب زبان.

### ۴.۱۴ لحظه‌ی وسوسه
`URGE_SUGGESTIONS` + سفارشی + مخفی‌سازی (`urgeHiddenIds`)، دامنه (همه/هر عادت).

## ۵. State و ذخیره‌سازی

**کلید:** `localStorage["alshadow-v14-level-colors"]` = **یک سند JSON** (کل `state`).
**IndexedDB:** `HABIT_PHOTOS_DB` (عکس عادت + عکس کتاب)، `rp-voice-notes` (store `notes`، index `bookId`؛ رکورد `{id,bookId,blob,at,ms}`)، `rp-reminders` (فقط برای Service Worker/PWA).

فیلدهای `state` (نقطه‌ی شروع در کد؛ سند زنده فیلدهای دیگر هم می‌سازد):
`theme, lang, bgColor, accentTheme, tileColors{success,fail,neutral}, habits[], records{iso:{hid:value}}, journal[], todos[], books[], scores{points,level,streak,lastDate,coins,lastPoints}, weekStart, showHolidays, calendarType, fontSize, bgPattern, tileShape, tileEffect, bgPatternOpacity, themeIntensity, profileName, reasons, triggers, triggerType, levelToastSent, levelReachedColor, masteryColor, customUrgeSuggestions[], urgeHiddenIds[], habitNotes, onboardingDone, langChosen, isPremium(محاسبه‌ای), proCache, avatar{gender,owned{},equipped{male{},female{}}}, termsAcceptedVersion, termsAcceptedAt, challenges[]` + `medals[], behaviorJournal{}, pomodoro, clock{lastSeen,lastSync}, __rpOwnerMark`.

### رفتارهای بارگذاری که باید عیناً بمانند
1. `Object.assign(defaults, stored)` — فیلدِ ناشناخته **حفظ** می‌شود.
2. `rpNormalizeState`: آرایه/شیء نادرست → مقدار درست؛ حذف عادت/کار/کتاب/چالشِ بی‌`id`؛ حذف روزِ خراب؛ حذف فیلدهای مرده (`coins, level, calorie, vows`).
3. `migrateTargetSnapshots` (قفل کردن `targetAtTime`).
4. `onboardingDone` undefined → `true` (کاربر قدیمی)، `langChosen` از آن مشتق می‌شود.
5. ذخیره‌ی ناموفق (حافظه‌ی پر) → پیام هشدار و **تغییر ثبت نمی‌شود**.
6. بازگشت `isPremium` همیشه از `recomputeTrustedPremiumFlag`.

## ۶. قالب فایل پشتیبان (نسخه‌ی `3.0`)

```
{ version:"3.0", exportedAt, appName:"روتین پلنر",
  data:{ habits, records, journal, todos, books, challenges, scores, medals, pomodoro,
         behaviorJournal, habitNotes, reasons, triggers, customUrgeSuggestions, urgeHiddenIds,
         avatar, levelToastSent, theme, lang, bgColor, accentTheme, weekStart, showHolidays,
         calendarType, fontSize, tileColors, bgPattern, tileShape, tileEffect, bgPatternOpacity,
         themeIntensity, profileName, triggerType, levelReachedColor, masteryColor,
         bookPhotos:{bookId:[dataUrl]}, habitPhotos:{habitId:[dataUrl]},
         bookVoices:{bookId:[{id,at,ms,type,dataUrl}]} } }
```
رمزدار: `{rpEncrypted:1, app, createdAt, kdf:{name:"PBKDF2",hash:"SHA-256",iterations,salt(b64)}, cipher:"AES-GCM", iv(b64), data(b64)}`.
نکته: `proCache`، `isPremium`، `clock` و `__rpOwnerMark` **عمداً داخل پشتیبان نیستند**.

## ۷. رفتارهای Android که باید حفظ شوند

| قابلیت | پیاده‌سازی فعلی | نکته |
|---|---|---|
| Back | `rpHandleAndroidBack`: ۱) بالاترین Modal (زبان/قوانین اجباری بسته نمی‌شوند؛ آموزش اولیه با `closeOnboarding`) ۲) منوی پروفایل ۳) لایت‌باکس عکس ۴) برگشت در پشته‌ی تب‌ها (یا خانه) ۵) در خانه: `exitApp` | ترتیب ثابت |
| یادآوری کار/عادت/چالش | `LocalNotifications.schedule({at, allowWhileIdle:true})`، شناسه = هش ۳۱ بیتی از رشته (`rpNumericId`) | عادت: **۱۴ نوبت بعدی** فقط در روزهای فعال؛ چالش: تا ۶۰ آلارم؛ بازتنظیم در هر باز شدن (`nativeResyncAllReminders`) |
| مجوز اعلان | `checkPermissions/requestPermissions` | Android 13+ |
| آلارم دقیق | `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` | بعد از ریبوت باید دوباره ساخته شود |
| ذخیره‌ی فایل | `saveToDownloads` (MediaStore، Android 10+، بدون مجوز) → در خطا `Filesystem`+`Share` | CSV/PDF/JSON |
| اشتراک | `Share.share({files})` | پشتیبان |
| میکروفون | `RECORD_AUDIO` + `getUserMedia` | یادداشت صوتی (حداکثر ۵ دقیقه) |
| پرداخت | Poolakey: `connect, purchase, consume, getPurchasedProducts` + **RSA public key** | `queries` برای `com.farsitel.bazaar` لازم است |
| شبکه | فقط `cafebazaar.ir` و `api.cafebazaar.ir` (HEAD برای ساعت) | CSP فعلی همین را تضمین می‌کند |
| `allowBackup=false` | عمداً (سیاست حریم خصوصی) | باید در Flutter هم بماند |
| روز/شب | `new Date().getHours()` → `rpApplySkyPhase` | ساعت دستگاه |
| کلیپ‌بورد/vibrate/AudioContext | Web APIs | معادل Flutter لازم |

## ۸. وابستگی‌های جانبی (برای `THIRD-PARTY-LICENSES.md`)
Vazirmatn (SIL OFL)، Chart.js / jsPDF / html2canvas (MIT)، Lucide (ISC)، Capacitor (MIT)، Poolakey (Apache-2.0).

## ۹. آنچه «Web-only» است و معادل بومی دارد (حذف نیست، جایگزینی است)
Service Worker / PWA / `rp-reminders` IndexedDB / `manifest.json`: فقط برای حالت مرورگر بود. روی اندروید نیتیو از ابتدا با `LocalNotifications` جایگزین شده (همان کدِ `isNativeApp()`). در Flutter معادلش `flutter_local_notifications` است و **رفتار کاربر تغییر نمی‌کند**.
