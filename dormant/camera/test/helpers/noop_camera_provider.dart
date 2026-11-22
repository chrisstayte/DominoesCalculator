import 'package:dominoes/providers/camera_provider.dart';

/// Camera provider that never touches the device camera. Restore it into
/// test/helpers/test_app.dart (and the harness `cameraProvider` parameter)
/// when the camera returns to the app.
class NoopCameraProvider extends CameraProvider {
  @override
  Future<void> initializeCamera() async {}

  @override
  void pausePreview() {}

  @override
  Future<void> requestPermissionAgain() async {}

  @override
  void resumePreview() {}
}
