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
  final ObjectDetector _detector = TfliteDetector();
  CameraState _state = CameraState.uninitialized;
  List<DetectionResult> _detections = [];
  String? _capturedImagePath;
  String? _errorMessage;

  CameraController? get controller => _controller;
  CameraState get state => _state;
  List<DetectionResult> get detections => List.unmodifiable(_detections);
  String? get capturedImagePath => _capturedImagePath;
  String? get errorMessage => _errorMessage;

  CameraProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _state = CameraState.permissionDenied;
        notifyListeners();
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No cameras available on this device.';
        _state = CameraState.error;
        notifyListeners();
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _detector.initialize();

      _state = CameraState.preview;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _state = CameraState.error;
      notifyListeners();
    }
  }

  Future<void> captureAndDetect() async {
    if (_state != CameraState.preview || _controller == null) return;

    try {
      _state = CameraState.capturing;
      notifyListeners();

      final xFile = await _controller!.takePicture();
      _capturedImagePath = xFile.path;

      _state = CameraState.processing;
      notifyListeners();

      final imageBytes = await File(xFile.path).readAsBytes();
      _detections = await _detector.detect(imageBytes);

      _state = CameraState.results;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Detection failed: $e';
      _state = CameraState.error;
      notifyListeners();
    }
  }

  void retake() {
    _detections = [];
    _capturedImagePath = null;
    _state = CameraState.preview;
    notifyListeners();
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
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_state == CameraState.preview || _state == CameraState.uninitialized) {
        initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }
}
