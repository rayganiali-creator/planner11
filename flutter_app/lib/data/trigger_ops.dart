// محرک/مشوق و علت‌های هر عادت (پنجره‌ی نمودارهای عادت). قواعدِ نسخه‌ی HTML؛ نسخه‌ی رایگان فقط ۷ روز اخیر را در نمودار می‌بیند.
import 'dart:math';

import '../core/calendar.dart';
import 'actions.dart';

String triggerUid() => 't_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${List.generate(5, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[Random().nextInt(36)]).join()}';

extension TriggerOps on AppActions {
  Map get _triggers {
    final s = store.state;
    if (s['triggers'] is! Map) s['triggers'] = <String, dynamic>{};
    return s['triggers'] as Map;
  }

  Map get _reasons {
    final s = store.state;
    if (s['reasons'] is! Map) s['reasons'] = <String, dynamic>{};
    return s['reasons'] as Map;
  }

  bool _inFreeWindow(String iso) {
    if (store.state['isPremium'] == true) return true;
    return iso.compareTo(dateToISO(addDays(startOfDay(today), -6))) >= 0;
  }

  List<Map> triggersFor(String hid) => ((_triggers[hid] as List?) ?? const []).whereType<Map>().toList();

  void addTrigger(String hid, String trigger, String type) {
    final l = _triggers[hid] is List ? _triggers[hid] as List : (_triggers[hid] = <Map>[]) as List;
    l.add({'id': triggerUid(), 'trigger': trigger.trim(), 'date': todayISO, 'type': type});
    store.save();
  }

  void removeTrigger(String hid, String tid) {
    if (_triggers[hid] is! List) return;
    final l = (_triggers[hid] as List).where((t) => t is Map && t['id'] != tid).toList();
    if (l.isEmpty) {
      _triggers.remove(hid);
    } else {
      _triggers[hid] = l;
    }
    store.save();
  }

  /// ثبتِ مستقیمِ علتِ موفقیت/شکست (بدون تیک‌زدنِ روز)
  void addManualReason(String hid, String status, String text) {
    final m = _reasons[hid] is Map ? _reasons[hid] as Map : (_reasons[hid] = <String, dynamic>{}) as Map;
    final key = 'm${DateTime.now().millisecondsSinceEpoch}_${List.generate(6, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[Random().nextInt(36)]).join()}';
    m[key] = {'status': status, 'reason': text.trim(), 'timestamp': DateTime.now().millisecondsSinceEpoch};
    store.save();
  }

  void deleteReasonFromHabit(String hid, String reason, String status) {
    final m = _reasons[hid];
    if (m is! Map) return;
    m.removeWhere((iso, e) => e is Map && e['status'] == status && e['reason'] == reason);
    if (m.isEmpty) _reasons.remove(hid);
    store.save();
  }

  Map<String, int> reasonFreq(String hid, String status) {
    final m = _reasons[hid];
    final out = <String, int>{};
    if (m is! Map) return out;
    m.forEach((iso, e) {
      if (!_inFreeWindow('$iso')) return;
      if (e is Map && e['status'] == status && e['reason'] is String && (e['reason'] as String).isNotEmpty && e['reason'] != '(بدون دلیل)') {
        out[e['reason']] = (out[e['reason']] ?? 0) + 1;
      }
    });
    return out;
  }

  Map<String, int> triggerFreq(String hid, String type) {
    final out = <String, int>{};
    for (final t in triggersFor(hid)) {
      final isInc = t['type'] == 'incentive';
      if ((type == 'incentive') != isInc) continue;
      out['${t['trigger']}'] = (out['${t['trigger']}'] ?? 0) + 1;
    }
    return out;
  }
}
