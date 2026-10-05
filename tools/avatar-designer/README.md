# Avatar Studio (ابزار مستقل و موقت)

ابزار طراحی آواتار برای «روتین پلنر» — جدا از خود اپ، بدون سرور، همه‌چیز محلی (IndexedDB/localStorage).

- باز کردن: فایل `dist/avatar-designer.html` را در مرورگر (Chrome/Edge/Safari) باز کنید.
- ساخت مجدد: `python3 import_app.py` (آواتار واقعی اپ → seed) سپس `python3 build.py`
- تست: `NODE_PATH=$(npm root -g) node test/run.js`
- خروجی نهایی: دکمه‌ی **Export** ← «بسته‌ی کامل (ZIP)» ← همان را برای Claude بفرستید.
- ذخیره‌ی پروژه برای ادامه‌ی کار بعدی: Export ← «پروژه (.rpa)»؛ بازیابی با **Import**.
