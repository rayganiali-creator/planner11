# ۰۲ — معماری Flutter

## اصل‌های حاکم
1. **هیچ redesign نیست.** هر ویجت از روی یک عنصرِ مشخص در HTML ساخته می‌شود و با اسکرین‌شات مقایسه می‌شود.
2. **سند JSON واحد، مثل نسخه‌ی فعلی.** `state` همان `Map<String,dynamic>` است و با نمای تایپ‌دار (extension) خوانده می‌شود؛ مدل‌های سخت‌گیرانه (freezed/json_serializable) عمداً استفاده **نمی‌شود**، چون فیلدِ ناشناخته باید حفظ شود و سند زنده فیلدهایی دارد که در هیچ schema‌ای تعریف نشده‌اند.
3. **منطق خالص جدا از UI** (`lib/core/`)، و هر تابعش با **تست تفاضلی** (differential test) در برابر خودِ JS سنجیده می‌شود: ورودی یکسان → خروجی یکسان.
4. **HTML/Capacitor دست‌نخورده می‌ماند.** Flutter در `flutter_app/` است و CI جداگانه دارد.

## نقشه‌ی فناوری

| نیاز | نسخه‌ی فعلی | Flutter | وضعیت معادل |
|---|---|---|---|
| State | شیء سراسری `state` + `saveState()` + `renderAll()` | `AppStore extends ChangeNotifier` نگهدارنده‌ی همان Map؛ `save()` = تغییر نسخه + نوشتن اتمیک + `notifyListeners()` | مستقیم |
| ذخیره‌ی سند | `localStorage` | فایل `state.json` در `getApplicationSupportDirectory()` با نوشتن اتمیک (tmp→rename) و `state.json.bak` | مستقیم (بهتر: localStorage سقف ~۵MB دارد) |
| عکس/صدا | IndexedDB | فایل در `media/{habit,book,voice}/…` + `index.json` | مستقیم |
| تقویم شمسی | `g2d/d2j/…` | پورت عین‌به‌عین به Dart | مستقیم + تست تفاضلی |
| نمودار | Chart.js (doughnut، bar، line) با تم اختصاصی `rpStyleChartConfig` | `CustomPainter` (نه `fl_chart`) تا گرادیان/گوشه‌ی گرد/فاصله‌ی حلقه‌ها/عدد وسط دقیقاً مثل فعلی شود | **نیاز به بازسازی** (معادل مستقیم ندارد) — پیاده‌سازی دستی |
| آواتار | `<canvas>` ۱۸۰×۱۸۶ + ۲۹۹ PNG | `CustomPainter` + `dart:ui Image` از `assets/avatar/` + `avatar_data.json` (همان `AV_DATA`) | مستقیم |
| تنفس/انیمیشن | `rpBreathe` | `Ticker`/`AnimationController` | مستقیم |
| نوتیفیکیشن | Capacitor LocalNotifications | `flutter_local_notifications` (`zonedSchedule` + `exactAllowWhileIdle`) + `timezone` | مستقیم |
| پرداخت | `BazaarBillingPlugin.kt` (Poolakey) | همان کلاس Kotlin به‌صورت `MethodChannel` (کلید RSA و منطق دست‌نخورده) | مستقیم |
| ذخیره در Downloads | `saveToDownloads` (MediaStore) | همان کد Kotlin زیر `MethodChannel` | مستقیم |
| اشتراک‌گذاری | Capacitor Share | `share_plus` | مستقیم |
| Back اندروید | `rpHandleAndroidBack` | `PopScope(canPop:false)` + یک `BackCoordinator` با **همان ترتیب اولویت** | مستقیم |
| میکروفون | `MediaRecorder` | `record` (AAC/Opus) + `audioplayers`/`just_audio` برای پخش | مستقیم؛ **فرمت صوتِ قدیمی (webm/opus) باید پخش شود** ← بخش خطرها |
| رمزنگاری | WebCrypto | `package:cryptography` (یا `pointycastle`) | مستقیم + تست cross-implementation با فایل‌های تولیدشده‌ی JS |
| PDF | html2canvas → jsPDF از DOM | `RepaintBoundary` → PNG → بسته‌ی `pdf` | **بازسازی** — خروجی باید از نظر بصری همانند باشد |
| CSV | رشته + BOM | `dart:convert` | مستقیم |
| فونت | Vazirmatn (woff2 در فایل) | TTF/OTF متغیر در `assets/fonts` (Flutter از woff2 پشتیبانی نمی‌کند) | مستقیم؛ تبدیل فونت لازم |
| آیکون | Lucide + map ایموجی→آیکون (`RP_ICON_MAP`) | `lucide_icons_flutter` یا SVG → `flutter_svg`؛ همان map | مستقیم |
| i18n | جفت‌های `data-fa/data-en` و رشته‌های درون‌خطی | مولد: استخراج خودکار همه‌ی جفت‌ها به `strings.g.dart`؛ تابع `tr(fa,en)` | مستقیم (متن‌ها کپی می‌شوند، بازنویسی نمی‌شوند) |
| RTL/LTR | `dir` | `Directionality` بر اساس `state.lang` | مستقیم |
| تم | CSS variables + `deriveBgVars` | `ThemeExtension` با همان محاسبات HSL و `mixHexColors` | مستقیم + تست تفاضلی روی رنگ‌ها |
| Responsive | media queries + `aspect-ratio` | `LayoutBuilder` با همان breakpointها | مستقیم |
| روز/شب | `getHours()` | `DateTime.now().hour` | مستقیم |
| Service Worker/PWA | مرورگر | — | **حذف‌نیست**: فقط وب بود، روی اندروید نیتیو پیشتر با LocalNotifications جایگزین شده |

### وابستگی‌های pub (پیشنهادی، حداقل)
`provider`, `path_provider`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `share_plus`, `record`, `just_audio`, `image_picker`, `flutter_image_compress`, `pdf`, `cryptography`, `flutter_svg`, `vibration`, `permission_handler`. (قفل شده با `pubspec.lock`؛ هیچ‌کدام سرور/آنالیتیکس ندارد.)

## ساختار پوشه‌ها

```
flutter_app/
  lib/
    core/        ← منطق خالص (تقویم، سطح/امتیاز، streak، pro-window، backup، normalize، رنگ)
    data/        ← AppStore، ذخیره‌ی اتمیک، media، migration
    platform/    ← MethodChannel: billing، downloads، back
    features/    ← هر صفحه/Modal یک پوشه (dashboard, habits, month, year, library, purchases, journal, pomodoro, todo, settings, avatar, challenges, urge, onboarding, terms)
    ui/          ← تم، کاشی، Modal پایه، نمودارها
  assets/        ← avatar/*.png، avatar_data.json، fonts، strings
  test/          ← تست‌های تفاضلی + golden
  tool/          ← اسکریپت‌های استخراج (i18n، avatar_data، golden از JS)
```

## استراتژی تست تفاضلی (قلب «بدون تغییر در محصول»)
1. در **نسخه‌ی تست** HTML، hookهای `__rpTest` اضافه می‌شود که توابع خالص را صدا می‌زند (فقط در `build_test.py`، نه محصول).
2. اسکریپت Playwright برای هر تابع، هزاران ورودی (تصادفی با seed ثابت + مرزی) را اجرا و `golden/*.json` می‌سازد.
3. تست Dart همان ورودی‌ها را می‌خواند و خروجی را **به‌صورت دقیق** مقایسه می‌کند.
4. برای UI: اسکرین‌شات HTML (Playwright، viewport ثابت) در برابر `flutter build web` (یا golden) با diff پیکسلی و آستانه‌ی مشخص.

## ترتیب Migration ویژگی‌ها (وابستگی‌ها از پایین به بالا)
۱) `core` خالص ← ۲) ذخیره/نرمال‌سازی/پشتیبان ← ۳) تم و پوسته (ناوبری، Back، Modal پایه) ← ۴) عادت‌ها + ثبت ماهانه/سالانه + خانه ← ۵) لیست کارها + یادآوری ← ۶) کتابخونه + عکس/صوت ← ۷) ژورنال + پومودورو ← ۸) نمودارها + تحلیل هوشمند ← ۹) چالش/مدال/دستاورد ← ۱۰) آواتار/فروشگاه ← ۱۱) پرو/پرداخت/خریدها ← ۱۲) تنظیمات/خروجی/PDF ← ۱۳) آموزش/راهنما/قوانین.
