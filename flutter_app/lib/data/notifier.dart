// رابط اعلان‌های محلی. پیاده‌سازیِ واقعی (flutter_local_notifications) در مرحله‌ی Native می‌آید.
abstract class Notifier {
  Future<void> scheduleOnce(String id, String title, String body, int atMs);
  Future<void> cancel(String id);
}

class NoopNotifier implements Notifier {
  @override
  Future<void> scheduleOnce(String id, String title, String body, int atMs) async {}
  @override
  Future<void> cancel(String id) async {}
}
