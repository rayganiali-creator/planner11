import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_planner/core/date_fmt.dart';
import 'package:routine_planner/core/format.dart';
import 'package:routine_planner/data/app_store.dart';
import 'package:routine_planner/ui/tokens.dart';
import 'package:routine_planner/features/shared/date_picker.dart';

void main() {
  final nowRuz = DateTime(2025, 3, 21, 14, 5); // ۱ فروردین ۱۴۰۴
  test('پیش‌فرض جلالی؛ فقط gregorian صریح میلادی است', () {
    expect(isJalali({}), isTrue);
    expect(isJalali({'calendarType': 'jalali'}), isTrue);
    expect(isJalali({'calendarType': 'gregorian'}), isFalse);
  });
  test('برچسب‌ها: جلالی/میلادی × فارسی/انگلیسی', () {
    expect(dateLabel(nowRuz, jalali: true, fa: true), '۱ فروردین ۱۴۰۴');
    expect(dateLabel(nowRuz, jalali: true, fa: false), '1 Farvardin 1404');
    expect(dateLabel(nowRuz, jalali: false, fa: false), 'Mar 21, 2025');
    expect(dateLabel(nowRuz, jalali: false, fa: true), '۲۱ مارس ۲۰۲۵');
    expect(dateTimeLabel(nowRuz, jalali: true, fa: true), '۱ فروردین — ۱۴:۰۵');
    expect(dateNumeric(nowRuz, jalali: true, fa: true), '۱۴۰۴/۱/۱');
    expect(dateNumeric(nowRuz, jalali: false, fa: false), '3/21/2025');
    expect(dateLabel(nowRuz, jalali: true, fa: true, weekday: true), 'جمعه، ۱ فروردین ۱۴۰۴');
  });
  test('هدر: رفتارِ قدیمی (فارسی=جلالی) حفظ شده و با تنظیم قابل‌تغییر است', () {
    expect(clockText(nowRuz, fa: true), 'جمعه، ۱ فروردین — ۱۴:۰۵');
    expect(clockText(nowRuz, fa: false), 'Friday, Mar 21 — 14:05');
    expect(clockText(nowRuz, fa: true, jalali: false), 'جمعه، ۲۱ مارس — ۱۴:۰۵');
    expect(clockText(nowRuz, fa: false, jalali: true), 'Friday, 1 Farvardin — 14:05');
  });

  Future<AppStore> mk(WidgetTester t, String cal) async {
    final dir = Directory.systemTemp.createTempSync('rp_dp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = AppStore('${dir.path}/s.json')..load();
    store.state['calendarType'] = cal;
    return store;
  }

  testWidgets('انتخابگر تاریخ جلالی: روزِ جلالی را به میلادیِ درست برمی‌گرداند', (tester) async {
    final store = await mk(tester, 'jalali');
    DateTime? out;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(theme: buildRpTheme(Brightness.light), home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () async => out = await pickDate(c, DateTime(2025, 3, 21), first: DateTime(2024), last: DateTime(2027)), child: const Text('go'))))),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jd-1404-1-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('jd-1404-1-15')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jp-next')));
    await tester.pump();
    expect(find.byKey(const ValueKey('jd-1404-2-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('jd-1404-2-10'))); // ۱۰ اردیبهشت ۱۴۰۴ = 2025-04-30
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jp-ok')));
    await tester.pumpAndSettle();
    expect(out, DateTime(2025, 4, 30));
  });

  testWidgets('تنظیم میلادی: انتخابگر Material باز می‌شود (نه جلالی)', (tester) async {
    final store = await mk(tester, 'gregorian');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(theme: buildRpTheme(Brightness.light), home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => pickDate(c, DateTime(2025, 3, 21), first: DateTime(2024), last: DateTime(2027)), child: const Text('go'))))),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.byKey(const ValueKey('jp-ok')), findsNothing);
  });
}
