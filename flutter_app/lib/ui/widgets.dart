// اجزای پایه‌ی Design System — همه از tokens.dart می‌خوانند.
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/app_store.dart';
import 'tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(RpSpace.s4), this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final b = context.rpBrightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RpRadius.lg),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(RpRadius.lg),
            border: Border.all(color: p.line),
            boxShadow: RpShadow.e1(b),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s3),
      child: Row(children: [
        Expanded(child: Text(title, style: rpText(RpType.bodyL, weight: 800, color: p.text))),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(action!, style: rpText(RpType.label, weight: 700, color: p.primary)),
            ),
          ),
      ]),
    );
  }
}

enum ChipTone { primary, gold, ok, bad, xp, hp }

class RpChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ChipTone tone;
  const RpChip(this.label, {super.key, this.icon, this.tone = ChipTone.primary});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final (bg, fg) = switch (tone) {
      ChipTone.primary => (p.primarySoft, p.primary),
      ChipTone.gold => (p.goldSoft, p.goldInk),
      ChipTone.ok => (p.okSoft, p.okInk),
      ChipTone.bad => (p.badSoft, p.badInk),
      ChipTone.xp => (p.xpSoft, p.xpInk),
      ChipTone.hp => (p.hpSoft, p.hpInk),
    };
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(RpRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
        Text(label, style: rpText(RpType.label, weight: 700, color: fg, height: 1.2)),
      ]),
    );
  }
}

enum BtnKind { primary, tonal, ghost, danger }

class RpButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final BtnKind kind;
  final bool small;
  const RpButton(this.label, {super.key, this.icon, this.onTap, this.kind = BtnKind.primary, this.small = false});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final h = small ? 36.0 : 48.0;
    final radius = BorderRadius.circular(small ? RpRadius.sm : RpRadius.md);
    Color fg;
    Decoration deco;
    switch (kind) {
      case BtnKind.primary:
        fg = p.onPrimary;
        deco = BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [p.btnA, p.btnB]),
          boxShadow: [BoxShadow(color: p.btnA.withValues(alpha: .35), blurRadius: 20, offset: const Offset(0, 8))],
        );
      case BtnKind.tonal:
        fg = p.primary;
        deco = BoxDecoration(borderRadius: radius, color: p.primarySoft);
      case BtnKind.ghost:
        fg = p.text;
        deco = BoxDecoration(borderRadius: radius, border: Border.all(color: p.line, width: 1.5));
      case BtnKind.danger:
        fg = p.badInk;
        deco = BoxDecoration(borderRadius: radius, color: p.badSoft);
    }
    return Opacity(
      opacity: onTap == null ? .55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            height: h,
            padding: EdgeInsets.symmetric(horizontal: small ? 10 : 20),
            decoration: deco,
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: small ? 16 : 18, color: fg), const SizedBox(width: 8)],
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(small ? RpType.label : RpType.body, weight: 800, color: fg, height: 1.2))),
            ]),
          ),
        ),
      ),
    );
  }
}

class RpProgressBar extends StatelessWidget {
  final double value; // 0..1
  final List<Color> colors;
  final double height;
  const RpProgressBar({super.key, required this.value, required this.colors, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RpRadius.pill),
      child: Container(
        height: height,
        color: p.line,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1).toDouble(),
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
        ),
      ),
    );
  }
}

/// حلقه‌ی پیشرفت (معادلِ conic-gradient)
class RpRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final Widget? center;
  final Color? color;
  const RpRing({super.key, required this.value, this.size = 92, this.center, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value.clamp(0, 1).toDouble(), color ?? p.primary, p.line, size * .1),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color fg, bg;
  final double w;
  _RingPainter(this.v, this.fg, this.bg, this.w);
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(w / 2, w / 2, s.width - w, s.height - w);
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = w..color = bg;
    c.drawArc(r, 0, 6.2831853, false, base);
    if (v <= 0) return;
    final top = Paint()..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..color = fg;
    c.drawArc(r, -1.5707963, 6.2831853 * v, false, top); // از بالا، ساعت‌گرد
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.fg != fg || o.bg != bg;
}

/// فاصله‌ی پایین فهرست‌ها (نوار ناوبری دیگر روی محتوا نمی‌افتد؛ فقط کمی هوا زیرِ آخرین ردیف).
double rpBottomPad(BuildContext context) => 28;


/// بخشِ کشویی (آکاردئون): ردیفِ مینیمالِ عنوان + خلاصه + فلش؛ با ضربه باز/بسته می‌شود (انیمیشن نرم).
/// اگر [persistKey] بدهید وضعیتِ باز/بسته در state['uiOpen'] ذخیره می‌شود.
class RpCollapsible extends StatefulWidget {
  final String title;
  final String? summary;
  final IconData? icon;
  final Widget child;
  final String? persistKey;
  final bool initiallyOpen;
  final bool card; // داخل کارت (پیش‌فرض) یا بی‌قاب
  const RpCollapsible({super.key, required this.title, required this.child, this.summary, this.icon, this.persistKey, this.initiallyOpen = false, this.card = true});
  @override
  State<RpCollapsible> createState() => _RpCollapsibleState();
}

class _RpCollapsibleState extends State<RpCollapsible> {
  late bool open = widget.initiallyOpen;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final k = widget.persistKey;
      if (k != null) {
        final st = _stateOf(context);
        final m = st?['uiOpen'];
        if (m is Map && m[k] is bool) open = m[k] as bool;
      }
    }
  }

  static Map? _stateOf(BuildContext context) {
    try {
      return context.read<AppStore>().state;
    } catch (_) {
      return null;
    }
  }

  void _toggle() {
    setState(() => open = !open);
    final k = widget.persistKey;
    if (k == null) return;
    try {
      final store = context.read<AppStore>();
      if (store.state['uiOpen'] is! Map) store.state['uiOpen'] = <String, dynamic>{};
      (store.state['uiOpen'] as Map)[k] = open;
      store.save();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final header = InkWell(
      borderRadius: BorderRadius.circular(RpRadius.lg),
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RpSpace.s4, vertical: RpSpace.s3),
        child: Row(children: [
          if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: p.muted), const SizedBox(width: 10)],
          Expanded(child: Text(widget.title, style: rpText(RpType.body, weight: 800, color: p.text))),
          if (widget.summary != null && !open)
            Flexible(child: Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: Text(widget.summary!, maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.label, weight: 600, color: p.muted)))),
          AnimatedRotation(turns: open ? .5 : 0, duration: RpMotion.fast, child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: p.muted)),
        ]),
      ),
    );
    final body = AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: open ? Padding(padding: const EdgeInsets.fromLTRB(RpSpace.s4, 0, RpSpace.s4, RpSpace.s4), child: widget.child) : const SizedBox(width: double.infinity),
    );
    final col = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, body]);
    return widget.card ? AppCard(padding: EdgeInsets.zero, child: col) : col;
  }
}
