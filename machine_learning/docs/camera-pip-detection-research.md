# Camera-Based Domino Pip Detection Research

> On-device processing only. No cloud APIs. Full offline support.

---

## Table of Contents

1. [Flutter Camera Packages](#1-flutter-camera-packages)
2. [On-Device ML / Computer Vision Options](#2-on-device-ml--computer-vision-options)
3. [Detection Approach Analysis](#3-detection-approach-analysis)
4. [Required Flutter Packages](#4-required-flutter-packages)
5. [Model Training](#5-model-training)
6. [Architecture Recommendations](#6-architecture-recommendations)
7. [Alternative Approaches](#7-alternative-approaches)
8. [Recommended Stack Summary](#8-recommended-stack-summary)

---

## 1. Flutter Camera Packages

### Primary: `camera` (Official Flutter Plugin)

- **Package**: [camera](https://pub.dev/packages/camera) `^0.11.1`
- Actively maintained by the Flutter team
- iOS, Android, Web support
- `startImageStream()` provides live `CameraImage` frames (YUV420 or BGRA8888)
- `takePicture()` for single image capture
- Flash, exposure, focus control built-in
- Android recently migrated to CameraX backend for better device compatibility

### Alternatives

| Package | Notes |
|---------|-------|
| [`camerawesome`](https://pub.dev/packages/camerawesome) | Highly customizable UI, built-in ML Kit support |
| [`multicamera`](https://pub.dev/packages/multicamera) | Multiple camera instances with ML Kit support |

**Recommendation**: Use the official `camera` package. For our use case (capture-then-process), `takePicture()` is all we need.

---

## 2. On-Device ML / Computer Vision Options

### Option A: Google ML Kit

- **Package**: [`google_mlkit_object_detection`](https://pub.dev/packages/google_mlkit_object_detection) `^0.14.0`
- Fully offline, on-device
- iOS and Android only (no desktop/web)
- Supports loading custom `.tflite` models
- Handles image format conversion internally
- ~30 FPS on modern devices for built-in models
- **Cons**: Mobile-only, community-maintained Flutter plugin, custom model must conform to ML Kit's tensor format

### Option B: TensorFlow Lite / LiteRT

- **Package**: [`flutter_litert`](https://pub.dev/packages/flutter_litert) `^1.1.0` (successor to `tflite_flutter`)
- Fully offline, on-device
- **Cross-platform**: Android, iOS, macOS, Windows, Linux, Web
- Direct Dart FFI bindings to the LiteRT C API
- GPU delegate (Metal on iOS, GPU on Android), XNNPACK for CPU
- `IsolateInterpreter` runs inference off the main thread
- **Cons**: You handle preprocessing and output parsing yourself

### Option C: Ultralytics YOLO Flutter Plugin

- **Package**: [`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) `^0.0.6`
- Fully offline, on-device
- Android and iOS
- Wraps YOLO models via platform channels (CoreML on iOS, TFLite on Android)
- Built-in real-time camera integration
- **Cons**: Tied to Ultralytics ecosystem, relatively newer

### Option D: OpenCV via `opencv_dart`

- **Package**: [`opencv_dart`](https://pub.dev/packages/opencv_dart) `^1.4.0`
- Fully offline, on-device
- Android, iOS, macOS, Windows, Linux
- Full OpenCV 4.x functionality (thresholding, contour detection, HoughCircles, blob detection)
- Can also load ONNX/TFLite models via DNN module
- **Cons**: Marked as WIP, traditional CV is sensitive to lighting/angle/style variations

### Option E: Apple Vision / Core ML (iOS Only)

- Via platform channels or [`apple_vision`](https://pub.dev/packages/apple_vision)
- Exceptional performance on Apple hardware (Neural Engine)
- **Cons**: iOS-only, requires Swift platform channel code, needs `.mlmodel` format

### Not Recommended

| Option | Why |
|--------|-----|
| **Google MediaPipe** | No official Flutter plugin, strengths are face/hand/pose detection, not object detection |
| **PyTorch Mobile / ExecuTorch** | Poorly maintained Flutter plugins, TFLite ecosystem has much better Flutter support |

---

## 3. Detection Approach Analysis

### Approach 1: Traditional Computer Vision (No ML)

**Pipeline**: Grayscale -> Blur -> Adaptive Threshold -> Contour Detection -> HoughCircles/BlobDetector

- No model training required, small binary size
- **Very sensitive** to lighting, shadows, angles, domino color
- Works in controlled conditions (white surface, overhead camera, good lighting)
- Fails in real-world variability
- **Verdict**: Not recommended as primary approach

### Approach 2: ML-Based Object Detection (Recommended)

**Pipeline**: YOLO/SSD model detects domino tiles -> crop each tile -> classify each half (0-12 pips)

- Robust to lighting, angle, and color variations
- Can handle multiple dominos in a single frame
- Real-time capable with YOLO-nano variants
- Transfer learning from COCO-pretrained models reduces training data needs
- **Verdict**: Most robust and practical for production

### Approach 3: Hybrid (ML Detection + CV Pip Counting)

**Pipeline**: ML detects and localizes tiles -> crop and normalize -> traditional CV counts pips in each half

- Smaller ML model (only detects tiles, doesn't classify pips)
- CV pip counting is reliable when the region is already cropped
- **Verdict**: Good middle-ground, reduces training complexity

### Recommended: ML-Based with Classification

1. **YOLOv11-nano** model trained on domino images
2. Detect each domino tile (bounding box)
3. Split each tile into two halves
4. Lightweight classifier (or blob detection) counts pips per half
5. Sum for scoring

---

## 4. Required Flutter Packages

### Core Dependencies

```yaml
dependencies:
  # Camera access
  camera: ^0.11.1

  # ML inference (choose one):
  flutter_litert: ^1.1.0                   # Cross-platform, most flexible
  # google_mlkit_object_detection: ^0.14.0  # Mobile-only, higher-level API
  # ultralytics_yolo: ^0.0.6               # If using YOLO models directly

  # Image processing
  image: ^4.5.3                            # Resize, crop, format conversion
  path_provider: ^2.1.5                    # Device filesystem access
  permission_handler: ^11.3.1              # Camera permissions

  # Optional: for hybrid approach
  # opencv_dart: ^1.4.0                    # Blob detection for pip counting
```

### Package Comparison

| Package | Offline | iOS | Android | Desktop | Model Format | Complexity |
|---------|---------|-----|---------|---------|-------------|------------|
| `google_mlkit_object_detection` | Yes | Yes | Yes | No | .tflite | Low |
| `flutter_litert` | Yes | Yes | Yes | Yes | .tflite | Medium |
| `ultralytics_yolo` | Yes | Yes | Yes | No | .mlmodel/.tflite | Low |
| `opencv_dart` | Yes | Yes | Yes | Yes | N/A | High |

---

## 5. Model Training

### Existing Domino Datasets (Roboflow Universe)

| Dataset | Images | Notes |
|---------|--------|-------|
| [Double Twelve Dominoes (rsrvr)](https://universe.roboflow.com/rsrvr/double-twelve-dominoes-lmkit/dataset/2) | 1,058 | Largest available |
| [Domino Counter (Elden Jahnke)](https://universe.roboflow.com/elden-jahnke-snkp7/domino-counter/dataset/1) | 590 | Good pip annotations |
| [YOLO11 Domino Counter](https://universe.roboflow.com/dominoes-counter/yolo11-domino-counter/dataset/1) | 211 | Already YOLO11 formatted |
| [Double Twelve (Pip Tracker)](https://universe.roboflow.com/pip-tracker/double-twelve-dominoes/dataset/2) | 146 | Smaller but annotated |

### Training Data Requirements

| Quality Level | Images Needed |
|---------------|---------------|
| Minimum viable (fine-tuning) | 500 - 1,000 |
| Good quality | 2,000 - 5,000 |
| Excellent quality | 5,000 - 10,000+ |

**Key variation factors**: domino color (white, black, ivory, colored), pip color, background surface, lighting (daylight, indoor, shadows), angle, domino set type (double-6, double-9, double-12).

### Synthetic Data Generation

- **Blender** (free): 3D domino models, render thousands of images with randomized backgrounds, lighting, and angles
- **Unity Perception / SynthDet** (free): End-to-end synthetic pipeline with Domain Randomization, auto-exports in COCO/YOLO formats
- **Roboflow**: Augmentation on existing datasets (rotation, brightness, crop, noise, mosaic)

### Training Pipeline

```
1. Collect data
   -> Roboflow datasets + synthetic renders + real photos

2. Annotate
   -> Roboflow (web-based) or CVAT (open source)

3. Train
   -> Ultralytics YOLOv11-nano
   -> Google Colab (free GPU) or local GPU
   -> yolo detect train model=yolo11n.pt data=dominos.yaml epochs=100 imgsz=640

4. Export to TFLite
   -> yolo export model=best.pt format=tflite int8=True
   -> Produces quantized .tflite file (typically 3-8MB)

5. Export to CoreML (iOS optimization)
   -> yolo export model=best.pt format=coreml nms=True

6. Validate on real-world test images

7. Bundle .tflite in Flutter app assets/models/
```

---

## 6. Architecture Recommendations

### Capture-Then-Process (Recommended for MVP)

| Factor | Real-Time (Stream) | Capture-Then-Process |
|--------|-------------------|---------------------|
| UX | Live bounding boxes on camera feed | Take photo, see results in 1-2s |
| Complexity | High (frame throttling, async inference) | Low (single image, single inference) |
| Performance | Continuous 10-30 FPS inference | Single inference per capture |
| Battery | Higher (continuous processing) | Minimal |
| Accuracy | Lower resolution for speed | Full-resolution image |

**Why capture-then-process**: Domino Calc is a scoring calculator, not a live AR experience. Users capture a moment (end of a round). Simpler to build, higher accuracy, lower battery use. Can add real-time preview later.

### Proposed User Flow

1. User taps "Camera" tab
2. Camera preview opens (live preview, no ML running)
3. User positions dominos in frame
4. User taps shutter button
5. App processes captured image (loading indicator, 0.5-2s)
6. Results overlay: detected dominos highlighted with pip counts
7. User confirms or manually adjusts any incorrect counts
8. Score is added to the game

### Performance Targets

| Model | Size | Inference Time |
|-------|------|---------------|
| YOLOv11-nano (INT8 TFLite) | ~3-4MB | ~15-30ms |
| MobileNet-SSD v2 | ~4MB | ~20-40ms |
| EfficientDet-Lite0 | ~4.4MB | ~25-50ms |

### Optimization Tips

- Use `IsolateInterpreter` (from `flutter_litert`) for off-main-thread inference
- iOS: Metal delegate for GPU acceleration
- Android: XNNPACK delegate for CPU, or GPU delegate
- INT8 quantization: ~75% size reduction, faster inference, minimal accuracy loss

### iOS vs Android Differences

| Aspect | iOS | Android |
|--------|-----|---------|
| Camera format | BGRA8888 | YUV420 (needs conversion) |
| Hardware accel | Metal + Neural Engine | NNAPI, GPU delegate, XNNPACK |
| Optimal model | CoreML (`.mlmodel`) | TFLite (`.tflite`) |
| Performance | Generally faster (Neural Engine) | Varies by device |
| Permissions | `NSCameraUsageDescription` in Info.plist | `CAMERA` in AndroidManifest.xml |

### Proposed File Structure

```
lib/
  features/
    camera/
      camera_screen.dart              # Camera preview + capture UI
      camera_controller.dart          # Camera lifecycle management
      detection/
        domino_detector.dart          # Abstract interface
        tflite_detector.dart          # LiteRT/TFLite implementation
        detection_result.dart         # Data classes for results
      processing/
        image_preprocessor.dart       # Resize, normalize, format convert
        result_postprocessor.dart     # Parse model output -> DominoTile objects
      widgets/
        detection_overlay.dart        # Draw bounding boxes + pip counts
        capture_button.dart
        result_confirmation.dart      # Let user confirm/edit detected score

assets/
  models/
    domino_detector.tflite            # ~3-8MB quantized model
    labels.txt                        # Class labels
```

---

## 7. Alternative Approaches

### Template Matching

Pre-store templates of each pip config, match against detected halves. Simple but extremely sensitive to scale, rotation, and style. Not practical.

### Classification-Only (No Detection)

User frames a single domino within a guide overlay, classify the whole cropped image. Simpler model but slow workflow for multiple dominos.

### Two-Model Pipeline

Model 1 (YOLO-nano) detects tiles, Model 2 (MobileNet classifier) classifies each half (13 classes: 0-12 pips). Each model is simpler and more accurate at its task. Slightly more complex pipeline.

---

## 8. Recommended Stack Summary

| Component | Package/Tool | Rationale |
|-----------|-------------|-----------|
| Camera | `camera` | Official, stable, capture support |
| ML Inference | `flutter_litert` | Cross-platform, flexible, modern |
| Model | YOLOv11-nano -> `.tflite` | Best speed/accuracy for mobile |
| Image Processing | `image` | Dart-native resize/crop/normalize |
| OpenCV (optional) | `opencv_dart` | Hybrid pip counting if needed |
| Permissions | `permission_handler` | Camera permission management |
| Training | Ultralytics + Roboflow | YOLOv11 training, existing datasets |
| Training data | Roboflow Universe + Blender synthetic | 1K+ real + 5K+ synthetic images |

### Phased Implementation Plan

**Phase 1 (MVP)**:
- `camera` package for capture-then-process
- `flutter_litert` with YOLOv11-nano model
- Detect tiles, count pips, present for user confirmation
- Bundle single `.tflite` model (~4-6MB)

**Phase 2 (Enhancement)**:
- Real-time preview with bounding box overlay
- Platform-specific optimization (CoreML on iOS)
- Improved model with more training data

**Phase 3 (Polish)**:
- AR overlay showing pip counts on live feed
- Multi-domino batch scanning
- Support for different set types (double-6, double-9, double-12)

---

## Competitive Landscape

| App | Platform | Approach | Installs |
|-----|----------|----------|----------|
| Domino Dot Counter | Android | Camera auto-count | 100K+ |
| Domino Scan | iOS/Android | Real-time AR | - |
| Domino Adder | iOS | Camera-based scoring | - |
| Domino Counter | iOS | Capture-based counting | 100K+ |

**Common user complaints**: accuracy drops with 20+ pips visible, colored pips cause issues, image stability matters. A well-trained ML model with capture-based (not real-time) approach addresses these.
