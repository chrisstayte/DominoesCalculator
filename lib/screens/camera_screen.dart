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

  bool isProcessing = false;
  List<dynamic>? recognitions = [];

  final int _points = 0;

  Future<File?> getFile(String fileName) async {
    try {
      // Get the temporary directory for the app
      final appDir = await getTemporaryDirectory();
      final appPath = appDir.path;

      // Create a File object for the file on the device
      final fileOnDevice = File('$appPath/$fileName');

      // Load the asset file and convert it to a Uint8List
      final rawAssetFile = await rootBundle.load(fileName);
      final rawBytes = rawAssetFile.buffer.asUint8List();

      // Write the Uint8List to the file on the device
      await fileOnDevice.writeAsBytes(rawBytes, flush: true);

      // Return the File object wrapped in a Future
      return fileOnDevice;
    } catch (e) {
      // Handle any errors that occur during the file operations
      print('Error getting file: $e');
      return null;
    }
  }

  @override
  void initState() async {
    WidgetsBinding.instance.addObserver(this);

    // Tflite.loadModel(
    //   model: "assets/lite-model_ssd_mobilenet_v1_1_metadata_2",
    //   labels: "assets/ssd_mobilenet.txt",
    // );

    _setupCamera();
    super.initState();
  }

  @override
  void dispose() async {
    // Remove this widget as an observer of the widget tree
    WidgetsBinding.instance.removeObserver(this);

    // Dispose of the camera controller
    _controller?.dispose();

    // Set the camera controller to null
    _controller = null;

    // Call the superclass dispose method
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
      case AppLifecycleState.detached:
      // TODO: Handle this case.
      case AppLifecycleState.inactive:
      // TODO: Handle this case.
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
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
            if (!isProcessing) {
              isProcessing = true;
              // Interpreter interpreter = await Interpreter.fromAsset(
              //     'assets/lite-model_ssd_mobilenet_v1_1_metadata_2');

              // TFL
              // interpreter
              //     .runSegmentationOnImage(
              //   imageBytes: image.planes.map((plane) {
              //     return plane.bytes;
              //   }).toList(),
              //   imageWidth: image.width,
              //   imageHeight: image.height,
              //   numResults: 1,
              //   threshold: 0.5,
              // )
              //     .then((results) {
              //   setState(() {
              //     segments = results;
              //   });
              // });
              // Tflite.detectObjectOnFrame(
              //   bytesList: image.planes.map((plane) {
              //     return plane.bytes;
              //   }).toList(),
              //   model: "assets/ssd_mobilenet.tflite",
              //   imageHeight: image.height,
              //   imageWidth: image.width,
              //   imageMean: 127.5,
              //   imageStd: 127.5,
              //   numResultsPerClass: 1,
              //   threshold: 0.4,
              // ).then((results) {
              //   setState(() {
              //     recognitions = results;
              //   });
              // });
              isProcessing = false;
            }
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
                                  'Points: $_points ${recognitions?.length}',
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
