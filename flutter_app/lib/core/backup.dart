// پشتیبان‌گیری و بازیابی — پورت عین‌به‌عینِ rpValidateBackup، منطق «کاندید، بعد جایگزین»،
// ساخت JSON نسخه‌ی ۳٫۰ و رمزگذاریِ اختیاری (AES-GCM-256 + PBKDF2-HMAC-SHA256).
// فرمتِ فایل‌ها با نسخه‌ی HTML یکی است: فایلِ ساخته‌شده در هر کدام در دیگری باز می‌شود.
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'doc.dart';
import 'js_compat.dart';
import 'state_model.dart';

// ---------------------------------------------------------------- اعتبارسنجی
const Map<String, String> rpBackupSchema = {
  'habits': 'array', 'records': 'object', 'journal': 'array', 'todos': 'array', 'books': 'array',
  'challenges': 'array', 'scores': 'object', 'medals': 'array', 'pomodoro': 'object',
  'behaviorJournal': 'object', 'habitNotes': 'object', 'reasons': 'object', 'triggers': 'object',
  'customUrgeSuggestions': 'array', 'urgeHiddenIds': 'array', 'progress': 'object', 'todoLog': 'array',
  'theme': 'string', 'lang': 'string', 'bgColor': 'string',
  'accentTheme': 'string', 'weekStart': 'number', 'showHolidays': 'boolean', 'calendarType': 'string',
  'fontSize': 'string', 'tileColors': 'object', 'bgPattern': 'string', 'tileShape': 'string',
  'tileEffect': 'string', 'bgPatternOpacity': 'number', 'themeIntensity': 'number',
  'profileName': 'string', 'triggerType': 'string',
};

/// `Array.isArray(v) ? 'array' : (v === null ? 'null' : typeof v)`
String rpTypeOf(Object? v) {
  if (v is List) return 'array';
  if (v == null) return 'null';
  if (v is bool) return 'boolean';
  if (v is num) return 'number';
  if (v is String) return 'string';
  return 'object';
}

typedef BackupValidation = ({bool ok, Map<String, dynamic> next, List<String> skipped, String version});

/// فقط میدان‌های سالم در `next` می‌آیند؛ دو میدانِ حیاتی (habits/records) خراب باشد کلِ فایل رد می‌شود.
BackupValidation rpValidateBackup(Object? raw) {
  const bad = (ok: false, next: <String, dynamic>{}, skipped: <String>[], version: '');
  if (raw is! Map) return bad;
  final d = raw['data'];
  if (!jsTruthy(d) || (d is! Map && d is! List)) return bad;
  if (d is! Map) return bad; // آرایه: habits/records ندارد → JS هم رد می‌کند
  if (rpTypeOf(d['habits']) != 'array' || rpTypeOf(d['records']) != 'object') return bad;
  final next = <String, dynamic>{};
  final skipped = <String>[];
  for (final e in rpBackupSchema.entries) {
    final v = d[e.key];
    if (v == null) continue;
    if (rpTypeOf(v) == e.value) {
      next[e.key] = v;
    } else {
      skipped.add(e.key);
    }
  }
  final ver = raw['version'];
  return (ok: true, next: next, skipped: skipped, version: jsTruthy(ver) ? jsString(ver) : '?');
}

/// جایگزینیِ یک‌جا (تا پیش از این هیچ‌چیزِ state عوض نشده): میدان‌های سالم روی state می‌نشینند
/// و سپس نرمال‌سازی اجرا می‌شود. true = state تغییر کرد.
void applyBackupToState(Doc state, Map<String, dynamic> next) {
  for (final e in next.entries) {
    state[e.key] = e.value;
  }
  final sc = state['scores'];
  if (!jsTruthy(sc) || sc is! Map) {
    state['scores'] = {'points': 0, 'level': 1, 'streak': 0, 'lastDate': null, 'coins': 0, 'lastPoints': 0};
  }
  rpNormalizeState(state);
}

// ---------------------------------------------------------------- ساخت JSON
/// رسانه‌ها (عکس/صدا) از خارجِ state می‌آیند؛ قالبشان با HTML یکی است.
class BackupMedia {
  final Map<String, List<String>> bookPhotos;
  final Map<String, List<String>> habitPhotos;
  final Map<String, List<Map<String, dynamic>>> bookVoices;
  const BackupMedia({this.bookPhotos = const {}, this.habitPhotos = const {}, this.bookVoices = const {}});
}

/// فیلدی که JS مستقیم از state می‌خواند: اگر کلید نبود (undefined) در JSON هم نمی‌آید.
void _pass(Map<String, dynamic> out, Doc s, String k) {
  if (s.containsKey(k)) out[k] = s[k];
}

Map<String, dynamic> createBackupMap(Doc s, {required DateTime exportedAtUtc, BackupMedia media = const BackupMedia()}) {
  Object? orDefault(String k, Object? d) => jsTruthy(s[k]) ? s[k] : d;
  final data = <String, dynamic>{
    'habits': orDefault('habits', []),
    'records': orDefault('records', {}),
    'journal': orDefault('journal', []),
    'todos': orDefault('todos', []),
    'books': orDefault('books', []),
    'challenges': orDefault('challenges', []),
    'scores': orDefault('scores', {}),
    'medals': orDefault('medals', []),
    'pomodoro': orDefault('pomodoro', null),
    'behaviorJournal': orDefault('behaviorJournal', {}),
    'habitNotes': orDefault('habitNotes', {}),
    'reasons': orDefault('reasons', {}),
    'triggers': orDefault('triggers', {}),
    'customUrgeSuggestions': orDefault('customUrgeSuggestions', []),
    'urgeHiddenIds': orDefault('urgeHiddenIds', []),
    // سیستمِ پیشرفت: XP، رویدادها، سطح/رتبه (مشتق)، دستاوردها و پیشرفتشان، نشان‌ها، نقاط عطف، عنوان‌ها، نشان‌های ویژه، آمار (مشتق از داده)، فصل‌ها و تاریخچه‌ی فصل
    'progress': orDefault('progress', null),
    'todoLog': orDefault('todoLog', []),
  };
  for (final k in const [
    'theme', 'lang', 'bgColor', 'accentTheme', 'weekStart', 'showHolidays', 'calendarType', 'fontSize', 'tileColors', 'bgPattern',
    'tileShape', 'tileEffect', 'bgPatternOpacity', 'themeIntensity', 'profileName', 'triggerType'
  ]) {
    _pass(data, s, k);
  }
  data['bookPhotos'] = media.bookPhotos;
  data['habitPhotos'] = media.habitPhotos;
  data['bookVoices'] = media.bookVoices;
  return {'version': '3.0', 'exportedAt': _isoMs(exportedAtUtc), 'appName': 'روتین پلنر', 'data': data};
}

/// `Date.prototype.toISOString`: همیشه UTC با سه رقم میلی‌ثانیه و پسوند Z
String _isoMs(DateTime d) {
  final u = d.toUtc();
  String p(int n, int w) => n.toString().padLeft(w, '0');
  return '${p(u.year, 4)}-${p(u.month, 2)}-${p(u.day, 2)}T${p(u.hour, 2)}:${p(u.minute, 2)}:${p(u.second, 2)}.${p(u.millisecond, 3)}Z';
}

/// `JSON.stringify(obj, null, 2)`
String backupToJson(Map<String, dynamic> m) => jsonStringify(m, indent: 2);

// ---------------------------------------------------------------- رمزنگاری
const int rpEncIterations = 300000;

Uint8List _unb64(String s) => Uint8List.fromList(base64.decode(s));

Future<SecretKey> _deriveKey(String pass, List<int> salt, int iterations) => Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: pass, nonce: salt);

/// پوشش رمزدار؛ خروجی همان JSON است که نسخه‌ی HTML می‌سازد و می‌خواند.
/// [salt] و [iv] فقط برای تست قابل تعیین‌اند؛ در برنامه تصادفی ساخته می‌شوند.
Future<String> rpEncryptBackup(String plain, String pass, {DateTime? createdAt, List<int>? salt, List<int>? iv, int iterations = rpEncIterations}) async {
  final rnd = SecureRandom.defaultRandom;
  final s = salt ?? List<int>.generate(16, (_) => rnd.nextInt(256));
  final n = iv ?? List<int>.generate(12, (_) => rnd.nextInt(256));
  final key = await _deriveKey(pass, s, iterations);
  final box = await AesGcm.with256bits().encrypt(utf8.encode(plain), secretKey: key, nonce: n);
  final data = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]); // همان چیدمانِ WebCrypto: متن رمز + برچسب ۱۶ بایتی
  return jsonStringify({
    'rpEncrypted': 1,
    'app': 'routine-planner',
    'createdAt': _isoMs(createdAt ?? DateTime.now()),
    'kdf': {'name': 'PBKDF2', 'hash': 'SHA-256', 'iterations': iterations, 'salt': base64.encode(s)},
    'cipher': 'AES-GCM',
    'iv': base64.encode(n),
    'data': base64.encode(data),
  }, indent: 2);
}

/// رمز غلط یا فایل دست‌کاری‌شده → null (برچسبِ احراز اصالتِ AES-GCM آن را می‌گیرد).
Future<String?> rpDecryptBackup(Map env, String pass) async {
  try {
    final kdf = env['kdf'] as Map;
    final itRaw = int.tryParse(jsString(jsOr(kdf['iterations'], rpEncIterations)).trim().split(RegExp(r'[^0-9\-+]')).first) ?? rpEncIterations;
    final it = itRaw < 1 ? 1 : (itRaw > 2000000 ? 2000000 : itRaw);
    final salt = _unb64(kdf['salt'] as String);
    final iv = _unb64(env['iv'] as String);
    final all = _unb64(env['data'] as String);
    if (all.length < 16) return null;
    final key = await _deriveKey(pass, salt, it);
    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(all.sublist(0, all.length - 16), nonce: iv, mac: Mac(all.sublist(all.length - 16))),
      secretKey: key,
    );
    return utf8.decode(clear);
  } catch (_) {
    return null;
  }
}

/// همان کار در یک Isolate جدا تا رابط کاربری حین ۳۰۰٬۰۰۰ تکرار قفل نشود.
Future<String> rpEncryptBackupInIsolate(String plain, String pass) => Isolate.run(() => rpEncryptBackup(plain, pass));
Future<String?> rpDecryptBackupInIsolate(Map env, String pass) => Isolate.run(() => rpDecryptBackup(env, pass));
