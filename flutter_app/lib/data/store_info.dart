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
