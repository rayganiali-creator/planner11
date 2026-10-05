// نمایش آواتار: سر/صورت (مینی) یا تمام‌قد، با تنفسِ نرم (در خواب و «کاهش حرکت» ساکن).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'avatar_compose.dart';

class AvatarView extends StatefulWidget {
  final AvData data;
  final String gender;
  final Map<String, String> equipped;
  final String cond;
  final double height;
  final bool headOnly;
  final String? mode;
  const AvatarView({super.key, required this.data, required this.gender, required this.equipped, required this.cond, this.height = 180, this.headOnly = false, this.mode});
  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));
  ui.Image? _img;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _compose();
  }

  @override
  void didUpdateWidget(AvatarView o) {
    super.didUpdateWidget(o);
    if (o.gender != widget.gender || o.cond != widget.cond || o.mode != widget.mode || !_same(o.equipped, widget.equipped)) _compose();
  }

  bool _same(Map a, Map b) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  Future<void> _compose() async {
    final t = ++_token;
    final im = await avCompose(widget.data, widget.gender, widget.equipped, widget.cond, mode: widget.mode);
    if (!mounted || t != _token) return;
    setState(() => _img = im);
    final asleep = widget.cond == 'asleep';
    if (asleep || MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _img;
    final head = (widget.data.raw['head'] as Map)[widget.gender] as List;
    final crop = widget.headOnly
        ? Rect.fromLTWH(avOffX + (head[0] as num), (head[1] as num).toDouble(), (head[2] as num).toDouble(), (head[3] as num).toDouble())
        : const Rect.fromLTWH(0, 0, avW, avH);
    final aspect = crop.width / crop.height;
    return SizedBox(
      height: widget.height,
      width: widget.height * aspect,
      child: img == null
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                // تنفس: کشیدگیِ عمودیِ بسیار کم از پایینِ تصویر (پاها ثابت)
                final s = 1 + 0.012 * math.sin(_c.value * 2 * math.pi) * (widget.cond == 'ok' ? 1 : .6);
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(1, s, 1),
                  child: CustomPaint(painter: _P(img, crop)),
                );
              },
            ),
    );
  }
}

class _P extends CustomPainter {
  final ui.Image img;
  final Rect src;
  _P(this.img, this.src);
  @override
  void paint(Canvas c, Size s) =>
      c.drawImageRect(img, src, Offset.zero & s, Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
  @override
  bool shouldRepaint(_P o) => o.img != img || o.src != src;
}

/// پس‌زمینه‌ی صحنه‌ی آواتار: فقط به ساعتِ روز بستگی دارد (نه به حالت روشن/تاریک برنامه).
/// روز: آسمانِ ملایم (نه خیلی روشن)؛ شب: آسمانِ تیره.
({Color top, Color bottom, Color ground}) avatarSky(bool day) => day
    ? (top: const Color(0xFF8DBBD3), bottom: const Color(0xFFCFE3DC), ground: const Color(0xFF4E8F86))
    : (top: const Color(0xFF0A1B36), bottom: const Color(0xFF1B4A5E), ground: const Color(0xFF082C2A));
