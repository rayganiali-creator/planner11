// کتابخانه: سطح کتابخوان، آمار، فیلتر/جست‌وجو، کارتِ کتاب، ثبت صفحه، ویرایش، حذف، تاریخچه، یادآوری.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/i18n.dart';
import '../../data/actions.dart';
import '../../data/app_store.dart';
import '../../data/library_ops.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../../data/media_store.dart';
import '../journal/journal_screen.dart' show fmtDateTime, showReminderPicker;
import '../media/media_widgets.dart';
import '../../data/habit_ops.dart' show newHabitId;

String libraryLevelLabel(int completed, bool fa) {
  final n = libraryLevelNum(completed);
  if (n >= 21) return fa ? 'سطح ۲۱ - کتابخوان اعظم 👑' : 'Level 21 - The Ultimate Reader 👑';
  return fa ? 'سطح ${toFa(n)}' : 'Level $n';
}

String toFa(Object v) => '$v'.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String filter = 'all';
  final search = TextEditingController();
  final open = <String>{};

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    final a = context.read<AppActions>();
    final p = context.rp;
    final fa = context.isFa;
    final all = a.books;
    final completed = a.completedBooks;
    final inProgress = all.where((b) => b['completed'] != true && ((b['pagesRead'] as num?) ?? 0) > 0).length;
    final pages = all.fold<num>(0, (s, b) => s + ((b['pagesRead'] as num?) ?? 0));
    final toNext = libraryBooksToNext(completed);
    final q = search.text.trim().toLowerCase();
    var list = all.where((b) {
      final done = b['completed'] == true;
      if (filter == 'progress' && (done || !(((b['pagesRead'] as num?) ?? 0) > 0))) return false;
      if (filter == 'done' && !done) return false;
      if (q.isNotEmpty && !('${b['title'] ?? ''} ${b['author'] ?? ''}'.toLowerCase().contains(q))) return false;
      return true;
    }).toList()
      ..sort((x, y) {
        final xd = x['completed'] == true, yd = y['completed'] == true;
        if (xd != yd) return xd ? 1 : -1;
        return ((y['createdAt'] as num?) ?? 0).compareTo((x['createdAt'] as num?) ?? 0);
      });
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return Stack(children: [
      ListView(
        padding: EdgeInsets.fromLTRB(RpSpace.s4, RpSpace.s3, RpSpace.s4, rpBottomPad(context)),
        children: [
          Text(context.tr('کتابخانه', 'Library'), style: rpText(RpType.titleL, weight: 800, color: p.text)),
          const SizedBox(height: RpSpace.s3),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 22, backgroundColor: p.goldSoft, child: Text(context.n(libraryLevelNum(completed)), style: rpText(RpType.bodyL, weight: 800, color: p.goldInk))),
                const SizedBox(width: RpSpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(libraryLevelLabel(completed, fa), style: rpText(RpType.bodyL, weight: 800, color: p.text)),
                    Text(
                      toNext > 0 ? context.tr('${context.n(toNext)} کتاب دیگر تا سطح بعد', '$toNext more book(s) to next level') : context.tr('به بالاترین سطح رسیدی! 👑', 'You reached the top level! 👑'),
                      style: rpText(RpType.label, weight: 500, color: p.muted),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: RpSpace.s3),
              RpProgressBar(value: libraryLevelPct(completed) / 100, colors: [p.gold, p.goldSoft]),
            ]),
          ),
          const SizedBox(height: RpSpace.s3),
          Row(children: [
            _Stat(context.n(all.length), context.tr('کل', 'Total'), p.blueInk, p.blueSoft),
            const SizedBox(width: 8),
            _Stat(context.n(completed), context.tr('تمام‌شده', 'Done'), p.okInk, p.okSoft),
            const SizedBox(width: 8),
            _Stat(context.n(inProgress), context.tr('در حال خواندن', 'Reading'), p.goldInk, p.goldSoft),
            const SizedBox(width: 8),
            _Stat(context.n(pages), context.tr('صفحه', 'Pages'), p.xpInk, p.xpSoft),
          ]),
          const SizedBox(height: RpSpace.s3),
          TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(LucideIcons.search, size: 18), hintText: context.tr('جست‌وجو در کتاب‌ها', 'Search books'))),
          const SizedBox(height: RpSpace.s2),
          Wrap(spacing: 8, children: [
            for (final f in const [('all', 'همه', 'All'), ('progress', 'در حال خواندن', 'Reading'), ('done', 'تمام‌شده', 'Completed')])
              ChoiceChip(label: Text(fa ? f.$2 : f.$3), selected: filter == f.$1, onSelected: (_) => setState(() => filter = f.$1)),
          ]),
          const SizedBox(height: RpSpace.s3),
          if (list.isEmpty)
            AppCard(child: Text(context.tr('هنوز کتابی ثبت نشده. یک کتاب جدید اضافه کن! 📚', 'No books yet. Add your first book! 📚'), style: rpText(RpType.body, weight: 500, color: p.muted)))
          else
            for (final b in list) _BookCard(book: b, nowMs: nowMs, open: open.contains(b['id']), onToggleHistory: () => setState(() => open.contains(b['id']) ? open.remove(b['id']) : open.add(b['id'] as String))),
        ],
      ),
      Positioned(
        left: RpSpace.s4, right: RpSpace.s4, bottom: 104,
        child: RpButton(context.tr('افزودن کتاب', 'Add book'), icon: LucideIcons.plus, onTap: () {
          if (!a.canAddBook) {
            a.toasts.show(context.tr('⭐ در نسخه‌ی رایگان حداکثر ۳ کتاب در حال مطالعه می‌توانید داشته باشید. با تمام کردن یک کتاب جا باز می‌شود، یا پرو را تهیه کنید.', '⭐ The free plan allows 3 books in progress. Finish one to free a slot, or get Pro.'), ms: 3400);
            return;
          }
          _bookEditor(context, null);
        }),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String v, label;
  final Color fg, bg;
  const _Stat(this.v, this.label, this.fg, this.bg);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: RpSpace.s3, horizontal: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(RpRadius.md)),
          child: Column(children: [
            Text(v, style: rpText(RpType.bodyL, weight: 800, color: fg)),
            Text(label, textAlign: TextAlign.center, style: rpText(RpType.caption, weight: 600, color: context.rp.muted)),
          ]),
        ),
      );
}

class _BookCard extends StatelessWidget {
  final Map book;
  final int nowMs;
  final bool open;
  final VoidCallback onToggleHistory;
  const _BookCard({required this.book, required this.nowMs, required this.open, required this.onToggleHistory});
  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final a = context.read<AppActions>();
    final fa = context.isFa;
    final b = book;
    final done = b['completed'] == true;
    final pct = bookProgressPct(b);
    final hist = ((b['history'] as List?) ?? const []).cast<Map>().reversed.take(6).toList();
    final remindAt = (b['remindAt'] as num?)?.toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: RpSpace.s3),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b['title']}', style: rpText(RpType.bodyL, weight: 800, color: p.text)),
                if ('${b['author'] ?? ''}'.isNotEmpty) Text('${b['author']}', style: rpText(RpType.label, weight: 500, color: p.muted)),
              ]),
            ),
            RpChip(done ? context.tr('✅ تمام‌شده', '✅ Completed') : context.tr('📖 در حال خواندن', '📖 Reading'), tone: done ? ChipTone.ok : ChipTone.primary),
          ]),
          Padding(padding: const EdgeInsets.only(top: 8), child: PhotoStrip(kind: PhotoKind.book, ownerId: '${b['id']}', editable: false, placeholder: true)),
          if ('${b['summary'] ?? ''}'.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text('${b['summary']}', style: rpText(RpType.body, weight: 500, color: p.muted, height: 1.8))),
          const SizedBox(height: RpSpace.s3),
          Row(children: [
            Expanded(child: Text(context.tr('${context.n(b['pagesRead'] ?? 0)} از ${context.n(b['totalPages'] ?? 0)} صفحه', '${b['pagesRead'] ?? 0} of ${b['totalPages'] ?? 0} pages'), style: rpText(RpType.label, weight: 600, color: p.muted))),
            Text(context.n('${pct.round()}${fa ? '٪' : '%'}'), style: rpText(RpType.label, weight: 800, color: p.text)),
          ]),
          const SizedBox(height: 6),
          RpProgressBar(value: pct / 100, colors: [p.primary, p.primary2]),
          if ('${b['reward'] ?? ''}'.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('🎁 ${context.tr('پاداش: ', 'Reward: ')}${b['reward']}', style: rpText(RpType.label, weight: 600, color: done ? p.okInk : p.goldInk))),
          const SizedBox(height: RpSpace.s2),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (!done) OutlinedButton(onPressed: () => _logPages(context, b), child: Text(context.tr('📖 ثبت صفحه', '📖 Log Pages'))),
            OutlinedButton(onPressed: onToggleHistory, child: Text(context.tr('🕒 تاریخچه', '🕒 History'))),
            OutlinedButton(
              onPressed: () => showReminderPicker(context, 'book', b),
              child: Text('⏰ ${remindAt != null && remindAt > nowMs ? fmtDateTime(remindAt, fa) : context.tr('یادآوری', 'Reminder')}'),
            ),
            OutlinedButton(onPressed: () => _bookEditor(context, b), child: Text(context.tr('✏️ ویرایش', '✏️ Edit'))),
            OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(context.tr('این کتاب حذف شود؟', 'Delete this book?')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('انصراف', 'Cancel'))),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.tr('حذف', 'Delete'))),
                    ],
                  ),
                );
                if (ok == true) a.deleteBook(b['id'] as String);
              },
              child: Text(context.tr('🗑 حذف', '🗑 Delete')),
            ),
          ]),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: hist.isEmpty
                  ? Text(context.tr('هنوز ثبتی نشده', 'No entries yet'), style: rpText(RpType.label, weight: 500, color: p.muted))
                  : Column(children: [
                      for (final h in hist)
                        Row(children: [
                          Expanded(child: Text('${h['dateLabel'] ?? ''}', style: rpText(RpType.label, weight: 500, color: p.muted))),
                          Text(context.tr('صفحه ${context.n(h['pagesRead'])}', 'page ${h['pagesRead']}'), style: rpText(RpType.label, weight: 700, color: p.text)),
                        ]),
                    ]),
            ),
        ]),
      ),
    );
  }
}

void _logPages(BuildContext context, Map b) {
  final a = context.read<AppActions>();
  final just = TextEditingController(), total = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${b['title']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: just, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: ctx.tr('چند صفحه خواندی؟', 'Pages just read'))),
        TextField(controller: total, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: ctx.tr('یا: تا کدام صفحه رسیدی؟', 'Or: current page'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('انصراف', 'Cancel'))),
        FilledButton(
          onPressed: () {
            final r = a.logPages(b['id'] as String, justRead: int.tryParse(just.text.trim()), totalSoFar: int.tryParse(total.text.trim()));
            if (!r.ok) {
              a.toasts.show(ctx.tr('⚠️ تعداد صفحه را وارد کن', '⚠️ Please enter a page count'));
              return;
            }
            Navigator.pop(ctx);
            if (r.justCompleted) {
              _bookComplete(context, b);
            } else {
              a.toasts.show(ctx.tr('📖 ${ctx.n(r.pct)}٪ خوانده شد!', '📖 ${r.pct}% read!'));
            }
          },
          child: Text(ctx.tr('ثبت', 'Save')),
        ),
      ],
    ),
  );
}

void _bookComplete(BuildContext context, Map b) {
  final a = context.read<AppActions>();
  final after = a.completedBooks, before = after - 1;
  final up = libraryLevelNum(after) > libraryLevelNum(before);
  final fa = context.isFa;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Column(children: [const Text('🎉', style: TextStyle(fontSize: 40)), Text('${b['title']}')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${b['reward']}'.isNotEmpty ? '🎁 ${b['reward']}' : ctx.tr('برای خودت پاداشی در نظر نگرفته بودی، ولی همین که تمومش کردی یک موفقیت بزرگه!', "You didn't set a reward, but finishing it is a big win on its own!"), textAlign: TextAlign.center),
        if (up) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${fa ? '🎊 سطحت رفت بالا: ' : '🎊 Level up: '}${libraryLevelLabel(after, fa)}', textAlign: TextAlign.center)),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('عالی!', 'Great!')))],
    ),
  );
}

void _bookEditor(BuildContext context, Map? b) {
  final a = context.read<AppActions>();
  // کتابِ جدید: شناسه از همین حالا ساخته می‌شود تا قبل از ثبتِ نهایی هم بشود عکس/صدا اضافه کرد (مثل HTML)
  final draftId = b == null ? newHabitId() : null;
  var saved = false;
  final title = TextEditingController(text: '${b?['title'] ?? ''}');
  final author = TextEditingController(text: '${b?['author'] ?? ''}');
  final summary = TextEditingController(text: '${b?['summary'] ?? ''}');
  final pages = TextEditingController(text: b?['totalPages'] != null ? '${b!['totalPages']}' : '');
  final reward = TextEditingController(text: '${b?['reward'] ?? ''}');
  final mediaStore = context.read<MediaStore>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.rp.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RpRadius.xl))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(RpSpace.s4), children: [
        Text(b == null ? ctx.tr('📚 افزودن کتاب', '📚 Add Book') : ctx.tr('✏️ ویرایش کتاب', '✏️ Edit Book'), style: rpText(RpType.title, weight: 800, color: ctx.rp.text)),
        TextField(controller: title, decoration: InputDecoration(labelText: ctx.tr('نام کتاب', 'Title'))),
        TextField(controller: author, decoration: InputDecoration(labelText: ctx.tr('نویسنده', 'Author'))),
        TextField(controller: summary, maxLines: 3, decoration: InputDecoration(labelText: ctx.tr('خلاصه', 'Summary'))),
        TextField(controller: pages, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: ctx.tr('تعداد صفحات', 'Total pages'))),
        TextField(controller: reward, decoration: InputDecoration(labelText: ctx.tr('پاداش پس از اتمام', 'Reward on completion'))),
        const SizedBox(height: 12),
        PhotoStrip(kind: PhotoKind.book, ownerId: (b?['id'] ?? draftId) as String),
        const SizedBox(height: 8),
        VoiceList(bookId: (b?['id'] ?? draftId) as String),
        const SizedBox(height: RpSpace.s4),
        Row(children: [
          Expanded(child: RpButton(ctx.tr('انصراف', 'Cancel'), kind: BtnKind.ghost, onTap: () => Navigator.pop(ctx))),
          const SizedBox(width: RpSpace.s3),
          Expanded(
            child: RpButton(ctx.tr('ذخیره', 'Save'), onTap: () {
              final err = a.saveBook(editingId: b?['id'] as String?, newId: draftId, title: title.text, author: author.text, summary: summary.text, totalPages: int.tryParse(pages.text.trim()), reward: reward.text);
              if (err == 'title') return a.toasts.show(ctx.tr('⚠️ نام کتاب را وارد کن', '⚠️ Please enter the book title'));
              if (err == 'pages') return a.toasts.show(ctx.tr('⚠️ تعداد صفحات معتبر وارد کن', '⚠️ Please enter a valid page count'));
              saved = true;
              Navigator.pop(ctx);
              a.toasts.show(ctx.tr('✅ کتاب ثبت شد', '✅ Book saved'));
            }),
          ),
        ]),
      ]),
    ),
  ).then((_) {
    // انصراف بدون ثبت: عکس/صدای یتیمِ همان پیش‌نویس پاک می‌شود
    if (draftId != null && !saved) {
      mediaStore.deleteAllPhotos(PhotoKind.book, draftId);
      mediaStore.deleteAllVoices(draftId);
    }
  });
}
