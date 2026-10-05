// انتخاب جنسیت (اولین اجرا) و پنل شخصی‌سازی/فروشگاه آواتار.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../core/gameplay.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/avatar_ops.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'avatar_compose.dart';
import 'avatar_view.dart';

Future<void> showGenderPicker(BuildContext context) {
  final a = context.read<AppActions>();
  final data = context.read<AvData?>();
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final p = ctx.rp;
      return AlertDialog(
        backgroundColor: p.surface,
        title: Text(ctx.tr('آواتار خودت را بساز', 'Create your avatar'), style: rpText(RpType.title, weight: 800, color: p.text)),
        content: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final g in const [('male', 'مرد', 'Male'), ('female', 'زن', 'Female')])
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(RpRadius.md),
                onTap: () {
                  a.chooseGender(g.$1);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    if (data != null) AvatarView(data: data, gender: g.$1, equipped: const {}, cond: 'ok', height: 80),
                    const SizedBox(height: 6),
                    Text(ctx.isFa ? g.$2 : g.$3, style: rpText(RpType.bodyL, weight: 800, color: p.text)),
                  ]),
                ),
              ),
            ),
        ]),
      );
    },
  );
}

Future<void> showAvatarPanel(BuildContext context) {
  final a = context.read<AppActions>();
  final data = context.read<AvData?>();
  if (data == null) return Future.value();
  if (a.avState().gender == null) return showGenderPicker(context);
  final store = context.read<AppStore>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (_) => MultiProvider(providers: [ChangeNotifierProvider.value(value: store), Provider.value(value: a), Provider<AvData?>.value(value: data)], child: const _Panel()),
  );
}

class _Panel extends StatefulWidget {
  const _Panel();
  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  String cat = 'clothes';
  String? sel;
  bool armed = false;

  List<AvCategory> visibleCats(AvData d, String g) => [for (final c in avCategories) if (!c.hidden && d.items.values.any((it) => it.category == c.key && it.compatible(g))) c];

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    final a = context.read<AppActions>();
    final d = context.read<AvData?>()!;
    final p = context.rp;
    final fa = context.isFa;
    final st = a.avState();
    final g = st.gender!;
    final pro = a.store.state['isPremium'] == true;
    final coins = ((a.store.state['scores'] as Map)['coins'] as num?) ?? 0;
    final equipped = d.equippedFor(a.store.state, g);
    final selItem = sel == null ? null : d.items[sel];
    // پیش‌نمایش: آیتمِ انتخاب‌شده را امتحان می‌کنیم
    final preview = Map<String, String>.from(equipped);
    if (selItem != null && selItem.compatible(g)) {
      preview[selItem.slot] = selItem.id;
      if (selItem.kind == 'pants' && preview['clothes'] != null && d.items[preview['clothes']]?.kind == 'outfit') preview.remove('clothes');
    }
    final now = a.today;
    final hp = computeAvatarHP(a.store.state, now);
    final cond = avConditionOf(hp, now.hour);
    final cats = visibleCats(d, g);
    if (!cats.any((c) => c.key == cat)) cat = 'clothes';
    var list = [for (final it in d.items.values) if (it.category == cat && it.compatible(g)) it];
    String? petNote;
    if (cat == 'petgear') {
      final petId = equipped['pet'];
      if (petId == null) {
        petNote = fa ? '🐾 اول از تبِ «حیوان» یک حیوان همراه انتخاب کن تا لوازمش روی او دیده شود.' : '🐾 Pick a pet from the Pets tab first so its gear shows up.';
      } else {
        final before = list.length;
        final anchors = (d.raw['petAnchor'] as Map?)?[petId] as Map?;
        list = [for (final it in list) if (anchors != null && anchors[it.on] != null) it];
        if (list.length < before) petNote = fa ? '🐢 «${d.items[petId]?.name ?? ''}» فقط کلاه می‌پوشد؛ گردنی‌ها برایش نمایش داده نمی‌شوند.' : '🐢 This pet only wears hats, so neck items are hidden.';
      }
    }

    String actionLabel() {
      final it = selItem;
      if (it == null) return fa ? 'یک آیتم را انتخاب کنید' : 'Select an item';
      if (it.kind == 'base') {
        final cur = a.baseIdFor(d, g);
        return cur == it.id ? (fa ? 'مدل فعلی' : 'Current model') : (fa ? 'انتخاب این مدل' : 'Use this model');
      }
      if (it.price > 0 && !pro) return fa ? '⭐ این آیتم با نسخه‌ی پرو باز می‌شود' : '⭐ Unlocks with Pro';
      if (equipped[it.slot] == it.id) return fa ? 'درآوردن' : 'Unequip';
      if (a.avOwned(d, it.id)) return fa ? 'پوشیدن' : 'Equip';
      if (coins < it.price) return fa ? 'سکه کافی نیست (${context.n((it.price - coins).round())} کم است)' : 'Not enough coins (${(it.price - coins).round()} short)';
      final pr = context.n(it.price);
      return armed ? (fa ? 'تأیید خرید · $pr 🪙' : 'Confirm · $pr 🪙') : (fa ? 'خرید · $pr 🪙' : 'Buy · $pr 🪙');
    }

    bool actionEnabled() {
      final it = selItem;
      if (it == null) return false;
      if (it.kind == 'base') return a.baseIdFor(d, g) != it.id;
      if (it.price > 0 && !pro) return true;
      if (equipped[it.slot] == it.id || a.avOwned(d, it.id)) return true;
      return coins >= it.price;
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s2, 0),
        child: Row(children: [
          Expanded(child: Text(context.tr('آواتار من', 'My avatar'), style: rpText(RpType.title, weight: 800, color: p.text))),
          Text('🪙 ${context.n(coins.round())}', style: rpText(RpType.bodyL, weight: 800, color: p.goldInk)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
      ),
      Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: RpSpace.s4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(RpRadius.lg), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [avatarSky(isDay(now.hour)).top, avatarSky(isDay(now.hour)).bottom])),
        // حیوان همیشه سمتِ راستِ آواتار است (راست‌چین/چپ‌چین فرقی نمی‌کند)
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            AvatarView(data: d, gender: g, equipped: preview, cond: cond, height: 110, mode: 'noPet'),
            if (preview.values.any((id) => d.items[id]?.kind == 'pet')) AvatarView(data: d, gender: g, equipped: preview, cond: cond, height: 110, mode: 'petOnly'),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: RpSpace.s4, vertical: RpSpace.s2),
        child: Row(children: [
          for (final gg in const [('male', 'مرد', 'Male'), ('female', 'زن', 'Female')])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(fa ? gg.$2 : gg.$3),
                selected: g == gg.$1,
                onSelected: (_) => setState(() {
                  a.switchGender(gg.$1);
                  sel = null;
                  armed = false;
                }),
              ),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: RpSpace.s4),
        child: Wrap(spacing: 6, runSpacing: 0, children: [
          for (final c in cats)
            ChoiceChip(
              key: ValueKey('cat-${c.key}'),
              visualDensity: VisualDensity.compact,
              label: Text('${c.icon} ${fa ? c.fa : c.en}'),
              selected: cat == c.key,
              onSelected: (_) => setState(() {
                cat = c.key;
                sel = null;
                armed = false;
              }),
            ),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(RpSpace.s4), children: [
          if (petNote != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(petNote, style: rpText(RpType.label, weight: 600, color: p.muted))),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: .78,
            children: [
              for (final it in list)
                _Card(
                  item: it,
                  gender: g,
                  selected: sel == it.id,
                  onTap: () => setState(() {
                    sel = it.id;
                    armed = false;
                  }),
                  tag: _tag(context, it, a, d, g, equipped, pro, coins),
                  equippedNow: it.kind == 'base' ? a.baseIdFor(d, g) == it.id : equipped[it.slot] == it.id,
                  locked: (it.price > 0 && !pro) || (!a.avOwned(d, it.id) && it.price > coins),
                ),
            ],
          ),
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RpSpace.s4, 0, RpSpace.s4, RpSpace.s3),
          child: RpButton(
            actionLabel(),
            onTap: actionEnabled()
                ? () {
                    final res = a.avAction(d, selItem!, armed: armed);
                    setState(() {
                      armed = res == 'armed';
                      if (res == 'unequipped') sel = null;
                    });
                    if (res == 'armed') {
                      Future.delayed(const Duration(milliseconds: 3500), () {
                        if (mounted) setState(() => armed = false);
                      });
                    }
                    if (res == 'pro') {
                      Navigator.pop(context);
                      a.toasts.show(context.tr('⭐ آیتم‌های آواتار با نسخه‌ی پرو باز می‌شوند و بعد با سکه خریده می‌شوند. انتخاب مرد یا زن و مدل‌ها رایگان است.', '⭐ Avatar items unlock with Pro and are then bought with coins. Gender and models are free.'), ms: 3400);
                    }
                  }
                : null,
          ),
        ),
      ),
    ]);
  }

  String _tag(BuildContext context, AvItem it, AppActions a, AvData d, String g, Map<String, String> eq, bool pro, num coins) {
    final fa = context.isFa;
    final owned = a.avOwned(d, it.id);
    final on = it.kind == 'base' ? a.baseIdFor(d, g) == it.id : eq[it.slot] == it.id;
    final proLock = it.price > 0 && !pro;
    final locked = proLock || (!owned && it.price > coins);
    if (proLock) return owned ? (fa ? '⭐ پرو (خریداری‌شده)' : '⭐ Pro (owned)') : (fa ? '⭐ پرو · ${context.n(it.price)} 🪙 سکه' : '⭐ Pro · ${it.price} 🪙 coins');
    if (on) return it.kind == 'base' ? (fa ? '✓ مدل فعلی' : '✓ Current') : (fa ? '✓ پوشیده' : '✓ Equipped');
    if (it.kind == 'base') return fa ? 'رایگان' : 'Free';
    if (owned) return fa ? 'خریداری‌شده' : 'Owned';
    if (it.price == 0) return fa ? 'رایگان' : 'Free';
    return '${locked ? '🔒 ' : ''}${fa ? '${context.n(it.price)} 🪙 سکه' : '${it.price} 🪙 coins'}';
  }
}

class _Card extends StatelessWidget {
  final AvItem item;
  final String gender, tag;
  final bool selected, equippedNow, locked;
  final VoidCallback onTap;
  const _Card({required this.item, required this.gender, required this.selected, required this.onTap, required this.tag, required this.equippedNow, required this.locked});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RpRadius.md),
      child: Opacity(
        opacity: locked ? .6 : 1,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(RpRadius.md),
            border: Border.all(color: selected ? p.primary : (equippedNow ? p.okInk : p.line), width: selected || equippedNow ? 2 : 1),
          ),
          child: Column(children: [
            Expanded(child: AvThumb(item: item, gender: gender)),
            Text(item.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: rpText(RpType.caption, weight: 700, color: p.text, height: 1.3)),
            Text(tag, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: rpText(9, weight: 600, color: p.muted, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}

final Map<String, ui.Rect> _bbox = {};

/// تصویرِ کوچکِ آیتم: کادرِ پیکسل‌های غیرشفاف را می‌برد و وسط کارت می‌گذارد (مثل avThumb)
class AvThumb extends StatefulWidget {
  final AvItem item;
  final String gender;
  const AvThumb({super.key, required this.item, required this.gender});
  @override
  State<AvThumb> createState() => _AvThumbState();
}

class _AvThumbState extends State<AvThumb> {
  ui.Image? img;
  ui.Rect? box;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final src = widget.item.assetFor(widget.gender);
    final im = await avLoadImg(src);
    if (im == null || !mounted) return;
    var bb = _bbox[src];
    if (bb == null) {
      final bd = (await im.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
      int x0 = im.width, y0 = im.height, x1 = -1, y1 = -1;
      for (int y = 0; y < im.height; y++) {
        for (int x = 0; x < im.width; x++) {
          if (bd[(y * im.width + x) * 4 + 3] != 0) {
            if (x < x0) x0 = x;
            if (x > x1) x1 = x;
            if (y < y0) y0 = y;
            if (y > y1) y1 = y;
          }
        }
      }
      bb = x1 < 0 ? ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()) : ui.Rect.fromLTWH(x0.toDouble(), y0.toDouble(), (x1 - x0 + 1).toDouble(), (y1 - y0 + 1).toDouble());
      _bbox[src] = bb;
    }
    if (mounted) {
      setState(() {
        img = im;
        box = bb;
      });
    }
  }

  @override
  Widget build(BuildContext context) => img == null ? const SizedBox.shrink() : CustomPaint(painter: _ThumbPainter(img!, box!), size: Size.infinite);
}

class _ThumbPainter extends CustomPainter {
  final ui.Image im;
  final ui.Rect bb;
  _ThumbPainter(this.im, this.bb);
  @override
  void paint(Canvas c, Size s) {
    final k = (s.width / bb.width < s.height / bb.height ? s.width / bb.width : s.height / bb.height) * .9;
    final w = (bb.width * k).roundToDouble(), h = (bb.height * k).roundToDouble();
    c.drawImageRect(im, bb, Rect.fromLTWH(((s.width - w) / 2).roundToDouble(), ((s.height - h) / 2).roundToDouble(), w, h), Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_ThumbPainter o) => o.im != im;
}
