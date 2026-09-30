// ایجاد/ویرایش/حذف/جابه‌جایی عادت — همان قواعدِ کنترل‌کننده‌های نسخه‌ی HTML.
import 'dart:math';

import '../core/calendar.dart';
import '../core/gameplay.dart';
import '../core/habits.dart';
import '../core/js_compat.dart';
import 'actions.dart';

const int freeHabitLimit = 3;

String newHabitId([int? nowMs, Random? rnd]) {
  final t = (nowMs ?? DateTime.now().millisecondsSinceEpoch).toRadixString(36);
  final r = rnd ?? Random();
  final s = List.generate(5, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[r.nextInt(36)]).join();
  return 'h_$t$s';
}

class HabitForm {
  String name = '', createdAt = '';
  String priority = 'yellow', scheduleMode = 'daily', type = 'binary', direction = 'more';
  bool permanent = true, reminderEnabled = false;
  int durationDays = 30, rewardPoints = 10;
  List<int> activeDays = [];
  num numericTarget = 1, timerTarget = 30;
  String numericUnit = 'بار', rewardText = '', punishmentText = '', reminderTime = '08:00';
  int? weeklyGoal;

  HabitForm(String todayIso) : createdAt = todayIso;

  HabitForm.from(Map h) {
    name = '${h['name'] ?? ''}';
    createdAt = '${h['createdAt']}';
    priority = '${h['priority'] ?? 'yellow'}';
    scheduleMode = '${h['scheduleMode'] ?? 'daily'}';
    activeDays = [for (final d in (h['activeDays'] is List ? h['activeDays'] as List : const [])) (d as num).toInt()];
    direction = '${h['direction'] ?? 'more'}';
    permanent = h['permanent'] != false;
    if (!permanent && h['endDate'] != null) {
      durationDays = max(1, isoToDate('${h['endDate']}').difference(isoToDate(createdAt)).inDays + 1);
    }
    type = '${h['type'] ?? 'binary'}';
    numericTarget = jsOr(h['numericTarget'], 1) as num;
    numericUnit = '${jsOr(h['numericUnit'], 'بار')}';
    timerTarget = jsOr(h['timerTarget'], 30) as num;
    weeklyGoal = h['weeklyGoal'] is num ? (h['weeklyGoal'] as num).toInt() : null;
    rewardText = '${h['rewardText'] ?? ''}';
    punishmentText = '${h['punishmentText'] ?? ''}';
    rewardPoints = h['rewardPoints'] is num && h['rewardPoints'] != 0 ? min(coinMaxPerOp, (h['rewardPoints'] as num).toInt()) : 10;
    reminderEnabled = h['reminderEnabled'] == true;
    reminderTime = h['reminderTime'] is String && (h['reminderTime'] as String).isNotEmpty ? h['reminderTime'] : '08:00';
  }

  Map<String, dynamic> toMap() {
    final d = <String, dynamic>{
      'name': name.trim(),
      'createdAt': createdAt,
      'priority': priority,
      'permanent': permanent,
      'endDate': permanent ? null : isoAddDays(createdAt, max(1, durationDays) - 1),
      'scheduleMode': scheduleMode,
      'activeDays': scheduleMode == 'custom' ? [...activeDays] : <int>[],
      'type': type,
      'direction': direction,
      'rewardText': rewardText.trim(),
      'punishmentText': punishmentText.trim(),
      'rewardPoints': min(coinMaxPerOp, max(1, rewardPoints)),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime.isEmpty ? '08:00' : reminderTime,
    };
    if (weeklyGoal != null) d['weeklyGoal'] = weeklyGoal;
    if (type == 'numeric') {
      d['numericTarget'] = numericTarget == 0 ? 1 : numericTarget;
      d['numericUnit'] = numericUnit.trim().isEmpty ? 'بار' : numericUnit.trim();
    }
    if (type == 'timer') d['timerTarget'] = timerTarget == 0 ? 30 : timerTarget;
    return d;
  }
}

extension HabitOps on AppActions {
  List<Map> get _habits => (store.state['habits'] as List).cast<Map>();

  bool canCreateHabit() => store.state['isPremium'] == true || _habits.length < freeHabitLimit;

  /// برمی‌گرداند: شناسه‌ی عادتِ ذخیره‌شده (یا null اگر نام خالی/روز انتخاب نشده)
  String? saveHabit(HabitForm f, {String? editingId}) {
    if (f.name.trim().isEmpty) return null;
    if (f.scheduleMode == 'custom' && f.activeDays.isEmpty) return null;
    final d = f.toMap();
    String id;
    if (editingId == null) {
      id = newHabitId();
      (store.state['habits'] as List).add({'id': id, ...d});
    } else {
      id = editingId;
      final h = _habits.where((x) => x['id'] == id).firstOrNull;
      if (h != null) {
        freezeHabitRecordTargets(store.state, h); // هدفِ قدیمی روی رکوردهای گذشته قفل می‌شود
        if (!d.containsKey('weeklyGoal')) h.remove('weeklyGoal');
        h.addAll(d);
      }
    }
    store.save();
    renderAll();
    return id;
  }

  void deleteHabit(String id) {
    final s = store.state;
    s['habits'] = _habits.where((h) => h['id'] != id).toList();
    final rec = s['records'];
    if (rec is Map) {
      for (final iso in rec.keys.toList()) {
        final day = rec[iso];
        if (day is Map) {
          day.remove(id);
          if (day.isEmpty) rec.remove(iso);
        }
      }
    }
    for (final k in ['reasons', 'triggers', 'habitNotes']) {
      if (s[k] is Map) (s[k] as Map).remove(id);
    }
    final sent = s['levelToastSent'];
    if (sent is Map) sent.removeWhere((k, _) => '$k'.startsWith('${id}_level_'));
    store.save();
    renderAll();
  }

  void moveHabitDown(int idx) {
    final l = store.state['habits'] as List;
    if (idx < l.length - 1) {
      final t = l[idx];
      l[idx] = l[idx + 1];
      l[idx + 1] = t;
      store.save();
    }
  }
}
