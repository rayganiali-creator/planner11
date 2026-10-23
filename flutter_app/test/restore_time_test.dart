import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/pro.dart';

void main() {
  const day = 86400000;
  test('بازیابی، تاریخِ خریدِ ثبت‌شده را جلو نمی‌برد', () {
    final now = 100 * day;
    final prev = [{'productId': 'rp_pro_1m', 'purchaseToken': 'tk', 'purchaseTime': 70 * day}];
    final out = stabilizePurchaseTimes([{'productId': 'rp_pro_1m', 'purchaseToken': 'tk', 'purchaseTime': now}], prev, now);
    expect(out.single['purchaseTime'], 70 * day);
    final w = computeProWindow(out);
    expect(w.expiresAt, 70 * day + planDurationMs(1));
  });
  test('بدون سابقه: زمانِ بازار حفظ می‌شود؛ زمانِ صفر یا آینده = الان', () {
    final now = 100 * day;
    expect(stabilizePurchaseTimes([{'productId': 'rp_pro_1m', 'purchaseToken': 'a', 'purchaseTime': 80 * day}], const [], now).single['purchaseTime'], 80 * day);
    expect(stabilizePurchaseTimes([{'productId': 'rp_pro_1m', 'purchaseToken': 'b', 'purchaseTime': 0}], const [], now).single['purchaseTime'], now);
    expect(stabilizePurchaseTimes([{'productId': 'rp_pro_1m', 'purchaseToken': 'c', 'purchaseTime': 500 * day}], const [], now).single['purchaseTime'], now);
  });
}
