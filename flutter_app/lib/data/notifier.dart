// رابط اعلان‌های محلی. پیاده‌سازیِ واقعی (flutter_local_notifications) در مرحله‌ی Native می‌آید.
import '../core/doc.dart';

abstract class Notifier {
  /// «زمانِ بعدی» همه‌ی یادآوری‌ها را از روی state دوباره ثبت می‌کند (planResyncAll)
  Future<void> resyncAll(Doc state, DateTime now);

  Future<void> scheduleOnce(String id, String title, String body, int atMs);
  Future<void> cancel(String id);
}

class NoopNotifier implements Notifier {
  @override
  Future<void> resyncAll(Doc state, DateTime now) async {}
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async {}
  @override
  Future<void> cancel(String id) async {}
}
