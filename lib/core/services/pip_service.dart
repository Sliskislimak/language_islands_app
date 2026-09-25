import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opakowanie na natywny pływający pasek Picture-in-Picture (iOS 15+).
///
/// Kanał natywny hostuje `AVPictureInPictureVideoCallViewController` z widokiem
/// SwiftUI, więc pasek utrzymuje się nad innymi aplikacjami podczas pętli
/// Shadowing i Recall. Na platformach bez wsparcia wszystkie metody są no-op.
class PipService {
  PipService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const String channelName = 'language_islands/pip';

  final MethodChannel _channel;

  bool? _supported;
  bool _isActive = false;

  /// Wywoływane, gdy okno PiP zostanie zamknięte poza aplikacją
  /// (przycisk zamknięcia w oknie PiP lub błąd systemowy).
  VoidCallback? onStoppedExternally;

  /// Czy okno PiP jest — zgodnie z ostatnią znaną odpowiedzią natywną — otwarte.
  bool get isActive => _isActive;

  Future<bool> isSupported() async {
    final cached = _supported;
    if (cached != null) return cached;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _supported = false;
      return false;
    }

    final supported = await _invoke<bool>('isPipSupported');
    _supported = supported ?? false;
    return _supported!;
  }

  Future<bool> start() async {
    if (!await isSupported()) return false;
    final started = await _invoke<bool>('startPip');
    _isActive = started ?? false;
    return _isActive;
  }

  Future<void> stop() async {
    if (!_isActive) return;
    _isActive = false;
    await _invoke<void>('stopPip');
  }

  Future<void> updateContent({
    required String primaryText,
    String? phoneticText,
    String? translationText,
  }) async {
    if (!_isActive) return;
    await _invoke<void>('updateContent', <String, dynamic>{
      'primaryText': primaryText,
      'phoneticText': phoneticText ?? '',
      'translationText': translationText ?? '',
    });
  }

  Future<void> clearContent() async {
    if (!_isActive) return;
    await updateContent(primaryText: '');
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onPipStopped') return;
    _isActive = false;
    onStoppedExternally?.call();
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      _supported = false;
      _isActive = false;
      return null;
    } on PlatformException {
      return null;
    }
  }
}
