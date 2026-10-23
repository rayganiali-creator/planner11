import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/app/toast.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/data/owner_unlock.dart';

void main() {
  test('کلید مشتق‌شده با Python/hashlib یکسان است', () async {
    expect(await deriveOwnerKey('test-code-123'), 'f485a8761b7653e885f2a51a9d89957aea8a40a6a836625560b047dc624404a2');
  });
  test('کد اشتباه پرو نمی‌دهد و پس از ۵ بار قفل می‌شود', () async {
    final dir = Directory.systemTemp.createTempSync('rp_own');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    var t = DateTime(2025, 1, 1, 10);
    final u = OwnerUnlock(store, ToastBus(), clock: () => t);
    for (int i = 0; i < 5; i++) {
      expect(await u.tryCode('wrong$i'), isFalse);
    }
    expect(store.state['isPremium'], isNot(true));
    expect(store.state.containsKey('__rpOwnerMark'), isFalse);
    expect(await u.tryCode(''), isFalse); // قفل
    t = t.add(const Duration(seconds: 31));
    expect(await u.tryCode('x'), isFalse);
  });
}
