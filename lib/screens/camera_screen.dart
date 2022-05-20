import 'dart:html';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChaBROOOngeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _controller?.dispose();
        _controller = null;

        break;
      case AppLifecycleState.resumed:
        _setupCamera();
        break;
      case AppLifecycleState.inactive:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.detached:
        // TODO: Handle this case.
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _setupCamera() async {
    // Permissions
    bool hasAccessToCamera = false;

    Permission.camera.request().then((result) {
      if (result.isGranted) {
        hasAccessToCamera = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
