// رسانه‌ها (عکس عادت/کتاب، یادداشت صوتی کتاب) روی دیسک — جایگزین IndexedDB.
// قالب رکوردها همان HTML است: عکس {id, ownerId, dataUrl, ts} ؛ صدا {id, bookId, bytes, type, at, ms}.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../core/backup.dart';

enum PhotoKind { habit, book }

class Photo {
  final String id, ownerId, mime;
  final int ts;
  final Uint8List bytes;
  const Photo(this.id, this.ownerId, this.mime, this.ts, this.bytes);
  String get dataUrl => 'data:$mime;base64,${base64.encode(bytes)}';
}

class Voice {
  final String id, bookId, type;
  final int at, ms;
  final Uint8List bytes;
  const Voice(this.id, this.bookId, this.type, this.at, this.ms, this.bytes);
  String get dataUrl => 'data:$type;base64,${base64.encode(bytes)}';
}

/// `data:<mime>;base64,<...>` → (mime, bytes). null اگر معتبر نبود.
({String mime, Uint8List bytes})? parseDataUrl(Object? u) {
  if (u is! String || !u.startsWith('data:')) return null;
  final i = u.indexOf(',');
  if (i < 0) return null;
  final head = u.substring(5, i);
  final mime = head.split(';').first;
  try {
    if (!head.contains('base64')) return (mime: mime.isEmpty ? 'text/plain' : mime, bytes: Uint8List.fromList(utf8.encode(Uri.decodeComponent(u.substring(i + 1)))));
    return (mime: mime.isEmpty ? 'application/octet-stream' : mime, bytes: Uint8List.fromList(base64.decode(u.substring(i + 1))));
  } catch (_) {
    return null;
  }
}

class MediaStore {
  final Directory root;
  int _seq = 0;
  MediaStore(String path) : root = Directory(path);

  String _safe(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
  Directory _dir(String kind, String owner) => Directory('${root.path}/$kind/${_safe(owner)}');
  String _newId(String prefix) => '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${(_seq++).toRadixString(36)}';

  // ------------------------------------------------------------ عکس
  Future<String?> addPhoto(PhotoKind kind, String ownerId, String dataUrl) async {
    final p = parseDataUrl(dataUrl);
    if (p == null) return null;
    final id = _newId(kind == PhotoKind.habit ? 'p' : 'bp');
    final d = _dir(kind.name, ownerId)..createSync(recursive: true);
    File('${d.path}/$id.bin').writeAsBytesSync(p.bytes, flush: true);
    File('${d.path}/$id.json').writeAsStringSync(jsonEncode({'id': id, 'ownerId': ownerId, 'mime': p.mime, 'ts': DateTime.now().millisecondsSinceEpoch}), flush: true);
    return id;
  }

  Future<List<Photo>> photos(PhotoKind kind, String ownerId) async {
    final d = _dir(kind.name, ownerId);
    if (!d.existsSync()) return [];
    final out = <Photo>[];
    for (final f in d.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      try {
        final m = jsonDecode(f.readAsStringSync()) as Map;
        final bin = File(f.path.replaceFirst(RegExp(r'\.json$'), '.bin'));
        if (!bin.existsSync()) continue;
        out.add(Photo(m['id'] as String, ownerId, m['mime'] as String, m['ts'] as int, bin.readAsBytesSync()));
      } catch (_) {}
    }
    out.sort((a, b) => a.id.compareTo(b.id)); // IndexedDB: ترتیبِ کلیدِ اصلی داخلِ یک ایندکس
    return out;
  }

  Future<void> deletePhoto(PhotoKind kind, String ownerId, String id) async {
    final d = _dir(kind.name, ownerId);
    for (final ext in ['bin', 'json']) {
      final f = File('${d.path}/$id.$ext');
      if (f.existsSync()) f.deleteSync();
    }
  }

  Future<void> deleteAllPhotos(PhotoKind kind, String ownerId) async {
    final d = _dir(kind.name, ownerId);
    if (d.existsSync()) d.deleteSync(recursive: true);
  }

  // ------------------------------------------------------------ صدا
  Future<String> putVoice(String bookId, {String? id, required Uint8List bytes, required String type, required int at, required int ms}) async {
    final vid = id ?? _newId('v');
    final d = _dir('voice', bookId)..createSync(recursive: true);
    File('${d.path}/${_safe(vid)}.bin').writeAsBytesSync(bytes, flush: true);
    File('${d.path}/${_safe(vid)}.json').writeAsStringSync(jsonEncode({'id': vid, 'bookId': bookId, 'type': type, 'at': at, 'ms': ms}), flush: true);
    return vid;
  }

  Future<List<Voice>> voices(String bookId) async {
    final d = _dir('voice', bookId);
    if (!d.existsSync()) return [];
    final out = <Voice>[];
    for (final f in d.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      try {
        final m = jsonDecode(f.readAsStringSync()) as Map;
        final bin = File(f.path.replaceFirst(RegExp(r'\.json$'), '.bin'));
        if (!bin.existsSync()) continue;
        out.add(Voice(m['id'] as String, bookId, m['type'] as String, m['at'] as int, m['ms'] as int, bin.readAsBytesSync()));
      } catch (_) {}
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  Future<void> deleteVoice(String bookId, String id) async {
    final d = _dir('voice', bookId);
    for (final ext in ['bin', 'json']) {
      final f = File('${d.path}/${_safe(id)}.$ext');
      if (f.existsSync()) f.deleteSync();
    }
  }

  Future<void> deleteAllVoices(String bookId) async {
    final d = _dir('voice', bookId);
    if (d.existsSync()) d.deleteSync(recursive: true);
  }

  // ------------------------------------------------------------ پشتیبان
  /// همان حلقه‌های createBackupJSON: رسانه‌ی کتاب‌ها و عادت‌های موجود در state.
  Future<BackupMedia> collectForBackup(List books, List habits) async {
    final bp = <String, List<String>>{}, hp = <String, List<String>>{};
    final bv = <String, List<Map<String, dynamic>>>{};
    for (final b in books) {
      if (b is! Map) continue;
      final id = '${b['id']}';
      final ph = await photos(PhotoKind.book, id);
      if (ph.isNotEmpty) bp[id] = [for (final p in ph) p.dataUrl];
      final vs = await voices(id);
      final outV = [for (final v in vs) {'id': v.id, 'at': v.at, 'ms': v.ms, 'type': v.type, 'dataUrl': v.dataUrl}];
      if (outV.isNotEmpty) bv[id] = outV;
    }
    for (final h in habits) {
      if (h is! Map) continue;
      final id = '${h['id']}';
      final ph = await photos(PhotoKind.habit, id);
      if (ph.isNotEmpty) hp[id] = [for (final p in ph) p.dataUrl];
    }
    return BackupMedia(bookPhotos: bp, habitPhotos: hp, bookVoices: bv);
  }

  /// بازیابی: «اول پاک، بعد نوشتن» تا ایمپورتِ دوباره داده را تکراری نکند.
  Future<void> restoreFromBackup(Map data) async {
    final bp = data['bookPhotos'];
    if (bp is Map) {
      for (final id in bp.keys) {
        try {
          await deleteAllPhotos(PhotoKind.book, '$id');
          for (final u in (bp[id] is List ? bp[id] as List : const [])) {
            await addPhoto(PhotoKind.book, '$id', '$u');
          }
        } catch (_) {}
      }
    }
    final hp = data['habitPhotos'];
    if (hp is Map) {
      for (final id in hp.keys) {
        try {
          await deleteAllPhotos(PhotoKind.habit, '$id');
          for (final u in (hp[id] is List ? hp[id] as List : const [])) {
            await addPhoto(PhotoKind.habit, '$id', '$u');
          }
        } catch (_) {}
      }
    }
    final bv = data['bookVoices'];
    if (bv is Map) {
      for (final id in bv.keys) {
        try {
          await deleteAllVoices('$id');
          for (final vo in (bv[id] is List ? bv[id] as List : const [])) {
            if (vo is! Map) continue;
            final p = parseDataUrl(vo['dataUrl']);
            if (p == null) continue;
            final atRaw = vo['at'] ?? vo['createdAt'];
            final msRaw = vo['ms'] ?? vo['duration'];
            await putVoice('$id',
                id: (vo['id'] is String && (vo['id'] as String).isNotEmpty) ? vo['id'] as String : null,
                bytes: p.bytes,
                type: (vo['type'] is String ? vo['type'] as String : null) ?? p.mime,
                at: atRaw is num && atRaw != 0 ? atRaw.toInt() : DateTime.now().millisecondsSinceEpoch,
                ms: msRaw is num ? msRaw.toInt() : 0);
          }
        } catch (_) {}
      }
    }
  }
}
