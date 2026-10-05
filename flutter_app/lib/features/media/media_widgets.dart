// عکس (عادت/کتاب) و یادداشت صوتی (کتاب، پرو). عکس‌ها مثل HTML: حداکثر ۱۲۸۰ پیکسل، JPEG با کیفیت ۷۲.
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../core/pro_features.dart';
import '../../ui/pro_widgets.dart';
import '../../app/i18n.dart';
import '../../data/actions.dart';
import '../../data/media_store.dart';
import '../../ui/tokens.dart';

Future<void> showPhotoLightbox(BuildContext context, Photo p) => showDialog<void>(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Dialog.fullscreen(
          backgroundColor: Colors.black87,
          child: Center(child: InteractiveViewer(child: Image.memory(p.bytes))),
        ),
      ),
    );

/// نوارِ عکس‌ها. editable=false ← فقط نمایش (کارتِ کتاب)
class PhotoStrip extends StatefulWidget {
  final PhotoKind kind;
  final String ownerId;
  final bool editable;
  final bool placeholder; // کتاب بدون عکس: 📕
  const PhotoStrip({super.key, required this.kind, required this.ownerId, this.editable = true, this.placeholder = false});
  @override
  State<PhotoStrip> createState() => _PhotoStripState();
}

class _PhotoStripState extends State<PhotoStrip> {
  List<Photo> photos = [];
  int loading = 0;
  MediaStore get media => context.read<MediaStore>();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final l = await media.photos(widget.kind, widget.ownerId);
    if (mounted) setState(() => photos = l);
  }

  Future<void> _add() async {
    final picker = ImagePicker();
    List<XFile> files;
    try {
      files = await picker.pickMultiImage(maxWidth: 1280, maxHeight: 1280, imageQuality: 72);
    } catch (_) {
      return;
    }
    if (files.isEmpty) return;
    setState(() => loading += files.length);
    for (final f in files) {
      try {
        final bytes = await f.readAsBytes();
        final mime = f.mimeType ?? 'image/jpeg';
        await media.addPhoto(widget.kind, widget.ownerId, 'data:$mime;base64,${_b64(bytes)}');
      } catch (_) {}
      if (mounted) setState(() => loading--);
    }
    await _reload();
  }

  static String _b64(List<int> b) => Uri.dataFromBytes(b).toString().split(',').last;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    if (!widget.editable && photos.isEmpty) {
      return widget.placeholder ? Container(width: 56, height: 56, margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(RpRadius.sm)), child: const Center(child: Text('📕', style: TextStyle(fontSize: 26)))) : const SizedBox.shrink();
    }
    return SizedBox(
      height: 64,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final ph in photos)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Stack(children: [
              GestureDetector(
                onTap: () => showPhotoLightbox(context, ph),
                child: ClipRRect(borderRadius: BorderRadius.circular(RpRadius.sm), child: Image.memory(ph.bytes, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 192)),
              ),
              if (widget.editable)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: GestureDetector(
                    onTap: () async {
                      await media.deletePhoto(widget.kind, widget.ownerId, ph.id);
                      _reload();
                    },
                    child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
                  ),
                ),
            ]),
          ),
        for (int i = 0; i < loading; i++) Container(width: 64, height: 64, margin: const EdgeInsetsDirectional.only(end: 8), decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(RpRadius.sm)), child: const Center(child: Text('⏳'))),
        if (widget.editable)
          GestureDetector(
            onTap: _add,
            child: Container(width: 64, height: 64, decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(RpRadius.sm), border: Border.all(color: p.line)), child: Icon(LucideIcons.imagePlus, color: p.muted)),
          ),
      ]),
    );
  }
}

/// یادداشت‌های صوتیِ یک کتاب: ضبط (پرو، حداکثر ۵ دقیقه)، پخش، حذف
class VoiceList extends StatefulWidget {
  final String bookId;
  const VoiceList({super.key, required this.bookId});
  @override
  State<VoiceList> createState() => _VoiceListState();
}

class _VoiceListState extends State<VoiceList> {
  List<Voice> voices = [];
  final rec = AudioRecorder();
  final player = AudioPlayer();
  bool recording = false;
  DateTime? started;
  Timer? _cap;
  String? playing;

  MediaStore get media => context.read<MediaStore>();

  @override
  void initState() {
    super.initState();
    _reload();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = null);
    });
  }

  @override
  void dispose() {
    _cap?.cancel();
    rec.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final l = await media.voices(widget.bookId);
    if (mounted) setState(() => voices = l);
  }

  Future<void> _toggleRecord() async {
    final a = context.read<AppActions>();
    final fa = a.store.state['lang'] != 'en';
    if (a.store.state['isPremium'] != true) {
      showProBlocked(context, ProFeature.voiceNotes);
      return;
    }
    if (recording) return _stop();
    try {
      if (!await rec.hasPermission()) {
        a.toasts.show(fa ? 'اجازه‌ی میکروفون داده نشد. تنظیمات اندروید ← برنامه‌ها ← روتین پلنر ← مجوزها ← میکروفون را روشن کنید.' : 'Microphone permission denied. Turn it on in Android Settings → Apps → Routine Planner → Permissions → Microphone.', ms: 4500);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await rec.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      started = DateTime.now();
      setState(() => recording = true);
      _cap = Timer(const Duration(minutes: 5), _stop); // حداکثر ۵ دقیقه
    } catch (e) {
      a.toasts.show(fa ? 'ضبط صدا شروع نشد' : 'Recording could not start', ms: 4500);
    }
  }

  Future<void> _stop() async {
    _cap?.cancel();
    final path = await rec.stop();
    final ms = started == null ? 0 : DateTime.now().difference(started!).inMilliseconds;
    if (mounted) setState(() => recording = false);
    if (path == null) return;
    final f = File(path);
    if (!f.existsSync()) return;
    await media.putVoice(widget.bookId, bytes: f.readAsBytesSync(), type: 'audio/mp4', at: DateTime.now().millisecondsSinceEpoch, ms: ms);
    f.deleteSync();
    _reload();
  }

  Future<void> _play(Voice v) async {
    if (playing == v.id) {
      await player.stop();
      setState(() => playing = null);
      return;
    }
    // فایل‌های ضبط‌شده در نسخه‌ی HTML webm/opus هستند؛ پخش‌کننده‌ی اندروید آن‌ها را می‌خواند
    final dir = await getTemporaryDirectory();
    final ext = v.type.contains('webm') ? 'webm' : v.type.contains('ogg') ? 'ogg' : v.type.contains('mp4') || v.type.contains('aac') ? 'm4a' : 'bin';
    final f = File('${dir.path}/play_${v.id}.$ext')..writeAsBytesSync(v.bytes);
    await player.play(DeviceFileSource(f.path));
    if (mounted) setState(() => playing = v.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    String dur(int ms) {
      final s = ms ~/ 1000;
      return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(context.tr('یادداشت صوتی', 'Voice notes'), style: rpText(RpType.label, weight: 700, color: p.muted))),
        OutlinedButton.icon(
          onPressed: _toggleRecord,
          icon: Icon(recording ? LucideIcons.square : LucideIcons.mic, size: 16, color: recording ? p.badInk : null),
          label: Text(recording ? context.tr('⏹ پایان ضبط', '⏹ Stop recording') : context.tr('🎙️ ضبط یادداشت صوتی', '🎙️ Record a voice note')),
        ),
      ]),
      if (voices.isEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(context.tr('هنوز یادداشت صوتی ثبت نشده.', 'No voice notes yet.'), style: rpText(RpType.caption, weight: 500, color: p.muted))),
      for (final v in voices)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: IconButton(icon: Icon(playing == v.id ? LucideIcons.pause : LucideIcons.play), onPressed: () => _play(v)),
          title: Text(dur(v.ms), style: rpText(RpType.body, weight: 600, color: p.text)),
          trailing: IconButton(
            icon: Icon(LucideIcons.trash2, size: 18, color: p.badInk),
            onPressed: () async {
              await media.deleteVoice(widget.bookId, v.id);
              _reload();
            },
          ),
        ),
    ]);
  }
}
