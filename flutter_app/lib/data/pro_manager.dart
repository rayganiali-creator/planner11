// اعتبارِ پرو (Entitlement) — پورتِ setProFromPurchases / checkProExpiry / restorePurchases / purchasePremium.
//  • شروعِ هر پلن = زمانِ خریدِ سرورِ بازار؛ پلن‌ها پشتِ هم (۷۵ روز = ۱۵ + ۶۰).
//  • خریدها تا پایانِ کل دوره consume نمی‌شوند (بازیابی روی گوشی جدید ممکن بماند).
//  • هرگز پرویی را که از راهِ دیگری (کدِ مالک) فعال شده خاموش نمی‌کند.
import '../app/toast.dart';
import '../core/pro.dart';
import 'app_store.dart';
import 'billing.dart';
import 'native_api.dart';
import 'notifier.dart';

String purchaseErrorMessage(Object e, bool fa) {
  final code = e is NativeError ? e.code : '$e';
  if (code == 'cancelled') return fa ? 'خرید لغو شد.' : 'Purchase cancelled.';
  if (code == 'connection_failed' || code == 'not_connected') {
    return fa
        ? 'اتصال به کافه‌بازار برقرار نشد. مطمئن شوید برنامه‌ی کافه‌بازار روی گوشی نصب است، وارد حساب شده‌اید و اینترنت دارید.'
        : 'Could not connect to Cafe Bazaar. Make sure the Bazaar app is installed, you are signed in, and you are online.';
  }
  if (code == 'failed_to_begin') return fa ? 'صفحه‌ی پرداخت کافه‌بازار باز نشد. کمی بعد دوباره امتحان کنید.' : "Cafe Bazaar's payment page could not be opened. Please try again shortly.";
  if (RegExp(r'not.?found|sku|product|item', caseSensitive: false).hasMatch(code)) return fa ? 'این پلن هنوز در کافه‌بازار فعال نشده است.' : 'This plan is not available on Cafe Bazaar yet.';
  return fa ? 'خرید انجام نشد. لطفاً دوباره تلاش کنید.' : 'Purchase failed. Please try again.';
}

class ProManager implements BillingService {
  final AppStore store;
  final NativeApi native;
  final ToastBus toasts;
  final Notifier notifier;
  void Function()? onExpired; // پنجره‌ی «پلن تمام شد»
  ProManager(this.store, this.native, this.toasts, this.notifier);

  bool get _fa => store.state['lang'] != 'en';

  void setProFromPurchases(List<Map> purchases, String source) {
    final w = computeProWindow(purchases);
    final now = store.rpNow();
    final prev = store.state['proCache'] is Map ? store.state['proCache'] as Map : const {};
    final list = [for (final p in w.list) {'productId': p['productId'], 'purchaseToken': p['purchaseToken'], 'purchaseTime': p['purchaseTime'] ?? 0}];
    final pc = <String, dynamic>{
      'isPro': w.lifetime || ((w.expiresAt ?? 0) > now),
      'expiresAt': w.expiresAt,
      'purchases': list,
      'checkedAt': now,
      'source': source,
      'expiredNotified': (prev['expiresAt'] == w.expiresAt) ? prev['expiredNotified'] == true : false,
    };
    pc['purchaseToken'] = list.isNotEmpty ? list.last['purchaseToken'] : null;
    pc['productId'] = list.isNotEmpty ? list.last['productId'] : null;
    pc['sig'] = rpSig(pc);
    store.state['proCache'] = pc;
    recomputeTrustedPremiumFlag(store.state, now);
    store.save();
    _scheduleExpiryNotice();
  }

  void _scheduleExpiryNotice() {
    final pc = store.state['proCache'];
    if (pc is! Map || pc['isPro'] != true || pc['expiresAt'] == null) return;
    notifier.scheduleOnce(
      'pro-expiry',
      _fa ? '⏳ پلن پرو شما به پایان رسید' : '⏳ Your Pro plan has ended',
      _fa ? 'برای ادامه‌ی استفاده از امکانات پرو، پلن را تمدید کنید.' : 'Renew to keep using Pro features.',
      (pc['expiresAt'] as num).toInt(),
    );
  }

  /// هر دقیقه و هنگام بازگشت به برنامه؛ پایانِ کل دوره ← پرو خاموش + خریدها مصرف
  Future<void> checkProExpiry() async {
    final s = store.state;
    final now = store.rpNow();
    final pc = s['proCache'];
    if (pc is! Map || pc['isPro'] != true || pc['expiresAt'] == null) {
      recomputeTrustedPremiumFlag(s, now);
      return;
    }
    if ((pc['expiresAt'] as num) > now) return;
    final expired = [for (final p in (pc['purchases'] as List? ?? const [])) Map.of(p as Map)];
    pc['isPro'] = false;
    final first = pc['expiredNotified'] != true;
    pc['expiredNotified'] = true;
    pc['sig'] = rpSig(pc);
    recomputeTrustedPremiumFlag(s, now);
    store.save();
    if (first && s['isPremium'] != true) onExpired?.call();
    try {
      await native.connect();
      for (final p in expired) {
        try {
          await native.consume('${p['purchaseToken']}');
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Future<void> purchase(String productId) async {
    try {
      await native.connect();
      final p = await native.purchase(productId);
      final prev = ((store.state['proCache'] is Map ? (store.state['proCache'] as Map)['purchases'] : null) as List? ?? const []).cast<Map>();
      final all = [
        ...prev.where((x) => x['purchaseToken'] != p['purchaseToken']),
        {'productId': p['productId'], 'purchaseToken': p['purchaseToken'], 'purchaseTime': p['purchaseTime'] ?? store.rpNow()},
      ];
      setProFromPurchases(all, 'purchase');
      toasts.show(_fa ? '🎉 نسخه‌ی کامل فعال شد!' : '🎉 Full version unlocked!', ms: 3000);
    } catch (e) {
      toasts.show(purchaseErrorMessage(e, _fa), ms: 5000);
    }
  }

  @override
  Future<void> restore({bool announce = false}) async {
    void say(String fa, String en) {
      if (announce) toasts.show(_fa ? fa : en, ms: 3600);
    }

    try {
      await native.connect();
      final res = await native.getPurchasedProducts();
      final allIds = {legacyLifetimeProductId, ...proPlans.map((p) => p.id)};
      final owned = res.where((p) => allIds.contains(p['productId'])).toList();
      if (owned.isNotEmpty) {
        setProFromPurchases([for (final p in owned) {'productId': p['productId'], 'purchaseToken': p['purchaseToken'], 'purchaseTime': p['purchaseTime'] ?? 0}], 'restore');
        await checkProExpiry();
        if (store.state['isPremium'] == true) {
          say('✅ خریدت بازیابی شد و پرو فعال است.', '✅ Your purchase was restored and Pro is active.');
        } else {
          say('پلن‌های قبلی‌ات پیدا شد ولی مدتشان تمام شده است.', 'Your earlier plans were found but they have ended.');
        }
      } else {
        final pc = store.state['proCache'];
        if (pc is Map && pc['purchases'] is List && (pc['purchases'] as List).isNotEmpty) {
          setProFromPurchases([], 'restore'); // پاسخِ رسمیِ بازار: خریدِ فعالی نیست (استرداد/مصرف‌شده)
        } else {
          recomputeTrustedPremiumFlag(store.state, store.rpNow());
          store.save();
        }
        if (store.state['isPremium'] == true) {
          say('پرو فعال است.', 'Pro is active.');
        } else {
          say('خرید فعالی در حساب کافه‌بازارِ این گوشی پیدا نشد.', 'No active purchase was found on this Cafe Bazaar account.');
        }
      }
    } catch (e) {
      await checkProExpiry(); // آفلاین: کشِ معتبر + ساعتِ مطمئن
      say('بازیابی انجام نشد. مطمئن شو برنامه‌ی کافه‌بازار نصب است، وارد حساب شده‌ای و اینترنت داری.', 'Restore failed. Make sure Cafe Bazaar is installed, you are signed in, and you are online.');
    }
  }
}
