import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const String channelName = 'language_islands/pip';

  final MethodChannel _channel;

  bool? _supported;
  bool _isActive = false;

  double? _windowWidth;
  double? _windowHeight;
  int _fontDelta = 0;
  int _translationSizeDelta = 0;
  bool _alignUnderPhonetics = true;

  VoidCallback? onStartedExternally;
  VoidCallback? onStoppedExternally;

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
      ..._stylePayload,
    });
  }

  Future<void> updateStyle({
    double? windowWidth,
    double? windowHeight,
    required int fontDelta,
    required int translationSizeDelta,
    required bool alignUnderPhonetics,
  }) async {
    _windowWidth = windowWidth;
    _windowHeight = windowHeight;
    _fontDelta = fontDelta;
    _translationSizeDelta = translationSizeDelta;
    _alignUnderPhonetics = alignUnderPhonetics;
    if (!await isSupported()) return;
    await _invoke<void>('setPipStyle', _stylePayload);
  }

  Map<String, dynamic> get _stylePayload {
    final payload = <String, dynamic>{
      'fontDelta': _fontDelta,
      'translationSizeDelta': _translationSizeDelta,
      'translationAlignRight': _alignUnderPhonetics,
    };
    if (_windowWidth != null) {
      payload['windowWidth'] = _windowWidth;
    }
    if (_windowHeight != null) {
      payload['windowHeight'] = _windowHeight;
    }
    return payload;
  }

  Future<void> clearContent() async {
    if (!_isActive) return;
    await updateContent(primaryText: '');
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onPipStarted') {
      _isActive = true;
      onStartedExternally?.call();
    } else if (call.method == 'onPipStopped') {
      _isActive = false;
      onStoppedExternally?.call();
    }
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