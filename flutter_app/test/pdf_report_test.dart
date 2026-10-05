import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/core/state_model.dart';
import 'package:routine_planner/features/settings/pdf_report.dart';

void main() {
  testWidgets('PDF گزارش ساخته می‌شود (هدر %PDF، چند صفحه برای فهرست بلند)', (tester) async {
    final st = defaultState();
    st['habits'] = [
      {'id': 'h1', 'name': 'ورزش', 'type': 'binary', 'start': '2025-01-01', 'permanent': true},
    ];
    st['todos'] = [for (int i = 0; i < 60; i++) {'id': 't$i', 'title': 'کار شماره $i', 'done': i.isEven}];
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold(body: SizedBox())));
    final overlay = key.currentState!.overlay!;
    final bytes = await tester.runAsync(() async {
      final f = buildPdfReport(st, overlay, today: DateTime(2025, 3, 10));
      for (int i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
      return f;
    });
    expect(bytes, isNotNull);
    expect(ascii.decode(bytes!.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
    final count = RegExp(r'/Count (\d+)').firstMatch(latin1.decode(bytes, allowInvalid: true))?.group(1);
    expect(int.parse(count!), greaterThanOrEqualTo(2));
  });
}
