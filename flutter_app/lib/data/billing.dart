// رابطِ پرداخت. پیاده‌سازیِ واقعی (Poolakey/کافه‌بازار از راه MethodChannel) در مرحله‌ی Native می‌آید؛
// تا آن زمان پیاده‌سازیِ «ناموجود» پیام روشن می‌دهد و هیچ خریدی ثبت نمی‌کند.
import '../app/toast.dart';

abstract class BillingService {
  Future<void> purchase(String productId);
  Future<void> restore();
}

class UnavailableBilling implements BillingService {
  final ToastBus toasts;
  final bool Function() isFa;
  UnavailableBilling(this.toasts, this.isFa);
  void _msg() => toasts.show(isFa() ? 'پرداخت در این نسخه هنوز متصل نشده است.' : 'Billing is not connected in this build yet.', ms: 3000);
  @override
  Future<void> purchase(String productId) async => _msg();
  @override
  Future<void> restore() async => _msg();
}
