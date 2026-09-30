// چالش‌ها و مدال‌ها (قواعدِ نسخه‌ی HTML): آماده‌ها رایگان، چالش شخصی و مدال پرو؛ جایزه ≤ ۵۰ سکه.
import 'dart:math';

import '../core/habits.dart';
import 'actions.dart';
import 'notifier.dart';

const challengePresets = [
  (id: 'preset_social7', icon: '📵', nameFa: '۷ روز بدون شبکه‌های اجتماعی', nameEn: '7 days off social media', kind: 'timed', days: 7, target: 0, reward: 30),
  (id: 'preset_workout10', icon: '🏃', nameFa: '۱۰ جلسه ورزش', nameEn: '10 workout sessions', kind: 'count', days: 0, target: 10, reward: 40),
];
const challengeEmojis = ['🔥', '💪', '🏃', '📚', '🧘', '🚭', '💧', '🥗', '😴', '🎯', '✍️', '🧹', '🎨', '💰', '🚴', '🧊'];
const _msUnit = {'minutes': 60000, 'hours': 3600000, 'days': 86400000};

String challengeUid(String prefix, int nowMs) => '${prefix}_${nowMs}_${List.generate(6, (_) => '0123456789abcdefghijklmnopqrstuvwxyz'[Random().nextInt(36)]).join()}';

/// 'gold' برای چالش‌های بلند/سخت، 'silver' و 'bronze' کوتاه‌تر
String medalTier(Map ch) {
  final size = ((ch['targetCount'] as num?) ?? 0) +
      ((ch['deadlineAt'] is num && ch['createdAt'] is num) ? ((ch['deadlineAt'] as num) - (ch['createdAt'] as num)) / 86400000 : 0);
  return size >= 20 ? 'gold' : size >= 7 ? 'silver' : 'bronze';
}

class ChallengeForm {
  String name = '', icon = '🔥', kind = 'count', unit = '', rewardText = '', deadlineMode = 'duration', durationUnit = 'days';
  int target = 1, rewardCoins = 10, durationValue = 1, reminderHours = 2;
  bool reminderOn = false;
  int? exactAt;
}

extension ChallengeOps on AppActions {
  List<Map> get challenges {
    final s = store.state;
    if (s['challenges'] is! List) s['challenges'] = [];
    return (s['challenges'] as List).cast<Map>();
  }

  bool get _pro => store.state['isPremium'] == true;
  int get _now => clock().millisecondsSinceEpoch;
  bool get _fa => store.state['lang'] != 'en';

  bool presetRunning(String id) => challenges.any((c) => c['presetId'] == id && (c['status'] == 'active' || c['status'] == 'pending_review'));

  Map? joinPreset(String id, {Notifier? notifier}) {
    final p = challengePresets.where((x) => x.id == id).firstOrNull;
    if (p == null || presetRunning(id)) return null;
    final now = _now;
    final ch = <String, dynamic>{
      'id': challengeUid('ch', now), 'presetId': p.id, 'name': _fa ? p.nameFa : p.nameEn, 'icon': p.icon, 'kind': p.kind,
      'rewardCoins': min(coinMaxPerOp, p.reward), 'rewardText': '', 'createdAt': now, 'status': 'active', 'completedAt': null,
    };
    if (p.kind == 'count') {
      ch['targetCount'] = p.target;
      ch['progressCount'] = 0;
    }
    if (p.kind == 'timed') {
      ch['deadlineMode'] = 'duration';
      ch['durationValue'] = p.days;
      ch['durationUnit'] = 'days';
      ch['deadlineAt'] = now + p.days * 86400000;
      ch['reminderIntervalHours'] = null;
    }
    challenges.add(ch);
    store.save();
    _schedule(ch, notifier);
    return ch;
  }

  /// null = موفق؛ وگرنه 'pro' | 'name' | 'date'
  String? createChallenge(ChallengeForm f, {Notifier? notifier}) {
    if (!_pro) return 'pro';
    final name = f.name.trim();
    if (name.isEmpty) return 'name';
    final now = _now;
    final ch = <String, dynamic>{
      'id': challengeUid('ch', now), 'name': name, 'icon': f.icon, 'kind': f.kind,
      'rewardCoins': min(coinMaxPerOp, max(0, f.rewardCoins)), 'rewardText': f.rewardText.trim(), 'createdAt': now, 'status': 'active', 'completedAt': null,
    };
    final needsCount = f.kind == 'count' || f.kind == 'both', needsTimed = f.kind == 'timed' || f.kind == 'both';
    if (needsCount) {
      ch['targetCount'] = max(1, f.target);
      ch['unit'] = f.unit.trim().isEmpty ? (_fa ? 'بار' : 'x') : f.unit.trim();
      ch['progressCount'] = 0;
    }
    if (needsTimed) {
      if (f.deadlineMode == 'exact') {
        final at = f.exactAt;
        if (at == null || at <= now) return 'date';
        ch['deadlineAt'] = at;
        ch['durationValue'] = null;
        ch['durationUnit'] = null;
      } else {
        final v = max(1, f.durationValue);
        ch['durationValue'] = v;
        ch['durationUnit'] = f.durationUnit;
        ch['deadlineAt'] = now + v * _msUnit[f.durationUnit]!;
      }
      ch['reminderIntervalHours'] = f.reminderOn ? max(1, min(72, f.reminderHours)) : null;
    }
    challenges.add(ch);
    store.save();
    _schedule(ch, notifier);
    return null;
  }

  void _schedule(Map ch, Notifier? n) {
    if (n == null || ch['deadlineAt'] is! num) return;
    final title = _fa ? '⏰ مهلت چالش تموم شد' : '⏰ Challenge deadline reached';
    final body = _fa ? 'زمان چالش «${ch['name']}» تموم شد! انجامش دادی؟' : 'Time for "${ch['name']}" is up! Did you complete it?';
    n.scheduleOnce('challenge-${ch['id']}', title, body, (ch['deadlineAt'] as num).toInt());
  }

  /// جایزه: سکه (با سقفِ مرکزی) + مدال پرو. برمی‌گرداند سکه‌ی واقعاً داده‌شده
  int awardChallenge(Map ch) {
    if (_pro) {
      if (store.state['medals'] is! List) store.state['medals'] = [];
      final medals = (store.state['medals'] as List).cast<Map>();
      if (!medals.any((m) => m['challengeId'] == ch['id'])) {
        medals.add({'challengeId': ch['id'], 'name': ch['name'], 'tier': medalTier(ch), 'at': _now});
      }
    }
    final coins = addCoins(store.state, (ch['rewardCoins'] as num?) ?? 0);
    final rt = '${ch['rewardText'] ?? ''}';
    toasts.show(
      _fa ? '🎉 آفرین! چالش «${ch['name']}» موفق شد. +$coins سکه${rt.isNotEmpty ? ' + 🎁 $rt' : ''}' : '🎉 Well done! "${ch['name']}" succeeded. +$coins coins${rt.isNotEmpty ? ' + 🎁 $rt' : ''}',
      ms: 4200,
      cls: 'toast-success',
    );
    store.save();
    return coins;
  }

  Map? _byId(String id) => challenges.where((x) => x['id'] == id).firstOrNull;

  void incrementChallenge(String id, int delta, {Notifier? notifier}) {
    final c = _byId(id);
    if (c == null || c['status'] != 'active') return;
    final np = max(0, (((c['progressCount'] as num?) ?? 0).toInt()) + delta);
    c['progressCount'] = np;
    if (np >= (c['targetCount'] as num)) {
      c['status'] = 'success';
      c['completedAt'] = _now;
      store.save();
      notifier?.cancel('challenge-$id');
      awardChallenge(c);
    } else {
      store.save();
    }
  }

  void finishCountChallenge(String id, {Notifier? notifier}) {
    final c = _byId(id);
    if (c == null || c['status'] != 'active') return;
    c['progressCount'] = c['targetCount'];
    c['status'] = 'success';
    c['completedAt'] = _now;
    notifier?.cancel('challenge-$id');
    store.save();
    awardChallenge(c);
  }

  void cancelChallenge(String id, {Notifier? notifier}) {
    final c = _byId(id);
    if (c == null) return;
    c['status'] = 'cancelled';
    c['completedAt'] = _now;
    notifier?.cancel('challenge-$id');
    store.save();
  }

  /// مهلتِ چالش‌های زماندار؛ شناسه‌ی چالش‌هایی که همین حالا «در انتظار پاسخ» شدند
  List<String> checkChallengeDeadlines() {
    final due = <String>[];
    for (final c in challenges) {
      if ((c['kind'] == 'timed' || c['kind'] == 'both') && c['status'] == 'active' && c['deadlineAt'] is num && _now >= (c['deadlineAt'] as num)) {
        c['status'] = 'pending_review';
        due.add(c['id'] as String);
        toasts.show('⏰ ${_fa ? 'زمان چالش «${c['name']}» تموم شد! انجامش دادی؟' : 'Time for "${c['name']}" is up! Did you complete it?'}', ms: 4500);
      }
    }
    if (due.isNotEmpty) store.save();
    return due;
  }

  void resolveCheckin(String id, bool success, {Notifier? notifier}) {
    final c = _byId(id);
    if (c == null) return;
    c['status'] = success ? 'success' : 'failed';
    c['completedAt'] = _now;
    notifier?.cancel('challenge-$id');
    store.save();
    if (success) {
      awardChallenge(c);
    } else {
      toasts.show(_fa ? 'اشکالی نداره، دفعه بعد! 💪' : 'No worries, next time! 💪');
    }
  }
}
