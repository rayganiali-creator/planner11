// فروشگاهِ همین بیلد (bazaar | myket): از لایه‌ی Native پرسیده می‌شود (هر فلیور یک APK جدا).
import 'package:flutter/services.dart';

String currentStore = 'bazaar';

Future<void> loadStoreId() async {
  try {
    currentStore = await const MethodChannel('rp/native').invokeMethod<String>('storeId') ?? 'bazaar';
  } catch (_) {
    currentStore = 'bazaar';
  }
}

bool get isMyket => currentStore == 'myket';
String get storeFa => isMyket ? 'مایکت' : 'کافه‌بازار';
String get storeEn => isMyket ? 'Myket' : 'Cafe Bazaar';

/// قیمتِ هر پلن از خودِ فروشگاه (فقط مایکت)؛ اگر نبود، قیمتِ ثبت‌شده در برنامه نشان داده می‌شود.
final Map<String, String> storePrices = {};

Future<void> refreshStorePrices(List<String> skus) async {
  if (!isMyket) return;
  const c = MethodChannel('rp/native');
  try {
    await c.invokeMethod('connect');
    final m = await c.invokeMethod<Map>('getPrices', {'skus': skus});
    if (m != null) {
      for (final e in m.entries) {
        final v = '${e.value}'.trim();
        if (v.isNotEmpty) storePrices['${e.key}'] = v;
      }
    }
  } catch (_) {}
}
