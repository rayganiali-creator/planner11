// ترکیب آواتار: پورتِ avCompose نسخه‌ی HTML روی بوم ۱۸۰×۱۸۶ (پیکسل‌آرت، بدون نرم‌سازی).
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../core/doc.dart';
import '../../core/gameplay.dart';

const double avW = 180, avH = 186, avOffX = 25;
const double _petCx = 142, _petBottom = 182;

const _kinds = <String, (int, String)>{
  'pet': (-10, 'pet'), 'petgear': (-9, 'petgear'), 'base': (0, 'base'),
  'shoes': (10, 'shoes'), 'pants': (20, 'pants'),
  'top': (30, 'clothes'), 'outfit': (35, 'clothes'),
  'armor': (50, 'armor'), 'cape': (55, 'cape'),
  'hair': (60, 'hair'), 'hijab': (60, 'hijab'),
  'hat': (70, 'headwear'), 'helmet': (70, 'headwear'),
  'sword': (80, 'sword'), 'shield': (90, 'shield'),
};
const _catPrice = <String, int>{
  'body': 0, 'clothes': 800, 'shoes': 800, 'hair': 400, 'hat': 400, 'hijab': 400, 'armor': 1000,
  'cape': 1000, 'sword': 1100, 'helmet': 1300, 'shield': 1000, 'pet': 800, 'petgear': 400,
};

List<double> _nums(Object? l) => [for (final x in (l as List)) (x as num).toDouble()];

class AvItem {
  final String id, category, kind, gender, slot;
  final String? name, asset, sleepAsset;
  final Map? files, backFiles, backFit, fits, po;
  final List<double>? size, off, rect;
  final String? on;
  final int layer, price;
  final bool flip;
  AvItem({
    required this.id, required this.category, required this.kind, required this.gender, required this.slot,
    required this.layer, required this.price, required this.flip,
    this.name, this.asset, this.sleepAsset, this.files, this.backFiles, this.backFit, this.fits, this.po,
    this.size, this.off, this.rect, this.on,
  });
  String assetFor(String g) =>
      files != null ? 'avatar/${files![g] ?? files!['male'] ?? files!['female']}' : asset!;
  bool compatible(String g) => gender == 'both' || gender == g;
}

class AvData {
  final Map<String, AvItem> items = {};
  final Map raw;
  AvData(this.raw) {
    for (final r in (raw['items'] as List).cast<Map>()) {
      var c = r['c'] as String;
      if (c == 'pants') c = 'clothes';
      final k = _kinds[r['k']] ?? (40, '${r['k']}');
      final slot = r['k'] == 'petgear' ? 'petgear_${r['on'] == 'neck' ? 'neck' : 'head'}' : k.$2;
      items[r['id'] as String] = AvItem(
        id: r['id'], category: c, kind: r['k'], gender: r['g'], slot: slot, name: r['n'],
        asset: r['f'] != null ? 'avatar/${r['f']}' : null,
        sleepAsset: r['fs'] != null ? 'avatar/${r['fs']}' : null,
        files: r['files'] as Map?, backFiles: r['backFiles'] as Map?, backFit: r['backFit'] as Map?,
        fits: r['fit'] as Map?, po: r['po'] as Map?,
        size: r['size'] == null ? null : _nums(r['size']), off: r['off'] == null ? null : _nums(r['off']),
        on: r['on'] as String?, layer: k.$1,
        price: r['price'] is num ? (r['price'] as num).toInt() : (_catPrice[c] ?? 800),
        flip: r['flip'] == true,
      );
    }
    for (final b in (raw['bases'] as List).cast<Map>()) {
      items[b['id'] as String] = AvItem(
        id: b['id'], category: 'body', kind: 'base', gender: b['g'], slot: 'base', layer: 0, price: 0, flip: false,
        asset: 'avatar/${b['f']}', rect: _nums(b['rect']),
      );
    }
  }

  static Future<AvData> load() async =>
      AvData(jsonDecode(await rootBundle.loadString('assets/avatar_data.json')) as Map);

  /// آیتم‌های پوشیده‌ی معتبر (پولی‌ها فقط با پرو) — avEquippedFor
  Map<String, String> equippedFor(Doc state, String gender) {
    final av = state['avatar'];
    final eqAll = av is Map && av['equipped'] is Map ? av['equipped'] as Map : const {};
    final eq = eqAll[gender] is Map ? eqAll[gender] as Map : const {};
    final out = <String, String>{};
    final pro = state['isPremium'] == true;
    eq.forEach((slot, id) {
      final it = items[id];
      if (it != null && it.slot == slot && it.slot != 'shoes' && it.compatible(gender) && (it.price == 0 || pro)) {
        out[slot as String] = it.id;
      }
    });
    return out;
  }
}

class _Layer {
  final AvItem? item;
  final bool isBase, isBack;
  final String kind;
  final int layer;
  final String asset;
  final List<double>? rect;
  final AvItem? clipUnder;
  _Layer({this.item, this.isBase = false, this.isBack = false, required this.kind, required this.layer, required this.asset, this.rect, this.clipUnder});
}

final Map<String, Future<ui.Image?>> _imgCache = {};
Future<ui.Image?> avLoadImg(String src) => _imgCache.putIfAbsent(src, () async {
      try {
        final d = await rootBundle.load('assets/$src');
        final codec = await ui.instantiateImageCodec(d.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      } catch (_) {
        return null;
      }
    });

Future<ui.Image> _hairUnderHat(ui.Image hair, List<double> hr, ui.Image hat, List<double> tr) async {
  final w = avW.toInt(), h = avH.toInt();
  Future<Uint8List> render(ui.Image im, List<double> r) async {
    final rec = ui.PictureRecorder();
    ui.Canvas(rec).drawImage(im, ui.Offset(r[0], r[1]), ui.Paint()..filterQuality = ui.FilterQuality.none);
    final img = await rec.endRecording().toImage(w, h);
    return (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  }

  final hd = await render(hair, hr);
  final td = await render(hat, tr);
  final bottom = List<int>.filled(w, -1);
  final bs = <int>[];
  for (int x = 0; x < w; x++) {
    for (int y = h - 1; y >= 0; y--) {
      if (td[(y * w + x) * 4 + 3] > 0) {
        bottom[x] = y;
        bs.add(y);
        break;
      }
    }
  }
  bs.sort();
  final mid = bs.isNotEmpty ? bs[(bs.length * 0.35).floor()] : -1;
  for (int x = 0; x < w; x++) {
    final b = bottom[x] >= 0 ? bottom[x] : mid;
    for (int y = 0; y <= b; y++) {
      hd[(y * w + x) * 4 + 3] = 0;
    }
  }
  final comp = await ui.ImmutableBuffer.fromUint8List(hd);
  final desc = ui.ImageDescriptor.raw(comp, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await desc.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

/// mode: null = آواتار + حیوان، 'noPet'، 'petOnly'
Future<ui.Image?> avCompose(AvData data, String gender, Map<String, String> equipped, String cond, {String? mode}) async {
  final sleeping = avCondEyesClosed(cond);
  final baseWanted = equipped['base'];
  final baseId = (baseWanted != null && data.items[baseWanted]?.gender == gender)
      ? baseWanted
      : (gender == 'male' ? 'base/male' : 'base/female');
  final base = data.items[baseId]!;
  bool petSide(String k) => k == 'pet' || k == 'petgear';
  final layers = <_Layer>[];
  if (mode != 'petOnly') layers.add(_Layer(item: base, isBase: true, kind: 'base', layer: 0, asset: base.asset!, rect: base.rect));
  final hasPet = equipped.values.any((id) => data.items[id]?.kind == 'pet');
  for (final id in equipped.values) {
    final it = data.items[id];
    if (it == null || it.kind == 'base' || !it.compatible(gender)) continue;
    if (mode == 'noPet' && petSide(it.kind)) continue;
    if (mode == 'petOnly' && !petSide(it.kind)) continue;
    if (it.kind == 'petgear' && !hasPet) continue;
    if (!petSide(it.kind) && it.fits?[gender] == null) continue;
    final String asset = (it.kind == 'pet' && sleeping && it.sleepAsset != null)
        ? it.sleepAsset!
        : (it.kind == 'petgear' ? it.asset! : it.assetFor(gender));
    layers.add(_Layer(item: it, kind: it.kind, layer: it.layer, asset: asset));
  }
  List<_Layer> stable(List<_Layer> l) {
    final idx = {for (int i = 0; i < l.length; i++) l[i]: i};
    return [...l]..sort((a, b) => a.layer != b.layer ? a.layer.compareTo(b.layer) : idx[a]!.compareTo(idx[b]!));
  }

  var ls = stable(layers);
  final headwear = ls.where((l) => l.kind == 'hat' || l.kind == 'helmet').firstOrNull;
  final hairIdx = ls.indexWhere((l) => l.kind == 'hair');
  if (headwear != null && hairIdx >= 0) {
    if (headwear.kind == 'helmet') {
      ls.removeAt(hairIdx);
    } else {
      final h = ls[hairIdx];
      ls[hairIdx] = _Layer(item: h.item, kind: h.kind, layer: h.layer, asset: h.asset, clipUnder: headwear.item);
    }
  }
  for (final l in [...ls]) {
    final bf = l.item?.backFiles?[gender];
    if (bf != null) {
      ls.add(_Layer(isBack: true, kind: 'cape_back', layer: -5, asset: 'avatar/$bf', rect: _nums(l.item!.backFit![gender])));
    }
  }
  ls = stable(ls);
  final hasWeapon = ls.any((l) => l.kind == 'sword'), hasShield = ls.any((l) => l.kind == 'shield');
  final extra = <({String f, List<double> rect})>[];
  final hands = (data.raw['hands'] as Map)[baseId] as Map? ?? const {};
  if (mode != 'petOnly' && hasWeapon && hands['L'] != null) extra.add((f: hands['L']['f'], rect: _nums(hands['L']['rect'])));
  if (mode != 'petOnly' && hasShield && hands['R'] != null) extra.add((f: hands['R']['f'], rect: _nums(hands['R']['rect'])));
  final sl = (data.raw['sleep'] as Map)[baseId] as Map?;
  if (mode != 'petOnly' && sleeping && sl != null) {
    ls.add(_Layer(isBack: true, kind: 'sleep', layer: 58, asset: 'avatar/${sl['f']}', rect: _nums(sl['rect'])));
  }
  final condMap = data.raw['cond'] as Map?;
  final condArt = (cond == 'hurt' || cond == 'sick') ? ((condMap?[cond] as Map?)?[gender] as Map?) : null;
  if (mode != 'petOnly' && condArt != null) {
    ls.add(_Layer(isBack: true, kind: 'cond', layer: 62, asset: 'avatar/${condArt['f']}', rect: _nums(condArt['rect'])));
  }
  ls = stable(ls);
  final petCond = (cond == 'hurt' || cond == 'sick') ? ((condMap?['pet'] as Map?)?[cond] as Map?) : null;
  final petMark = (mode != 'noPet' && hasPet && petCond != null) ? petCond : null;

  final imgs = await Future.wait([
    for (final l in ls) avLoadImg(l.asset),
    for (final e in extra) avLoadImg('avatar/${e.f}'),
    if (petMark != null) avLoadImg('avatar/${petMark['f']}'),
  ]);
  if (mode != 'petOnly' && imgs[ls.indexWhere((l) => l.isBase)] == null) return null; // base failed

  final rec = ui.PictureRecorder();
  final cv = ui.Canvas(rec);
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.none..isAntiAlias = false;
  void shadow(double cx, double cy, double rx) {
    // JS: گرادیانِ «دایره‌ای» (شعاع rx) که فقط داخلِ بیضیِ کم‌ارتفاع (rx × 0.16rx) رنگ می‌شود
    final g = ui.Gradient.radial(ui.Offset(cx, cy), rx, [const ui.Color(0x42000000), const ui.Color(0x00000000)]);
    cv.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 2 * rx, height: 2 * rx * 0.16), ui.Paint()..shader = g);
  }

  void img(ui.Image im, double x, double y, [double? w, double? h]) {
    final dw = w ?? im.width.toDouble(), dh = h ?? im.height.toDouble();
    cv.drawImageRect(im, ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), ui.Rect.fromLTWH(x, y, dw, dh), paint);
  }

  ({double x, double y, double hs})? petAnchor(({double x, double y, String id})? pr, String which) {
    if (pr == null) return null;
    final a = (data.raw['petAnchor'] as Map?)?[pr.id] as Map?;
    if (a == null || a[which] == null) return null;
    final p = _nums(a[which]);
    return (x: pr.x + p[0], y: pr.y + p[1], hs: (a['hs'] as num?)?.toDouble() ?? 1.0);
  }

  void withMirror(bool flip, double x, double w, void Function() draw) {
    if (!flip) return draw();
    cv.save();
    cv.translate(2 * x + w, 0);
    cv.scale(-1, 1);
    draw();
    cv.restore();
  }

  ({double x, double y, String id})? petRect;
  for (int i = 0; i < ls.length; i++) {
    final l = ls[i];
    final im = imgs[i];
    if (im == null) continue;
    final it = l.item;
    if (l.kind == 'pet' && it != null) {
      final w = it.size![0], h = it.size![1];
      shadow(_petCx, _petBottom, math.max(8, w * 0.42));
      petRect = (x: (_petCx - w / 2).roundToDouble(), y: _petBottom - h, id: it.id);
      img(im, petRect.x, petRect.y);
      continue;
    }
    if (l.kind == 'petgear' && it != null) {
      final p = petAnchor(petRect, it.on ?? 'head');
      if (p == null) continue;
      final ov = (it.po != null && petRect != null) ? it.po![petRect.id] as Map? : null;
      final off = ov?['off'] != null ? _nums(ov!['off']) : (it.off ?? [0, 0]);
      final gs = ov?['size'] != null ? _nums(ov!['size']) : it.size!;
      final gflip = ov != null && ov.containsKey('flip') ? ov['flip'] == true : it.flip;
      final sc = it.on == 'head' ? p.hs : 1.0;
      final w = math.max(1.0, (gs[0] * sc).roundToDouble()), h = math.max(1.0, (gs[1] * sc).roundToDouble());
      final ox = off[0] * sc, oy = off[1] * sc;
      final gx = (p.x - w / 2 + ox).roundToDouble(), gy = (it.on == 'head' ? p.y - h + oy : p.y + oy).roundToDouble();
      withMirror(gflip, gx, w, () => img(im, gx, gy, w, h));
      continue;
    }
    final r = (l.isBase || l.isBack) ? l.rect! : _nums(it!.fits![gender]);
    if (l.isBase) shadow(avOffX + 65, 182, 30);
    final flip = it?.flip ?? false;
    bool done = false;
    if (l.clipUnder != null) {
      final hatIdx = ls.indexWhere((x) => x.item?.id == l.clipUnder!.id);
      final hatIm = hatIdx >= 0 ? imgs[hatIdx] : null;
      if (hatIm != null) {
        final merged = await _hairUnderHat(im, r, hatIm, _nums(l.clipUnder!.fits![gender]));
        withMirror(flip, avOffX + r[0], r[2], () => img(merged, avOffX, 0));
        done = true;
      }
    }
    if (done) continue;
    if (l.kind == 'hijab') {
      final sp = ui.Paint()
        ..filterQuality = ui.FilterQuality.none
        ..colorFilter = const ui.ColorFilter.mode(ui.Color.fromRGBO(20, 14, 24, 0.38), ui.BlendMode.srcIn);
      for (final dx in [0.0, 1.0, -1.0]) {
        cv.drawImageRect(im, ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
            ui.Rect.fromLTWH(avOffX + r[0] + dx, r[1] + 1, r[2], r[3]), sp);
      }
    }
    withMirror(flip, avOffX + r[0], r[2], () => img(im, avOffX + r[0], r[1], r[2], r[3]));
  }
  for (int k = 0; k < extra.length; k++) {
    final im = imgs[ls.length + k];
    if (im != null) img(im, avOffX + extra[k].rect[0], extra[k].rect[1]);
  }
  if (petMark != null && petRect != null) {
    final im = imgs[ls.length + extra.length];
    final p = petAnchor(petRect, 'head');
    if (im != null && p != null) {
      final sz = _nums(petMark['size']);
      img(im, (p.x - sz[0] / 2).roundToDouble(), (p.y + 2).roundToDouble());
    }
  }
  return rec.endRecording().toImage(avW.toInt(), avH.toInt());
}
