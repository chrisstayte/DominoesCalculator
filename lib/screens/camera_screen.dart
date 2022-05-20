import 'package:camera/camera.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/widgets/permission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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

    await Permission.camera.request().then((result) {
      if (result.isGranted) {
        hasAccessToCamera = true;
      }
    });

    if (hasAccessToCamera) {
      try {
        _cameras = await availableCameras();
        if (_cameras.length < 1) {
          await showDialog(
            context: context,
            builder: (builder) {
              return AlertDialog(
                title: Text('Your device has no cameras available'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'))
                ],
              );
            },
          );
          Navigator.pop(context);
          return;
        }

        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _controller?.initialize().then((value) async {
          await _controller
              ?.lockCaptureOrientation((DeviceOrientation.portraitUp));
          if (mounted) {}
        }).onError((error, stackTrace) {
          debugPrint('camera initalize error: ${error?.toString()}');
        });
      } catch (_) {}
    } else {
      showGeneralDialog(
        context: context,
        pageBuilder: (_, __, ___) {
          return PermissionDialog(
            hasAccessToCamera: hasAccessToCamera,
          );
        },
        transitionBuilder: (_, anim, __, child) {
          Tween<Offset> tween;
          if (anim.status == AnimationStatus.reverse) {
            tween = Tween(begin: Offset(0, 1), end: Offset.zero);
          } else {
            tween = Tween(begin: Offset(0, 1), end: Offset.zero);
          }

          return SlideTransition(
            position: tween.animate(anim),
            child: FadeTransition(
              opacity: anim,
              child: child,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
    );
  }
}
