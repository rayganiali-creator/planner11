// پوسته: صفحه‌ی فعلی + نوار ناوبری شناور + منوی + (Action Grid) + Back اندروید.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/actions.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/calendar/calendar_screens.dart';
import '../features/habits/habits_screen.dart';
import '../ui/tokens.dart';
import 'i18n.dart';
import 'nav.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  @override
  void initState() {
    super.initState();
    // پنجره‌ی «سطح استادی» (ادامه‌ی مرحله‌ی بعد؟) — هر وقت ثبتی به سقفِ مرحله برسد
    context.read<AppActions>().onCapstone = (hid, level) => _capstone(hid, level);
  }

  void _capstone(String hid, int level) {
    final store = context.read<AppActions>().store;
    final h = (store.state['habits'] as List).cast<Map>().firstWhere((x) => x['id'] == hid, orElse: () => {});
    if (h.isEmpty) return;
    final fa = store.state['lang'] != 'en';
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final p = ctx.rp;
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RpRadius.xl)),
          title: Column(children: [
            const Text('🏆', style: TextStyle(fontSize: 40)),
            Text(fa ? 'سطح استادی!' : 'Mastery reached!', style: rpText(RpType.title, weight: 800, color: p.text)),
          ]),
          content: Text(
            fa
                ? 'تبریک! شما در عادت «${h['name']}» به سطح ${level >= 12 ? 'استاد اعظم' : 'استادی'} رسیدید. می‌خواهید این عادت را ادامه دهید و وارد مرحله‌ی بعد شوید؟'
                : 'Congratulations! You reached ${level >= 12 ? 'Grand Master' : 'Master'} level in the habit "${h['name']}". Would you like to continue this habit and move to the next stage?',
            textAlign: TextAlign.center,
            style: rpText(RpType.body, weight: 500, color: p.text, height: 2),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(fa ? 'نه، همین‌جا کافیه' : 'No, this is enough')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AppActions>().continueToNextStage(hid);
              },
              child: Text(fa ? 'بله، ادامه بده' : 'Yes, continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    return PopScope(
      canPop: false, // Back اندروید را خودمان با همان ترتیبِ نسخه‌ی HTML مدیریت می‌کنیم
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!nav.handleBack()) SystemNavigator.pop();
      },
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: RpMotion.slow,
            switchInCurve: RpMotion.ease,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(position: Tween(begin: const Offset(0, .015), end: Offset.zero).animate(anim), child: child),
            ),
            child: KeyedSubtree(key: ValueKey(nav.current), child: _page(nav.current)),
          ),
        ),
        bottomNavigationBar: const GlassNav(),
      ),
    );
  }

  Widget _page(AppView v) => switch (v) {
        AppView.dashboard => const DashboardScreen(),
        AppView.habits => const HabitsScreen(),
        AppView.month => const MonthScreen(),
        AppView.year => const YearScreen(),
        _ => _Soon(view: v),
      };
}

/// جای صفحه‌هایی که هنوز Migration نشده‌اند (رسماً در گزارش وضعیت ثبت است).
class _Soon extends StatelessWidget {
  final AppView view;
  const _Soon({required this.view});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(LucideIcons.hammer, size: 40, color: p.muted),
          const SizedBox(height: 12),
          Text(context.tr('این صفحه هنوز به نسخه‌ی جدید منتقل نشده است.', 'This page has not been migrated yet.'),
              textAlign: TextAlign.center, style: rpText(RpType.body, weight: 600, color: p.muted)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- نوار ناوبری
class GlassNav extends StatelessWidget {
  const GlassNav({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final nav = context.watch<NavController>();
    final dark = context.rpBrightness == Brightness.dark;
    Widget item(AppView v, IconData icon, String label) {
      final on = nav.current == v;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => nav.go(v),
            child: AnimatedContainer(
              duration: RpMotion.base,
              curve: RpMotion.ease,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              decoration: BoxDecoration(color: on ? p.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(18)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 22, color: on ? p.primary : p.muted),
                const SizedBox(height: 2),
                Text(label, style: rpText(RpType.caption, weight: 700, color: on ? p.primary : p.muted, height: 1.2)),
              ]),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: SizedBox(
          height: 76,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: p.surface.withValues(alpha: dark ? .72 : .78),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: dark ? const Color(0x14FFFFFF) : const Color(0xA6FFFFFF)),
                    boxShadow: RpShadow.e3(context.rpBrightness),
                  ),
                  child: Row(children: [
                    item(AppView.dashboard, LucideIcons.house, context.tr('خانه', 'Home')),
                    item(AppView.habits, LucideIcons.target, context.tr('عادت‌ها', 'Habits')),
                    const SizedBox(width: 72), // جای دکمه‌ی +
                    item(AppView.month, LucideIcons.calendarDays, context.tr('تقویم', 'Calendar')),
                    item(AppView.todo, LucideIcons.squareCheck, context.tr('کارها', 'To-Do')),
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 22,
              child: Semantics(
                button: true,
                label: context.tr('انتخاب صفحه', 'Choose a tab'),
                child: GestureDetector(
                  onTap: () => showActionGrid(context),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(colors: [p.gold, const Color(0xFFE9C25F)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                      boxShadow: [
                        BoxShadow(color: p.gold.withValues(alpha: .5), blurRadius: 26, offset: const Offset(0, 12)),
                        BoxShadow(color: p.bg, spreadRadius: 6),
                      ],
                    ),
                    child: Icon(LucideIcons.plus, size: 28, color: p.onGold),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- منوی + (Action Grid)
Future<void> showActionGrid(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x85060E0D),
    builder: (_) => const _ActionGridSheet(),
  );
}

class _ActionGridSheet extends StatelessWidget {
  const _ActionGridSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final nav = context.read<NavController>();
    final items = <(IconData, Color, Color, String, AppView?)>[
      (LucideIcons.target, p.primarySoft, p.primary, context.tr('عادت‌ها', 'Habits'), AppView.habits),
      (LucideIcons.calendarDays, p.blueSoft, p.blueInk, context.tr('ثبت ماهانه', 'Monthly Record'), AppView.month),
      (LucideIcons.calendarRange, p.xpSoft, p.xpInk, context.tr('ثبت سالانه', 'Yearly Record'), AppView.year),
      (LucideIcons.library, p.goldSoft, p.goldInk, context.tr('کتابخونه', 'Library'), AppView.library),
      (LucideIcons.wallet, p.okSoft, p.okInk, context.tr('خریدها', 'Purchases'), AppView.purchases),
      (LucideIcons.notebookPen, p.hpSoft, p.hpInk, context.tr('یادداشت', 'Journal'), AppView.journal),
      (LucideIcons.squareCheck, p.primarySoft, p.primary, context.tr('لیست کارها', 'To-Do'), AppView.todo),
      (LucideIcons.timer, p.xpSoft, p.xpInk, context.tr('پومودورو', 'Pomodoro'), AppView.pomodoro),
      (LucideIcons.trophy, p.goldSoft, p.goldInk, context.tr('چالش‌ها', 'Challenges'), null),
      (LucideIcons.zap, p.hpSoft, p.hpInk, context.tr('لحظه‌ی وسوسه', 'Urge Moment'), null),
      (LucideIcons.chartColumn, p.blueSoft, p.blueInk, context.tr('تحلیل', 'Analytics'), AppView.habits),
      (LucideIcons.settings, p.okSoft, p.okInk, context.tr('تنظیمات', 'Settings'), AppView.settings),
    ];
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: RpShadow.e3(context.rpBrightness),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(9)))),
          const SizedBox(height: 14),
          Text(context.tr('انتخاب صفحه', 'Choose a Tab'), style: rpText(RpType.title, weight: 800, color: p.text)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .98,
            children: [
              for (final (icon, bg, fg, label, view) in items)
                InkWell(
                  borderRadius: BorderRadius.circular(RpRadius.lg),
                  onTap: () {
                    Navigator.pop(context);
                    if (view != null) nav.go(view);
                  },
                  child: Ink(
                    decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(RpRadius.lg), border: Border.all(color: p.line)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                        child: Icon(icon, size: 24, color: fg),
                      ),
                      const SizedBox(height: 9),
                      Text(label, textAlign: TextAlign.center, style: rpText(RpType.label, weight: 700, color: p.text, height: 1.35)),
                    ]),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}
