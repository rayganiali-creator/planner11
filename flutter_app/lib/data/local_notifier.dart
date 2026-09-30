// اعلان‌های محلیِ اندروید (flutter_local_notifications) — اجرای «عملیاتِ» برنامه‌ریزِ تست‌شده‌ی core/reminders.dart.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/doc.dart';
import '../core/reminders.dart';
import 'app_store.dart';
import 'notifier.dart';

class LocalNotifier implements Notifier {
  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _askedPermission = false;

  static const _channel = AndroidNotificationDetails(
    'rp_reminders',
    'یادآوری‌ها',
    channelDescription: 'یادآوری عادت‌ها، کارها، پومودورو و چالش‌ها',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _ready = true;
    } catch (_) {}
  }

  /// فقط وقتی واقعاً برای یک یادآوری لازم می‌شود (نه بی‌دلیل) — مثل ensureNotifyPermission
  Future<void> _ensurePermission() async {
    if (_askedPermission) return;
    _askedPermission = true;
    final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await a?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> runOps(List<ReminderOp> ops) async {
    await init();
    if (!_ready) return;
    for (final op in ops) {
      try {
        if (op.kind == 'cancel') {
          await _p.cancel(op.id);
        } else {
          await _ensurePermission();
          await _p.zonedSchedule(
            op.id,
            op.title,
            op.body,
            tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, op.atMs!.toInt()), // لحظه‌ی مطلق؛ به منطقه‌ی محلی وابسته نیست
            const NotificationDetails(android: _channel),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) =>
      runOps(planScheduleOnce(id, title, body, atMs, DateTime.now().millisecondsSinceEpoch));

  @override
  Future<void> cancel(String id) => runOps(planCancel(id));

  @override
  Future<void> resyncAll(Doc state, DateTime now) => runOps(planResyncAll(state, now));
}

/// هر تغییری در فهرستِ یادآورها (همه‌ی مسیرها: عادت، کار، یادداشت، کتاب، چالش) ← یک همگام‌سازیِ تأخیری.
/// همان ایده‌ی rpReminderSig در HTML: فقط وقتی «امضا» عوض شده کار می‌کند.
class ReminderSync {
  final AppStore store;
  final Notifier notifier;
  String _sig = '';
  Timer? _t;
  ReminderSync(this.store, this.notifier) {
    _sig = _signature(); // وضعیتِ اولیه؛ همگام‌سازیِ اول را main با syncNow() می‌زند
    store.addListener(_onChange);
  }

  String _signature() {
    final s = store.state;
    List l(String k) => s[k] is List ? s[k] as List : const [];
    return jsonEncode([
      s['lang'],
      [for (final t in l('todos')) if (t is Map) [t['id'], t['dueAt'], t['done'], t['repeatMode'], t['repeatDays'], t['title']]],
      [for (final h in l('habits')) if (h is Map) [h['id'], h['reminderEnabled'], h['reminderTime'], h['name'], h['activeDays'], h['scheduleMode']]],
      [for (final j in l('journal')) if (j is Map) [j['id'], j['remindAt']]],
      [for (final b in l('books')) if (b is Map) [b['id'], b['remindAt']]],
      [for (final c in l('challenges')) if (c is Map) [c['id'], c['status'], c['deadlineAt']]],
    ]);
  }

  void _onChange() {
    final sig = _signature();
    if (sig == _sig) return;
    _sig = sig;
    _t?.cancel();
    _t = Timer(const Duration(seconds: 1), syncNow);
  }

  Future<void> syncNow() => notifier.resyncAll(store.state, DateTime.now());

  void dispose() {
    _t?.cancel();
    store.removeListener(_onChange);
  }
}
