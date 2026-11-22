# Mobile integration: detector v2 and classifier v3

The camera is currently parked outside the app build. See the
[restore steps](../dormant/camera/README.md) before using the camera-specific
build and verification instructions below. The results recorded here describe
the earlier camera-enabled integration.

The dormant Flutter camera implementation performs tile detection, perspective
rectification and pip classification on device. Both interpreters, image decoding and crop work
run on a persistent background isolate. No photo upload is required.

The detector weights were exported without retraining, using Ultralytics
8.4.144, Torch 2.9.0, litert-torch 0.9.0 and ai-edge-litert 2.1.4:

```python
from ultralytics import YOLO
YOLO("best.pt").export(format="litert", quantize=32, imgsz=640,
                       batch=1, device="cpu")
```

The camera-enabled build used the FP16 export of `pips-v3-mnv2-mixed-01`. The tensor contracts
and exact SHA-256 hashes are in `assets/models/domino_models.json`. Preprocessing
must preserve the different detector and classifier input ranges.

## Verification

- Original detector and mobile export, same five frozen validation photos / 124
  instances and square 640 preprocessing: both mAP50 0.995 and mAP50–95
  0.9696750568. These are validation scores, not general full-photo accuracy.
- Classifier FP16 and FP32 exports retain all Keras argmax predictions on the
  248 original validation halves (247/248 correct) and the 36 reviewed challenge
  pairs. The selected classifier previously improved reviewed challenge pairs
  from 18/36 to 29/36 on the frozen detector crops.
- Native Flutter inference processed all seven existing challenge photos. It
  found the same tile counts as the Python LiteRT pipeline with identical square
  input dimensions. Full-photo pipelines can change crop geometry and predictions
  slightly with resize rounding; this is not a claim of identical photo totals.
- For all 173 detected tile crops, Dart and OpenCV rectification/classification
  produced the same unordered pip pairs when given the same corners. Matching
  NumPy float32 long-edge selection is necessary: floating-point ties can rotate
  a crop 180 degrees.
- Local host CPU processing, including image decoding, inference and display
  encoding, took approximately 0.09–0.8 seconds per existing test photo. This is
  not an iPhone performance benchmark.
- Flutter tests cover rotated decoding/NMS, portrait letterboxing, RGB splitting,
  degenerate crops, blank scoring, unreadable results, and appending values to an
  existing calculator. An opt-in native smoke test loads the actual assets,
  checks error recovery and can run private photos outside the repository.

The unchanged detector still misses the two known white-background challenge
photos. Crossing tiles and false detections also remain possible. Results show
rotated outlines and require explicit review of selected tiles. Model confidence
is available in settings. Unreadable tiles produce a subtotal and
cannot transfer to the calculator until corrected and confirmed. Blanks stay class 0 and are scored using the
current 0/25/50 setting. Existing calculator values are preserved when adding. The [camera review flow](camera-review.md)
adds only selected, confirmed tiles and supports correcting or excluding detections.

## Local iPhone test build

```sh
flutter build ios --profile
```

The camera is currently removed from the app, pending licensing: its code is
parked in `dormant/camera/` (outside the build) with restore steps in its README,
and the camera plugins, permissions and model assets are not shipped. When
restoring the camera, keep CocoaPods enabled for the pinned flutter_litert 1.4.0
plugin: its Swift package is a stub without the native inference libraries.
The project explicitly selects CocoaPods in pubspec.yaml.

Before a device update, back up its app preferences privately. Install the same
bundle identifier without uninstalling so preferences and saved games remain.
Physical iPhone initialization and a capture completed successfully. The full
camera-enabled Flutter suite, including native model loading, passed 54 tests.
App preferences were compared privately before and after installation; all
original app preference values were preserved.

Wireless installation and launching work after USB pairing. Stop Device Hub
screen sharing using More Actions → Stop Screen Sharing before testing the
camera directly on the phone. In the device check, both Dominoes and the
built-in Camera were blank during screen sharing; the user confirmed that the
camera worked after screen sharing stopped. Do not unpair to end screen sharing.
Signing metadata and device identifiers do not belong in this public document.
No store release is part of this change.

## Native verification and rollback

```sh
flutter analyze --no-fatal-infos
flutter test
DOMINO_NATIVE_MODEL_TEST=1 flutter test test/services/domino_pipeline_test.dart  # after restoring dormant/camera
```

For a local private comparison, set `DOMINO_PRIVATE_TEST_PHOTOS` to an external
JSON file containing photo paths. The test writes results under `/tmp`, never
inside this repository. Native model tests are opt-in because CI hosts need the
appropriate native runtime library.

The training data, original checkpoints and split manifests are untouched.
The preceding dev revision is `03b99128b6f19d231b6d65e1060e713feb5e1053`.
Revert the integration commit to restore the previous app pipeline. Model
replacement is explicit: update the asset, hash and contract together and rerun
validation. Publishing the combined app is pending the owner's license choice;
including an upstream model notice does not change the app's own license.
