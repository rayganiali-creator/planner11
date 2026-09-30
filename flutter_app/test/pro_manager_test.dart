import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/core/pro.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/native_api.dart';
import 'package:routine_planner/data/notifier.dart';
import 'package:routine_planner/data/pro_manager.dart';

class FakeNative implements NativeApi {
  final List<String> log = [];
  final List<Map> owned = [];
  Object? failWith;
  Map? nextPurchase;
  @override
  Future<void> connect() async {
    log.add('connect');
    if (failWith is NativeError && (failWith as NativeError).code == 'connection_failed') throw failWith!;
  }

  @override
  Future<Map> purchase(String productId) async {
    log.add('purchase $productId');
    if (failWith != null) throw failWith!;
    final p = nextPurchase ?? {'productId': productId, 'purchaseToken': 'tok-$productId', 'purchaseTime': DateTime.now().millisecondsSinceEpoch};
    owned.add(p);
    return p;
  }

  @override
  Future<void> consume(String t) async {
    log.add('consume $t');
    owned.removeWhere((p) => p['purchaseToken'] == t);
  }

  @override
  Future<List<Map>> getPurchasedProducts() async => [...owned];
  @override
  Future<String> saveToDownloads({required String fileName, required String mimeType, required String base64Data}) async => 'content://x';
}

class Rec implements Notifier {
  final calls = <String>[];
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async => calls.add('sched $id $atMs');
  @override
  Future<void> cancel(String id) async => calls.add('cancel $id');
}

void main() {
  late Directory dir;
  late AppStore store;
  late FakeNative nat;
  late ToastBus toasts;
  late Rec notif;
  late ProManager pm;
  late List<String> shown;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('rp_pm');
    store = AppStore('${dir.path}/s.json')..load();
    nat = FakeNative();
    toasts = ToastBus();
    shown = [];
    toasts.addListener(() {});
    notif = Rec();
    pm = ProManager(store, nat, toasts, notif);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('خرید یک‌ماهه ← پرو؛ سپس دوماهه روی آن ← جمعِ روزها (۱۵ مانده + ۶۰ = ۷۵)', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const day = 86400000;
    nat.nextPurchase = {'productId': 'rp_pro_1m', 'purchaseToken': 'a', 'purchaseTime': now - 15 * day};
    await pm.purchase('rp_pro_1m');
    expect(store.state['isPremium'], isTrue);
    expect(proDaysLeft(store.state, store.rpNow()), 15);
    nat.nextPurchase = {'productId': 'rp_pro_2m', 'purchaseToken': 'b', 'purchaseTime': now};
    await pm.purchase('rp_pro_2m');
    expect(proDaysLeft(store.state, store.rpNow()), 75);
    expect(((store.state['proCache'] as Map)['purchases'] as List).length, 2);
    expect(notif.calls.any((c) => c.startsWith('sched pro-expiry')), isTrue);
    expect(nat.log.where((l) => l.startsWith('consume')), isEmpty); // تا پایانِ دوره مصرف نمی‌شود
    // امضا معتبر است و دستکاریِ کش پرو را خاموش می‌کند
    expect(recomputeTrustedPremiumFlag(store.state, store.rpNow()), isTrue);
    ((store.state['proCache'] as Map)['purchases'] as List).add({'productId': 'rp_pro_6m', 'purchaseToken': 'fake', 'purchaseTime': now});
    expect(recomputeTrustedPremiumFlag(store.state, store.rpNow()), isFalse);
  });

  test('لغو/خطا: پرو فعال نمی‌شود و پیام درست است', () async {
    nat.failWith = NativeError('cancelled');
    await pm.purchase('rp_pro_1m');
    expect(store.state['isPremium'], isNot(true));
    expect(purchaseErrorMessage(NativeError('cancelled'), true), 'خرید لغو شد.');
    expect(purchaseErrorMessage(NativeError('connection_failed'), false), contains('Cafe Bazaar'));
    expect(purchaseErrorMessage(NativeError('weird'), false), 'Purchase failed. Please try again.');
    expect(purchaseErrorMessage(NativeError('sku_not_found'), true), contains('فعال نشده'));
  });

  test('بازیابی: خرید موجود ← پرو؛ بدون خرید ← کشِ قبلی پاک؛ آفلاین ← کش می‌ماند؛ کدِ مالک دست‌نخورده', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    nat.owned.add({'productId': 'rp_pro_3m', 'purchaseToken': 't3', 'purchaseTime': now - 1000});
    nat.owned.add({'productId': 'ناشناس', 'purchaseToken': 'x', 'purchaseTime': now});
    await pm.restore();
    expect(store.state['isPremium'], isTrue);
    expect(((store.state['proCache'] as Map)['purchases'] as List).length, 1); // ناشناس فیلتر شد
    // آفلاین
    nat.failWith = NativeError('connection_failed');
    await pm.restore();
    expect(store.state['isPremium'], isTrue);
    // استرداد: بازار می‌گوید خریدی نیست
    nat.failWith = null;
    nat.owned.clear();
    await pm.restore();
    expect(store.state['isPremium'], isFalse);
    // مالک: با نشانه‌ی مالک، restore خاموشش نمی‌کند
    store.state['__rpOwnerMark'] = rpOwnerMarkValue;
    await pm.restore();
    expect(store.state['isPremium'], isTrue);
  });

  test('پایانِ دوره: پرو خاموش، پنجره‌ی پایان یک‌بار، خریدها مصرف', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const day = 86400000;
    nat.owned.add({'productId': 'rp_pro_1m', 'purchaseToken': 'old', 'purchaseTime': now - 40 * day});
    pm.setProFromPurchases([nat.owned.first], 'test'); // انقضا ۱۰ روز پیش
    var fired = 0;
    pm.onExpired = () => fired++;
    // setProFromPurchases خودش isPro=false می‌گذارد؛ برای سنجشِ مسیرِ انقضا، حالتِ «هنوز فعال بود» را می‌سازیم
    final pc = store.state['proCache'] as Map;
    pc['isPro'] = true;
    pc['sig'] = rpSig(pc);
    store.state['isPremium'] = true;
    await pm.checkProExpiry();
    expect(store.state['isPremium'], isFalse);
    expect(fired, 1);
    expect(nat.log, contains('consume old'));
    await pm.checkProExpiry();
    expect(fired, 1); // دوباره اعلام نمی‌شود
    expect(shown, isEmpty);
  });
}
