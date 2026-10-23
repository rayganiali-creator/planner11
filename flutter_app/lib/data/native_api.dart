// قراردادِ Native (MethodChannel «rp/native») — در تست با نسخه‌ی جعلی عوض می‌شود.
import 'package:flutter/services.dart';

abstract class NativeApi {
  Future<void> connect();
  Future<Map> purchase(String productId);
  Future<void> consume(String purchaseToken);
  Future<List<Map>> getPurchasedProducts();

  /// کد خطا مثلاً 'legacy_android' را به‌صورت NativeError پرتاب می‌کند
  Future<String> saveToDownloads({required String fileName, required String mimeType, required String base64Data});
}

class NativeError implements Exception {
  final String code;
  final String? message;
  NativeError(this.code, [this.message]);
  @override
  String toString() => 'NativeError($code, $message)';
}

class ChannelNativeApi implements NativeApi {
  static const _c = MethodChannel('rp/native');

  Future<T> _call<T>(String m, [Map<String, Object?>? a]) async {
    try {
      final r = await _c.invokeMethod<T>(m, a);
      return r as T;
    } on PlatformException catch (e) {
      throw NativeError(e.code, e.message);
    } on MissingPluginException {
      throw NativeError('no_native', 'native bridge unavailable');
    }
  }

  @override
  Future<void> connect() => _call<Map>('connect');
  @override
  Future<Map> purchase(String productId) => _call<Map>('purchase', {'productId': productId}).then((m) => Map.of(m));
  @override
  Future<void> consume(String purchaseToken) => _call<Map>('consume', {'purchaseToken': purchaseToken});
  @override
  Future<List<Map>> getPurchasedProducts() async {
    final m = await _call<Map>('getPurchasedProducts');
    return [for (final p in (m['products'] as List? ?? const [])) Map.of(p as Map)];
  }

  @override
  Future<String> saveToDownloads({required String fileName, required String mimeType, required String base64Data}) async {
    final m = await _call<Map>('saveToDownloads', {'fileName': fileName, 'mimeType': mimeType, 'data': base64Data});
    return '${m['uri']}';
  }
}
