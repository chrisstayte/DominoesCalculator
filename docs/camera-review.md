# Camera scanning and reviewing your tiles

The camera tab is always shown. For a local device build:

```sh
flutter run --profile
```

Keep Device Hub screen sharing stopped when using the physical iPhone camera.
The phone can remain paired and receive wireless builds. Screen sharing caused
both the app and the built-in Camera to show a blank feed during device testing.

## Scan, capture, review

1. Point the camera at the dominoes. Live rotated boxes show tiles found by the
   detector. The scan line and live tile count stay visible while aiming.
2. Tap the shutter. Live scanning stops, a full photo is processed with both
   models, and the camera closes while you review the result.
3. The photo and list use the same stable tile numbers. Tap a tile in the photo,
   its pips in the list, or its checkbox to mark it as yours. Green boxes are
   yours; yellow boxes are other tiles. Tapping a photo box also scrolls its
   numbered row into view.
4. Choose **YES** when a tile's values are correct. **NO · EDIT** opens the two
   half-value controls, including blank (0). Saving a correction confirms it.
   A false detection can be excluded there and restored with **UNDO**. Excluding
   a tile keeps the remaining numbers stable.
5. Pinch to zoom and drag to pan the photo. The minus, fit and plus controls are
   also available. Boxes and touch targets move with the photo. Number badges
   sit above tiles and keep a constant screen size while zooming; pip values
   stay in the list so the photo remains clear.
6. **ADD N TILES** appends only your selected, confirmed tiles to the calculator.
   It stays disabled when none are selected or a selected tile needs values
   confirmed. Existing calculator entries remain. Duplicate taps cannot add the
   same reviewed photo twice.

All tiles start unselected and unconfirmed. The score shown during review counts
only confirmed selections, applying the current blank value. **ALL MINE** is a
selection shortcut; it does not confirm predictions. **CLEAR** removes selection.
Corrections affect this photo's score only, not the source predictions, model,
training labels, original photos, saved game logs or training data.

## Performance and validation

Live scanning uses the unchanged detector only. It accepts at most one frame at
a time and starts no more than four scans per second; actual speed depends on
the device. Incoming frames are dropped while a scan is busy. BGRA and YUV plane
strides are respected and portrait rotation is applied before inference. Live
frames are reduced to detector size in the background worker. They are not saved
or uploaded, and the classifier runs only after capture.

The shutter drains the current live request before running full-photo inference.
Tab changes and camera restarts invalidate old live results. The camera session
is disposed before reviewing a captured photo and recreated on retake.

Tests cover stream backpressure, capture priority, stale results, camera restart,
raw plane layout and rotation, real native model loading, ownership, confirmation,
correction and exclusion, blank scoring, duplicate-add protection, zoom hit tests,
pinch gestures, phone/tablet layouts, and larger accessibility text. Regression
tests also verify that closing camera settings preserves the nested camera
route and that zoomed number badges remain the same screen size and selectable.
The full camera-enabled suite passes 71 tests, including real native models. The existing
model contracts and weights remain unchanged. See the
[mobile model integration](../machine_learning/docs/mobile-integration-2026-11-22.md)
for validation scope and model licensing.

The prior integration checkpoint is `a096ac0`. Reverting the camera review commit
restores that checkpoint without changing trained models or source data.
