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
  /// true = حاشیه‌های شفافِ تصویر بریده می‌شود تا خودِ آواتار کادر را پر کند ([height] = ارتفاعِ بخشِ دیدنی)
  final bool cropToContent;
  const AvatarView({super.key, required this.data, required this.gender, required this.equipped, required this.cond, this.height = 180, this.headOnly = false, this.mode, this.cropToContent = false});
  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));
  ui.Image? _img;
  Rect? _bbox;
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
    Rect? bb;
    if (widget.cropToContent && im != null) bb = await _contentBox(im);
    if (!mounted || t != _token) return;
    setState(() {
      _img = im;
      _bbox = bb;
    });
    final asleep = widget.cond == 'asleep';
    if (asleep || MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  /// کادرِ پیکسل‌های غیرشفاف (با ۲ پیکسل حاشیه)
  static Future<Rect> _contentBox(ui.Image im) async {
    final bd = (await im.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
    int x0 = im.width, y0 = im.height, x1 = -1, y1 = -1;
    for (int y = 0; y < im.height; y++) {
      for (int x = 0; x < im.width; x++) {
        if (bd[(y * im.width + x) * 4 + 3] > 8) {
          if (x < x0) x0 = x;
          if (x > x1) x1 = x;
          if (y < y0) y0 = y;
          if (y > y1) y1 = y;
        }
      }
    }
    if (x1 < 0) return Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble());
    return Rect.fromLTRB((x0 - 2).clamp(0, im.width).toDouble(), (y0 - 2).clamp(0, im.height).toDouble(), (x1 + 3).clamp(0, im.width).toDouble(), (y1 + 3).clamp(0, im.height).toDouble());
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
        : (widget.cropToContent && _bbox != null ? _bbox! : const Rect.fromLTWH(0, 0, avW, avH));
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
