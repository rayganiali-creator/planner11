// تست تفاضلی «بارگذاریِ state»: ۱۶۰ بارگذاریِ واقعیِ صفحه‌ی JS (با localStorage دستکاری‌شده) در برابر پورت Dart.
// شاملِ JSON خراب، نوع‌های اشتباه، فیلدهای مرده، رکوردهای قدیمیِ بدونِ targetAtTime، و کش پرو.
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/state_model.dart';

import 'golden_loader.dart';

// تفاوتِ آگاهانه: آواتار/سطحِ عادت (levelToastSent, levelReachedColor, masteryColor) حذف و progress/todoLog اضافه شد.
const _legacy = {'avatar', 'levelToastSent', 'levelReachedColor', 'masteryColor', 'progress', 'todoLog'};
Object? _strip(Object? o) => o is Map ? {for (final e in o.entries) if (!_legacy.contains(e.key)) e.key: _strip(e.value)} : o;

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
        diff = firstDiff(_strip(got), _strip(want));
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
