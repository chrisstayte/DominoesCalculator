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

After comparison, `scripts/export_classifier_candidate.py` can create FP32 and FP16
LiteRT files in a new export directory inside a candidate run. It checks all original
validation halves against Keras, records prediction changes and accuracy loss, and
measures batch-one CPU inference on the current host. It refuses an existing export
directory and verifies protected input hashes again. Host timing is not phone timing.

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
- All 44 local ML unit checks passed, including compatible candidate metadata and
  refusal to replace an existing contract. Dev CI passed for the clean experiment notebook.
- MobileNetV2 FP32 and FP16 conversion/inference passed an additional synthetic
  smoke check. This verifies portability of the architecture, not recognition accuracy.
- Colab could not allocate an additional GPU. Appended the classifier-only launch
  cell to the existing connected T4 notebook; earlier cells and saved runs remain intact.
- Both Colab trials, the controlled comparison, and both candidates' FP32/FP16
  export checks completed. A slow Drive file read recovered without modifying any
  input files. Protected hashes passed after both training runs, comparison, and exports.

## Completed results

The mixed-color/grayscale candidate is the strongest observed classifier in this
experiment. No additional source photos or manual labels were used. The 821 existing
labeled tiles supplied 1,178 training halves and 248 validation halves. The 216 final
test halves stayed unused. Aggregate numbers are in the
[public result record](../reviews/2026-11-22-classifier-v3.json).

| Classifier | Original validation | Fixed original pairs | Black pips | Colored pips | Fixed detector pairs |
| --- | ---: | ---: | ---: | ---: | ---: |
| `pips-v1-02` | 99.19% | 8/36 | 0/19 | 8/17 | 8/36 |
| `pips-v2-01` | 91.13% | 17/36 | 13/19 | 4/17 | 18/36 |
| `pips-v3-mnv2-rgb-01` | 99.60% | 15/36 | 7/19 | 8/17 | 14/36 |
| **`pips-v3-mnv2-mixed-01`** | **99.60%** | **29/36** | **18/19** | **11/17** | **29/36** |

The original validation denominator is 248 halves from five source photos; pair
columns require both values to match, allowing the halves to swap. The two crop
comparisons use different fixed geometries, so their correct pairs need not be the
same even when totals match. The unchanged detector supplied 0, 73, 33, 0, 30, 33,
and 12 boxes across the seven scenes. No detector was trained or replaced.

The RGB trial completed 33 epochs (12 head + 21 fine-tuning); its best original
validation loss was 0.009109. The mixed trial completed 40 epochs (12 + 28); its
best loss was 0.006737. These checkpoints were selected before scoring the challenge
photos. The RGB-only trial's high original validation score did not transfer as well
to the development scenes; keep that regression as part of the experiment record.

### Robustness checks

All variants below reuse the same 248 validation halves and are correlated checks.

| Classifier | Original | Grayscale | Red/blue swapped | Darker |
| --- | ---: | ---: | ---: | ---: |
| `pips-v1-02` | 99.19% | 35.89% | 47.18% | 54.03% |
| `pips-v2-01` | 91.13% | 91.13% | 83.06% | 79.84% |
| RGB pretrained | 99.60% | 68.55% | 62.90% | 99.60% |
| Mixed pretrained | 99.60% | 99.19% | 99.60% | 100.00% |

An independent local check reproduced all four classifiers' Colab totals on both
sets of fixed challenge crops. This supports the comparison; it does not turn the
development examples or transformed validation copies into an independent final test.

### Portable candidate

The mixed model has 872,256 parameters. Its verified exports are 3,417,832 bytes
(FP32) and 1,741,460 bytes (FP16). Both matched Keras predictions on all 248 original
validation halves and on both sets of 36 development pairs. Each export retained
29/36 correct development pairs. Inputs remain RGB float32 0–255 with scaling embedded;
outputs retain numeric class order 0–15.

The exported models remain private under the candidate's `exports/portable-01/`
directory. Current-host CPU diagnostics were recorded privately. Sequential timings
varied considerably between candidates with identical architectures, so they are
not a controlled speed comparison or evidence of target-phone latency. App assets
and the existing model-selection defaults were not changed.

### Remaining errors and rollback

All seven mixed-model overlays were inspected. Seven selected original-crop pairs
are still wrong. Difficult angled/crowded layouts and some larger pip counts remain
weak. With the detector fixed, shifted boxes can introduce different classifier
mistakes: the clean black-pip layout had 12/12 correct on its original crops but
9/12 on the saved newer detector crops. The two white-background scenes still have
zero detections; watermark false detections and crossing boxes also remain.

Keep `pips-v3-mnv2-mixed-01` as the next classifier candidate, not a claim of dependable
whole-photo scoring. Both v3 trials, their phase-best/best/last checkpoints, and all
earlier runs remain available. To return to an earlier result, select its existing
run name in the photo tester. To run another training experiment, use new trial and
comparison names in [notebook 6](../notebooks/06_pretrained_classifier.ipynb); do not
overwrite this experiment. Further classifier experiments can reuse the same labels.

For notebook 4, use `DETECTOR_RUN_NAME="domino-v2-01"` and
`CLASSIFIER_RUN_NAME="pips-v3-mnv2-mixed-01"`, then rerun model loading. New candidates
include the same dataset-contract fields expected by that loader. Existing models
retain their original metadata. The completed trials used training code revision
`fb897b1`; notebook 6 now pins `02ece74`, which adds the compatible metadata write
without changing the training recipe or previously trained weights.

Both candidates passed notebook 4's actual model-loading cell and its `half_predict`
RGB input/output check in Colab. The metadata finalizer verified each completed
checkpoint's saved hash before adding the missing contract; it did not rewrite weights.
