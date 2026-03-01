import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dominoes/providers/camera_provider.dart';
import 'package:dominoes/services/sfx_service.dart';
import 'package:dominoes/services/vibration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:dominoes/widgets/action_button.dart';
import 'package:dominoes/widgets/capture_button.dart';
import 'package:dominoes/widgets/section_card.dart';
import 'package:dominoes/widgets/segmented_control.dart';
import 'package:dominoes/widgets/setting_row.dart';
import 'package:dominoes/widgets/detection_overlay.dart';
import 'package:dominoes/widgets/camera_loading_view.dart';
import 'package:dominoes/widgets/dot_grid_painter.dart';
import 'package:dominoes/widgets/permission_denied_view.dart';
import 'package:dominoes/widgets/viewfinder_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  DeviceOrientation _deviceOrientation = DeviceOrientation.portrait;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  @override
  void initState() {
    super.initState();
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen(_onAccelerometerEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CameraProvider>();
      if (provider.state == CameraState.uninitialized) {
        provider.initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    super.dispose();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final x = event.x;
    final y = event.y;

    DeviceOrientation orientation;
    if (y.abs() > x.abs()) {
      orientation = y > 0
          ? DeviceOrientation.portrait
          : DeviceOrientation.upsideDown;
    } else {
      orientation = x < 0
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.landscapeRight;
    }

    if (orientation != _deviceOrientation) {
      setState(() => _deviceOrientation = orientation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final camera = context.watch<CameraProvider>();
    final settings = context.watch<LocalSettingsProvider>().localSettings;

    return Scaffold(
      appBar: AppBar(
        title: Transform(
          transform: Matrix4.skewX(-0.15),
          child: Container(
            color: nbt.headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'DETECT',
              style: GoogleFonts.bricolageGrotesque(
                color: nbt.headerTextColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        centerTitle: true,
        leading: kDebugMode
            ? IconButton(
                icon: SvgPicture.asset(
                  'assets/images/icons/bug.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(nbt.iconColor, BlendMode.srcIn),
                ),
                onPressed: () => _showLabelsDialog(context, nbt),
              )
            : null,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/icons/sliders.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(nbt.iconColor, BlendMode.srcIn),
            ),
            onPressed: () => _showDetectSettingsDialog(context, nbt),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: nbt.borderColor, height: 3),
        ),
      ),
      body: switch (camera.state) {
        CameraState.uninitialized => CameraLoadingView(
          accentColor: settings.appAccentColor.color,
        ),
        CameraState.permissionDenied => PermissionDeniedView(
          onRequestPermission: () => camera.requestPermissionAgain(),
        ),
        CameraState.preview => _buildPreview(
          camera,
          nbt,
          settings.appAccentColor.color,
        ),
        CameraState.capturing ||
        CameraState.processing => _buildProcessing(camera, nbt),
        CameraState.results => _buildResults(
          camera,
          nbt,
          settings.showConfidence,
          settings.appAccentColor.color,
        ),
        CameraState.error => _buildError(camera, nbt),
      },
    );
  }

  Future<void> _showLabelsDialog(
    BuildContext context,
    NeoBrutalistTheme nbt,
  ) async {
    final labelsData = await rootBundle.loadString(
      'assets/models/coco_labels.txt',
    );
    final labels = labelsData
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '???')
        .toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: nbt.borderColor, width: 3),
        ),
        backgroundColor: nbt.cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: nbt.headerColor,
              padding: const EdgeInsets.all(12),
              child: Text(
                'MODEL LABELS (${labels.length})',
                style: GoogleFonts.bricolageGrotesque(
                  color: nbt.headerTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: labels.length,
                separatorBuilder: (_, __) => Divider(
                  color: nbt.borderColor.withValues(alpha: 0.2),
                  height: 1,
                ),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    labels[index].toUpperCase(),
                    style: GoogleFonts.bricolageGrotesque(
                      color: nbt.bodyTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetectSettingsDialog(BuildContext context, NeoBrutalistTheme nbt) {
    final provider = context.read<LocalSettingsProvider>();

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<LocalSettingsProvider>(
          builder: (context, provider, _) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 48,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: nbt.cardColor,
                border: Border.all(color: nbt.borderColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: nbt.shadowColor,
                    offset: const Offset(6, 6),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    color: nbt.headerColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'DETECT_SETTINGS',
                            style: GoogleFonts.bricolageGrotesque(
                              color: nbt.headerTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.close,
                            color: nbt.headerTextColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SettingRow(
                    label: 'CONFIDENCE',
                    child: SegmentedControl<bool>(
                      options: const [true, false],
                      labels: const ['ON', 'OFF'],
                      selected: provider.localSettings.showConfidence,
                      onSelected: provider.setShowConfidence,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(
    CameraProvider camera,
    NeoBrutalistTheme nbt,
    Color accentColor,
  ) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: nbt.borderColor, width: 3),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: camera.controller!.value.previewSize!.height,
                        height: camera.controller!.value.previewSize!.width,
                        child: CameraPreview(camera.controller!),
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  painter: ViewfinderOverlay(
                    color: accentColor,
                    label: 'TARGET',
                    deviceOrientation: _deviceOrientation,
                  ),
                ),
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: DotGridPainter(
            backgroundColor: nbt.dotGridBackground,
            dotColor: nbt.dotGridDotColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CaptureButton(
                onTap: () {
                  context.read<SfxService>().playCapture();
                  context.read<VibrationService>().medium();
                  camera.captureAndDetect();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing(CameraProvider camera, NeoBrutalistTheme nbt) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (camera.capturedImagePath != null)
                Image.file(File(camera.capturedImagePath!), fit: BoxFit.cover),
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: nbt.accentYellow,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Transform(
                        transform: Matrix4.skewX(-0.15),
                        child: Container(
                          color: nbt.headerColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            'PROCESSING...',
                            style: GoogleFonts.bricolageGrotesque(
                              color: nbt.headerTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    CameraProvider camera,
    NeoBrutalistTheme nbt,
    bool showConfidence,
    Color accentColor,
  ) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (camera.capturedImagePath != null)
                Image.file(File(camera.capturedImagePath!), fit: BoxFit.cover),
              CustomPaint(
                painter: DetectionOverlay(
                  detections: camera.detections,
                  borderColor: accentColor,
                  textColor: Colors.black,
                  badgeColor: accentColor,
                  showConfidence: showConfidence,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: nbt.cardColor,
            border: Border(top: BorderSide(color: nbt.borderColor, width: 3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (camera.detections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: nbt.cardColor,
                      border: Border.all(color: nbt.borderColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: nbt.headerColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'DETECTED (${camera.detections.length})',
                            style: GoogleFonts.bricolageGrotesque(
                              color: nbt.headerTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        ...camera.detections.map(
                          (d) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    d.label.toUpperCase(),
                                    style: GoogleFonts.bricolageGrotesque(
                                      color: nbt.bodyTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (showConfidence)
                                  Text(
                                    '${(d.confidence * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.bricolageGrotesque(
                                      color: nbt.secondaryTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'NO OBJECTS DETECTED',
                    style: GoogleFonts.bricolageGrotesque(
                      color: nbt.secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        icon: Icons.refresh,
                        color: nbt.accentRed,
                        foregroundColor: Colors.black,
                        onTap: () {
                          context.read<SfxService>().playDelete();
                          context.read<VibrationService>().medium();
                          camera.retake();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        icon: Icons.check,
                        color: nbt.accentGreen,
                        foregroundColor: Colors.black,
                        onTap: () {
                          context.read<SfxService>().playSuccess();
                          context.read<VibrationService>().medium();
                          // Placeholder for future calculator integration
                          camera.retake();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(CameraProvider camera, NeoBrutalistTheme nbt) {
    return CustomPaint(
      painter: DotGridPainter(
        backgroundColor: nbt.dotGridBackground,
        dotColor: nbt.dotGridDotColor,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: nbt.accentRed),
              const SizedBox(height: 16),
              Text(
                'ERROR',
                style: GoogleFonts.bricolageGrotesque(
                  color: nbt.bodyTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                camera.errorMessage ?? 'An unexpected error occurred.',
                style: GoogleFonts.bricolageGrotesque(
                  color: nbt.secondaryTextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  icon: Icons.refresh,
                  color: nbt.accentYellow,
                  foregroundColor: Colors.black,
                  onTap: () => camera.initializeCamera(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
