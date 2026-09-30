// تست تفاضلی «بارگذاریِ state»: ۱۶۰ بارگذاریِ واقعیِ صفحه‌ی JS (با localStorage دستکاری‌شده) در برابر پورت Dart.
// شاملِ JSON خراب، نوع‌های اشتباه، فیلدهای مرده، رکوردهای قدیمیِ بدونِ targetAtTime، و کش پرو.
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/state_model.dart';

import 'golden_loader.dart';

void main() {
  final rows = (loadGolden('load') as List).cast<Map<String, dynamic>>();

  test('همه‌ی ${rows.length} بارگذاری با خروجی JS یکسان است', () {
    int bad = 0;
    final msgs = <String>[];
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final want = r['ok'] as Map<String, dynamic>;
      Object? got;
      String? diff;
      try {
        final l = loadStateFromRaw(r['raw'] as String?, nowMs: r['nowMs'] as num);
        got = {'state': l.state, 'repaired': l.repaired};
        diff = firstDiff(got, want);
      } catch (e, st) {
        diff = 'EXCEPTION: $e\n$st';
      }
      if (diff != null) {
        bad++;
        if (msgs.length < 8) msgs.add('#$i raw=${(r['raw'] as String?)?.substring(0, ((r['raw'] as String).length).clamp(0, 90))}\n   $diff');
      }
    }
    expect(bad, 0, reason: '$bad مورد متفاوت:\n${msgs.join('\n')}');
  });
}
