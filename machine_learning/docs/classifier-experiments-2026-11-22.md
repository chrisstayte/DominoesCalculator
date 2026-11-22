# Classifier experiments with existing labels

## Scope and rollback

Improve the pip classifier using existing reviewed labels. Keep `domino-v2-01`
and its saved photo-test boxes fixed. Do not modify source photos, crop images,
labels, group assignments, the frozen split, earlier model runs, or app assets.
The final test split stays unused. Each experiment requires a new run directory
and refuses to overwrite an existing one. Every epoch saves a recoverable last
checkpoint; the best validation checkpoint is retained separately.

Private inputs, snapshots, weights, detailed predictions, overlays, and training
logs remain in the user's Drive project. Public commits contain code, clean
notebooks without execution outputs, and reviewed aggregate findings only. Do not
publish account identifiers, Drive IDs/links, source-image names, raw notebook
outputs, credentials, or private dataset contents in new results.

## First controlled comparison

Use ImageNet-pretrained MobileNetV2, width multiplier 0.5, at the existing 128×128
half resolution. Preserve numeric classes 0–15 and RGB 0–255 external input;
MobileNet scaling to −1…1 is embedded in the model. Train a new head for up to 12
epochs, then fine-tune convolution weights for up to 40 epochs at a lower learning
rate. Batch-normalization statistics remain frozen. Select the checkpoint with the
lowest original-validation cross entropy across both phases.

| Run | Color augmentation | Other controls |
| --- | --- | --- |
| `pips-v3-mnv2-rgb-01` | RGB, modest hue/saturation changes | Same architecture, seed, split, epoch limits, class weighting, geometry and lighting |
| `pips-v3-mnv2-mixed-01` | 50% grayscale plus broader hue changes | Same architecture, seed, split, epoch limits, class weighting, geometry and lighting |

Both use rotations/flips, mild lighting changes, and shrink/pad rather than crops
that could remove pips. This compares two color-augmentation recipes as a unit;
it does not isolate grayscale probability from hue range. Challenge photos never
enter training, checkpoint selection, or the validation split. Record all trials,
including regressions, before deciding whether another iteration is justified.

## Evaluation

Recompute the two previous classifiers and the new candidates on identical data:

- Original validation halves, with per-value support and accuracy.
- Grayscale, red/blue-swapped, and darker validation variants; these are correlated
  transformations of the same photos, not new independent observations.
- The 36 previously checked development tile pairs on fixed original crops,
  broken down by black and colored pips.
- The same selected pairs matched to saved `domino-v2-01` boxes using polygon IoU
  ≥ 0.5. All classifiers receive identical detector crops. Save overlays for all
  seven scenes, including the two with zero detections.

Whole-photo recall and total-score accuracy remain unavailable without exhaustive
annotations of those scenes. A classifier change cannot recover a missing box.
Model parameter count and checkpoint size are recorded; neither establishes phone
latency. Mobile deployment needs separate export and device verification.

## Integrity checks

Before training, validate the existing crop metadata, label hash, group separation,
and frozen split against the earlier classifier contract. Hash all original crop
files, manifests, baseline classifier checkpoints, and the fixed detector weights.
Save label/manifests copies inside the new run, load training/validation images into
local memory, and verify protected file hashes after training and comparison.
Comparison also verifies the saved baseline and detector prediction hashes.

Implementation references: [Keras transfer learning](https://keras.io/guides/transfer_learning/),
[MobileNet applications](https://keras.io/api/applications/mobilenet/).

## Execution log

- Prepared isolated experiment code and input-preservation checks.
- Training and comparison results are pending execution; no improvement is claimed yet.
