import 'package:camera/camera.dart';
import 'package:dominoes/providers/camera_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraProvider', () {
    test('starts uninitialized with no captured results', () {
      final provider = CameraProvider();
      addTearDown(provider.dispose);

      expect(provider.state, CameraState.uninitialized);
      expect(provider.controller, isNull);
      expect(provider.capturedImagePath, isNull);
      expect(provider.detections, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.flashMode, FlashMode.auto);
    });

    test('cycles flash modes without a camera controller', () async {
      final provider = CameraProvider();
      addTearDown(provider.dispose);

      await provider.cycleFlashMode();
      expect(provider.flashMode, FlashMode.always);

      await provider.cycleFlashMode();
      expect(provider.flashMode, FlashMode.off);

      await provider.cycleFlashMode();
      expect(provider.flashMode, FlashMode.auto);
    });

    test('retake returns to preview state and clears results', () {
      final provider = CameraProvider();
      addTearDown(provider.dispose);

      provider.retake();

      expect(provider.state, CameraState.preview);
      expect(provider.capturedImagePath, isNull);
      expect(provider.detections, isEmpty);
    });
  });
}
