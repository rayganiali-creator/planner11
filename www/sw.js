// نکته‌ی مهم برای دیپلوی: هر بار که نسخه‌ی جدیدی از برنامه را روی گیت‌هاب/سرور منتشر می‌کنید،
// این عدد نسخه را عوض کنید (v3 -> v4 -> ...). با این کار مرورگر/PWA نصب‌شده روی گوشی کاربر
// کش قدیمی را دور می‌ریزد و نسخه‌ی تازه را می‌گیرد. قبلاً این عدد ثابت می‌ماند و همین باعث می‌شد
// تغییرات (مثلاً رنگ پس‌زمینه) بعد از نصب PWA هیچ‌وقت به‌روزرسانی نشوند.
const CACHE_VERSION = 'v13';
const CACHE_NAME = 'routine-planner-' + CACHE_VERSION;
const ASSETS = ['./', './index.html', './manifest.json', './vendor/chart.umd.min.js'];

const REMINDER_DB = 'rp-reminders';
const REMINDER_STORE = 'items';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// صفحه می‌تواند با فرستادن این پیام، سرویس‌ورکرِ در حالِ انتظار را فوراً فعال کند
// (استفاده می‌شود برای این‌که آپدیت‌های جدید سریع‌تر به دست کاربر برسند).
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});

// استراتژی «network-first» برای صفحه‌ی اصلی (HTML): همیشه اول تلاش می‌کند نسخه‌ی
// تازه را از شبکه بگیرد و در کش هم به‌روزش می‌کند؛ فقط وقتی آفلاین است از کش استفاده
// می‌کند. این یعنی دیگر هیچ تغییری (رنگ، باگ‌فیکس و ...) روی گوشی کاربر گیر نمی‌کند.
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const isHTML = req.mode === 'navigate' || (req.headers.get('accept') || '').includes('text/html');

  if (isHTML) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req).then((cached) => cached || caches.match('./index.html')))
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) =>
      cached ||
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy)).catch(() => {});
          return res;
        })
        .catch(() => cached)
    )
  );
});

// با لمس نوتیفیکیشن، اگر برنامه باز است روی همان پنجره فوکوس می‌کند، وگرنه یک پنجره‌ی جدید باز می‌کند.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow('./index.html');
    })
  );
});

// ============================================================
// یادآوری‌ها وقتی برنامه کاملاً بسته است — بهترین تلاش ممکن
// ------------------------------------------------------------
// صفحه‌ی اصلی، لیست کارها/عادت‌هایی که سررسیدشان نزدیک است را داخل IndexedDB
// می‌نویسد. این‌جا، در Service Worker، هر وقت مرورگر به ما اجازه‌ی اجرا بدهد
// (رویداد periodicsync) آن لیست را چک می‌کنیم و نوتیف واقعی نشان می‌دهیم.
// توجه صادقانه: مرورگرها (به‌خصوص روی اندروید) فاصله‌ی زمانی periodicsync را خودشان
// تعیین می‌کنند (معمولاً چیزی بین چند ده دقیقه تا چند ساعت) و هیچ مرورگری بدون یک
// سرور Push واقعی، تحویل نوتیف را دقیقاً «سرِ ثانیه» وقتی برنامه کاملاً بسته است
// تضمین نمی‌کند. وقتی خودِ برنامه باز یا در پس‌زمینه (تب زنده) است، نوتیف‌ها دقیق
// و سر وقت نمایش داده می‌شوند.
// ============================================================
function rpOpenDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(REMINDER_DB, 1);
    req.onupgradeneeded = () => {
      if (!req.result.objectStoreNames.contains(REMINDER_STORE)) {
        req.result.createObjectStore(REMINDER_STORE, { keyPath: 'id' });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function rpCheckAndFireReminders() {
  return rpOpenDB().then((db) => new Promise((resolve) => {
    let tx;
    try { tx = db.transaction(REMINDER_STORE, 'readwrite'); } catch (e) { resolve(); return; }
    const store = tx.objectStore(REMINDER_STORE);
    const getAll = store.getAll();
    getAll.onsuccess = () => {
      const now = Date.now();
      const items = getAll.result || [];
      const due = items.filter((it) => it.dueAt <= now);
      due.forEach((it) => {
        self.registration.showNotification(it.title, {
          body: it.body,
          tag: it.tag,
          icon: 'icons/icon-192.png'
        });
        store.delete(it.id);
      });
      resolve();
    };
    getAll.onerror = () => resolve();
  })).catch(() => {});
}

self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'rp-check-reminders') {
    event.waitUntil(rpCheckAndFireReminders());
  }
});

// یک تلاش پشتیبان اضافه: بعضی مرورگرها periodicsync ندارند ولی sync معمولی دارند.
self.addEventListener('sync', (event) => {
  if (event.tag === 'rp-check-reminders-once') {
    event.waitUntil(rpCheckAndFireReminders());
  }
});
