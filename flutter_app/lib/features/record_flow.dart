// جریانِ ثبت: «چرا؟» (دلیل) ← ثبتِ رکورد ← پنجره‌ی پاداش/تنبیه. دقیقاً ترتیبِ نسخه‌ی HTML:
//   دلیل ذخیره می‌شود، سپس رکورد؛ «رد شدن» فقط رکورد؛ «انصراف» هیچ. دوباره‌زدنِ دکمه‌ی فعال بی‌پرسش برمی‌دارد.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/i18n.dart';
import '../data/actions.dart';
import '../data/urge_ops.dart';
import '../ui/tokens.dart';

Future<void> recordBinaryFlow(BuildContext context, String hid, String iso, String v, {required bool alreadyActive}) async {
  final a = context.read<AppActions>();
  if (alreadyActive) return a.setBinary(iso, hid, v);
  await _withReason(context, hid, iso, v, () => a.setBinary(iso, hid, v));
}

/// val == null ← پاک‌کردنِ رکورد (بی‌پرسش)
Future<void> recordValueFlow(BuildContext context, String hid, String iso, num? val) async {
  final a = context.read<AppActions>();
  if (val == null) return a.clear(iso, hid);
  final h = (a.store.state['habits'] as List).cast<Map>().where((x) => x['id'] == hid).firstOrNull;
  final direction = h?['direction'] ?? 'more';
  final target = h == null ? 1 : (h['type'] == 'numeric' ? h['numericTarget'] : h['timerTarget']);
  final t = target is num ? target : 0;
  final status = direction == 'less' ? (val <= t ? 'success' : 'fail') : (val >= t ? 'success' : 'fail');
  await _withReason(context, hid, iso, status, () => a.setValue(iso, hid, val));
}

Future<void> _withReason(BuildContext context, String hid, String iso, String status, VoidCallback apply) async {
  final a = context.read<AppActions>();
  final r = await showReasonDialog(context, hid, status);
  if (r == null) return; // انصراف
  if (r.isNotEmpty) a.saveReason(hid, iso, status, r);
  apply();
  if (context.mounted) await showRewardPunish(context, hid, status);
}

/// برمی‌گرداند: متنِ دلیل، '' برای «رد شدن»، null برای «انصراف»
Future<String?> showReasonDialog(BuildContext context, String hid, String status) {
  final a = context.read<AppActions>();
  final prev = a.previousReasons(hid, status);
  final habit = (a.store.state['habits'] as List).cast<Map>().where((x) => x['id'] == hid).firstOrNull;
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      final p = ctx.rp;
      return StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: p.surface,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ctx.tr('چرا؟', 'Why?'), style: rpText(RpType.title, weight: 800, color: p.text)),
            Text('${habit?['name'] ?? '—'}', style: rpText(RpType.label, weight: 600, color: p.muted)),
            Text(status == 'success' ? ctx.tr('✅ موفق', '✅ Success') : ctx.tr('❌ ناموفق', '❌ Failed'), style: rpText(RpType.label, weight: 800, color: status == 'success' ? p.okInk : p.badInk)),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (prev.isEmpty)
                Text(ctx.tr('هنوز دلیلی ثبت نشده', 'No previous reasons'), style: rpText(RpType.label, weight: 500, color: p.muted))
              else
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final r in prev)
                    ActionChip(
                      label: Text(r.length > 30 ? '${r.substring(0, 30)}…' : r),
                      tooltip: r,
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (c2) => AlertDialog(
                            title: Text(ctx.tr('آیا می‌خواهید همین دلیل را ثبت کنید؟', 'Do you want to use this reason?')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c2, false), child: Text(ctx.tr('نه، ویرایش', 'No, edit'))),
                              FilledButton(onPressed: () => Navigator.pop(c2, true), child: Text(ctx.tr('بله', 'Yes'))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          if (ctx.mounted) Navigator.pop(ctx, r);
                        } else {
                          setS(() => c.text = r);
                        }
                      },
                    ),
                ]),
              const SizedBox(height: 12),
              TextField(controller: c, maxLines: 3, decoration: InputDecoration(hintText: ctx.tr('دلیل…', 'Reason…'))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('انصراف', 'Cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, ''), child: Text(ctx.tr('رد شدن', 'Skip'))),
            FilledButton(
              onPressed: () {
                final t = c.text.trim();
                if (t.isEmpty) {
                  a.toasts.show(ctx.tr('لطفاً دلیل را بنویس یا از دکمه رد شدن استفاده کن.', 'Please write a reason or use Skip.'), ms: 2500);
                  return;
                }
                Navigator.pop(ctx, t);
              },
              child: Text(ctx.tr('ثبت', 'Save')),
            ),
          ],
        );
      });
    },
  );
}

Future<void> showRewardPunish(BuildContext context, String hid, String status) {
  final rp = context.read<AppActions>().rewardPunish(hid, status);
  if (rp == null) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final p = ctx.rp;
      return AlertDialog(
        backgroundColor: p.surface,
        title: Text(rp.$1, style: rpText(RpType.title, weight: 800, color: p.text)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rp.$2, style: rpText(RpType.label, weight: 600, color: p.muted)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: status == 'success' ? p.okSoft : p.badSoft, borderRadius: BorderRadius.circular(RpRadius.md)),
            child: Text(rp.$3, style: rpText(RpType.body, weight: 600, color: p.text, height: 1.8)),
          ),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('باشه', 'OK')))],
      );
    },
  );
}
