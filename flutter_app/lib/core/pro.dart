// پورت منطق «حق دسترسی پرو»: پنجره‌ی زمانیِ پلن‌های انباشته، امضای کش، ساعت مطمئن و
// تشخیص پرو بودن. هر تابع با خروجی طلایی JS سنجیده می‌شود (test/pro_test.dart).
import 'doc.dart';
import 'js_compat.dart';


const String premiumUnlockSalt = 'routineplanner-salt-9f3';
const String legacyLifetimeProductId = 'premium_unlock';

// نشانه‌ی داخلیِ وضعیت مالک: ۱۲ نویسه‌ی اول از کلیدِ مشتق‌شده + '-ok' (همان JS).
const String premiumUnlockKey = 'a9d28d7b025b30e436344ceaa0e8b673273f3591230c040a07e97021df5e71bc';
final String rpOwnerMarkValue = '${premiumUnlockKey.substring(0, 12)}-ok';

class ProPlan {
  final String id, priceFa, priceEn, labelFa, labelEn;
  final int months;
  const ProPlan(this.id, this.months, this.priceFa, this.priceEn, this.labelFa, this.labelEn);
}

const List<ProPlan> proPlans = [
  ProPlan('rp_pro_1m', 1, '۳۹٬۰۰۰ تومان', '39,000 Toman', '۱ ماهه', '1 Month'),
  ProPlan('rp_pro_2m', 2, '۶۸٬۰۰۰ تومان', '68,000 Toman', '۲ ماهه', '2 Months'),
  ProPlan('rp_pro_3m', 3, '۹۹٬۰۰۰ تومان', '99,000 Toman', '۳ ماهه', '3 Months'),
  ProPlan('rp_pro_6m', 6, '۱۷۹٬۰۰۰ تومان', '179,000 Toman', '۶ ماهه', '6 Months'),
];

/// هر «ماه» = ۳۰ روز.
int planDurationMs(int months) => months * 30 * 24 * 3600 * 1000;

ProPlan? findProPlan(Object? productId) {
  for (final p in proPlans) {
    if (p.id == productId) return p;
  }
  return null;
}

num _time(Object? v) {
  final n = jsToNumber(jsOr(v, 0));
  return n.isNaN ? 0 : n;
}

/// مرتب‌سازی پایدار (مثل Array.prototype.sort در ES2019): برابرها ترتیبِ اولشان را نگه می‌دارند.
List<Map> _sortedByTime(List purchases) {
  final idx = <MapEntry<int, Map>>[];
  for (int i = 0; i < purchases.length; i++) {
    final p = purchases[i];
    if (p is Map) idx.add(MapEntry(i, p));
  }
  idx.sort((a, b) {
    final c = _time(a.value['purchaseTime']).compareTo(_time(b.value['purchaseTime']));
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return [for (final e in idx) e.value];
}

/// زمانِ خریدِ هر رسید را پایدار می‌کند: بازیابی هرگز تاریخِ خرید را «جلو» نمی‌برد.
/// - اگر همان رسید (purchaseToken) قبلاً روی گوشی ثبت شده، زمانِ کوچک‌تر (قدیمی‌تر) می‌ماند.
/// - زمانِ نامعتبر/صفر ← «اولین باری که دیده شد» (الان)، و از آن به بعد ثابت می‌ماند.
/// - زمانِ آینده به «الان» محدود می‌شود.
List<Map> stabilizePurchaseTimes(List<Map> restored, List prev, num now) {
  final known = <String, num>{};
  for (final p in prev) {
    if (p is! Map) continue;
    final t = _time(p['purchaseTime']);
    final k = '${p['purchaseToken']}';
    if (t > 0 && p['purchaseToken'] != null) known[k] = known.containsKey(k) && known[k]! < t ? known[k]! : t;
  }
  return [
    for (final p in restored)
      () {
        num t = _time(p['purchaseTime']);
        if (t <= 0 || t > now) t = now;
        final old = known['${p['purchaseToken']}'];
        if (old != null && old < t) t = old;
        return {'productId': p['productId'], 'purchaseToken': p['purchaseToken'], 'purchaseTime': t};
      }()
  ];
}

typedef ProWindow = ({bool lifetime, num? expiresAt, List<Map> list});

/// هر پلنِ تازه از «انتهای پلنِ قبلی» شروع می‌شود، نه از امروز.
ProWindow computeProWindow(List? purchases) {
  num exp = 0;
  bool lifetime = false;
  final list = _sortedByTime(purchases ?? const []);
  for (final p in list) {
    if (p['productId'] == legacyLifetimeProductId) {
      lifetime = true;
      continue;
    }
    final plan = findProPlan(p['productId']);
    if (plan == null) continue;
    final t = _time(p['purchaseTime']);
    final start = exp > t ? exp : t;
    exp = start + planDurationMs(plan.months);
  }
  return (lifetime: lifetime, expiresAt: lifetime ? null : (exp == 0 ? 0 : exp), list: list);
}

/// JSON.stringify مطابق JS برای ساختارهای ساده (عدد، رشته، null، لیست).
String jsJsonStringify(Object? v) {
  if (v == null) return 'null';
  if (v is bool) return v ? 'true' : 'false';
  if (v is num) return (v is double && (v.isNaN || v.isInfinite)) ? 'null' : jsString(v);
  if (v is String) return _jsonStr(v);
  if (v is List) return '[${v.map((e) => jsJsonStringify(e)).join(',')}]';
  return 'null';
}

String _jsonStr(String s) {
  final b = StringBuffer('"');
  for (final c in s.codeUnits) {
    switch (c) {
      case 0x22: b.write('\\"'); break;
      case 0x5C: b.write('\\\\'); break;
      case 0x08: b.write('\\b'); break;
      case 0x0C: b.write('\\f'); break;
      case 0x0A: b.write('\\n'); break;
      case 0x0D: b.write('\\r'); break;
      case 0x09: b.write('\\t'); break;
      default:
        if (c < 0x20) {
          b.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
        } else {
          b.writeCharCode(c);
        }
    }
  }
  b.write('"');
  return b.toString();
}

/// امضای ساده روی کشِ پرو (FNV-1a ۳۲ بیتی): ویرایش دستیِ ذخیره‌سازی کش را باطل می‌کند.
String rpSig(Map obj) {
  final purchases = obj['purchases'];
  final list = purchases is List ? purchases : const [];
  final arr = [
    obj['isPro'],
    obj['expiresAt'],
    [for (final p in list) [(p as Map)['productId'], p['purchaseToken'], p['purchaseTime']]],
    jsOr(obj['legacyUntil'], 0),
  ];
  final str = '${jsJsonStringify(arr)}|rp-pro-v2|$premiumUnlockSalt';
  int h = 0x811c9dc5;
  for (final c in str.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(36);
}

/// ساعت مطمئن (Trusted Clock) — «الان» هیچ‌وقت فقط از ساعت گوشی گرفته نمی‌شود.
class TrustedClock {
  /// مقدارهای اولیه‌ی نقطه‌ی لنگر (جلسه/سرور)؛ null = تنظیم نشده.
  ({num eff, num perf})? sessionAnchor;
  ({num server, num perf})? trustedAnchor;
  TrustedClock({this.sessionAnchor, this.trustedAnchor});

  /// [dateNow] = Date.now() ، [perfNow] = performance.now() ، [lastSeen] = state.clock.lastSeen
  num now({required num dateNow, required num perfNow, Object? lastSeen}) {
    final ls = jsToNumber(jsOr(lastSeen, 0));
    final last = ls.isNaN ? 0 : ls;
    final ta = trustedAnchor;
    if (ta != null) {
      final v = ta.server + (perfNow - ta.perf);
      return v > last ? v : last;
    }
    num t = dateNow > last ? dateNow : last;
    final sa = sessionAnchor;
    if (sa != null) {
      final v = sa.eff + (perfNow - sa.perf);
      if (v > t) t = v;
    }
    return t;
  }
}

num _asNum(Object? v) => jsToNumber(v);

/// `state.isPremium` را فقط از منابع واقعی می‌سازد (رسیدِ کافه‌بازار یا نشانه‌ی مالک).
bool recomputeTrustedPremiumFlag(Doc state, num nowMs) {
  final pc = state['proCache'];
  Map? c = pc is Map ? pc : null;
  final purchases = c?['purchases'];
  final hasProof = c != null && (jsTruthy(c['purchaseToken']) || (purchases is List && purchases.isNotEmpty));
  bool sigOk = false;
  if (c != null) {
    sigOk = !c.containsKey('sig') ? !jsTruthy(purchases) : c['sig'] == rpSig(c);
  }
  final exp = c?['expiresAt'];
  final bazaarOk = c != null && c['isPro'] == true && hasProof && sigOk && (exp == null || _asNum(exp) > nowMs);
  final ownerOk = state['__rpOwnerMark'] == rpOwnerMarkValue;
  final r = bazaarOk || ownerOk;
  state['isPremium'] = r;
  return r;
}

/// روزهای باقی‌مانده؛ null = بی‌پایان یا پرو نیست.
int? proDaysLeft(Doc state, num nowMs) {
  final pc = state['proCache'];
  if (!jsTruthy(state['isPremium']) || pc is! Map || pc['expiresAt'] == null) return null;
  final d = ((_asNum(pc['expiresAt']) - nowMs) / 86400000).ceil();
  return d < 0 ? 0 : d;
}

/// بخش‌های خط‌زمانیِ تب «خریدها» (هر خرید + بازه‌ی اعتبارش).
typedef ProSegment = ({Map p, ProPlan? plan, bool lifetime, bool unknown, num from, num? to});

List<ProSegment> proPurchaseSegments(Doc state) {
  final pc = state['proCache'];
  final list = _sortedByTime(pc is Map && pc['purchases'] is List ? pc['purchases'] as List : const []);
  num exp = 0;
  final out = <ProSegment>[];
  for (final p in list) {
    final t = _time(p['purchaseTime']);
    if (p['productId'] == legacyLifetimeProductId) {
      out.add((p: p, plan: null, lifetime: true, unknown: false, from: t, to: null));
      continue;
    }
    final plan = findProPlan(p['productId']);
    if (plan == null) {
      out.add((p: p, plan: null, lifetime: false, unknown: true, from: t, to: t));
      continue;
    }
    final from = exp > t ? exp : t;
    exp = from + planDurationMs(plan.months);
    out.add((p: p, plan: plan, lifetime: false, unknown: false, from: from, to: exp));
  }
  return out;
}
