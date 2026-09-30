// خروجی/ورودیِ فایل (پشتیبان، اشتراک‌گذاری، CSV، PDF). پیاده‌سازیِ واقعی (ذخیره در Downloads، share، انتخاب فایل) Native است.
import '../app/toast.dart';

abstract class FilesService {
  Future<void> exportBackup();
  Future<void> shareBackup();
  Future<void> importBackup();
  Future<void> exportCsv();
  Future<void> exportPdf();
}

class UnavailableFiles implements FilesService {
  final ToastBus toasts;
  final bool Function() isFa;
  UnavailableFiles(this.toasts, this.isFa);
  Future<void> _m() async => toasts.show(isFa() ? 'این قابلیت هنوز در این نسخه متصل نشده است.' : 'This feature is not connected in this build yet.', ms: 3000);
  @override
  Future<void> exportBackup() => _m();
  @override
  Future<void> shareBackup() => _m();
  @override
  Future<void> importBackup() => _m();
  @override
  Future<void> exportCsv() => _m();
  @override
  Future<void> exportPdf() => _m();
}
