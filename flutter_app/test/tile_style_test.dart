import 'dart:ui' show PictureRecorder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_planner/features/calendar/tile_style.dart';

void main() {
  test('هر ۱۹ شکل مسیرِ غیرخالی و داخل کادر می‌سازد', () {
    expect(tileShapes.length, 19);
    expect(tileEffects.length, 14);
    for (final t in tileShapes) {
      final b = tilePath(t.id, const Size(40, 40)).getBounds();
      expect(b.isEmpty, isFalse, reason: t.id);
      expect(b.left >= -0.01 && b.top >= -0.01 && b.right <= 40.01 && b.bottom <= 40.01, isTrue, reason: '${t.id} $b');
    }
  });
  test('دایره و ستاره: نقطه‌ی مرکز داخل، گوشه‌ی دایره بیرون', () {
    expect(tilePath('round', const Size(40, 40)).contains(const Offset(20, 20)), isTrue);
    expect(tilePath('round', const Size(40, 40)).contains(const Offset(1, 1)), isFalse);
    expect(tilePath('square', const Size(40, 40)).contains(const Offset(3, 3)), isTrue);
    expect(tilePath('star', const Size(40, 40)).contains(const Offset(1, 38)), isFalse);
  });
  test('همه‌ی جلوه‌ها بدون خطا رسم می‌شوند', () {
    for (final e in tileEffects) {
      for (final s in ['round', 'heart', 'hex', 'blob']) {
        final rec = PictureRecorder();
        final c = Canvas(rec);
        final st = TileStyle(shape: s, effect: e.id);
        const size = Size(40, 40);
        final path = tilePath(s, size);
        st.paintOuter(c, path);
        st.paintInner(c, path, Offset.zero & size, false);
        st.paintOverlay(c, path, Offset.zero & size);
        rec.endRecording();
      }
    }
  });
}
