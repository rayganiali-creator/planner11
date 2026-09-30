// لحظه‌ی وسوسه + دلیل‌ها + پاداش/تنبیه. قواعدِ نسخه‌ی HTML.
import 'dart:math';

import 'actions.dart';
import 'urge_data.dart';

class UrgeItem {
  final String id, emoji, text, scope;
  final String? habitId;
  final bool isDefault;
  UrgeItem(this.id, this.emoji, this.text, this.scope, this.habitId, this.isDefault);
}

extension UrgeOps on AppActions {
  bool get _fa => store.state['lang'] != 'en';
  List<Map> get _habitsL => (store.state['habits'] as List).cast<Map>();

  List<UrgeItem> allUrgeSuggestions() {
    final s = store.state;
    final hidden = (s['urgeHiddenIds'] is List ? s['urgeHiddenIds'] as List : const []).toSet();
    final general = _fa ? 'عمومی' : 'General';
    final out = <UrgeItem>[];
    for (final u in urgeSuggestions) {
      if (hidden.contains(u.$1)) continue;
      out.add(UrgeItem(u.$1, u.$2, _fa ? u.$3 : u.$4, general, null, true));
    }
    for (final c in (s['customUrgeSuggestions'] is List ? (s['customUrgeSuggestions'] as List).cast<Map>() : const <Map>[])) {
      out.add(UrgeItem('${c['id']}', '${c['emoji'] ?? '💡'}', '${c['text']}', general, null, false));
    }
    for (final h in _habitsL) {
      for (final c in (h['urgeSuggestions'] is List ? (h['urgeSuggestions'] as List).cast<Map>() : const <Map>[])) {
        out.add(UrgeItem('${c['id']}', '${c['emoji'] ?? '💡'}', '${c['text']}', '${h['name']}', h['id'] as String, false));
      }
    }
    return out;
  }

  List<UrgeItem> shuffledUrges([Random? r]) {
    final a = allUrgeSuggestions();
    final rnd = r ?? Random();
    for (int i = a.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final t = a[i];
      a[i] = a[j];
      a[j] = t;
    }
    return a;
  }

  void deleteUrge(UrgeItem it) {
    final s = store.state;
    if (it.isDefault) {
      if (s['urgeHiddenIds'] is! List) s['urgeHiddenIds'] = [];
      final l = s['urgeHiddenIds'] as List;
      if (!l.contains(it.id)) l.add(it.id);
    } else if (it.habitId != null) {
      final h = _habitsL.where((x) => x['id'] == it.habitId).firstOrNull;
      if (h != null && h['urgeSuggestions'] is List) h['urgeSuggestions'] = (h['urgeSuggestions'] as List).where((x) => (x as Map)['id'] != it.id).toList();
    } else {
      s['customUrgeSuggestions'] = ((s['customUrgeSuggestions'] as List?) ?? const []).where((x) => (x as Map)['id'] != it.id).toList();
    }
    store.save();
  }

  bool addUrge(String text, String? habitId) {
    final t = text.trim();
    if (t.isEmpty) return false;
    final item = <String, dynamic>{
      'id': 'u_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${List.generate(5, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[Random().nextInt(36)]).join()}',
      'emoji': '💡',
      'text': t,
    };
    if (habitId != null && habitId.isNotEmpty) {
      final h = _habitsL.where((x) => x['id'] == habitId).firstOrNull;
      if (h != null) (h['urgeSuggestions'] is List ? h['urgeSuggestions'] as List : (h['urgeSuggestions'] = <Map>[])).add(item);
    } else {
      (store.state['customUrgeSuggestions'] is List ? store.state['customUrgeSuggestions'] as List : (store.state['customUrgeSuggestions'] = <Map>[])).add(item);
    }
    store.save();
    return true;
  }

  // ---------------------------------------------------------------- دلیل‌ها
  void saveReason(String hid, String iso, String status, String reason) {
    final s = store.state;
    if (s['reasons'] is! Map) s['reasons'] = <String, dynamic>{};
    final r = s['reasons'] as Map;
    if (r[hid] is! Map) r[hid] = <String, dynamic>{};
    (r[hid] as Map)[iso] = {'status': status, 'reason': reason.isEmpty ? '(بدون دلیل)' : reason, 'timestamp': DateTime.now().millisecondsSinceEpoch};
    store.save();
  }

  List<String> previousReasons(String hid, String status) {
    final r = store.state['reasons'];
    final all = r is Map && r[hid] is Map ? r[hid] as Map : const {};
    final set = <String>{};
    for (final e in all.values) {
      if (e is Map && e['status'] == status && e['reason'] is String && (e['reason'] as String).isNotEmpty && e['reason'] != '(بدون دلیل)') set.add(e['reason']);
    }
    return set.toList();
  }

  /// متنِ پاداش/تنبیهِ عادت برای وضعیت؛ null اگر خالی باشد
  (String title, String habit, String text)? rewardPunish(String hid, String status) {
    final h = _habitsL.where((x) => x['id'] == hid).firstOrNull;
    if (h == null) return null;
    final text = '${(status == 'success' ? h['rewardText'] : h['punishmentText']) ?? ''}'.trim();
    if (text.isEmpty) return null;
    final title = status == 'success' ? (_fa ? '🎉 پاداش شما!' : '🎉 Your Reward!') : (_fa ? '⚠️ تنبیه شما' : '⚠️ Your Punishment');
    return (title, '${h['name']}', text);
  }
}
