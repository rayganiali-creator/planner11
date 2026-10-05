// کدِ مدیر (tryPremiumUnlockCode در HTML): PBKDF2-HMAC-SHA256 با ۳۰۰٬۰۰۰ تکرار روی sha256(salt+code)
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../app/toast.dart';
import '../core/pro.dart';
import 'app_store.dart';

const String _kdfSalt = 'rp-owner-kdf-v2';
const int _kdfIter = 300000;

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

/// کلیدِ مشتق‌شده از کد (همان JS: rpDeriveBits(sha256Hex(SALT + val), KDF_SALT, ITER))
Future<String> deriveOwnerKey(String code, {int iterations = _kdfIter}) async {
  final h = _hex((await Sha256().hash(utf8.encode(premiumUnlockSalt + code))).bytes);
  final k = await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256).deriveKeyFromPassword(password: h, nonce: utf8.encode(_kdfSalt));
  return _hex(await k.extractBytes());
}

bool _eqConst(String a, String b) {
  if (a.length != b.length) return false;
  var d = 0;
  for (var i = 0; i < a.length; i++) {
    d |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return d == 0;
}

class OwnerUnlock {
  final AppStore store;
  final ToastBus toasts;
  final DateTime Function() clock;
  OwnerUnlock(this.store, this.toasts, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;
  int _attempts = 0;
  DateTime? _lockedUntil;
  bool get _fa => store.state['lang'] != 'en';

  /// true = پرو فعال شد
  Future<bool> tryCode(String raw) async {
    final now = clock();
    if (_lockedUntil != null && now.isBefore(_lockedUntil!)) {
      final s = _lockedUntil!.difference(now).inSeconds + 1;
      toasts.show(_fa ? '⏳ چند بار اشتباه زدی؛ $s ثانیه‌ی دیگه دوباره امتحان کن' : '⏳ Too many attempts; try again in ${s}s', ms: 2500);
      return false;
    }
    final val = raw.trim();
    String key = '';
    try {
      key = val.isEmpty ? '' : await deriveOwnerKey(val);
    } catch (_) {}
    if (val.isNotEmpty && _eqConst(key, premiumUnlockKey)) {
      _attempts = 0;
      store.state['__rpOwnerMark'] = rpOwnerMarkValue;
      recomputeTrustedPremiumFlag(store.state, store.rpNow());
      store.save();
      toasts.show(_fa ? '🎉 نسخه‌ی کامل فعال شد!' : '🎉 Full version unlocked!', ms: 3000);
      return true;
    }
    _attempts++;
    if (_attempts >= 5) {
      _lockedUntil = now.add(const Duration(seconds: 30));
      _attempts = 0;
      toasts.show(_fa ? '⏳ به‌خاطر تلاش زیاد، ۳۰ ثانیه قفل شد' : '⏳ Locked for 30s after too many attempts', ms: 2800);
    } else {
      toasts.show(_fa ? '❌ کد درست نیست' : '❌ Incorrect code', ms: 2000);
    }
    return false;
  }
}
