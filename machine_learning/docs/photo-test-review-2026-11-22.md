# Photo test review · November 22, 2026

Seven saved photo tests were reviewed, including all 99 reconstructed detector crops.
The baseline used `domino-v1-01` and `pips-v1-02`. The selected, visually transcribed
examples and baseline prediction hashes are in [the review record](../reviews/2026-11-22-photo-tests.json).
These are development examples chosen after seeing errors, not an independent test set.
They have no exhaustive box annotations, so full-photo recall/accuracy is not measurable here.

| Photo | Detected boxes | What worked | What failed |
| --- | ---: | --- | --- |
| `360_F_109730848…jpg` | 12 | Most boxes roughly enclose a tile | 20 of 24 halves predicted 6, four predicted 10. A visible 0\|1 became 6\|6. |
| `1000_F_88049010…jpg` | 24 | Many tile locations found | 25 halves predicted 10 and 18 predicted 14, although visible values are 0–6. Some boxes include neighbors. |
| `1000_F_411914392…jpg` | 0 | — | One clearly visible 3\|4 on white was missed. |
| `domino-square_0.png` | 0 | — | Overlapping tiles on white were missed. Some values are obscured. |
| `il_1080xN.2696512739_8upg.jpg` | 29 | Many tile locations found | Different color mapping: a red 9\|green 1 became 10\|8 at high confidence. Duplicate detections 6/28. |
| `s-l1200.jpg` | 14 | Examples 7\|3 and 9\|2 were correct | Most crowded tiles missed; off-image/neighbor crops, a misoriented divider, and background-only detection 13. |
| `il_fullxfull.7639957162_4r22.jpg` | 20 | Several training-like color pairs correct, including 1\|8, 10\|10 and 11\|11 | Dense display largely missed; some crossing/duplicate boxes. A 1\|12 crop became 1\|13. |

The strongest evidence for color dependence comes from a controlled check on the
**same 248 original validation halves** with the saved classifier. Grayscale changed
158 predictions (63.7%); swapping red/blue changed 130 (52.4%). These are prediction
changes, not accuracy estimates. The experiment keeps crop geometry and weights fixed.
The saved run's original validation accuracy was 99.19%, which did not establish
reliability on different physical sets, color mappings, or layouts.

## Changes prepared for the next runs

- **Classifier `pips-v2-01`:** grayscale is embedded in the saved model, alongside
  normalization. Training, photo inference and TFLite therefore use the same transform
  while the external input stays RGB 0–255. Training-only hue/saturation, gamma,
  contrast/darkening, reduced resolution and shrink/pad augmentation vary appearance.
  Shrink/pad keeps the full half in view. Actual augmentation previews are displayed.
- **Detector `domino-v2-01`:** RGB plus grayscale copies of training photos, with
  explicit rotation, translation, scale, perspective and HSV augmentation. Original
  validation/test photos and the frozen split are preserved. Augmented copies are not
  independent scenes. A separate local cache prevents mixing recipes.
- **Checks:** original/grayscale/channel-swapped/darker/lower-resolution validation
  results are saved separately. Run contracts record the recipe and reject resuming
  older weights under a new recipe. Old runs can still be evaluated/exported.
- **Photo tester:** saves numbered tile crops and flags boxes extending outside the
  photo. Confident predictions and blue outlines can still be wrong.

The grayscale operation uses a [serializable Keras image operation](https://keras.io/api/ops/image/).
Detector controls follow the [Ultralytics augmentation reference](https://docs.ultralytics.com/guides/yolo-data-augmentation/).
Grayscale retains luminance differences; it reduces a shortcut but does not prove the
network counts pips. It also cannot repair a detector box that contains the wrong tile.

## Data to collect next

The next useful collection should change **tile style and scene layout**, not just
increase epochs on the same set. A practical first target is 60–100 additional photos,
then inspect the failure distribution again; this is a collection target, not an
accuracy guarantee.

1. Include multiple black-pip sets and colored sets with different color-to-value mappings.
   Include blanks, 1/2/3, 5/6, and dense 10–15 patterns where applicable.
2. Include single-tile close-ups, small groups, ordinary scattered hands, and touching
   grids/chains. Deliberately include white backgrounds and larger tiles in the frame.
3. Vary camera angle, background, shadow/glare and distance. Use real phone captures
   matching intended use. An unobscured tile is a better first target than guessing
   hidden values behind overlapping tiles.
4. Annotate complete visible tile boxes consistently and verify both half labels from
   each crop. Reject unreadable geometry; never use current predictions as ground truth.
5. Keep all angles of an arrangement/session in the same group. Include a check with
   an entire physical set unseen in training. Add new annotated photos under a new
   dataset version and new run names; do not rewrite the existing frozen split.

The seven reviewed uploads can be reused as a development challenge for before/after
inspection. After using them to choose changes, collect fresh photos for final testing.
Training on these uploads requires actual box/half labels; they are not automatically
added to the training dataset.

## Retraining and comparison

Open the updated training notebooks from `dev`. Existing crops and labels are reusable.
The classifier uses `pips-v2-01`; the detector uses `domino-v2-01`. Leave `FINAL_TEST=False`.
Both training recipes are new experiments rather than resumes of the previous models.

For a monitored Colab job, mount Drive and install notebook 2's training dependencies,
then run `scripts/run_model_stage.py` for `classifier`, `detector`, and `compare` in
separate Python processes. This releases GPU memory between training stages. Each
stage writes a completion receipt and figures under `training_reports/`. Comparison
reuses the same seven originals, saves new photo-test folders, and scores the selected
36 manually checked pairs on fixed baseline crops to isolate classifier changes.
Full-photo detector changes still require visual inspection.

## Completed v2 results

Both models finished training in Colab on November 22, 2026. The executed
[results notebook](../notebooks/05_v2_retraining_results.ipynb) was saved to `dev`.
Weights remain in Drive under `models/classifier/pips-v2-01/best.keras` and
`models/detector/domino-v2-01/weights/best.pt`. All seven original photos were
retested. [Run records and predictions](../reviews/2026-11-22-v2/summary.json)
preserve the comparison, validation metrics, and completion receipts.

**The result is mixed. These runs are experiments, not approved app replacements.**
Black-pip classification improved, colored examples regressed, and both photos on
white backgrounds still have zero detections. The app's model assets and export
selection were not replaced.

### Classifier: same original crops

Both halves must match the manually checked values; exchanging the two halves is
allowed. Crop geometry is held fixed to isolate classifier changes.

| Selected examples | Baseline `pips-v1-02` | New `pips-v2-01` |
| --- | ---: | ---: |
| Black pips, two wood-background photos | 0/19 | 13/19 |
| Colored pips, three photos | 8/17 | 4/17 |
| All selected tile pairs | 8/36 (22.2%) | 17/36 (47.2%) |

The classifier completed 60 epochs. On the original 248 validation halves its
accuracy was 91.13%, down from the baseline run's 99.19%. Those halves come from
only five photos. Grayscale conversion changed none of the new model's predictions;
red/blue channel swapping changed 26/248, versus 130/248 in the controlled baseline
check. Grayscale still uses unequal luminance weights for color channels, so channel
swapping is not invariant. New accuracy was 83.06% for channel swapping, 79.84% for
darkening, and 92.34% for reduced resolution. These transformed copies are not new
independent test scenes.

### Detector and the complete pipeline

The detector stopped after 81 epochs, with its best checkpoint at epoch 61. Saved
validation mAP50 was 0.995 and mAP50–95 was 0.96976. Its original validation set has
only five photos/124 boxes, and these scores did not transfer to all uploaded scenes.

| Photo | Boxes before → after | Fixed-crop pairs before → after | New overlay inspection |
| --- | ---: | ---: | --- |
| Single 3\|4 on white | 0 → 0 | — | Still missed entirely. |
| Dense inventory `il_fullxfull…` | 20 → 73 | 6/6 → 1/6 | Many more real tile locations found; duplicate/shifted boxes remain, and several values regress. |
| Alternate colored set `il_1080xN…` | 29 → 33 | 0/7 → 3/7 | Some values improve; duplicates and boxes crossing neighboring tiles remain. |
| Overlapping tiles on white | 0 → 0 | — | Still missed entirely. |
| Angled grid `s-l1200.jpg` | 14 → 30 | 2/4 → 0/4 | Numerous shifted, crossing, and off-image boxes; extra boxes are not reliable tile counts. |
| Black-pip chain `1000_F_88049010…` | 24 → 33 | 0/7 → 5/7 | Real locations plus false detections on watermark text; several crops span tile boundaries. |
| Black-pip layout `360_F_109730848…` | 12 → 12 | 0/12 → 8/12 | Tile locations roughly retained; 6-pip halves are still often undercounted. |

Matching the 36 selected original boxes to new detections with one-to-one polygon
IoU ≥ 0.5 found a match for all 36; 18 new detected-crop pairs had correct values
(baseline 8/36). This differs from 17/36 above because the new detector changes the
crop. These are **selected original detector boxes**, not independently annotated
box ground truth. This does not measure full-photo accuracy, missed-tile recall,
false-positive rate, or total-score correctness. Counts alone cannot establish an
improvement. All seven overlays were inspected; none establishes dependable totals.

### What the next training dataset needs

Keep the grayscale recipe as a candidate, but add and verify real black-pip and
alternate-color examples before choosing it for the app. Prioritize the two missed
white-background layouts, touching grids/chains, close-ups, and watermark/text
background negatives. Label complete visible tiles and both halves manually. Include
balanced examples of 4/5/6 and dense higher values: the new black-pip overlays show
undercounting even when locations look reasonable. Inspect classifier performance
by physical set, value, and crop quality instead of relying on the combined average.

Use the 60–100-photo collection plan above, preserve whole-session/set holdouts, and
create a new dataset version. Do not automatically train on these predictions.
These seven uploads have now influenced the recipe and need fresh final-test photos.
Another longer run on the same narrow dataset would not by itself demonstrate that
the remaining scene/style failures are fixed. In notebook 4, explicitly select
`domino-v2-01` and `pips-v2-01` to inspect this experiment; its baseline defaults
remain available for comparison.

Live results: [Colab job](https://colab.research.google.com/drive/1C3FHmqEEyvFwXDrjq_hycgEe-LjMZdQE),
[Drive comparison report](https://drive.google.com/drive/folders/1CGRsCyU5zIuWjaNvy2zxeC-Bn-BO1iT-),
[all saved photo tests](https://drive.google.com/drive/folders/1USsohrWCanegOJsnaNave-hxZWpi1LsU).
