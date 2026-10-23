// پوسته: صفحه‌ی فعلی + نوار ناوبری شناور + منوی + (Action Grid) + Back اندروید.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/actions.dart';
import '../data/challenge_ops.dart';
import '../data/notifier.dart';
import '../data/reminder_tick.dart';
import '../features/challenges/challenges_sheet.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/onboarding/onboarding.dart';
import '../features/urge/urge_sheet.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/analytics/smart_screen.dart';
import '../features/calendar/calendar_screens.dart';
import '../features/habits/habits_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/progress/badges_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/progress/reveal.dart';
import '../features/rating/rate_prompt.dart';
import '../features/library/library_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import '../features/purchases/purchases_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/todo/todo_screen.dart';
import '../ui/tokens.dart';
import 'i18n.dart';
import 'nav.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Timer? _chTimer;
  Timer? _remTimer;
  final List<String> _checkins = [];
  bool _checkinOpen = false;

  void _tickChallenges() {
    final a = context.read<AppActions>();
    _checkins.addAll(a.checkChallengeDeadlines());
    _nextCheckin();
  }

  Future<void> _nextCheckin() async {
    if (_checkinOpen || _checkins.isEmpty || !mounted) return;
    final a = context.read<AppActions>();
    final id = _checkins.first;
    final c = a.challenges.where((x) => x['id'] == id).firstOrNull;
    if (c == null || c['status'] != 'pending_review') {
      _checkins.removeAt(0);
      return _nextCheckin();
    }
    _checkinOpen = true;
    await showChallengeCheckin(context, c);
    _checkins.remove(id);
    _checkinOpen = false;
    if (mounted) Future.delayed(const Duration(milliseconds: 500), _nextCheckin);
  }

  bool _revealing = false;
  Future<void> _reveal() async {
    if (_revealing || !mounted) return;
    _revealing = true;
    try {
      await showPendingReveals(context);
    } finally {
      _revealing = false;
    }
  }

  void _onProgress() {
    if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void dispose() {
    try { context.read<AppActions>().progressTick.removeListener(_onProgress); } catch (_) {}
    _chTimer?.cancel();
    _remTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tickChallenges();
      final texts = context.read<AppTexts?>();
      if (texts != null) runFirstRunFlow(context, texts);
    });
    final acts = context.read<AppActions>();
    acts.progressTick.addListener(_onProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    _chTimer = Timer.periodic(const Duration(seconds: 20), (_) => _tickChallenges());
    _remTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<AppActions>().reminderTick(notifier: context.read<Notifier?>());
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    return PopScope(
      canPop: false, // Back اندروید را خودمان با همان ترتیبِ نسخه‌ی HTML مدیریت می‌کنیم
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!nav.handleBack()) askReviewOrExit(context);
      },
      child: Scaffold(
        // نوار ناوبری محتوا را نمی‌پوشاند: بدنه بالای آن تمام می‌شود و آخرِ هر صفحه همیشه دیده می‌شود
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
        // نوار ناوبری اندازه‌ی ثابت دارد؛ با «فونت بزرگ» فقط متنِ صفحه‌ها بزرگ می‌شود (وگرنه سرریز می‌کرد)
        bottomNavigationBar: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.0, child: const GlassNav()),
      ),
    );
  }

  Widget _page(AppView v) => switch (v) {
        AppView.dashboard => const DashboardScreen(),
        AppView.habits => const HabitsScreen(),
        AppView.purchases => const PurchasesScreen(),
        AppView.todo => const TodoScreen(),
        AppView.journal => const JournalScreen(),
        AppView.library => const LibraryScreen(),
        AppView.pomodoro => const PomodoroScreen(),
        AppView.settings => const SettingsScreen(),
        AppView.analytics => const AnalyticsScreen(),
        AppView.smart => const SmartScreen(),
        AppView.progress => const ProgressScreen(),
        AppView.badges => const BadgesScreen(),
        AppView.month => const MonthScreen(),
        AppView.year => const YearScreen(),
      };
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
  final root = context;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x85060E0D),
    builder: (_) => _ActionGridSheet(rootContext: root),
  );
}

class _ActionGridSheet extends StatelessWidget {
  final BuildContext rootContext;
  const _ActionGridSheet({required this.rootContext});

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
      (LucideIcons.trendingUp, p.primarySoft, p.primary, context.tr('پیشرفت', 'Progress'), AppView.progress),
      (LucideIcons.award, p.goldSoft, p.goldInk, context.tr('نشان‌های من', 'My Badges'), AppView.badges),
      (LucideIcons.brain, p.xpSoft, p.xpInk, context.tr('تحلیل هوشمند', 'Smart Analysis'), AppView.smart),
      (LucideIcons.chartColumn, p.blueSoft, p.blueInk, context.tr('تحلیل', 'Analytics'), AppView.analytics),
      (LucideIcons.settings, p.okSoft, p.okInk, context.tr('تنظیمات', 'Settings'), AppView.settings),
    ];
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(RpRadius.lg)),
          boxShadow: RpShadow.e3(context.rpBrightness),
        ),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    if (view != null) {
                      nav.go(view);
                    } else if (label == context.tr('چالش‌ها', 'Challenges')) {
                      showChallenges(rootContext);
                    } else if (label == context.tr('لحظه‌ی وسوسه', 'Urge Moment')) {
                      showUrge(rootContext);
                    }
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
        ])),
      ),
    );
  }
}
