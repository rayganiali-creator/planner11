// تست تفاضلی منطق پرو (پنجره‌ی پلن‌ها، امضای کش، ساعت مطمئن، تشخیص پرو، روز مانده، خط‌زمانی).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/pro.dart';

import 'golden_loader.dart';

TrustedClock _clock(Map a) {
  final s = a['sess'] as Map?;
  final t = a['trust'] as Map?;
  return TrustedClock(
    sessionAnchor: s == null ? null : (eff: s['eff'] as num, perf: s['perf'] as num),
    trustedAnchor: t == null ? null : (server: t['server'] as num, perf: t['perf'] as num),
  );
}

num _now(Map st, Map a) => _clock(a).now(dateNow: a['date'] as num, perfNow: a['perf'] as num, lastSeen: (st['clock'] as Map?)?['lastSeen']);

Map<String, dynamic> _copy(Object? st) => jsonDecode(jsonEncode(st)) as Map<String, dynamic>;

void main() {
  final cases = (loadGolden('pro') as List).cast<Map<String, dynamic>>();

  Object? run(String fn, List a) {
    switch (fn) {
      case 'proWindow':
        final w = computeProWindow(a[0] as List?);
        return {'lifetime': w.lifetime, 'expiresAt': w.expiresAt, 'list': w.list};
      case 'rpSig_obj':
        return rpSig(a[0] as Map);
      case 'rpNowWith':
        return _now(a[0] as Map, a[1] as Map);
      case 'recomputePremium':
        final st = _copy(a[0]);
        return recomputeTrustedPremiumFlag(st, _now(st, a[1] as Map));
      case 'daysLeft':
        final st = _copy(a[0]);
        return proDaysLeft(st, _now(st, a[1] as Map));
      case 'segments':
        final st = _copy(a[0]);
        return [
          for (final s in proPurchaseSegments(st))
            {'pid': s.p['productId'], 'plan': s.plan?.id, 'lifetime': s.lifetime, 'unknown': s.unknown, 'from': s.from, 'to': s.to}
        ];
    }
    throw UnimplementedError(fn);
  }

  test('همه‌ی ${cases.length} مورد با خروجی JS یکسان است', () {
    final counts = <String, int>{};
    final bad = <String, int>{};
    final msgs = <String>[];
    for (final c in cases) {
      final fn = c['fn'] as String;
      counts[fn] = (counts[fn] ?? 0) + 1;
      Object? got;
      try {
        got = run(fn, c['args']);
      } catch (e) {
        got = 'EXCEPTION: $e';
      }
      Object? want = c['ok'];
      // JS فیلدهای undefined را در JSON حذف می‌کند؛ مقدارهای null/غایب را یکی بگیر
      if (fn == 'proWindow') {
        got = {'lifetime': (got as Map)['lifetime'], 'expiresAt': got['expiresAt'], 'list': got['list']};
      }
      if (!deepEq(jsonDecode(jsonEncode(got)), want)) {
        bad[fn] = (bad[fn] ?? 0) + 1;
        if (msgs.length < 10) msgs.add('$fn(${jsonEncode(c['args']).substring(0, 220)})\n   Dart=${jsonEncode(got)}\n   JS  =${jsonEncode(want)}');
      }
    }
    // ignore: avoid_print
    print('تعداد هر تابع: $counts');
    expect(bad, isEmpty, reason: 'اختلاف‌ها: $bad\n${msgs.join('\n')}');
  });
}
