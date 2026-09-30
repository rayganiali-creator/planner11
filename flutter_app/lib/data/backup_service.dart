// ignore_for_file: use_build_context_synchronously  (context از کلیدِ سراسریِ Navigator گرفته می‌شود، نه از ویجتی که ممکن است از بین برود)
// پشتیبان‌گیری/بازیابی/CSV با همان رفتارِ HTML: پرسشِ رمز (اختیاری)، نامِ فایل، ذخیره در Downloads یا اشتراک،
// و ورود: تأیید ← خواندن ← (رمز) ← اعتبارسنجی ← جایگزینیِ یک‌جا؛ خطا هیچ‌چیز را عوض نمی‌کند.
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/nav_key.dart';
import '../app/toast.dart';
import '../core/backup.dart';
import '../core/calendar.dart';
import '../core/habits.dart';
import '../core/js_compat.dart';
import 'actions.dart';
import 'files_service.dart';
import 'media_store.dart';
import 'native_api.dart';

typedef PasswordChoice = ({bool plain, String pass});

class BackupService implements FilesService {
  final AppActions actions;
  final MediaStore media;
  final NativeApi native;
  final ToastBus toasts;
  BackupService(this.actions, this.media, this.native, this.toasts);

  bool get _fa => actions.store.state['lang'] != 'en';
  BuildContext? get _ctx => rpNavKey.currentContext;

  String _stamp() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}-${n.hour}-${n.minute}';
  }

  @visibleForTesting
  Future<String> debugJson() => _json();

  Future<String> _json() async {
    final s = actions.store.state;
    final m = await media.collectForBackup((s['books'] as List?) ?? const [], (s['habits'] as List?) ?? const []);
    return backupToJson(createBackupMap(s, exportedAtUtc: DateTime.now().toUtc(), media: m));
  }

  /// null = انصراف
  Future<({String text, bool enc})?> _payload() async {
    final json = await _json();
    final ctx = _ctx;
    if (ctx == null) return (text: json, enc: false);
    final c = await askPassword(ctx, set: true);
    if (c == null) return null;
    if (c.plain) return (text: json, enc: false);
    try {
      return (text: await rpEncryptBackupInIsolate(json, c.pass), enc: true);
    } catch (_) {
      toasts.show(_fa ? 'رمزگذاری انجام نشد؛ فایل بدون رمز ساخته شد.' : 'Encryption failed; the backup was saved unencrypted.', ms: 4000);
      return (text: json, enc: false);
    }
  }

  Future<bool> _save(String name, String mime, List<int> bytes) async {
    try {
      await native.saveToDownloads(fileName: name, mimeType: mime, base64Data: base64.encode(bytes));
      return true;
    } catch (_) {
      return _share(name, mime, bytes); // اندروید قدیمی/خطا: اشتراک
    }
  }

  Future<bool> _share(String name, String mime, List<int> bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$name')..writeAsBytesSync(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: mime)], subject: name));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> exportBackup() async {
    final p = await _payload();
    if (p == null) return;
    final name = 'RoutinePlanner-Backup-${p.enc ? 'ENC-' : ''}${_stamp()}.json';
    final ok = await _save(name, 'application/json', utf8.encode(p.text));
    toasts.show(ok ? (_fa ? '✅ فایل پشتیبان ذخیره شد' : '✅ Backup saved') : (_fa ? '⚠️ ذخیره‌سازی ناموفق بود' : '⚠️ Saving failed'), ms: 3000);
  }

  @override
  Future<void> shareBackup() async {
    final p = await _payload();
    if (p == null) return;
    final ok = await _share('RoutinePlanner-Backup${p.enc ? '-ENC' : ''}.json', 'application/json', utf8.encode(p.text));
    if (!ok) toasts.show(_fa ? '⚠️ اشتراک‌گذاری ناموفق بود' : '⚠️ Sharing failed', ms: 3000);
  }

  @override
  Future<void> importBackup() async {
    final ctx = _ctx;
    if (ctx == null) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(_fa ? '⚠️ اطلاعات فعلی جایگزین میشه. ادامه میدی؟' : '⚠️ Current data will be replaced. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_fa ? 'انصراف' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(_fa ? 'ادامه' : 'Continue')),
        ],
      ),
    );
    if (ok != true) return;
    final pick = await FilePicker.pickFiles();
    final path = pick.firstOrNull?.path;
    if (path == null) return;
    await importFromText(utf8.decode(File(path).readAsBytesSync(), allowMalformed: true));
  }

  /// منطقِ ورود (برای تست هم قابل‌فراخوانی)
  Future<bool> importFromText(String text, {Future<PasswordChoice?> Function()? ask, bool quiet = false}) async {
    void err(String fa, String en) => toasts.show(_fa ? fa : en, ms: 4200);
    Object? raw;
    try {
      raw = jsonDecode(text);
    } catch (_) {
      err('❌ فایل پشتیبان خوانده نشد (JSON معتبر نیست). داده‌ی فعلی دست‌نخورده ماند.', '❌ Could not read the backup (invalid JSON). Your current data is untouched.');
      return false;
    }
    if (raw is Map && jsTruthy(raw['rpEncrypted'])) {
      final c = ask != null ? await ask() : (_ctx == null ? null : await askPassword(_ctx!, set: false));
      if (c == null || c.pass.isEmpty) return false;
      final plain = await rpDecryptBackupInIsolate(raw, c.pass);
      if (plain == null) {
        err('❌ رمز درست نیست (یا فایل خراب است). داده‌ی فعلی دست‌نخورده ماند.', '❌ Wrong password (or the file is damaged). Your current data is untouched.');
        return false;
      }
      try {
        raw = jsonDecode(plain);
      } catch (_) {
        err('❌ محتوای فایل پس از رمزگشایی سالم نبود.', '❌ The decrypted content was not valid.');
        return false;
      }
    }
    final v = rpValidateBackup(raw);
    if (!v.ok) {
      err('❌ این فایل پشتیبانِ روتین پلنر نیست یا خراب است. داده‌ی فعلی دست‌نخورده ماند.', '❌ Not a valid Routine Planner backup. Your current data is untouched.');
      return false;
    }
    applyBackupToState(actions.store.state, v.next);
    actions.store.save();
    final d = (raw as Map)['data'];
    if (d is Map) await media.restoreFromBackup(d);
    actions.renderAll();
    if (!quiet) toasts.show(_fa ? '✅ اطلاعات با موفقیت بازیابی شد' : '✅ Data restored successfully', ms: 3500);
    return true;
  }

  // ---------------------------------------------------------------- انتقال از نسخه‌ی HTML
  /// نسخه‌ی HTML (۱٫۰٫۶ به بعد) یک کپیِ کامل در `files/rp_handoff.json` می‌نویسد؛ اولین باز شدنِ نسخه‌ی Flutter
  /// (تا وقتی واردنشده باشد؛ مستقل از اینکه state.json ساخته شده یا نه) آن را وارد می‌کند. فایل بعد از موفقیت به `.imported.json` تغییر نام می‌دهد
  /// (پاک نمی‌شود: اگر مشکلی پیش آمد هنوز یک نسخه‌ی کامل از داده‌ها هست).
  Future<bool> importHandoff(String dirPath) async {
    final f = File('$dirPath/rp_handoff.json');
    if (!f.existsSync()) return false;
    final text = utf8.decode(f.readAsBytesSync(), allowMalformed: true);
    final ok = await importFromText(text, quiet: true);
    if (ok) {
      try {
        f.renameSync('$dirPath/rp_handoff.imported.json');
      } catch (_) {}
      toasts.show(_fa ? '✅ داده‌های نسخه‌ی قبلی برنامه منتقل شد' : '✅ Your data from the previous version was carried over', ms: 5000);
    }
    return ok;
  }

  // ---------------------------------------------------------------- CSV
  String buildCsv() {
    final s = actions.store.state;
    final fa = _fa;
    String f(Object? v) {
      final t = v == null ? '' : '$v';
      return RegExp(r'[",\n\r]').hasMatch(t) ? '"${t.replaceAll('"', '""')}"' : t;
    }

    final rows = <List<Object?>>[
      fa ? ['تاریخ', 'تاریخ شمسی', 'عادت', 'وضعیت', 'مقدار ثبت‌شده'] : ['Date', 'Persian date', 'Habit', 'Status', 'Value'],
    ];
    final recs = s['records'] is Map ? s['records'] as Map : const {};
    final habits = (s['habits'] as List).cast<Map>();
    for (final iso in (recs.keys.cast<String>().toList()..sort())) {
      final rec = recs[iso];
      if (rec is! Map) continue;
      for (final hid in rec.keys) {
        final h = habits.where((x) => x['id'] == hid).firstOrNull;
        if (h == null) continue;
        final raw = rec[hid];
        final val = raw is Map ? raw['value'] : raw;
        final p = iso.split('-').map(int.parse).toList();
        final j = toJalaali(p[0], p[1], p[2]);
        final st = getStatusFromRecord(raw, h);
        rows.add([iso, '${j.jy}/${pad2(j.jm)}/${pad2(j.jd)}', h['name'], st == 'success' ? (fa ? 'موفق' : 'Success') : st == 'fail' ? (fa ? 'ناموفق' : 'Failed') : (fa ? 'ثبت‌نشده' : 'Not set'), val is num ? val : '']);
      }
    }
    if (rows.length == 1) return '';
    return '﻿${rows.map((r) => r.map(f).join(',')).join('\r\n')}';
  }

  @override
  Future<void> exportCsv() async {
    final csv = buildCsv();
    if (csv.isEmpty) {
      toasts.show(_fa ? 'هنوز هیچ ثبتی برای خروجی وجود ندارد.' : 'Nothing recorded yet to export.', ms: 2500);
      return;
    }
    final ok = await _save('RoutinePlanner-Data-${_stamp()}.csv', 'text/csv', utf8.encode(csv));
    toasts.show(ok ? (_fa ? '✅ فایل ذخیره شد' : '✅ File saved') : (_fa ? '⚠️ ذخیره‌سازی ناموفق بود' : '⚠️ Saving failed'), ms: 3000);
  }

  @override
  Future<void> exportPdf() async {
    toasts.show(_fa ? 'خروجی PDF هنوز در این نسخه متصل نشده است.' : 'PDF export is not connected in this build yet.', ms: 3000);
  }
}

/// پنجره‌ی رمز: set = ساخت (با «بدون رمز»)، وگرنه ورود
Future<PasswordChoice?> askPassword(BuildContext context, {required bool set}) {
  final fa = Localizations.localeOf(context).languageCode != 'en';
  final c1 = TextEditingController(), c2 = TextEditingController();
  String? error;
  return showDialog<PasswordChoice>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(set ? (fa ? '🔒 رمزِ فایل پشتیبان' : '🔒 Backup password') : (fa ? '🔑 رمزِ فایل را وارد کن' : '🔑 Enter the backup password')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (set) Text(fa ? 'اگر رمز را گم کنی، فایل هرگز باز نمی‌شود.' : 'If you lose the password, the file can never be opened.'),
          TextField(controller: c1, obscureText: true, decoration: InputDecoration(labelText: fa ? 'رمز' : 'Password')),
          if (set) TextField(controller: c2, obscureText: true, decoration: InputDecoration(labelText: fa ? 'تکرار رمز' : 'Repeat password')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(fa ? 'انصراف' : 'Cancel')),
          if (set) TextButton(onPressed: () => Navigator.pop(ctx, (plain: true, pass: '')), child: Text(fa ? 'بدون رمز' : 'No password')),
          FilledButton(
            onPressed: () {
              if (c1.text.isEmpty) {
                setS(() => error = fa ? 'رمز را وارد کن.' : 'Enter a password.');
                return;
              }
              if (set && c1.text != c2.text) {
                setS(() => error = fa ? 'دو رمز یکی نیست.' : 'Passwords do not match.');
                return;
              }
              Navigator.pop(ctx, (plain: false, pass: c1.text));
            },
            child: Text(fa ? 'تأیید' : 'OK'),
          ),
        ],
      ),
    ),
  );
}
