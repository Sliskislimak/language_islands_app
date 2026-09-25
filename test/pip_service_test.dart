import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/services/pip_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PipService.channelName);
  final calls = <MethodCall>[];

  late PipService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls.clear();
    service = PipService(channel: channel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'isPipSupported' => true,
        'startPip' => true,
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('PipService', () {
    test('updateContent is a no-op until PiP has been started', () async {
      await service.updateContent(primaryText: '走ります');
      expect(calls, isEmpty);
    });

    test('forwards the three text lines once active', () async {
      expect(await service.start(), isTrue);
      expect(service.isActive, isTrue);

      await service.updateContent(
        primaryText: '走ります',
        phoneticText: 'hashirimasu',
        translationText: 'biegnę',
      );

      final update = calls.last;
      expect(update.method, 'updateContent');
      expect(update.arguments, <String, dynamic>{
        'primaryText': '走ります',
        'phoneticText': 'hashirimasu',
        'translationText': 'biegnę',
        'fontDelta': 0,
        'translationSizeDelta': 0,
        'translationAlignRight': true,
      });
    });

    test('updateStyle forwards deltas and alignment', () async {
      await service.updateStyle(
        fontDelta: 2,
        translationSizeDelta: 4,
        alignUnderPhonetics: false,
      );

      expect(calls, hasLength(2));
      expect(calls.first.method, 'isPipSupported');
      expect(calls.last.method, 'setPipStyle');
      expect(calls.last.arguments, <String, dynamic>{
        'fontDelta': 2,
        'translationSizeDelta': 4,
        'translationAlignRight': false,
      });
    });

    test('updateContent includes the last style after updateStyle', () async {
      await service.updateStyle(
        fontDelta: 4,
        translationSizeDelta: 2,
        alignUnderPhonetics: true,
      );
      await service.start();
      await service.updateContent(
        primaryText: '走ります',
        phoneticText: 'hashirimasu',
        translationText: 'biegnę',
      );

      expect(calls.last.method, 'updateContent');
      expect(calls.last.arguments, <String, dynamic>{
        'primaryText': '走ります',
        'phoneticText': 'hashirimasu',
        'translationText': 'biegnę',
        'fontDelta': 4,
        'translationSizeDelta': 2,
        'translationAlignRight': true,
      });
    });

    test('stop marks the bar inactive exactly once', () async {
      await service.start();
      await service.stop();
      expect(service.isActive, isFalse);
      expect(calls.where((c) => c.method == 'stopPip'), hasLength(1));

      await service.stop();
      expect(calls.where((c) => c.method == 'stopPip'), hasLength(1));
    });

    test('native close notification clears the active flag', () async {
      await service.start();

      var notified = false;
      service.onStoppedExternally = () => notified = true;

      await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage(
        PipService.channelName,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onPipStopped'),
        ),
        (_) {},
      );

      expect(notified, isTrue);
      expect(service.isActive, isFalse);
    });
  });
}
