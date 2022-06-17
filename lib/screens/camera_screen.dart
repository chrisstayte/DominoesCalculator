import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/widgets/permission_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  Uint8List? _byte;

  final int _points = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
    super.initState();
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
    }
    super.didChangeAppLifecycleState(state);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
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
        if (_cameras.isEmpty) {
          await showDialog(
            context: context,
            builder: (builder) {
              return AlertDialog(
                title: const Text('Your device has no cameras available'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'))
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
          _controller?.startImageStream((image) async {
            // Uint8List bytes = _concatenatePlanes(image.planes);
            // XFile img = XFile.fromData(bytes);
            // Directory dir = await getApplicationDocumentsDirectory();
            // String dirName = dir.path;
            // String imgPath = dirName + '/original.jpg';
            // await img.saveTo(imgPath);
            // await Cv2.cvtColor(
            //         pathString: imgPath, outputType: Cv2.COLOR_BGR2GRAY)
            //     .then((grayImageBytes) async {
            //   img = XFile.fromData(grayImageBytes!);
            //   imgPath = dirName + '/gray.jpg';
            //   await img.saveTo(imgPath);
            //   Cv2.threshold(
            //           pathString: imgPath,
            //           thresholdValue: 0,
            //           maxThresholdValue: 255,
            //           thresholdType: Cv2.THRESH_BINARY_INV)
            //       .then((thresh) {
            //     // img = XFile.fromData(thresh);
            //     setState(() {
            //       _byte = thresh;
            //     });
            //     // imgPath = dirName + '/thresh.jpg';
            //     // img.saveTo(imgPath);
            //   });
            // });
          });
          if (mounted) {
            setState(() {});
          }
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
            tween = Tween(begin: const Offset(0, 1), end: Offset.zero);
          } else {
            tween = Tween(begin: const Offset(0, 1), end: Offset.zero);
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
      body: _controller?.value.isInitialized ?? false
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    height: 40,
                  ),
                  Container(
                    padding: const EdgeInsets.all(0),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Global.ui.cornerRadius),
                    ),
                    child: Stack(
                      children: [
                        CameraPreview(
                          _controller!,
                        ),
                        Positioned.fill(
                          top: 15,
                          child: Align(
                            alignment: AlignmentDirectional.topCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    Global.ui.cornerRadius),
                                color: context
                                    .watch<SettingsProvider>()
                                    .appAccentColor,
                              ),
                              height: 35,
                              width: 155,
                              child: Center(
                                child: Text(
                                  'Points: $_points',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _byte != null ? Image.memory(_byte!) : SizedBox()
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Global.ui.cornerRadius,
                        ),
                        color: Colors.red.shade400,
                      ),
                      child: const Center(
                        child: Text(
                          'Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
