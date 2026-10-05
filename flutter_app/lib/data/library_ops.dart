// کتابخانه: سطح کتابخوان، ثبت صفحه، افزودن/ویرایش/حذف کتاب (قواعدِ نسخه‌ی HTML).
import 'dart:math';

import '../core/calendar.dart';
import 'actions.dart';
import 'media_store.dart';
import 'habit_ops.dart' show newHabitId;

const int freeBookLimit = 3;

int libraryLevelNum(int completed) => min(completed ~/ 5 + 1, 21);
int libraryBooksToNext(int completed) {
  final n = libraryLevelNum(completed);
  return n >= 21 ? 0 : n * 5 - completed;
}

double libraryLevelPct(int completed) => libraryLevelNum(completed) >= 21 ? 100 : (completed % 5) / 5 * 100;

double bookProgressPct(Map b) {
  final t = b['totalPages'];
  if (t is! num || t <= 0) return 0;
  final r = (b['pagesRead'] as num?) ?? 0;
  return (r / t * 100).clamp(0, 100).toDouble();
}

typedef LogResult = ({bool ok, bool justCompleted, int pct});

extension LibraryOps on AppActions {
  List<Map> get books {
    final s = store.state;
    if (s['books'] is! List) s['books'] = [];
    return (s['books'] as List).cast<Map>();
  }

  int get completedBooks => books.where((b) => b['completed'] == true).length;
  bool get canAddBook => store.state['isPremium'] == true || books.where((b) => b['completed'] != true).length < freeBookLimit;

  /// برمی‌گرداند: null = موفق، وگرنه کلیدِ خطا ('title' | 'pages')
  String? saveBook({String? editingId, String? newId, required String title, required String author, required String summary, required int? totalPages, required String reward}) {
    final t = title.trim();
    if (t.isEmpty) return 'title';
    if (totalPages == null || totalPages <= 0) return 'pages';
    if (editingId != null) {
      final b = books.where((x) => x['id'] == editingId).firstOrNull;
      if (b != null) {
        b['title'] = t;
        b['author'] = author.trim();
        b['summary'] = summary.trim();
        b['totalPages'] = totalPages;
        b['reward'] = reward.trim();
        if (((b['pagesRead'] as num?) ?? 0) >= totalPages) {
          b['pagesRead'] = totalPages;
          b['completed'] = true;
        } else {
          b['completed'] = false;
        }
      }
    } else {
      books.add({
        'id': newId ?? newHabitId(),
        'title': t,
        'author': author.trim(),
        'summary': summary.trim(),
        'totalPages': totalPages,
        'reward': reward.trim(),
        'pagesRead': 0,
        'completed': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'completedAt': null,
        'history': <Map>[],
      });
    }
    store.save();
    return null;
  }

  void deleteBook(String id) {
    store.state['books'] = books.where((b) => b['id'] != id).toList();
    media?.deleteAllPhotos(PhotoKind.book, id);
    media?.deleteAllVoices(id);
    store.save();
  }

  /// `totalSoFar` (مجموعِ خوانده‌شده) بر `justRead` (امروز چند صفحه) اولویت دارد — مثل HTML
  LogResult logPages(String id, {int? justRead, int? totalSoFar}) {
    final b = books.where((x) => x['id'] == id).firstOrNull;
    if (b == null) return (ok: false, justCompleted: false, pct: 0);
    final read = ((b['pagesRead'] as num?) ?? 0).toInt();
    int newTotal;
    int delta;
    if (totalSoFar != null && totalSoFar >= 0) {
      newTotal = totalSoFar;
      delta = totalSoFar - read;
    } else if (justRead != null && justRead > 0) {
      newTotal = read + justRead;
      delta = justRead;
    } else {
      return (ok: false, justCompleted: false, pct: 0);
    }
    final total = (b['totalPages'] as num).toInt();
    if (newTotal > total) newTotal = total;
    if (newTotal < 0) newTotal = 0;
    b['pagesRead'] = newTotal;
    final now = clock();
    final fa = store.state['lang'] != 'en';
    String label;
    if (fa) {
      final j = toJalaali(now.year, now.month, now.day);
      label = toPersianDigits('${j.jy}/${j.jm}/${j.jd}');
    } else {
      label = '${now.month}/${now.day}/${now.year}';
    }
    (b['history'] is List ? b['history'] as List : (b['history'] = <Map>[])).add({'date': now.millisecondsSinceEpoch, 'dateLabel': label, 'pagesRead': newTotal, 'delta': delta});
    final was = b['completed'] == true;
    final nowDone = newTotal >= total;
    b['completed'] = nowDone;
    store.save();
    var just = false;
    if (nowDone && !was) {
      b['completedAt'] = now.millisecondsSinceEpoch;
      store.save();
      just = true;
    }
    afterChange();
    return (ok: true, justCompleted: just, pct: bookProgressPct(b).round());
  }
}
