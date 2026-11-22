import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/models/preview_frame.dart';
import 'package:dominoes/services/live_detection_tracker.dart';
import 'package:dominoes/services/object_detector.dart';
import 'package:dominoes/services/tflite_detector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

enum CameraState {
  uninitialized,
  permissionDenied,
  preview,
  capturing,
  processing,
  results,
  error,
}

class CameraProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// Minimum spacing between live detector requests. Requests are also
  /// serialized (one in flight), so this mostly caps battery use.
  static const _minFrameInterval = Duration(milliseconds: 90);
  CameraController? _controller;
  final ObjectDetector _detector;
  CameraState _state = CameraState.uninitialized;
  DetectionReport? _report;
  String? _capturedImagePath;
  String? _errorMessage;
  String? _liveMessage;
  FlashMode _flashMode = FlashMode.auto;
  final _tracker = LiveDetectionTracker();
  final _liveTracks = ValueNotifier<List<TrackedDetection>>(const []);
  Future<void>? _initializing;
  Future<void>? _closing;
  Future<void>? _startingStream;
  Future<void>? _liveTask;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;
  bool _wantsPreview = false;
  int _generation = 0;
  int _captureGeneration = 0;
  int _liveGeneration = 0;

  CameraController? get controller => _controller;
  CameraState get state => _state;
  DetectionReport? get report => _report;
  List<DetectionResult> get detections => _report?.detections ?? const [];
  List<DetectionResult> get liveDetections => [
    for (final track in _liveTracks.value) track.detection,
  ];

  /// Stable, smoothed live boxes. Updated without [notifyListeners] so a
  /// detector result only repaints the overlay, not the whole camera screen.
  ValueListenable<List<TrackedDetection>> get liveTracks => _liveTracks;
  String? get liveMessage => _liveMessage;
  String? get capturedImagePath => _capturedImagePath;
  String? get errorMessage => _errorMessage;
  FlashMode get flashMode => _flashMode;

  CameraProvider({ObjectDetector? detector})
    : _detector = detector ?? TfliteDetector() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initializeCamera() {
    if (_disposed) return Future.value();
    _wantsPreview = true;
    if (_state == CameraState.error || _state == CameraState.permissionDenied) {
      _state = CameraState.uninitialized;
      _errorMessage = null;
      notifyListeners();
    }
    return _initializing ??= _initializeCamera().whenComplete(() {
      _initializing = null;
      // A tab/lifecycle change can cancel an in-flight initialization. Retry
      // only if the user has returned while that old controller was closing.
      if (!_disposed &&
          _wantsPreview &&
          _controller == null &&
          _state == CameraState.uninitialized) {
        scheduleMicrotask(initializeCamera);
      }
    });
  }

  Future<void> _initializeCamera() async {
    final generation = ++_generation;
    CameraController? next;
    try {
      await _closing;
      final status = await Permission.camera.request();
      if (_disposed || generation != _generation || !_wantsPreview) return;
      if (!status.isGranted) {
        _state = CameraState.permissionDenied;
        notifyListeners();
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty)
        throw StateError('No cameras available on this device.');
      final back = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final wide = back.where(
        (camera) => camera.lensType == CameraLensType.wide,
      );
      final selected = wide.isNotEmpty
          ? wide.first
          : back.isNotEmpty
          ? back.first
          : cameras.first;
      // Close the old native session before creating a replacement. The iOS
      // plugin owns one native camera session, even with multiple Dart handles.
      await _closeCamera();
      if (_disposed || generation != _generation || !_wantsPreview) return;
      next = CameraController(
        selected,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await next.initialize();
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await next.setFlashMode(_flashMode);
      await _detector.initialize();
      if (_disposed || generation != _generation || !_wantsPreview) return;
      _controller = next;
      next = null;
      _errorMessage = null;
      _liveMessage = null;
      _state = CameraState.preview;
      notifyListeners();
      await _startLiveStream();
    } catch (error) {
      if (_disposed || generation != _generation || !_wantsPreview) return;
      _errorMessage = 'Failed to initialize camera: $error';
      _state = CameraState.error;
      _wantsPreview = false;
      notifyListeners();
    } finally {
      await next?.dispose();
    }
  }

  Future<void> _startLiveStream() {
    if (_startingStream != null) return _startingStream!;
    final camera = _controller;
    if (_disposed ||
        !_wantsPreview ||
        _state != CameraState.preview ||
        camera == null ||
        camera.value.isStreamingImages)
      return Future.value();
    return _startingStream = _startStream(
      camera,
    ).whenComplete(() => _startingStream = null);
  }

  Future<void> _startStream(CameraController camera) async {
    try {
      await camera.startImageStream((image) => _onFrame(image, camera));
    } catch (_) {
      if (!_disposed &&
          camera == _controller &&
          _state == CameraState.preview) {
        _liveMessage = 'Live boxes unavailable. You can still take a photo.';
        notifyListeners();
      }
    }
  }

  void _onFrame(CameraImage image, CameraController camera) {
    if (_disposed ||
        !_wantsPreview ||
        _state != CameraState.preview ||
        camera != _controller ||
        _liveTask != null)
      return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _minFrameInterval) return;
    _lastFrame = now;
    final format = image.format.group;
    if (format != ImageFormatGroup.bgra8888 &&
        format != ImageFormatGroup.yuv420)
      return;
    // Capture is locked to portrait. iOS can deliver portrait buffers directly;
    // Android generally delivers sensor-oriented landscape buffers.
    final rotation = image.width > image.height
        ? camera.description.sensorOrientation
        : 0;
    final frame = PreviewFrame(
      width: image.width,
      height: image.height,
      rotation: rotation,
      format: format == ImageFormatGroup.bgra8888
          ? PreviewPixelFormat.bgra8888
          : PreviewPixelFormat.yuv420,
      planes: [
        for (final plane in image.planes)
          PreviewPlane(
            plane.bytes,
            rowStride: plane.bytesPerRow,
            pixelStride:
                plane.bytesPerPixel ??
                (format == ImageFormatGroup.bgra8888 ? 4 : 1),
          ),
      ],
    );
    final generation = _liveGeneration;
    _liveTask = _scanFrame(
      frame,
      generation,
    ).whenComplete(() => _liveTask = null);
  }

  Future<void> _scanFrame(PreviewFrame frame, int generation) async {
    try {
      final result = await _detector.detectPreview(frame);
      if (_disposed ||
          generation != _liveGeneration ||
          _state != CameraState.preview ||
          !_wantsPreview)
        return;
      _liveTracks.value = _tracker.update(result.detections);
      if (_liveMessage != null) {
        _liveMessage = null;
        notifyListeners();
      }
    } catch (_) {
      if (_disposed ||
          generation != _liveGeneration ||
          _state != CameraState.preview)
        return;
      _clearLive();
      _liveMessage = 'Live boxes unavailable. You can still take a photo.';
      notifyListeners();
    }
  }

  Future<void> captureAndDetect() async {
    final camera = _controller;
    if (_disposed || _state != CameraState.preview || camera == null) return;
    final generation = ++_captureGeneration;
    _liveGeneration++;
    _clearLive();
    try {
      _state = CameraState.capturing;
      notifyListeners();
      // Drain the single live request before the high-resolution snapshot.
      // This prevents a live frame from occupying the interpreter at capture.
      await _startingStream;
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      await _liveTask;
      if (_disposed ||
          generation != _captureGeneration ||
          camera != _controller)
        return;
      final picture = await camera.takePicture();
      if (_disposed || generation != _captureGeneration) return;
      _capturedImagePath = picture.path;
      _state = CameraState.processing;
      _wantsPreview = false;
      notifyListeners();
      await _closeCamera();
      final report = await _detector.detect(
        await File(picture.path).readAsBytes(),
      );
      if (_disposed || generation != _captureGeneration) return;
      _report = report;
      _state = CameraState.results;
      notifyListeners();
    } catch (error) {
      if (_disposed || generation != _captureGeneration) return;
      _errorMessage = 'Detection failed: $error';
      _state = CameraState.error;
      notifyListeners();
    }
  }

  void _clearLive() {
    _tracker.reset();
    _liveTracks.value = const [];
  }

  Future<void> _closeCamera() {
    final camera = _controller;
    _controller = null;
    if (camera == null) return _closing ?? Future.value();
    final prior = _closing;
    return _closing = () async {
      await prior;
      await _startingStream;
      if (camera.value.isStreamingImages) {
        try {
          await camera.stopImageStream();
        } catch (_) {
          /* Session may already be inactive. */
        }
      }
      await camera.dispose();
    }();
  }

  Future<void> setFocusPoint(Offset point) async {
    final camera = _controller;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      await camera.setFocusMode(FocusMode.auto);
      await camera.setFocusPoint(point);
    } catch (_) {
      /* Device may not support focus. */
    }
    try {
      await camera.setExposurePoint(point);
    } catch (_) {
      /* Device may not support exposure. */
    }
  }

  Future<void> cycleFlashMode() async {
    _flashMode = switch (_flashMode) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    await _controller?.setFlashMode(_flashMode);
    if (!_disposed) notifyListeners();
  }

  void retake() {
    if (_disposed) return;
    _captureGeneration++;
    _report = null;
    _errorMessage = null;
    _clearLive();
    _capturedImagePath = null;
    _state = _controller == null
        ? CameraState.uninitialized
        : CameraState.preview;
    notifyListeners();
  }

  void pausePreview() {
    if (_disposed) return;
    _wantsPreview = false;
    _generation++;
    _liveGeneration++;
    _clearLive();
    unawaited(_closeCamera());
    if (_state == CameraState.preview || _state == CameraState.capturing) {
      _captureGeneration++;
      _state = CameraState.uninitialized;
      notifyListeners();
    }
  }

  void resumePreview() {
    if (_disposed ||
        (_state != CameraState.uninitialized && _state != CameraState.preview))
      return;
    _wantsPreview = true;
    if (_controller == null) {
      initializeCamera();
    } else {
      _startLiveStream();
    }
  }

  Future<void> requestPermissionAgain() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    if (status.isGranted && !_disposed) await initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive &&
        (_controller != null || _initializing != null)) {
      pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      resumePreview();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _wantsPreview = false;
    _generation++;
    _captureGeneration++;
    _liveGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_closeCamera());
    _detector.dispose();
    _tracker.reset();
    _liveTracks.dispose();
    super.dispose();
  }
}
