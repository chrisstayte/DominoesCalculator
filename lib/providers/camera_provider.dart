import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dominoes/models/detection_result.dart';
import 'package:dominoes/services/object_detector.dart';
import 'package:dominoes/services/tflite_detector.dart';
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
  CameraController? _controller;
  final ObjectDetector _detector;
  CameraState _state = CameraState.uninitialized;
  List<DetectionResult> _detections = [];
  String? _capturedImagePath;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.auto;
  DetectionReport? _report;
  Future<void>? _initializing;
  bool _disposed = false;
  int _generation = 0;
  int _captureGeneration = 0;

  DetectionReport? get report => _report;

  CameraController? get controller => _controller;
  CameraState get state => _state;
  List<DetectionResult> get detections => List.unmodifiable(_detections);
  String? get capturedImagePath => _capturedImagePath;
  String? get errorMessage => _errorMessage;
  FlashMode get flashMode => _flashMode;

  CameraProvider({ObjectDetector? detector})
    : _detector = detector ?? TfliteDetector() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initializeCamera() {
    if (_disposed) return Future.value();
    return _initializing ??= _initializeCamera().whenComplete(
      () => _initializing = null,
    );
  }

  Future<void> _initializeCamera() async {
    final generation = ++_generation;
    CameraController? next;
    try {
      final status = await Permission.camera.request();
      if (_disposed || generation != _generation) return;
      if (!status.isGranted) {
        _state = CameraState.permissionDenied;
        notifyListeners();
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No cameras available on this device.');
      }
      final back = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      next = CameraController(
        back.isEmpty ? cameras.first : back.first,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await next.initialize();
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await next.setFlashMode(_flashMode);
      await _detector.initialize();
      if (_disposed || generation != _generation) return;
      final previous = _controller;
      _controller = next;
      next = null;
      await previous?.dispose();
      if (_disposed || generation != _generation) return;
      _errorMessage = null;
      _state = CameraState.preview;
      notifyListeners();
    } catch (e) {
      if (_disposed || generation != _generation) return;
      _errorMessage = 'Failed to initialize camera: $e';
      _state = CameraState.error;
      notifyListeners();
    } finally {
      await next?.dispose();
    }
  }

  Future<void> captureAndDetect() async {
    if (_state != CameraState.preview || _controller == null) return;

    final generation = ++_captureGeneration;
    try {
      _state = CameraState.capturing;
      notifyListeners();

      final xFile = await _controller!.takePicture();
      if (_disposed || generation != _captureGeneration) return;
      _capturedImagePath = xFile.path;

      _state = CameraState.processing;
      notifyListeners();

      final imageBytes = await File(xFile.path).readAsBytes();
      final report = await _detector.detect(imageBytes);
      if (_disposed || generation != _captureGeneration) return;
      _report = report;
      _detections = report.detections;

      _state = CameraState.results;
      notifyListeners();
    } catch (e) {
      if (_disposed || generation != _captureGeneration) return;
      _errorMessage = 'Detection failed: $e';
      _state = CameraState.error;
      notifyListeners();
    }
  }

  Future<void> setFocusPoint(Offset normalizedPoint) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setFocusPoint(normalizedPoint);
    } catch (_) {
      // Some devices don't support tap focus
    }
    try {
      await _controller!.setExposurePoint(normalizedPoint);
    } catch (_) {
      // Some devices don't support tap exposure
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
    _detections = [];
    _capturedImagePath = null;
    _state = _controller == null && _initializing != null
        ? CameraState.uninitialized
        : CameraState.preview;
    notifyListeners();
  }

  void pausePreview() {
    if (_disposed) return;
    _generation++;
    _controller?.dispose();
    _controller = null;
    if (_state == CameraState.preview) {
      _state = CameraState.uninitialized;
      notifyListeners();
    }
  }

  void resumePreview() {
    if (_disposed) return;
    if (_controller == null &&
        (_state == CameraState.uninitialized ||
            _state == CameraState.preview)) {
      initializeCamera();
    }
  }

  Future<void> requestPermissionAgain() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    if (status.isGranted) {
      await initializeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive && _controller != null) {
      pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      resumePreview();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _captureGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }
}
