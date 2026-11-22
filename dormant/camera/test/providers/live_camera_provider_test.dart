import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/models/preview_frame.dart';
import 'package:dominoes/providers/camera_provider.dart';
import 'package:dominoes/services/object_detector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const outline = DetectionResult(
  label: 'Domino',
  confidence: .9,
  boundingBox: Rect.fromLTWH(.1, .1, .5, .25),
);

class _Detector implements ObjectDetector {
  final List<String> log;
  final pending = Completer<PreviewDetections>();
  int liveCalls = 0;
  bool initialized = false;
  _Detector(this.log);
  @override
  bool get isInitialized => initialized;
  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<PreviewDetections> detectPreview(PreviewFrame frame) {
    liveCalls++;
    log.add('live');
    return pending.future;
  }

  @override
  Future<DetectionReport> detect(Uint8List bytes) async {
    log.add('photo inference');
    return DetectionReport(
      detections: const [outline],
      imageSize: const Size(16, 32),
      imageBytes: bytes,
      processingTime: Duration.zero,
    );
  }

  @override
  void dispose() {
    initialized = false;
  }
}

class _Camera extends CameraPlatform {
  final List<String> log;
  final String photoPath;
  late StreamController<CameraImageData> frames;
  CameraDescription? selected;
  _Camera(this.log, this.photoPath);
  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'tele',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
      lensType: CameraLensType.telephoto,
    ),
    CameraDescription(
      name: 'wide',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
      lensType: CameraLensType.wide,
    ),
  ];
  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings? settings,
  ) async {
    selected = description;
    log.add('create');
    return 1;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int id) => Stream.value(
    CameraInitializedEvent(
      id,
      32,
      16,
      ExposureMode.auto,
      true,
      FocusMode.auto,
      true,
    ),
  );
  @override
  Stream<CameraErrorEvent> onCameraError(int id) =>
      Stream.value(CameraErrorEvent(id, ''));
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      Stream.value(
        const DeviceOrientationChangedEvent(DeviceOrientation.portraitUp),
      );
  @override
  Future<void> initializeCamera(
    int id, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {}
  @override
  Future<void> lockCaptureOrientation(
    int id,
    DeviceOrientation orientation,
  ) async {}
  @override
  Future<void> setFlashMode(int id, FlashMode mode) async {}
  @override
  bool supportsImageStreaming() => true;
  @override
  Stream<CameraImageData> onStreamedFrameAvailable(
    int id, {
    CameraImageStreamOptions? options,
  }) {
    frames = StreamController<CameraImageData>(
      onListen: () => log.add('stream start'),
      onCancel: () => log.add('stream stop'),
    );
    return frames.stream;
  }

  @override
  Future<XFile> takePicture(int id) async {
    log.add('take picture');
    return XFile(photoPath);
  }

  @override
  Future<void> dispose(int id) async {
    log.add('dispose');
  }

  void emit() => frames.add(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.bgra8888, raw: 0),
      width: 32,
      height: 16,
      planes: [
        CameraImagePlane(
          bytes: Uint8List(32 * 16 * 4),
          bytesPerRow: 128,
          bytesPerPixel: 4,
        ),
      ],
    ),
  );
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CameraPlatform original;
  late _Camera camera;
  late _Detector detector;
  late Directory directory;
  late List<String> log;

  setUp(() async {
    original = CameraPlatform.instance;
    log = [];
    directory = await Directory.systemTemp.createTemp('domino-camera-test-');
    final photo = File('${directory.path}/capture.jpg');
    await photo.writeAsBytes([1, 2, 3]);
    camera = _Camera(log, photo.path);
    detector = _Detector(log);
    CameraPlatform.instance = camera;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async =>
              call.method == 'requestPermissions' ? <int, int>{1: 1} : 1,
        );
  });
  tearDown(() async {
    CameraPlatform.instance = original;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        );
    await directory.delete(recursive: true);
  });

  test(
    'one live request at a time; shutter drains it before taking a photo',
    () async {
      final provider = CameraProvider(detector: detector);
      addTearDown(() async {
        provider.dispose();
        await flush();
      });
      await provider.initializeCamera();
      expect(provider.state, CameraState.preview);
      expect(camera.selected!.name, 'wide');
      camera.emit();
      camera.emit();
      await flush();
      expect(detector.liveCalls, 1);
      final capture = provider.captureAndDetect();
      await flush();
      expect(log, isNot(contains('take picture')));
      detector.pending.complete(
        const PreviewDetections(imageSize: Size(16, 32), detections: [outline]),
      );
      await capture;
      expect(provider.state, CameraState.results);
      expect(provider.liveDetections, isEmpty);
      expect(log.indexOf('stream stop'), lessThan(log.indexOf('take picture')));
      expect(log.indexOf('dispose'), lessThan(log.indexOf('photo inference')));
      provider.retake();
      expect(provider.state, CameraState.uninitialized);
      await provider.initializeCamera();
      expect(provider.state, CameraState.preview);
    },
  );

  test(
    'a live result arriving after pause cannot repaint stale boxes',
    () async {
      final provider = CameraProvider(detector: detector);
      addTearDown(() async {
        provider.dispose();
        await flush();
      });
      await provider.initializeCamera();
      camera.emit();
      await flush();
      provider.pausePreview();
      detector.pending.complete(
        const PreviewDetections(imageSize: Size(16, 32), detections: [outline]),
      );
      await flush();
      expect(provider.state, CameraState.uninitialized);
      expect(provider.liveDetections, isEmpty);
    },
  );
}
