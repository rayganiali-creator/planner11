// تب «خریدها»: کارت وضعیت، پلن‌ها (انباشته‌شونده)، تاریخچه. خریدِ واقعی از BillingService (Native) می‌آید.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../onboarding/onboarding.dart';

import '../../app/i18n.dart';
import '../../core/date_fmt.dart';
import '../../core/pro.dart';
import '../../data/app_store.dart';
import '../../app/toast.dart';
import '../../data/billing.dart';
import '../../data/owner_unlock.dart';
import '../../ui/tokens.dart';
import '../../ui/pro_widgets.dart';
import '../../ui/widgets.dart';

String purDateLabel(num? ts, {required bool fa, required bool jalali, bool withTime = false}) {
  if (ts == null || ts == 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
  final out = dateLabel(d, jalali: jalali, fa: fa);
  return withTime ? '$out — ${timeLabel(d, fa: fa)}' : out;
}

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  int _titleTaps = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  bool _adminOpen = false;
  final _adminCtl = TextEditingController();
  OwnerUnlock? _owner;

  String? busy;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final billing = context.read<BillingService>();
    final p = context.rp;
    final st = store.state;
    final fa = context.isFa;
    final jalali = isJalali(st);
    String d(num? t, [bool time = false]) => purDateLabel(t, fa: fa, jalali: jalali, withTime: time);
    final segs = proPurchaseSegments(st);
    final now = store.rpNow();
    final lifetime = segs.any((x) => x.lifetime);
    final pc = st['proCache'];
    final expiresAt = pc is Map ? (pc['expiresAt'] as num? ?? 0) : 0;
    final premium = st['isPremium'] == true;
    final timed = premium && expiresAt != 0 && !lifetime;

    Widget hero;
    if (lifetime) {
      hero = _Hero(badge: context.tr('⭐ پرو همیشگی', '⭐ Lifetime Pro'), big: '∞', sub: context.tr('دسترسی همیشگی داری؛ تاریخ پایانی ندارد.', 'You have lifetime access — no expiry date.'));
    } else if (timed) {
      final days = proDaysLeft(st, now) ?? 0;
      final start = segs.isNotEmpty ? segs.first.from : now;
      final total = (expiresAt - start).clamp(1, double.infinity);
      final left = ((expiresAt - now) / total).clamp(0.0, 1.0).toDouble();
      hero = _Hero(
        badge: context.tr('⭐ پرو فعال', '⭐ Pro active'),
        big: context.n(days),
        unit: context.tr('روز باقی‌مانده', 'days left'),
        sub: '${context.tr('پایان دوره: ', 'Ends on: ')}${d(expiresAt)}',
        bar: left,
      );
    } else if (premium) {
      hero = _Hero(badge: context.tr('⭐ پرو فعال', '⭐ Pro active'), big: '∞', sub: context.tr('بدون تاریخ پایان.', 'No end date.'));
    } else {
      hero = _Hero(badge: context.tr('نسخه‌ی رایگان', 'Free plan'), free: true, sub: context.tr('پلن فعالی نداری. با خرید هر پلن، همه‌ی امکانات پرو باز می‌شود.', 'No active plan. Any plan unlocks every Pro feature.'));
    }

    final base = timed ? expiresAt : now;
    final ownedIds = {for (final x in segs) if (!x.unknown && (x.to == null || x.to! > now)) x.p['productId']};
    return ListView(
      padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // مدیر: ۷ ضربه‌ی سریع روی عنوان → کادرِ کدِ مدیر
            final n = DateTime.now();
            _titleTaps = n.difference(_lastTap).inMilliseconds > 2500 ? 1 : _titleTaps + 1;
            _lastTap = n;
            if (_titleTaps >= 7) {
              _titleTaps = 0;
              setState(() => _adminOpen = true);
            }
          },
          child: Row(children: [Expanded(child: Text(context.tr('خریدها', 'Purchases'), style: rpText(RpType.titleL, weight: 800, color: p.text))), const HelpButton('purchases')]),
        ),
        const SizedBox(height: RpSpace.s3),
        if (_adminOpen) ...[
          AppCard(
            child: Row(children: [
              Expanded(child: TextField(key: const ValueKey('admin-code'), controller: _adminCtl, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: InputDecoration(hintText: context.tr('کد مدیر', 'Admin code')))),
              const SizedBox(width: 8),
              RpButton(context.tr('تأیید', 'Unlock'), small: true, onTap: () async {
                _owner ??= OwnerUnlock(context.read<AppStore>(), context.read<ToastBus>());
                final code = _adminCtl.text;
                _adminCtl.clear();
                final ok = await _owner!.tryCode(code);
                if (ok && mounted) setState(() => _adminOpen = false);
              }),
            ]),
          ),
          const SizedBox(height: RpSpace.s3),
        ],
        hero,
        if (!premium) ...[const SizedBox(height: RpSpace.s3), const ProPitch()],
        if (!lifetime && (!premium || timed)) ...[
          const SizedBox(height: RpSpace.s4),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                timed
                    ? context.tr('پلن تازه به انتهای پلن فعلی اضافه می‌شود، نه اینکه جایش را بگیرد. مثلاً اگر ۱۵ روز از پلنِ یک‌ماهه‌ات مانده باشد و پلنِ دوماهه بخری، ۷۵ روز خواهی داشت.',
                        'A new plan is added to the end of your current plan — it does not replace it. If 15 days remain on your 1-month plan and you buy 2 months, you will have 75 days.')
                    : context.tr('با خرید هر پلن، پرو از همین لحظه فعال می‌شود.', 'Buying any plan activates Pro right away.'),
                style: rpText(RpType.body, weight: 500, color: p.muted, height: 1.8),
              ),
              if (ownedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr('هر پلن تا پایان دوره‌اش دوباره قابل خرید نیست؛ برای تمدید یکی از پلن‌های دیگر را انتخاب کن.', 'A plan cannot be bought again until its period ends; pick one of the other plans to extend.'),
                    style: rpText(RpType.label, weight: 500, color: p.muted, height: 1.8),
                  ),
                ),
              const SizedBox(height: RpSpace.s3),
              for (final plan in proPlans)
                _PlanRow(
                  plan: plan,
                  owned: ownedIds.contains(plan.id),
                  timed: timed,
                  until: d(base + planDurationMs(plan.months)),
                  busy: busy == plan.id,
                  onBuy: () async {
                    setState(() => busy = plan.id);
                    try {
                      await billing.purchase(plan.id);
                    } finally {
                      if (mounted) setState(() => busy = null);
                    }
                  },
                ),
            ]),
          ),
        ],
        const SizedBox(height: RpSpace.s3),
        const ProComparison(),
        const SizedBox(height: RpSpace.s3),
        RpButton(context.tr('بازیابی خریدها', 'Restore purchases'), icon: LucideIcons.refreshCw, kind: BtnKind.tonal, onTap: () async {
          await billing.restore();
        }),
        const SizedBox(height: RpSpace.s4),
        SectionHeader(context.tr('تاریخچه‌ی خریدها', 'Purchase history')),
        if (segs.isEmpty)
          AppCard(child: Text(context.tr('هنوز خریدی ثبت نشده. هر خریدی که انجام بدهی همین‌جا با تاریخ و مدتش ثبت می‌شود.', 'No purchases yet. Every purchase you make will be listed here with its date and duration.'), style: rpText(RpType.body, weight: 500, color: p.muted, height: 1.8)))
        else
          for (final x in segs.reversed)
            _HistoryItem(seg: x, now: now, d: d),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final String badge, sub;
  final String? big, unit;
  final double? bar;
  final bool free;
  const _Hero({required this.badge, required this.sub, this.big, this.unit, this.bar, this.free = false});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Container(
      padding: const EdgeInsets.all(RpSpace.s5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RpRadius.xl),
        gradient: free ? null : LinearGradient(colors: [p.btnA, p.btnB]),
        color: free ? p.surface2 : null,
        border: free ? Border.all(color: p.line) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RpChip(badge, tone: free ? ChipTone.primary : ChipTone.gold),
        if (big != null) ...[
          const SizedBox(height: RpSpace.s2),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(big!, style: rpText(RpType.display, weight: 800, color: free ? p.text : p.onPrimary)),
            if (unit != null) ...[const SizedBox(width: 8), Text(unit!, style: rpText(RpType.body, weight: 600, color: free ? p.muted : p.onPrimary))],
          ]),
        ],
        const SizedBox(height: 6),
        Text(sub, style: rpText(RpType.body, weight: 500, color: free ? p.muted : p.onPrimary, height: 1.8)),
        if (bar != null) ...[
          const SizedBox(height: RpSpace.s3),
          RpProgressBar(value: bar!, colors: [p.gold, p.goldSoft]),
        ],
      ]),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final ProPlan plan;
  final bool owned, timed, busy;
  final String until;
  final VoidCallback onBuy;
  const _PlanRow({required this.plan, required this.owned, required this.timed, required this.busy, required this.until, required this.onBuy});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final dd = (planDurationMs(plan.months) / 86400000).round();
    final best = plan.months == 6;
    return Container(
      margin: const EdgeInsets.only(bottom: RpSpace.s2),
      padding: const EdgeInsets.all(RpSpace.s3),
      decoration: BoxDecoration(
        color: owned ? p.okSoft : p.surface2,
        borderRadius: BorderRadius.circular(RpRadius.md),
        border: Border.all(color: best ? p.gold : p.line, width: best ? 1.5 : 1),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(fa ? plan.labelFa : plan.labelEn, style: rpText(RpType.bodyL, weight: 800, color: p.text)),
              if (best) RpChip(context.tr('به‌صرفه‌ترین', 'Best value'), tone: ChipTone.gold),
            ]),
            Text(fa ? plan.priceFa : plan.priceEn, style: rpText(RpType.body, weight: 700, color: p.primary)),
            Text('+ ${context.n(dd)} ${context.tr('روز', 'days')}', style: rpText(RpType.label, weight: 600, color: p.muted)),
            Text(owned ? context.tr('همین حالا در پلن توست', 'already in your plan') : '${context.tr('تا ', 'until ')}$until', style: rpText(RpType.label, weight: 500, color: p.muted)),
          ]),
        ),
        SizedBox(
          width: 110,
          child: RpButton(
            busy ? context.tr('در حال اتصال…', 'Connecting…') : owned ? context.tr('خریداری‌شده', 'Owned') : timed ? context.tr('افزودن', 'Add') : context.tr('خرید', 'Buy'),
            small: true,
            onTap: (owned || busy) ? null : onBuy,
          ),
        ),
      ]),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ProSegment seg;
  final num now;
  final String Function(num?, [bool]) d;
  const _HistoryItem({required this.seg, required this.now, required this.d});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final fa = context.isFa;
    final x = seg;
    String chip;
    var col = p.muted;
    if (x.lifetime) {
      chip = context.tr('همیشگی', 'Lifetime');
      col = p.okInk;
    } else if (x.unknown) {
      chip = context.tr('نامشخص', 'Unknown');
    } else if (now >= x.to!) {
      chip = context.tr('تمام‌شده', 'Ended');
    } else if (now >= x.from) {
      chip = context.tr('فعال', 'Active');
      col = p.okInk;
    } else {
      chip = context.tr('در نوبت', 'Queued');
      col = p.blueInk;
    }
    final name = x.plan != null ? (fa ? x.plan!.labelFa : x.plan!.labelEn) : x.lifetime ? context.tr('نسخه‌ی همیشگی', 'Lifetime unlock') : '${x.p['productId'] ?? '—'}';
    final price = x.plan != null ? ' · ${fa ? x.plan!.priceFa : x.plan!.priceEn}' : '';
    final tok = '${x.p['purchaseToken'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s2),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: rpText(RpType.body, weight: 800, color: p.text))),
            Text(chip, style: rpText(RpType.label, weight: 700, color: col)),
          ]),
          const SizedBox(height: 4),
          Text('${context.tr('خرید: ', 'Purchased: ')}${d(x.p['purchaseTime'] as num?, true)}$price', style: rpText(RpType.label, weight: 500, color: p.muted)),
          if (!x.unknown)
            Text(
              '${context.tr('از ', 'From ')}${d(x.from)}${x.to == null ? context.tr(' برای همیشه', ' forever') : context.tr(' تا ', ' to ') + d(x.to)}',
              style: rpText(RpType.label, weight: 500, color: p.muted),
            ),
          if (tok.isNotEmpty)
            Text('${context.tr('کد رهگیری: ', 'Receipt: ')}…${tok.length > 10 ? tok.substring(tok.length - 10) : tok}', style: rpText(RpType.caption, weight: 500, color: p.muted)),
        ]),
      ),
    );
  }
}
