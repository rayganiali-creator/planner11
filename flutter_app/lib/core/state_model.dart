// مقدارهای پیش‌فرض، نرمال‌سازی و خطِ لولهی «بارگذاریِ state» — پورت عین‌به‌عینِ بخش STATE و
// rpNormalizeState از www/index.html. داده‌ی ناقص/خراب هرگز نباید برنامه را بیندازد و
// هیچ فیلدِ ناشناخته‌ای نباید از بین برود (Object.assign: مقدارهای ذخیره‌شده روی پیش‌فرض می‌نشینند).
import 'dart:convert';

import 'js_compat.dart';
import 'pro.dart';

typedef Doc = Map<String, dynamic>;

Doc defaultState() => <String, dynamic>{
      'theme': 'light',
      'lang': 'fa',
      'bgColor': '#F6F1E7',
      'accentTheme': 'teal',
      'tileColors': {'success': '#3E9B4F', 'fail': '#C0483B', 'neutral': '#E5DBC8'},
      'habits': [],
      'records': {},
      'journal': [],
      'todos': [],
      'books': [],
      'scores': {'points': 0, 'level': 1, 'streak': 0, 'lastDate': null, 'coins': 0, 'lastPoints': 0},
      'weekStart': 0,
      'showHolidays': true,
      'calendarType': 'jalali',
      'fontSize': 'medium',
      'bgPattern': 'solid',
      'tileShape': 'round',
      'tileEffect': 'none',
      'bgPatternOpacity': 0.35,
      'themeIntensity': 0,
      'profileName': 'کاربر',
      'reasons': {},
      'triggers': {},
      'triggerType': 'trigger',
      'levelToastSent': {},
      'levelReachedColor': '#146B69',
      'masteryColor': '#C79A2E',
      'customUrgeSuggestions': [],
      'urgeHiddenIds': [],
      'habitNotes': {},
      'onboardingDone': false,
      'langChosen': false,
      'isPremium': false,
      'proCache': null,
      'avatar': {'gender': null, 'owned': {}, 'equipped': {'male': {}, 'female': {}}},
      'termsAcceptedVersion': null,
      'termsAcceptedAt': null,
      'challenges': [],
    };

bool _isObj(Object? v) => v is Map; // typeof === 'object' && !Array (برای ساختارهای نگاشتی)
bool _isJsObject(Object? v) => v != null && (v is Map || v is List); // typeof === 'object' && !== null

Doc _freshScores() => {'points': 0, 'level': 1, 'streak': 0, 'lastDate': null, 'coins': 0, 'lastPoints': 0};

/// هر میدانِ خراب یا با نوعِ اشتباه به نوعِ درستش برمی‌گردد. true = چیزی اصلاح شد.
bool rpNormalizeState(Doc state) {
  bool fixed = false;
  for (final k in const ['habits', 'journal', 'todos', 'books', 'challenges', 'medals', 'customUrgeSuggestions', 'urgeHiddenIds']) {
    if (state[k] is! List) {
      state[k] = <dynamic>[];
      fixed = true;
    }
  }
  for (final k in const ['records', 'reasons', 'triggers', 'habitNotes', 'behaviorJournal', 'levelToastSent', 'tileColors']) {
    final v = state[k];
    if (v == null || !_isObj(v) || !jsTruthy(v)) {
      state[k] = <String, dynamic>{};
      fixed = true;
    }
  }
  if (state['scores'] is! Map) {
    state['scores'] = _freshScores();
    fixed = true;
  }
  final sc = state['scores'] as Map;
  for (final k in const ['points', 'level', 'streak', 'coins', 'lastPoints']) {
    final n = jsToNumber(sc[k]);
    sc[k] = n.isFinite ? _intIfWhole(n) : (k == 'level' ? 1 : 0);
  }
  if (state['avatar'] is! Map) {
    state['avatar'] = {'gender': null, 'owned': {}, 'equipped': {'male': {}, 'female': {}}};
  }
  final av = state['avatar'] as Map;
  if (!_isJsObject(av['owned']) || !jsTruthy(av['owned'])) av['owned'] = {};
  if (!_isJsObject(av['equipped']) || !jsTruthy(av['equipped'])) av['equipped'] = {'male': {}, 'female': {}};
  final eq = av['equipped'];
  if (eq is Map) {
    if (!_isJsObject(eq['male'])) eq['male'] = {};
    if (!_isJsObject(eq['female'])) eq['female'] = {};
  }
  // عادت/کار/کتاب/چالشِ بی‌شناسه قابل استفاده نیست
  bool hasId(Object? e) => e is Map && jsTruthy(e['id']);
  state['habits'] = [for (final h in state['habits'] as List) if (hasId(h)) h];
  state['todos'] = [for (final t in state['todos'] as List) if (hasId(t)) t];
  state['books'] = [for (final b in state['books'] as List) if (hasId(b)) b];
  state['challenges'] = [for (final c in state['challenges'] as List) if (hasId(c)) c];
  state['journal'] = [for (final j in state['journal'] as List) if (_isJsObject(j)) j];
  final tc = state['tileColors'] as Map;
  if (!jsTruthy(tc['success'])) {
    state['tileColors'] = {'success': '#3E9B4F', 'fail': '#C0483B', 'neutral': '#E5DBC8'};
  }
  // هر روزِ تقویم باید یک شیء باشد؛ روزِ خراب حذف می‌شود
  final recs = state['records'] as Map;
  for (final iso in recs.keys.toList()) {
    if (recs[iso] is! Map) {
      recs.remove(iso);
      fixed = true;
    }
  }
  // میدان‌های مرده‌ی نسخه‌های قدیمی
  for (final k in const ['coins', 'level', 'calorie', 'vows']) {
    if (state.containsKey(k)) {
      state.remove(k);
      fixed = true;
    }
  }
  return fixed;
}

/// اعداد کامل را int نگه می‌دارد تا JSON مثل JS («5» نه «5.0») خروجی بدهد.
num _intIfWhole(double n) => (n == n.truncateToDouble() && n.abs() < 9e15) ? n.toInt() : n;

/// `String(raw)` برای مهاجرتِ رکوردهای قدیمی
Object? _lockedTarget(Map h) {
  return h['type'] == 'numeric' ? jsOr(h['numericTarget'], 1) : jsOr(h['timerTarget'], 30);
}

/// رکوردهای قدیمیِ عددی/زمانی بدونِ targetAtTime را با هدف فعلیِ عادت «قفل» می‌کند.
void migrateTargetSnapshots(Doc state) {
  final habits = state['habits'], records = state['records'];
  if (habits is! List || records is! Map) return;
  final habitMap = <dynamic, Map>{for (final h in habits) if (h is Map) h['id']: h};
  for (final iso in records.keys) {
    final rec = records[iso];
    if (rec is! Map) continue;
    for (final hid in rec.keys.toList()) {
      final h = habitMap[hid];
      if (h == null) continue;
      if (h['type'] != 'numeric' && h['type'] != 'timer') continue;
      final raw = rec[hid];
      final cur = _lockedTarget(h);
      if (raw is Map) {
        if (!raw.containsKey('targetAtTime')) raw['targetAtTime'] = cur;
      } else if (raw is List) {
        // در JS ویژگی روی آرایه می‌نشیند که در JSON دیده نمی‌شود
      } else {
        rec[hid] = {'value': jsString(raw), 'targetAtTime': cur};
      }
    }
  }
}

typedef LoadedState = ({Doc state, bool repaired});

num _effNow(Doc state, num nowMs) {
  final c = state['clock'];
  final ls = c is Map ? jsToNumber(jsOr(c['lastSeen'], 0)) : 0;
  final last = ls.isNaN ? 0 : ls;
  return nowMs > last ? nowMs : last;
}

/// `Object.assign(state, p)` برای مقدارهای ذخیره‌شده‌ی دلخواه (شیء، آرایه، رشته، …).
void _assign(Doc state, Object? p) {
  if (p is Map) {
    for (final e in p.entries) {
      state['${e.key}'] = e.value;
    }
  } else if (p is List) {
    for (int i = 0; i < p.length; i++) {
      state['$i'] = p[i];
    }
  } else if (p is String) {
    final units = p.codeUnits;
    for (int i = 0; i < units.length; i++) {
      state['$i'] = String.fromCharCode(units[i]);
    }
  }
}

/// معادلِ بارگذاریِ اولیه. [raw] همان متنِ ذخیره‌شده در localStorage (یا null برای نصب تازه).
/// [nowMs] = «الان»ِ ساعتِ مطمئن.
LoadedState loadStateFromRaw(String? raw, {required num nowMs}) {
  final state = defaultState();
  bool repaired = false;
  if (raw != null && raw.isNotEmpty) {
    bool parsed = true;
    Object? p;
    try {
      p = jsonDecode(raw);
    } catch (_) {
      parsed = false; // JSON خراب: state همان پیش‌فرض می‌ماند (try/catch بی‌صدا در JS)
    }
    if (parsed) {
      _assign(state, p);
      if (rpNormalizeState(state)) repaired = true;
      _initClock(state);
      recomputeTrustedPremiumFlag(state, _effNow(state, nowMs));
      _applyDefaultsAfterLoad(state);
    }
  }
  _initClock(state);
  recomputeTrustedPremiumFlag(state, _effNow(state, nowMs));
  return (state: state, repaired: repaired);
}

void _applyDefaultsAfterLoad(Doc state) {
  bool absent(String k) => !state.containsKey(k);
  if (!jsTruthy(state['journal'])) state['journal'] = [];
  if (!jsTruthy(state['todos'])) state['todos'] = [];
  if (!jsTruthy(state['books'])) state['books'] = [];
  if (!jsTruthy(state['scores'])) state['scores'] = {'points': 0, 'level': 1, 'streak': 0, 'lastDate': null};
  if (absent('weekStart')) state['weekStart'] = 0;
  if (absent('showHolidays')) state['showHolidays'] = true;
  if (absent('calendarType')) state['calendarType'] = 'jalali';
  if (absent('fontSize')) state['fontSize'] = 'medium';
  if (!jsTruthy(state['accentTheme'])) state['accentTheme'] = 'teal';
  if (!jsTruthy(state['bgColor'])) state['bgColor'] = '#F6F1E7';
  if (!jsTruthy(state['tileColors'])) state['tileColors'] = {'success': '#3E9B4F', 'fail': '#C0483B', 'neutral': '#E5DBC8'};
  if (!jsTruthy(state['bgPattern'])) state['bgPattern'] = 'solid';
  if (!jsTruthy(state['tileShape'])) state['tileShape'] = 'round';
  if (!jsTruthy(state['tileEffect'])) state['tileEffect'] = 'none';
  if (absent('bgPatternOpacity')) state['bgPatternOpacity'] = 0.35;
  if (!jsTruthy(state['profileName'])) state['profileName'] = 'کاربر';
  if (!jsTruthy(state['reasons'])) state['reasons'] = {};
  if (!jsTruthy(state['triggers'])) state['triggers'] = {};
  if (absent('triggerType')) state['triggerType'] = 'trigger';
  if (!jsTruthy(state['levelToastSent'])) state['levelToastSent'] = {};
  if (!jsTruthy(state['levelReachedColor'])) state['levelReachedColor'] = '#146B69';
  if (!jsTruthy(state['masteryColor'])) state['masteryColor'] = '#C79A2E';
  if (!jsTruthy(state['customUrgeSuggestions'])) state['customUrgeSuggestions'] = [];
  if (!jsTruthy(state['urgeHiddenIds'])) state['urgeHiddenIds'] = [];
  if (!jsTruthy(state['habitNotes'])) state['habitNotes'] = {};
  // کالری‌شمار و عهدنامه از برنامه حذف شده‌اند؛ داده‌ی قدیمی‌شان پاک می‌شود
  state.remove('calorie');
  state.remove('vows');
  if (absent('themeIntensity')) state['themeIntensity'] = state['theme'] == 'dark' ? 100 : 0;
  if (!jsTruthy(state['scores'])) state['scores'] = {'points': 0, 'level': 1, 'streak': 0, 'lastDate': null, 'coins': 0, 'lastPoints': 0};
  final sc = state['scores'] as Map;
  if (!sc.containsKey('coins')) sc['coins'] = 0;
  if (!sc.containsKey('lastPoints')) sc['lastPoints'] = jsOr(sc['points'], 0);
  if (state['challenges'] is! List) state['challenges'] = [];
  // کاربرِ قدیمی آموزش اولیه و انتخاب زبان را دوباره نمی‌بیند (برای کلیدِ غایب)
  if (absent('onboardingDone')) state['onboardingDone'] = true;
  if (absent('langChosen')) state['langChosen'] = jsTruthy(state['onboardingDone']);
  migrateTargetSnapshots(state);
}

void _initClock(Doc state) {
  if (!jsTruthy(state['clock'])) state['clock'] = {'lastSeen': 0, 'lastSync': 0};
}
